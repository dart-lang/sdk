// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@JS()
library js_native_test;

import 'dart:async';
import 'dart:html';
import 'dart:typed_data' show ByteBuffer, Int32List;
import 'dart:indexed_db' show IdbFactory, KeyRange;

import 'package:js/js.dart';
import 'package:js/js_util.dart' as js_util;

import 'package:unittest/unittest.dart';
import 'package:unittest/html_individual_config.dart';

_injectJs() {
  final script = new ScriptElement();
  script.type = 'text/javascript';
  script.innerHtml = r"""
var x = 42;

var _x = 123;

var myArray = ["value1"];

function returnThis() {
  return this;
}

function getTypeOf(o) {
  return typeof(o);
}

function Foo(a) {
  this.a = a;
}

Foo.b = 38;

Foo.prototype.bar = function() {
  return this.a;
}
Foo.prototype.toString = function() {
  return "I'm a Foo a=" + this.a;
}

var container = new Object();
container.Foo = Foo;

function checkMap(m, key, value) {
  if (m.hasOwnProperty(key))
    return m[key] == value;
  else
    return false;
}

""";
  document.body.append(script);
}

@JS()
external bool checkMap(m, String, value);

@JS('JSON.stringify')
external String stringify(o);

@JS('Node')
external get JSNodeType;

@JS('Element')
external get JSElementType;

@JS('Text')
external get JSTextType;

@JS('HTMLCanvasElement')
external get JSHtmlCanvasElementType;

@JS()
class Foo {
  external Foo(num a);

  external num get a;
  external num bar();
}

@JS('Foo')
external get JSFooType;

@JS()
@anonymous
class ExampleTypedLiteral {
  external factory ExampleTypedLiteral({a, b, JS$_c, JS$class});

  external get a;
  external get b;
  external get JS$_c;
  external set JS$_c(v);
  // Identical to JS$_c but only accessible within the library.
  external get _c;
  external get JS$class;
  external set JS$class(v);
}

@JS("Object.prototype.hasOwnProperty")
external get _hasOwnProperty;

bool hasOwnProperty(o, String name) {
  return js_util.callMethod(_hasOwnProperty, 'call', [o, name]);
}

