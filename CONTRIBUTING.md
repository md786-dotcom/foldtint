# Contributing

Thank you for your interest in foldtint.

This document tells you how to change the code. It also tells you how to send a pull request.

## Before you start

You need these items:

- macOS 14 or later
- Xcode Command Line Tools
- Swift 6
- Node.js 18 or later (for npm packaging only)

The project works on macOS only. You cannot build the native binary on Linux or Windows.

## Get the code

1. Fork the repository on GitHub.
2. Clone your fork to your computer.
3. Go to the project folder in a terminal.

## Build

Run this command:

```
swift build
```

Run this command for a release binary:

```
make release
```

Run this command for the npm packaging build:

```
npm run build
```

The npm build command needs macOS. It writes a prebuilt binary under `prebuilds/`.

## Test

Run this command:

```
swift test
```

Run this command for the full quality gate:

```
make quality
```

The quality script runs tests, coverage, SwiftLint, complexity checks, and a mutation sample.

## Quality rules

Your change must meet these rules:

- Test coverage is 85% or higher.
- Mutation sample score is 85% or higher.
- Cyclomatic complexity is less than 22 for each function.
- Halstead difficulty is less than 80 for each function.
- CRAP score is less than 25 for each function.
- Each Swift file has fewer than 500 lines.
- The code does not use `Any`, `AnyObject`, or `unknown`.
- SwiftLint passes with `--strict`.

Run `make quality` before you send a pull request.

## Code style

Match the style in the existing code.

- Use Swift 6.
- Keep functions small.
- Put shared logic in `FoldtintKit`.
- Put CLI wiring in `Sources/foldtint/main.swift`.
- Add tests in `Tests/FoldtintTests/`.
- Do not add comments for obvious code.

## Pull request process

1. Create a branch from `main`.
2. Make your change.
3. Run `make quality`.
4. Push your branch to your fork.
5. Open a pull request against `main`.

Write a short description in the pull request. Tell us what you changed and why.

We may ask for changes before we merge.

## Scope

foldtint works on top-level Desktop folders only. Do not add support for nested folders, files, or paths outside the Desktop unless we agree first.

The tool uses Finder tags. Do not add custom icons or hex colors unless we agree first.

## Questions

Open an issue on GitHub:

https://github.com/md786-dotcom/foldtint/issues

## License

When you send a pull request, you agree that your change uses the MIT license. See `LICENSE`.
