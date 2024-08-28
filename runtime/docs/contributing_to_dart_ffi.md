# Contributing to Dart FFI

First, go through the [general contributions guide](https://github.com/dart-lang/sdk/blob/main/CONTRIBUTING.md).


# Dart FFI architecture

Dart FFI is implemented in four main locations:

1. the `dart:ffi` library files,
2. the analyzer,
3. the CFE (common front end), and
4. the VM (virtual machine).

The `dart:ffi` library files contain the public API for `dart:ffi`.
The analyzer checks Dart code using `dart:ffi` does not contain any errors when opening an IDE or using dart analyze.
The CFE performs similar checks, but does so when running Dart code with `dart run` or compiling Dart code with `dart compile`.
If there are no errors, the CFE “transforms” or “desugars” most `dart:ffi` code into lower level concepts.
These are encoded in the kernel file.
The VM (or precompiler) takes the kernel file and compiles it into machine code.

```
     ╭─────────────╮
     │╭─────────────╮       ╔══════════╗
     ││╭─────────────╮┣━━━▶ ║ Analyzer ║ ┣━━━▶  Error messages
     ┆││ Dart Source │      ╚══════════╝
     ┆┆│             │
      ┆┆             ┆
       ┆             ┆

     ╭─────────────╮
     │╭─────────────╮       ╔═════╗
     ││╭─────────────╮┣━━━▶ ║ CFE ║ ┣━━━▶  Error messages
     ┆││ Dart Source │      ╚═════╝
     ┆┆│             │
      ┆┆             ┆
       ┆             ┆

     ╭─────────────╮                       ╭────────────╮
     │╭─────────────╮       ╔═════╗        │╭────────────╮        ╔════╗
     ││╭─────────────╮┣━━━▶ ║ CFE ║ ┣━━━▶  ││╭────────────╮ ┣━━━▶ ║ VM ║
     ┆││ Dart Source │      ╚═════╝        │││ Kernel AST │       ╚════╝
     ┆┆│             │                     ╰││ (binary)   │
      ┆┆             ┆                      ╰│            │
       ┆             ┆                       ╰────────────╯
```

The analyzer and CFE are implemented in Dart code.
The VM is implemented in C++. The analyzer and CFE are relatively easy to work on.
Working on the VM is more complicated.
So let’s focus on the analyzer and CFE first.

Most bugs/features require contributing to various parts of the implementation in the FFI.
But some bugs might be localized to for example only the analyzer.


# Contributing to the Dart FFI library files

The public API and some of the implementation is ordinary Dart code.


## Implementation files

- `sdk/lib/ffi/(.*).dart` contains the public API, it hides implementation details.
- `sdk/lib/_internal/vm/lib/ffi(.*)_patch.dart` contains the implementation details hidden from the public API.

However, many of the functions are either marked `external` or their implementation throws.
The real implementation of these functions is in the VM.


# Contributing to the Dart FFI analyzer implementation

## Documentation

Familiarize yourself with the architecture of the analyzer by reading the documentation on the [AST (abstract syntax tree)](https://github.com/dart-lang/sdk/blob/main/pkg/analyzer/doc/tutorial/ast.md) and [element model](https://github.com/dart-lang/sdk/blob/main/pkg/analyzer/doc/tutorial/element.md).


## Implementation files

- `pkg/analyzer/lib/src/generated/ffi_verifier.dart`. The whole implementation of the FFI in the analyzer is in this file.


## Test files

Unit tests

- `pkg/analyzer/test/src/diagnostics/ffi_(.*)_test.dart`. Run with `$ dart pkg/analyzer/test/src/diagnostics/ffi_native_test.dart`. These unit tests don’t require rebuilding the SDK.
- These unit tests are run against a mock SDK: `pkg/analyzer/lib/src/test_utilities/mock_sdk.dart`.

Integration tests

- `tests/ffi/static_checks/(.*)_test.dart`. Prefer creating new tests with the “new style” `// [analyzer] ...`. The tests can be run with `$ tools/build.py -mrelease runtime create_platform_sdk && tools/test.py -cfasta -mrelease tests/ffi/static_checks/vmspecific_static_checks_array_test.dart`. These tests require rebuilding the SDK. These tests also can contain `// [cfe] ...` error expectations. Which makes them good for checking that the behavior is similar in the CFE and analyzer implementation. And because these test files are standalone Dart, you can easily pass them as an argument to the analyzer when running from source in the debugger.


## Running in the debugger

If you’re using vscode, you can use the following configuration to run the analyzer from source and be able to set breakpoints.

```
      {
        "name": "dart analyzer.dart",
        "type": "dart",
        "request": "launch",
        "program": "pkg/analyzer_cli/bin/analyzer.dart",
        "args": [
          "tests/ffi/static_checks/vmspecific_static_checks_array_test.dart",
        ],
        "toolArgs": [],
        "enableAsserts": true,
        "cwd": "${workspaceFolder}",
      },
```

Replace the file under test in args as needed.

To run the unit tests in the debugger:

```
      {
        "name": "dart pkg/analyzer/test/...",
        "type": "dart",
        "request": "launch",
        "program": "pkg/analyzer/test/src/diagnostics/subtype_of_struct_class_test.dart",
        "args": [],
        "enableAsserts": true,
        "cwd": "${workspaceFolder}",
      },
```

Replace the test as needed.

## Gotcha’s

- Methods must be alphabetically sorted. Run `$ dart pkg/analysis_server/test/verify_sorted_test.dart`.


## Learning from already merged PRs

You can learn a lot from looking at previous PRs:

- [Git history of the ffi_verifier.dart](https://github.com/dart-lang/sdk/commits/main/pkg/analyzer/lib/src/generated/ffi_verifier.dart).


# Contributing to the Dart FFI CFE implementation

## Implementation files

- `pkg/vm/lib/modular/transformations/ffi/(.*).dart` contains the CFE transformations for `dart:ffi`.


## Test files

- `pkg/vm/testcases/transformations/ffi/(.*).dart` are the input files and the `.expect` files are a human readable version of kernel files. The tests can be run and their expect files updated with `$ tools/build.py -ax64 -mrelease create_platform_sdk runtime && dart -DupdateExpectations=true pkg/vm/test/transformations/ffi_test.dart`.


## Running in the debugger

Running the transformation tests from source in the debugger can be done with the following configuration.

```
      {
        "name": "dart pkg/vm/test/transformations/ffi_test.dart",
        "type": "dart",
        "request": "launch",
        "program": "pkg/vm/test/transformations/ffi_test.dart",
        "args": [
          "compound_copies",
        ],
        "toolArgs": [
          "-DupdateExpectations=true",
        ],
        "enableAsserts": true,
        "cwd": "${workspaceFolder}",
      },
```

Running the CFE on a Dart file can be done with the following configuration.

```
      {
        "name": "dart gen_kernel.dart",
        "type": "dart",
        "request": "launch",
        "program": "pkg/vm/bin/gen_kernel.dart",
        "args": [
          "--platform=${workspaceFolder}/xcodebuild/ReleaseARM64/vm_platform_strong.dill",
          "third_party/pkg/native/pkgs/ffi/test/allocation_test.dart",
        ],
        "toolArgs": [],
        "enableAsserts": true,
        "cwd": "${workspaceFolder}",
      },
```

You can read more about kernel format in the [VM readme](https://github.com/dart-lang/sdk/blob/main/runtime/docs/README.md).


# Contributing to the the Dart FFI implementation in the VM

In order to be able to work on the VM implementation of Dart FFI, you first need to familiarize yourself with the Dart VM:

- [The VM readme](https://github.com/dart-lang/sdk/blob/main/runtime/docs/README.md)
- [The VM glossary](https://github.com/dart-lang/sdk/blob/main/runtime/docs/glossary.md)


## Implementation files

- `runtime/vm/compiler/ffi/`: relatively self-contained files for the FFI. For example the logic for which registers of the CPU arguments must be passed in calls to C.
- `runtime/vm/compiler/frontend/kernel_to_il.cc`: Contains most of the IL generation.
- `runtime/vm/compiler/backend/il(.*).cc`: Contains most of the machine code generation.


## Test files

Unit tests

- `runtime/bin/ffi_unit_test/run_ffi_unit_tests.cc` and `runtime/vm/compiler/ffi/(.*)_test.cc` contains unit tests for some parts of the FFI. Run (and update) with `$ tools/build.py -mrelease run_ffi_unit_tests && tools/test.py -mrelease --vm-options=--update ffi_unit`.

Integration tests

- `tests/ffi/(.*)_test.dart` Integration tests. Run for AOT on host machine with `$ tools/build.py -mdebug create_platform_sdk runtime ffi_test_functions dart_precompiled_runtime && tools/test.py -mdebug -cdartkp ffi`. Run for JIT on host machine with `$ tools/build.py -mdebug create_platform_sdk runtime ffi_test_functions && tools/test.py -mdebug ffi`.

Test generators

- `tests/ffi/generator/(.*).dart` contains test generators. Writing tests for Dart FFI that need to cover a wide variety of slightly different cases is tedious and error prone. Instead, we prefer generating tests in such cases.


## Running in the debugger

If you’re using vscode on an Arm64 Mac you can use the following configuration. The first command is for running JIT. The second command is for precompiling AOT and the third command is for running AOT. You can find the specific commands to run by passing `-v` to the test.py invocations from above.

For Linux, use out/DebugX64 as the out directory and gdb as MIMode.

```
{
  "launch": {
    "version": "0.2.0",
    "configurations": [
      {
        "name": "ccpdbg dart",
        "type": "cppdbg",
        "request": "launch",
        "program": "${workspaceFolder}/xcodebuild/DebugARM64/dart",
        "args": [
          // "--print-flow-graph",
          // "--print-flow-graph-filter=Ffi",
          // "--disassemble",
          "tests/ffi/address_of_typeddata_generated_test.dart",
        ],
        "stopAtEntry": false,
        "cwd": "${workspaceFolder}",
        "environment": [],
        "externalConsole": false,
        "MIMode": "lldb",
        "sourceFileMap": {
          "runtime/": "${workspaceFolder}/runtime/",
        },
      },
      {
        "name": "ccpdbg gen_snapshot",
        "type": "cppdbg",
        "request": "launch",
        "program": "${workspaceFolder}/xcodebuild/DebugARM64/gen_snapshot",
        "args": [
          "--snapshot-kind=app-aot-assembly",
          "--assembly=/Users/dacoharkes/dart-sdk/sdk/xcodebuild/DebugARM64/generated_compilations/custom-configuration-4/tests_ffi_isolate_independent_il_based_global_var_test/out.S",
          "--iic-impl-il",
          "-Dtest_runner.configuration=custom-configuration-4",
          "--ignore-unrecognized-flags",
          "--packages=/Users/dacoharkes/dart-sdk/sdk/.packages",
          "/Users/dacoharkes/dart-sdk/sdk/xcodebuild/DebugARM64/generated_compilations/custom-configuration-4/tests_ffi_isolate_independent_il_based_function_call_2_test/out.dill",
        ],
        "stopAtEntry": false,
        "cwd": "${workspaceFolder}/xcodebuild/DebugARM64/",
        "environment": [],
        "externalConsole": false,
        "MIMode": "lldb",
        "sourceFileMap": {
          "../../": "${workspaceFolder}/",
        },
      },
      {
        "name": "ccpdbg dart_precompiled_runtime",
        "type": "cppdbg",
        "request": "launch",
        "program": "${workspaceFolder}/xcodebuild/DebugARM64/dart_precompiled_runtime",
        "args": [
          "/Users/dacoharkes/dart-sdk/sdk/xcodebuild/DebugARM64/generated_compilations/custom-configuration-4/runtime_tests_vm_dart_memoizable_idempotent_test/out.aotsnapshot",
        ],
        "stopAtEntry": false,
        "cwd": "${workspaceFolder}/xcodebuild/DebugARM64/",
        "environment": [],
        "externalConsole": false,
        "MIMode": "lldb",
        "sourceFileMap": {
          "../../": "${workspaceFolder}/",
        },
      },
```

## Explore the history.

You can learn a lot by exploring PRs that implement various features.

- [PRs that modify the IL generation](https://dart-review.googlesource.com/q/owner:dacoharkes@google.com+size:%3E300+kernel_to_il.cc+status:merged) for the FFI.
- [PRs that modify the machine code generation](https://dart-review.googlesource.com/q/owner:dacoharkes@google.com+size:%3E300+il_x64.cc+status:merged) for the FFI.


# What to work on.

You can look at [issues labeled ‘library:ffi’](https://github.com/dart-lang/sdk/issues?q=is%3Aopen+is%3Aissue+label%3Alibrary-ffi).
More specifically you can also apply the label [’contributions-welcome’](https://github.com/dart-lang/sdk/issues?q=is%3Aopen+is%3Aissue+label%3Acontributions-welcome).


# Preparing  PR

The first line of the commit message is usually `[vm/ffi] ...`.

If your PR modifies the running of Dart files (so not only error messages in analyzer and/or CFE), we should ensure it’s tested on all platforms.
To add all the CI bots that cover running the FFI in different configurations, you can add a footer to the commit message with the result of `$ tools/find_builders.dart ffi/function_structs_by_value_generated_args_test`.
(This only works for already existing tests, so if you’re adding a new test, you can get the list of bots from a pre-existing test, for example the one above.)

Prefer using Gerrit directly for uploading a PR rather than using pull requests via GitHub. For more info see [the Contributing guide](https://github.com/dart-lang/sdk/blob/main/CONTRIBUTING.md#uploading-the-patch-for-review).

## New tests

Any new tests need to be added to the root `BUILD.gn` `test_sources`.
This adds the test sources to the `fuchsia_component` that tests FFI on Fuchsia.
