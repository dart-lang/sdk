# SDK development code analysis

_dartanalyzer_ used to be the tool for statically analyzing dart code
at the command line.  However, this tool [has been replaced][] with
`dart analyze` for this purpose in current SDKs and will no longer
be published on pub.

**Do not** depend on the command line interface or other semantics in
this directory as it is now an internal tool for SDK development, used
as the `dart2analyzer` "compiler" for `tools/test.py` in the SDK.
It is configured as part of the test runner,
[here](https://github.com/dart-lang/sdk/blob/main/pkg/test_runner/lib/src/compiler_configuration.dart).

## SDK development usage

For SDK development, run analysis from the test tool to validate analysis
conclusions on language samples in the testing directory.
From the root of the SDK:

```
tools/test.py --build --use-sdk -c dart2analyzer co19 language
```

This will build the Dart VM and compile dartanalyzer into a snapshot, then use
that snapshot while analyzing those directories under `testing/`.  Without
`--use-sdk`, test.py will use the source code version of the analyzer
instead of the compiled one, which can be useful for debugging.

[has been replaced]: https://github.com/dart-lang/sdk/issues/48457