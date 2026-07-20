// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Check that JS types work.

import 'dart:collection';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import 'package:expect/async_helper.dart';
import 'package:expect/expect.dart';

const isJSBackend = const bool.fromEnvironment('dart.library.html');

@JS('Set')
extension type JSSet._(JSObject _) implements JSObject, JSIterable<JSNumber> {
  external JSSet(JSArray<JSNumber> contents);
}

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

@JS('Object.create')
external JSObject create([JSObject? proto]);

@JS()
external JSFunction fun;

@JS('fun')
external JSString doFun(JSString a, JSString b);

@JS()
external JSExportedDartFunction<JSString Function(JSString, JSString)> edf;

@JS()
external JSExportedDartFunction<JSString Function(JSObject, JSString, JSString)>
edfWithThis;

@JS()
external JSArray arr;

@JS('arr')
external JSArray<JSNumber> arrN;

@JS()
external JSArray<JSNumber?> arrNNullable;

@JS()
external JSArray<JSString> arrStr;

@JS()
external JSArray<JSString?> arrStrNullable;

@JS()
external JSArray<JSBoolean> arrBool;

@JS()
external JSArray<JSBoolean?> arrBoolNullable;

@JS()
external JSBoxedDartObject edo;

@JS()
external JSArrayBuffer buf;

extension on JSArrayBuffer {
  external int get byteLength;
}

@JS('SharedArrayBuffer')
external JSAny? get _sharedArrayBufferConstructor;

bool supportsSharedArrayBuffer = _sharedArrayBufferConstructor != null;

@JS('SharedArrayBuffer')
extension type JSSharedArrayBuffer._(JSObject _) implements JSObject {
  external JSSharedArrayBuffer(int length);
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

@JS('Uint8Array')
extension type JSUint8ArrayShared._(JSUint8Array _) implements JSUint8Array {
  external JSUint8ArrayShared(JSSharedArrayBuffer buf);
}

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

@JS()
external JSIterator<JSAny> getGenerator();

class CustomList<E> extends ListBase<E> {
  final List<E> _inner;

  CustomList(this._inner);

  int get length => _inner.length;

  set length(int value) {
    _inner.length = value;
  }

  E operator [](int index) => _inner[index];

  void operator []=(int index, E value) {
    _inner[index] = value;
  }

  void add(E value) {
    _inner.add(value);
  }

  void addAll(Iterable<E> values) {
    _inner.addAll(values);
  }
}

class DartObject {
  String get foo => 'bar';
}

@pragma('dart2js:never-inline')
@pragma('dart2js:assumeDynamic')
confuse(x) => x;

// TODO(srujzs): Split this test into multiple tests.
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
  Expect.isTrue(obj is JSObject);
  Expect.isTrue(confuse(obj) is JSObject);
  Expect.equals('bar', (obj as SimpleObject).foo.toDart);
  Expect.isNull(JSObject.getPrototypeOf(create(null)));
  final prototype = JSObject();
  Expect.equals(prototype, JSObject.getPrototypeOf(create(prototype)));
  // JS auto-boxes primitive values for `getPrototypeOf`.
  final stringPrototype = JSObject.getPrototypeOf(''.toJS);
  Expect.isNotNull(stringPrototype);
  Expect.isTrue(stringPrototype!.has('charAt'));

  // [JSFunction]
  Expect.isTrue(fun is JSFunction);
  Expect.isTrue(confuse(fun) is JSFunction);

  // [JSExportedDartFunction] <-> [Function]
  final dartFunction = (JSString a, JSString b) {
    return (a.toDart + b.toDart).toJS;
  };
  edf = dartFunction.toJS;
  // Should be able to assign to `JSFunction<T>`.
  JSFunction<JSString Function(JSString, JSString)> _ = edf;
  Expect.equals('foobar', doFun('foo'.toJS, 'bar'.toJS).toDart);
  Expect.equals('foobar', edf.toDart('foo'.toJS, 'bar'.toJS).toDart);
  Expect.identical(edf.toDart, dartFunction);
  // `toDart` with just `Function` should succeed.
  Expect.identical(
    (edf as JSExportedDartFunction<Function>).toDart,
    dartFunction,
  );
  // Two wrappers should not be the same.
  Expect.notEquals(edf, dartFunction.toJS);
  // If the wrong function type, `toDart` should throw.
  Expect.throws(() => (edf as JSExportedDartFunction<void Function()>).toDart);
  // Converting a non-function should throw.
  Expect.throws(() => ('foo'.toJS as JSExportedDartFunction).toDart);
  // `this` should be captured correctly in `toJSCaptureThis`.
  final this_ = JSObject();
  final dartFunctionThis = (JSObject this__, JSString a, JSString b) {
    Expect.equals(this_, this__);
    return (a.toDart + b.toDart).toJS;
  };
  edfWithThis = dartFunctionThis.toJSCaptureThis;
  Expect.equals(
    (edfWithThis.callAsFunction(
      this_,
      'foo'.toJS,
      'bar'.toJS,
    ) as JSString).toDart,
    'foobar',
  );
  Expect.identical(edfWithThis.toDart, dartFunctionThis);
  Expect.identical(
    (edfWithThis as JSExportedDartFunction).toDart,
    dartFunctionThis,
  );
  Expect.throws(
    () =>
        (edfWithThis as JSExportedDartFunction<int Function(JSString)>).toDart,
  );
  Expect.notEquals(edfWithThis, dartFunctionThis.toJSCaptureThis);

