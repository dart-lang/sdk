// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Check that JS types work.

import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:js_util';
import 'dart:typed_data';

import 'package:expect/expect.dart';
import 'package:expect/minitest.dart';

const isJSBackend = const bool.fromEnvironment('dart.library.html');

@JS()
external void eval(String code);

@JS()
external JSAny any;

@JS()
external JSObject obj;

@JS()
@staticInterop
class SimpleObject {}

extension SimpleObjectExtension on SimpleObject {
  external JSString get foo;
}

@JS()
external JSFunction fun;

@JS('fun')
external JSString doFun(JSString a, JSString b);

@JS()
external JSExportedDartFunction edf;

@JS()
external JSArray arr;

@JS()
external JSBoxedDartObject edo;

@JS()
external JSArrayBuffer buf;

@JS()
external JSDataView dat;

@JS()
external JSTypedArray tar;

@JS()
external JSInt8Array ai8;

@JS()
external JSUint8Array au8;

@JS()
external JSUint8ClampedArray ac8;

@JS()
external JSInt16Array ai16;

@JS()
external JSUint16Array au16;

@JS()
external JSInt32Array ai32;

@JS()
external JSUint32Array au32;

@JS()
external JSFloat32Array af32;

@JS()
external JSFloat64Array af64;

@JS()
external JSNumber nbr;

@JS()
external JSBoolean boo;

@JS()
external JSString str;

@JS()
external JSSymbol symbol;

@JS('Symbol')
external JSSymbol createSymbol(String value);

extension on JSSymbol {
  @JS('toString')
  external String toStringExternal();
}

@JS()
external JSBigInt bigInt;

@JS('BigInt')
external JSBigInt createBigInt(String value);

extension on JSBigInt {
  @JS('toString')
  external String toStringExternal();
}

@JS()
external JSAny? nullAny;

@JS()
external JSAny? undefinedAny;

@JS()
external JSAny? definedNonNullAny;

class DartObject {
  String get foo => 'bar';
}

@pragma('dart2js:never-inline')
@pragma('dart2js:assumeDynamic')
confuse(x) => x;

