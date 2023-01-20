// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

const jsRuntimeBlobPart1 = r'''
// `modulePromise` is a promise to the `WebAssembly.module` object to be
//   instantiated.
// `importObjectPromise` is a promise to an object that contains any additional
//   imports needed by the module that aren't provided by the standard runtime.
//   The fields on this object will be merged into the importObject with which
//   the module will be instantiated.
// This function returns a promise to the instantiated module.
export const instantiate = async (modulePromise, importObjectPromise) => {
    let asyncBridge;
    let dartInstance;
    function stringFromDartString(string) {
        const totalLength = dartInstance.exports.$stringLength(string);
        let result = '';
        let index = 0;
        while (index < totalLength) {
          let chunkLength = Math.min(totalLength - index, 0xFFFF);
          const array = new Array(chunkLength);
          for (let i = 0; i < chunkLength; i++) {
              array[i] = dartInstance.exports.$stringRead(string, index++);
          }
          result += String.fromCharCode(...array);
        }
        return result;
    }

    function stringToDartString(string) {
        const length = string.length;
        let range = 0;
        for (let i = 0; i < length; i++) {
            range |= string.codePointAt(i);
        }
        if (range < 256) {
            const dartString = dartInstance.exports.$stringAllocate1(length);
            for (let i = 0; i < length; i++) {
                dartInstance.exports.$stringWrite1(dartString, i, string.codePointAt(i));
            }
            return dartString;
        } else {
            const dartString = dartInstance.exports.$stringAllocate2(length);
            for (let i = 0; i < length; i++) {
                dartInstance.exports.$stringWrite2(dartString, i, string.charCodeAt(i));
            }
            return dartString;
        }
    }

    // Converts a Dart List to a JS array. Any Dart objects will be converted, but
    // this will be cheap for JSValues.
    function arrayFromDartList(constructor, list) {
        const length = dartInstance.exports.$listLength(list);
        const array = new constructor(length);
        for (let i = 0; i < length; i++) {
            array[i] = dartInstance.exports.$listRead(list, i);
        }
        return array;
    }

    function dataViewFromDartByteData(byteData, byteLength) {
        const dataView = new DataView(new ArrayBuffer(byteLength));
        for (let i = 0; i < byteLength; i++) {
            dataView.setUint8(i, dartInstance.exports.$byteDataGetUint8(byteData, i));
        }
        return dataView;
    }

    // A special symbol attached to functions that wrap Dart functions.
    const jsWrappedDartFunctionSymbol = Symbol("JSWrappedDartFunction");

    function finalizeWrapper(dartFunction, wrapped) {
        wrapped.dartFunction = dartFunction;
        wrapped[jsWrappedDartFunctionSymbol] = true;
        return wrapped;
    }

    // Calls a constructor with a variable number of arguments.
    function callConstructorVarArgs(constructor, args) {
        // Apply bind to the constructor. We pass `null` as the first argument
        // to `bind.apply` because this is `bind`'s unused context
        // argument(`new` will explicitly create a new context).
        const factoryFunction = constructor.bind.apply(constructor, [null, ...args]);
        return new factoryFunction();
    }

    // Imports
    const dart2wasm = {
        printToConsole: function(string) {
            console.log(stringFromDartString(string))
        },
        scheduleCallback: function(milliseconds, closure) {
            setTimeout(function() {
                dartInstance.exports.$invokeCallback(closure);
            }, milliseconds);
        },
        futurePromise: new WebAssembly.Function(
            {parameters: ['externref', 'externref'], results: ['externref']},
            function(future) {
                return new Promise(function (resolve, reject) {
                    dartInstance.exports.$awaitCallback(future, resolve);
                });
            },
            {suspending: 'first'}),
        callResolve: function(resolve, result) {
            // This trampoline is needed because [resolve] is a JS function that
            // can't be called directly from Wasm.
            resolve(result);
        },
        callAsyncBridge: function(args, completer) {
            // This trampoline is needed because [asyncBridge] is a function wrapped
            // by `returnPromiseOnSuspend`, and the stack-switching functionality of
            // that wrapper is implemented as part of the export adapter.
            asyncBridge(args, completer);
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
        objectLength: function(o) {
            return o.length;
        },
        objectReadIndex: function(o, i) {
            return o[i];
        },
        objectKeys: function(o) {
            return Object.keys(o);
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
        isJSRegExp: function(o) {
            return o instanceof RegExp;
        },
        isJSSimpleObject: function(o) {
            const proto = Object.getPrototypeOf(o);
            return proto === Object.prototype || proto === null;
        },
        roundtrip: function(o) {
            // This function exists as a hook for the native JS -> Wasm type
            // conversion rules. The Dart runtime will overload variants of this
            // function with the necessary return type to trigger the desired
            // coercion.
            return o;
        },
        toJSBoolean: function(b) {
            return !!b;
        },
        newObject: function() {
            return {};
        },
        newArray: function() {
            return [];
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
        callConstructorVarArgs: callConstructorVarArgs,
        safeCallConstructorVarArgs: function(constructor, args) {
            try {
                return callConstructorVarArgs(constructor, args);
            } catch (e) {
                return String(e);
            }
        },
        getTimeZoneNameForSeconds: function(secondsSinceEpoch) {
            const date = new Date(secondsSinceEpoch * 1000);
            const match = /\((.*)\)/.exec(date.toString());
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
        toUpperCase: function(string) {
            return stringToDartString(stringFromDartString(string).toUpperCase());
        },
        toLowerCase: function(string) {
            return stringToDartString(stringFromDartString(string).toLowerCase());
        },
        isWindows: function() {
            return typeof process != undefined &&
                Object.prototype.toString.call(process) == "[object process]" &&
                process.platform == "win32";
        },
        getCurrentUri: function() {
            // On browsers return `globalThis.location.href`
            if (globalThis.location != null) {
              return stringToDartString(globalThis.location.href);
            }
            return null;
        },
        stringify: function(o) {
            return stringToDartString(String(o));
        },
        doubleToString: function(v) {
            return stringToDartString(v.toString());
        },
        toFixed: function(double, digits) {
            return stringToDartString(double.toFixed(digits));
        },
        toExponential: function(double, fractionDigits)  {
            return stringToDartString(double.toExponential(fractionDigits));
        },
        toPrecision: function(double, precision) {
            return stringToDartString(double.toPrecision(precision));
        },
        parseDouble: function(source) {
            // Notice that JS parseFloat accepts garbage at the end of the string.
            // Accept only:
            // - [+/-]NaN
            // - [+/-]Infinity
            // - a Dart double literal
            // We do allow leading or trailing whitespace.
            const jsSource = stringFromDartString(source);
            if (!/^\s*[+-]?(?:Infinity|NaN|(?:\.\d+|\d+(?:\.\d*)?)(?:[eE][+-]?\d+)?)\s*$/.test(jsSource)) {
              return NaN;
            }
            return parseFloat(jsSource);
        },
        quoteStringForRegExp: function(string) {
            // We specialize this method in the runtime to avoid the overhead of
            // jumping back and forth between JS and Dart. This method is optimized
            // to test before replacement, which should be much faster. This might
            // be worth measuring in real world use cases though.
            let jsString = stringFromDartString(string);
            if (/[[\]{}()*+?.\\^$|]/.test(jsString)) {
                jsString = jsString.replace(/[[\]{}()*+?.\\^$|]/g, '\\$&');
            }
            return stringToDartString(jsString);
        },
        areEqualInJS: function(l, r) {
            return l === r;
        },
        promiseThen: function(promise, successFunc, failureFunc) {
            promise.then(successFunc, failureFunc);
        },
        performanceNow: function() {
            return performance.now();
        },
        instanceofTrampoline: function(object, type) {
            return object instanceof type;
        },
''';

// We break inside the 'dart2wasm' object to enable injection of methods. We
// could use interpolation, but then we'd have to escape characters.
const jsRuntimeBlobPart2 = r'''
    };

    const baseImports = {
        dart2wasm: dart2wasm,
        Math: Math,
        Date: Date,
        Object: Object,
        Array: Array,
        Reflect: Reflect,
    };
    dartInstance = await WebAssembly.instantiate(await modulePromise, {
        ...baseImports,
        ...(await importObjectPromise),
    });

    // Initialize async bridge.
    asyncBridge = new WebAssembly.Function(
        {parameters: ['externref', 'externref'], results: ['externref']},
        dartInstance.exports.$asyncBridge,
        {promising: 'first'});
    return dartInstance;
}

// Call the main function for the instantiated module
// `moduleInstance` is the instantiated dart2wasm module
// `args` are any arguments that should be passed into the main function.
export const invoke = async (moduleInstance, ...args) => {
    moduleInstance.exports.$invokeMain(moduleInstance.exports.$getMain());
}
''';