  // [JSIterable]
  final iterable = JSSet([1.toJS, 2.toJS].toJS);
  final iterator = iterable.iterator;
  Expect.isNull(iterator.returnValue);
  Expect.isNull(iterator.throwError);
  final result1 = iterator.next();
  Expect.isFalse(result1.isDone);
  Expect.equals(1.toJS, result1.value);
  final result2 = iterator.next();
  Expect.isFalse(result2.isDone);
  Expect.equals(2.toJS, result2.value);
  final result3 = iterator.next();
  Expect.isTrue(result3.isDone);
  Expect.isNull(result3.value);

  Expect.equals(2.toJS, iterable.iterator.drop(1).next().value);
  Expect.equals(
    1.toJS,
    JSIterator.fromFunctions(() => JSIteratorResult.value(1.toJS)).next().value,
  );
  Expect.equals(
    1.toJS,
    JSIterator.fromFunctions(
      () => JSIteratorResult.done(0.toJS),
      returnValue: () => JSIteratorResult.done(1.toJS),
    ).returnValue!().value,
  );

  eval(r'''
    globalThis.getGenerator = function*() {
      yield 1;
    }
  ''');
  Expect.equals(2.toJS, getGenerator().returnValue!(2.toJS).value);
  final returnNoArg = getGenerator().returnValue!().value;
  Expect.isTrue(
    isJSBackend ? returnNoArg.isUndefined : returnNoArg.isUndefinedOrNull,
  );
  Expect.throws<JSString>(() => getGenerator().throwError!("oh no".toJS));

  // Nullish errors should be caught and converted to Dart wrappers. These tests
  // are currently failing due to https://github.com/dart-lang/sdk/issues/63109.

  // Expect.throws(
  //   () => getGenerator().throwError!(null),
  //   (error) => !error.isA<JSAny?>(),
  // );
  // Expect.throws(
  //   () => getGenerator().throwError!(),
  //   (error) => !error.isA<JSAny?>(),
  // );

  // [JSIterable] <-> [Iterable]
  final listFromIter = [...iterable.toDartIterable];
  Expect.equals(2, listFromIter.length);
  Expect.equals(1.toJS, listFromIter[0]);
  Expect.equals(2.toJS, listFromIter[1]);
  final iteratorFromDart = [1.toJS].toJSIterable.iterator;
  Expect.equals(1.toJS, iteratorFromDart.next().value);
  Expect.isTrue(iteratorFromDart.next().isDone);

  // [JSBoxedDartObject] <-> [Object]
  edo = DartObject().toJSBox;
  Expect.isTrue(edo is JSBoxedDartObject);
  Expect.isTrue(confuse(edo) is JSBoxedDartObject);
  Expect.equals('bar', ((edo as JSBoxedDartObject).toDart as DartObject).foo);
  Expect.isTrue(edo.instanceOfString('Object'));
  // Functions should be boxed without assertInterop.
  final concat = (String a, String b) => a + b;
  edo = concat.toJSBox;
  Expect.equals(
    'foobar',
    (edo.toDart as String Function(String, String))('foo', 'bar'),
  );
  // Should not box a non Dart-object.
  Expect.throws(() => edo.toJSBox);

  // [JSArray] constructors and members.
  arrN = JSArray<JSNumber>();
  Expect.equals(0, arrN.length);
  arrN = JSArray<JSNumber>.withLength(4);
  Expect.equals(4, arrN.length);
  arrN.length = 1;
  Expect.equals(1, arrN.length);
  arrN[0] = 1.toJS;
  Expect.equals(1, arrN[0].toDartInt);
  arrN = JSArray.from<JSNumber>(arrN);
  Expect.equals(1, arrN.length);
  Expect.equals(1, arrN[0].toDartInt);
  arrN.add(0.toJS);
  Expect.equals(2, arrN.length);
  Expect.equals(0, arrN[1].toDartInt);
  final typedArray = JSArray.from<JSNumber>(JSUint8Array.withLength(4));
  Expect.equals(4, typedArray.length);
  Expect.equals(0, typedArray[0].toDartInt);

  // [JSArray] <-> [List<JSAny?>]
  final list = <JSAny?>[1.0.toJS, 'foo'.toJS];
  arr = list.toJS;
  Expect.isTrue(arr is JSArray);
  Expect.isTrue(confuse(arr) is JSArray);
  List<JSAny?> dartArr = arr.toDart;
  Expect.equals(1.0, (dartArr[0] as JSNumber).toDartDouble);
  Expect.equals('foo', (dartArr[1] as JSString).toDart);

  List<JSNumber> dartArrN = arrN.toDart;
  if (isJSBackend) {
    // Since lists on the JS backends are passed by ref, we only create a
    // cast-list if there's a downcast needed.
    Expect.equals(dartArr, list);
    Expect.equals(dartArr.toJS, arr);
    Expect.notEquals(dartArrN, list);
    Expect.throwsTypeError(() => dartArrN[1]);
    // `toJS` doesn't handle user-defined lists currently.
    Expect.throwsTypeError(() => dartArrN.toJS);
  } else {
    // dart2wasm clones the list if it was instantiated in Dart and otherwise it
    // unwraps when using `toJS`.
    Expect.notEquals(dartArr, list);
    Expect.equals(dartArr.toJS, arr);
    Expect.notEquals(dartArrN, list);
    dartArrN[1];
    Expect.equals(dartArrN.toJS, arrN);
  }