void syncTests() {
  eval('''
    globalThis.obj = {
      'foo': 'bar',
    };
    globalThis.fun = function(a, b) {
      return globalThis.edf(a, b);
    }
    globalThis.nullAny = null;
    globalThis.undefinedAny = undefined;
    globalThis.definedNonNullAny = {};
  ''');

  // [JSObject]
  expect(obj is JSObject, true);
  expect(confuse(obj) is JSObject, true);
  expect((obj as SimpleObject).foo.toDart, 'bar');

  // [JSFunction]
  expect(fun is JSFunction, true);
  expect(confuse(fun) is JSFunction, true);

  // [JSExportedDartFunction] <-> [Function]
  edf = (JSString a, JSString b) {
    return (a.toDart + b.toDart).toJS;
  }.toJS;
  expect(doFun('foo'.toJS, 'bar'.toJS).toDart, 'foobar');
  expect(
      (edf.toDart as JSString Function(JSString, JSString))(
              'foo'.toJS, 'bar'.toJS)
          .toDart,
      'foobar');
  // Converting a non-function should throw.
  Expect.throws(() => ('foo'.toJS as JSExportedDartFunction).toDart);

  // [JSBoxedDartObject] <-> [Object]
  edo = DartObject().toJSBox;
  expect(edo is JSBoxedDartObject, true);
  expect(confuse(edo) is JSBoxedDartObject, true);
  expect(((edo as JSBoxedDartObject).toDart as DartObject).foo, 'bar');
  // Functions should be boxed without assertInterop.
  final concat = (String a, String b) => a + b;
  edo = concat.toJSBox;
  expect(
      (edo.toDart as String Function(String, String))('foo', 'bar'), 'foobar');
  // Should not box a non Dart-object.
  Expect.throws(() => edo.toJSBox);

  // [JSArray] <-> [List<JSAny?>]
  arr = [1.0.toJS, 'foo'.toJS].toJS;
  expect(arr is JSArray, true);
  expect(confuse(arr) is JSArray, true);
  List<JSAny?> dartArr = arr.toDart;
  expect((dartArr[0] as JSNumber).toDartDouble, 1.0);
  expect((dartArr[1] as JSString).toDart, 'foo');

  // [ArrayBuffer] <-> [ByteBuffer]
  buf = Uint8List.fromList([0, 255, 0, 255]).buffer.toJS;
  expect(buf is JSArrayBuffer, true);
  expect(confuse(buf) is JSArrayBuffer, true);
  ByteBuffer dartBuf = buf.toDart;
  expect(dartBuf.asUint8List(), equals([0, 255, 0, 255]));

  // [DataView] <-> [ByteData]
  dat = Uint8List.fromList([0, 255, 0, 255]).buffer.asByteData().toJS;
  expect(dat is JSDataView, true);
  expect(confuse(dat) is JSDataView, true);
  ByteData dartDat = dat.toDart;
  expect(dartDat.getUint8(0), 0);
  expect(dartDat.getUint8(1), 255);

  // [TypedArray]s <-> [TypedData]s
  // Int8
  ai8 = Int8List.fromList([-128, 0, 127]).toJS;
  expect(ai8 is JSInt8Array, true);
  expect(confuse(ai8) is JSInt8Array, true);
  Int8List dartAi8 = ai8.toDart;
  expect(dartAi8, equals([-128, 0, 127]));

  // Uint8
  au8 = Uint8List.fromList([-1, 0, 255, 256]).toJS;
  expect(au8 is JSUint8Array, true);
  expect(confuse(au8) is JSUint8Array, true);
  Uint8List dartAu8 = au8.toDart;
  expect(dartAu8, equals([255, 0, 255, 0]));

  // Uint8Clamped
  ac8 = Uint8ClampedList.fromList([-1, 0, 255, 256]).toJS;
  expect(ac8 is JSUint8ClampedArray, true);
  expect(confuse(ac8) is JSUint8ClampedArray, true);
  Uint8ClampedList dartAc8 = ac8.toDart;
  expect(dartAc8, equals([0, 0, 255, 255]));

  // Int16
  ai16 = Int16List.fromList([-32769, -32768, 0, 32767, 32768]).toJS;
  expect(ai16 is JSInt16Array, true);
  expect(confuse(ai16) is JSInt16Array, true);
  Int16List dartAi16 = ai16.toDart;
  expect(dartAi16, equals([32767, -32768, 0, 32767, -32768]));

  // Uint16
  au16 = Uint16List.fromList([-1, 0, 65535, 65536]).toJS;
  expect(au16 is JSUint16Array, true);
  expect(confuse(au16) is JSUint16Array, true);
  Uint16List dartAu16 = au16.toDart;
  expect(dartAu16, equals([65535, 0, 65535, 0]));

  // Int32
  ai32 = Int32List.fromList([-2147483648, 0, 2147483647]).toJS;
  expect(ai32 is JSInt32Array, true);
  expect(confuse(ai32) is JSInt32Array, true);
  Int32List dartAi32 = ai32.toDart;
  expect(dartAi32, equals([-2147483648, 0, 2147483647]));

  // Uint32
  au32 = Uint32List.fromList([-1, 0, 4294967295, 4294967296]).toJS;
  expect(au32 is JSUint32Array, true);
  expect(confuse(au32) is JSUint32Array, true);
  Uint32List dartAu32 = au32.toDart;
  expect(dartAu32, equals([4294967295, 0, 4294967295, 0]));

  // Float32
  af32 = Float32List.fromList([-1000.488, -0.00001, 0.0001, 10004.888]).toJS;
  expect(af32 is JSFloat32Array, true);
  expect(confuse(af32) is JSFloat32Array, true);
  Float32List dartAf32 = af32.toDart;
  expect(dartAf32,
      equals(Float32List.fromList([-1000.488, -0.00001, 0.0001, 10004.888])));

  // Float64
  af64 = Float64List.fromList([-1000.488, -0.00001, 0.0001, 10004.888]).toJS;
  expect(af64 is JSFloat64Array, true);
  expect(confuse(af64) is JSFloat64Array, true);
  Float64List dartAf64 = af64.toDart;
  expect(dartAf64, equals([-1000.488, -0.00001, 0.0001, 10004.888]));

  // [JSNumber] <-> [double]
  nbr = 4.5.toJS;
  expect(nbr is JSNumber, true);
  expect(confuse(nbr) is JSNumber, true);
  double dartNbr = nbr.toDartDouble;
  expect(dartNbr, 4.5);

  // [JSBoolean] <-> [bool]
  boo = true.toJS;
  expect(boo is JSBoolean, true);
  expect(confuse(boo) is JSBoolean, true);
  bool dartBoo = boo.toDart;
  expect(dartBoo, true);

  // [JSString] <-> [String]
  str = 'foo'.toJS;
  expect(str is JSString, true);
  expect(confuse(str) is JSString, true);
  String dartStr = str.toDart;
  expect(dartStr, 'foo');

  // [JSSymbol]
  symbol = createSymbol('foo');
  expect(symbol is JSSymbol, true);
  expect(confuse(symbol) is JSSymbol, true);
  expect(symbol.toStringExternal(), 'Symbol(foo)');

  // [JSBigInt]
  bigInt = createBigInt('9876543210000000000000123456789');
  expect(bigInt is JSBigInt, true);
  expect(confuse(bigInt) is JSBigInt, true);
  expect(bigInt.toStringExternal(), '9876543210000000000000123456789');

  // null and undefined can flow into `JSAny?`.
  // TODO(srujzs): Remove the `isJSBackend` checks when `JSNull` and
  // `JSUndefined` can be distinguished on dart2wasm.
  if (isJSBackend) {
    expect(nullAny.isNull, true);
    expect(nullAny.isUndefined, false);
  }
  expect(nullAny, null);
  expect(nullAny.isUndefinedOrNull, true);
  expect(nullAny.isDefinedAndNotNull, false);
  expect(nullAny.typeofEquals('object'), true);
  if (isJSBackend) {
    expect(undefinedAny.isNull, false);
    expect(undefinedAny.isUndefined, true);
  }
  expect(undefinedAny.isUndefinedOrNull, true);
  expect(undefinedAny.isDefinedAndNotNull, false);
  if (isJSBackend) {
    expect(undefinedAny.typeofEquals('undefined'), true);
    expect(definedNonNullAny.isNull, false);
    expect(definedNonNullAny.isUndefined, false);
  } else {
    expect(undefinedAny.typeofEquals('object'), true);
  }
  expect(definedNonNullAny.isUndefinedOrNull, false);
  expect(definedNonNullAny.isDefinedAndNotNull, true);
  expect(definedNonNullAny.typeofEquals('object'), true);
}

