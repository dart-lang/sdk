// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library matcher.mirror_test;

import 'package:matcher/mirror_matchers.dart';
import 'package:unittest/unittest.dart' show test;

import 'test_utils.dart';

class C {
  var instanceField = 1;
  get instanceGetter => 2;
  static var staticField = 3;
  static get staticGetter => 4;
}

void main() {

  initUtils();

  test('hasProperty', () {
    var foo = [3];
    shouldPass(foo, hasProperty('length', 1));
    shouldFail(foo, hasProperty('foo'), 'Expected: has property "foo" '
        'Actual: [3] '
        'Which: has no property named "foo"');
    shouldFail(foo, hasProperty('length', 2),
        'Expected: has property "length" which matches <2> '
        'Actual: [3] '
        'Which: has property "length" with value <1>');
    var c = new C();
    shouldPass(c, hasProperty('instanceField', 1));
    shouldPass(c, hasProperty('instanceGetter', 2));
    shouldFail(c, hasProperty('staticField'),
        'Expected: has property "staticField" '
        'Actual: <Instance of \'C\'> '
        'Which: has a member named "staticField",'
        ' but it is not an instance property');
    shouldFail(c, hasProperty('staticGetter'),
        'Expected: has property "staticGetter" '
        'Actual: <Instance of \'C\'> '
        'Which: has a member named "staticGetter",'
        ' but it is not an instance property');
  });
}
