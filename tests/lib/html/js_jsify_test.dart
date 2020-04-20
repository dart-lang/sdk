// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'dart:indexed_db' show IdbFactory, KeyRange;
import 'dart:typed_data' show Int32List;
import 'dart:js';

import 'package:js/js_util.dart' as js_util;
import 'package:expect/minitest.dart';

import 'js_test_util.dart';

main() {
  injectJs();

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
}
