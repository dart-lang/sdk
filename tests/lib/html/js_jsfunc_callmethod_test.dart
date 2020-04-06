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
}
