// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests behavior of external extension members, which are routed to js_util
// calls by a CFE transformation.

@JS()
library external_extension_members_test;

import 'package:js/js.dart';
import 'package:js/js_util.dart' as js_util;
import 'package:expect/minitest.dart';

@JS()
external void eval(String code);

@JS()
class Foo {
  external Foo(int a);
}

extension FooExt on Foo {
  external var field;
  external final finalField;
  @JS('fieldAnnotation')
  external var annotatedField;

  external get getter;
  @JS('getterAnnotation')
  external get annotatedGetter;

  external set setter(_);
  @JS('setterAnnotation')
  external set annotatedSetter(_);

  external num getField();
  external void setField10([optionalArgument = 10]);
  @JS('toString')
  external String extToString();
  external dynamic getFirstEl(list);
  external num sumFn(a, b);
  @JS('sumFn')
  external num otherSumFn(a, b);
}

@JS('module.Bar')
class Bar {
  external Bar(int a);
}

extension BarExt on Bar {
  @JS('field')
  external var barField;
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

    var module = {Bar: Foo};
    """);

  test('fields', () {
    var foo = Foo(42);
    // field getters
    expect(foo.field, equals(42));
    expect(foo.finalField, equals(42));
    expect(foo.annotatedField, equals(42));

    // field setters
    foo.field = 'squid';
    expect(foo.field, equals('squid'));

    foo.annotatedField = 'octopus';
    expect(foo.annotatedField, equals('octopus'));
    js_util.setProperty(foo, 'fieldAnnotation', 'clownfish');
    expect(foo.annotatedField, equals('clownfish'));
  });

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
    expect(bar.barField, equals(5));
    expect(js_util.getProperty(bar, 'field'), equals(5));

    bar.barField = 10;
    expect(js_util.getProperty(bar, 'fieldAnnotation'), equals(5));
    expect(js_util.getProperty(bar, 'field'), equals(10));
  });
}
