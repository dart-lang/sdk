<!--
Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
for details. All rights reserved. Use of this source code is governed by a
BSD-style license that can be found in the LICENSE file.
-->
# Fasta -- Fully-resolved AST, Accelerated.

Fasta is a compiler framework for compiling Dart sources to Kernel IR. When Fasta works well, you won't even know you're using it, as it will be transparently integrated in tools like *dart*, *dartanalyzer*, *dart2js*, etc.

Hopefully, you'll notice that Fasta-based tools are fast, with good error messages. If not, please let us [know](https://github.com/dart-lang/sdk/issues/new).

Fasta sounds like faster, and that's a promise we intend to keep.

## Getting Started

1. [Build](https://github.com/dart-lang/sdk/wiki/Building#building) the VM and patched SDK. Note: you only need to build the target `runtime`, so you only need to run this command:

```bash
./tools/build.py --mode release --arch x64 runtime
```

Make sure to define these environment variables, for example, by adding them to `~/.bashrc`:

```bash
# Linux
DART_SDK=<Location of Dart SDK source check out>
export DART_AOT_VM=${DART_SDK}/out/ReleaseIA32/dart
export DART_AOT_SDK=${DART_SDK}/out/ReleaseIA32/patched_sdk
```

```bash
# Mac OS X
DART_SDK=<Location of Dart SDK source check out>
export DART_AOT_VM=${DART_SDK}/xcodebuild/ReleaseIA32/dart
export DART_AOT_SDK=${DART_SDK}/xcodebuild/ReleaseIA32/patched_sdk
```

If you want to help us translate these instructions to another OS, please let us [know](https://github.com/dart-lang/sdk/issues/new).

## Create an Outline File

1. Run `dart pkg/front_end/lib/src/fasta/bin/outline.dart pkg/compiler/lib/src/dart2js.dart`

2. Optionally, run `dart pkg/kernel/bin/dartk.dart pkg/compiler/lib/src/dart2js.dart.dill` to view the generated outline.

This will generate a file named `pkg/compiler/lib/src/dart2js.dart.dill` which contains a serialized reprsentation of the input program excluding method bodies. This is similar to an analyzer summary.


## Create a Platform Dill File

A `platform.dill` is a dill file that contains the Dart SDK platform libraries. For now, this is generated with dartk until fasta reaches a higher rate of test passes.

```bash
dart pkg/front_end/lib/src/fasta/bin/compile_platform.dart platform.dill
```

Make sure to define `$DART_AOT_SDK` as described [above](#Building-The-Dart-SDK).

## Compiling a Program

```bash
dart pkg/front_end/lib/src/fasta/bin/compile.dart pkg/front_end/test/fasta/hello.dart
```

This will generate `pkg/front_end/test/fasta/hello.dart.dill` which can be run this way:

```bash
$DART_AOT_VM pkg/front_end/test/fasta/hello.dart.dill
```

Where `$DART_AOT_VM` is defined as described [above](#Building-The-Dart-SDK).

### Using dartk and the Analyzer AST

```bash
dart pkg/front_end/lib/src/fasta/bin/kompile.dart pkg/front_end/test/fasta/hello.dart
```

This will generate `pkg/front_end/test/fasta/hello.dart.dill` which can be run this way:

```bash
$DART_AOT_VM pkg/front_end/test/fasta/hello.dart.dill
```

Where `$DART_AOT_VM` is defined as described [above](#Building-The-Dart-SDK).

## Running Tests

Run:

```bash
dart -c pkg/testing/bin/testing.dart --config=pkg/front_end/test/fasta/testing.json
```

## Running dart2js

```bash
dart pkg/front_end/lib/src/fasta/bin/compile.dart pkg/compiler/lib/src/dart2js.dart
$DART_AOT_VM pkg/compiler/lib/src/dart2js.dart.dill pkg/front_end/test/fasta/hello.dart
```

The output of dart2js will be `out.js`, and it can be run on any Javascript engine, for example, d8 which is included with the Dart SDK sources:

```
./third_party/d8/<OS>/d8 out.js
```

Where `<OS>` is one of `linux`, `macos`, or `windows`.
