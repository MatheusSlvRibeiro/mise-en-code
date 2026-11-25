---
name: fe-react-ui
description: Conventions for React + TypeScript components in a Vite app: folder layout, export style, typed props, and SCSS Modules with BEM. Use when creating or reviewing a component, page, or hook, or when styling with SCSS.
---

# React UI

## Layout and placement

```
src/
├── components/   # used in 2+ places
├── pages/        # one folder per route
├── hooks/        # used in 2+ places
├── lib/          # utilities and API access; tests in lib/__tests__/
├── schemas/      # zod schemas used in 2+ places
├── styles/       # _variables.scss, global.scss
└── main.tsx
```

Code lives next to its single user and moves to a shared folder only when a second real user appears. Do not create shared folders ahead of need. A component, its stylesheet, and its test share one folder: `Button/Button.tsx`, `Button.module.scss`, `Button.test.tsx`.

## Components

- Named exports. `default` only for pages.
- Props are an `interface` declared above the component.
- No `style={{}}`.
- Data shapes from outside the component (forms, API responses, URL params) come from a zod schema, not from a loose `interface` in the `.tsx`. See fe-forms.

```tsx
import clsx from 'clsx';
import styles from './Button.module.scss';

interface ButtonProps {
  label: string;
  variant?: 'primary' | 'secondary';
  onClick: () => void;
}

export function Button({ label, variant = 'primary', onClick }: ButtonProps) {
  return (
    <button className={clsx(styles.button, styles[`button--${variant}`])} onClick={onClick}>
      {label}
    </button>
  );
}
```

## Styling: SCSS Modules + BEM

One `.module.scss` per component. The module scope prevents collisions, so BEM names stay short: block `.button`, modifier `&--primary`, element `&__icon`. Build dynamic modifiers with `clsx`.

```scss
// Button.module.scss: variables come from _variables.scss, injected globally
.button {
  padding: $space-2 $space-4;

  &--primary { background: $color-primary; color: #fff; }
  &__icon { margin-right: $space-2; }
}
```

- Shared variables and mixins live in `src/styles/_variables.scss` and `_mixins.scss`. Inject them once with `additionalData` instead of `@use` in every file (config below).
- `global.scss` (reset, base typography) is imported only in `main.tsx`, never in a component.
- Never import plain global CSS from a component.
- For landing pages and utility-first styling, see fe-tailwind instead.

## Vite and TypeScript config

```ts
// vite.config.ts (needs @types/node)
import { fileURLToPath, URL } from 'node:url';
import react from '@vitejs/plugin-react';
import { defineConfig } from 'vitest/config';

export default defineConfig({
  plugins: [react()],
  resolve: { alias: { '@': fileURLToPath(new URL('./src', import.meta.url)) } },
  css: {
    preprocessorOptions: {
      scss: { additionalData: `@use "@/styles/variables" as *;` },
    },
  },
});
```

```json
// tsconfig.json: TypeScript 7 removed `baseUrl`; paths are relative to the file
{ "compilerOptions": { "paths": { "@/*": ["./src/*"] } } }
```

Env vars read in the browser are `import.meta.env.VITE_*`. Anything without the `VITE_` prefix is not exposed, and nothing secret may use it.
