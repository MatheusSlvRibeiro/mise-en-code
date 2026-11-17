---
name: be-jwt-auth
description: Sets up JWT authentication in httpOnly cookies with SimpleJWT for Django APIs consumed by the product's own SPA, including CSRF enforcement. Use when adding login, logout, or refresh endpoints, or changing auth settings.
---

# JWT in httpOnly cookies (SimpleJWT)

Tokens never appear in a response body and never reach `localStorage`: they travel in `httpOnly` cookies, which closes the XSS route to stealing them. The price is CSRF, so every unsafe request must echo the `csrftoken` cookie in an `X-CSRFToken` header.

DRF enforces CSRF only for `SessionAuthentication`. A custom cookie authentication class gets **no** CSRF check unless it calls one itself, so the class below does.

Add `rest_framework_simplejwt.token_blacklist` and `corsheaders` to `INSTALLED_APPS`, and run `migrate`.

## Settings

```python
REST_FRAMEWORK = {
    "DEFAULT_AUTHENTICATION_CLASSES": ["accounts.authentication.CookieJWTAuthentication"],
    "DEFAULT_PERMISSION_CLASSES": ["rest_framework.permissions.IsAuthenticated"],
}
SIMPLE_JWT = {
    "ACCESS_TOKEN_LIFETIME": timedelta(minutes=15),
    "REFRESH_TOKEN_LIFETIME": timedelta(days=7),
    "ROTATE_REFRESH_TOKENS": True,
    "BLACKLIST_AFTER_ROTATION": True,
}
AUTH_COOKIE_ACCESS = "access_token"
AUTH_COOKIE_REFRESH = "refresh_token"
AUTH_COOKIE_REFRESH_PATH = "/auth/token/refresh/"
AUTH_COOKIE_SECURE = not DEBUG
AUTH_COOKIE_SAMESITE = "Lax"

CSRF_COOKIE_HTTPONLY = False  # the frontend must read it
CORS_ALLOW_CREDENTIALS = True
```

Name the app `accounts`, not `auth`: the label `auth` collides with `django.contrib.auth`.

## Authentication

```python
# accounts/authentication.py
from django.conf import settings
from rest_framework import exceptions
from rest_framework.authentication import CSRFCheck
from rest_framework_simplejwt.authentication import JWTAuthentication


def enforce_csrf(request):
    check = CSRFCheck(lambda request: None)
    check.process_request(request)
    reason = check.process_view(request, None, (), {})
    if reason:
        raise exceptions.PermissionDenied(f"CSRF Failed: {reason}")


class CookieJWTAuthentication(JWTAuthentication):
    """Cookie first. Bearer header for non-browser clients, which need no CSRF check."""

    def authenticate(self, request):
        raw_token = request.COOKIES.get(settings.AUTH_COOKIE_ACCESS)
        if raw_token is None:
            return super().authenticate(request)
        validated_token = self.get_validated_token(raw_token)
        user = self.get_user(validated_token)
        enforce_csrf(request)
        return user, validated_token
```

## Views

```python
# accounts/serializers.py
from django.conf import settings
from rest_framework import serializers
from rest_framework_simplejwt.exceptions import InvalidToken
from rest_framework_simplejwt.serializers import TokenRefreshSerializer


class CookieTokenRefreshSerializer(TokenRefreshSerializer):
    refresh = serializers.CharField(required=False)

    def validate(self, attrs):
        refresh = self.context["request"].COOKIES.get(settings.AUTH_COOKIE_REFRESH)
        if not refresh:
            raise InvalidToken("No refresh token cookie.")
        attrs["refresh"] = refresh
        return super().validate(attrs)
```

```python
# accounts/views.py
from django.conf import settings
from django.middleware.csrf import get_token
from django.utils.decorators import method_decorator
from django.views.decorators.csrf import ensure_csrf_cookie
from rest_framework import permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.exceptions import TokenError
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView

from .authentication import enforce_csrf
from .serializers import CookieTokenRefreshSerializer


def set_auth_cookies(response, access, refresh):
    common = {"httponly": True, "secure": settings.AUTH_COOKIE_SECURE, "samesite": settings.AUTH_COOKIE_SAMESITE}
    lifetimes = settings.SIMPLE_JWT
    response.set_cookie(
        settings.AUTH_COOKIE_ACCESS, access,
        max_age=int(lifetimes["ACCESS_TOKEN_LIFETIME"].total_seconds()), **common,
    )
    response.set_cookie(
        settings.AUTH_COOKIE_REFRESH, refresh, path=settings.AUTH_COOKIE_REFRESH_PATH,
        max_age=int(lifetimes["REFRESH_TOKEN_LIFETIME"].total_seconds()), **common,
    )


class CookieTokenObtainPairView(TokenObtainPairView):
    def post(self, request, *args, **kwargs):
        response = super().post(request, *args, **kwargs)
        if response.status_code == status.HTTP_200_OK:
            set_auth_cookies(response, response.data.pop("access"), response.data.pop("refresh"))
            get_token(request)  # makes CsrfViewMiddleware set the csrftoken cookie
        return response


class CookieTokenRefreshView(TokenRefreshView):
    serializer_class = CookieTokenRefreshSerializer

    def post(self, request, *args, **kwargs):
        enforce_csrf(request)
        response = super().post(request, *args, **kwargs)
        if response.status_code == status.HTTP_200_OK:
            set_auth_cookies(response, response.data.pop("access"), response.data.pop("refresh"))
        return response


class LogoutView(APIView):
    authentication_classes = []
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        enforce_csrf(request)
        refresh = request.COOKIES.get(settings.AUTH_COOKIE_REFRESH)
        if refresh:
            try:
                RefreshToken(refresh).blacklist()
            except TokenError:
                pass  # already expired or blacklisted
        response = Response(status=status.HTTP_204_NO_CONTENT)
        response.delete_cookie(settings.AUTH_COOKIE_ACCESS)
        response.delete_cookie(settings.AUTH_COOKIE_REFRESH, path=settings.AUTH_COOKIE_REFRESH_PATH)
        return response


@method_decorator(ensure_csrf_cookie, name="get")
class CsrfView(APIView):
    authentication_classes = []
    permission_classes = [permissions.AllowAny]

    def get(self, request):
        return Response(status=status.HTTP_204_NO_CONTENT)
```

Routes, under `auth/`: `token/`, `token/refresh/`, `logout/`, `csrf/`.

## Rules

- The cookie flags are always `httponly`, `Secure` outside local dev, and `SameSite`. Use `SameSite=None` only when the frontend and API are on different sites, and then `Secure` is mandatory.
- `CORS_ALLOWED_ORIGINS` lists exact origins, never `*`: browsers refuse credentials for a wildcard origin. When the frontend is on another origin, also set `CSRF_TRUSTED_ORIGINS` to those origins, with scheme.
- Login and CSRF-cookie endpoints are the only ones without a CSRF check. Refresh and logout enforce it.
- A Bearer-header endpoint for non-browser clients is an exception. Document why when you add one.

## Client side

- Send every request with credentials (`withCredentials: true` in axios, `credentials: "include"` in fetch).
- On app load, call `GET /auth/csrf/` so the browser has a `csrftoken` cookie.
- On `POST`, `PUT`, `PATCH`, and `DELETE`, copy the `csrftoken` cookie value into the `X-CSRFToken` header.
- On a `401`, call `POST /auth/token/refresh/` once, then retry the original request. If refresh fails, send the user to login.
- Test with `APIClient(enforce_csrf_checks=True)`; see test-pytest.
