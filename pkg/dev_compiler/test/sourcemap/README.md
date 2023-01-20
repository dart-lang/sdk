# Testing of source maps

This folder contains two types of tests for validating sourcemaps:
the debugging behavior and the stacktrace behavior.

Running the tests requires the compilation of the correct targets. DDC currently
also requires `ddc_outline_unsound.dill` inside
`{sdkroot}/{out,xcodebuild}/{ReleaseX64,ReleaseARM64}/ddc_outline_unsound.dill`.

Except for that, running them should simply be a matter of executing the `*_suite.dart` files.

All tests are plain Dart files and goes in "testfiles" (debugging tests) or "stacktrace_testfiles"
(stacktrace tests). They are automatically picked up by the testing framework.

## Debugging tests (step tests)

See `README.md` in `pkg/sourcemap_testing`.

### Debugging a test

One can filter which tests are run by running (from the sourcemap folder):
```
dart sourcemaps_ddk_suite.dart -- sourcemaps_ddk/printing_class_fields
```

One can additionally get debug output for failing tests (i.e. tests with different outcome than
expected), e.g.:
```
dart sourcemaps_ddk_suite.dart -Ddebug=true -- sourcemaps_ddk/printing_class_fields
```

The latter is also useful in combination with `/*fail*/` when adding new tests to see all the places
where the debugger stopped (both in JS positions and translated to dart positions).

For instance `-Ddebug=true -- sourcemaps_ddk/next_through_catch_test` with a `/*fail*/`
currently gives output like the following:

```
Stop #1

test.main = function() {                            |  main() {
  try {                                             |    try {
    let value = /*STOP*/"world";                    |      var value = /*STOP*/"world";
    dart.throw(dart.str`Hello, ${value}`);          |      // Comment
  } catch (e) {                                     |      throw "Hello, $value";

Stop #2

  try {                                             |      var value = "world";
    let value = "world";                            |      // Comment
    /*STOP*/dart.throw(dart.str`Hello, ${value}`);  |      /*STOP*/throw "Hello, $value";
  } catch (e) {                                     |    }
    let st = dart.stackTrace(e);                    |    // Comment

Stop #3

    dart.throw(dart.str`Hello, ${value}`);          |    }
  } catch (e) {                                     |    // Comment
    let st = /*STOP*/dart.stackTrace(e);            |    catch (e, /*STOP*/st) {
    {                                               |      print(e);
      core.print(e);                                |      print(st);

[...]
```
