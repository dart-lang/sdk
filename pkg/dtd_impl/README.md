# Dart Tooling Daemon

The server implementation for the Dart Tooling Daemon. This is meant to be run
by our internal tooling and facilitates communication between our internal
tools.

For details on the protocol used to communicate with the Dart Tooling Daemon see
[The DTD Protocol](./dtd_protocol.md)

## Running the Dart Tooling Daemon

### Compiled version

To run the tooling daemon compiled with the Dart SDK:

1. [Build the Dart SDK](https://github.com/dart-lang/sdk/wiki/Building)

- make sure to build with `create_platform_sdk`
- e.g. `./tools/build.py create_platform_sdk`

2. run `dart tooling-daemon`
    > :info The dart binary should be the one you just built in step 1.

### Testing changes locally

To quickly test changes to the tooling daemon, start it by running:

```bash
dart run bin/dtd.dart
```

## Running tests

To run the tests under the `test/` directory, run `dart test test/`.

However, if you are testing changes that span `pkg/dtd` and `pkg/dtd_impl`,
you'll need to build the Dart SDK, and then use the built Dart executable to run
the test.

1. Build the Dart SDK: `./tools/build.py create_platform_sdk`
2. Run the test: `xcodebuild/ReleaseARM64/dart-sdk/bin/dart test test/`
