# Adding a new pubspec diagnostic

This document describes the process of adding a new (non-lint) pubspec
diagnostic to the analyzer.

## Background

Analyzer parses pubspecs and sends change notifications to a validator that can
be used to produce diagnostics in pubspec.yaml files. Taking advantage of this
we can provide rich dynamic feedback to authors as they type.

## Recipe

The basic recipe for implementing a new pubspec diagnostic is as follows:

1. Introduce a new `PubspecWarningCode` code to `messages.yaml`.
2. Re-generate Dart error code files (run `generate_files`).
3. Add corresponding tests to a new test library in
   `test/src/pubspec/diagnostics`.
4. Implement analysis in a new validator in `lib/src/pubspec/validators` and
   add it to list of validators in `pubspec_validator.dart`
   (or enhance an existing one).

Once implemented, you’ll want to look for ecosystem breakages. Useful bots to
watch:

* [analyzer-analysis-server-linux-try][]
  analyzes SDK packages and is a great early warning system
* [flutter-analyze-try][] and
* [flutter-engine-linux-try][]
  will tell you if your change will block an SDK roll into Flutter

[analyzer-analysis-server-linux-try](https://ci.chromium.org/p/dart/builders/ci.sandbox/analyzer-analysis-server-linux)
[flutter-analyze-try](https://ci.chromium.org/p/dart/builders/ci.sandbox/flutter-analyze)
[flutter-engine-linux-try](https://ci.chromium.org/p/dart/builders/ci.sandbox/flutter-engine-linux)

You’ll need to clean up these downstream breakages before you can land yours.

In the case of SDK breakages, you can fix them in your initial PR. Flutter and
Flutter Engine breakages should be handled in PRs to their respective Flutter
repos.

## Example: Deprecated Fields

The introduction of diagnostics for deprecated fields (corresponding to the
existing [pub client check][]) demonstrates a lot of these ideas and serves as a
good jumping off point for future diagnostics.

[pub client check](https://github.com/dart-lang/pub/blob/ab41ef0aaef7a20f759c6147aa8121a1396ee589/lib/src/validator/deprecated_fields.dart#L18-L35)

1. The initial PR: https://dart-review.googlesource.com/c/sdk/+/204420 (notice 
   the breakage to analyzer_plugin and telemetry that needed fixing).
2. Flutter repo fixes: https://github.com/flutter/flutter/pull/84997 and 
   https://github.com/flutter/flutter/pull/85036.
