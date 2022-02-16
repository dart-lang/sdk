// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Runner V8 script for testing dart2wasm, takes ".wasm" file as argument.
// Run as follows:
//
// $> d8 --experimental-wasm-gc --wasm-gc-js-interop run_wasm.js -- <file_name>.wasm

function stringFromDartString(string) {
    var length = inst.exports.$stringLength(string);
    var array = new Array(length);
    for (var i = 0; i < length; i++) {
        array[i] = inst.exports.$stringRead(string, i);
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
        var dartString = inst.exports.$stringAllocate1(length);
        for (var i = 0; i < length; i++) {
            inst.exports.$stringWrite1(dartString, i, string.codePointAt(i));
        }
        return dartString;
    } else {
        var dartString = inst.exports.$stringAllocate2(length);
        for (var i = 0; i < length; i++) {
            inst.exports.$stringWrite2(dartString, i, string.codePointAt(i));
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
            inst.exports.$call0(closure);
        }, milliseconds);
    }
};

// Create a Wasm module from the binary wasm file.
var bytes = readbuffer(arguments[0]);
var module = new WebAssembly.Module(bytes);

// Instantiate the Wasm module, importing from the global scope.
var importObject = (typeof window !== 'undefined')
    ? window
    : Realm.global(Realm.current());
var inst = new WebAssembly.Instance(module, importObject);

var result = inst.exports.main();
if (result) console.log(result);
