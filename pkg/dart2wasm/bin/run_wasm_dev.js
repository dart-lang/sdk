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
//       -- /abs/path/to/wasm_dev_rt.mjs wasm_dev_rt.wasm <dart_module>.wasm ...
//
// Adapted from `pkg/dart2wasm/bin/run_wasm.js`.

const devRuntimeJsArg = 0;
const devRuntimeWasmArg = 1;
const firstWasmArg = 2;

let args = Array.from(arguments);
const argsSplit = args.indexOf('--');
if (argsSplit != -1) {
  args = args.slice(0, argsSplit);
}

const main = async () => {
  const devRuntimeJs = await import(args[devRuntimeJsArg]);
  const compiledDevRuntime =
    await devRuntimeJs.compile(readbuffer(args[devRuntimeWasmArg]));
  const devRuntimeApp = await compiledDevRuntime.instantiate({});

  const importObject = {
    wasm_dev_rt: devRuntimeApp.instantiatedModule.exports,
  };
  const moduleInstances = [];
  for (let i = firstWasmArg; i < args.length; i++) {
    const compiledModule = await WebAssembly.compile(readbuffer(args[i]), {
      builtins: ['js-string'],
      importedStringConstants: '',
    });
    moduleInstances.push(
      await WebAssembly.instantiate(compiledModule, importObject),
    );
  }
  moduleInstances[0].exports.main();
};

main().catch((e) => {
  print(e);
  quit(1);
});
