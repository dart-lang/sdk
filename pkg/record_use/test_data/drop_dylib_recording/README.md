This sample builds a native library for adding and multiplying. It then uses
the recorded usages feature to tree-shake unused libraries out.

## Usage:

### Keep all:
```
devdart --enable-experiment=native-assets,record-use build bin/drop_dylib_recording_all.dart
```
The `lib/` folder now contains both libraries
```
./bin/drop_dylib_recording_all/drop_dylib_recording_all.exe add
```
Prints `Hello world: 7!`


### Treeshake:
```
devdart --enable-experiment=native-assets,record-use build bin/drop_dylib_recording_shake.dart
```
The `lib/` folder now contains only the `add` library.
```
./bin/drop_dylib_recording_shake/drop_dylib_recording_shake.exe
```
Prints `Hello world: 7!`
