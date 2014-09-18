// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library unittest.nested_groups_setup_teardown_test;

import 'dart:async';

import 'package:unittest/unittest.dart';

import 'package:metatest/metatest.dart';

void main() => initTests(_test);

void _test(message) {
  initMetatest(message);

  expectTestsPass('nested groups setup/teardown', () {
    StringBuffer s = new StringBuffer();
    group('level 1', () {
      setUp(makeDelayedSetup(1, s));
      group('level 2', () {
        setUp(makeImmediateSetup(2, s));
        tearDown(makeDelayedTeardown(2, s));
        group('level 3', () {
          group('level 4', () {
            setUp(makeDelayedSetup(4, s));
            tearDown(makeImmediateTeardown(4, s));
            group('level 5', () {
              setUp(makeImmediateSetup(5, s));
              group('level 6', () {
                tearDown(makeDelayedTeardown(6, s));
                test('inner', () {});
              });
            });
          });
        });
      });
    });
    test('after nest', () {
      expect(s.toString(), "l1 U l2 U l4 U l5 U l6 D l4 D l2 D ");
    });
  });
}


Function makeDelayedSetup(int index, StringBuffer s) => () {
  return new Future.delayed(new Duration(milliseconds: 1), () {
    s.write('l$index U ');
  });
};

Function makeDelayedTeardown(int index, StringBuffer s) => () {
  return new Future.delayed(new Duration(milliseconds: 1), () {
    s.write('l$index D ');
  });
};

Function makeImmediateSetup(int index, StringBuffer s) => () {
  s.write('l$index U ');
};

Function makeImmediateTeardown(int index, StringBuffer s) => () {
  s.write('l$index D ');
};
