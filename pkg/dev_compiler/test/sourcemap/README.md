# Testing of source maps

This folder contains a testing framework for validating the debugging behavior of the generated js.
It currently has 2 suits: One for (legacy) DDC and one for DDC with kernel (DDK).
In addition it uses a framework for testing stacktraces. This also exists in the same two
configurations.

Running the tests likely requires the compilation of the correct targets. DDK currently also
requires `ddc_sdk.dill` inside
`{sdkroot}/{out,xcodebuild}/ReleaseX64/gen/utils/dartdevc/ddc_sdk.dill`.

Except for that, running them should simply be a matter of executing the `*_suite.dart` files.

All tests are plain Dart files and goes in "testfiles" (debugging tests) or "stacktrace_testfiles"
(stacktrace tests). They are automatically picked up by the testing framework.

## Debugging tests (step tests)

These tests works in a few steps:
1) Create the JS
2) Run the JS with D8, setting instructed brakepoints etc.
3) Translating JS positions to dart positions
4) Validating the stopped at positions.

The test files themselves contain information about where to stop, which brakepoints to expect etc.
The contain this information in comments inlined in the code as in `/*key*/` where `key` can be on
of the following:

* **fail**: Will fail the test. Useful for debugging in conjunction with
`-Ddebug=true -- suite//singletest` (see below).
* **Debugger:stepOver**: Will step over breakpoints. Default (i.e. without this) is to step into.
* **bl** (break line): insert a breakpoint on this line. This does not add any new expected breaks.
* **s:{i}** (stop): adds an expected stop as the `i`th stop (1-indexed).
* **sl:{i}** (stop at line): adds an expected stop as the `i`th stop (1-indexed). Only check the
line number.
* **nb** (no break): The debugger should never break on this line.
* **nbc** (no break column): The debugger should never break on this line and column.
* **nbb:{i}:{j}** (no break between): The debugger should not break on this line between expectation
`i` and `j` (1-indexed). Note that `from` can also be the special value `0` meaning from the very
first stop. For example `nbb:0:1` means not before first expected stop.
* **nm** (no mapping): There's not allowed to be any mapping to this line.
* **bc:{i}** (break column): inserts a breakpoint at this line and column and adds an expected stop
as the `i`th stop (1-indexed).

Note that in an ideal world `bc:{i}` would not be unnecessary: Stopping at a line and stepping
should generally be enough. Because of the current behavior of d8 though, for instance
```
baz(foo(), bar())
```
will stop at `baz`, go into `foo`, stop at `bar`, go into `bar` and stop at `baz`.
From a Dart perspective we would instead expect it to stop at `foo`, go into `foo`, stop at `bar`,
go into `bar` and stop a `baz`.
Having **bc:{i}** allows us to force this behavior as d8 can actually stop at `foo` too.

All of these annotations are removed before compiling to js and the expected output thus refers to
the unannotated code.

When the test confirms that the debugger broke at the expected locations it allows for additional
breakpoints before, between and after the expected breakpoints.

## Debugging a test

One can filter which tests are run by running (from the sourcemap folder):
```
dart sourcemaps_ddc_suite.dart -- sourcemaps_ddc//printing_class_fields
```

One can additionally get debug output for failing tests (i.e. tests with different outcome than
expected), e.g.:
```
dart sourcemaps_ddc_suite.dart -Ddebug=true -- sourcemaps_ddc//printing_class_fields
```

The latter is also useful in combination with `/*fail*/` when adding new tests to see all the places
where the debugger stopped (both in JS positions and translated to dart positions).

For instance `-Ddebug=true -- sourcemaps_ddk//next_through_catch_test` with a `/*fail*/`
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

## Technical details

Some of the logic comes from https://github.com/ChromeDevTools/devtools-frontend/, for instance see
https://github.com/ChromeDevTools/devtools-frontend/blob/fa18d70a995f06cb73365b2e5b8ae974cf60bd3a/
front_end/sources/JavaScriptSourceFrame.js#L1520-L1523
for how a line breakpoint is resolved:
Basically the line asked to break on in user code (e.g. in dart code) is asked for first and last
javascript positions; these are then used to get possible breakpoints in that part. If there are
none it tries the next line (etc for a number of lines). Once it finds something (in javascript
positions) it converts that to user code position (e.g. in dart code), normalizes it by converting
to javascript position and back to user code position again, then converts to javascript position
and sets the breakpoint.
This is to some extend mimicked here when setting a line break (though not a "column break").
