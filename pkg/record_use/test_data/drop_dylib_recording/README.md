This sample builds a native library for adding and multiplying. It then uses
the recorded usages feature to tree-shake unused libraries out.

## Usage:

### Keep all:
```
dart --enable-experiment=record-use build bin/drop_dylib_recording_all.dart
```
The `lib/` folder now contains both libraries
```
./bin/drop_dylib_recording_all/drop_dylib_recording_all.exe add
```
Prints `Hello world: 7!`


### Treeshake using calls:
```
dart --enable-experiment=record-use build bin/drop_dylib_recording_calls.dart
```
The `lib/` folder now contains only the `add` library.
```
./bin/drop_dylib_recording_calls/drop_dylib_recording_calls.exe
```
Prints `Hello world: 7!`

### Treeshake using instances:
```
dart --enable-experiment=record-use build bin/drop_dylib_recording_instances.dart
```
The `lib/` folder now contains only the `add` library.
```
./bin/drop_dylib_recording_calls/drop_dylib_recording_instances.exe
```
Prints `Hello world: 7!`
