# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Flutter multiplatform application called "info_class" with Firebase integration. The project supports web, iOS, Android, macOS, Windows, and Linux platforms.

## Development Commands

### Build and Run
- `flutter run` - Run the app on connected device/simulator
- `flutter run -d web-server` - Run web version
- `flutter run -d chrome` - Run in Chrome browser
- `flutter build web` - Build for web deployment
- `flutter build apk` - Build Android APK
- `flutter build ios` - Build for iOS (requires macOS)

### Testing and Quality
- `flutter test` - Run unit and widget tests
- `flutter analyze` - Run static analysis and linting
- `flutter pub get` - Install dependencies
- `flutter pub upgrade` - Upgrade dependencies
- `flutter doctor` - Check Flutter installation and dependencies

### Platform-Specific
- `flutter run -d macos` - Run on macOS
- `flutter run -d windows` - Run on Windows
- `flutter run -d linux` - Run on Linux

## Architecture

### Core Structure
- **lib/main.dart** - Entry point with basic Material App setup and counter demo
- **lib/firebase_options.dart** - Firebase configuration for all platforms (currently web-only)
- **pubspec.yaml** - Dependencies including firebase_core

### Firebase Integration
The project includes Firebase setup with configurations for web platform. Firebase options are centralized in `firebase_options.dart` with platform-specific configurations. Currently only web platform is fully configured - other platforms will throw UnsupportedError until properly configured via FlutterFire CLI.

### Platform Support
The project is configured for all Flutter-supported platforms with complete folder structure for:
- Web (primary configured platform)
- iOS/macOS with Xcode projects and Podfiles
- Android with native structure
- Windows/Linux with CMake configurations

### Dependencies
- **firebase_core**: Firebase SDK integration
- **cupertino_icons**: iOS-style icons
- **flutter_lints**: Code quality and style enforcement

## Firebase Setup Notes

To properly configure Firebase for all platforms, run:
```bash
flutter pub global activate flutterfire_cli
flutterfire configure
```

This will update `firebase_options.dart` with platform-specific configurations and create necessary configuration files for each platform.