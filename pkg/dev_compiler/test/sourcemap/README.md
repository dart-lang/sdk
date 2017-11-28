This folder contains a testing framework for validating the debugging behaviour of the generated js.
It currently has 2 suits: One for (legacy) DDC and one for DDC with kernel (DDK).

Running the tests likely requires the compilation of the correct targets. DDK currently also
requires `ddc_sdk.dill` inside `./out/ReleaseX64/gen/utils/dartdevc/ddc_sdk.dill`.
This should be remedied at some point.

All tests are plain Dart files and goes in "testfiles". They are automatically picked up by the
testing framework.

The tests files should contain comments describing where to set breakpoints,
and the expected breaking positions.
This is done with comments as in `/*key*/` where `key` can be on of the following:

* **fail**: Will fail the test. Useful for debugging.
* **Debugger:stepOver**: Will step over breakpoints. Default (i.e. without this) is to step into.
* **bl** (break line): insert a breakpoint on this line. This does not add any new expected breaks.
* **s:{i}** (stop): adds an expected stop as the `i`th stop (1-indexed).
* **sl:{i}** (stop at line): adds an expected stop as the `i`th stop (1-indexed). Only check the
line number.
* **nb** (no break): The debugger should never break on this line.
* **nbc** (no break column): The debugger should never break on this line and column.
* **nbb:{i}:{j}** (no break between): The debugger should not break on this line between expectation
`i` and `j` (1-indexed). From can also be the special value 0 meaning from the beginning.
For example `nbb:0:1` means not before first expected stop.
* **nm** (no mapping): There's not allowed to be any mapping to this line.
* **bc:{i}** (break column): inserts a breakpoint at this line and column and adds an expected stop
as the `i`th stop (1-indexed).

Note that in an ideal world `bc:{i}` would be unnecessary: Stopping at a line and stepping should
generally be enough. Because of the current behaviour of d8 though, for instance
```
baz(foo(), bar())
```
will stop at `baz`, go into `foo`, stop at `bar`, go into `bar` and stop at `baz`.
From a Dart perspective we would instead expect it to stop at `foo`, go into `foo`, stop at `bar`,

go into `bar` and stop a `baz`.
Having **bc:{i}** allows us to force this behaviour as d8 can actually stop at `foo` too.


All of these annotations are removed before compiling to js and the expected output thus refers to
the unannotated code.

When the test confirms that the debugger broke at the expected locations it allows for additional
breakpoints before, between and after the expected breakpoints.

One can filter which tests are run by running (from the sourcemap folder):
```
dart sourcemaps_ddc_suite.dart -- sourcemaps_ddc//printing_class_fields
```

One can additionally get debug output for failing tests (i.e. tests with different outcome than
expected), e.g.:
```
dart sourcemaps_ddc_suite.dart -Ddebug=true -- sourcemaps_ddc//printing_class_fields
```

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
