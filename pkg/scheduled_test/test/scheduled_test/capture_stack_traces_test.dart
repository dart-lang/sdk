// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io' hide sleep;

import 'package:scheduled_test/scheduled_test.dart';

import '../metatest.dart';
import '../utils.dart';

void main() {
  setUpTimeout();

  expectTestsPass('error includes a stack trace by default', () {
    var error;
    test('test 1', () {
      currentSchedule.onComplete.schedule(() {
        error = currentSchedule.errors.first;
      });

      schedule(() => throw 'error');
    });

    test('test 2', () {
      // There should be two stack traces: one for the thrown error, and one
      // for the failed task (which is the captured one).
      expect(error.toString(),
          stringContainsInOrder(['Stack trace:', 'Stack trace:']));
    });
  }, passing: ['test 2']);

  expectTestsPass('does not capture a stack trace if set to false', () {
    var errorThrown = new Object();
    var error;
    test('test 1', () {
      currentSchedule.captureStackTraces = false;
      currentSchedule.onComplete.schedule(() {
        error = currentSchedule.errors.first;
      });

      schedule(() => throw errorThrown);
    });

    test('test 2', () {
      // There should only be the stack trace for the thrown exception, but no
      // captured trace for the failed task.
      var numStackTraces = 'Stack trace:'.allMatches(error.toString()).length;
      expect(numStackTraces, equals(1));
    });
  }, passing: ['test 2']);
}
