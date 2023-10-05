// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:js_util';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';

@JS()
external void eval(String code);

void createObjectTest() {
  Object o = newObject();
  Expect.isFalse(hasProperty(o, 'foo'));
  Expect.equals('bar', setProperty(o, 'foo', 'bar'));
  Expect.isTrue(hasProperty(o, 'foo'));
  Expect.equals('bar', getProperty(o, 'foo'));
}

void equalTest() {
  // Different objects aren't equal.
  {
    Object o1 = newObject();
    Object o2 = newObject();
    Expect.notEquals(o1, o2);
  }

  {
    eval(r'''
      function JSClass() {}

      globalThis.boolData = true;
      globalThis.boolData2 = true;
      globalThis.numData = 4;
      globalThis.numData2 = 4;
      globalThis.arrData = [1, 2, 3];
      globalThis.strData = 'foo';
      globalThis.strData2 = 'foo';
      globalThis.funcData = function JSClass() {}
      globalThis.JSClass = new globalThis.funcData();
    ''');
    Object gt = globalThis;
    void test(String propertyName, bool testCanonicalization) {
      Expect.equals(
          getProperty(gt, propertyName), getProperty(gt, propertyName));
      if (testCanonicalization) {
        Expect.equals(
            getProperty(gt, propertyName), getProperty(gt, propertyName + "2"));
      }
    }

    test("boolData", true);
    test("numData", true);
    // TODO(joshualitt): Start returning arrays by reference.
    //test("arrData", false);
    test("strData", true);
    test("funcData", false);
    test("JSClass", false);
  }
}

void instanceofTest() {
  eval(r'''
      globalThis.JSClass1 = function() {}
      globalThis.JSClass2 = function() {}

      globalThis.obj = new JSClass1();
    ''');
  Expect.isTrue(instanceof(
      getProperty(globalThis, 'obj'), getProperty(globalThis, 'JSClass1')));
  Expect.isFalse(instanceof(
      getProperty(globalThis, 'obj'), getProperty(globalThis, 'JSClass2')));
}

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

void evalAndConstructTest() {
  eval(r'''
    function JSClass(c) {
      this.c = c;
      this.sum = (a, b) => {
        return a + b + this.c;
      }
      this.list = ['a', 'b', 'c'];
    }
    globalThis.JSClass = JSClass;
  ''');
  Object gt = globalThis;
  Object constructor = getProperty(gt, 'JSClass');
  Object jsClass = callConstructor(constructor, ['world!']);
  Expect.equals('hello world!', callMethod(jsClass, 'sum', ['hello', ' ']));
  _expectRecEquals(
      ['a', 'b', 'c'], getProperty(jsClass, 'list') as List<Object?>);
}

class Foo {
  final int i;
  Foo(this.i);
}

void dartObjectRoundTripTest() {
  Object o = newObject();
  setProperty(o, 'foo', Foo(4));
  Object foo = getProperty(o, 'foo')!;
  Expect.equals(4, (foo as Foo).i);
}

