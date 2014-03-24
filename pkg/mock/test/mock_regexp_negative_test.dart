// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library mock.mock_regexp_negative_test;

import 'package:unittest/unittest.dart' show test;
import 'package:matcher/matcher.dart';
import 'package:mock/mock.dart';

void main() {
  test('Mocking: RegExp CallMatcher bad', () {
    var m = new Mock();
    m.when(callsTo(matches('^[A-Z]'))).
           alwaysThrow('Method names must start with lower case.');
    m.Test();
  });
}
