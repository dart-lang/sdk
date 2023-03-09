// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Runner V8 script for testing dart2wasm, takes ".wasm" files as arguments.
//
// Run as follows:
//
// $> d8 --experimental-wasm-gc --experimental-wasm-stack-switching \
//       --experimental-wasm-type-reflection run_wasm.js \
//       -- /abs/path/to/<dart_module>.mjs <dart_module>.wasm [<ffi_module>.wasm]
//
// Please note we require an absolute path for the JS runtime. This is a
// workaround for a discrepancy in D8. Specifically, `import`(used to load .mjs
// files) searches for imports relative to run_wasm.js, but `readbuffer`(used to
// read in .wasm files) searches relative to CWD.  A path relative to
// `run_wasm.js` will also work.
//
// Or with the `run_dart2wasm_d8` helper script:
//
// $> sdk/bin/run_dart2wasm_d8 <dart_module>.wasm [<ffi_module>.wasm]
//
// If an FFI module is specified, it will be instantiated first, and its
// exports will be supplied as imports to the Dart module under the 'ffi'
// module name.
const jsRuntimeArg = 0;
const wasmArg = 1;
const ffiArg = 2;

// We would like this itself to be a ES module rather than a script, but
// unfortunately d8 does not return a failed error code if an unhandled
// exception occurs asynchronously in an ES module.
const main = async () => {
    const dart2wasm = await import(arguments[jsRuntimeArg]);
    function compile(filename) {
        // Create a Wasm module from the binary wasm file.
        var bytes = readbuffer(filename);
        return new WebAssembly.Module(bytes);
    }

    function instantiate(filename, imports) {
        return new WebAssembly.Instance(compile(filename), imports);
    }

    globalThis.window ??= globalThis;

    let importObject = {};

    // Is an FFI module specified?
    if (arguments.length > 2) {
        // instantiate FFI module
        var ffiInstance = instantiate(arguments[ffiArg], {});
        // Make its exports available as imports under the 'ffi' module name
        importObject.ffi = ffiInstance.exports;
    }

    // Instantiate the Dart module, importing from the global scope.
    var dartInstance = await dart2wasm.instantiate(Promise.resolve(compile(arguments[wasmArg])), Promise.resolve(importObject));

    // Call `main`. If tasks are placed into the event loop (by scheduling tasks
    // explicitly or awaiting Futures), these will automatically keep the script
    // alive even after `main` returns.
    await dart2wasm.invoke(dartInstance);
};
main();