  // [JSArray<T>] <-> [List<T>]
  final listN = <JSNumber>[1.0.toJS, 2.0.toJS];
  arrN = listN.toJS;
  Expect.isTrue(arrN is JSArray<JSNumber>);
  Expect.isTrue(confuse(arrN) is JSArray<JSNumber>);

  dartArr = arr.toDart;
  dartArrN = arrN.toDart;
  if (isJSBackend) {
    // A cast-list should not be introduced if the array is already the
    // right list type.
    Expect.equals(dartArr, listN);
    Expect.equals(dartArr.toJS, arrN);
    Expect.equals(dartArrN, listN);
    Expect.equals(dartArrN.toJS, arrN);
  } else {
    // dart2wasm clones the list if it was instantiated in Dart and otherwise it
    // unwraps when using `toJS`.
    Expect.notEquals(dartArr, listN);
    Expect.equals(dartArr.toJS, arrN);
    Expect.notEquals(dartArrN, listN);
    Expect.equals(dartArrN.toJS, arrN);
  }

  // [JSArray<JSNumber>] <-> [List<double>]
  final listOfDoubles = <double>[1.0, 2.0];
  final arrayOfDoubles = listOfDoubles.toJS;
  Expect.isTrue(arrayOfDoubles is JSArray<JSNumber>);
  Expect.isTrue(confuse(arrayOfDoubles) is JSArray<JSNumber>);

  var dartArrayOfDoubles = arrayOfDoubles.toDartDoubleList;
  Expect.equals(dartArrayOfDoubles.length, listOfDoubles.length);
  Expect.equals(dartArrayOfDoubles[0], listOfDoubles[0]);
  Expect.equals(dartArrayOfDoubles[1], listOfDoubles[1]);

  if (isJSBackend) {
    Expect.equals(dartArrayOfDoubles, listOfDoubles);
    Expect.equals(dartArrayOfDoubles.toJS, listOfDoubles);
  } else {
    Expect.notEquals(dartArrayOfDoubles, listOfDoubles);
    Expect.notEquals(dartArrayOfDoubles.toJS, listOfDoubles);
  }

  arrN = JSArray();
  arrN.add((1.0).toJS);
  dartArrayOfDoubles = arrN.toDartDoubleList;
  Expect.equals(dartArrayOfDoubles.length, 1);
  Expect.equals(dartArrayOfDoubles[0], 1.0);

  Expect.throws(() => CustomList([1.0]).toJS);

  // [JSArray<JSNumber>] <-> [List<int>]
  final listOfInts = <int>[1, 2];
  final arrayOfInts = listOfInts.toJS;
  Expect.isTrue(arrayOfInts is JSArray<JSNumber>);
  Expect.isTrue(confuse(arrayOfInts) is JSArray<JSNumber>);

  final dartArrayOfInts = arrayOfInts.toDartIntList;
  Expect.equals(dartArrayOfInts.length, listOfInts.length);
  Expect.equals(dartArrayOfInts[0], listOfInts[0]);
  Expect.equals(dartArrayOfInts[1], listOfInts[1]);

  if (isJSBackend) {
    Expect.equals(dartArrayOfInts, listOfInts);
    Expect.equals(dartArrayOfInts.toJS, listOfInts);
  } else {
    Expect.notEquals(dartArrayOfInts, listOfInts);
    Expect.notEquals(dartArrayOfInts.toJS, listOfInts);
  }

  Expect.throws(() => CustomList([1]).toJS);

  // Copy the list to elicit an error even on platforms where this only throws
  // lazily.
  Expect.throws(() => List.of([1.5.toJS].toJS.toDartIntList));

  // [JSArray<JSNumber?>] <-> [List<double?>]
  final listOfNullableDoubles = <double?>[1.0, null];
  final arrayOfNullableDoubles = listOfNullableDoubles.toJS;
  Expect.isTrue(arrayOfNullableDoubles is JSArray<JSNumber?>);
  Expect.isTrue(confuse(arrayOfNullableDoubles) is JSArray<JSNumber?>);

  var dartArrayOfNullableDoubles = arrayOfNullableDoubles.toDartDoubleList;
  Expect.equals(
    dartArrayOfNullableDoubles.length,
    listOfNullableDoubles.length,
  );
  Expect.equals(dartArrayOfNullableDoubles[0], listOfNullableDoubles[0]);
  Expect.equals(dartArrayOfNullableDoubles[1], listOfNullableDoubles[1]);

  if (isJSBackend) {
    Expect.equals(dartArrayOfNullableDoubles, listOfNullableDoubles);
    Expect.equals(dartArrayOfNullableDoubles.toJS, listOfNullableDoubles);
  } else {
    Expect.notEquals(dartArrayOfNullableDoubles, listOfNullableDoubles);
    Expect.notEquals(dartArrayOfNullableDoubles.toJS, listOfNullableDoubles);
  }

