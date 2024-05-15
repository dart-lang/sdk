# Building Dart2Wasm

To build dart2wasm for local running & testing we use
```
% tools/build.py -mrelease -ax64 dart2wasm
```

This will

* generate `out/ReleaseX64/dart2wasm_platform.dill`
* make an AOT snapshot of the dart2wasm compiler itself

## Building Dart2Wasm as part of the Dart SDK build

Building the Dart SDK with

```
% tools/build.py -mrelease -ax64 create_sdk
```

will allow you to run the compiler via `dart compile wasm`.

# Local development

For local development one can use two helper scripts to compile & run wasm apps:
```
% pkg/dart2wasm/tool/compile_benchmark -O0 -g app.dart app.wasm
% pkg/dart2wasm/tool/run_benchmark --d8 app.wasm
```

This will

* compile `app.dart` with dart2wasm
* will not run binaryen/wasm-opt for wasm2wasm optimizations (due to `-O0`)
* will keep name section for debugging / profiling (due to `-g`)
* run the app in D8

(The reason those scripts have "benchmark" in their name is historic - due to
them also being used by golem)

(The compilation can also be done using `dart compile wasm` which accepts
similar flags to `compile_benchmark`)

## Run dart2wasm from source

To avoid re-building with `tools/build.py ... dart2wasm` one run the compiler
from source:

* Use `pkg/dart2wasm/tool/compile_benchmark --src ...`
* Use `pkg/dart2wasm/tool/compile_benchmark --src --compiler-asserts ...`


# Testing Dart2Wasm

One can run dart2wasm tests as usual with
```
# Takes approval database into account
% dart tools/test.dart -n dart2wasm-linux-(optimized-){d8,jsc,jsshell}

# Takes only status files into account
% tools/test.py -n dart2wasm-linux-(optimized-){d8,jsc,jsshell}
```

The test framwork will use the same two scripts to compile & run (
`pkg/dart2wasm/tool/{compile,run}_benchmark`) as

(The test framework can be asked to use `dart compile wasm` from the SDK
instead using `--use-sdk` (or update in `tools/bots/test_matrix.json`))

