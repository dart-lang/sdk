// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import 'package:expect/expect.dart';

@JS()
external void eval(String code);

void createObjectTest() {
  JSObject o = JSObject();
  void testHasGetSet(String property, String? value) {
    // []/[]=
    Expect.isFalse(o.hasProperty(property.toJS).toDart);
    o[property] = value?.toJS;
    Expect.isTrue(o.hasProperty(property.toJS).toDart);
    Expect.equals(value, (o[property] as JSString?)?.toDart);
    Expect.isTrue(o.delete(property.toJS).toDart);

    // Weirdly enough, delete almost always returns true.
    Expect.isTrue(o.delete(property.toJS).toDart);

    // getProperty/setProperty
    Expect.isFalse(o.hasProperty(property.toJS).toDart);
    o.setProperty(property.toJS, value?.toJS);
    Expect.isTrue(o.hasProperty(property.toJS).toDart);
    Expect.equals(value, (o.getProperty(property.toJS) as JSString?)?.toDart);
    Expect.isTrue(o.delete(property.toJS).toDart);
  }

  testHasGetSet('foo', 'bar');
  testHasGetSet('baz', null);
}

void equalTest() {
  // Different objects aren't equal.
  {
    JSObject o1 = JSObject();
    JSObject o2 = JSObject();
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
    JSObject gc = globalContext;
    void test(String propertyName, bool testCanonicalization) {
      Expect.equals(gc[propertyName], gc[propertyName]);
      if (testCanonicalization) {
        Expect.equals(gc[propertyName], gc[propertyName + "2"]);
      }
    }

    test("boolData", true);
    test("numData", true);
    test("arrData", false);
    test("strData", true);
    test("funcData", false);
    test("JSClass", false);
  }
}

// TODO(srujzs): This helper is no longer in dart:js_interop_unsafe. Move this
// test.
void typeofTest() {
  eval(r'''
    globalThis.b = true;
    globalThis.n = 4;
    globalThis.str = 'foo';
    globalThis.f = function foo() {}
    globalThis.o = {};
    globalThis.nil = null;
    globalThis.u = undefined;
    globalThis.sym = Symbol('sym');
  ''');

  final types = {
    'boolean',
    'number',
    'string',
    'function',
    'object',
    'undefined',
    'symbol'
  };
  void test(String property, String expectedType) {
    Expect.isTrue(globalContext[property].typeofEquals(expectedType));
    for (final type in types) {
      if (type != expectedType) {
        Expect.isFalse(globalContext[property].typeofEquals(type));
      }
    }
  }

  test('b', 'boolean');
  test('n', 'number');
  test('str', 'string');
  test('f', 'function');
  test('o', 'object');
  test('nil', 'object');
  // TODO(joshualitt): Test for `undefined` when we it can flow into `JSAny?`.
  // test('u', 'undefined');
  test('sym', 'symbol');
}