  arrNNullable = JSArray();
  arrNNullable.add((1.0).toJS);
  arrNNullable.add(null);
  dartArrayOfNullableDoubles = arrNNullable.toDartDoubleList;
  Expect.equals(dartArrayOfNullableDoubles.length, 2);
  Expect.equals(dartArrayOfNullableDoubles[0], 1.0);
  Expect.equals(dartArrayOfNullableDoubles[1], null);

  Expect.throws(() => CustomList(<double?>[1.0]).toJS);

  // [JSArray<JSNumber?>] <-> [List<int?>]
  final listOfNullableInts = <int?>[1, null];
  final arrayOfNullableInts = listOfNullableInts.toJS;
  Expect.isTrue(arrayOfNullableInts is JSArray<JSNumber?>);
  Expect.isTrue(confuse(arrayOfNullableInts) is JSArray<JSNumber?>);

  final dartArrayOfNullableInts = arrayOfNullableInts.toDartIntList;
  Expect.equals(dartArrayOfNullableInts.length, listOfNullableInts.length);
  Expect.equals(dartArrayOfNullableInts[0], listOfNullableInts[0]);
  Expect.equals(dartArrayOfNullableInts[1], listOfNullableInts[1]);

  if (isJSBackend) {
    Expect.equals(dartArrayOfNullableInts, listOfNullableInts);
    Expect.equals(dartArrayOfNullableInts.toJS, listOfNullableInts);
  } else {
    Expect.notEquals(dartArrayOfNullableInts, listOfNullableInts);
    Expect.notEquals(dartArrayOfNullableInts.toJS, listOfNullableInts);
  }

  Expect.throws(() => CustomList(<int?>[1]).toJS);

  // Copy the list to elicit an error even on platforms where this only throws
  // lazily.
  Expect.throws(() => List.of([1.5.toJS, null].toJS.toDartIntList));

  // [JSArray<JSString>] <-> [List<String>]
  final listOfStrings = ["foo", "bar"];
  final arrayOfStrings = listOfStrings.toJS;
  Expect.isTrue(arrayOfStrings is JSArray<JSString>);
  Expect.isTrue(confuse(arrayOfStrings) is JSArray<JSString>);

  var dartArrayOfStrings = arrayOfStrings.toDartStringList;
  Expect.equals(dartArrayOfStrings.length, listOfStrings.length);
  Expect.equals(dartArrayOfStrings[0], listOfStrings[0]);
  Expect.equals(dartArrayOfStrings[1], listOfStrings[1]);

  if (isJSBackend) {
    Expect.equals(dartArrayOfStrings, listOfStrings);
    Expect.equals(dartArrayOfStrings.toJS, listOfStrings);
  } else {
    Expect.notEquals(dartArrayOfStrings, listOfStrings);
    Expect.notEquals(dartArrayOfStrings.toJS, listOfStrings);
  }

  arrStr = JSArray();
  arrStr.add("a".toJS);
  dartArrayOfStrings = arrStr.toDartStringList;
  Expect.equals(dartArrayOfStrings.length, 1);
  Expect.equals(dartArrayOfStrings[0], "a");

  Expect.throws(() => CustomList(["a"]).toJS);

  // [JSArray<JSString?>] <-> [List<String?>]
  final listOfNullableStrings = ["foo", null];
  final arrayOfNullableStrings = listOfNullableStrings.toJS;
  Expect.isTrue(arrayOfNullableStrings is JSArray<JSString?>);
  Expect.isTrue(confuse(arrayOfNullableStrings) is JSArray<JSString?>);

  var dartArrayOfNullableStrings = arrayOfNullableStrings.toDartStringList;
  Expect.equals(
    dartArrayOfNullableStrings.length,
    listOfNullableStrings.length,
  );
  Expect.equals(dartArrayOfNullableStrings[0], listOfNullableStrings[0]);
  Expect.equals(dartArrayOfNullableStrings[1], listOfNullableStrings[1]);

  if (isJSBackend) {
    Expect.equals(dartArrayOfNullableStrings, listOfNullableStrings);
    Expect.equals(dartArrayOfNullableStrings.toJS, listOfNullableStrings);
  } else {
    Expect.notEquals(dartArrayOfNullableStrings, listOfNullableStrings);
    Expect.notEquals(dartArrayOfNullableStrings.toJS, listOfNullableStrings);
  }

  arrStrNullable = JSArray();
  arrStrNullable.add("a".toJS);
  arrStrNullable.add(null);
  dartArrayOfNullableStrings = arrStrNullable.toDartStringList;
  Expect.equals(dartArrayOfNullableStrings.length, 2);
  Expect.equals(dartArrayOfNullableStrings[0], "a");
  Expect.equals(dartArrayOfNullableStrings[1], null);

  Expect.throws(() => CustomList(<String?>["a"]).toJS);

  // [JSArray<JSBoolean>] <-> [List<bool>]
  final listOfBools = [true, false];
  final arrayOfBooleans = listOfBools.toJS;
  Expect.isTrue(arrayOfBooleans is JSArray<JSBoolean>);
  Expect.isTrue(confuse(arrayOfBooleans) is JSArray<JSBoolean>);

