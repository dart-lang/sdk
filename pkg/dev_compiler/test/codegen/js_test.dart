// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library jsTest;

import 'dart:js';

// TODO(jmesserly): get tests from package(s) instead.
import 'dom.dart';
import 'minitest.dart';

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
  group('identity', () {

    test('context instances should be identical', () {
      var c1 = context;
      var c2 = context;
      expect(identical(c1, c2), true);
    });

    // TODO(jacobr): switch from equals to identical when dartium supports
    // maintaining proxy equality.
    test('identical JS functions should have equal proxies', () {
      var f1 = context['Object'];
      var f2 = context['Object'];
      expect(f1, equals(f2));
    });

    // TODO(justinfagnani): old tests duplicate checks above, remove
    // on test next cleanup pass
    test('test proxy equality', () {
      var foo1 = new JsObject(context['Foo'], [1]);
      var foo2 = new JsObject(context['Foo'], [2]);
      context['foo1'] = foo1;
      context['foo2'] = foo2;
      expect(foo1, isNot(context['foo2']));
      expect(foo2, context['foo2']);
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
        expect(proto['role'], 'proto');
        final obj = context['someObject'];
        expect(obj['role'], 'object');
      });
    });

  });

  group('context', () {

    test('read global field', () {
      expect(context['x'], 42);
      expect(context['y'], null);
    });

    test('read global field with underscore', () {
      expect(context['_x'], 123);
      expect(context['y'], null);
    });

    test('write global field', () {
      context['y'] = 42;
      expect(context['y'], 42);
    });

  });

  group('new JsObject()', () {

    test('new Foo()', () {
      var foo = new JsObject(context['Foo'], [42]);
      expect(foo['a'], 42);
      expect(foo.callMethod('bar'), 42);
      expect(() => foo.callMethod('baz'), throwsA(isNoSuchMethodError));
    });

    test('new container.Foo()', () {
      final Foo2 = context['container']['Foo'];
      final foo = new JsObject(Foo2, [42]);
      expect(foo['a'], 42);
      expect(Foo2['b'], 38);
    });

    test('new Array()', () {
      var a = new JsObject(context['Array']);
      expect(a, (a) => a is JsArray);

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
      expect(a.callMethod('getTime'), 12345678);
    });

    test('new Date("December 17, 1995 03:24:00 GMT")', () {
      final a = new JsObject(context['Date'],
          ["December 17, 1995 03:24:00 GMT"]);
      expect(a.callMethod('getTime'), 819170640000);
    });

    test('new Date(1995,11,17)', () {
      // Note: JS Date counts months from 0 while Dart counts from 1.
      final a = new JsObject(context['Date'], [1995, 11, 17]);
      final b = new DateTime(1995, 12, 17);
      expect(a.callMethod('getTime'), b.millisecondsSinceEpoch);
    });

    test('new Date(1995,11,17,3,24,0)', () {
      // Note: JS Date counts months from 0 while Dart counts from 1.
      final a = new JsObject(context['Date'],
          [1995, 11, 17, 3, 24, 0]);
      final b = new DateTime(1995, 12, 17, 3, 24, 0);
      expect(a.callMethod('getTime'), b.millisecondsSinceEpoch);
    });

    test('new Object()', () {
      final a = new JsObject(context['Object']);
      expect(a, isNotNull);

      a['attr'] = "value";
      expect(a['attr'], "value");
    });

    test(r'new RegExp("^\w+$")', () {
      final a = new JsObject(context['RegExp'], [r'^\w+$']);
      expect(a, isNotNull);
      expect(a.callMethod('test', ['true']), true);
      expect(a.callMethod('test', [' false']), false);
    });

    test('js instantiation via map notation : new Array()', () {
      final a = new JsObject(context['Array']);
      expect(a, isNotNull);
      expect(a['length'], 0);

      a.callMethod('push', ["value 1"]);
      expect(a['length'], 1);
      expect(a[0], "value 1");

      a.callMethod('pop');
      expect(a['length'], 0);
    });

    test('js instantiation via map notation : new Date()', () {
      final a = new JsObject(context['Date']);
      expect(a.callMethod('getTime'), isNotNull);
    });

    test('>10 parameters', () {
      final o = new JsObject(context['Baz'], [1,2,3,4,5,6,7,8,9,10,11]);
      for (var i = 1; i <= 11; i++) {
        expect(o["f$i"], i);
      }
      expect(o['constructor'], context['Baz']);
    });
  });

  group('JsFunction and callMethod', () {

    test('new JsObject can return a JsFunction', () {
      var f = new JsObject(context['Function']);
      expect(f, (a) => a is JsFunction);
    });

    test('JsFunction.apply on a function defined in JS', () {
      expect(context['razzle'].apply([]), 42);
    });

    test('JsFunction.apply on a function that uses "this"', () {
      var object = new Object();
      expect(context['returnThis'].apply([], thisArg: object), same(object));
    });

    test('JsObject.callMethod on a function defined in JS', () {
      expect(context.callMethod('razzle'), 42);
      expect(() => context.callMethod('dazzle'), throwsA(isNoSuchMethodError));
    });

    test('callMethod with many arguments', () {
      expect(context.callMethod('varArgs', [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]),
        55);
    });

    test('access a property of a function', () {
      expect(context.callMethod('Bar'), "ret_value");
      expect(context['Bar']['foo'], "property_value");
    });

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
      expect(context.callMethod('isPropertyInstanceOf',
          ['a', context['Array']]), true);
      var a = context['a'];
      expect(a, (a) => a is JsArray);
      expect(a, [1, 2, 3]);
      context.deleteProperty('a');
    });

    test('pass Array to JS', () {
      context['a'] = [1, 2, 3];
      expect(context.callMethod('isPropertyInstanceOf',
          ['a', context['Array']]), false);
      var a = context['a'];
      expect(a, (a) => a is List);
      expect(a, isNot((a) => a is JsArray));
      expect(a, [1, 2, 3]);
      context.deleteProperty('a');
    });

    test('[]', () {
      var array = new JsArray.from([1, 2]);
      expect(array[0], 1);
      expect(array[1], 2);
      expect(() => array[-1], throwsA(isRangeError));
      expect(() => array[2], throwsA(isRangeError));
    });

   test('[]=', () {
      var array = new JsArray.from([1, 2]);
      array[0] = 'd';
      array[1] = 'e';
      expect(array, ['d', 'e']);
      expect(() => array[-1] = 3, throwsA(isRangeError));
      expect(() => array[2] = 3, throwsA(isRangeError));
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
      expect(() => array.insert(4, 'e'), throwsA(isRangeError));
      expect(() => array.insert(-1, 'e'), throwsA(isRangeError));
    });

    test('removeAt', () {
      var array = new JsArray.from(['a', 'b', 'c']);
      expect(array.removeAt(1), 'b');
      expect(array, ['a', 'c']);
      expect(() => array.removeAt(2), throwsA(isRangeError));
      expect(() => array.removeAt(-1), throwsA(isRangeError));
    });

    test('removeLast', () {
      var array = new JsArray.from(['a', 'b', 'c']);
      expect(array.removeLast(), 'c');
      expect(array, ['a', 'b']);
      array.length = 0;
      expect(() => array.removeLast(), throwsA(isRangeError));
    });

    test('removeRange', () {
      var array = new JsArray.from(['a', 'b', 'c', 'd']);
      array.removeRange(1, 3);
      expect(array, ['a', 'd']);
      expect(() => array.removeRange(-1, 2), throwsA(isRangeError));
      expect(() => array.removeRange(0, 3), throwsA(isRangeError));
      expect(() => array.removeRange(2, 1), throwsA(isRangeError));
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
      var node = new JsObject.fromBrowserObject(document.createElement('div'));
      context.callMethod('addTestProperty', [node]);
      expect(node is JsObject, true);
      expect(node.instanceof(context['HTMLDivElement']), true);
      expect(node['testProperty'], 'test');
    });

    test('primitives and null throw ArgumentError', () {
      for (var v in ['a', 1, 2.0, true, null]) {
        expect(() => new JsObject.fromBrowserObject(v),
            throwsA((a) => a is ArgumentError));
      }
    });

  });

  group('Dart functions', () {
    test('invoke Dart callback from JS', () {
      expect(() => context.callMethod('invokeCallback'), throws);

      context['callback'] = () => 42;
      expect(context.callMethod('invokeCallback'), 42);

      context.deleteProperty('callback');
    });

    test('callback as parameter', () {
      expect(context.callMethod('getTypeOf', [context['razzle']]),
          "function");
    });

    test('invoke Dart callback from JS with this', () {
      // A JavaScript constructor implemented in Dart using 'this'
      final constructor = new JsFunction.withThis(($this, arg1) {
        $this['a'] = 42;
      });
      var o = new JsObject(constructor, ["b"]);
      expect(o['a'], 42);
    });

    test('invoke Dart callback from JS with 11 parameters', () {
      context['callbackWith11params'] = (p1, p2, p3, p4, p5, p6, p7,
          p8, p9, p10, p11) => '$p1$p2$p3$p4$p5$p6$p7$p8$p9$p10$p11';
      expect(context.callMethod('invokeCallbackWith11params'),
          '1234567891011');
    });

    test('return a JS proxy to JavaScript', () {
      var result = context.callMethod('testJsMap',
          [() => new JsObject.jsify({'value': 42})]);
      expect(result, 42);
    });

    test('emulated functions should be callable in JS', () {
      context['callable'] = new Callable();
      var result = context.callMethod('callable');
      expect(result, 'called');
      context.deleteProperty('callable');
    }, skip: "https://github.com/dart-lang/dev_compiler/issues/244");

  });

  group('JsObject.jsify()', () {

    test('convert a List', () {
      final list = [1, 2, 3, 4, 5, 6, 7, 8];
      var array = new JsObject.jsify(list);
      expect(context.callMethod('isArray', [array]), true);
      expect(array['length'], list.length);
      for (var i = 0; i < list.length ; i++) {
        expect(array[i], list[i]);
      }
    });

    test('convert an Iterable', () {
      final set = new Set.from([1, 2, 3, 4, 5, 6, 7, 8]);
      var array = new JsObject.jsify(set);
      expect(context.callMethod('isArray', [array]), true);
      expect(array['length'], set.length);
      for (var i = 0; i < array['length'] ; i++) {
        expect(set.contains(array[i]), true);
      }
    });

    test('convert a Map', () {
      var map = {'a': 1, 'b': 2, 'c': 3};
      var jsMap = new JsObject.jsify(map);
      expect(!context.callMethod('isArray', [jsMap]), true);
      for (final key in map.keys) {
        expect(context.callMethod('checkMap', [jsMap, key, map[key]]), true);
      }
    });

    test('deep convert a complex object', () {
      final object = {
        'a': [1, [2, 3]],
        'b': {
          'c': 3,
          'd': new JsObject(context['Foo'], [42])
        },
        'e': null
      };
      var jsObject = new JsObject.jsify(object);
      expect(jsObject['a'][0], object['a'][0]);
      expect(jsObject['a'][1][0], object['a'][1][0]);
      expect(jsObject['a'][1][1], object['a'][1][1]);
      expect(jsObject['b']['c'], object['b']['c']);
      expect(jsObject['b']['d'], object['b']['d']);
      expect(jsObject['b']['d'].callMethod('bar'), 42);
      expect(jsObject['e'], null);
    });

    test('throws if object is not a Map or Iterable', () {
      expect(() => new JsObject.jsify('a'),
          throwsA((a) => a is ArgumentError));
    });
  });

  group('JsObject methods', () {

    test('hashCode and ==', () {
      final o1 = context['Object'];
      final o2 = context['Object'];
      expect(o1 == o2, true);
      expect(o1.hashCode == o2.hashCode, true);
      final d = context['document'];
      expect(o1 == d, false);
    });

    test('toString', () {
      var foo = new JsObject(context['Foo'], [42]);
      expect(foo.toString(), "I'm a Foo a=42");
      var container = context['container'];
      expect(container.toString(), "[object Object]");
    });

    test('toString returns a String even if the JS object does not', () {
      var foo = new JsObject(context['Liar']);
      expect(foo.callMethod('toString'), 1);
      expect(foo.toString(), '1');
    });

    test('instanceof', () {
      var foo = new JsObject(context['Foo'], [1]);
      expect(foo.instanceof(context['Foo']), true);
      expect(foo.instanceof(context['Object']), true);
      expect(foo.instanceof(context['String']), false);
    });

    test('deleteProperty', () {
      var object = new JsObject.jsify({});
      object['a'] = 1;
      expect(context['Object'].callMethod('keys', [object])['length'], 1);
      expect(context['Object'].callMethod('keys', [object])[0], "a");
      object.deleteProperty("a");
      expect(context['Object'].callMethod('keys', [object])['length'], 0);
    });

    test('hasProperty', () {
      var object = new JsObject.jsify({});
      object['a'] = 1;
      expect(object.hasProperty('a'), true);
      expect(object.hasProperty('b'), false);
    });

    test('[] and []=', () {
      final myArray = context['myArray'];
      expect(myArray['length'], 1);
      expect(myArray[0], "value1");
      myArray[0] = "value2";
      expect(myArray['length'], 1);
      expect(myArray[0], "value2");

      final foo = new JsObject(context['Foo'], [1]);
      foo["getAge"] = () => 10;
      expect(foo.callMethod('getAge'), 10);
    });

  });

  group('transferrables', () {

    group('JS->Dart', () {

      test('DateTime', () {
        var date = context.callMethod('getNewDate');
        expect(date is DateTime, true);
      });

      test('window', () {
        expect(context['window'] is Window, true);
      });

      test('foreign browser objects should be proxied', () {
        var iframe = document.createElement('iframe');
        document.body.appendChild(iframe);
        var proxy = new JsObject.fromBrowserObject(iframe);

        // Window
        var contentWindow = proxy['contentWindow'];
        expect(contentWindow, isNot((a) => a is Window));
        expect(contentWindow, (a) => a is JsObject);

        // Node
        var foreignDoc = contentWindow['document'];
        expect(foreignDoc, isNot((a) => a is Node));
        expect(foreignDoc, (a) => a is JsObject);

        // Event
        var clicked = false;
        foreignDoc['onclick'] = (e) {
          expect(e, isNot((a) => a is Event));
          expect(e, (a) => a is JsObject);
          clicked = true;
        };

        context.callMethod('fireClickEvent', [contentWindow]);
        expect(clicked, true);
      });

      test('document', () {
        expect(context['document'] is Document, true);
      });

      test('Blob', () {
        var blob = context.callMethod('getNewBlob');
        expect(blob is Blob, true);
        expect(blob.type, 'text/html');
      });

      test('unattached DivElement', () {
        var node = context.callMethod('getNewDivElement');
        expect(node is DivElement, true);
      });

      test('Event', () {
        var event = context.callMethod('getNewEvent');
        expect(event is Event, true);
      });

      test('ImageData', () {
        var node = context.callMethod('getNewImageData');
        expect(node is ImageData, true);
      });

    });

    group('Dart->JS', () {

      test('Date', () {
        context['o'] = new DateTime(1995, 12, 17);
        var dateType = context['Date'];
        expect(context.callMethod('isPropertyInstanceOf', ['o', dateType]),
            true);
        context.deleteProperty('o');
      });

      test('window', () {
        context['o'] = window;
        var windowType = context['Window'];
        expect(context.callMethod('isPropertyInstanceOf', ['o', windowType]),
            true);
        context.deleteProperty('o');
      });

      test('document', () {
        context['o'] = document;
        var documentType = context['Document'];
        expect(context.callMethod('isPropertyInstanceOf', ['o', documentType]),
            true);
        context.deleteProperty('o');
      });

      test('Blob', () {
        var fileParts = ['<a id="a"><b id="b">hey!</b></a>'];
        context['o'] = new Blob(fileParts, type: 'text/html');
        var blobType = context['Blob'];
        expect(context.callMethod('isPropertyInstanceOf', ['o', blobType]),
            true);
        context.deleteProperty('o');
      });

      test('unattached DivElement', () {
        context['o'] = document.createElement('div');
        var divType = context['HTMLDivElement'];
        expect(context.callMethod('isPropertyInstanceOf', ['o', divType]),
            true);
        context.deleteProperty('o');
      });

      test('Event', () {
        context['o'] = new CustomEvent('test');
        var eventType = context['Event'];
        expect(context.callMethod('isPropertyInstanceOf', ['o', eventType]),
            true);
        context.deleteProperty('o');
      });

      // this test fails in IE9 for very weird, but unknown, reasons
      // the expression context['ImageData'] fails if useHtmlConfiguration()
      // is called, or if the other tests in this file are enabled
      test('ImageData', () {
        CanvasElement canvas = document.createElement('canvas');
        var ctx = canvas.getContext('2d') as CanvasRenderingContext2D;
        context['o'] = ctx.createImageData(1, 1);
        var imageDataType = context['ImageData'];
        expect(context.callMethod('isPropertyInstanceOf', ['o', imageDataType]),
            true);
        context.deleteProperty('o');
      });

    });
  });
}
