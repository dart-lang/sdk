// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

// Tests behavior of external extension members, which are routed to js_util
// calls by a CFE transformation.

@JS()
library external_extension_members_test;

import 'dart:js_interop';

import 'package:expect/expect.dart';
import 'package:expect/minitest.dart';
import 'package:js/js_util.dart' as js_util;

@JS()
external void eval(String code);

@JS()
@staticInterop
class Foo<T extends JSAny, U extends Nested> {
  external factory Foo(int a);
}

extension FooExt<T extends JSAny, U extends Nested> on Foo<T, U> {
  external get getter;
  @JS('getterAnnotation')
  external get annotatedGetter;

  external set setter(_);
  @JS('setterAnnotation')
  external set annotatedSetter(_);

  external num getField();
  external void setField10([optionalArgument]);
  @JS('toString')
  external String extToString();
  external dynamic getFirstEl(list);
  external num sumFn(a, b);
  @JS('sumFn')
  external num otherSumFn(a, b);

  @JS('field')
  external T get fieldT;
  @JS('field')
  external set fieldT(T _);
  @JS('sumFn')
  external T sumFnT(T a, T b);
  @JS('sumFn')
  external R sumFnGeneric<R extends JSAny, P extends JSAny>(P a, [P b]);

  external Nested get nested;
  external set nested(Nested _);
  external Nested combineNested(Nested a, Nested b);

  @JS('nested')
  external U get nestedU;
  @JS('nested')
  external set nestedU(U _);
  @JS('combineNested')
  external U combineNestedU(U a, [U b]);
  @JS('combineNested')
  external R combineNestedGeneric<R extends Nested>(R a, [R b]);
}

@JS('module.Bar')
@staticInterop
class Bar {
  external factory Bar(int a);
}

extension BarExt on Bar {
  @JS('field')
  external get barFieldGetter;
  @JS('field')
  external set barFieldSetter(_);
}

@JS()
@staticInterop
class Nested<T extends JSAny> {
  external factory Nested(T value);
}

extension NestedExt<T extends JSAny> on Nested<T> {
  external T get value;
}

void main() {
  eval(r"""
    function Foo(a) {
      this.field = a;
      this.fieldAnnotation = a;
      this.finalField = a;

      this.getter = a;
      this.getterAnnotation = a;
    }

    Foo.prototype.toString = function() {
      return "Foo: " + this.field;
    }

    Foo.prototype.getField = function() {
      return this.field;
    }

    Foo.prototype.setField10 = function(optionalArgument) {
      this.field = optionalArgument;
    }

    Foo.prototype.getFirstEl = function(list) {
      return list[0];
    }

    Foo.prototype.sumFn = function(a, b) {
      return a + b;
    }

    Foo.prototype.combineNested = function(a, b) {
      return new Nested(a.value + b.value);
    }

    var module = {Bar: Foo};

    function Nested(value) {
      this.value = value;
    }
    """);

  test('getters', () {
    var foo = Foo(42);
    expect(foo.getter, equals(42));
    expect(foo.annotatedGetter, equals(42));

    js_util.setProperty(foo, 'getterAnnotation', 'eel');
    expect(foo.annotatedGetter, equals('eel'));
  });

  test('setters', () {
    var foo = Foo(42);
    foo.setter = 'starfish';
    expect(js_util.getProperty(foo, 'setter'), equals('starfish'));

    foo.annotatedSetter = 'whale';
    expect(js_util.getProperty(foo, 'setterAnnotation'), equals('whale'));
  });

  test('methods', () {
    var foo = Foo(42);

    expect(foo.getField(), equals(42));
    expect(foo.extToString(), equals('Foo: 42'));
    expect(foo.getFirstEl([1, 2, 3]), equals(1));
    expect(foo.sumFn(2, 3), equals(5));
    expect(foo.otherSumFn(10, 5), equals(15));
  });

  test('module class', () {
    var bar = Bar(5);
    expect(js_util.getProperty(bar, 'fieldAnnotation'), equals(5));
    expect(bar.barFieldGetter, equals(5));
    expect(js_util.getProperty(bar, 'field'), equals(5));

    bar.barFieldSetter = 10;
    expect(js_util.getProperty(bar, 'fieldAnnotation'), equals(5));
    expect(js_util.getProperty(bar, 'field'), equals(10));
  });

  test('type parameters', () {
    final foo = Foo<JSString, Nested>(0);
    final value = 'value';
    final jsValue = value.toJS;
    foo.fieldT = jsValue;
    expect(foo.fieldT.toDart, value);
    expect(foo.sumFnT(jsValue, jsValue).toDart, '$value$value');
    expect(foo.sumFnGeneric<JSNumber, JSNumber>(0.toJS, 0.toJS).toDartInt, 0);

    foo.nested = Nested(jsValue);
    expect((foo.nested as Nested<JSString>).value.toDart, value);
    expect(
        (foo.combineNested(Nested(value.toJS), Nested(jsValue))
                as Nested<JSString>)
            .value
            .toDart,
        '$value$value');

    foo.nestedU = Nested(jsValue);
    expect((foo.nestedU as Nested<JSString>).value.toDart, value);
    expect(
        (foo.combineNestedU(Nested(jsValue), Nested(jsValue))
                as Nested<JSString>)
            .value
            .toDart,
        '$value$value');
    expect(
        foo.combineNestedGeneric(Nested(jsValue), Nested(jsValue)).value.toDart,
        '$value$value');

    // Try invalid generics.
    (foo as Foo<JSNumber, Nested>).fieldT = 0.toJS;
    // dart2wasm uses a JSStringImpl here for conversion without validating the
    // extern ref, so we would only see that it's not a String when we call
    // methods on it.
    Expect.throws(() => foo.fieldT.toDart.toLowerCase());
    Expect.throws(() => foo
        .sumFnGeneric<JSNumber, JSString>(value.toJS, value.toJS)
        .toDartInt
        .isEven);
    Expect.throws(() => foo
        .sumFnGeneric<JSString, JSNumber>(0.toJS, 0.toJS)
        .toDart
        .toLowerCase());
  });
}
