---
name: be-django-api
description: Conventions for Django + DRF APIs: app layout, base model with soft delete, base viewset, serializers, error shape, migrations, and env config. Use when creating or changing a model, serializer, view, migration, or settings in a Django project.
---

# Django + DRF API

Stack: PostgreSQL, `django-filter`, `python-dotenv`. Declare dependencies in `pyproject.toml` (`uv add`), and never add one without asking the user.

## Layout

One app per domain at the project root, plus a `core` app for shared code.

```
<domain>/
├── models/            # one file per entity; __init__.py re-exports them
├── admin/
├── api/serializers/   # one file per entity
├── api/views/         # one file per entity
├── services.py        # only for logic beyond CRUD
├── urls.py
└── tests/             # see test-pytest
core/                  # models.py (BaseModel), viewsets.py (BaseViewSet), exceptions.py
```

## Models

```python
# core/models.py
import uuid
from django.db import models
from django.utils import timezone


class BaseModel(models.Model):
    uuid = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    deleted_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        abstract = True

    def delete(self, using=None, keep_parents=False):
        """Soft delete: keep the row, stamp deleted_at."""
        self.deleted_at = timezone.now()
        self.save(update_fields=["deleted_at"])

    def hard_delete(self, using=None, keep_parents=False):
        return super().delete(using=using, keep_parents=keep_parents)
```

- The primary key field is `uuid`. Every model inherits `BaseModel`.
- Deleting is soft. `BaseViewSet` hides deleted rows, but every other query (services, admin, related lookups) must filter `deleted_at__isnull=True` itself. `QuerySet.delete()` is a hard delete.
- `on_delete=PROTECT` by default. `CASCADE` only for children that cannot exist alone.
- Choices are `TextChoices`, never magic strings. `Meta.ordering = ["-created_at"]`.

## Serializers

- List `fields` explicitly, never `__all__`. Put `uuid` and the timestamps in `read_only_fields`.
- Nested objects for reading, IDs (`PrimaryKeyRelatedField`) for writing.
- Never expose `password` or internal flags. Field rules go in `validate_<field>`, cross-field rules in `validate`.

## Views

```python
# core/viewsets.py
from django_filters.rest_framework import DjangoFilterBackend
from rest_framework import permissions, viewsets
from rest_framework.filters import OrderingFilter, SearchFilter


class BaseViewSet(viewsets.ModelViewSet):
    permission_classes = [permissions.IsAuthenticated]
    filter_backends = [DjangoFilterBackend, SearchFilter, OrderingFilter]

    def get_queryset(self):
        return super().get_queryset().filter(deleted_at__isnull=True)
```

```python
# projects/api/views/project_views.py
class ProjectViewSet(BaseViewSet):
    queryset = Project.objects.all()
    serializer_class = ProjectSerializer
    filterset_fields = ["status"]
    search_fields = ["name"]

    def get_queryset(self):
        return super().get_queryset().filter(owner=self.request.user)

    def perform_create(self, serializer):
        serializer.save(owner=self.request.user)
```

- Inherit `BaseViewSet`. Declare `permission_classes` explicitly when a view differs from the base.
- `get_queryset` must narrow to the user's scope whenever the data is owned. Leaking another user's rows is the most common bug.
- Views stay thin: validate with the serializer, call `services.py` for logic beyond CRUD, return.
- Status codes: `201` create, `204` delete, `400` validation, `403` permission, `404` not found.
- `PAGE_SIZE = 50`, `DjangoFilterBackend` as the default filter backend.

## Errors

Every error response has the shape `{"success": false, "message": ..., "errors": ...}`. Register the handler and do not return ad-hoc error bodies, because the frontend reads this shape.

```python
# core/exceptions.py
from rest_framework import status
from rest_framework.response import Response
from rest_framework.views import exception_handler


def custom_exception_handler(exc, context):
    response = exception_handler(exc, context)
    if response is None:
        return Response(
            {"success": False, "message": "Internal server error", "errors": None},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR,
        )
    message = "Invalid data" if response.status_code in (400, 422) else "Error"
    return Response({"success": False, "message": message, "errors": response.data}, status=response.status_code)
```

Set it as `REST_FRAMEWORK["EXCEPTION_HANDLER"]`.

## Migrations

Every model change ships with its migration: run `makemigrations`, read the file, run `migrate`, and commit it. Never edit a migration that has been applied.

## Config

- Read env vars with `os.getenv` after `load_dotenv()`. `.env` is gitignored, `.env.example` is committed with placeholders, and secrets never enter the repo.
- Parse booleans: `DEBUG = os.getenv("DEBUG", "False") == "True"`. `os.getenv("DEBUG")` returns a string, and the string `"False"` is truthy.
- Variables: `SECRET_KEY`, `DEBUG`, `ALLOWED_HOSTS`, `DATABASE_NAME`, `DATABASE_USER`, `DATABASE_PASSWORD`, `DATABASE_HOST`, `DATABASE_PORT`, `CORS_ALLOWED_ORIGINS`.
- `CORS_ALLOWED_ORIGINS` lists exact origins. See be-jwt-auth when the API uses cookie auth.
