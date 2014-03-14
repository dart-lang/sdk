// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library unittestTest;
import 'dart:isolate';
import 'dart:async';
import 'package:unittest/unittest.dart';

part 'unittest_test_utils.dart';

var testName = 'late exception test';

var testFunction = (_) {
  var f;
  test('testOne', () {
    f = expectAsync(() {});
    _defer(f);
  });
  test('testTwo', () {
    _defer(expectAsync(() { f(); }));
  });
};

var expected = buildStatusString(1, 0, 1, 'testOne',
    message: 'Callback called (2) after test case testOne has already '
        'been marked as pass.:testTwo:');
