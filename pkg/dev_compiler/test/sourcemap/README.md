This folder contains a testing framework for validating the debugging behaviour of the generated js.
It currently has 2 suits: One for (legacy) DDC and one for DDC with kernel (DDK).

Running the tests likely requires the compilation of the correct targets. DDK currently also
requires `ddc_sdk.dill` inside `./out/ReleaseX64/gen/utils/dartdevc/ddc_sdk.dill`.
This should be remedied at some point.

This framework borrows some things from the dart2js testing and is something that dart2js could
probably also start utilizing at some point.
Eventually things will likely move to a shared location.

All tests are plain Dart files and goes in "testfiles". They are automatically picked up by the
testing framework.

The tests files should contain comments describing where to set breakpoints,
and the expected breaking positions.
This is done with comments as in
```
/*key*/
```
where `key` can be on of the following:
* **bl** (break line): insert a breakpoint on this line. This does not add any new expected breaks.
* **s:{i}** (stop): adds an expected stop as the `i`th stop.
* **bc:{i}** (break column): inserts a breakpoint at this line and column.
* **nb** (no break): The debugger should never break on this line.
* **nm** (no mapping): There's not allowed to be any mapping to this line.
This also adds an expected stop as the `i`th stop.
Note that in an ideal world this would be unnecessary: Stopping at a line and stepping should
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
