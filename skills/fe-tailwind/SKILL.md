---
name: fe-tailwind
description: Styling with Tailwind CSS v4 without cluttering components: design tokens, predefined utilities, and variants. Use when styling a landing page or any project that uses Tailwind.
---

# Tailwind CSS v4

Components stay readable because the design decisions live in one stylesheet, `src/styles/index.css`, and the JSX only names them. There is no per-component CSS file.

## Tokens and predefined styles

```css
/* src/styles/index.css */
@import 'tailwindcss';

@theme {
  --color-brand-500: oklch(0.62 0.19 259);
  --color-brand-600: oklch(0.55 0.2 259);
  --color-surface: oklch(0.99 0 0);
  --color-muted: oklch(0.55 0.02 260);
  --font-display: 'Inter', sans-serif;
  --radius-card: 1rem;
}

/* A repeated pattern gets a name here, not a long string of utilities in JSX. */
@utility section-y {
  padding-block: --spacing(16);
}

@utility eyebrow {
  font-size: var(--text-sm);
  letter-spacing: 0.08em;
  text-transform: uppercase;
  color: var(--color-brand-600);
}
```

- Every `@theme` variable becomes utilities: `--color-brand-500` gives `bg-brand-500`, `text-brand-500`; `--radius-card` gives `rounded-card`.
- `@utility` classes accept variants like any utility: `md:section-y`, `hover:eyebrow`.
- Components use these names: `bg-brand-500`, `rounded-card`, `section-y`. Never a raw value such as `bg-[#1a2b3c]` or `p-[13px]`. A value that is not a token becomes a token first.
- No `style={{}}`.

## Variants

Build class names with `cn()`, and use `cva` once a component has 3 or more variants.

```ts
// src/lib/cn.ts
import { clsx, type ClassValue } from 'clsx';
import { twMerge } from 'tailwind-merge';

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}
```

```tsx
// src/ui/Button.tsx
import { cva, type VariantProps } from 'class-variance-authority';
import type { ButtonHTMLAttributes } from 'react';
import { cn } from '@/lib/cn';

const button = cva('rounded-card px-4 py-2 font-medium transition-colors', {
  variants: {
    variant: {
      primary: 'bg-brand-500 text-surface hover:bg-brand-600',
      ghost: 'bg-transparent text-brand-600 hover:text-brand-500',
    },
  },
  defaultVariants: { variant: 'primary' },
});

interface ButtonProps
  extends ButtonHTMLAttributes<HTMLButtonElement>,
    VariantProps<typeof button> {}

export function Button({ variant, className, ...props }: ButtonProps) {
  return <button className={cn(button({ variant }), className)} {...props} />;
}
```

## When to extract

- The same utilities repeated in 3+ places become a component (`<Card>`, `<Badge>`) or an `@utility`, not a string constant of classes.
- `cn()` lets a caller override classes safely through `className`, because `tailwind-merge` resolves conflicts.
- Component structure, export style, and layout rules are in fe-react-ui.

## Setup

Install `tailwindcss` and `@tailwindcss/vite`, add the plugin to `vite.config.ts`, and import `src/styles/index.css` once in `main.tsx`.
