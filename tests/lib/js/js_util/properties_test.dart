// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests the functionality of object properties with the js_util library. For
// js_util tests with HTML objects see tests/lib/html/js_util_test.dart.

@JS()
library js_util_properties_test;

import 'package:js/js.dart';
import 'package:js/js_util.dart' as js_util;
import 'package:expect/minitest.dart';

@JS()
external String jsFunction();

@JS()
external void eval(String code);

@JS('JSON.stringify')
external String stringify(o);

@JS('ArrayBuffer')
external get JSArrayBufferType;

@JS()
class Foo {
  external Foo(num a);

  external num get a;
  external num bar();
  external Object get objectProperty;
}

@JS('Foo')
external get JSFooType;

String dartFunction() {
  return 'Dart Function';
}

@JS()
@anonymous
class ExampleTypedLiteral {
  external factory ExampleTypedLiteral({a, b});

  external get a;
  external get b;
}

String _getBarWithSideEffect() {
  var x = 5;
  expect(x, equals(5));
  return 'bar';
}

main() {
  eval(r"""
    function Foo(a) {
      this.a = a;
    }

    Foo.b = 38;

    Foo.prototype.list = [2, 4, 6];

    Foo.prototype.bar = function() {
      return this.a;
    }

    Foo.prototype.toString = function() {
      return "I'm a Foo a=" + this.a;
    }

    Foo.prototype.fnList = [Foo.prototype.bar, Foo.prototype.toString];

    Foo.prototype.objectProperty = {
      'c': 1,
      'list': [10, 20, 30],
      'functionProperty': function() { return 'Function Property'; }
    }

    function jsFunction() {
      return "JS Function";
    }

    Foo.prototype.nestedFunction = function() {
      return function() {
        return 'Nested Function';
      };
    }

    Foo.prototype.getFirstEl = function(list) {
      return list[0];
    }

    Foo.prototype.sumFn = function(a, b) {
      return a + b;
    }

    Foo.prototype.getA = function(obj) {
      return obj.a;
    }

    Foo.prototype.callFn = function(fn) {
      return fn();
    }
    """);

  group('newObject', () {
    test('create', () {
      expect(identical(js_util.newObject(), js_util.newObject()), isFalse);
    });

    test('callMethod', () {
      var o = js_util.newObject();
      expect(js_util.callMethod(o, 'toString', []), equals('[object Object]'));
      expect(stringify(o), equals('{}'));
    });

    test('properties', () {
      var o = js_util.newObject();
      expect(js_util.hasProperty(o, 'foo bar'), isFalse);
      expect(js_util.hasProperty(o, 'toString'), isTrue);
      expect(js_util.callMethod(o, 'hasOwnProperty', ['toString']), isFalse);
      expect(js_util.callMethod(o, 'hasOwnProperty', ['foo bar']), isFalse);
      js_util.setProperty(o, 'foo bar', 42);
      expect(js_util.callMethod(o, 'hasOwnProperty', ['foo bar']), isTrue);
      expect(js_util.getProperty(o, 'foo bar'), equals(42));
      expect(js_util.hasProperty(o, 'foo bar'), isTrue);
      expect(stringify(o), equals('{"foo bar":42}'));
    });

    test('nested properties calls', () {
      var o = js_util.newObject();
      var f = new Foo(42);
      js_util.setProperty(o, 'foo', f);
      var foo = js_util.getProperty(o, 'foo');
      expect(foo, equals(f));
      expect(js_util.hasProperty(foo, 'a'), isTrue);
      expect(js_util.getProperty(foo, 'a'), equals(42));
      js_util.setProperty(foo, 'a', 24);
      expect(js_util.getProperty(foo, 'a'), equals(24));
    });
  });

  group('hasProperty', () {
    test('typed object', () {
      var f = new Foo(42);
      expect(js_util.hasProperty(f, 'a'), isTrue);
      expect(js_util.hasProperty(f, 'bar'), isTrue);
      expect(js_util.hasProperty(f, 'b'), isFalse);
      expect(js_util.hasProperty(f, 'toString'), isTrue);
      js_util.setProperty(f, '__proto__', null);
      expect(js_util.hasProperty(f, 'toString'), isFalse);
    });

    test('typed literal', () {
      var literal = new ExampleTypedLiteral(a: 'x', b: 42);
      expect(js_util.hasProperty(literal, 'a'), isTrue);
      expect(js_util.hasProperty(literal, 'b'), isTrue);
      expect(js_util.hasProperty(literal, 'anything'), isFalse);

      literal = new ExampleTypedLiteral(a: null);
      expect(js_util.hasProperty(literal, 'a'), isTrue);
      expect(js_util.hasProperty(literal, 'b'), isFalse);
      expect(js_util.hasProperty(literal, 'anything'), isFalse);
    });

    test('complex hasProperty calls', () {
      var f = new Foo(42);
      expect(js_util.hasProperty(f.objectProperty, 'c'), isTrue);
      expect(js_util.hasProperty(f.objectProperty, 'nonexistent'), isFalse);

      // Using a variable for the property name.
      String propertyName = 'bar';
      expect(js_util.hasProperty(f, propertyName), isTrue);
    });
  });

  group('getProperty', () {
    test('typed object', () {
      var f = new Foo(42);
      expect(js_util.getProperty(f, 'a'), equals(42));
      expect(js_util.getProperty(f, 'b'), isNull);
      expect(js_util.getProperty(f, 'bar') is Function, isTrue);
      expect(js_util.getProperty(f, 'list') is List, isTrue);
      expect(js_util.getProperty(f, 'objectProperty') is Object, isTrue);
      expect(js_util.getProperty(f, 'toString') is Function, isTrue);
      js_util.setProperty(f, '__proto__', null);
      expect(js_util.getProperty(f, 'toString'), isNull);
    });

    test('typed literal', () {
      var literal = new ExampleTypedLiteral(a: 'x', b: 42);
      expect(js_util.getProperty(literal, 'a'), equals('x'));
      expect(js_util.getProperty(literal, 'b'), equals(42));
      expect(js_util.getProperty(literal, 'anything'), isNull);
    });

    test('complex getProperty calls', () {
      var f = new Foo(42);

      // Accessing a method property.
      expect(js_util.getProperty(f, 'bar') is Function, isTrue);
      expect(js_util.callMethod(f, 'bar', []), equals(42));

      // Accessing list properties.
      expect(js_util.getProperty(f, 'list')[0], equals(2));
      expect(js_util.getProperty(f, 'fnList')[0] is Function, isTrue);
      expect(
          js_util.callMethod(
              js_util.getProperty(f, 'fnList')[0], 'apply', [f, []]),
          equals(42));

      // Accessing nested object properites.
      var objectProperty = js_util.getProperty(f, 'objectProperty');
      expect(js_util.getProperty(objectProperty, 'c'), equals(1));
      expect(js_util.getProperty(objectProperty, 'list') is List, isTrue);
      expect(js_util.getProperty(objectProperty, 'list')[1], equals(20));
      expect(
          js_util.getProperty(objectProperty, 'functionProperty') is Function,
          isTrue);

      // Using a variable for the property name.
      String propertyName = 'a';
      expect(js_util.getProperty(f, propertyName), equals(42));
      String bar = _getBarWithSideEffect();
      expect(js_util.getProperty(f, bar) is Function, isTrue);
      expect(js_util.callMethod(f, bar, []), equals(42));
    });
  });

  group('setProperty', () {
    test('typed object', () {
      var f = new Foo(42);
      expect(js_util.getProperty(f, 'a'), equals(42));
      js_util.setProperty(f, 'a', 100);
      expect(f.a, equals(100));
      expect(js_util.getProperty(f, 'a'), equals(100));

      expect(js_util.getProperty(f, 'list') is List, isTrue);
      js_util.setProperty(f, 'list', [8]);
      expect(js_util.getProperty(f, 'list') is List, isTrue);
      expect(js_util.getProperty(f, 'list')[0], equals(8));

      js_util.setProperty(f, 'newProperty', 'new');
      expect(js_util.getProperty(f, 'newProperty'), equals('new'));
    });

    test('typed literal', () {
      var literal = new ExampleTypedLiteral();
      js_util.setProperty(literal, 'a', 'foo');
      expect(js_util.getProperty(literal, 'a'), equals('foo'));
      expect(literal.a, equals('foo'));
      js_util.setProperty(literal, 'a', literal);
      expect(identical(literal.a, literal), isTrue);
      var list = ['arr'];
      js_util.setProperty(literal, 'a', list);
      expect(identical(literal.a, list), isTrue);
    });

    test('complex setProperty calls', () {
      var f = new Foo(42);

      // Set function property to a num.
      expect(js_util.getProperty(f, 'bar') is Function, isTrue);
      js_util.setProperty(f, 'bar', 5);
      expect(js_util.getProperty(f, 'bar') is Function, isFalse);
      expect(js_util.getProperty(f, 'bar'), equals(5));

      // Set property to a Dart function.
      js_util.setProperty(f, 'bar', allowInterop(dartFunction));
      expect(js_util.getProperty(f, 'bar') is Function, isTrue);
      expect(js_util.callMethod(f, 'bar', []), equals('Dart Function'));
      js_util.setProperty(f, 'bar', allowInterop(() {
        return 'Inline';
      }));
      expect(js_util.callMethod(f, 'bar', []), equals('Inline'));

      // Set property to a JS function.
      js_util.setProperty(f, 'bar', allowInterop(jsFunction));
      expect(js_util.getProperty(f, 'bar') is Function, isTrue);
      expect(js_util.callMethod(f, 'bar', []), equals('JS Function'));

      // Set property with nested object properties.
      js_util.setProperty(f.objectProperty, 'c', 'new val');
      expect(js_util.getProperty(f.objectProperty, 'c'), equals('new val'));
      js_util.setProperty(f.objectProperty, 'list', [1, 2, 3]);
      expect(js_util.getProperty(f.objectProperty, 'list')[1], equals(2));

      // Using a variable for the property name.
      String propertyName = 'bar';
      js_util.setProperty(f, propertyName, 'foo');
      expect(js_util.getProperty(f, 'bar'), equals('foo'));
      String bar = _getBarWithSideEffect();
      js_util.setProperty(f, bar, 'baz');
      expect(js_util.getProperty(f, bar), equals('baz'));
    });
  });

  group('callMethod', () {
    test('typed object', () {
      var f = new Foo(42);
      expect(js_util.callMethod(f, 'bar', []), equals(42));
    });

    test('complex callMethod calls', () {
      var f = new Foo(42);

      // Call a method that returns an unbound function.
      expect(js_util.callMethod(f, 'nestedFunction', []) is Function, isTrue);
      expect(js_util.callMethod(f, 'nestedFunction', [])(),
          equals('Nested Function'));

      // Call method on a nested function property.
      expect(js_util.callMethod(f.objectProperty, 'functionProperty', []),
          equals('Function Property'));

      // Call method with different args.
      expect(
          js_util.callMethod(f, 'getFirstEl', [
            [25, 50]
          ]),
          equals(25));
      expect(js_util.callMethod(f, 'sumFn', [2, 3]), equals(5));
      expect(js_util.callMethod(f, 'getA', [f]), equals(42));
      expect(js_util.callMethod(f, 'callFn', [allowInterop(jsFunction)]),
          equals("JS Function"));
      expect(js_util.callMethod(f, 'callFn', [allowInterop(dartFunction)]),
          equals("Dart Function"));
      expect(
          js_util.callMethod(f, 'callFn', [
            allowInterop(() {
              return "inline";
            })
          ]),
          equals("inline"));

      // Using a variable for the method name.
      String methodName = 'bar';
      expect(js_util.callMethod(f, methodName, []), equals(42));
      String bar = _getBarWithSideEffect();
      expect(js_util.callMethod(f, bar, []), equals(42));
    });
  });

  group('instanceof', () {
    test('typed object', () {
      var f = new Foo(42);
      expect(js_util.instanceof(f, JSFooType), isTrue);
      expect(js_util.instanceof(f, JSArrayBufferType), isFalse);
    });

    test('typed literal', () {
      var literal = new ExampleTypedLiteral();
      expect(js_util.instanceof(literal, JSFooType), isFalse);
    });
  });

  group('callConstructor', () {
    test('typed object', () {
      Foo f = js_util.callConstructor(JSFooType, [42]);
      expect(f.a, equals(42));
    });
  });
}
