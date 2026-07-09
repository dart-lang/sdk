## Contributing

Contributions welcome! Please follow the guide in [Contributing][contributing].

## Building

If you want to build Dart yourself, here is a guide to
[getting the source, preparing your machine to build the SDK, and
building][building].

There are more documents on our [wiki](https://github.com/dart-lang/sdk/wiki).
Once set up to build the SDK, run:

```
./tools/build.py -mrelease create_sdk
```

### Testing your changes against a local Flutter project

There may be times where you want to test your SDK changes locally against a
Flutter project. To do this, you can use the `copy_dart_to_flutter.dart` script
in the `sdk/tools/` directory.

To see usage information for this script, run:
```sh
dart ./tools/copy_dart_to_flutter.dart -h
```

For ease of use, consider setting the `LOCAL_DART_SDK` and `LOCAL_FLUTTER_SDK`
environment variables. Otherwise, you will need to specify these paths via the
`-d` and `-f` options when running the script. You can add the following to your
`.bash_profile` or `.zshrc` file to set the environment variables:

```sh
export LOCAL_DART_SDK='/Users/me/path/to/dart-sdk/sdk'
export LOCAL_FLUTTER_SDK='/Users/me/path/to/flutter'
```

Instructions for testing your local changes against a Flutter project:
1. Run the `copy_dart_to_flutter.dart` script.
    ```sh
    dart ./tools/copy_dart_to_flutter.dart
    ```
2. Open a Flutter project in your IDE and restart the Analysis Server to test
your changes.

## Running tests

To run analyzer tests:

```
./tools/test.py -mrelease pkg/analyzer/test/
```

To run all analysis server tests:

```
./tools/test.py -mrelease pkg/analysis_server/test/
```

To run just the analysis server integration tests:

```
./tools/test.py -mrelease pkg/analysis_server/integration_test/
```

To run a single test:

```
dart test pkg/analysis_server/test/some_test.dart
```

> Note: `dart` may need to point to a Dart SDK built from source
depending on the changes you are testing.

[building]: https://github.com/dart-lang/sdk/wiki/Building
[contributing]: https://github.com/dart-lang/sdk/blob/master/CONTRIBUTING.md
