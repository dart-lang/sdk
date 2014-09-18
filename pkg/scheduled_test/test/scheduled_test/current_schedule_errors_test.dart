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

  expectTestResults('a scheduled test with an out-of-band error should fail',
      () {
    mock_clock.mock().run();
    test('test 1', () {
      sleep(1).then((_) => throw 'error');
    });

    test('test 2', () {
      return sleep(2);
    });
  }, [{
    'description': 'test 1',
    'result': 'error'
  }, {
    'description': 'test 2',
    'result': 'pass'
  }]);

  expectTestsPass('currentSchedule.errors contains the error in the onComplete '
      'queue', () {
    var errors;
    test('test 1', () {
      currentSchedule.onComplete.schedule(() {
        errors = currentSchedule.errors;
      });

      throw 'error';
    });

    test('test 2', () {
      expect(errors, everyElement(new isInstanceOf<ScheduleError>()));
      expect(errors.map((e) => e.error), equals(['error']));
    });
  }, passing: ['test 2']);

  expectTestsPass('currentSchedule.errors contains the error in the '
      'onException queue', () {
    var errors;
    test('test 1', () {
      currentSchedule.onException.schedule(() {
        errors = currentSchedule.errors;
      });

      throw 'error';
    });

    test('test 2', () {
      expect(errors, everyElement(new isInstanceOf<ScheduleError>()));
      expect(errors.map((e) => e.error), equals(['error']));
    });
  }, passing: ['test 2']);

  expectTestsPass('currentSchedule.errors contains an error passed into '
      'signalError synchronously', () {
    var errors;
    test('test 1', () {
      currentSchedule.onException.schedule(() {
        errors = currentSchedule.errors;
      });

      currentSchedule.signalError('error');
    });

    test('test 2', () {
      expect(errors, everyElement(new isInstanceOf<ScheduleError>()));
      expect(errors.map((e) => e.error), equals(['error']));
    });
  }, passing: ['test 2']);

  expectTestsPass('currentSchedule.errors contains an error passed into '
      'signalError asynchronously', () {
    var errors;
    test('test 1', () {
      currentSchedule.onException.schedule(() {
        errors = currentSchedule.errors;
      });

      schedule(() => currentSchedule.signalError('error'));
    });

    test('test 2', () {
      expect(errors, everyElement(new isInstanceOf<ScheduleError>()));
      expect(errors.map((e) => e.error), equals(['error']));
    });
  }, passing: ['test 2']);

  expectTestsPass('currentSchedule.errors contains an error passed into '
      'signalError out-of-band', () {
    var errors;
    test('test 1', () {
      currentSchedule.onException.schedule(() {
        errors = currentSchedule.errors;
      });

      pumpEventQueue().then(wrapAsync((_) {
        return currentSchedule.signalError('error');
      }));
    });

    test('test 2', () {
      expect(errors, everyElement(new isInstanceOf<ScheduleError>()));
      expect(errors.map((e) => e.error), equals(['error']));
    });
  }, passing: ['test 2']);

  expectTestsPass('currentSchedule.errors contains errors from both the task '
      'queue and the onException queue in onComplete', () {
    var errors;
    test('test 1', () {
      currentSchedule.onComplete.schedule(() {
        errors = currentSchedule.errors;
      });

      currentSchedule.onException.schedule(() {
        throw 'error2';
      });

      throw 'error1';
    });

    test('test 2', () {
      expect(errors, everyElement(new isInstanceOf<ScheduleError>()));
      expect(errors.map((e) => e.error), equals(['error1', 'error2']));
    });
  }, passing: ['test 2']);

  expectTestsPass('currentSchedule.errors contains multiple out-of-band errors '
      'from both the main task queue and onException in onComplete', () {
    mock_clock.mock().run();
    var errors;
    test('test 1', () {
      currentSchedule.onComplete.schedule(() {
        errors = currentSchedule.errors;
      });

      currentSchedule.onException.schedule(() {
        sleep(1).then(wrapAsync((_) {
          throw 'error3';
        }));
        sleep(2).then(wrapAsync((_) {
          throw 'error4';
        }));
      });

      sleep(1).then(wrapAsync((_) {
        throw 'error1';
      }));
      sleep(2).then(wrapAsync((_) {
        throw 'error2';
      }));
    });

    test('test 2', () {
      expect(errors, everyElement(new isInstanceOf<ScheduleError>()));
      expect(errors.map((e) => e.error),
          orderedEquals(['error1', 'error2', 'error3', 'error4']));
    });
  }, passing: ['test 2']);

  expectTestsPass('currentSchedule.errors contains multiple out-of-band errors '
      'from both the main task queue and onException in onComplete reported '
      'via wrapFuture', () {
    mock_clock.mock().run();
    var errors;
    test('test 1', () {
      currentSchedule.onComplete.schedule(() {
        errors = currentSchedule.errors;
      });

      currentSchedule.onException.schedule(() {
        wrapFuture(sleep(1).then((_) {
          throw 'error3';
        }));
        wrapFuture(sleep(2).then((_) {
          throw 'error4';
        }));
      });

      wrapFuture(sleep(1).then((_) {
        throw 'error1';
      }));
      wrapFuture(sleep(2).then((_) {
        throw 'error2';
      }));
    });

    test('test 2', () {
      expect(errors, everyElement(new isInstanceOf<ScheduleError>()));
      expect(errors.map((e) => e.error),
          orderedEquals(['error1', 'error2', 'error3', 'error4']));
    });
  }, passing: ['test 2']);

  expectTestsPass('currentSchedule.errors contains both an out-of-band error '
      'and an error raised afterwards in a task', () {
    mock_clock.mock().run();
    var errors;
    test('test 1', () {
      currentSchedule.onComplete.schedule(() {
        errors = currentSchedule.errors;
      });

      sleep(1).then(wrapAsync((_) {
        throw 'out-of-band';
      }));

      schedule(() => sleep(2).then((_) {
        throw 'in-band';
      }));
    });

    test('test 2', () {
      expect(errors, everyElement(new isInstanceOf<ScheduleError>()));
      expect(errors.map((e) => e.error), equals(['out-of-band', 'in-band']));
    });
  }, passing: ['test 2']);

  expectTestsPass('currentSchedule.errors contains both an error raised in a '
      'task and an error raised afterwards out-of-band', () {
    mock_clock.mock().run();
    var errors;
    test('test 1', () {
      currentSchedule.onComplete.schedule(() {
        errors = currentSchedule.errors;
      });

      sleep(2).then(wrapAsync((_) {
        throw 'out-of-band';
      }));

      schedule(() => sleep(1).then((_) {
        throw 'in-band';
      }));
    });

    test('test 2', () {
      expect(errors, everyElement(new isInstanceOf<ScheduleError>()));
      expect(errors.map((e) => e.error), equals(['in-band', 'out-of-band']));
    });
  }, passing: ['test 2']);
}
