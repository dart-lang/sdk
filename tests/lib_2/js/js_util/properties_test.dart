// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

// Tests the functionality of object properties with the js_util library. For
// js_util tests with HTML objects see tests/lib/html/js_util_test.dart.

@JS()
library js_util_properties_test;

import 'package:js/js.dart';
import 'package:js/js_util.dart' as js_util;
import 'package:expect/minitest.dart';

@JS('Object.setPrototypeOf')
external Object objectSetPrototypeOf(Object obj, Object proto);

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
  external List get list;
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

class DartClass {
  int x = 3;
  int getX() => x;

  static staticFunction() => 'static';
  static const staticConstList = [1];
}

class GenericDartClass<T> {
  final T myT;
  GenericDartClass(this.myT);

  T getT() => myT;
}

T getTopLevelGenerics<T>(T t) => t;

String _getBarWithSideEffect() {
  var x = 5;
  expect(x, equals(5));
  return 'bar';
}

@JS()
class CallMethodTest {
  external CallMethodTest();

  external zero();
  external one(a);
  external two(a, b);
  external three(a, b, c);
  external four(a, b, c, d);
  external five(a, b, c, d, e);
}

@JS()
external get Zero;
@JS()
external get One;
@JS()
external get Two;
@JS()
external get Three;
@JS()
external get Four;
@JS()
external get Five;

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

    function CallMethodTest() {}

    CallMethodTest.prototype.zero = function() {
      return 'zero';
    }
    CallMethodTest.prototype.one = function(a) {
      return 'one';
    }
    CallMethodTest.prototype.two = function(a, b) {
      return 'two';
    }
    CallMethodTest.prototype.three = function(a, b, c) {
      return 'three';
    }
    CallMethodTest.prototype.four = function(a, b, c, d) {
      return 'four';
    }
    CallMethodTest.prototype.five = function(a, b, c, d, e) {
      return 'five';
    }

    function Zero() {
      this.count = 0;
    }
    function One(a) {
      this.count = 1;
    }
    function Two(a, b) {
      this.count = 2;
    }
    function Three(a, b, c) {
      this.count = 3;
    }
    function Four(a, b, c, d) {
      this.count = 4;
    }
    function Five(a, b, c, d, e) {
      this.count = 5;
    }

    globalThis.globalKey = 'foo';
    """);

  group('globalThis', () {
    test('create', () {
      expect(identical(js_util.globalThis, js_util.globalThis), isTrue);
    });

    test('isGlobalThis', () {
      expect(js_util.hasProperty(js_util.globalThis, 'One'), isTrue);
      expect(js_util.getProperty(js_util.globalThis, 'globalKey'), 'foo');
    });
  });

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
      objectSetPrototypeOf(f, null);
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
      objectSetPrototypeOf(f, null);
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
      expect(js_util.getProperty(f.list, "0"), equals(2));
      var index = 0;
      expect(js_util.getProperty(f.list, index++), equals(2));
      expect(index, equals(1));
      expect(js_util.getProperty(f.list, index), equals(4));

      // Accessing nested object properties.
      var objectProperty = js_util.getProperty(f, 'objectProperty');
      expect(js_util.getProperty(objectProperty, 'c'), equals(1));
      expect(js_util.getProperty(objectProperty, 'list') is List, isTrue);
      expect(js_util.getProperty(objectProperty, 'list')[1], equals(20));
      expect(
          js_util.getProperty(objectProperty, 'functionProperty') is Function,
          isTrue);
      // Using nested getProperty calls.
      expect(
          js_util.getProperty(
              js_util.getProperty(
                  js_util.getProperty(f, 'objectProperty'), 'list'),
              1),
          equals(20));

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
      js_util.setProperty(f, 'a', null);
      expect(f.a, equals(null));

      expect(js_util.getProperty(f, 'list') is List, isTrue);
      js_util.setProperty(f, 'list', [8]);
      expect(js_util.getProperty(f, 'list') is List, isTrue);
      expect(js_util.getProperty(f, 'list')[0], equals(8));

      js_util.setProperty(f, 'newProperty', 'new');
      expect(js_util.getProperty(f, 'newProperty'), equals('new'));

      // Using a variable for the property value.
      var num = 4;
      js_util.setProperty(f, 'a', num);
      expect(f.a, equals(num));
      var str = 'bar';
      js_util.setProperty(f, 'a', str);
      expect(f.a, equals(str));
      var b = false;
      js_util.setProperty(f, 'a', b);
      expect(f.a, equals(b));
      var list = [2, 4, 6];
      js_util.setProperty(f, 'a', list);
      expect(f.a, equals(list));
      var fn = allowInterop(dartFunction);
      js_util.setProperty(f, 'a', fn);
      expect(f.a, equals(fn));
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
      js_util.setProperty(f, 'bar', allowInterop(DartClass.staticFunction));
      expect(js_util.callMethod(f, 'bar', []), equals('static'));

      // Set property to a JS function.
      js_util.setProperty(f, 'bar', allowInterop(jsFunction));
      expect(js_util.getProperty(f, 'bar') is Function, isTrue);
      expect(js_util.callMethod(f, 'bar', []), equals('JS Function'));

      // Set property with nested object properties.
      js_util.setProperty(f.objectProperty, 'c', 'new val');
      expect(js_util.getProperty(f.objectProperty, 'c'), equals('new val'));
      js_util.setProperty(f.objectProperty, 'list', [1, 2, 3]);
      expect(js_util.getProperty(f.objectProperty, 'list')[1], equals(2));
      // Using a nested getProperty call.
      js_util.setProperty(
          js_util.getProperty(f, 'objectProperty'), 'c', 'nested val');
      expect(js_util.getProperty(f.objectProperty, 'c'), equals('nested val'));

      // Using a variable for the property name.
      String propertyName = 'bar';
      js_util.setProperty(f, propertyName, 'foo');
      expect(js_util.getProperty(f, 'bar'), equals('foo'));
      String bar = _getBarWithSideEffect();
      js_util.setProperty(f, bar, 'baz');
      expect(js_util.getProperty(f, bar), equals('baz'));
      js_util.setProperty(f, _getBarWithSideEffect(), 'mumble');
      expect(js_util.getProperty(f, bar), equals('mumble'));

      // Set property to a function call.
      js_util.setProperty(f, 'a', dartFunction());
      String expected = dartFunction();
      expect(f.a, equals(expected));

      // Using a tearoff as the property value.
      js_util.setProperty(f, 'tearoff', allowInterop(DartClass().getX));
      expect(js_util.callMethod(f, 'tearoff', []), equals(3));

      // Set property to instance method calls.
      js_util.setProperty(f, 'a', DartClass().getX());
      expect(f.a, equals(3));
      js_util.setProperty(f, 'a', GenericDartClass<int>(5).getT());
      expect(f.a, equals(5));

      // Set property using a generics wrapper on value.
      js_util.setProperty(f, 'a', getTopLevelGenerics<int>(10));
      expect(f.a, equals(10));
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
      // Using a nested getProperty call.
      expect(
          js_util.callMethod(
              js_util.getProperty(f, 'objectProperty'), 'functionProperty', []),
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
          equals('JS Function'));
      expect(js_util.callMethod(f, 'callFn', [allowInterop(dartFunction)]),
          equals('Dart Function'));
      expect(
          js_util.callMethod(f, 'callFn', [
            allowInterop(() {
              return 'inline';
            })
          ]),
          equals('inline'));
      expect(
          js_util.callMethod(
              f, 'callFn', [allowInterop(DartClass.staticFunction)]),
          equals('static'));

      // Using a variable for the method name.
      String methodName = 'bar';
      expect(js_util.callMethod(f, methodName, []), equals(42));
      String bar = _getBarWithSideEffect();
      expect(js_util.callMethod(f, bar, []), equals(42));
    });

    test('callMethod with List edge cases', () {
      var o = CallMethodTest();

      expect(js_util.callMethod(o, 'zero', []), equals('zero'));
      expect(js_util.callMethod(o, 'zero', <int>[]), equals('zero'));
      expect(js_util.callMethod(o, 'zero', List.empty()), equals('zero'));
      expect(js_util.callMethod(o, 'zero', List<int>.empty()), equals('zero'));

      expect(
          js_util.callMethod(o, 'two', List<int>.filled(2, 0)), equals('two'));
      expect(js_util.callMethod(o, 'three', List<int>.generate(3, (i) => i)),
          equals('three'));

      Iterable<String> iterableStrings = <String>['foo', 'bar'];
      expect(js_util.callMethod(o, 'two', List.of(iterableStrings)),
          equals('two'));

      const l1 = [1, 2];
      const l2 = [3, 4];
      expect(js_util.callMethod(o, 'four', List.from(l1)..addAll(l2)),
          equals('four'));
      expect(js_util.callMethod(o, 'four', l1 + l2), equals('four'));
      expect(js_util.callMethod(o, 'four', List.unmodifiable([1, 2, 3, 4])),
          equals('four'));

      var setElements = {1, 2};
      expect(js_util.callMethod(o, 'two', setElements.toList()), equals('two'));

      var spreadList = [1, 2, 3];
      expect(js_util.callMethod(o, 'four', [1, ...spreadList]), equals('four'));
    });

    test('edge cases for lowering to _callMethodUncheckedN', () {
      var o = CallMethodTest();

      expect(js_util.callMethod(o, 'zero', []), equals('zero'));
      expect(js_util.callMethod(o, 'one', [1]), equals('one'));
      expect(js_util.callMethod(o, 'four', [1, 2, 3, 4]), equals('four'));
      expect(js_util.callMethod(o, 'five', [1, 2, 3, 4, 5]), equals('five'));

      // List with a type declaration, short circuits element checking
      expect(js_util.callMethod(o, 'two', <int>[1, 2]), equals('two'));

      // List as a variable instead of a List Literal or constant
      var list = [1, 2];
      expect(js_util.callMethod(o, 'two', list), equals('two'));

      // Mixed types of elements to check in the given list.
      var x = 4;
      var str = 'cat';
      var b = false;
      var evens = [2, 4, 6];
      expect(js_util.callMethod(o, 'four', [x, str, b, evens]), equals('four'));
      var obj = Object();
      expect(js_util.callMethod(o, 'one', [obj]), equals('one'));
      var nullElement = null;
      expect(js_util.callMethod(o, 'one', [nullElement]), equals('one'));

      // const lists.
      expect(js_util.callMethod(o, 'one', const [3]), equals('one'));
      const constList = [10, 20, 30];
      expect(js_util.callMethod(o, 'three', constList), equals('three'));
      expect(js_util.callMethod(o, 'one', DartClass.staticConstList),
          equals('one'));
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
      var f = js_util.callConstructor(JSFooType, [42]);
      expect(f.a, equals(42));

      var f2 =
          js_util.callConstructor(js_util.getProperty(f, 'constructor'), [5]);
      expect(f2.a, equals(5));
    });

    test('typed literal', () {
      ExampleTypedLiteral literal = js_util.callConstructor(
          js_util.getProperty(ExampleTypedLiteral(), 'constructor'), []);
      expect(literal.a, equals(null));
    });

    test('callConstructor with List edge cases', () {
      expect(js_util.getProperty(js_util.callConstructor(Zero, []), 'count'),
          equals(0));
      expect(
          js_util.getProperty(js_util.callConstructor(Zero, <int>[]), 'count'),
          equals(0));
      expect(
          js_util.getProperty(
              js_util.callConstructor(Zero, List.empty()), 'count'),
          equals(0));
      expect(
          js_util.getProperty(
              js_util.callConstructor(Zero, List<int>.empty()), 'count'),
          equals(0));

      expect(
          js_util.getProperty(
              js_util.callConstructor(Two, List<int>.filled(2, 0)), 'count'),
          equals(2));
      expect(
          js_util.getProperty(
              js_util.callConstructor(Three, List<int>.generate(3, (i) => i)),
              'count'),
          equals(3));

      Iterable<String> iterableStrings = <String>['foo', 'bar'];
      expect(
          js_util.getProperty(
              js_util.callConstructor(Two, List.of(iterableStrings)), 'count'),
          equals(2));

      const l1 = [1, 2];
      const l2 = [3, 4];
      expect(
          js_util.getProperty(
              js_util.callConstructor(Four, List.from(l1)..addAll(l2)),
              'count'),
          equals(4));
      expect(
          js_util.getProperty(js_util.callConstructor(Four, l1 + l2), 'count'),
          equals(4));
      expect(
          js_util.getProperty(
              js_util.callConstructor(Four, List.unmodifiable([1, 2, 3, 4])),
              'count'),
          equals(4));

      var setElements = {1, 2};
      expect(
          js_util.getProperty(
              js_util.callConstructor(Two, setElements.toList()), 'count'),
          equals(2));

      var spreadList = [1, 2, 3];
      expect(
          js_util.getProperty(
              js_util.callConstructor(Four, [1, ...spreadList]), 'count'),
          equals(4));
    });

    test('edge cases for lowering to _callConstructorUncheckedN', () {
      expect(js_util.getProperty(js_util.callConstructor(Zero, []), 'count'),
          equals(0));
      expect(js_util.getProperty(js_util.callConstructor(One, [1]), 'count'),
          equals(1));
      expect(
          js_util.getProperty(
              js_util.callConstructor(Four, [1, 2, 3, 4]), 'count'),
          equals(4));
      expect(
          js_util.getProperty(
              js_util.callConstructor(Five, [1, 2, 3, 4, 5]), 'count'),
          equals(5));

      // List with a type declaration, short circuits element checking
      expect(
          js_util.getProperty(
              js_util.callConstructor(Two, <int>[1, 2]), 'count'),
          equals(2));

      // List as a variable instead of a List Literal or constant
      var list = [1, 2];
      expect(js_util.getProperty(js_util.callConstructor(Two, list), 'count'),
          equals(2));

      // Mixed types of elements to check in the given list.
      var x = 4;
      var str = 'cat';
      var b = false;
      var evens = [2, 4, 6];
      expect(
          js_util.getProperty(
              js_util.callConstructor(Four, [x, str, b, evens]), 'count'),
          equals(4));
      var obj = Object();
      expect(js_util.getProperty(js_util.callConstructor(One, [obj]), 'count'),
          equals(1));
      var nullElement = null;
      expect(
          js_util.getProperty(
              js_util.callConstructor(One, [nullElement]), 'count'),
          equals(1));

      // const lists.
      expect(
          js_util.getProperty(js_util.callConstructor(One, const [3]), 'count'),
          equals(1));
      const constList = [10, 20, 30];
      expect(
          js_util.getProperty(
              js_util.callConstructor(Three, constList), 'count'),
          equals(3));
      expect(
          js_util.getProperty(
              js_util.callConstructor(One, DartClass.staticConstList), 'count'),
          equals(1));
    });
  });
}