@JS()
external JSPromise getResolvedPromise();

@JS()
external JSPromise getRejectedPromise();

@JS()
external JSPromise resolvePromiseWithNullOrUndefined(bool resolveWithNull);

@JS()
external JSPromise rejectPromiseWithNullOrUndefined(bool resolveWithNull);

Future<void> asyncTests() async {
  eval(r'''
    globalThis.getResolvedPromise = function() {
      return Promise.resolve('resolved');
    }
    globalThis.getRejectedPromise = function() {
      return Promise.reject(new Error('rejected'));
    }
    globalThis.resolvePromiseWithNullOrUndefined = function(resolveWithNull) {
      return Promise.resolve(resolveWithNull ? null : undefined);
    }
    globalThis.rejectPromiseWithNullOrUndefined = function(rejectWithNull) {
      return Promise.reject(rejectWithNull ? null : undefined);
    }
  ''');

  // [JSPromise] -> [Future].
  // Test resolution.
  {
    Future<JSAny?> f = getResolvedPromise().toDart;
    expect(((await f) as JSString).toDart, 'resolved');
  }

  // Test rejection.
  {
    try {
      await getRejectedPromise().toDart;
      fail('Expected rejected promise to throw.');
    } catch (e) {
      final jsError = e as JSObject;
      expect(jsError.toString(), 'Error: rejected');
    }
  }

  // Test resolution Promise chaining.
  {
    bool didThen = false;
    Future<JSAny?> f = getResolvedPromise().toDart.then((resolved) {
      expect((resolved as JSString).toDart, 'resolved');
      didThen = true;
      return null;
    });
    await f;
    expect(didThen, true);
  }

  // Test rejection Promise chaining.
  {
    Future<JSAny?> f = getRejectedPromise().toDart.then((_) {
      fail('Expected rejected promise to throw.');
      return null;
    }, onError: (e) {
      final jsError = e as JSObject;
      expect(jsError.toString(), 'Error: rejected');
    });
    await f;
  }

  // Test resolving promise with null and undefined.
  Future<void> testResolveWithNullOrUndefined(bool resolveWithNull) async {
    Future<JSAny?> f =
        resolvePromiseWithNullOrUndefined(resolveWithNull).toDart;
    expect(((await f) as JSAny?), null);
  }

  await testResolveWithNullOrUndefined(true);
  await testResolveWithNullOrUndefined(false);

  // Test rejecting promise with null and undefined should trigger an exception.
  Future<void> testRejectionWithNullOrUndefined(bool rejectWithNull) async {
    try {
      await rejectPromiseWithNullOrUndefined(rejectWithNull).toDart;
      fail('Expected rejected promise to throw.');
    } catch (e) {
      expect(e is NullRejectionException, true);
    }
  }

  await testRejectionWithNullOrUndefined(true);
  await testRejectionWithNullOrUndefined(false);

  // [Future<JSAny?>] -> [JSPromise].
  // Test resolution.
  {
    final f = Future<JSAny?>(() => 'resolved'.toJS).toJS.toDart;
    expect(((await f) as JSString).toDart, 'resolved');
  }

  // Test rejection.
  {
    try {
      await Future<JSAny?>(() => throw Exception()).toJS.toDart;
      fail('Expected future to throw.');
    } catch (e) {
      expect(e is JSObject, true);
      final jsError = e as JSObject;
      expect(jsError.instanceof(globalContext['Error'] as JSFunction), true);
      expect((jsError['error'] as JSBoxedDartObject).toDart is Exception, true);
      StackTrace.fromString((jsError['stack'] as JSString).toDart);
    }
  }

  // [Future<void>] -> [JSPromise].
  // Test resolution.
  {
    var compute = false;
    final f = Future<void>(() {
      compute = true;
    }).toJS.toDart;
    await f;
    expect(compute, true);
  }

  // Test rejection.
  {
    try {
      await Future<void>(() => throw Exception()).toJS.toDart as Future<void>;
      fail('Expected future to throw.');
    } catch (e) {
      expect(e is JSObject, true);
      final jsError = e as JSObject;
      expect(jsError.instanceof(globalContext['Error'] as JSFunction), true);
      expect((jsError['error'] as JSBoxedDartObject).toDart is Exception, true);
      StackTrace.fromString((jsError['stack'] as JSString).toDart);
    }
  }
}

void main() async {
  syncTests();
  await asyncTests();
}
