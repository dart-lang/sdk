// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library unittest.skipped_soloed_nested_test;

import 'package:unittest/unittest.dart';

import 'package:metatest/metatest.dart';

void main() => initTests(_test);

void _test(message) {
  initMetatest(message);

  expectTestResults('skipped/soloed nested groups with setup/teardown', () {
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
  }, [{
    'description': 'non-solo group solo_test in non-solo group',
    'result': 'pass',
  }, {
    'description': 'solo group solo group non-solo test',
    'result': 'pass',
  }, {
    'description': 'solo group solo group solo test',
    'result': 'pass',
  }, {
    'description': 'solo group nested non-solo group in solo group '
        'nested non-solo group non-solo test',
    'result': 'pass',
  }, {
    'description': 'solo group nested non-solo group in solo group '
        'nested non-solo group solo test',
    'result': 'pass',
  }, {
    'description': 'final',
    'result': 'pass',
  }]);
}
