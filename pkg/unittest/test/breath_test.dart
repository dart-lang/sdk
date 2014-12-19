// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library unittest.breath_test;

import 'dart:async';

import 'package:unittest/unittest.dart';

void main() {
  // Test the sync test 'breath' feature of unittest.

  // We use the testStartStopwatch to determine if the 'starve'
  // test was executed within a small enough time interval from
  // the first test that we are guaranteed the second test is
  // running in a microtask. If the second test is running as a
  // microtask we are guaranteed the timer scheduled in the
  // first test has not been run yet.
  var testStartStopwatch = new Stopwatch()..start();

  group('breath', () {
    var sentinel = 0;

    test('initial', () {
      Timer.run(() {
        sentinel = 1;
      });
    });

    test('starve', () {
      // If less than BREATH_INTERVAL time has passed since before
      // we started the test group then the previous test's timer
      // has not been run (at least this is what we are testing).
      if (testStartStopwatch.elapsed.inMilliseconds <= BREATH_INTERVAL) {
        expect(sentinel, 0);
      }

      // Next we wait for at least BREATH_INTERVAL to guaranteed the
      // next (third) test is run using a timer which means it will
      // run after the timer scheduled in the first test and hence
      // the sentinel should have been set to 1.
      var sw = new Stopwatch()..start();
      while (sw.elapsed.inMilliseconds < BREATH_INTERVAL);
    });

    test('breathed', () {
      expect(sentinel, 1);
    });
  });
}
