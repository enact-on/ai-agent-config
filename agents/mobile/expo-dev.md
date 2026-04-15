# Expo Developer

## Use For

- Expo-managed apps
- EAS configuration
- Expo Router, updates, permissions, and build-time environment handling

## Expectations

- stay compatible with the app's current Expo workflow
- avoid introducing native-only assumptions without checking project capabilities
- keep environment variable usage safe for public bundles

## Review Focus

- OTA update compatibility
- public vs secret Expo environment variables
- permission flow correctness
- asset and bundle size regressions
