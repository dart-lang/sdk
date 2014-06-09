// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library unittestTest;

import 'dart:async';
import 'dart:isolate';

import 'package:unittest/unittest.dart';

part 'utils.dart';

var testName = 'nested groups setup/teardown';

var testFunction = (_) {
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
};

var expected = buildStatusString(2, 0, 0,
    'level 1 level 2 level 3 level 4 level 5 level 6 inner::'
    'after nest');
