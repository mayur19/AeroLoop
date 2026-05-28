# Contributing to AeroLoop

First off, thank you for considering contributing to AeroLoop! It's people like you that make open source such a great community.

## How to Contribute

### 1. Fork & Clone
1. Fork the repository on GitHub.
2. Clone your fork locally: `git clone https://github.com/YOUR-USERNAME/AeroLoop.git`
3. Open `AeroLoop.xcodeproj` or run `xcodegen generate` if the project file is out of sync.

### 2. Branching Strategy
Create a new branch for your feature or bugfix:
`git checkout -b feature/your-feature-name`
or
`git checkout -b fix/your-bugfix-name`

### 3. Development Guidelines
- **Swift Conventions:** Follow standard Swift 5.9 styling. Use 4-space indentation.
- **Architecture:** Keep UI code in `Views`, business logic in `Services`, data representation in `Models`, and playback logic in `Core`. (See `ARCHITECTURE.md` for more details).
- **App Sandbox:** AeroLoop is a sandboxed Mac app. Do not introduce arbitrary file system writes outside of the App Group container (`SharedPaths`).

### 4. Submitting a Pull Request
Once your changes are ready and tested:
1. Push your branch to your fork: `git push origin feature/your-feature-name`
2. Open a Pull Request (PR) against the `main` branch of the upstream AeroLoop repository.
3. Provide a clear description of what the PR solves or adds. Include screenshots or screen recordings for UI changes.

### 5. Review Process
The repository maintainers will review your PR. They may ask for changes or clarifications. Once approved, your PR will be merged into the `main` branch. 
*Note: Only maintainers can merge PRs into `main`. Direct pushes to `main` are disabled.*

## Reporting Issues
If you find a bug or have a feature request, please open an Issue on GitHub. Include your macOS version, AeroLoop version, and steps to reproduce the bug if applicable.
