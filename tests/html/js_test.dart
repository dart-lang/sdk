// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library jsTest;

import 'dart:async';
import 'dart:html';
import 'dart:js';

import '../../pkg/unittest/lib/unittest.dart';
import '../../pkg/unittest/lib/html_config.dart';

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
  for (var i=0; i<list.length; i++) {
    result += list[i].getAttribute("class");
  }
  return result;
}

function getNewDivElement() {
  return document.createElement("div");
}

function testJsMap(callback) {
  var result = callback();
  return result['value'];
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
""";
  document.body.append(script);
}

class Foo implements Serializable<JsObject> {
  final JsObject _proxy;

  Foo(num a) : this._proxy = new JsObject(context['Foo'], [a]);

  JsObject toJs() => _proxy;

  num get a => _proxy['a'];
  num bar() => _proxy.callMethod('bar');
}

class Color implements Serializable<String> {
  static final RED = new Color._("red");
  static final BLUE = new Color._("blue");
  String _value;
  Color._(this._value);
  String toJs() => this._value;
}

main() {
  _injectJs();
  useHtmlConfiguration();

  test('read global field', () {
    expect(context['x'], equals(42));
    expect(context['y'], isNull);
  });

  test('read global field with underscore', () {
    expect(context['_x'], equals(123));
    expect(context['y'], isNull);
  });

  test('hashCode and operator==(other)', () {
    final o1 = context['Object'];
    final o2 = context['Object'];
    expect(o1 == o2, isTrue);
    expect(o1.hashCode == o2.hashCode, isTrue);
    final d = context['document'];
    expect(o1 == d, isFalse);
  });

  test('js instantiation : new Foo()', () {
    final Foo2 = context['container']['Foo'];
    final foo = new JsObject(Foo2, [42]);
    expect(foo['a'], 42);
    expect(Foo2['b'], 38);
  });

  test('js instantiation : new Array()', () {
    final a = new JsObject(context['Array']);
    expect(a, isNotNull);
    expect(a['length'], equals(0));

    a.callMethod('push', ["value 1"]);
    expect(a['length'], equals(1));
    expect(a[0], equals("value 1"));

    a.callMethod('pop');
    expect(a['length'], equals(0));
  });

  test('js instantiation : new Date()', () {
    final a = new JsObject(context['Date']);
    expect(a.callMethod('getTime'), isNotNull);
  });

  test('js instantiation : new Date(12345678)', () {
    final a = new JsObject(context['Date'], [12345678]);
    expect(a.callMethod('getTime'), equals(12345678));
  });

  test('js instantiation : new Date("December 17, 1995 03:24:00 GMT+01:00")',
      () {
    final a = new JsObject(context['Date'],
                           ["December 17, 1995 03:24:00 GMT+01:00"]);
    expect(a.callMethod('getTime'), equals(819167040000));
  });

  test('js instantiation : new Date(1995,11,17)', () {
    // Note: JS Date counts months from 0 while Dart counts from 1.
    final a = new JsObject(context['Date'], [1995, 11, 17]);
    final b = new DateTime(1995, 12, 17);
    expect(a.callMethod('getTime'), equals(b.millisecondsSinceEpoch));
  });

  test('js instantiation : new Date(1995,11,17,3,24,0)', () {
    // Note: JS Date counts months from 0 while Dart counts from 1.
    final a = new JsObject(context['Date'],
                                       [1995, 11, 17, 3, 24, 0]);
    final b = new DateTime(1995, 12, 17, 3, 24, 0);
    expect(a.callMethod('getTime'), equals(b.millisecondsSinceEpoch));
  });

  test('js instantiation : new Object()', () {
    final a = new JsObject(context['Object']);
    expect(a, isNotNull);

    a['attr'] = "value";
    expect(a['attr'], equals("value"));
  });

  test(r'js instantiation : new RegExp("^\w+$")', () {
    final a = new JsObject(context['RegExp'], [r'^\w+$']);
    expect(a, isNotNull);
    expect(a.callMethod('test', ['true']), isTrue);
    expect(a.callMethod('test', [' false']), isFalse);
  });

  test('js instantiation via map notation : new Array()', () {
    final a = new JsObject(context['Array']);
    expect(a, isNotNull);
    expect(a['length'], equals(0));

    a['push'].apply(a, ["value 1"]);
    expect(a['length'], equals(1));
    expect(a[0], equals("value 1"));

    a['pop'].apply(a);
    expect(a['length'], equals(0));
  });

  test('js instantiation via map notation : new Date()', () {
    final a = new JsObject(context['Date']);
    expect(a['getTime'].apply(a), isNotNull);
  });

  test('js instantiation : typed array', () {
    final codeUnits = "test".codeUnits;
    final buf = new JsObject(context['ArrayBuffer'], [codeUnits.length]);
    final bufView = new JsObject(context['Uint8Array'], [buf]);
    for (var i = 0; i < codeUnits.length; i++) {
      bufView[i] = codeUnits[i];
    }
  });

  test('js instantiation : >10 parameters', () {
    final o = new JsObject(context['Baz'], [1,2,3,4,5,6,7,8,9,10,11]);
    for (var i = 1; i <= 11; i++) {
      o["f$i"] = i;
    }
  });

  test('write global field', () {
    context['y'] = 42;
    expect(context['y'], equals(42));
  });

  test('get JS JsFunction', () {
    var razzle = context['razzle'];
    expect(razzle.apply(context), equals(42));
  });

  test('call JS function', () {
    expect(context.callMethod('razzle'), equals(42));
    expect(() => context.callMethod('dazzle'), throwsA(isNoSuchMethodError));
  });

  test('call JS function via map notation', () {
    expect(context['razzle'].apply(context), equals(42));
    expect(() => context['dazzle'].apply(context),
        throwsA(isNoSuchMethodError));
  });

  test('call JS function with varargs', () {
    expect(context.callMethod('varArgs', [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]),
      equals(55));
  });

  test('allocate JS object', () {
    var foo = new JsObject(context['Foo'], [42]);
    expect(foo['a'], equals(42));
    expect(foo.callMethod('bar'), equals(42));
    expect(() => foo.callMethod('baz'), throwsA(isNoSuchMethodError));
  });

  test('call toString()', () {
    var foo = new JsObject(context['Foo'], [42]);
    expect(foo.toString(), equals("I'm a Foo a=42"));
    var container = context['container'];
    expect(container.toString(), equals("[object Object]"));
  });

  test('allocate simple JS array', () {
    final list = [1, 2, 3, 4, 5, 6, 7, 8];
    var array = jsify(list);
    expect(context.callMethod('isArray', [array]), isTrue);
    expect(array['length'], equals(list.length));
    for (var i = 0; i < list.length ; i++) {
      expect(array[i], equals(list[i]));
    }
  });

  test('allocate JS array with iterable', () {
    final set = new Set.from([1, 2, 3, 4, 5, 6, 7, 8]);
    var array = jsify(set);
    expect(context.callMethod('isArray', [array]), isTrue);
    expect(array['length'], equals(set.length));
    for (var i = 0; i < array['length'] ; i++) {
      expect(set.contains(array[i]), isTrue);
    }
  });

  test('allocate simple JS map', () {
    var map = {'a': 1, 'b': 2, 'c': 3};
    var jsMap = jsify(map);
    expect(!context.callMethod('isArray', [jsMap]), isTrue);
    for (final key in map.keys) {
      expect(context.callMethod('checkMap', [jsMap, key, map[key]]), isTrue);
    }
  });

  test('allocate complex JS object', () {
    final object =
      {
        'a': [1, [2, 3]],
        'b': {
          'c': 3,
          'd': new JsObject(context['Foo'], [42])
        },
        'e': null
      };
    var jsObject = jsify(object);
    expect(jsObject['a'][0], equals(object['a'][0]));
    expect(jsObject['a'][1][0], equals(object['a'][1][0]));
    expect(jsObject['a'][1][1], equals(object['a'][1][1]));
    expect(jsObject['b']['c'], equals(object['b']['c']));
    expect(jsObject['b']['d'], equals(object['b']['d']));
    expect(jsObject['b']['d'].callMethod('bar'), equals(42));
    expect(jsObject['e'], isNull);
  });

  test('invoke Dart callback from JS', () {
    expect(() => context.callMethod('invokeCallback'), throws);

    context['callback'] = new Callback(() => 42);
    expect(context.callMethod('invokeCallback'), equals(42));

    context.deleteProperty('callback');
    expect(() => context.callMethod('invokeCallback'), throws);

    context['callback'] = () => 42;
    expect(context.callMethod('invokeCallback'), equals(42));

    context.deleteProperty('callback');
  });

  test('callback as parameter', () {
    expect(context.callMethod('getTypeOf', [context['razzle']]),
        equals("function"));
  });

  test('invoke Dart callback from JS with this', () {
    final constructor = new Callback.withThis(($this, arg1) {
      $this['a'] = 42;
      $this['b'] = jsify(["a", arg1]);
    });
    var o = new JsObject(constructor, ["b"]);
    expect(o['a'], equals(42));
    expect(o['b'][0], equals("a"));
    expect(o['b'][1], equals("b"));
  });

  test('invoke Dart callback from JS with 11 parameters', () {
    context['callbackWith11params'] = new Callback((p1, p2, p3, p4, p5, p6, p7,
        p8, p9, p10, p11) => '$p1$p2$p3$p4$p5$p6$p7$p8$p9$p10$p11');
    expect(context.callMethod('invokeCallbackWith11params'),
        equals('1234567891011'));
  });

  test('return a JS proxy to JavaScript', () {
    var result = context.callMethod('testJsMap', [() => jsify({'value': 42})]);
    expect(result, 42);
  });

  test('test proxy equality', () {
    var foo1 = new JsObject(context['Foo'], [1]);
    var foo2 = new JsObject(context['Foo'], [2]);
    context['foo'] = foo1;
    context['foo'] = foo2;
    expect(foo1, isNot(equals(context['foo'])));
    expect(foo2, equals(context['foo']));
  });

  test('test instanceof', () {
    var foo = new JsObject(context['Foo'], [1]);
    expect(foo.instanceof(context['Foo']), isTrue);
    expect(foo.instanceof(context['Object']), isTrue);
    expect(foo.instanceof(context['String']), isFalse);
  });

  test('test deleteProperty', () {
    var object = jsify({});
    object['a'] = 1;
    expect(context['Object'].callMethod('keys', [object])['length'], 1);
    expect(context['Object'].callMethod('keys', [object])[0], "a");
    object.deleteProperty("a");
    expect(context['Object'].callMethod('keys', [object])['length'], 0);
  });

  test('test hasProperty', () {
    var object = jsify({});
    object['a'] = 1;
    expect(object.hasProperty('a'), isTrue);
    expect(object.hasProperty('b'), isFalse);
  });

  test('test index get and set', () {
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

  test('access a property of a function', () {
    expect(context.callMethod('Bar'), "ret_value");
    expect(context['Bar']['foo'], "property_value");
  });

  test('retrieve same dart Object', () {
    final date = new DateTime.now();
    context['dartDate'] = date;
    expect(context['dartDate'], equals(date));
  });

  test('usage of Serializable', () {
    final red = Color.RED;
    context['color'] = red;
    expect(context['color'], equals(red._value));
  });
}
