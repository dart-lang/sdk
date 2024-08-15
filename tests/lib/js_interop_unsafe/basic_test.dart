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
    // has/[]/[]=
    Expect.isFalse(o.has(property));
    o[property] = value?.toJS;
    Expect.isTrue(o.has(property));
    Expect.equals(value, (o[property] as JSString?)?.toDart);
    Expect.isTrue(o.delete(property.toJS).toDart);

    // Weirdly enough, delete almost always returns true.
    Expect.isTrue(o.delete(property.toJS).toDart);

    // hasProperty/getProperty/setProperty
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
  Expect.isFalse(0.toJS.instanceof(jsClass2Constructor));
  Expect.isTrue(obj.instanceOfString('JSClass1'));
  Expect.isFalse(obj.instanceOfString('JSClass2'));
  Expect.isFalse(0.toJS.instanceOfString('JSClass1'));
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
  symbolTest();
}
