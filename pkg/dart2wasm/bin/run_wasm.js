// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Runner V8 script for testing dart2wasm, takes ".wasm" files as arguments.
//
// Run as follows:
//
// $> d8 --experimental-wasm-gc --wasm-gc-js-interop run_wasm.js -- <dart_module>.wasm [<ffi_module>.wasm]
//
// If an FFI module is specified, it will be instantiated first, and its
// exports will be supplied as imports to the Dart module under the 'ffi'
// module name.

function stringFromDartString(string) {
    var length = dartInstance.exports.$stringLength(string);
    var array = new Array(length);
    for (var i = 0; i < length; i++) {
        array[i] = dartInstance.exports.$stringRead(string, i);
    }
    return String.fromCharCode(...array);
}

function stringToDartString(string) {
    var length = string.length;
    var range = 0;
    for (var i = 0; i < length; i++) {
        range |= string.codePointAt(i);
    }
    if (range < 256) {
        var dartString = dartInstance.exports.$stringAllocate1(length);
        for (var i = 0; i < length; i++) {
            dartInstance.exports.$stringWrite1(dartString, i, string.codePointAt(i));
        }
        return dartString;
    } else {
        var dartString = dartInstance.exports.$stringAllocate2(length);
        for (var i = 0; i < length; i++) {
            dartInstance.exports.$stringWrite2(dartString, i, string.codePointAt(i));
        }
        return dartString;
    }
}

// Imports for printing and event loop
var dart2wasm = {
    printToConsole: function(string) {
        console.log(stringFromDartString(string))
    },
    scheduleCallback: function(milliseconds, closure) {
        setTimeout(function() {
            dartInstance.exports.$call0(closure);
        }, milliseconds);
    },
    getCurrentStackTrace: function() {
        // [Error] should be supported in most browsers.
        // A possible future optimization we could do is to just save the
        // `Error` object here, and stringify the stack trace when it is
        // actually used.
        let stackString = new Error().stack.toString();

        // We remove the last three lines of the stack trace to prevent including
        // `Error`, `getCurrentStackTrace`, and `StackTrace.current` in the
        // stack trace.
        let userStackString = stackString.split('\n').slice(3).join('\n');
        return stringToDartString(userStackString);
    }
};

function instantiate(filename, imports) {
    // Create a Wasm module from the binary wasm file.
    var bytes = readbuffer(filename);
    var module = new WebAssembly.Module(bytes);
    return new WebAssembly.Instance(module, imports);
}

// Import from the global scope.
var importObject = (typeof window !== 'undefined')
    ? window
    : Realm.global(Realm.current());

// Is an FFI module specified?
if (arguments.length > 1) {
    // instantiate FFI module
    var ffiInstance = instantiate(arguments[1], {});
    // Make its exports available as imports under the 'ffi' module name
    importObject.ffi = ffiInstance.exports;
}

// Instantiate the Dart module, importing from the global scope.
var dartInstance = instantiate(arguments[0], importObject);

var result = dartInstance.exports.main();
if (result) console.log(result);
