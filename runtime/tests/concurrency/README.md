This directory contains code to produce a large isolate stress test. It has the
following helper files:

`generate_stress_test_list.dart`: Will recursively walk test suite
directories, tries to run tests and see whether they could be included as part
of the stress test.

Only tests that are passing, run reasonably quick and don't use features that
prevent running them inside isolates will be considered.

=> The filtered tests that are considered will be written into
`stress_test_list.json`.

The resulting `stress_test_list.json` file was hand-edited afterwards to remove
certain tests that have passed the simple automated filter but cannot be used
as part of the stress test.

`generate_stress_test.dart`: Can be used to consume `stress_test_list.json` and
build the stress test files.

`stress_test_list.json`: Contains two lists of tests (one for NNBD and one for
non-NNBD) that can be used to generate a stress test.

To ensure the list doesn't get out-of-date we have two tests on regular bots
that will try to compile the stress test to kernel, thereby ensuring that the
files at least exist and compile, see
`runtime/tests/vm/dart/isolates/concurrency_stress_sanity_test.dart`.
