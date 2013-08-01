// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';

import 'package:unittest/unittest.dart';
import 'package:unittest/mirror_matchers.dart';

import 'test_common.dart';
import 'test_utils.dart';

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
  });
}