  var dartArrayOfBooleans = arrayOfBooleans.toDartBoolList;
  Expect.equals(dartArrayOfBooleans.length, listOfBools.length);
  Expect.equals(dartArrayOfBooleans[0], listOfBools[0]);
  Expect.equals(dartArrayOfBooleans[1], listOfBools[1]);

  if (isJSBackend) {
    Expect.equals(dartArrayOfBooleans, listOfBools);
    Expect.equals(dartArrayOfBooleans.toJS, listOfBools);
  } else {
    Expect.notEquals(dartArrayOfBooleans, listOfBools);
    Expect.notEquals(dartArrayOfBooleans.toJS, listOfBools);
  }

  arrBool = JSArray();
  arrBool.add(true.toJS);
  dartArrayOfBooleans = arrBool.toDartBoolList;
  Expect.equals(dartArrayOfBooleans.length, 1);
  Expect.equals(dartArrayOfBooleans[0], true);

  Expect.throws(() => CustomList([true]).toJS);

  // [JSArray<JSBoolean>] <-> [List<bool>]
  final listOfNullableBools = [true, null];
  final arrayOfNullableBooleans = listOfNullableBools.toJS;
  Expect.isTrue(arrayOfNullableBooleans is JSArray<JSBoolean?>);
  Expect.isTrue(confuse(arrayOfNullableBooleans) is JSArray<JSBoolean?>);

  var dartArrayOfNullableBooleans = arrayOfNullableBooleans.toDartBoolList;
  Expect.equals(
    dartArrayOfNullableBooleans.length,
    listOfNullableBools.length,
  );
  Expect.equals(dartArrayOfNullableBooleans[0], listOfNullableBools[0]);
  Expect.equals(dartArrayOfNullableBooleans[1], listOfNullableBools[1]);

  if (isJSBackend) {
    Expect.equals(dartArrayOfNullableBooleans, listOfNullableBools);
    Expect.equals(dartArrayOfNullableBooleans.toJS, listOfNullableBools);
  } else {
    Expect.notEquals(dartArrayOfNullableBooleans, listOfNullableBools);
    Expect.notEquals(dartArrayOfNullableBooleans.toJS, listOfNullableBools);
  }

  arrBoolNullable = JSArray();
  arrBoolNullable.add(true.toJS);
  arrBoolNullable.add(null);
  dartArrayOfNullableBooleans = arrBoolNullable.toDartBoolList;
  Expect.equals(dartArrayOfNullableBooleans.length, 2);
  Expect.equals(dartArrayOfNullableBooleans[0], true);
  Expect.equals(dartArrayOfNullableBooleans[1], null);

  Expect.throws(() => CustomList(<bool?>[true]).toJS);

  // [ArrayBuffer] <-> [ByteBuffer]
  buf = Uint8List.fromList([0, 255, 0, 255]).buffer.toJS;
  Expect.isTrue(buf is JSArrayBuffer);
  Expect.isTrue(confuse(buf) is JSArrayBuffer);
  ByteBuffer dartBuf = buf.toDart;
  Expect.listEquals([0, 255, 0, 255], dartBuf.asUint8List());
  Expect.equals(buf, dartBuf.toJS);
  buf = JSArrayBuffer(5);
  Expect.equals(5, buf.byteLength);
  buf = JSArrayBuffer(5, {'maxByteLength': 12}.jsify() as JSObject);
  // TODO(https://github.com/dart-lang/sdk/issues/61043): Support this in the
  // test runner.
  if (supportsSharedArrayBuffer) {
    final sharedArrayBuffer = JSSharedArrayBuffer(4);
    final sharedByteBuffer = JSUint8ArrayShared(sharedArrayBuffer)
        .toDart
        .buffer;
    // Not a `JSArrayBuffer`.
    Expect.throws(() => sharedByteBuffer.toJS);
  }

  // [DataView] <-> [ByteData]
  final datBuf = Uint8List.fromList([0, 255, 0, 255]).buffer.toJS;
  dat = datBuf.toDart.asByteData().toJS;
  Expect.isTrue(dat is JSDataView);
  Expect.isTrue(confuse(dat) is JSDataView);
  ByteData dartDat = dat.toDart;
  Expect.equals(0, dartDat.getUint8(0));
  Expect.equals(255, dartDat.getUint8(1));
  Expect.equals(dat, dartDat.toJS);
  dat = JSDataView(datBuf);
  Expect.equals(datBuf, dat.buffer);
  final dat2 = JSDataView(datBuf, 1, 3);
  Expect.equals(1, dat2.byteOffset);
  Expect.equals(3, dat2.byteLength);

