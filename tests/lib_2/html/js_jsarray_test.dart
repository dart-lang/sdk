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
    expect(context.callMethod('isPropertyInstanceOf', ['a', context['Array']]),
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
}
