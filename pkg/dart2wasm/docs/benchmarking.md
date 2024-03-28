# Get V8 checkout

Assuming `depot_tools` is installed and in `PATH`:

### Get V8 source

```
% mkdir v8-gclient && cd v8-gclient
v8-gclient % fetch v8 && cd v8
v8-gclient/v8 % tools/dev/gm.py x64.release
<may fail but will generate out/x64.release/args.gn>
...
```

See also https://v8.dev/docs/source-code
See also https://v8.dev/docs/build

### Build V8 With

```
v8-gclient/v8 % vim out/x64.release/args.gn
...
enable_profiling = true
use_goma = false
use_remoteexec = false
...
v8-gclient/v8 % autoninja -C out/x64.release
...
```

See also https://v8.dev/docs/linux-perf

### Profile a Dart2Wasm app

```
<sdk> % <v8-repo>/tools/profiling/linux-perf-d8.py <v8-repo>/out/x64.release/d8 pkg/dart2wasm/bin/run_wasm.js -- $PWD/<file>.mjs $PWD/<file>.wasm
<sdk> % sdk/bin/dart2wasm --omit-type-checks .../benchmark.dart output.wasm
<sdk> % <v8-repo>/tools/profiling/linux-perf-d8.py <v8-repo>/out/x64.release/d8 pkg/dart2wasm/bin/run_wasm.js -- $PWD/output.mjs $PWD/output.wasm

```

See also https://v8.dev/docs/linux-perf