  // [TypedArray]s <-> [TypedData]s
  // Test common TypedArray constructors for different subtypes.
  void testTypedArrayConstructors(
    JSTypedArray Function(JSArrayBuffer) createFromBuffer,
    JSTypedArray Function(JSArrayBuffer, int, int)
    createFromBufferOffsetAndLength,
    JSTypedArray Function(int) createFromLength,
    int byteSize,
  ) {
    var byteLength = 16;
    final buf = JSArrayBuffer(byteLength);
    var typedArray = createFromBuffer(buf);
    Expect.equals(buf, typedArray.buffer);
    Expect.equals(byteLength, typedArray.byteLength);
    Expect.equals(0, typedArray.byteOffset);
    Expect.equals(typedArray.length, byteLength ~/ byteSize);

    byteLength = 8;
    typedArray = createFromBufferOffsetAndLength(
      buf,
      8,
      byteLength ~/ byteSize,
    );
    Expect.equals(buf, typedArray.buffer);
    Expect.equals(byteLength, typedArray.byteLength);
    Expect.equals(8, typedArray.byteOffset);
    Expect.equals(typedArray.length, byteLength ~/ byteSize);

    typedArray = createFromLength(byteLength ~/ byteSize);
    Expect.equals(byteLength, typedArray.byteLength);
    Expect.equals(0, typedArray.byteOffset);
    Expect.equals(typedArray.length, byteLength ~/ byteSize);
  }

  // Int8
  ai8 = Int8List.fromList([-128, 0, 127]).toJS;
  Expect.isTrue(ai8 is JSInt8Array);
  Expect.isTrue(confuse(ai8) is JSInt8Array);
  Int8List dartAi8 = ai8.toDart;
  Expect.listEquals([-128, 0, 127], dartAi8);
  Expect.equals(ai8, dartAi8.toJS);
  testTypedArrayConstructors(
    (JSArrayBuffer obj) => JSInt8Array(obj),
    (JSArrayBuffer obj, int byteOffset, int length) =>
        JSInt8Array(obj, byteOffset, length),
    (int length) => JSInt8Array.withLength(length),
    1,
  );

  // Uint8
  au8 = Uint8List.fromList([-1, 0, 255, 256]).toJS;
  Expect.isTrue(au8 is JSUint8Array);
  Expect.isTrue(confuse(au8) is JSUint8Array);
  Uint8List dartAu8 = au8.toDart;
  Expect.listEquals([255, 0, 255, 0], dartAu8);
  Expect.equals(au8, dartAu8.toJS);
  testTypedArrayConstructors(
    (JSArrayBuffer obj) => JSUint8Array(obj),
    (JSArrayBuffer obj, int byteOffset, int length) =>
        JSUint8Array(obj, byteOffset, length),
    (int length) => JSUint8Array.withLength(length),
    1,
  );

  // Uint8Clamped
  ac8 = Uint8ClampedList.fromList([-1, 0, 255, 256]).toJS;
  Expect.isTrue(ac8 is JSUint8ClampedArray);
  Expect.isTrue(confuse(ac8) is JSUint8ClampedArray);
  Uint8ClampedList dartAc8 = ac8.toDart;
  Expect.listEquals([0, 0, 255, 255], dartAc8);
  Expect.equals(ac8, dartAc8.toJS);
  testTypedArrayConstructors(
    (JSArrayBuffer obj) => JSUint8ClampedArray(obj),
    (JSArrayBuffer obj, int byteOffset, int length) =>
        JSUint8ClampedArray(obj, byteOffset, length),
    (int length) => JSUint8ClampedArray.withLength(length),
    1,
  );

  // Int16
  ai16 = Int16List.fromList([-32769, -32768, 0, 32767, 32768]).toJS;
  Expect.isTrue(ai16 is JSInt16Array);
  Expect.isTrue(confuse(ai16) is JSInt16Array);
  Int16List dartAi16 = ai16.toDart;
  Expect.listEquals([32767, -32768, 0, 32767, -32768], dartAi16);
  Expect.equals(ai16, dartAi16.toJS);
  testTypedArrayConstructors(
    (JSArrayBuffer obj) => JSInt16Array(obj),
    (JSArrayBuffer obj, int byteOffset, int length) =>
        JSInt16Array(obj, byteOffset, length),
    (int length) => JSInt16Array.withLength(length),
    2,
  );

  // Uint16
  au16 = Uint16List.fromList([-1, 0, 65535, 65536]).toJS;
  Expect.isTrue(au16 is JSUint16Array);
  Expect.isTrue(confuse(au16) is JSUint16Array);
  Uint16List dartAu16 = au16.toDart;
  Expect.listEquals([65535, 0, 65535, 0], dartAu16);
  Expect.equals(au16, dartAu16.toJS);
  testTypedArrayConstructors(
    (JSArrayBuffer obj) => JSUint16Array(obj),
    (JSArrayBuffer obj, int byteOffset, int length) =>
        JSUint16Array(obj, byteOffset, length),
    (int length) => JSUint16Array.withLength(length),
    2,
  );

  // Int32
  ai32 = Int32List.fromList([-2147483648, 0, 2147483647]).toJS;
  Expect.isTrue(ai32 is JSInt32Array);
  Expect.isTrue(confuse(ai32) is JSInt32Array);
  Int32List dartAi32 = ai32.toDart;
  Expect.listEquals([-2147483648, 0, 2147483647], dartAi32);
  Expect.equals(ai32, dartAi32.toJS);
  testTypedArrayConstructors(
    (JSArrayBuffer obj) => JSInt32Array(obj),
    (JSArrayBuffer obj, int byteOffset, int length) =>
        JSInt32Array(obj, byteOffset, length),
    (int length) => JSInt32Array.withLength(length),
    4,
  );

