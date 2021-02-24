// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests the jsify functionality of the js_util library.

@JS()
library js_util_jsify_test;

import 'package:js/js.dart';
import 'package:js/js_util.dart' as js_util;
import 'package:expect/minitest.dart';

@JS()
external void eval(String code);

@JS()
external bool checkMap(m, String, value);

@JS()
class Foo {
  external Foo(num a);

  external num get a;
  external num bar();
}

main() {
  eval(r"""
    function Foo(a) {
      this.a = a;
    }

    Foo.prototype.bar = function() {
      return this.a;
    }

    function checkMap(m, key, value) {
      if (m.hasOwnProperty(key))
        return m[key] == value;
      else
        return false;
    }
    """);

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
    expect(jsMap is List, isFalse);
    expect(jsMap is Map, isFalse);
    for (var key in map.keys) {
      expect(checkMap(jsMap, key, map[key]), isTrue);
    }
  });

  test('deep convert a complex object', () {
    dynamic object = {
      'a': [
        1,
        [2, 3]
      ],
      'b': {'c': 3, 'd': new Foo(42)},
      'e': null
    };
    var jsObject = js_util.jsify(object);
    expect(js_util.getProperty(jsObject, 'a')[0], equals(object['a'][0]));
    expect(js_util.getProperty(jsObject, 'a')[1][0], equals(object['a'][1][0]));
    expect(js_util.getProperty(jsObject, 'a')[1][1], equals(object['a'][1][1]));

    var b = js_util.getProperty(jsObject, 'b');
    expect(js_util.getProperty(b, 'c'), equals(object['b']['c']));
    var d = js_util.getProperty(b, 'd');
    expect(d, equals(object['b']['d']));
    expect(js_util.getProperty(d, 'a'), equals(42));
    expect(js_util.callMethod(d, 'bar', []), equals(42));

    expect(js_util.getProperty(jsObject, 'e'), isNull);
  });

  test('throws if object is not a Map or Iterable', () {
    expect(() => js_util.jsify('a'), throwsArgumentError);
  });
}
