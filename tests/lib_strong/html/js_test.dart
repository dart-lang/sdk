// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'dart:typed_data' show Int32List;
import 'dart:indexed_db' show IdbFactory, KeyRange;
import 'dart:js';
import 'package:js/js_util.dart' as js_util;

import 'package:expect/minitest.dart';

_injectJs() {
  final script = new ScriptElement();
  script.type = 'text/javascript';
  script.innerHtml = r"""
var x = 42;

var _x = 123;

var myArray = ["value1"];

var foreignDoc = (function(){
  var doc = document.implementation.createDocument("", "root", null);
  var element = doc.createElement('element');
  element.setAttribute('id', 'abc');
  doc.documentElement.appendChild(element);
  return doc;
})();

function razzle() {
  return x;
}

function returnThis() {
  return this;
}

function getTypeOf(o) {
  return typeof(o);
}

function varArgs() {
  var args = arguments;
  var sum = 0;
  for (var i = 0; i < args.length; ++i) {
    sum += args[i];
  }
  return sum;
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

function isArray(a) {
  return a instanceof Array;
}

function checkMap(m, key, value) {
  if (m.hasOwnProperty(key))
    return m[key] == value;
  else
    return false;
}

function invokeCallback() {
  return callback();
}

function invokeCallbackWith11params() {
  return callbackWith11params(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11);
}

function returnElement(element) {
  return element;
}

function getElementAttribute(element, attr) {
  return element.getAttribute(attr);
}

function addClassAttributes(list) {
  var result = "";
  for (var i=0; i < list.length; i++) {
    result += list[i].getAttribute("class");
  }
  return result;
}

function getNewDate() {
  return new Date(1995, 11, 17);
}

function getNewDivElement() {
  return document.createElement("div");
}

function getNewEvent() {
  return new CustomEvent('test');
}

function getNewBlob() {
  var fileParts = ['<a id="a"><b id="b">hey!</b></a>'];
  return new Blob(fileParts, {type : 'text/html'});
}

function getNewIDBKeyRange() {
  return IDBKeyRange.only(1);
}

function getNewImageData() {
  var canvas = document.createElement('canvas');
  var context = canvas.getContext('2d');
  return context.createImageData(1, 1);
}

function getNewInt32Array() {
  return new Int32Array([1, 2, 3, 4, 5, 6, 7, 8]);
}

function getNewArrayBuffer() {
  return new ArrayBuffer(8);
}

function isPropertyInstanceOf(property, type) {
  return window[property] instanceof type;
}

function testJsMap(callback) {
  var result = callback();
  return result['value'];
}

function addTestProperty(o) {
  o.testProperty = "test";
}

function fireClickEvent(w) {
  var event = w.document.createEvent('Events');
  event.initEvent('click', true, false);
  w.document.dispatchEvent(event);
}

function Bar() {
  return "ret_value";
}
Bar.foo = "property_value";

function Baz(p1,p2,p3,p4,p5,p6,p7,p8,p9,p10,p11) {
  this.f1 = p1;
  this.f2 = p2;
  this.f3 = p3;
  this.f4 = p4;
  this.f5 = p5;
  this.f6 = p6;
  this.f7 = p7;
  this.f8 = p8;
  this.f9 = p9;
  this.f10 = p10;
  this.f11 = p11;
}

function Liar(){}

Liar.prototype.toString = function() {
  return 1;
}

function identical(o1, o2) {
  return o1 === o2;
}

var someProto = { role: "proto" };
var someObject = Object.create(someProto);
someObject.role = "object";

""";
  document.body.append(script);
}

// Some test are either causing other test to fail in IE9, or they are failing
// for unknown reasons
// useHtmlConfiguration+ImageData bug: dartbug.com/14355
skipIE9_test(String description, t()) {
  if (Platform.supportsTypedData) {
    test(description, t);
  }
}

class Foo {
  final JsObject _proxy;

  Foo(num a) : this._proxy = new JsObject(context['Foo'], [a]);

  JsObject toJs() => _proxy;

  num get a => _proxy['a'];
  num bar() => _proxy.callMethod('bar');
}

class Color {
  static final RED = new Color._("red");
  static final BLUE = new Color._("blue");
  String _value;
  Color._(this._value);
  String toJs() => this._value;
}

class TestDartObject {}

class Callable {
  call() => 'called';
}

