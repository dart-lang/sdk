// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests the dartify functionality of the js_util library.

@JS()
library js_util_jsify_test;

import 'package:js/js.dart';
import 'package:js/js_util.dart' as js_util;
import 'package:expect/expect.dart';
import 'package:expect/minitest.dart'; // ignore: deprecated_member_use_from_same_package

@JS()
external void eval(String code);

main() {
  eval(r"""
    globalThis.arrayData = [1, 2, false, 4, 'hello', 6, [1, 2], {'foo': 'bar'}, null];
    globalThis.recArrayData = [];
    globalThis.recArrayData = [globalThis.recArrayData];
    globalThis.objectData = {
      'a': 1,
      'b': [1, 2, 3],
      'c': {
        'a': true,
        'b': 'foo',
        'c': null,
      },
    };
    globalThis.recObjectData = {};
    globalThis.recObjectData = {'foo': globalThis.recObjectData}
    globalThis.throwData = new RegExp();
    globalThis.complexData = {
      'a': new Date(0),
      'b': new Promise((resolve, reject) => {}),
    };
    globalThis.complexList = [
      new Date(0),
      new Promise((resolve, reject) => {}),
    ];
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
      {'foo': 'bar'},
      null
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
        'c': null,
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

  test('complex types convert in an Object', () {
    Object? jsObject = js_util.getProperty(js_util.globalThis, 'complexData');
    Map<Object?, Object?> dartObject =
        js_util.dartify(jsObject) as Map<Object?, Object?>;
    Expect.isTrue(dartObject['a']! is DateTime);
    Expect.isTrue(dartObject['b']! is Future);
  });

  test('complex types convert in a List', () {
    Object? jsArray = js_util.getProperty(js_util.globalThis, 'complexList');
    List<Object?> dartList = js_util.dartify(jsArray) as List<Object?>;
    Expect.isTrue(dartList[0] is DateTime);
    Expect.isTrue(dartList[1] is Future);
  });

  test('throws if object is a regexp', () {
    expect(
        () => js_util
            .dartify(js_util.getProperty(js_util.globalThis, 'throwData')),
        throwsArgumentError);
  });
}
