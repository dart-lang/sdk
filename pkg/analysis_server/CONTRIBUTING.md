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
./tools/test.py -mrelease pkg/analysis_server/test/integration/
```


[building]: https://github.com/dart-lang/sdk/wiki/Building
[contributing]: https://github.com/dart-lang/sdk/wiki/Contributing
