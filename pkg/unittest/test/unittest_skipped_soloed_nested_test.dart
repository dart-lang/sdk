// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library unittestTest;
import 'dart:isolate';
import 'dart:async';
import 'package:unittest/unittest.dart';

part 'unittest_test_utils.dart';

var testName = 'skipped/soloed nested groups with setup/teardown';

var testFunction = (_) {
  StringBuffer s = null;
  setUp(() {
    if (s == null) s = new StringBuffer();
  });
  test('top level', () {
    s.write('A');
  });
  skip_test('skipped top level', () {
    s.write('B');
  });
  skip_group('skipped top level group', () {
    setUp(() {
      s.write('C');
    });
    solo_test('skipped solo nested test', () {
      s.write('D');
    });
  });
  group('non-solo group', () {
    setUp(() {
      s.write('E');
    });
    test('in non-solo group', () {
      s.write('F');
    });
    solo_test('solo_test in non-solo group', () {
      s.write('G');
    });
  });
  solo_group('solo group', () {
    setUp(() {
      s.write('H');
    });
    test('solo group non-solo test', () {
      s.write('I');
    });
    solo_test('solo group solo test', () {
      s.write('J');
    });
    group('nested non-solo group in solo group', () {
      test('nested non-solo group non-solo test', () {
        s.write('K');
      });
      solo_test('nested non-solo group solo test', () {
        s.write('L');
      });
    });
  });
  solo_test('final', () {
    expect(s.toString(), "EGHIHJHKHL");
  });
};

var expected =  buildStatusString(6, 0, 0,
    'non-solo group solo_test in non-solo group::'
    'solo group solo group non-solo test::'
    'solo group solo group solo test::'
    'solo group nested non-solo group in solo group nested non-'
    'solo group non-solo test::'
    'solo group nested non-solo group in solo'
    ' group nested non-solo group solo test::'
    'final');
