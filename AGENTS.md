# Repository Guidelines

## Project Structure & Module Organization

AeroLoop is a native macOS SwiftUI app generated with XcodeGen. Edit `project.yml` when targets, dependencies, build settings, or source membership change, then regenerate `AeroLoop.xcodeproj`.

- `AeroLoop/App`: app entry point and shared app state.
- `AeroLoop/Core`: wallpaper window, playback engine, and video player integration.
- `AeroLoop/Models`: domain types such as wallpapers, playlists, and display/quality modes.
- `AeroLoop/Services`: persistence, metadata, battery/fullscreen detection, and library services.
- `AeroLoop/Views`: SwiftUI menu bar, settings, onboarding, library, and preview UI.
- `AeroLoop/Resources`: entitlements and asset catalogs.
- `AeroLoopSaver`: macOS screen saver bundle that reuses selected app types.

## Build, Test, and Development Commands

- `xcodegen generate`: regenerate the Xcode project from `project.yml`.
- `open AeroLoop.xcodeproj`: open the generated project for local development.
- `xcodebuild -project AeroLoop.xcodeproj -scheme AeroLoop -configuration Debug -destination 'platform=macOS' build`: build the app from the command line.
- `xcodebuild -list -project AeroLoop.xcodeproj`: inspect available targets and schemes.

The project requires macOS 13+ and Xcode 15+. GRDB is resolved through Swift Package Manager.

## Coding Style & Naming Conventions

Use standard Swift 5.9 conventions: four-space indentation, `UpperCamelCase` for types, `lowerCamelCase` for methods/properties, and focused files named after their primary type. Keep playback and desktop-window behavior in `Core`, stateful integrations in `Services`, domain data in `Models`, and SwiftUI composition in `Views`. Use `// MARK: -` sparingly to separate meaningful sections. Avoid introducing analytics or network behavior; the app is intended to stay local-first.

## Testing Guidelines

There is no test target in this checkout yet. When adding tests, add an XCTest target in `project.yml`, place tests under `AeroLoopTests`, and name files after the unit under test, for example `SettingsManagerTests.swift`. Prefer focused unit tests for models and services; use UI tests only for workflows that cannot be covered below the UI layer.

## Commit & Pull Request Guidelines

This checkout does not include `.git` history, so no repository-specific commit pattern can be inferred. Use short, imperative commit subjects such as `Add playlist persistence` or `Fix fullscreen pause detection`. Pull requests should include a concise description, linked issue or discussion when applicable, test/build results, and screenshots or screen recordings for visible UI changes.

## Security & Configuration Tips

Do not commit personal Xcode user data, build outputs, signing assets, or local media. The screen saver reads shared wallpaper state from `/Users/Shared/AeroLoop`; treat changes to that path and sandbox entitlements as security-sensitive.
