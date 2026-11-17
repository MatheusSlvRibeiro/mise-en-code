---
name: test-pytest
description: Testing conventions for Django + DRF with pytest-django and factory_boy. Use when writing or changing tests for models, serializers, views, or services.
---

# pytest for Django + DRF

Add `pytest`, `pytest-django`, and `factory-boy` to the dev dependencies. Run `pytest` from the project root.

```ini
# pytest.ini
[pytest]
DJANGO_SETTINGS_MODULE=<project>.settings
python_files = test_*.py
```

## Layout

`<domain>/tests/` holds one file per layer: `test_models.py`, `test_serializers.py`, `test_views.py`, `test_services.py`, plus `factories.py`. The file must be named `test_*.py` to be collected.

## Rules

- Tests use the real database. Mock only what is outside the system: HTTP calls, storage, email.
- Build data with factories, not large shared fixtures.
- Every endpoint has an integration test that checks the status code, the shape of the body, and the effect in the database.
- Every endpoint that returns owned data has a scoping test: another user's rows must not appear.
- Mark tests that touch the database with `@pytest.mark.django_db`.
- A test must be able to fail. No `assert True`, and no test that runs code without checking a result.

## Patterns

```python
# conftest.py
import pytest
from rest_framework.test import APIClient


@pytest.fixture
def api_client() -> APIClient:
    return APIClient()


@pytest.fixture
def user(db):
    return UserFactory()


@pytest.fixture
def authenticated_client(api_client, user) -> APIClient:
    api_client.force_authenticate(user=user)
    return api_client
```

```python
# projects/tests/factories.py
import factory
from django.contrib.auth import get_user_model


class UserFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = get_user_model()

    username = factory.Sequence(lambda n: f"user{n}")
    password = factory.django.Password("s3cret-pass")  # hashed; set_password in a hook is not saved


class ProjectFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = Project

    owner = factory.SubFactory(UserFactory)
    name = factory.Faker("word")
```

```python
# projects/tests/test_views.py
@pytest.mark.django_db
def test_user_lists_only_own_projects(api_client):
    user = UserFactory()
    own = ProjectFactory(owner=user)
    ProjectFactory(owner=UserFactory())  # must not appear

    api_client.force_authenticate(user=user)
    res = api_client.get("/api/projects/")

    assert res.status_code == 200
    assert [p["uuid"] for p in res.json()["results"]] == [str(own.uuid)]
```

- Errors have the shape `{"success": false, "message": ..., "errors": ...}`; assert on it (see be-django-api).
- A delete test checks that the row still exists with `deleted_at` set, and that it no longer appears in the list.
- To test cookie auth (see be-jwt-auth), use `APIClient(enforce_csrf_checks=True)`. The default client skips CSRF, so a test with it proves nothing about CSRF. Cover: login sets httpOnly cookies and returns no tokens, an unsafe request without `X-CSRFToken` gets `403`, and the same request with it succeeds.
