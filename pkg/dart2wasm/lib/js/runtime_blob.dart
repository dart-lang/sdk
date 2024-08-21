// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

const jsRuntimeBlobPart1 = r'''
// Returns whether the `js-string` built-in is supported.
function detectJsStringBuiltins() {
    let bytes = [
        0,   97,  115, 109, 1,   0,   0,  0,   1,   4,   1,   96,  0,
        0,   2,   23,  1,   14,  119, 97, 115, 109, 58,  106, 115, 45,
        115, 116, 114, 105, 110, 103, 4,  99,  97,  115, 116, 0,   0
    ];
    return WebAssembly.validate(
        new Uint8Array(bytes), {builtins: ['js-string']});
}

// Compile a dart2wasm-generated Wasm module using
// `WebAssembly.compileStreaming`, with the flags needed by dart2wasm. `source`
// needs to have a type expected by `WebAssembly.compileStreaming`.
//
// Pass the output of this to `instantiate` below to instantiate the compiled
// module.
export const compileStreaming = (source) => {
    return WebAssembly.compileStreaming(
        source,
        detectJsStringBuiltins() ? {builtins: ['js-string']} : {}
    );
}

// Compile a dart2wasm-generated Wasm module using `WebAssembly.compile`, with
// the flags needed by dart2wasm. `source` needs to have a type expected by
// `WebAssembly.compileStreaming`.
//
// Pass the output of this to `instantiate` below to instantiate the compiled
// module.
export const compile = (bytes) => {
    return WebAssembly.compile(
        bytes,
        detectJsStringBuiltins() ? {builtins: ['js-string']} : {}
    );
}

// `modulePromise` is a promise to the `WebAssembly.module` object to be
//   instantiated.
// `importObjectPromise` is a promise to an object that contains any additional
//   imports needed by the module that aren't provided by the standard runtime.
//   The fields on this object will be merged into the importObject with which
//   the module will be instantiated.
// This function returns a promise to the instantiated module.
export const instantiate = async (modulePromise, importObjectPromise) => {
    let dartInstance;
''';

const jsRuntimeBlobPart3 = r'''
    // Prints to the console
    function printToConsole(value) {
      if (typeof dartPrint == "function") {
        dartPrint(value);
        return;
      }
      if (typeof console == "object" && typeof console.log != "undefined") {
        console.log(value);
        return;
      }
      if (typeof print == "function") {
        print(value);
        return;
      }

      throw "Unable to print message: " + js;
    }

    // Converts a Dart List to a JS array. Any Dart objects will be converted, but
    // this will be cheap for JSValues.
    function arrayFromDartList(constructor, list) {
      const exports = dartInstance.exports;
      const read = exports.$listRead;
      const length = exports.$listLength(list);
      const array = new constructor(length);
      for (let i = 0; i < length; i++) {
        array[i] = read(list, i);
      }
      return array;
    }

    // A special symbol attached to functions that wrap Dart functions.
    const jsWrappedDartFunctionSymbol = Symbol("JSWrappedDartFunction");

    function finalizeWrapper(dartFunction, wrapped) {
      wrapped.dartFunction = dartFunction;
      wrapped[jsWrappedDartFunctionSymbol] = true;
      return wrapped;
    }

    // Imports
    const dart2wasm = {
''';

// We break inside the 'dart2wasm' object to enable injection of methods. We
// could use interpolation, but then we'd have to escape characters.
const jsRuntimeBlobPart4 = r'''
    };

    const baseImports = {
        dart2wasm: dart2wasm,
''';

// We break inside of `baseImports` to inject internalized strings.
const jsRuntimeBlobPart5 = r'''
        Math: Math,
        Date: Date,
        Object: Object,
        Array: Array,
        Reflect: Reflect,
    };

    const jsStringPolyfill = {
        "charCodeAt": (s, i) => s.charCodeAt(i),
        "compare": (s1, s2) => {
            if (s1 < s2) return -1;
            if (s1 > s2) return 1;
            return 0;
        },
        "concat": (s1, s2) => s1 + s2,
        "equals": (s1, s2) => s1 === s2,
        "fromCharCode": (i) => String.fromCharCode(i),
        "length": (s) => s.length,
        "substring": (s, a, b) => s.substring(a, b),
    };

    dartInstance = await WebAssembly.instantiate(await modulePromise, {
        ...baseImports,
        ...(await importObjectPromise),
        "wasm:js-string": jsStringPolyfill,
    });

    return dartInstance;
}

// Call the main function for the instantiated module
// `moduleInstance` is the instantiated dart2wasm module
// `args` are any arguments that should be passed into the main function.
export const invoke = (moduleInstance, ...args) => {
  moduleInstance.exports.$invokeMain(args);
}
''';
