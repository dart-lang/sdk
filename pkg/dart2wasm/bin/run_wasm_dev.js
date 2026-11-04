// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Runner D8 script for testing dart2wasm_dev, takes ".wasm" files as
// arguments.
//
// Run as follows on D8:
//
// $> d8 run_wasm_dev.js \
//       -- /abs/path/to/wasm_dev_rt.mjs wasm_dev_rt.wasm <dart_module>.wasm
//
// Adapted from `pkg/dart2wasm/bin/run_wasm.js`.

const devRuntimeJsArg = 0;
const devRuntimeWasmArg = 1;
const wasmArg = 2;

const args = arguments;

const main = async () => {
  const devRuntimeJs = await import(args[devRuntimeJsArg]);
  const compiledDevRuntime =
    await devRuntimeJs.compile(readbuffer(args[devRuntimeWasmArg]));
  const devRuntimeApp = await compiledDevRuntime.instantiate({});

  const importObject = {
    wasm_dev_rt: devRuntimeApp.instantiatedModule.exports,
  };
  const compiledApp = await WebAssembly.compile(readbuffer(args[wasmArg]), {
    builtins: ['js-string'],
    importedStringConstants: '',
  });
  const appInstance = await WebAssembly.instantiate(compiledApp, importObject);
  appInstance.exports.main();
};

main().catch((e) => {
  print(e);
  quit(1);
});