main() {
  _injectJs();

  group('identity', () {
    test('context instances should be identical', () {
      var c1 = context;
      var c2 = context;
      expect(identical(c1, c2), isTrue);
    });

    test('identical JS objects should have identical proxies', () {
      var o1 = new JsObject(context['Foo'], [1]);
      context['f1'] = o1;
      var o2 = context['f1'];
      expect(identical(o1, o2), isTrue);
    });

/*
 TODO(jacobr): enable this test when dartium supports maintaining proxy
    equality.
    test('identical Dart objects should have identical proxies', () {
      var o1 = new TestDartObject();
      expect(context.callMethod('identical', [o1, o1]), isTrue);
    });
    */

    test('identical Dart functions should have identical proxies', () {
      var f1 = allowInterop(() => print("I'm a Function!"));
      expect(context.callMethod('identical', [f1, f1]), isTrue);
    });

    test('identical JS functions should have identical proxies', () {
      var f1 = context['Object'];
      var f2 = context['Object'];
      expect(identical(f1, f2), isTrue);
    });

    // TODO(justinfagnani): old tests duplicate checks above, remove
    // on test next cleanup pass
    test('test proxy equality', () {
      var foo1 = new JsObject(context['Foo'], [1]);
      var foo2 = new JsObject(context['Foo'], [2]);
      context['foo1'] = foo1;
      context['foo2'] = foo2;
      expect(foo1, notEquals(context['foo2']));
      expect(foo2, equals(context['foo2']));
      context.deleteProperty('foo1');
      context.deleteProperty('foo2');
    });

    test('retrieve same dart Object', () {
      final obj = new Object();
      context['obj'] = obj;
      expect(context['obj'], same(obj));
      context.deleteProperty('obj');
    });

    group('caching', () {
      test('JS->Dart', () {
        // Test that we are not pulling cached proxy from the prototype
        // when asking for a proxy for the object.
        final proto = context['someProto'];
        expect(proto['role'], equals('proto'));
        final obj = context['someObject'];
        expect(obj['role'], equals('object'));
      });
    });
  });

  group('context', () {
    test('read global field', () {
      expect(context['x'], equals(42));
      expect(context['y'], isNull);
    });

    test('read global field with underscore', () {
      expect(context['_x'], equals(123));
      expect(context['y'], isNull);
    });

    test('write global field', () {
      context['y'] = 42;
      expect(context['y'], equals(42));
    });
  });

  group('new_JsObject', () {
    test('new Foo()', () {
      var foo = new JsObject(context['Foo'], [42]);
      expect(foo['a'], equals(42));
      expect(foo.callMethod('bar'), equals(42));
      expect(() => foo.callMethod('baz'), throwsNoSuchMethodError);
    });

    test('new container.Foo()', () {
      final Foo2 = context['container']['Foo'];
      final foo = new JsObject(Foo2, [42]);
      expect(foo['a'], 42);
      expect(Foo2['b'], 38);
    });

    test('new Array()', () {
      var a = new JsObject(context['Array']);
      expect(a is JsArray, isTrue);

      // Test that the object still behaves via the base JsObject interface.
      // JsArray specific tests are below.
      expect(a['length'], 0);

      a.callMethod('push', ["value 1"]);
      expect(a['length'], 1);
      expect(a[0], "value 1");

      a.callMethod('pop');
      expect(a['length'], 0);
    });

    test('new Date()', () {
      final a = new JsObject(context['Date']);
      expect(a.callMethod('getTime'), isNotNull);
    });

    test('new Date(12345678)', () {
      final a = new JsObject(context['Date'], [12345678]);
      expect(a.callMethod('getTime'), equals(12345678));
    });

    test('new Date("December 17, 1995 03:24:00 GMT")', () {
      final a =
          new JsObject(context['Date'], ["December 17, 1995 03:24:00 GMT"]);
      expect(a.callMethod('getTime'), equals(819170640000));
    });

    test('new Date(1995,11,17)', () {
      // Note: JS Date counts months from 0 while Dart counts from 1.
      final a = new JsObject(context['Date'], [1995, 11, 17]);
      final b = new DateTime(1995, 12, 17);
      expect(a.callMethod('getTime'), equals(b.millisecondsSinceEpoch));
    });

    test('new Date(1995,11,17,3,24,0)', () {
      // Note: JS Date counts months from 0 while Dart counts from 1.
      final a = new JsObject(context['Date'], [1995, 11, 17, 3, 24, 0]);
      final b = new DateTime(1995, 12, 17, 3, 24, 0);
      expect(a.callMethod('getTime'), equals(b.millisecondsSinceEpoch));
    });

    test('new Object()', () {
      final a = new JsObject(context['Object']);
      expect(a, isNotNull);

      a['attr'] = "value";
      expect(a['attr'], equals("value"));
    });

    test(r'new RegExp("^\w+$")', () {
      final a = new JsObject(context['RegExp'], [r'^\w+$']);
      expect(a, isNotNull);
      expect(a.callMethod('test', ['true']), isTrue);
      expect(a.callMethod('test', [' false']), isFalse);
    });

    test('js instantiation via map notation : new Array()', () {
      final a = new JsObject(context['Array']);
      expect(a, isNotNull);
      expect(a['length'], equals(0));

      a.callMethod('push', ["value 1"]);
      expect(a['length'], equals(1));
      expect(a[0], equals("value 1"));

      a.callMethod('pop');
      expect(a['length'], equals(0));
    });

    test('js instantiation via map notation : new Date()', () {
      final a = new JsObject(context['Date']);
      expect(a.callMethod('getTime'), isNotNull);
    });

    test('typed array', () {
      if (Platform.supportsTypedData) {
        // Safari's ArrayBuffer is not a Function and so doesn't support bind
        // which JsObject's constructor relies on.
        // bug: https://bugs.webkit.org/show_bug.cgi?id=122976
        if (context['ArrayBuffer']['bind'] != null) {
          final codeUnits = "test".codeUnits;
          final buf = new JsObject(context['ArrayBuffer'], [codeUnits.length]);
          final bufView = new JsObject(context['Uint8Array'], [buf]);
          for (var i = 0; i < codeUnits.length; i++) {
            bufView[i] = codeUnits[i];
          }
        }
      }
    });

    test('>10 parameters', () {
      final o =
          new JsObject(context['Baz'], [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]);
      for (var i = 1; i <= 11; i++) {
        expect(o["f$i"], i);
      }
      expect(o['constructor'], equals(context['Baz']));
    });
  });

  group('JsFunction and callMethod', () {
    test('new JsObject can return a JsFunction', () {
      var f = new JsObject(context['Function']);
      expect(f is JsFunction, isTrue);
    });

    test('JsFunction.apply on a function defined in JS', () {
      expect(context['razzle'].apply([]), equals(42));
    });

    test('JsFunction.apply on a function that uses this', () {
      var object = new Object();
      expect(context['returnThis'].apply([], thisArg: object), same(object));
    });

    test('JsObject.callMethod on a function defined in JS', () {
      expect(context.callMethod('razzle'), equals(42));
      expect(() => context.callMethod('dazzle'), throwsNoSuchMethodError);
    });

    test('callMethod with many arguments', () {
      expect(context.callMethod('varArgs', [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]),
          equals(55));
    });

    test('access a property of a function', () {
      expect(context.callMethod('Bar'), "ret_value");
      expect(context['Bar']['foo'], "property_value");
    });
/*
 TODO(jacobr): evaluate whether we should be in the business of throwing
 ArgumentError outside of checked mode. In unchecked mode this should just
 return a NoSuchMethodError as the class lacks a method "true".

    test('callMethod throws if name is not a String or num', () {
      expect(() => context.callMethod(true),
          throwsArgumentError);
    });
*/
  });

  group('JsArray', () {
    test('new JsArray()', () {
      var array = new JsArray();
      var arrayType = context['Array'];
      expect(array.instanceof(arrayType), true);
      expect(array, []);
      // basic check that it behaves like a List
      array.addAll([1, 2, 3]);
      expect(array, [1, 2, 3]);
    });

    test('new JsArray.from()', () {
      var array = new JsArray.from([1, 2, 3]);
      var arrayType = context['Array'];
      expect(array.instanceof(arrayType), true);
      expect(array, [1, 2, 3]);
    });

    test('get Array from JS', () {
      context['a'] = new JsObject(context['Array'], [1, 2, 3]);
      expect(
          context.callMethod('isPropertyInstanceOf', ['a', context['Array']]),
          isTrue);
      var a = context['a'];
      expect(a is JsArray, isTrue);
      expect(a, [1, 2, 3]);
      context.deleteProperty('a');
    });

    test('pass Array to JS', () {
      context['a'] = [1, 2, 3];
      var a = context['a'];
      expect(a is List, isTrue);
      expect(a is JsArray, isFalse);
      expect(a, [1, 2, 3]);
      context.deleteProperty('a');
    });

    test('[]', () {
      var array = new JsArray.from([1, 2]);
      expect(array[0], 1);
      expect(array[1], 2);
      expect(() => array[-1], throwsRangeError);
      expect(() => array[2], throwsRangeError);
    });

    test('[]=', () {
      var array = new JsArray<Object>.from([1, 2]);
      array[0] = 'd';
      array[1] = 'e';
      expect(array, ['d', 'e']);
      expect(() => array[-1] = 3, throwsRangeError);
      expect(() => array[2] = 3, throwsRangeError);
    });

    test('length', () {
      var array = new JsArray.from([1, 2, 3]);
      expect(array.length, 3);
      array.add(4);
      expect(array.length, 4);
      array.length = 2;
      expect(array, [1, 2]);
      array.length = 3;
      expect(array, [1, 2, null]);
    });

    test('add', () {
      var array = new JsArray();
      array.add('a');
      expect(array, ['a']);
      array.add('b');
      expect(array, ['a', 'b']);
    });

    test('addAll', () {
      var array = new JsArray();
      array.addAll(['a', 'b']);
      expect(array, ['a', 'b']);
      // make sure addAll can handle Iterables
      array.addAll(new Set.from(['c']));
      expect(array, ['a', 'b', 'c']);
    });

    test('insert', () {
      var array = new JsArray.from([]);
      array.insert(0, 'b');
      expect(array, ['b']);
      array.insert(0, 'a');
      expect(array, ['a', 'b']);
      array.insert(2, 'c');
      expect(array, ['a', 'b', 'c']);
      expect(() => array.insert(4, 'e'), throwsRangeError);
      expect(() => array.insert(-1, 'e'), throwsRangeError);
    });

    test('removeAt', () {
      var array = new JsArray.from(['a', 'b', 'c']);
      expect(array.removeAt(1), 'b');
      expect(array, ['a', 'c']);
      expect(() => array.removeAt(2), throwsRangeError);
      expect(() => array.removeAt(-1), throwsRangeError);
    });

    test('removeLast', () {
      var array = new JsArray.from(['a', 'b', 'c']);
      expect(array.removeLast(), 'c');
      expect(array, ['a', 'b']);
      array.length = 0;
      expect(() => array.removeLast(), throwsRangeError);
    });

    test('removeRange', () {
      var array = new JsArray.from(['a', 'b', 'c', 'd']);
      array.removeRange(1, 3);
      expect(array, ['a', 'd']);
      expect(() => array.removeRange(-1, 2), throwsRangeError);
      expect(() => array.removeRange(0, 3), throwsRangeError);
      expect(() => array.removeRange(2, 1), throwsRangeError);
    });

    test('setRange', () {
      var array = new JsArray.from(['a', 'b', 'c', 'd']);
      array.setRange(1, 3, ['e', 'f']);
      expect(array, ['a', 'e', 'f', 'd']);
      array.setRange(3, 4, ['g', 'h', 'i'], 1);
      expect(array, ['a', 'e', 'f', 'h']);
    });

    test('sort', () {
      var array = new JsArray.from(['c', 'a', 'b']);
      array.sort();
      expect(array, ['a', 'b', 'c']);
    });

    test('sort with a Comparator', () {
      var array = new JsArray.from(['c', 'a', 'b']);
      array.sort((a, b) => -(a.compareTo(b)));
      expect(array, ['c', 'b', 'a']);
    });
  });

  group('JsObject.fromBrowserObject()', () {
    test('Nodes are proxied', () {
      var node = new JsObject.fromBrowserObject(new DivElement());
      context.callMethod('addTestProperty', [node]);
      expect(node is JsObject, isTrue);
      // TODO(justinfagnani): make this work in IE9
      // expect(node.instanceof(context['HTMLDivElement']), isTrue);
      expect(node['testProperty'], 'test');
    });

    test('primitives and null throw ArgumentError', () {
      for (var v in ['a', 1, 2.0, true, null]) {
        expect(() => new JsObject.fromBrowserObject(v), throwsArgumentError);
      }
    });
  });

  group('Dart_functions', () {
    test('invoke Dart callback from JS', () {
      expect(() => context.callMethod('invokeCallback'), throws);

      context['callback'] = () => 42;
      expect(context.callMethod('invokeCallback'), equals(42));

      context.deleteProperty('callback');
    });

    test('pass a Dart function to JS and back', () {
      var dartFunction = () => 42;
      context['dartFunction'] = dartFunction;
      expect(identical(context['dartFunction'], dartFunction), isTrue);
      context.deleteProperty('dartFunction');
    });

    test('callback as parameter', () {
      expect(context.callMethod('getTypeOf', [context['razzle']]),
          equals("function"));
    });

    test('invoke Dart callback from JS with this', () {
      // A JavaScript constructor function implemented in Dart which
      // uses 'this'
      final constructor = new JsFunction.withThis(($this, arg1) {
        var t = $this;
        $this['a'] = 42;
      });
      var o = new JsObject(constructor, ["b"]);
      expect(o['a'], equals(42));
    });

    test('invoke Dart callback from JS with 11 parameters', () {
      context['callbackWith11params'] =
          (p1, p2, p3, p4, p5, p6, p7, p8, p9, p10, p11) =>
              '$p1$p2$p3$p4$p5$p6$p7$p8$p9$p10$p11';
      expect(context.callMethod('invokeCallbackWith11params'),
          equals('1234567891011'));
    });

    test('return a JS proxy to JavaScript', () {
      var result = context.callMethod('testJsMap', [
        () => new JsObject.jsify({'value': 42})
      ]);
      expect(result, 42);
    });

    test('emulated functions should be callable in JS', () {
      context['callable'] = new Callable();
      var result = context.callMethod('callable');
      expect(result, 'called');
      context.deleteProperty('callable');
    });
  });

  group('JsObject.jsify()', () {
    test('convert a List', () {
      final list = [1, 2, 3, 4, 5, 6, 7, 8];
      var array = new JsObject.jsify(list);
      expect(context.callMethod('isArray', [array]), isTrue);
      expect(array['length'], equals(list.length));
      for (var i = 0; i < list.length; i++) {
        expect(array[i], equals(list[i]));
      }
    });

    test('convert an Iterable', () {
      final set = new Set.from([1, 2, 3, 4, 5, 6, 7, 8]);
      var array = new JsObject.jsify(set);
      expect(context.callMethod('isArray', [array]), isTrue);
      expect(array['length'], equals(set.length));
      for (var i = 0; i < array['length']; i++) {
        expect(set.contains(array[i]), isTrue);
      }
    });

    test('convert a Map', () {
      var map = {
        'a': 1,
        'b': 2,
        'c': 3,
        'd': allowInteropCaptureThis((that) => 42)
      };
      var jsMap = new JsObject.jsify(map);
      expect(!context.callMethod('isArray', [jsMap]), isTrue);
      for (final key in map.keys) {
        expect(context.callMethod('checkMap', [jsMap, key, map[key]]), isTrue);
      }
    });

    test('deep convert a complex object', () {
      dynamic object = {
        'a': [
          1,
          [2, 3]
        ],
        'b': {
          'c': 3,
          'd': new JsObject(context['Foo'], [42])
        },
        'e': null
      };
      var jsObject = new JsObject.jsify(object);
      expect(jsObject['a'][0], equals(object['a'][0]));
      expect(jsObject['a'][1][0], equals(object['a'][1][0]));
      expect(jsObject['a'][1][1], equals(object['a'][1][1]));
      expect(jsObject['b']['c'], equals(object['b']['c']));
      expect(jsObject['b']['d'], equals(object['b']['d']));
      expect(jsObject['b']['d'].callMethod('bar'), equals(42));
      expect(jsObject['e'], isNull);
    });

    test('throws if object is not a Map or Iterable', () {
      expect(() => new JsObject.jsify('a'), throwsArgumentError);
    });
  });

  group('JsObject_methods', () {
    test('hashCode and ==', () {
      final o1 = context['Object'];
      final o2 = context['Object'];
      expect(o1 == o2, isTrue);
      expect(o1.hashCode == o2.hashCode, isTrue);
      final d = context['document'];
      expect(o1 == d, isFalse);
    });

    test('toString', () {
      var foo = new JsObject(context['Foo'], [42]);
      expect(foo.toString(), equals("I'm a Foo a=42"));
      var container = context['container'];
      expect(container.toString(), equals("[object Object]"));
    });

    test('toString returns a String even if the JS object does not', () {
      var foo = new JsObject(context['Liar']);
      expect(foo.callMethod('toString'), 1);
      expect(foo.toString(), '1');
    });

    test('instanceof', () {
      var foo = new JsObject(context['Foo'], [1]);
      expect(foo.instanceof(context['Foo']), isTrue);
      expect(foo.instanceof(context['Object']), isTrue);
      expect(foo.instanceof(context['String']), isFalse);
    });

    test('deleteProperty', () {
      var object = new JsObject.jsify({});
      object['a'] = 1;
      expect(context['Object'].callMethod('keys', [object])['length'], 1);
      expect(context['Object'].callMethod('keys', [object])[0], "a");
      object.deleteProperty("a");
      expect(context['Object'].callMethod('keys', [object])['length'], 0);
    });

/* TODO(jacobr): this is another test that is inconsistent with JS semantics.
    test('deleteProperty throws if name is not a String or num', () {
      var object = new JsObject.jsify({});
      expect(() => object.deleteProperty(true),
          throwsArgumentError);
    });
  */

    test('hasProperty', () {
      var object = new JsObject.jsify({});
      object['a'] = 1;
      expect(object.hasProperty('a'), isTrue);
      expect(object.hasProperty('b'), isFalse);
    });

/* TODO(jacobr): is this really the correct unchecked mode behavior?
    test('hasProperty throws if name is not a String or num', () {
      var object = new JsObject.jsify({});
      expect(() => object.hasProperty(true),
          throwsArgumentError);
    });
*/

    test('[] and []=', () {
      final myArray = context['myArray'];
      expect(myArray['length'], equals(1));
      expect(myArray[0], equals("value1"));
      myArray[0] = "value2";
      expect(myArray['length'], equals(1));
      expect(myArray[0], equals("value2"));

      final foo = new JsObject(context['Foo'], [1]);
      foo["getAge"] = () => 10;
      expect(foo.callMethod('getAge'), equals(10));
    });

/* TODO(jacobr): remove as we should only throw this in checked mode.
    test('[] and []= throw if name is not a String or num', () {
      var object = new JsObject.jsify({});
      expect(() => object[true],
          throwsArgumentError);
      expect(() => object[true] = 1,
          throwsArgumentError);
    });
*/
  });

  group('transferrables', () {
    group('JS->Dart', () {
      test('DateTime', () {
        var date = context.callMethod('getNewDate');
        expect(date is DateTime, isTrue);
      });

      test('window', () {
        expect(context['window'] is Window, isTrue);
      });

      test('foreign browser objects should be proxied', () {
        var iframe = new IFrameElement();
        document.body.children.add(iframe);
        var proxy = new JsObject.fromBrowserObject(iframe);

        // Window
        var contentWindow = proxy['contentWindow'];
        expect(contentWindow is! Window, isTrue);
        expect(contentWindow is JsObject, isTrue);

        // Node
        var foreignDoc = contentWindow['document'];
        expect(foreignDoc is! Node, isTrue);
        expect(foreignDoc is JsObject, isTrue);

        // Event
        var clicked = false;
        foreignDoc['onclick'] = (e) {
          expect(e is! Event, isTrue);
          expect(e is JsObject, isTrue);
          clicked = true;
        };

        context.callMethod('fireClickEvent', [contentWindow]);
        expect(clicked, isTrue);
      });

      test('foreign functions pass function is checks', () {
        var iframe = new IFrameElement();
        document.body.children.add(iframe);
        var proxy = new JsObject.fromBrowserObject(iframe);

        var contentWindow = proxy['contentWindow'];
        var foreignDoc = contentWindow['document'];

        // Function
        var foreignFunction = foreignDoc['createElement'];
        expect(foreignFunction is JsFunction, isTrue);

        // Verify that internal isChecks in callMethod work.
        foreignDoc.callMethod('createElement', ['div']);

        var typedContentWindow = js_util.getProperty(iframe, 'contentWindow');
        var typedForeignDoc =
            js_util.getProperty(typedContentWindow, 'document');

        var typedForeignFunction =
            js_util.getProperty(typedForeignDoc, 'createElement');
        expect(typedForeignFunction is Function, isTrue);
        js_util.callMethod(typedForeignDoc, 'createElement', ['div']);
      });

      test('document', () {
        expect(context['document'] is Document, isTrue);
      });

      skipIE9_test('Blob', () {
        var blob = context.callMethod('getNewBlob');
        expect(blob is Blob, isTrue);
        expect(blob.type, equals('text/html'));
      });

      test('unattached DivElement', () {
        var node = context.callMethod('getNewDivElement');
        expect(node is DivElement, isTrue);
      });

      test('Event', () {
        var event = context.callMethod('getNewEvent');
        expect(event is Event, true);
      });

      test('KeyRange', () {
        if (IdbFactory.supported) {
          var node = context.callMethod('getNewIDBKeyRange');
          expect(node is KeyRange, isTrue);
        }
      });

      test('ImageData', () {
        var node = context.callMethod('getNewImageData');
        expect(node is ImageData, isTrue);
      });

      test('typed data: Int32Array', () {
        if (Platform.supportsTypedData) {
          var list = context.callMethod('getNewInt32Array');
          print(list);
          expect(list is Int32List, isTrue);
          expect(list, equals([1, 2, 3, 4, 5, 6, 7, 8]));
        }
      });
    });

    group('Dart->JS', () {
      test('Date', () {
        context['o'] = new DateTime(1995, 12, 17);
        var dateType = context['Date'];
        expect(context.callMethod('isPropertyInstanceOf', ['o', dateType]),
            isTrue);
        context.deleteProperty('o');
      });

      skipIE9_test('window', () {
        context['o'] = window;
        var windowType = context['Window'];
        expect(context.callMethod('isPropertyInstanceOf', ['o', windowType]),
            isTrue);
        context.deleteProperty('o');
      });

      skipIE9_test('document', () {
        context['o'] = document;
        var documentType = context['Document'];
        expect(context.callMethod('isPropertyInstanceOf', ['o', documentType]),
            isTrue);
        context.deleteProperty('o');
      });

      skipIE9_test('Blob', () {
        var fileParts = ['<a id="a"><b id="b">hey!</b></a>'];
        context['o'] = new Blob(fileParts, 'text/html');
        var blobType = context['Blob'];
        expect(context.callMethod('isPropertyInstanceOf', ['o', blobType]),
            isTrue);
        context.deleteProperty('o');
      });

      test('unattached DivElement', () {
        context['o'] = new DivElement();
        var divType = context['HTMLDivElement'];
        expect(
            context.callMethod('isPropertyInstanceOf', ['o', divType]), isTrue);
        context.deleteProperty('o');
      });

      test('Event', () {
        context['o'] = new CustomEvent('test');
        var eventType = context['Event'];
        expect(context.callMethod('isPropertyInstanceOf', ['o', eventType]),
            isTrue);
        context.deleteProperty('o');
      });

      test('KeyRange', () {
        if (IdbFactory.supported) {
          context['o'] = new KeyRange.only(1);
          var keyRangeType = context['IDBKeyRange'];
          expect(
              context.callMethod('isPropertyInstanceOf', ['o', keyRangeType]),
              isTrue);
          context.deleteProperty('o');
        }
      });

      // this test fails in IE9 for very weird, but unknown, reasons
      // the expression context['ImageData'] fails if useHtmlConfiguration()
      // is called, or if the other tests in this file are enabled
      skipIE9_test('ImageData', () {
        var canvas = new CanvasElement();
        var ctx = canvas.getContext('2d') as CanvasRenderingContext2D;
        context['o'] = ctx.createImageData(1, 1);
        var imageDataType = context['ImageData'];
        expect(context.callMethod('isPropertyInstanceOf', ['o', imageDataType]),
            isTrue);
        context.deleteProperty('o');
      });

      test('typed data: Int32List', () {
        if (Platform.supportsTypedData) {
          context['o'] = new Int32List.fromList([1, 2, 3, 4]);
          var listType = context['Int32Array'];
          // TODO(jacobr): make this test pass. Currently some type information
          // is lost when typed arrays are passed between JS and Dart.
          // expect(context.callMethod('isPropertyInstanceOf', ['o', listType]),
          //    isTrue);
          context.deleteProperty('o');
        }
      });
    });
  });
}