void deepConversionsTest() {
  // Dart to JS.
  Expect.isNull(dartify(jsify(null)));
  Expect.equals(true, dartify(jsify(true)));
  Expect.equals(2.0, dartify(jsify(2.0)));
  Expect.equals('foo', dartify(jsify('foo')));
  _expectRecEquals(
      ['a', 'b', 'c'], dartify(jsify(['a', 'b', 'c'])) as List<Object?>);
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
      dartify(jsify({
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
      })));
  // TODO(joshualitt): Debug the cast failure.
  //List<Object?> l = Int8List.fromList(<int>[-128, 0, 127]);
  //_expectIterableEquals(l, dartify(jsify(l)) as Int8List);
  List<Object?> l = Uint8List.fromList([-1, 0, 255, 256]);
  _expectIterableEquals(l, dartify(jsify(l)) as Uint8List);
  l = Uint8ClampedList.fromList([-1, 0, 255, 256]);
  _expectIterableEquals(l, dartify(jsify(l)) as Uint8ClampedList);
  l = Int16List.fromList([-32769, -32768, 0, 32767, 32768]);
  _expectIterableEquals(l, dartify(jsify(l)) as Int16List);
  l = Uint16List.fromList([-1, 0, 65535, 65536]);
  _expectIterableEquals(l, dartify(jsify(l)) as Uint16List);
  l = Int32List.fromList([-2147483648, 0, 2147483647]);
  _expectIterableEquals(l, dartify(jsify(l)) as Int32List);
  l = Uint32List.fromList([-1, 0, 4294967295, 4294967296]);
  _expectIterableEquals(l, dartify(jsify(l)) as Uint32List);
  l = Float32List.fromList([-1000.488, -0.00001, 0.0001, 10004.888]);
  _expectIterableEquals(l, dartify(jsify(l)) as Float32List);
  l = Float64List.fromList([-1000.488, -0.00001, 0.0001, 10004.888]);
  _expectIterableEquals(l, dartify(jsify(l)) as Float64List);
  ByteBuffer buffer = Uint8List.fromList([0, 1, 2, 3]).buffer;
  _expectIterableEquals(buffer.asUint8List(),
      (dartify(jsify(buffer)) as ByteBuffer).asUint8List());
  ByteData byteData = ByteData.view(buffer);
  _expectIterableEquals(byteData.buffer.asUint8List(),
      (dartify(jsify(byteData)) as ByteData).buffer.asUint8List());

  // JS to Dart.
  eval(r'''
    globalThis.a = null;
    globalThis.b = 'foo';
    globalThis.c = ['a', 'b', 'c'];
    globalThis.d = 2.5;
    globalThis.e = true;
    globalThis.f = function () { return 'hello world'; };
    globalThis.g = {
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
    // TODO(joshualitt): Fix int8 failure.
    // globalThis.int8Array = new Int8Array([-128, 0, 127]);
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
  ''');
  Object gt = globalThis;
  Expect.isNull(getProperty(gt, 'a'));
  Expect.equals('foo', getProperty(gt, 'b'));
  _expectRecEquals(['a', 'b', 'c'], getProperty<List<Object?>>(gt, 'c'));
  Expect.equals(2.5, getProperty(gt, 'd'));
  Expect.equals(true, getProperty(gt, 'e'));
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
  }, dartify(getProperty(gt, 'g')));
  _expectRecEquals({
    'a': {},
  }, dartify(getProperty(gt, 'rec')));

  _expectIterableEquals(Uint8List.fromList([-1, 0, 255, 256]),
      getProperty(gt, 'uint8Array') as Uint8List);
  _expectIterableEquals(Uint8ClampedList.fromList([-1, 0, 255, 256]),
      getProperty(gt, 'uint8ClampedArray') as Uint8ClampedList);
  _expectIterableEquals(Int16List.fromList([-32769, -32768, 0, 32767, 32768]),
      getProperty(gt, 'int16Array') as Int16List);
  _expectIterableEquals(Uint16List.fromList([-1, 0, 65535, 65536]),
      getProperty<List<Object?>>(gt, 'uint16Array') as Uint16List);
  _expectIterableEquals(Int32List.fromList([-2147483648, 0, 2147483647]),
      getProperty(gt, 'int32Array') as Int32List);
  _expectIterableEquals(Uint32List.fromList([-1, 0, 4294967295, 4294967296]),
      getProperty(gt, 'uint32Array') as Uint32List);
  _expectIterableEquals(
      Float32List.fromList([-1000.488, -0.00001, 0.0001, 10004.888]),
      getProperty(gt, 'float32Array') as Float32List);
  _expectIterableEquals(
      Float64List.fromList([-1000.488, -0.00001, 0.0001, 10004.888]),
      getProperty(gt, 'float64Array') as Float64List);
  _expectIterableEquals(Uint8List.fromList([-1, 0, 255, 256]),
      (getProperty(gt, 'arrayBuffer') as ByteBuffer).asUint8List());
  _expectIterableEquals(Uint8List.fromList([-1, 0, 255, 256]),
      (getProperty(gt, 'dataView') as ByteData).buffer.asUint8List());

  // Confirm a function that takes a roundtrip remains a function.
  Expect.equals('hello world',
      callMethod(gt, 'invoke', <Object?>[dartify(getProperty(gt, 'f'))]));

  // Confirm arrays, which need to be converted implicitly, are still
  // recursively converted by dartify when desired.
  _expectIterableEquals([
    {'foo': 'bar'},
    [
      1,
      2,
      3,
      {'baz': 'boo'}
    ],
  ], dartify(getProperty(globalThis, 'implicitExplicit')) as Iterable);

  // Test that JS objects behave as expected in Map / Set.
  Set<Object?> set = {};
  Expect.isTrue(set.add(getProperty(globalThis, 'keyObject1')));
  Expect.isFalse(set.add(getProperty(globalThis, 'keyObject2')));
  Expect.equals(1, set.length);

  Map<Object?, Object?> map = {};
  map[getProperty(globalThis, 'keyObject1')] = 'foo';
  map[getProperty(globalThis, 'keyObject2')] = 'bar';
  Expect.equals(1, map.length);
  Expect.equals('bar', map[getProperty(globalThis, 'keyObject1')]);
}

