# Example usage of package:wasm

This example demonstrates how to use package:wasm to run a wasm build of the [Brotli compression library](https://github.com/google/brotli).

### Running the example

`dart brotli.dart lipsum.txt`

This will compress lipsum.txt, report the compression ratio, then decompress it and verify that the result matches the input.

### Generating wasm code

libbrotli.wasm was built by cloning the [Brotli repo](https://github.com/google/brotli), and compiling it using [wasienv](https://github.com/wasienv/wasienv).

There are several ways of building wasm code. The most important difference between the tool sets is how the wasm code they generate interacts with the OS. For very simple code this difference doesn't matter. But if the library does any sort of OS interaction, such as file IO, or even using malloc, it will need to use either Emscripten or WASI for that interaction. package:wasm only supports WASI at the moment.

To target WASI, one option is to use [wasi-libc](https://github.com/WebAssembly/wasi-libc) and a recent version of clang. Set the target to `--target=wasm32-unknown-wasi` and the `--sysroot` to wasi-libc.

Another option is to build using [wasienv](https://github.com/wasienv/wasienv), which is a set of tools that are essentially just an ergonomic wrapper around the clang + wasi-libc approach. This is how libbrotli.wasm was built:

1. Install [wasienv](https://github.com/wasienv/wasienv) and clone the [Brotli repo](https://github.com/google/brotli).
2. Compile every .c file in brotli/c/common/, dec/, and enc/, using wasicc:
`wasicc -c foo.c -o out/foo.o -I c/include`
3. Link all the .o files together using wasild:
`wasild --no-entry --export=bar out/foo.o $wasienv_sysroot/lib/wasm32-wasi/libc.a`
The `--no-entry` flag tells the linker to ignore the fact that there's no `main()` function, which is important for libraries.
`--export=bar` will export the `bar()` function from the library, so that it can be found by package:wasm. For libbrotli.wasm, every function in c/include/brotli/encode.h and decode.h was exported.
Brotli used functions from libc, so the wasm version of libc that comes with wasienv was also linked in.
If there are still undefined symbols after linking in the wasi libraries, the `--allow-undefined` flag tells the linker to treat undefined symbols as function imports. These functions can then be supplied from Dart code.