  // Uint32
  au32 = Uint32List.fromList([-1, 0, 4294967295, 4294967296]).toJS;
  Expect.isTrue(au32 is JSUint32Array);
  Expect.isTrue(confuse(au32) is JSUint32Array);
  Uint32List dartAu32 = au32.toDart;
  Expect.listEquals([4294967295, 0, 4294967295, 0], dartAu32);
  Expect.equals(au32, dartAu32.toJS);
  testTypedArrayConstructors(
    (JSArrayBuffer obj) => JSUint32Array(obj),
    (JSArrayBuffer obj, int byteOffset, int length) =>
        JSUint32Array(obj, byteOffset, length),
    (int length) => JSUint32Array.withLength(length),
    4,
  );

  // Float32
  af32 = Float32List.fromList([-1000.488, -0.00001, 0.0001, 10004.888]).toJS;
  Expect.isTrue(af32 is JSFloat32Array);
  Expect.isTrue(confuse(af32) is JSFloat32Array);
  Float32List dartAf32 = af32.toDart;
  Expect.listEquals(
    Float32List.fromList([-1000.488, -0.00001, 0.0001, 10004.888]),
    dartAf32,
  );
  Expect.equals(af32, dartAf32.toJS);
  testTypedArrayConstructors(
    (JSArrayBuffer obj) => JSFloat32Array(obj),
    (JSArrayBuffer obj, int byteOffset, int length) =>
        JSFloat32Array(obj, byteOffset, length),
    (int length) => JSFloat32Array.withLength(length),
    4,
  );

  // Float64
  af64 = Float64List.fromList([-1000.488, -0.00001, 0.0001, 10004.888]).toJS;
  Expect.isTrue(af64 is JSFloat64Array);
  Expect.isTrue(confuse(af64) is JSFloat64Array);
  Float64List dartAf64 = af64.toDart;
  Expect.listEquals([-1000.488, -0.00001, 0.0001, 10004.888], dartAf64);
  Expect.equals(af64, dartAf64.toJS);
  testTypedArrayConstructors(
    (JSArrayBuffer obj) => JSFloat64Array(obj),
    (JSArrayBuffer obj, int byteOffset, int length) =>
        JSFloat64Array(obj, byteOffset, length),
    (int length) => JSFloat64Array.withLength(length),
    8,
  );

  // [JSNumber] <-> [double]
  nbr = 4.5.toJS;
  Expect.isTrue(nbr is JSNumber);
  Expect.isTrue(confuse(nbr) is JSNumber);
  double dartNbr = nbr.toDartDouble;
  Expect.equals(4.5, dartNbr);

  // [JSBoolean] <-> [bool]
  boo = true.toJS;
  Expect.isTrue(boo is JSBoolean);
  Expect.isTrue(confuse(boo) is JSBoolean);
  bool dartBoo = boo.toDart;
  Expect.isTrue(dartBoo);

  // [JSString] <-> [String]
  str = 'foo'.toJS;
  Expect.isTrue(str is JSString);
  Expect.isTrue(confuse(str) is JSString);
  String dartStr = str.toDart;
  Expect.equals('foo', dartStr);

  // [JSSymbol]
  symbol = JSSymbol('foo');
  Expect.isTrue(symbol is JSSymbol);
  Expect.isTrue(confuse(symbol) is JSSymbol);
  Expect.equals('Symbol(foo)', symbol.toStringExternal());
  Expect.equals(symbol.description, 'foo');
  Expect.notEquals(JSSymbol.forKey('foo'), symbol);
  Expect.equals(JSSymbol.forKey('foo'), JSSymbol.forKey('foo'));
  Expect.equals(JSSymbol.forKey('foo').key, 'foo');
  Expect.isTrue(JSSymbol.asyncIterator is JSSymbol);
  Expect.isTrue(JSSymbol.hasInstance is JSSymbol);
  Expect.isTrue(JSSymbol.isConcatSpreadable is JSSymbol);
  Expect.isTrue(JSSymbol.iterator is JSSymbol);
  Expect.isTrue(JSSymbol.match is JSSymbol);
  Expect.isTrue(JSSymbol.matchAll is JSSymbol);
  Expect.isTrue(JSSymbol.replace is JSSymbol);
  Expect.isTrue(JSSymbol.search is JSSymbol);
  Expect.isTrue(JSSymbol.species is JSSymbol);
  Expect.isTrue(JSSymbol.split is JSSymbol);
  Expect.isTrue(JSSymbol.toPrimitive is JSSymbol);
  Expect.isTrue(JSSymbol.toStringTag is JSSymbol);
  Expect.isTrue(JSSymbol.unscopables is JSSymbol);

  // [JSBigInt]
  bigInt = createBigInt('9876543210000000000000123456789');
  Expect.isTrue(bigInt is JSBigInt);
  Expect.isTrue(confuse(bigInt) is JSBigInt);
  Expect.equals('9876543210000000000000123456789', bigInt.toStringExternal());