// TODO(srujzs): This helper is no longer in dart:js_interop_unsafe. Move this
// test.
void instanceOfTest() {
  eval(r'''
      globalThis.JSClass1 = function() {}
      globalThis.JSClass2 = function() {}

      globalThis.obj = new JSClass1();
    ''');
  JSObject gc = globalContext;
  JSObject obj = gc['obj'] as JSObject;
  JSFunction jsClass1Constructor = gc['JSClass1'] as JSFunction;
  JSFunction jsClass2Constructor = gc['JSClass2'] as JSFunction;
  Expect.isTrue(obj.instanceof(jsClass1Constructor));
  Expect.isFalse(obj.instanceof(jsClass2Constructor));
  Expect.isTrue(obj.instanceOfString('JSClass1'));
  Expect.isFalse(obj.instanceOfString('JSClass2'));
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

void methodsAndConstructorsTest() {
  eval(r'''
    function JSClass(c) {
      this.c = c;
      this.sum = (a, b) => {
        console.log(a + ' ' + b);
        return `${a}${b}${this.c}`;
      }
    }
    globalThis.JSClass = JSClass;
  ''');
  JSObject gc = globalContext;
  JSFunction constructor = gc['JSClass'] as JSFunction;

  // Var args one arg
  JSObject jsObj1 =
      constructor.callAsConstructorVarArgs<JSObject>(<JSAny?>['world!'.toJS]);
  Expect.equals(
      'hello world!',
      jsObj1.callMethodVarArgs<JSString>(
          'sum'.toJS, <JSAny?>['hello'.toJS, ' '.toJS]).toDart);
  Expect.equals(
      'helloundefinedworld!',
      jsObj1.callMethodVarArgs<JSString>(
          'sum'.toJS, <JSAny?>['hello'.toJS]).toDart);
  Expect.equals('undefinedundefinedworld!',
      jsObj1.callMethodVarArgs<JSString>('sum'.toJS, <JSAny?>[]).toDart);
  Expect.equals('undefinedundefinedworld!',
      jsObj1.callMethodVarArgs<JSString>('sum'.toJS).toDart);
  Expect.equals(
      'nullnullworld!',
      jsObj1.callMethodVarArgs<JSString>(
          'sum'.toJS, <JSAny?>[null, null]).toDart);
  // Var args no args
  jsObj1 = constructor.callAsConstructorVarArgs<JSObject>();
  Expect.equals(jsObj1['c'], null);

  // Fixed args one arg
  jsObj1 = constructor.callAsConstructor<JSObject>('world!'.toJS);
  Expect.equals('hello world!',
      jsObj1.callMethod<JSString>('sum'.toJS, 'hello'.toJS, ' '.toJS).toDart);
  Expect.equals('helloundefinedworld!',
      jsObj1.callMethod<JSString>('sum'.toJS, 'hello'.toJS).toDart);
  Expect.equals('undefinedundefinedworld!',
      jsObj1.callMethod<JSString>('sum'.toJS, null).toDart);
  Expect.equals('undefinedundefinedworld!',
      jsObj1.callMethod<JSString>('sum'.toJS).toDart);
  // Fixed args no args
  jsObj1 = constructor.callAsConstructor<JSObject>();
  Expect.equals(jsObj1['c'], null);
}

void deepConversionsTest() {
  // Dart to JS.
  Expect.isNull(null.jsify().dartify());
  Expect.equals(true, true.jsify().dartify());
  Expect.equals(2.0, 2.0.jsify().dartify());
  Expect.equals('foo', 'foo'.jsify().dartify());
  _expectRecEquals(
      ['a', 'b', 'c'], ['a', 'b', 'c'].jsify().dartify() as List<Object?>);
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
  List<Object?> l = Int8List.fromList(<int>[-128, 0, 127]);
  _expectIterableEquals(l, l.jsify().dartify() as Int8List);
  l = Uint8List.fromList([-1, 0, 255, 256]);
  _expectIterableEquals(l, l.jsify().dartify() as Uint8List);
  l = Uint8ClampedList.fromList([-1, 0, 255, 256]);
  _expectIterableEquals(l, l.jsify().dartify() as Uint8ClampedList);
  l = Int16List.fromList([-32769, -32768, 0, 32767, 32768]);
  _expectIterableEquals(l, l.jsify().dartify() as Int16List);
  l = Uint16List.fromList([-1, 0, 65535, 65536]);
  _expectIterableEquals(l, l.jsify().dartify() as Uint16List);
  l = Int32List.fromList([-2147483648, 0, 2147483647]);
  _expectIterableEquals(l, l.jsify().dartify() as Int32List);
  l = Uint32List.fromList([-1, 0, 4294967295, 4294967296]);
  _expectIterableEquals(l, l.jsify().dartify() as Uint32List);
  l = Float32List.fromList([-1000.488, -0.00001, 0.0001, 10004.888]);
  _expectIterableEquals(l, l.jsify().dartify() as Float32List);
  l = Float64List.fromList([-1000.488, -0.00001, 0.0001, 10004.888]);
  _expectIterableEquals(l, l.jsify().dartify() as Float64List);
  ByteBuffer buffer = Uint8List.fromList([0, 1, 2, 3]).buffer;
  _expectIterableEquals(buffer.asUint8List(),
      (buffer.jsify().dartify() as ByteBuffer).asUint8List());
  ByteData byteData = ByteData.view(buffer);
  _expectIterableEquals(byteData.buffer.asUint8List(),
      (byteData.jsify().dartify() as ByteData).buffer.asUint8List());

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
  ''');
  JSObject gc = globalContext;
  Expect.isNull(gc['a']);
  Expect.equals('foo', gc.getProperty<JSString>('b'.toJS).toDart);
  _expectRecEquals(
      ['a', 'b', 'c'],
      gc
          .getProperty<JSArray>('c'.toJS)
          .toDart
          .map((JSAny? o) => (o as JSString).toDart));
  Expect.equals(2.5, gc.getProperty<JSNumber>('d'.toJS).toDartDouble);
  Expect.equals(true, gc.getProperty<JSBoolean>('e'.toJS).toDart);
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
  }, gc.getProperty('g'.toJS).dartify());
  _expectRecEquals({
    'a': {},
  }, gc.getProperty('rec'.toJS).dartify());

  _expectIterableEquals(Int8List.fromList(<int>[-128, 0, 127]),
      gc.getProperty<JSInt8Array>('int8Array'.toJS).toDart);
  _expectIterableEquals(Uint8List.fromList([-1, 0, 255, 256]),
      gc.getProperty<JSUint8Array>('uint8Array'.toJS).toDart);
  _expectIterableEquals(Uint8ClampedList.fromList([-1, 0, 255, 256]),
      gc.getProperty<JSUint8ClampedArray>('uint8ClampedArray'.toJS).toDart);
  _expectIterableEquals(Int16List.fromList([-32769, -32768, 0, 32767, 32768]),
      gc.getProperty<JSInt16Array>('int16Array'.toJS).toDart);
  _expectIterableEquals(Uint16List.fromList([-1, 0, 65535, 65536]),
      gc.getProperty<JSUint16Array>('uint16Array'.toJS).toDart);
  _expectIterableEquals(Int32List.fromList([-2147483648, 0, 2147483647]),
      gc.getProperty<JSInt32Array>('int32Array'.toJS).toDart);
  _expectIterableEquals(Uint32List.fromList([-1, 0, 4294967295, 4294967296]),
      gc.getProperty<JSUint32Array>('uint32Array'.toJS).toDart);
  _expectIterableEquals(
      Float32List.fromList([-1000.488, -0.00001, 0.0001, 10004.888]),
      gc.getProperty<JSFloat32Array>('float32Array'.toJS).toDart);
  _expectIterableEquals(
      Float64List.fromList([-1000.488, -0.00001, 0.0001, 10004.888]),
      gc.getProperty<JSFloat64Array>('float64Array'.toJS).toDart);
  _expectIterableEquals(Uint8List.fromList([-1, 0, 255, 256]),
      gc.getProperty<JSArrayBuffer>('arrayBuffer'.toJS).toDart.asUint8List());
  _expectIterableEquals(Uint8List.fromList([-1, 0, 255, 256]),
      gc.getProperty<JSDataView>('dataView'.toJS).toDart.buffer.asUint8List());

  // Confirm a function that takes a roundtrip remains a function.
  JSFunction foo = gc['f'].dartify() as JSFunction;
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
  ], gc['implicitExplicit'].dartify() as Iterable);

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
}

@JS('Symbol')
@staticInterop
class _JSSymbol {
  @JS('for')
  external static JSAny _for(JSString s);
  external static JSString keyFor(JSAny s);
}

@JS()
external JSAny get symbol;

@JS()
external JSAny get symbol2;

@JS()
external JSString methodWithSymbol(JSAny s);

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
  JSObject gc = globalContext;
  Expect.equals(
      _JSSymbol.keyFor(_JSSymbol._for('symbol'.toJS)).toDart, 'symbol');
  Expect.equals(
      gc.getProperty<JSString>(gc.getProperty<JSAny>('symbol'.toJS)).toDart,
      'boo');
  Expect.equals(methodWithSymbol(symbol).toDart, 'symbol');
  Expect.equals(_JSSymbol.keyFor(symbol).toDart, 'symbol');
  Expect.equals(
      _JSSymbol.keyFor(gc.getProperty<JSAny>('symbol'.toJS)).toDart, 'symbol');
  Expect.equals(gc.callMethod<JSString>(symbol2).toDart, 'hello world');
}

void main() {
  createObjectTest();
  equalTest();
  typeofTest();
  instanceOfTest();
  methodsAndConstructorsTest();
  deepConversionsTest();
  symbolTest();
}
