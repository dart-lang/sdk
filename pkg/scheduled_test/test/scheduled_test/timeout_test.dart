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

  expectTestsPass("a single task that takes too long will cause a timeout "
      "error", () {
    mock_clock.mock().run();
    var errors;
    test('test 1', () {
      currentSchedule.timeout = new Duration(milliseconds: 1);

      currentSchedule.onException.schedule(() {
        errors = currentSchedule.errors;
      });

      schedule(() => sleep(2));
    });

    test('test 2', () {
      expect(errors, everyElement(new isInstanceOf<ScheduleError>()));
      expect(errors.map((e) => e.error), equals(["The schedule timed out after "
        "0:00:00.001000 of inactivity."]));
    });
  }, passing: ['test 2']);

  expectTestsPass("an out-of-band callback that takes too long will cause a "
      "timeout error", () {
    mock_clock.mock().run();
    var errors;
    test('test 1', () {
      currentSchedule.timeout = new Duration(milliseconds: 1);

      currentSchedule.onException.schedule(() {
        errors = currentSchedule.errors;
      });

      sleep(2).then(wrapAsync((_) => expect('foo', equals('foo'))));
    });

    test('test 2', () {
      expect(errors, everyElement(new isInstanceOf<ScheduleError>()));
      expect(errors.map((e) => e.error), equals(["The schedule timed out after "
        "0:00:00.001000 of inactivity."]));
    });
  }, passing: ['test 2']);

  expectTestsPass("each task resets the timeout timer", () {
    mock_clock.mock().run();
    test('test', () {
      currentSchedule.timeout = new Duration(milliseconds: 2);

      schedule(() => sleep(1));
      schedule(() => sleep(1));
      schedule(() => sleep(1));
    });
  });

  expectTestsPass("setting up the test doesn't trigger a timeout", () {
    var clock = mock_clock.mock();
    test('test', () {
      currentSchedule.timeout = new Duration(milliseconds: 1);

      clock.tick(2);
      schedule(() => expect('foo', equals('foo')));
    });
  });

  expectTestsPass("an out-of-band error that's signaled after a timeout but "
      "before the test completes is registered", () {
    mock_clock.mock().run();
    var errors;
    test('test 1', () {
      currentSchedule.timeout = new Duration(milliseconds: 3);

      currentSchedule.onException.schedule(() => sleep(2));
      currentSchedule.onException.schedule(() {
        errors = currentSchedule.errors;
      });

      sleep(4).then(wrapAsync((_) {
        throw 'out-of-band';
      }));
    });

    test('test 2', () {
      expect(errors, everyElement(new isInstanceOf<ScheduleError>()));
      expect(errors.map((e) => e.error), equals([
        "The schedule timed out after 0:00:00.003000 of inactivity.",
        "out-of-band"
      ]));
    });
  }, passing: ['test 2']);

  expectTestsPass("an out-of-band error that's signaled after a timeout but "
      "before the test completes plays nicely with other out-of-band callbacks",
      () {
    mock_clock.mock().run();
    var errors;
    var onExceptionCallbackRun = false;
    var onCompleteRunAfterOnExceptionCallback = false;
    test('test 1', () {
      currentSchedule.timeout = new Duration(milliseconds: 2);

      currentSchedule.onException.schedule(() {
        sleep(1).then(wrapAsync((_) {
          onExceptionCallbackRun = true;
        }));
      });

      currentSchedule.onComplete.schedule(() {
        onCompleteRunAfterOnExceptionCallback = onExceptionCallbackRun;
      });

      sleep(3).then(wrapAsync((_) {
        throw 'out-of-band';
      }));
    });

    test('test 2', () {
      expect(onCompleteRunAfterOnExceptionCallback, isTrue);
    });
  }, passing: ['test 2']);

  expectTestsPass("a task that times out while waiting to handle an "
      "out-of-band error records both", () {
    mock_clock.mock().run();
    var errors;
    test('test 1', () {
      currentSchedule.timeout = new Duration(milliseconds: 2);

      currentSchedule.onException.schedule(() {
        errors = currentSchedule.errors;
      });

      schedule(() => sleep(4));
      sleep(1).then((_) => currentSchedule.signalError('out-of-band'));
    });

    test('test 2', () {
      expect(errors, everyElement(new isInstanceOf<ScheduleError>()));
      expect(errors.map((e) => e.error), equals([
        "out-of-band",
        "The schedule timed out after 0:00:00.002000 of inactivity."
      ]));
    });
  }, passing: ['test 2']);

  expectTestsPass("a task that has an error then times out waiting for an "
      "out-of-band callback records both", () {
    mock_clock.mock().run();
    var errors;
    test('test 1', () {
      currentSchedule.timeout = new Duration(milliseconds: 2);

      currentSchedule.onException.schedule(() {
        errors = currentSchedule.errors;
      });

      schedule(() {
        throw 'error';
      });
      wrapFuture(sleep(3));
    });

    test('test 2', () {
      expect(errors, everyElement(new isInstanceOf<ScheduleError>()));
      expect(errors.map((e) => e.error), equals([
        "error",
        "The schedule timed out after 0:00:00.002000 of inactivity."
      ]));
    });
  }, passing: ['test 2']);

  expectTestsPass("currentSchedule.heartbeat resets the timeout timer", () {
    mock_clock.mock().run();
    test('test', () {
      currentSchedule.timeout = new Duration(milliseconds: 3);

      schedule(() {
        return sleep(2).then((_) {
          currentSchedule.heartbeat();
          return sleep(2);
        });
      });
    });
  });

  // TODO(nweiz): test out-of-band post-timeout errors that are detected after
  // the test finishes once we can detect top-level errors (issue 8417).
}