  // null and undefined can flow into `JSAny?`.
  // TODO(srujzs): Remove the `isJSBackend` checks when `JSNull` and
  // `JSUndefined` can be distinguished on dart2wasm.
  if (isJSBackend) {
    Expect.isTrue(nullAny.isNull);
    Expect.isFalse(nullAny.isUndefined);
  }
  Expect.isNull(nullAny);
  Expect.isTrue(nullAny.isUndefinedOrNull);
  Expect.isFalse(nullAny.isDefinedAndNotNull);
  Expect.isTrue(nullAny.typeofEquals('object'));
  if (isJSBackend) {
    Expect.isFalse(undefinedAny.isNull);
    Expect.isTrue(undefinedAny.isUndefined);
  }
  Expect.isTrue(undefinedAny.isUndefinedOrNull);
  Expect.isFalse(undefinedAny.isDefinedAndNotNull);
  if (isJSBackend) {
    Expect.isTrue(undefinedAny.typeofEquals('undefined'));
    Expect.isFalse(definedNonNullAny.isNull);
    Expect.isFalse(definedNonNullAny.isUndefined);
  } else {
    Expect.isTrue(undefinedAny.typeofEquals('object'));
  }
  Expect.isFalse(definedNonNullAny.isUndefinedOrNull);
  Expect.isTrue(definedNonNullAny.isDefinedAndNotNull);
  Expect.isTrue(definedNonNullAny.typeofEquals('object'));
}

@JS()
external JSPromise<T> getResolvedPromise<T extends JSAny?>();

@JS()
external JSPromise<T> getRejectedPromise<T extends JSAny?>();

@JS()
external JSPromise<T> resolvePromiseWithNullOrUndefined<T extends JSAny?>(
  bool resolveWithNull,
);

@JS()
external JSPromise<T> rejectPromiseWithNullOrUndefined<T extends JSAny?>(
  bool resolveWithNull,
);

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
    Expect.equals('resolved', ((await f) as JSString).toDart);
  }

  // Test resolution with generics.
  {
    final f = getResolvedPromise<JSString>().toDart;
    Expect.equals('resolved', (await f).toDart);
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
      Expect.fail('Expected rejected promise to throw.');
    } catch (e) {
      final jsError = e as JSObject;
      Expect.equals('Error: rejected', jsError.toString());
    }
  }

  // Test rejection with generics.
  {
    try {
      await getRejectedPromise<JSString>().toDart;
      Expect.fail('Expected rejected promise to throw.');
    } catch (e) {
      final jsError = e as JSObject;
      Expect.equals('Error: rejected', jsError.toString());
    }
  }

  // Test resolution Promise chaining.
  {
    bool didThen = false;
    final f = getResolvedPromise().toDart.then((resolved) {
      Expect.equals('resolved', (resolved as JSString).toDart);
      didThen = true;
      return null;
    });
    await f;
    Expect.isTrue(didThen);
  }

  // Test rejection Promise chaining.
  {
    final f = getRejectedPromise().toDart.then(
      (_) {
        Expect.fail('Expected rejected promise to throw.');
        return null;
      },
      onError: (e) {
        final jsError = e as JSObject;
        Expect.equals('Error: rejected', jsError.toString());
      },
    );
    await f;
  }

  // Test resolving generic promise with null and undefined.
  Future<void> testResolveWithNullOrUndefined<T extends JSAny?>(
    bool resolveWithNull,
  ) async {
    final f = resolvePromiseWithNullOrUndefined<T>(resolveWithNull).toDart;
    Expect.isNull(await f);
  }

  await testResolveWithNullOrUndefined(true);
  await testResolveWithNullOrUndefined(false);
  await testResolveWithNullOrUndefined<JSNumber?>(true);
  await testResolveWithNullOrUndefined<JSNumber?>(false);

  // Test rejecting generic promise with null and undefined should trigger an
  // exception.
  Future<void> testRejectionWithNullOrUndefined<T extends JSAny?>(
    bool rejectWithNull,
  ) async {
    try {
      await rejectPromiseWithNullOrUndefined<T>(rejectWithNull).toDart;
      Expect.fail('Expected rejected promise to throw.');
    } catch (e) {
      Expect.isTrue(e is NullRejectionException);
      Expect.equals(rejectWithNull, !(e as NullRejectionException).isUndefined);
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
    Expect.equals('resolved', ((await f) as JSString).toDart);
  }

  // Test resolution with generics.
  {
    final f = Future<JSString>(() => 'resolved'.toJS).toJS.toDart;
    Expect.equals('resolved', (await f).toDart);
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
      Expect.fail('Expected future to throw.');
    } catch (e) {
      Expect.isTrue(e is JSObject);
      final jsError = e as JSObject;
      Expect.isTrue(jsError.instanceof(globalContext['Error'] as JSFunction));
      Expect.isTrue(
        (jsError['error'] as JSBoxedDartObject).toDart is Exception,
      );
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
    Expect.isTrue(compute);
  }

  // Test rejection.
  {
    try {
      final f =
          Future<void>(() => throw Exception()).toJS.toDart as Future<void>;
      await f;
      Expect.fail('Expected future to throw.');
    } catch (e) {
      Expect.isTrue(e is JSObject);
      final jsError = e as JSObject;
      Expect.isTrue(jsError.instanceof(globalContext['Error'] as JSFunction));
      Expect.isTrue(
        (jsError['error'] as JSBoxedDartObject).toDart is Exception,
      );
      StackTrace.fromString((jsError['stack'] as JSString).toDart);
    }
  }
}

void main() {
  syncTests();
  asyncTest(() async => await asyncTests());
}
