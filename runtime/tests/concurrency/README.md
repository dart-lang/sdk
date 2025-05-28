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

`stress_test_list.json`: Contains a list of tests that can be used to generate a
stress test.

The stress test is run on the `iso-stress-linux-arm64` and 
`iso-stress-linux-x64` builders.
