# Inspecting the generated Wasm code

## Using the compiler itself

The compiler allows printing the Wasm code for all functions by using
`--print-wasm`
```
pkg/dart2Wasm/tool/compile_benchmark --compiler-asserts --print-wasm app.dart app.wasm
```

## Use `wami` to inspect Wasm files

The V8 repository contains a `wami` tool to inspect Wasm files.

First ensure you [Checkout & Build V8](v8.md). That will result in a
`out/x64.release/wami` binary.

Consider putting it into `PATH` or adding an
`alias wami=<path-to-v8>/out/x64.release/wami` into shellrc.

### Inspect sections of Wasm file

It can be used to dump section statistics
```
% wami --section-stats -o app.stats app.wasm
```

### Inspect contents of Wasm file

It can be used to dump the entire Wasm file with or without offsets
```
% wami --offsets --full-wat -o app.wat app.wasm
% wami --full-wat -o app.wat app.wasm
```

