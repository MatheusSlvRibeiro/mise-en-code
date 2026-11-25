# 0005. Authenticate SPAs with JWT in httpOnly cookies

Status: Accepted
Date: 2026-11-17

## Context

A Django API consumed by its own single-page app needs a way to carry the user's tokens. Tokens kept in `localStorage` or read from a response body are available to any script on the page, so a single XSS bug exposes them. The maintainer's existing Django project sends SimpleJWT tokens in the response body and reads them from an `Authorization: Bearer` header.

## Decision

New projects use SimpleJWT with both tokens in `httpOnly` cookies, never in a response body and never in browser storage. The `be-jwt-auth` skill holds the code. The details that matter:

- The access cookie lives 15 minutes and the refresh cookie 7 days. The refresh token rotates and the old one is blacklisted. The refresh cookie is scoped to the refresh path.
- Cookies are `Secure` outside local development and `SameSite=Lax`. `SameSite=None` is only for a frontend on a different site.
- CSRF is enforced by the authentication class. DRF checks CSRF only for `SessionAuthentication`, so a custom cookie class gets no check unless it calls one. The class enforces it on every cookie-authenticated unsafe request, and the refresh and logout endpoints enforce it too. The client copies the `csrftoken` cookie into an `X-CSRFToken` header.
- Logout blacklists the refresh token and deletes both cookies.
- A `Bearer` header still works for non-browser clients, which hold no ambient credentials and so need no CSRF check. An endpoint that returns a token in a body is an exception and must say why.

## Consequences

- A script on the page cannot read the tokens, which closes the common XSS route.
- Every client has to send credentials and echo the CSRF token, which adds client code that a Bearer token does not need.
- Cross-origin setups need exact CORS origins (never `*`) and `CSRF_TRUSTED_ORIGINS`.
- The skill's code was run in a throwaway project with Django 6.1, DRF 3.18, and SimpleJWT 5.5: 15 tests passed, and removing the CSRF check made the matching test fail. Not tested: the client code, and `CSRF_TRUSTED_ORIGINS` across HTTPS origins.
- The maintainer's existing project, which uses a Bearer header, is not covered. Migrating it is a separate decision.

## Alternatives considered

- **Bearer token in the header, stored by the SPA.** This is what the existing project does. Rejected for new projects: the token must live somewhere scripts can read.
- **Django session cookies.** Rejected: the project already uses SimpleJWT, and sessions would add server-side state.
