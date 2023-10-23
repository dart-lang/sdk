# Contributing to `package:vm_service` and `package:vm_service_interface`

## Updating the VM service version

To update `package:vm_service` and `package:vm_service_interface` to support the latest version of the [VM service protocol](https://github.com/dart-lang/sdk/blob/main/runtime/vm/service/service.md), run the following script to regenerate the client and interface:

`dart tool/generate.dart`

## Updating the code generator

Both `package:vm_service` and `package:vm_service_interface` make use of code generation to generate much of their implementations. As a result, manual changes made to some files (e.g., `package:vm_service/src/vm_service.dart` and `package:vm_service_interface/src/vm_service_interface.dart`) will be overwritten by the code generator.

To make changes to the generated files, make changes in one or more of the following files:

- `tool/dart/generate_dart_client.dart` for code specific to `package:vm_service`
- `tool/dart/generate_dart_interface.dart` for code specific to `package:vm_service_interface`
- `tool/dart/generate_dart_common.dart` for code common to `package:vm_service` and `package:vm_service_interface`

## Running tests locally

### 1. Build the SDK

From the root of the Dart SDK, run the following commands:

    gclient sync -D && \
    python3 tools/build.py -ax64 create_sdk

Note: for a release build, add the `-mrelease` flag: `./tools/build.py -mrelease -ax64 create_sdk`

### 2. Run the tests

To run all the tests: `python3 tools/test.py [ -mdebug | -mrelease ] -ax64 -j4 pkg/vm_service`

To run a single test: `dart pkg/vm_service/test/<test_name>.dart`