main() {
  _injectJs();
  useHtmlIndividualConfiguration();

  group('js_util.jsify()', () {
    test('convert a List', () {
      final list = [1, 2, 3, 4, 5, 6, 7, 8];
      var array = js_util.jsify(list);
      expect(array is List, isTrue);
      expect(identical(array, list), isFalse);
      expect(array.length, equals(list.length));
      for (var i = 0; i < list.length; i++) {
        expect(array[i], equals(list[i]));
      }
    });

    test('convert an Iterable', () {
      final set = new Set.from([1, 2, 3, 4, 5, 6, 7, 8]);
      var array = js_util.jsify(set);
      expect(array is List, isTrue);
      expect(array.length, equals(set.length));
      for (var i = 0; i < array.length; i++) {
        expect(set.contains(array[i]), isTrue);
      }
    });

    test('convert a Map', () {
      var map = {'a': 1, 'b': 2, 'c': 3};
      var jsMap = js_util.jsify(map);
      expect(jsMap is! List, isTrue);
      for (var key in map.keys) {
        expect(checkMap(jsMap, key, map[key]), isTrue);
      }
    });

    test('deep convert a complex object', () {
      final object = {
        'a': [
          1,
          [2, 3]
        ],
        'b': {'c': 3, 'd': new Foo(42)},
        'e': null
      };
      var jsObject = js_util.jsify(object);
      expect(js_util.getProperty(jsObject, 'a')[0], equals(object['a'][0]));
      expect(
          js_util.getProperty(jsObject, 'a')[1][0], equals(object['a'][1][0]));
      expect(
          js_util.getProperty(jsObject, 'a')[1][1], equals(object['a'][1][1]));
      expect(js_util.getProperty(js_util.getProperty(jsObject, 'b'), 'c'),
          equals(object['b']['c']));
      expect(js_util.getProperty(js_util.getProperty(jsObject, 'b'), 'd'),
          equals(object['b']['d']));
      expect(
          js_util.callMethod(
              js_util.getProperty(js_util.getProperty(jsObject, 'b'), 'd'),
              'bar', []),
          equals(42));
      expect(js_util.getProperty(jsObject, 'e'), isNull);
    });

    test('throws if object is not a Map or Iterable', () {
      expect(
          () => js_util.jsify('a'), throwsA(new isInstanceOf<ArgumentError>()));
    });
  });

  group('js_util.newObject', () {
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
      expect(hasOwnProperty(o, 'toString'), isFalse);
      expect(hasOwnProperty(o, 'foo bar'), isFalse);
      js_util.setProperty(o, 'foo bar', 42);
      expect(hasOwnProperty(o, 'foo bar'), isTrue);
      expect(js_util.getProperty(o, 'foo bar'), equals(42));
      expect(js_util.hasProperty(o, 'foo bar'), isTrue);
      expect(stringify(o), equals('{"foo bar":42}'));
    });
  });

  group('hasProperty', () {
    test('typed object', () {
      var f = new Foo(42);
      expect(js_util.hasProperty(f, 'a'), isTrue);
      expect(js_util.hasProperty(f, 'toString'), isTrue);
      js_util.setProperty(f, '__proto__', null);
      expect(js_util.hasProperty(f, 'toString'), isFalse);
    });
    test('typed literal', () {
      var l =
          new ExampleTypedLiteral(a: 'x', b: 42, JS$_c: null, JS$class: true);
      expect(js_util.hasProperty(l, 'a'), isTrue);
      expect(js_util.hasProperty(l, 'b'), isTrue);
      expect(js_util.hasProperty(l, '_c'), isTrue);
      expect(l.JS$_c, isNull);
      expect(js_util.hasProperty(l, 'class'), isTrue);
      // JS$_c escapes to _c so the property JS$_c will not exist on the object.
      expect(js_util.hasProperty(l, r'JS$_c'), isFalse);
      expect(js_util.hasProperty(l, r'JS$class'), isFalse);
      expect(l.JS$class, isTrue);

      l = new ExampleTypedLiteral(a: null);
      expect(js_util.hasProperty(l, 'a'), isTrue);
      expect(js_util.hasProperty(l, 'b'), isFalse);
      expect(js_util.hasProperty(l, '_c'), isFalse);
      expect(js_util.hasProperty(l, 'class'), isFalse);

      l = new ExampleTypedLiteral(JS$_c: 74);
      expect(js_util.hasProperty(l, '_c'), isTrue);
      expect(l.JS$_c, equals(74));
    });
  });

  group('getProperty', () {
    test('typed object', () {
      var f = new Foo(42);
      expect(js_util.getProperty(f, 'a'), equals(42));
      expect(js_util.getProperty(f, 'toString') is Function, isTrue);
      js_util.setProperty(f, '__proto__', null);
      expect(js_util.getProperty(f, 'toString'), isNull);
    });

    test('typed literal', () {
      var l = new ExampleTypedLiteral(a: 'x', b: 42, JS$_c: 7, JS$class: true);
      expect(js_util.getProperty(l, 'a'), equals('x'));
      expect(js_util.getProperty(l, 'b'), equals(42));
      expect(js_util.getProperty(l, '_c'), equals(7));
      expect(l.JS$_c, equals(7));
      expect(js_util.getProperty(l, 'class'), isTrue);
      expect(js_util.getProperty(l, r'JS$_c'), isNull);
      expect(js_util.getProperty(l, r'JS$class'), isNull);
    });
  });

  group('setProperty', () {
    test('typed object', () {
      var f = new Foo(42);
      expect(js_util.getProperty(f, 'a'), equals(42));
      js_util.setProperty(f, 'a', 100);
      expect(f.a, equals(100));
      expect(js_util.getProperty(f, 'a'), equals(100));
    });

    test('typed literal', () {
      var l = new ExampleTypedLiteral();
      js_util.setProperty(l, 'a', 'foo');
      expect(js_util.getProperty(l, 'a'), equals('foo'));
      expect(l.a, equals('foo'));
      js_util.setProperty(l, 'a', l);
      expect(identical(l.a, l), isTrue);
      var list = ['arr'];
      js_util.setProperty(l, 'a', list);
      expect(identical(l.a, list), isTrue);
      l.JS$class = 42;
      expect(l.JS$class, equals(42));
      js_util.setProperty(l, 'class', 100);
      expect(l.JS$class, equals(100));
    });
  });

  group('callMethod', () {
    test('html object', () {
      var canvas = new Element.tag('canvas');
      expect(
          identical(canvas.getContext('2d'),
              js_util.callMethod(canvas, 'getContext', ['2d'])),
          isTrue);
    });

    test('typed object', () {
      var f = new Foo(42);
      expect(js_util.callMethod(f, 'bar', []), equals(42));
    });
  });

  group('instanceof', () {
    test('html object', () {
      var canvas = new Element.tag('canvas');
      expect(js_util.instanceof(canvas, JSNodeType), isTrue);
      expect(js_util.instanceof(canvas, JSTextType), isFalse);
      expect(js_util.instanceof(canvas, JSElementType), isTrue);
      expect(js_util.instanceof(canvas, JSHtmlCanvasElementType), isTrue);
      var div = new Element.tag('div');
      expect(js_util.instanceof(div, JSNodeType), isTrue);
      expect(js_util.instanceof(div, JSTextType), isFalse);
      expect(js_util.instanceof(div, JSElementType), isTrue);
      expect(js_util.instanceof(div, JSHtmlCanvasElementType), isFalse);

      var text = new Text('foo');
      expect(js_util.instanceof(text, JSNodeType), isTrue);
      expect(js_util.instanceof(text, JSTextType), isTrue);
      expect(js_util.instanceof(text, JSElementType), isFalse);
    });

    test('typed object', () {
      var f = new Foo(42);
      expect(js_util.instanceof(f, JSFooType), isTrue);
      expect(js_util.instanceof(f, JSNodeType), isFalse);
    });

    test('typed literal', () {
      var l = new ExampleTypedLiteral();
      expect(js_util.instanceof(l, JSFooType), isFalse);
    });
  });

  group('callConstructor', () {
    test('html object', () {
      var textNode = js_util.callConstructor(JSTextType, ['foo']);
      expect(js_util.instanceof(textNode, JSTextType), isTrue);
      expect(textNode is Text, isTrue);
      expect(textNode.text, equals('foo'));
    });

    test('typed object', () {
      Foo f = js_util.callConstructor(JSFooType, [42]);
      expect(f.a, equals(42));
    });
  });
}
