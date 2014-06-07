// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library matcher.deprecated_matchers_test;

import 'package:matcher/matcher.dart';
import 'package:unittest/unittest.dart' show test, group;

import 'test_utils.dart';

void main() {
  initUtils();

  test('throwsAbstractClassInstantiationError', () {
    expect(() => new _AbstractClass(), throwsAbstractClassInstantiationError);
  });

  test('throwsFallThroughError', () {
    expect(() {
      var a = 0;
      switch (a) {
        case 0:
          a += 1;
        case 1:
          return;
      }
    }, throwsFallThroughError);
  });
}

abstract class _AbstractClass {
}
