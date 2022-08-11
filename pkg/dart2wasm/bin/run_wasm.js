// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Runner V8 script for testing dart2wasm, takes ".wasm" files as arguments.
//
// Run as follows:
//
// $> d8 --experimental-wasm-gc --experimental-wasm-nn-locals --wasm-gc-js-interop run_wasm.js -- <dart_module>.wasm [<ffi_module>.wasm]
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

// Converts a Dart List to a JS array. Any Dart objects will be converted, but
// this will be cheap for JSValues.
function arrayFromDartList(constructor, list) {
    var length = dartInstance.exports.$listLength(list);
    var array = new constructor(length);
    for (var i = 0; i < length; i++) {
        array[i] = dartInstance.exports.$listRead(list, i);
    }
    return array;
}

function dataViewFromDartByteData(byteData, byteLength) {
    var dataView = new DataView(new ArrayBuffer(byteLength));
    for (var i = 0; i < byteLength; i++) {
        dataView.setUint8(i, dartInstance.exports.$byteDataGetUint8(byteData, i));
    }
    return dataView;
}

// A special symbol attached to functions that wrap Dart functions.
var jsWrappedDartFunctionSymbol = Symbol("JSWrappedDartFunction");

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
    },
    int8ArrayFromDartInt8List: function(list) {
        return arrayFromDartList(Int8Array, list);
    },
    uint8ArrayFromDartUint8List: function(list) {
        return arrayFromDartList(Uint8Array, list);
    },
    uint8ClampedArrayFromDartUint8ClampedList: function(list) {
        return arrayFromDartList(Uint8ClampedArray, list);
    },
    int16ArrayFromDartInt16List: function(list) {
        return arrayFromDartList(Int16Array, list);
    },
    uint16ArrayFromDartUint16List: function(list) {
        return arrayFromDartList(Uint16Array, list);
    },
    int32ArrayFromDartInt32List: function(list) {
        return arrayFromDartList(Int32Array, list);
    },
    uint32ArrayFromDartUint32List: function(list) {
        return arrayFromDartList(Uint32Array, list);
    },
    float32ArrayFromDartFloat32List: function(list) {
        return arrayFromDartList(Float32Array, list);
    },
    float64ArrayFromDartFloat64List: function(list) {
        return arrayFromDartList(Float64Array, list);
    },
    dataViewFromDartByteData: function(byteData, byteLength) {
        return dataViewFromDartByteData(byteData, byteLength);
    },
    arrayFromDartList: function(list) {
        return arrayFromDartList(Array, list);
    },
    stringFromDartString: stringFromDartString,
    stringToDartString: stringToDartString,
    wrapDartFunction: function(dartFunction, exportFunctionName) {
        var wrapped = function (...args) {
            return dartInstance.exports[`${exportFunctionName}`](
                dartFunction, ...args.map(dartInstance.exports.$dartifyRaw));
        }
        wrapped.dartFunction = dartFunction;
        wrapped[jsWrappedDartFunctionSymbol] = true;
        return wrapped;
    },
    objectLength: function(o) {
        return o.length;
    },
    objectReadIndex: function(o, i) {
        return o[i];
    },
    unwrapJSWrappedDartFunction: function(o) {
        return o.dartFunction;
    },
    isJSUndefined: function(o) {
        return o === undefined;
    },
    isJSBoolean: function(o) {
        return typeof o === "boolean";
    },
    isJSNumber: function(o) {
        return typeof o === "number";
    },
    isJSBigInt: function(o) {
        return typeof o === "bigint";
    },
    isJSString: function(o) {
        return typeof o === "string";
    },
    isJSSymbol: function(o) {
        return typeof o === "symbol";
    },
    isJSFunction: function(o) {
        return typeof o === "function";
    },
    isJSInt8Array: function(o) {
        return o instanceof Int8Array;
    },
    isJSUint8Array: function(o) {
        return o instanceof Uint8Array;
    },
    isJSUint8ClampedArray: function(o) {
        return o instanceof Uint8ClampedArray;
    },
    isJSInt16Array: function(o) {
        return o instanceof Int16Array;
    },
    isJSUint16Array: function(o) {
        return o instanceof Uint16Array;
    },
    isJSInt32Array: function(o) {
        return o instanceof Int32Array;
    },
    isJSUint32Array: function(o) {
        return o instanceof Uint32Array;
    },
    isJSFloat32Array: function(o) {
        return o instanceof Float32Array;
    },
    isJSFloat64Array: function(o) {
        return o instanceof Float64Array;
    },
    isJSArrayBuffer: function(o) {
        return o instanceof ArrayBuffer;
    },
    isJSDataView: function(o) {
        return o instanceof DataView;
    },
    isJSArray: function(o) {
        return o instanceof Array;
    },
    isJSWrappedDartFunction: function(o) {
        return typeof o === "function" &&
            o[jsWrappedDartFunctionSymbol] === true;
    },
    isJSObject: function(o) {
        return o instanceof Object;
    },
    roundtrip: function (o) {
      // This function exists as a hook for the native JS -> Wasm type
      // conversion rules. The Dart runtime will overload variants of this
      // function with the necessary return type to trigger the desired
      // coercion.
      return o;
    },
    newObject: function() {
        return {};
    },
    globalThis: function() {
        return globalThis;
    },
    getProperty: function(object, name) {
        return object[name];
    },
    hasProperty: function(object, name) {
        return name in object;
    },
    setProperty: function(object, name, value) {
        return object[name] = value;
    },
    callMethodVarArgs: function(object, name, args) {
        return object[name].apply(object, args);
    },
    callConstructorVarArgs: function(constructor, args) {
        // Apply bind to the constructor. We pass `null` as the first argument
        // to `bind.apply` because this is `bind`'s unused context
        // argument(`new` will explicitly create a new context).
        var factoryFunction = constructor.bind.apply(constructor, [null, ...args]);
        return new factoryFunction();
    },
    getTimeZoneNameForSeconds: function(secondsSinceEpoch) {
        var date = new Date(secondsSinceEpoch * 1000);
        var match = /\((.*)\)/.exec(date.toString());
        if (match == null) {
            // This should never happen on any recent browser.
            return '';
        }
        return stringToDartString(match[1]);

    },
    getTimeZoneOffsetInSeconds: function(secondsSinceEpoch) {
        return new Date(secondsSinceEpoch * 1000).getTimezoneOffset() * 60;
    },
    jsonEncode: function(s) {
        return stringToDartString(JSON.stringify(stringFromDartString(s)));
    },
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
