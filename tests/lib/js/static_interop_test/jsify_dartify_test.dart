// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import 'package:expect/expect.dart';

void _expectIterableEquals(Iterable<Object?> l, Iterable<Object?> r) {
  final lIt = l.iterator;
  final rIt = r.iterator;
  while (lIt.moveNext()) {
    Expect.isTrue(rIt.moveNext());
    _expectRecEquals(lIt.current, rIt.current);
  }
  Expect.isFalse(rIt.moveNext());
}

void _expectRecEquals(Object? l, Object? r) {
  if (l is Iterable && r is Iterable) {
    _expectIterableEquals(l, r);
  } else if (l is Map && r is Map) {
    _expectIterableEquals(l.keys, r.keys);
    for (final key in l.keys) {
      _expectRecEquals(l[key], r[key]);
    }
  } else {
    Expect.equals(l, r);
  }
}

@JS()
external void eval(String code);

void main() {
  // Dart to JS.
  Expect.isNull(null.jsify().dartify());
  Expect.isTrue(true.jsify().isA<JSBoolean>());
  Expect.equals(true, true.jsify().dartify() as bool);
  Expect.isTrue(2.0.jsify().isA<JSNumber>());
  Expect.equals(2.0, 2.0.jsify().dartify() as double);
  Expect.isTrue(0.jsify().isA<JSNumber>());
  Expect.equals(0.0, 0.jsify().dartify() as double);
  Expect.isTrue('foo'.jsify().isA<JSString>());
  Expect.equals('foo', 'foo'.jsify().dartify() as String);
  List<Object?> l = ['a', 'b', 'c'];
  Expect.isTrue(l.jsify().isA<JSArray>());
  _expectRecEquals(l, l.jsify().dartify() as List<Object?>);
  _expectRecEquals(
      {
        'null': 'foo',
        'foo': null,
        'a': 1,
        'b': true,
        'c': [1, 2, 3, null],
        'd': 'foo',
        'e': {
          'f': 2,
          'g': [2, 4, 6]
        },
      },
      {
        'null': 'foo',
        'foo': null,
        'a': 1,
        'b': true,
        'c': [1, 2, 3, null],
        'd': 'foo',
        'e': {
          'f': 2,
          'g': [2, 4, 6]
        },
      }.jsify().dartify());
  l = Int8List.fromList(<int>[-128, 0, 127]);
  Expect.isTrue(l.jsify().isA<JSInt8Array>());
  _expectIterableEquals(l, l.jsify().dartify() as Int8List);
  l = Uint8List.fromList([-1, 0, 255, 256]);
  Expect.isTrue(l.jsify().isA<JSUint8Array>());
  _expectIterableEquals(l, l.jsify().dartify() as Uint8List);
  l = Uint8ClampedList.fromList([-1, 0, 255, 256]);
  Expect.isTrue(l.jsify().isA<JSUint8ClampedArray>());
  _expectIterableEquals(l, l.jsify().dartify() as Uint8ClampedList);
  l = Int16List.fromList([-32769, -32768, 0, 32767, 32768]);
  Expect.isTrue(l.jsify().isA<JSInt16Array>());
  _expectIterableEquals(l, l.jsify().dartify() as Int16List);
  l = Uint16List.fromList([-1, 0, 65535, 65536]);
  Expect.isTrue(l.jsify().isA<JSUint16Array>());
  _expectIterableEquals(l, l.jsify().dartify() as Uint16List);
  l = Int32List.fromList([-2147483648, 0, 2147483647]);
  Expect.isTrue(l.jsify().isA<JSInt32Array>());
  _expectIterableEquals(l, l.jsify().dartify() as Int32List);
  l = Uint32List.fromList([-1, 0, 4294967295, 4294967296]);
  Expect.isTrue(l.jsify().isA<JSUint32Array>());
  _expectIterableEquals(l, l.jsify().dartify() as Uint32List);
  l = Float32List.fromList([-1000.488, -0.00001, 0.0001, 10004.888]);
  Expect.isTrue(l.jsify().isA<JSFloat32Array>());
  _expectIterableEquals(l, l.jsify().dartify() as Float32List);
  l = Float64List.fromList([-1000.488, -0.00001, 0.0001, 10004.888]);
  Expect.isTrue(l.jsify().isA<JSFloat64Array>());
  _expectIterableEquals(l, l.jsify().dartify() as Float64List);
  ByteBuffer buffer = Uint8List.fromList([0, 1, 2, 3]).buffer;
  Expect.isTrue(buffer.jsify().isA<JSArrayBuffer>());
  _expectIterableEquals(buffer.asUint8List(),
      (buffer.jsify().dartify() as ByteBuffer).asUint8List());
  ByteData byteData = ByteData.view(buffer);
  Expect.isTrue(byteData.jsify().isA<JSDataView>());
  _expectIterableEquals(byteData.buffer.asUint8List(),
      (byteData.jsify().dartify() as ByteData).buffer.asUint8List());

  // JS to Dart.
  eval(r'''
    globalThis.a = null;
    globalThis.b = undefined;
    globalThis.c = 'foo';
    globalThis.d = ['a', 'b', 'c'];
    globalThis.e = 2.5;
    globalThis.f = true;
    globalThis.g = function () { return 'hello world'; };
    globalThis.h = {
        null: 'foo',
        'foo': null,
        'a': 1,
        'b': true,
        'c': [1, 2, 3, null],
        'd': 'foo',
        'e': {'f': 2, 'g': [2, 4, 6]},
      };
    globalThis.invoke = function (f) { return f(); }
    globalThis.rec = {};
    globalThis.rec = {'a': rec};
    globalThis.int8Array = new Int8Array([-128, 0, 127]);
    globalThis.uint8Array = new Uint8Array([-1, 0, 255, 256]);
    globalThis.uint8ClampedArray = new Uint8ClampedArray([-1, 0, 255, 256]);
    globalThis.int16Array = new Int16Array([-32769, -32768, 0, 32767, 32768]);
    globalThis.uint16Array = new Uint16Array([-1, 0, 65535, 65536]);
    globalThis.int32Array = new Int32Array([-2147483648, 0, 2147483647]);
    globalThis.uint32Array = new Uint32Array([-1, 0, 4294967295, 4294967296]);
    globalThis.float32Array = new Float32Array([-1000.488, -0.00001, 0.0001,
        10004.888]);
    globalThis.float64Array = new Float64Array([-1000.488, -0.00001, 0.0001,
        10004.888]);
    globalThis.arrayBuffer = globalThis.uint8Array.buffer;
    globalThis.dataView = new DataView(globalThis.arrayBuffer);
    globalThis.implicitExplicit = [
      {'foo': 'bar'},
      [1, 2, 3, {'baz': 'boo'}],
    ];
    let keyObject = function () {};
    globalThis.keyObject1 = keyObject;
    globalThis.keyObject2 = keyObject;
    globalThis.symbol = Symbol('symbol');
  ''');
  JSObject gc = globalContext;
  Expect.isNull(gc['a']);
  Expect.isNull(gc['b']);
  Expect.equals('foo', gc['c'].dartify() as String);
  _expectRecEquals(['a', 'b', 'c'], gc['d'].dartify() as List<Object?>);
  Expect.equals(2.5, gc['e'].dartify() as double);
  Expect.equals(true, gc['f'].dartify() as bool);
  _expectRecEquals({
    'null': 'foo',
    'foo': null,
    'a': 1,
    'b': true,
    'c': [1, 2, 3, null],
    'd': 'foo',
    'e': {
      'f': 2,
      'g': [2, 4, 6]
    },
  }, gc['h'].dartify() as Map<Object?, Object?>);
  _expectRecEquals({
    'a': {},
  }, gc['rec'].dartify() as Map<Object?, Object?>);

  _expectIterableEquals(Int8List.fromList(<int>[-128, 0, 127]),
      gc['int8Array'].dartify() as Int8List);
  _expectIterableEquals(Uint8List.fromList([-1, 0, 255, 256]),
      gc['uint8Array'].dartify() as Uint8List);
  _expectIterableEquals(Uint8ClampedList.fromList([-1, 0, 255, 256]),
      gc['uint8ClampedArray'].dartify() as Uint8ClampedList);
  _expectIterableEquals(Int16List.fromList([-32769, -32768, 0, 32767, 32768]),
      gc['int16Array'].dartify() as Int16List);
  _expectIterableEquals(Uint16List.fromList([-1, 0, 65535, 65536]),
      gc['uint16Array'].dartify() as Uint16List);
  _expectIterableEquals(Int32List.fromList([-2147483648, 0, 2147483647]),
      gc['int32Array'].dartify() as Int32List);
  _expectIterableEquals(Uint32List.fromList([-1, 0, 4294967295, 4294967296]),
      gc['uint32Array'].dartify() as Uint32List);
  _expectIterableEquals(
      Float32List.fromList([-1000.488, -0.00001, 0.0001, 10004.888]),
      gc['float32Array'].dartify() as Float32List);
  _expectIterableEquals(
      Float64List.fromList([-1000.488, -0.00001, 0.0001, 10004.888]),
      gc['float64Array'].dartify() as Float64List);
  _expectIterableEquals(Uint8List.fromList([-1, 0, 255, 256]),
      (gc['arrayBuffer'].dartify() as ByteBuffer).asUint8List());
  _expectIterableEquals(Uint8List.fromList([-1, 0, 255, 256]),
      (gc['dataView'].dartify() as ByteData).buffer.asUint8List());

  // Confirm a function that takes a roundtrip remains a function.
  // TODO(srujzs): Delete this test after we remove this conversion.
  JSFunction foo = gc['g'].dartify() as JSFunction;
  Expect.equals(
      'hello world', gc.callMethod<JSString>('invoke'.toJS, foo).toDart);

  // Confirm arrays, which need to be converted implicitly, are still
  // recursively converted by dartify() when desired.
  _expectIterableEquals([
    {'foo': 'bar'},
    [
      1,
      2,
      3,
      {'baz': 'boo'}
    ],
  ], gc['implicitExplicit'].dartify() as List<Object?>);

  // Test that JS objects behave as expected in Map / Set.
  Set<Object?> set = {};
  JSAny? key1 = gc['keyObject1'];
  JSAny? key2 = gc['keyObject2'];
  Expect.isTrue(set.add(key1));
  Expect.isTrue(set.contains(key1));
  Expect.isFalse(set.add(key2));
  Expect.isTrue(set.contains(key2));
  Expect.equals(1, set.length);

  Map<Object?, Object?> map = {};
  map[key1] = 'foo';
  map[key2] = 'bar';
  Expect.equals(1, map.length);
  Expect.equals('bar', map[key1]);

  // Test that unrelated values are left alone/simply boxed.
  Expect.isTrue((gc['symbol'].dartify() as JSAny).isA<JSSymbol>());
  Expect.equals(gc['symbol'], gc['symbol'].dartify());
}
