// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests the dartify functionality of the js_util library.

@JS()
library js_util_jsify_test;

import 'package:js/js.dart';
import 'package:js/js_util.dart' as js_util;
import 'package:expect/expect.dart';
import 'package:expect/minitest.dart';

@JS()
external void eval(String code);

main() {
  eval(r"""
    globalThis.arrayData = [1, 2, false, 4, 'hello', 6, [1, 2], {'foo': 'bar'}];
    globalThis.recArrayData = [];
    globalThis.recArrayData = [globalThis.recArrayData];
    globalThis.objectData = {
      'a': 1,
      'b': [1, 2, 3],
      'c': {
        'a': true,
        'b': 'foo',
      },
    };
    globalThis.recObjectData = {};
    globalThis.recObjectData = {'foo': globalThis.recObjectData}
    globalThis.throwData = function() {};
    """);

  test('convert an array', () {
    Object? jsArray = js_util.getProperty(js_util.globalThis, 'arrayData');
    Object? dartArray = js_util.dartify(jsArray);
    List<Object?> expectedValues = [
      1,
      2,
      false,
      4,
      'hello',
      6,
      [1, 2],
      {'foo': 'bar'}
    ];
    Expect.deepEquals(expectedValues, dartArray);
  });

  test('convert a recursive array', () {
    Object? jsArray = js_util.getProperty(js_util.globalThis, 'recArrayData');
    Object? dartArray = js_util.dartify(jsArray);
    List<Object?> expectedValues = [[]];
    Expect.deepEquals(expectedValues, dartArray);
  });

  test('convert an object literal', () {
    Object? jsObject = js_util.getProperty(js_util.globalThis, 'objectData');
    Object? dartObject = js_util.dartify(jsObject);
    Map<Object?, Object?> expectedValues = {
      'a': 1,
      'b': [1, 2, 3],
      'c': {
        'a': true,
        'b': 'foo',
      },
    };
    Expect.deepEquals(expectedValues, dartObject);
  });

  test('convert a recursive object literal', () {
    Object? jsObject = js_util.getProperty(js_util.globalThis, 'recObjectData');
    Object? dartObject = js_util.dartify(jsObject);
    Map<Object?, Object?> expectedValues = {
      'foo': {},
    };
    Expect.deepEquals(expectedValues, dartObject);
  });

  test('throws if object is not an object literal or array', () {
    expect(
        () => js_util
            .dartify(js_util.getProperty(js_util.globalThis, 'throwData')),
        throwsArgumentError);
  });
}
