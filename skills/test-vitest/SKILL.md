---
name: test-vitest
description: Testing conventions for React with Vitest and Testing Library. Use when writing or changing tests for components, forms, or src/lib/ functions.
---

# Vitest + Testing Library

Dev dependencies: `vitest`, `jsdom`, `@testing-library/react`, `@testing-library/user-event`, `@testing-library/jest-dom`. Run `npx vitest run`.

```ts
// vite.config.ts (inside defineConfig, imported from 'vitest/config')
test: {
  environment: 'jsdom',
  globals: true,
  setupFiles: './src/test-setup.ts',
},
```

```ts
// src/test-setup.ts
import '@testing-library/jest-dom/vitest';
```

With `globals: true`, add `"vitest/globals"` and `"@testing-library/jest-dom"` to `compilerOptions.types` so `tsc` accepts the test files.

## Where tests live

- A component test sits beside the component: `Button/Button.test.tsx`.
- Every function in `src/lib/` has a test in `src/lib/__tests__/`.

## Rules

- Test what the user sees and does. Do not test internals.
- Query by role and accessible name: `getByRole('button', { name: 'Save' })`. Use `getByTestId` only when no role fits.
- Use `userEvent`, awaited, not `fireEvent`.
- `vi.mock` only at the edges of the system: API calls, storage. Never mock a child component.
- After an async action, wait for the result with `findBy*` or `vi.waitFor`. Do not sleep.

```tsx
// Button.test.tsx
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { describe, expect, it, vi } from 'vitest';
import { Button } from './Button';

describe('Button', () => {
  it('calls onClick when clicked', async () => {
    const handler = vi.fn();
    render(<Button label="Save" onClick={handler} />);

    await userEvent.click(screen.getByRole('button', { name: 'Save' }));

    expect(handler).toHaveBeenCalledOnce();
  });
});
```

## Forms

Assert that schema messages appear and that invalid data does not submit. A valid submit awaits the handler.

```tsx
await userEvent.type(screen.getByLabelText('Email'), 'nope');
await userEvent.click(screen.getByRole('button', { name: 'Sign in' }));

expect(await screen.findByText('Enter a valid email')).toBeInTheDocument();
expect(onSubmit).not.toHaveBeenCalled();
```

Each input needs a visible `<label>` so the test can find it by its label text. See fe-forms.
