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

  expectTestsPass("nested schedule() runs its function immediately (but "
      "asynchronously)", () {
    test('test', () {
      schedule(() {
        var nestedScheduleRun = false;
        schedule(() {
          nestedScheduleRun = true;
        });

        expect(nestedScheduleRun, isFalse);
        expect(pumpEventQueue().then((_) => nestedScheduleRun),
            completion(isTrue));
      });
    });
  });

  expectTestsPass("nested schedule() calls don't wait for one another", () {
    mock_clock.mock().run();
    test('test', () {
      var sleepFinished = false;
      schedule(() {
        schedule(() => sleep(1).then((_) {
          sleepFinished = true;
        }));
        schedule(() => expect(sleepFinished, isFalse));
      });
    });
  });

  expectTestsPass("nested schedule() calls block their parent task", () {
    mock_clock.mock().run();
    test('test', () {
      var sleepFinished = false;
      schedule(() {
        schedule(() => sleep(1).then((_) {
          sleepFinished = true;
        }));
      });

      schedule(() => expect(sleepFinished, isTrue));
    });
  });

  expectTestsPass("nested schedule() calls forward their Future values", () {
    mock_clock.mock().run();
    test('test', () {
      schedule(() {
        expect(schedule(() => 'foo'), completion(equals('foo')));
      });
    });
  });

  expectTestsPass("errors in nested schedule() calls are properly registered",
      () {
    var errors;
    test('test 1', () {
      currentSchedule.onException.schedule(() {
        errors = currentSchedule.errors;
      });

      schedule(() {
        schedule(() {
          throw 'error';
        });
      });
    });

    test('test 2', () {
      expect(errors, everyElement(new isInstanceOf<ScheduleError>()));
      expect(errors.map((e) => e.error), equals(['error']));
    });
  }, passing: ['test 2']);

  expectTestsPass("nested scheduled blocks whose return values are passed to "
      "wrapFuture should report exceptions once", () {
    var error = 'oh no!';
    var errors;
    test('test 1', () {
      currentSchedule.onException.schedule(() {
        errors = currentSchedule.errors;
      });

      schedule(() {
        wrapFuture(schedule(() {
          throw error;
        }));

        return pumpEventQueue();
      });
    });

    test('test 2', () {
      expect(errors, everyElement(new isInstanceOf<ScheduleError>()));
      expect(errors.map((e) => e.error), equals([error]));
    });
  }, passing: ['test 2']);

  expectTestsPass("a nested task failing shouldn't short-circuit the parent "
      "task", () {
    var parentTaskFinishedBeforeOnComplete = false;
    test('test 1', () {
      var parentTaskFinished = false;
      currentSchedule.onComplete.schedule(() {
        parentTaskFinishedBeforeOnComplete = parentTaskFinished;
      });

      schedule(() {
        schedule(() {
          throw 'error';
        });

        return sleep(1).then((_) {
          parentTaskFinished = true;
        });
      });
    });

    test('test 2', () {
      expect(parentTaskFinishedBeforeOnComplete, isTrue);
    });
  }, passing: ['test 2']);
}
