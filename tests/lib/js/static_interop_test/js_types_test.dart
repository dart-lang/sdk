// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Check that JS types work.

import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';
// TODO(srujzs): Delete this import and replace all uses with expect.dart.
import 'package:expect/minitest.dart'; // ignore: deprecated_member_use_from_same_package

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

extension on SimpleObject {
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

@JS('arr')
external JSArray<JSNumber> arrN;

@JS()
external JSBoxedDartObject edo;

@JS()
external JSArrayBuffer buf;

extension on JSArrayBuffer {
  external int get byteLength;
}

@JS()
external JSDataView dat;

extension on JSDataView {
  external JSArrayBuffer get buffer;
  external int get byteLength;
  external int get byteOffset;
}

@JS()
external JSTypedArray tar;

extension on JSTypedArray {
  external JSArrayBuffer get buffer;
  external int get byteLength;
  external int get byteOffset;
  external int get length;
}

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
  final dartFunction = (JSString a, JSString b) {
    return (a.toDart + b.toDart).toJS;
  };
  edf = dartFunction.toJS;
  expect(doFun('foo'.toJS, 'bar'.toJS).toDart, 'foobar');
  expect(
      (edf.toDart as JSString Function(JSString, JSString))(
              'foo'.toJS, 'bar'.toJS)
          .toDart,
      'foobar');
  Expect.identical(edf.toDart, dartFunction);
  // Two wrappers should not be the same.
  Expect.notEquals(edf, dartFunction.toJS);
  // Converting a non-function should throw.
  Expect.throws(() => ('foo'.toJS as JSExportedDartFunction).toDart);
  // `this` should be captured correctly in `toJSCaptureThis`.
  final this_ = JSObject();
  final dartFunctionThis = (JSObject this__, JSString a, JSString b) {
    Expect.equals(this_, this__);
    return (a.toDart + b.toDart).toJS;
  };
  edf = dartFunctionThis.toJSCaptureThis;
  Expect.equals(
      (edf.callAsFunction(this_, 'foo'.toJS, 'bar'.toJS) as JSString).toDart,
      'foobar');
  Expect.identical(edf.toDart, dartFunctionThis);
  Expect.notEquals(edf, dartFunctionThis.toJSCaptureThis);

  // [JSBoxedDartObject] <-> [Object]
  edo = DartObject().toJSBox;
  expect(edo is JSBoxedDartObject, true);
  expect(confuse(edo) is JSBoxedDartObject, true);
  expect(((edo as JSBoxedDartObject).toDart as DartObject).foo, 'bar');
  expect(edo.instanceOfString('Object'), true);
  // Functions should be boxed without assertInterop.
  final concat = (String a, String b) => a + b;
  edo = concat.toJSBox;
  expect(
      (edo.toDart as String Function(String, String))('foo', 'bar'), 'foobar');
  // Should not box a non Dart-object.
  Expect.throws(() => edo.toJSBox);

  // [JSArray] constructors and members.
  arrN = JSArray<JSNumber>();
  expect(arrN.length, 0);
  arrN = JSArray<JSNumber>.withLength(4);
  expect(arrN.length, 4);
  arrN.length = 1;
  expect(arrN.length, 1);
  arrN[0] = 1.toJS;
  expect(arrN[0].toDartInt, 1);
  arrN = JSArray.from<JSNumber>(arrN);
  expect(arrN.length, 1);
  expect(arrN[0].toDartInt, 1);
  final typedArray = JSArray.from<JSNumber>(JSUint8Array.withLength(4));
  expect(typedArray.length, 4);
  expect(typedArray[0].toDartInt, 0);

  // [JSArray] <-> [List<JSAny?>]
  final list = <JSAny?>[1.0.toJS, 'foo'.toJS];
  arr = list.toJS;
  expect(arr is JSArray, true);
  expect(confuse(arr) is JSArray, true);
  List<JSAny?> dartArr = arr.toDart;
  expect((dartArr[0] as JSNumber).toDartDouble, 1.0);
  expect((dartArr[1] as JSString).toDart, 'foo');

  List<JSNumber> dartArrN = arrN.toDart;
  if (isJSBackend) {
    // Since lists on the JS backends are passed by ref, we only create a
    // cast-list if there's a downcast needed.
    expect(dartArr, list);
    Expect.notEquals(dartArrN, list);
    Expect.throwsTypeError(() => dartArrN[1]);
  } else {
    // On dart2wasm, we always create a new list using JSArrayImpl.
    Expect.notEquals(dartArr, list);
    Expect.notEquals(dartArrN, list);
    dartArrN[1];
  }

