# Contributing to A1 Battery Billing Pro

Thank you for your interest in contributing to **A1 Battery Billing Pro**! We welcome contributions, bug reports, and suggestions.

## Development Workflow

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`>= 3.2.0`)
- [Dart SDK](https://dart.dev/get-dart) (`>= 3.0.0`)
- Android Studio / VS Code with Flutter and Dart extensions
- Android device or emulator (API 21+) / Windows Desktop build tools

### Getting Started

1. **Fork the Repository**
2. **Clone your fork**:
   ```bash
   git clone https://github.com/krishnakumar-2001/a1-battery-billing-app.git
   cd a1-battery-billing-app
   ```
3. **Install Dependencies**:
   ```bash
   flutter pub get
   ```
4. **Create a Feature Branch**:
   ```bash
   git checkout -b feature/your-feature-name
   ```

### Code Quality Standards

Before committing, ensure your code adheres to project formatting and passes all static checks and tests:

```bash
# Analyze code for warnings and lint issues
flutter analyze

# Run the complete automated test suite
flutter test
```

### Commit Guidelines

Follow [Conventional Commits](https://www.conventionalcommits.org/):
- `feat:` New functionality
- `fix:` Bug fix
- `docs:` Documentation improvements
- `refactor:` Code refactoring without behavior change
- `test:` Adding or updating tests
- `chore:` Tooling, dependencies, or configuration updates

### Submitting a Pull Request

1. Push your branch to GitHub:
   ```bash
   git push origin feature/your-feature-name
   ```
2. Open a Pull Request against the `main` branch.
3. Provide a clear description of the changes made and link any related issues.
