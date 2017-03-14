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

1. [Build](https://github.com/dart-lang/sdk/wiki/Building#building) the VM and patched SDK. Note: you only need to build the targets `runtime_kernel`, and `dart_precompiled_runtime`, so you only need to run this command:

```bash
./tools/build.py --mode release --arch x64 runtime_kernel dart_precompiled_runtime
```

## Create an Outline File

1. Run `./pkg/front_end/tool/fasta outline pkg/compiler/lib/src/dart2js.dart`

2. Optionally, run `./pkg/front_end/tool/fasta dump-ir pkg/kernel/bin/dump.dart pkg/compiler/lib/src/dart2js.dart.dill` to view the generated outline.

This will generate a file named `pkg/compiler/lib/src/dart2js.dart.dill` which contains a serialized representation of the input program excluding method bodies. This is similar to an analyzer summary.


## Create a Platform Dill File

A `platform.dill` is a dill file that contains the Dart SDK platform libraries.

```bash
./pkg/front_end/tool/fasta compile-platform platform.dill
```

## Compiling a Program

```bash
./pkg/front_end/tool/fasta compile pkg/front_end/test/fasta/hello.dart
```

This will generate `pkg/front_end/test/fasta/hello.dart.dill` which can be run this way:

```bash
./sdk/bin/dart pkg/front_end/test/fasta/hello.dart.dill
```

### Using dartk and the Analyzer AST

```bash
./pkg/front_end/tool/fasta analyzer-compile pkg/front_end/test/fasta/hello.dart
```

This will generate `pkg/front_end/test/fasta/hello.dart.dill` which can be run this way:

```bash
./sdk/bin/dart pkg/front_end/test/fasta/hello.dart.dill
```

## Running Tests

See [How to test Fasta](TESTING.md)

## Running dart2js

```bash
./pkg/front_end/tool/fasta compile pkg/compiler/lib/src/dart2js.dart
./sdk/bin/dart pkg/compiler/lib/src/dart2js.dart.dill pkg/front_end/test/fasta/hello.dart
```

The output of dart2js will be `out.js`, and it can be run on any Javascript engine, for example, d8 which is included with the Dart SDK sources:

```
./third_party/d8/<OS>/d8 out.js
```

Where `<OS>` is one of `linux`, `macos`, or `windows`.