  // [JSArray<T>] <-> [List<T>]
  final listN = <JSNumber>[1.0.toJS, 2.0.toJS];
  arrN = listN.toJS;
  expect(arrN is JSArray<JSNumber>, true);
  expect(confuse(arrN) is JSArray<JSNumber>, true);

  dartArr = arr.toDart;
  dartArrN = arrN.toDart;
  if (isJSBackend) {
    // A cast-list should not be introduced if the the array is already the
    // right list type.
    expect(dartArr, listN);
    expect(dartArrN, listN);
  } else {
    Expect.notEquals(dartArr, list);
    Expect.notEquals(dartArrN, list);
  }

  // [ArrayBuffer] <-> [ByteBuffer]
  buf = Uint8List.fromList([0, 255, 0, 255]).buffer.toJS;
  expect(buf is JSArrayBuffer, true);
  expect(confuse(buf) is JSArrayBuffer, true);
  ByteBuffer dartBuf = buf.toDart;
  expect(dartBuf.asUint8List(), equals([0, 255, 0, 255]));
  buf = JSArrayBuffer(5);
  expect(buf.byteLength, 5);
  buf = JSArrayBuffer(5, {'maxByteLength': 12}.jsify() as JSObject);

  // [DataView] <-> [ByteData]
  final datBuf = Uint8List.fromList([0, 255, 0, 255]).buffer.toJS;
  dat = datBuf.toDart.asByteData().toJS;
  expect(dat is JSDataView, true);
  expect(confuse(dat) is JSDataView, true);
  ByteData dartDat = dat.toDart;
  expect(dartDat.getUint8(0), 0);
  expect(dartDat.getUint8(1), 255);
  dat = JSDataView(datBuf);
  expect(dat.buffer, datBuf);
  final dat2 = JSDataView(datBuf, 1, 3);
  expect(dat2.byteOffset, 1);
  expect(dat2.byteLength, 3);

  // [TypedArray]s <-> [TypedData]s
  // Test common TypedArray constructors for different subtypes.
  void testTypedArrayConstructors(
      JSTypedArray Function(JSArrayBuffer) createFromBuffer,
      JSTypedArray Function(JSArrayBuffer, int, int)
          createFromBufferOffsetAndLength,
      JSTypedArray Function(int) createFromLength,
      int byteSize) {
    var byteLength = 16;
    final buf = JSArrayBuffer(byteLength);
    var typedArray = createFromBuffer(buf);
    expect(typedArray.buffer, buf);
    expect(typedArray.byteLength, byteLength);
    expect(typedArray.byteOffset, 0);
    expect(typedArray.length, byteLength ~/ byteSize);

    byteLength = 8;
    typedArray =
        createFromBufferOffsetAndLength(buf, 8, byteLength ~/ byteSize);
    expect(typedArray.buffer, buf);
    expect(typedArray.byteLength, byteLength);
    expect(typedArray.byteOffset, 8);
    expect(typedArray.length, byteLength ~/ byteSize);

    typedArray = createFromLength(byteLength ~/ byteSize);
    expect(typedArray.byteLength, byteLength);
    expect(typedArray.byteOffset, 0);
    expect(typedArray.length, byteLength ~/ byteSize);
  }

  // Int8
  ai8 = Int8List.fromList([-128, 0, 127]).toJS;
  expect(ai8 is JSInt8Array, true);
  expect(confuse(ai8) is JSInt8Array, true);
  Int8List dartAi8 = ai8.toDart;
  expect(dartAi8, equals([-128, 0, 127]));
  testTypedArrayConstructors(
      (JSArrayBuffer obj) => JSInt8Array(obj),
      (JSArrayBuffer obj, int byteOffset, int length) =>
          JSInt8Array(obj, byteOffset, length),
      (int length) => JSInt8Array.withLength(length),
      1);

  // Uint8
  au8 = Uint8List.fromList([-1, 0, 255, 256]).toJS;
  expect(au8 is JSUint8Array, true);
  expect(confuse(au8) is JSUint8Array, true);
  Uint8List dartAu8 = au8.toDart;
  expect(dartAu8, equals([255, 0, 255, 0]));
  testTypedArrayConstructors(
      (JSArrayBuffer obj) => JSUint8Array(obj),
      (JSArrayBuffer obj, int byteOffset, int length) =>
          JSUint8Array(obj, byteOffset, length),
      (int length) => JSUint8Array.withLength(length),
      1);

  // Uint8Clamped
  ac8 = Uint8ClampedList.fromList([-1, 0, 255, 256]).toJS;
  expect(ac8 is JSUint8ClampedArray, true);
  expect(confuse(ac8) is JSUint8ClampedArray, true);
  Uint8ClampedList dartAc8 = ac8.toDart;
  expect(dartAc8, equals([0, 0, 255, 255]));
  testTypedArrayConstructors(
      (JSArrayBuffer obj) => JSUint8ClampedArray(obj),
      (JSArrayBuffer obj, int byteOffset, int length) =>
          JSUint8ClampedArray(obj, byteOffset, length),
      (int length) => JSUint8ClampedArray.withLength(length),
      1);

