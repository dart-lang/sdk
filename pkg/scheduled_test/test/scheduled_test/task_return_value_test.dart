// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:scheduled_test/scheduled_test.dart';
import 'package:scheduled_test/src/mock_clock.dart' as mock_clock;

import 'package:metatest/metatest.dart';
import '../utils.dart';

void main() => initTests(_test);

void _test(message) {
  initMetatest(message);

  setUpTimeout();

  expectTestsPass("an error thrown in a scheduled task should be piped to that "
      "task's return value", () {
    var error;
    test('test 1', () {
      schedule(() {
        throw 'error';
      }).catchError((e) {
        error = e;
      });
    });

    test('test 2', () {
      expect(error, new isInstanceOf<ScheduleError>());
      expect(error.error, equals('error'));
    });
  }, passing: ['test 2']);

  expectTestsPass("an error thrown in a scheduled task should be piped to "
      "future tasks' return values", () {
    var error;
    test('test 1', () {
      schedule(() {
        throw 'error';
      });

      schedule(() => null).catchError((e) {
        error = e;
      });
    });

    test('test 2', () {
      expect(error, new isInstanceOf<ScheduleError>());
      expect(error.error, equals('error'));
    });
  }, passing: ['test 2']);

  expectTestsPass("an out-of-band error should be piped to future tasks' "
      "return values, but not the current task's", () {
    mock_clock.mock().run();
    var error;
    var firstTaskError = false;
    var secondTaskRun = false;
    test('test 1', () {
      schedule(() => sleep(2)).catchError((_) {
        firstTaskError = true;
      });

      sleep(1).then(wrapAsync((_) {
        throw 'error';
      }));

      schedule(() {
        secondTaskRun = true;
      }).catchError((e) {
        error = e;
      });
    });

    test('test 2', () {
      expect(firstTaskError, isFalse);
      expect(secondTaskRun, isFalse);
      expect(error, new isInstanceOf<ScheduleError>());
      expect(error.error, equals('error'));
    });
  }, passing: ['test 2']);
}
