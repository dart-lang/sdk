# Auto-snapshotting

IMPORTANT: memory snapshots should not be requested from external users because they may contain PII.

If a user reports that the process `dart:analysis_server.dart.snapshot` takes too much memory,
and the issue is hard to reproduce, you may want to request memory snapshots from the user.

## Request numbers

Ask user to provide memory footprint for the process `dart:analysis_server.dart.snapshot`.
If there are many instances of the process, ask for the biggest memory footprint among
the instances.

- **Mac**: column 'Real Mem' in 'Activity Monitor'
- **Windows**: TODO: add content
- **Linux**: TODO: add content

## Create auto-snapshotting argument

Based on the reported and expected values, construct auto-snapshotting argument. See example in
the [test file](../../../../test/utilities/usage_tracking/usage_tracking_test.dart), the
constant `_autosnapshottingArg`.

See explanation of parameters in
[documentation for AutoSnapshottingConfig](https://github.com/dart-lang/leak_tracker/blob/main/lib/src/usage_tracking/model.dart).

## Instruct user to configure analyzer

Pass the created argument to the user and instruct them to configure
analyzer.

### For VSCode

1. Open Settings > Extensions > Dart > Analyser
2. Add the argument to `Dart: Analyzer Additional Args`

### For Android Studio

1. Open Android Stusio screen 'Welcome to Android Studio'
2. Press Cmd + Shift + A
2. Type 'Registry' into search field
3. Click 'Registry...'
4. Add the argument to the value of the key 'dart.server.additional.arguments'

## Analyze snapshots

Ask user to provide the collected snapshots and analyze them.

TODO (polina-c): link DevTools documentation
