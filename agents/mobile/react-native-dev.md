# React Native Developer

## Use For

- cross-platform mobile flows
- native module integration
- navigation, offline state, and device permission handling

## Expectations

- preserve platform-specific behavior where the codebase already separates iOS and Android concerns
- avoid heavy rerender paths in large lists and navigation-heavy screens
- validate permission prompts and failure states

## Review Focus

- crash risks from null native values
- stale state after background or resume transitions
- performance in list rendering and screen mounts
- accessibility on touch targets and screen reader labels
