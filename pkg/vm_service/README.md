[![pub package](https://img.shields.io/pub/v/vm_service.svg)](https://pub.dev/packages/vm_service)
[![package publisher](https://img.shields.io/pub/publisher/vm_service.svg)](https://pub.dev/packages/vm_service/publisher)

A library to access the VM Service Protocol.

## Usage

See the
[example](https://github.com/dart-lang/sdk/blob/main/pkg/vm_service/example/vm_service_tester.dart)
for a simple use of the library's API.

The VM Service Protocol spec can be found at
[github.com/dart-lang/sdk/runtime/vm/service/service.md](https://github.com/dart-lang/sdk/blob/main/runtime/vm/service/service.md).

## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: https://github.com/dart-lang/sdk/issues

## Running tests locally

1. Build the SDK
    ```
    gclient sync -D && \
    ./tools/build.py -ax64 create_sdk
    ```
    Note: for a release build, add the `-mrelease` flag: `./tools/build.py -mrelease -ax64 create_sdk`

2. Run the tests

    - To run all the tests: `python3 tools/test.py [ -mdebug | -mrelease ] -ax64 -j4 pkg/vm_service`

    - To run a single test: `dart pkg/vm_service/test/<test_name>.dart`
