# AGENTS.md - Developer Guidelines for app_cemdo

## Project Overview
This is a Flutter mobile application (Dart) for CEMDO (a utility company app). The app provides account management, invoice viewing, supply tracking, and payment services.

## Build, Lint, and Test Commands

### Running the App
```bash
# Development build (default)
flutter run

# Development flavor
flutter run --flavor development --dart-define=FLAVOR=development

# Production flavor
flutter run --flavor production --dart-define=FLAVOR=production
```

### Linting & Analysis
```bash
# Run static analysis
flutter analyze

# Run with specific rules
dart analyze lib/
```

### Testing
```bash
# Run all tests
flutter test

# Run a single test file
flutter test test/widget_test.dart

# Run tests matching a pattern
flutter test --name "LoginScreen"

# Run tests in a specific file
flutter test test/logic/providers/auth_provider_test.dart

# Run with coverage
flutter test --coverage
```

### Building
```bash
# Build Android APK (debug)
flutter build apk --debug

# Build Android APK (release)
flutter build apk --release

# Build iOS (requires macOS)
flutter build ios --release

# Build for web
flutter build web
```

### Dependencies
```bash
# Get dependencies
flutter pub get

# Upgrade dependencies
flutter pub upgrade

# Run build_runner for code generation
dart run build_runner build
```

---

## Code Style Guidelines

### Project Structure
```
lib/
├── main.dart                    # App entry point
├── app.dart                     # App configuration
├── data/
│   ├── models/                  # Data models (User, Invoice, etc.)
│   └── services/                # API, storage, notifications
├── logic/
│   └── providers/               # State management (ChangeNotifier providers)
├── ui/
│   ├── screens/                 # Full screen widgets
│   ├── widgets/                 # Reusable UI components
│   └── utils/                   # Utility functions
└── exceptions/                  # Custom exceptions
```

### File Naming
- Use **snake_case** for all Dart files: `login_screen.dart`, `api_service.dart`
- Use **PascalCase** for class names: `class AuthProvider`, `class User`
- Use **camelCase** for variables and functions: `final userName`, `void login()`
- Use **SCREAMING_SNAKE_CASE** for constants: `const MAX_RETRY = 3`

### Imports
- Use **package imports** for internal code:
  ```dart
  import 'package:app_cemdo/data/services/api_service.dart';
  import 'package:app_cemdo/logic/providers/auth_provider.dart';
  ```
- Use **relative imports** for files in the same directory:
  ```dart
  import '../models/user_model.dart';
  ```
- Order imports: Dart SDK → External packages → Internal packages → Relative

### Dart Conventions
- **Always use type annotations** for function parameters and return types:
  ```dart
  Future<void> login(String email, String password) async { ... }
  ```
- **Prefer `final` over `var`** for immutable variables
- **Use `const` constructors** when possible
- **Use trailing commas** for better formatting
- **Prefer arrow functions** for simple single-expression functions:
  ```dart
  String get token => _token;  // Getter
  ```

### State Management (Provider)
- Providers should extend `ChangeNotifier`:
  ```dart
  class AuthProvider with ChangeNotifier { ... }
  ```
- Use dependency injection in constructors:
  ```dart
  AuthProvider({
    ApiService? apiService,
    SecureStorageService? secureStorageService,
  }) {
    _apiService = apiService ?? ApiService();
  }
  ```
- Use `notifyListeners()` after state changes

### Error Handling
- Use custom exceptions for domain-specific errors:
  ```dart
  class ApiException implements Exception {
    final String message;
    final int statusCode;
    ApiException({required this.message, required this.statusCode});
    @override
    String toString() => message;
  }
  ```
- Use `try-catch` with proper error reporting to ErrorService:
  ```dart
  try {
    final response = await _apiService.post('endpoint', body: data);
  } catch (e, stack) {
    ErrorService().reportError(e, stack, 'Context description');
    rethrow;
  }
  ```
- Use `debugPrint` for development debugging (not `print`)
- Report critical errors to Sentry via `ErrorService().reportError()`

### Models
- Use immutable models with `final` fields
- Implement `fromJson` factory constructor:
  ```dart
  factory User.fromJson(Map<String, dynamic> json) { ... }
  ```
- Implement `toJson` method for serialization
- Use `copyWith` pattern for immutable updates:
  ```dart
  User copyWith({String? name}) => User(
    name: name ?? this.name,
    ...
  );
  ```

### Testing
- Use `mocktail` for mocking (not mockito - already in pubspec.yaml)
- Follow the same directory structure as `lib/` in `test/`
- Use descriptive test names following pattern: `testWidgets 'description'`
- Wrap tested widgets with required providers:
  ```dart
  Widget createTestWidget() {
    return ChangeNotifierProvider<AuthProvider>.value(
      value: mockAuthProvider,
      child: const MaterialApp(home: MyScreen()),
    );
  }
  ```

### UI/Screens
- Use `const` constructors for StatelessWidgets when possible
- Follow Flutter material design guidelines
- Use `Scaffold.of(context)` pattern for SnackBars
- Handle loading states with `CircularProgressIndicator`

### Additional Notes
- Environment variables are loaded from `.env.development` and `.env.production`
- Use `dotenv` package for environment configuration
- Firebase is configured for notifications and messaging
- Sentry is integrated for error tracking

---

## VS Code Configuration
The project includes launch configurations for different flavors in `.vscode/launch.json`:
- `app_cemdo_development` - Development flavor
- `app_cemdo_production` - Production flavor
