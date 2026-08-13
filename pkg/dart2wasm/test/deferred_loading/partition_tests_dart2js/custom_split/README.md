The expectation files in this directory are how dart2wasm is expected to
partition tests into deferred parts.

The original tests are in
`pkg/compiler/test/custom_split/data/<testname>` containing

* `main.dart`: The main application to compiler
* `<helper>.dart`: Libraries `main.dart` may import
* `constraints.json`: The constraints to apply to the partitioning algorithm