  // Int16
  ai16 = Int16List.fromList([-32769, -32768, 0, 32767, 32768]).toJS;
  expect(ai16 is JSInt16Array, true);
  expect(confuse(ai16) is JSInt16Array, true);
  Int16List dartAi16 = ai16.toDart;
  expect(dartAi16, equals([32767, -32768, 0, 32767, -32768]));
  testTypedArrayConstructors(
      (JSArrayBuffer obj) => JSInt16Array(obj),
      (JSArrayBuffer obj, int byteOffset, int length) =>
          JSInt16Array(obj, byteOffset, length),
      (int length) => JSInt16Array.withLength(length),
      2);

  // Uint16
  au16 = Uint16List.fromList([-1, 0, 65535, 65536]).toJS;
  expect(au16 is JSUint16Array, true);
  expect(confuse(au16) is JSUint16Array, true);
  Uint16List dartAu16 = au16.toDart;
  expect(dartAu16, equals([65535, 0, 65535, 0]));
  testTypedArrayConstructors(
      (JSArrayBuffer obj) => JSUint16Array(obj),
      (JSArrayBuffer obj, int byteOffset, int length) =>
          JSUint16Array(obj, byteOffset, length),
      (int length) => JSUint16Array.withLength(length),
      2);

  // Int32
  ai32 = Int32List.fromList([-2147483648, 0, 2147483647]).toJS;
  expect(ai32 is JSInt32Array, true);
  expect(confuse(ai32) is JSInt32Array, true);
  Int32List dartAi32 = ai32.toDart;
  expect(dartAi32, equals([-2147483648, 0, 2147483647]));
  testTypedArrayConstructors(
      (JSArrayBuffer obj) => JSInt32Array(obj),
      (JSArrayBuffer obj, int byteOffset, int length) =>
          JSInt32Array(obj, byteOffset, length),
      (int length) => JSInt32Array.withLength(length),
      4);

  // Uint32
  au32 = Uint32List.fromList([-1, 0, 4294967295, 4294967296]).toJS;
  expect(au32 is JSUint32Array, true);
  expect(confuse(au32) is JSUint32Array, true);
  Uint32List dartAu32 = au32.toDart;
  expect(dartAu32, equals([4294967295, 0, 4294967295, 0]));
  testTypedArrayConstructors(
      (JSArrayBuffer obj) => JSUint32Array(obj),
      (JSArrayBuffer obj, int byteOffset, int length) =>
          JSUint32Array(obj, byteOffset, length),
      (int length) => JSUint32Array.withLength(length),
      4);

  // Float32
  af32 = Float32List.fromList([-1000.488, -0.00001, 0.0001, 10004.888]).toJS;
  expect(af32 is JSFloat32Array, true);
  expect(confuse(af32) is JSFloat32Array, true);
  Float32List dartAf32 = af32.toDart;
  expect(dartAf32,
      equals(Float32List.fromList([-1000.488, -0.00001, 0.0001, 10004.888])));
  testTypedArrayConstructors(
      (JSArrayBuffer obj) => JSFloat32Array(obj),
      (JSArrayBuffer obj, int byteOffset, int length) =>
          JSFloat32Array(obj, byteOffset, length),
      (int length) => JSFloat32Array.withLength(length),
      4);

