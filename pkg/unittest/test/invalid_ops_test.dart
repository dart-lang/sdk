// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library unittest.invalid_ops_test;

import 'package:unittest/unittest.dart';

import 'package:metatest/metatest.dart';

void main() => initTests(_test);

void _test(message) {
  initMetatest(message);

  expectTestsPass('testcases immutable', () {
    test('test', () {
      expect(() => test('test', () {}), throwsStateError);
      expect(() => solo_test('test', () {}), throwsStateError);
      expect(() => group('test', () {}), throwsStateError);
      expect(() => solo_group('test', () {}), throwsStateError);
      expect(() => setUp(() {}), throwsStateError);
      expect(() => tearDown(() {}), throwsStateError);
      expect(() => runTests(), throwsStateError);
    });
  });
}
