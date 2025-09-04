// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests behavior of external extension members, which are routed to js_util
// calls by a CFE transformation.

import 'dart:js_interop';

import 'package:expect/expect.dart';
// To test non-JS types for @staticInterop.
import 'package:js/js.dart' as pkgJs;
import 'package:js/js_util.dart' as js_util;

@JS()
external void eval(String code);

@pkgJs.JS()
@pkgJs.staticInterop
class Foo<T extends JSAny?, U extends Nested> {
  external factory Foo(int a);
}

extension FooExt<T extends JSAny?, U extends Nested> on Foo<T, U> {
  external var field;
  external final finalField;
  @JS('fieldAnnotation')
  external var annotatedField;
  @JS('nested-field.foo.field')
  external var nestedField;

  external get getter;
  @JS('getterAnnotation')
  external get annotatedGetter;

  external set setter(_);
  @JS('setterAnnotation')
  external set annotatedSetter(_);

  @JS('nestedGetSet.1.getSet')
  external get nestedGetSet;
  @JS('nestedGetSet.1.getSet')
  external set nestedGetSet(_);

  external num getField();
  external void setField10([optionalArgument]);
  @JS('toString')
  external String extToString();
  external dynamic getFirstEl(list);
  external num sumFn(a, b);
  @JS('sumFn')
  external num otherSumFn(a, b);
  @JS('nested^method.method')
  external String nestedMethod();

  @JS('field')
  external T fieldT;
  @JS('sumFn')
  external T sumFnT(T a, T b);
  @JS('sumFn')
  external R sumFnGeneric<R extends JSAny?, P extends JSAny?>(P a, [P b]);

  external Nested nested;
  external Nested combineNested(Nested a, Nested b);

  @JS('nested')
  external U nestedU;
  @JS('combineNested')
  external U combineNestedU(U a, [U b]);
  @JS('combineNested')
  external R combineNestedGeneric<R extends Nested>(R a, [R b]);
}

@pkgJs.JS('module.Bar')
@pkgJs.staticInterop
class Bar {
  external factory Bar(int a);
}

extension BarExt on Bar {
  @JS('field')
  external var barField;
}

@JS()
@staticInterop
class Nested<T extends JSAny?> {
  external factory Nested(T value);
}

extension NestedExt<T extends JSAny?> on Nested<T> {
  external T get value;
}

void main() {
  eval(r"""
    function Foo(a) {
      this.field = a;
      this.fieldAnnotation = a;
      this.finalField = a;
      this['nested-field'] = {
        foo: {
          field: a
        }
      };

      this.getter = a;
      this.getterAnnotation = a;
      this.nestedGetSet = {
        '1': {
          getSet: a
        }
      };
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

    Foo.prototype['nested^method'] = {
      method: function() {
        return 'nestedMethod';
      }
    }

    Foo.prototype.combineNested = function(a, b) {
      return new Nested(a.value + b.value);
    }

    var module = {Bar: Foo};

    function Nested(value) {
      this.value = value;
    }
    """);

  {
    // fields.

    var foo = Foo(42);
    // field getters
    Expect.equals(42, foo.field);
    Expect.equals(42, foo.finalField);
    Expect.equals(42, foo.annotatedField);
    Expect.equals(42, foo.nestedField);

    // field setters
    foo.field = 'squid';
    Expect.equals('squid', foo.field);
    foo.annotatedField = 'octopus';
    Expect.equals('octopus', foo.annotatedField);
    js_util.setProperty(foo, 'fieldAnnotation', 'clownfish');
    Expect.equals('clownfish', foo.annotatedField);
    foo.nestedField = 'shark';
    Expect.equals('shark', foo.nestedField);
  }

  {
    // getters.

    var foo = Foo(42);
    Expect.equals(42, foo.getter);
    Expect.equals(42, foo.annotatedGetter);
    Expect.equals(42, foo.nestedGetSet);

    js_util.setProperty(foo, 'getterAnnotation', 'eel');
    Expect.equals('eel', foo.annotatedGetter);
  }

  {
    // setters.

    var foo = Foo(42);
    foo.setter = 'starfish';
    Expect.equals('starfish', js_util.getProperty(foo, 'setter'));

    foo.annotatedSetter = 'whale';
    Expect.equals('whale', js_util.getProperty(foo, 'setterAnnotation'));

    foo.nestedGetSet = 'dolphin';
    Expect.equals('dolphin', foo.nestedGetSet);
  }

  {
    // methods.

    var foo = Foo(42);

    Expect.equals(42, foo.getField());
    Expect.equals('Foo: 42', foo.extToString());
    Expect.equals(1, foo.getFirstEl([1, 2, 3]));
    Expect.equals(5, foo.sumFn(2, 3));
    Expect.equals(15, foo.otherSumFn(10, 5));
    Expect.equals('nestedMethod', foo.nestedMethod());
  }

  {
    // module class.

    var bar = Bar(5);
    Expect.equals(5, js_util.getProperty(bar, 'fieldAnnotation'));
    Expect.equals(5, bar.barField);
    Expect.equals(5, js_util.getProperty(bar, 'field'));

    bar.barField = 10;
    Expect.equals(5, js_util.getProperty(bar, 'fieldAnnotation'));
    Expect.equals(10, js_util.getProperty(bar, 'field'));
  }

  {
    // type parameters.

    final foo = Foo<JSString, Nested>(0);
    final value = 'value';
    final jsValue = value.toJS;
    foo.fieldT = jsValue;
    Expect.equals(value, foo.fieldT.toDart);
    Expect.equals('$value$value', foo.sumFnT(jsValue, jsValue).toDart);
    Expect.equals(
      0,
      foo.sumFnGeneric<JSNumber, JSNumber>(0.toJS, 0.toJS).toDartInt,
    );

    foo.nested = Nested(jsValue);
    Expect.equals(value, (foo.nested as Nested<JSString>).value.toDart);
    Expect.equals(
      '$value$value',
      (foo.combineNested(Nested(value.toJS), Nested(jsValue))
              as Nested<JSString>)
          .value
          .toDart,
    );

    foo.nestedU = Nested(jsValue);
    Expect.equals(value, (foo.nestedU as Nested<JSString>).value.toDart);
    Expect.equals(
      '$value$value',
      (foo.combineNestedU(Nested(jsValue), Nested(jsValue)) as Nested<JSString>)
          .value
          .toDart,
    );
    Expect.equals(
      '$value$value',
      foo.combineNestedGeneric(Nested(jsValue), Nested(jsValue)).value.toDart,
    );

    // Try invalid generics.
    (foo as Foo<JSNumber, Nested>).fieldT = 0.toJS;
    // dart2wasm uses a JSStringImpl here for conversion without validating the
    // extern ref, so we would only see that it's not a String when we call
    // methods on it.
    Expect.throws(() => foo.fieldT.toDart.split('foo'));
    Expect.throws(
      () => foo
          .sumFnGeneric<JSNumber, JSString>(value.toJS, value.toJS)
          .toDartInt
          .isEven,
    );
    Expect.throws(
      () => foo
          .sumFnGeneric<JSString, JSNumber>(0.toJS, 0.toJS)
          .toDart
          .split('foo'),
    );
  }
}