  // Float64
  af64 = Float64List.fromList([-1000.488, -0.00001, 0.0001, 10004.888]).toJS;
  expect(af64 is JSFloat64Array, true);
  expect(confuse(af64) is JSFloat64Array, true);
  Float64List dartAf64 = af64.toDart;
  expect(dartAf64, equals([-1000.488, -0.00001, 0.0001, 10004.888]));
  testTypedArrayConstructors(
      (JSArrayBuffer obj) => JSFloat64Array(obj),
      (JSArrayBuffer obj, int byteOffset, int length) =>
          JSFloat64Array(obj, byteOffset, length),
      (int length) => JSFloat64Array.withLength(length),
      8);

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
external JSPromise<T> getResolvedPromise<T extends JSAny?>();

@JS()
external JSPromise<T> getRejectedPromise<T extends JSAny?>();

@JS()
external JSPromise<T> resolvePromiseWithNullOrUndefined<T extends JSAny?>(
    bool resolveWithNull);

@JS()
external JSPromise<T> rejectPromiseWithNullOrUndefined<T extends JSAny?>(
    bool resolveWithNull);

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
    final f = getResolvedPromise().toDart;
    expect(((await f) as JSString).toDart, 'resolved');
  }

  // Test resolution with generics.
  {
    final f = getResolvedPromise<JSString>().toDart;
    expect((await f).toDart, 'resolved');
  }

  // Test resolution with incorrect type.
  // TODO(54214): This type error is not caught in the JS compilers correctly.
  // {
  //   try {
  //     final f = getResolvedPromise<JSNumber>().toDart;
  //     final jsNum = await f;
  //     // TODO(54179): This should be a `jsNum.toDart` call, but currently we try
  //     // to coerce all extern refs into primitive types in this conversion
  //     // method. Change this once that bug is fixed.
  //     if (!jsNum.typeofEquals('number')) throw TypeError();
  //     fail('Expected resolution or use of type to throw.');
  //   } catch (e) {
  //     expect(e is TypeError, true);
  //   }
  // }

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

  // Test rejection with generics.
  {
    try {
      await getRejectedPromise<JSString>().toDart;
      fail('Expected rejected promise to throw.');
    } catch (e) {
      final jsError = e as JSObject;
      expect(jsError.toString(), 'Error: rejected');
    }
  }

  // Test resolution Promise chaining.
  {
    bool didThen = false;
    final f = getResolvedPromise().toDart.then((resolved) {
      expect((resolved as JSString).toDart, 'resolved');
      didThen = true;
      return null;
    });
    await f;
    expect(didThen, true);
  }

  // Test rejection Promise chaining.
  {
    final f = getRejectedPromise().toDart.then((_) {
      fail('Expected rejected promise to throw.');
      return null;
    }, onError: (e) {
      final jsError = e as JSObject;
      expect(jsError.toString(), 'Error: rejected');
    });
    await f;
  }

  // Test resolving generic promise with null and undefined.
  Future<void> testResolveWithNullOrUndefined<T extends JSAny?>(
      bool resolveWithNull) async {
    final f = resolvePromiseWithNullOrUndefined<T>(resolveWithNull).toDart;
    expect(await f, null);
  }

  await testResolveWithNullOrUndefined(true);
  await testResolveWithNullOrUndefined(false);
  await testResolveWithNullOrUndefined<JSNumber?>(true);
  await testResolveWithNullOrUndefined<JSNumber?>(false);

  // Test rejecting generic promise with null and undefined should trigger an
  // exception.
  Future<void> testRejectionWithNullOrUndefined<T extends JSAny?>(
      bool rejectWithNull) async {
    try {
      await rejectPromiseWithNullOrUndefined<T>(rejectWithNull).toDart;
      fail('Expected rejected promise to throw.');
    } catch (e) {
      expect(e is NullRejectionException, true);
    }
  }

  await testRejectionWithNullOrUndefined(true);
  await testRejectionWithNullOrUndefined(false);
  await testRejectionWithNullOrUndefined<JSNumber?>(true);
  await testRejectionWithNullOrUndefined<JSNumber?>(false);

  // [Future] -> [JSPromise].
  // Test resolution.
  {
    final f = Future<JSAny?>(() => 'resolved'.toJS).toJS.toDart;
    expect(((await f) as JSString).toDart, 'resolved');
  }

  // Test resolution with generics.
  {
    final f = Future<JSString>(() => 'resolved'.toJS).toJS.toDart;
    expect((await f).toDart, 'resolved');
  }

  // Test resolution with incorrect types. Depending on the backend and the type
  // test, the promise may throw when its resolved or when the resolved value is
  // internalized.
  // TODO(54214): These type errors are not caught in the JS compilers
  // correctly.
  // {
  //   try {
  //     final f =
  //         (Future<JSString>(() => 'resolved'.toJS).toJS as JSPromise<JSBoolean>)
  //             .toDart;
  //     final jsBool = await f;
  //     // TODO(54179): This should be a `jsBool.toDart` call, but currently we
  //     // try to coerce all extern refs into primitive types in this conversion
  //     // method. Change this once that bug is fixed.
  //     if (!jsBool.typeofEquals('boolean')) throw TypeError();
  //     fail('Expected resolution or use of type to throw.');
  //   } catch (e) {
  //     expect(e is TypeError, true);
  //   }

  //   // Incorrect nullability.
  //   try {
  //     final f =
  //         (Future<JSString?>(() => null).toJS as JSPromise<JSString>).toDart;
  //     await f;
  //     fail('Expected incorrect nullability to throw.');
  //   } catch (e) {
  //     expect(e is TypeError, true);
  //   }
  // }

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
      final f =
          Future<void>(() => throw Exception()).toJS.toDart as Future<void>;
      await f;
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

void main() {
  syncTests();
  asyncTest(() async => await asyncTests());
}