Future<void> promiseToFutureTest() async {
  Object gt = globalThis;
  eval(r'''
    globalThis.rejectedPromise = new Promise((resolve, reject) => reject('rejected'));
    globalThis.resolvedPromise = new Promise(resolve => resolve('resolved'));
    globalThis.getResolvedPromise = function() {
      return resolvedPromise;
    }
    //globalThis.nullRejectedPromise = Promise.reject(null);
  ''');

  // Test resolved
  {
    Future f = promiseToFuture(getProperty(gt, 'resolvedPromise'));
    Expect.equals('resolved', await f);
  }

  // Test rejected
  {
    String result = await asyncExpectThrows<String>(
        promiseToFuture(getProperty(gt, 'rejectedPromise')));
    Expect.equals('rejected', result);
  }

  // Test return resolved
  {
    Future f = promiseToFuture(callMethod(gt, 'getResolvedPromise', []));
    Expect.equals('resolved', await f);
  }

  // Test promise chaining
  {
    bool didThen = false;
    Future f = promiseToFuture(callMethod(gt, 'getResolvedPromise', []));
    f.then((resolved) {
      Expect.equals(resolved, 'resolved');
      didThen = true;
    });
    await f;
    Expect.isTrue(didThen);
  }

  // Test rejecting promise with null should trigger an exception.
  // TODO(joshualitt): Fails with an illegal cast.
  // {
  //   Future f = promiseToFuture(getProperty(gt, 'nullRejectedPromise'));
  //   f.then((_) { Expect.fail("Expect promise to reject"); }).catchError((e) {
  //     print('A');
  //     Expect.isTrue(e is NullRejectionException);
  //   });
  //   await f;
  // }
}

@JS('Symbol')
@staticInterop
class _JSSymbol {
  @JS('for')
  external static _JSSymbol _for(JSString s);
  external static JSString keyFor(_JSSymbol s);
}

@JS()
external _JSSymbol get symbol;

@JS()
external _JSSymbol get symbol2;

@JS()
external JSString methodWithSymbol(_JSSymbol s);

void symbolTest() {
  eval(r'''
      var s1 = Symbol.for('symbol');
      globalThis.symbol = s1;
      globalThis[s1] = 'boo';
      globalThis.methodWithSymbol = function(s) {
        return Symbol.keyFor(s);
      }
      var symbol2 = Symbol.for('symbolMethod');
      globalThis[symbol2] = function() {
        return 'hello world';
      }
      globalThis.symbol2 = symbol2;
      ''');
  Expect.equals(
      _JSSymbol.keyFor(_JSSymbol._for('symbol'.toJS)).toDart, 'symbol');
  Expect.equals(
      getProperty<String>(
          globalThis, getProperty<_JSSymbol>(globalThis, 'symbol')),
      'boo');
  Expect.equals(methodWithSymbol(symbol).toDart, 'symbol');
  Expect.equals(_JSSymbol.keyFor(symbol).toDart, 'symbol');
  Expect.equals(
      _JSSymbol.keyFor(getProperty<_JSSymbol>(globalThis, 'symbol')).toDart,
      'symbol');
  Expect.equals(callMethod<String>(globalThis, symbol2, []), 'hello world');
}

void main() async {
  createObjectTest();
  equalTest();
  instanceofTest();
  evalAndConstructTest();
  dartObjectRoundTripTest();
  deepConversionsTest();
  await promiseToFutureTest();
  symbolTest();
}
