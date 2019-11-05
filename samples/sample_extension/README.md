This directory contains samples of native extensions.

To run the samples, first build both the Dart SDK and the runtime. For example:

```
$ ./tools/build.py create_sdk runtime
```

Then execute the sample programs. For example:

```
$ xcodebuild/ReleaseX64/dart samples/sample_extension/test/sample_extension_test.dart
```
