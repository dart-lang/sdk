# Build V8

See [Checkout & Build V8](v8.md)

# Profile a Dart2Wasm app

```
<sdk> % <v8-repo>/tools/profiling/linux-perf-d8.py <v8-repo>/out/x64.release/d8 pkg/dart2wasm/bin/run_wasm.js -- $PWD/<file>.mjs $PWD/<file>.wasm
<sdk> % sdk/bin/dart2wasm --omit-type-checks .../benchmark.dart output.wasm
<sdk> % <v8-repo>/tools/profiling/linux-perf-d8.py <v8-repo>/out/x64.release/d8 pkg/dart2wasm/bin/run_wasm.js -- $PWD/output.mjs $PWD/output.wasm

```

See also https://v8.dev/docs/linux-perf
