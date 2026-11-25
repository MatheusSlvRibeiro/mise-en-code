---
name: fe-forms
description: Forms with React Hook Form and zod, where schema, type, and error messages live together and the component is structure only. Use when creating or reviewing any form.
---

# Forms: React Hook Form + zod

The schema owns the rules, the type, and the messages. The component owns structure: `useForm`, JSX, submit. It declares no data type and does no manual validation (`if (!email.includes('@'))`).

```ts
// LoginForm.schema.ts
import { z } from 'zod';

export const loginSchema = z
  .object({
    email: z.email('Enter a valid email'),
    password: z.string().min(8, 'Use at least 8 characters'),
    confirmPassword: z.string(),
  })
  .refine((data) => data.password === data.confirmPassword, {
    message: 'Passwords do not match',
    path: ['confirmPassword'],
  });

export type LoginData = z.infer<typeof loginSchema>;
```

```tsx
// LoginForm.tsx
import { zodResolver } from '@hookform/resolvers/zod';
import { useForm } from 'react-hook-form';
import { loginSchema, type LoginData } from './LoginForm.schema';

interface LoginFormProps {
  onSubmit: (data: LoginData) => Promise<void>;
}

export function LoginForm({ onSubmit }: LoginFormProps) {
  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting },
  } = useForm<LoginData>({ resolver: zodResolver(loginSchema) });

  return (
    <form onSubmit={handleSubmit(onSubmit)}>
      <input {...register('email')} />
      {errors.email && <span role="alert">{errors.email.message}</span>}
      {/* password and confirmPassword follow the same pattern */}
      <button type="submit" disabled={isSubmitting}>Sign in</button>
    </form>
  );
}
```

## Rules

- Use the top-level validators of zod 4: `z.email()`, not `z.string().email()`.
- Show `errors.<field>.message` and nothing else. A message string in the JSX means the rule is in the wrong place.
- A rule across fields (passwords must match) is `.refine()` with a `path`, never a comparison in `onSubmit`.
- A schema used by one form sits beside it as `<Form>.schema.ts`. Used by 2+ forms, it moves to `src/schemas/`.
- Backend errors arrive as `{ success, message, errors }` (see be-django-api), where `errors` maps field names to message lists. Parse that shape with a zod schema, then apply each entry with `setError(field, { message })`. Never trust an untyped response.
- Write messages in the language of the product's UI.
