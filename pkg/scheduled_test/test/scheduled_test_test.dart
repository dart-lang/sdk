// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library scheduled_test_test;

import 'dart:async';
import 'dart:io';

import 'package:scheduled_test/scheduled_test.dart';
import 'package:scheduled_test/src/mock_clock.dart' as mock_clock;

import 'metatest.dart';
import 'utils.dart';

void main() {
  metaSetUp(() {
    // TODO(nweiz): We used to only increase the timeout to 10s for the Windows
    // bots, but the Linux and Mac bots have started taking upwards of 5s when
    // running pumpEventQueue, so we're increasing the timeout across the board
    // (see issue 9248).
    currentSchedule.timeout = new Duration(seconds: 10);
  });

  expectTestsPass('a scheduled test with a correct synchronous expectation '
      'should pass', () {
    test('test', () {
      expect('foo', equals('foo'));
    });
  });

  expectTestsFail('a scheduled test with an incorrect synchronous expectation '
      'should fail', () {
    test('test', () {
      expect('foo', equals('bar'));
    });
  });

  expectTestsPass('a scheduled test with a correct asynchronous expectation '
      'should pass', () {
    test('test', () {
      expect(new Future.immediate('foo'), completion(equals('foo')));
    });
  });

  expectTestsFail('a scheduled test with an incorrect asynchronous expectation '
      'should fail', () {
    test('test', () {
      expect(new Future.immediate('foo'), completion(equals('bar')));
    });
  });

  expectTestsPass('a passing scheduled synchronous expect should register', () {
    test('test', () {
      schedule(() => expect('foo', equals('foo')));
    });
  });

  expectTestsFail('a failing scheduled synchronous expect should register', () {
    test('test', () {
      schedule(() => expect('foo', equals('bar')));
    });
  });

  expectTestsPass('a passing scheduled asynchronous expect should '
      'register', () {
    test('test', () {
      schedule(() =>
          expect(new Future.immediate('foo'), completion(equals('foo'))));
    });
  });

  expectTestsFail('a failing scheduled synchronous expect should '
      'register', () {
    test('test', () {
      schedule(() =>
          expect(new Future.immediate('foo'), completion(equals('bar'))));
    });
  });

  expectTestsPass('scheduled blocks should be run in order after the '
      'synchronous setup', () {
    test('test', () {
      var list = [1];
      schedule(() => list.add(2));
      list.add(3);
      schedule(() => expect(list, equals([1, 3, 4, 2])));
      list.add(4);
    });
  });

  expectTestsPass('scheduled blocks should forward their return values as '
      'Futures', () {
    test('synchronous value', () {
      var future = schedule(() => 'value');
      expect(future, completion(equals('value')));
    });

    test('asynchronous value', () {
      var future = schedule(() => new Future.immediate('value'));
      expect(future, completion(equals('value')));
    });
  });

  expectTestsPass('scheduled blocks should wait for their Future return values '
      'to complete before proceeding', () {
    test('test', () {
      var value = 'unset';
      schedule(() => pumpEventQueue().then((_) {
        value = 'set';
      }));
      schedule(() => expect(value, equals('set')));
    });
  });

  expectTestsFail('a test failure in a chained future in a scheduled block '
      'should be registered', () {
    test('test', () {
      schedule(() => new Future.immediate('foo')
          .then((v) => expect(v, equals('bar'))));
    });
  });

  expectTestsFail('an error in a chained future in a scheduled block should be '
      'registered', () {
    test('test', () {
      schedule(() => new Future.immediate(null).then((_) {
        throw 'error';
      }));
    });
  });

  expectTestsFail('an out-of-band failure in wrapAsync is handled', () {
    mock_clock.mock().run();
    test('test', () {
      schedule(() {
        sleep(1).then(wrapAsync((_) => expect('foo', equals('bar'))));
      });
      schedule(() => sleep(2));
    });
  });

  expectTestsFail('an out-of-band failure in wrapAsync that finishes after the '
      'schedule is handled', () {
    mock_clock.mock().run();
    test('test', () {
      schedule(() {
        sleep(2).then(wrapAsync((_) => expect('foo', equals('bar'))));
      });
      schedule(() => sleep(1));
    });
  });

  expectTestsFail('an out-of-band failure in wrapFuture is handled', () {
    mock_clock.mock().run();
    test('test', () {
      schedule(() {
        wrapFuture(sleep(1).then((_) => expect('foo', equals('bar'))));
      });
      schedule(() => sleep(2));
    });
  });

  expectTestsFail('an out-of-band failure in wrapFuture that finishes after '
      'the schedule is handled', () {
    mock_clock.mock().run();
    test('test', () {
      schedule(() {
        wrapFuture(sleep(2).then((_) => expect('foo', equals('bar'))));
      });
      schedule(() => sleep(1));
    });
  });

  expectTestsPass("wrapFuture should return the value of the wrapped future",
      () {
    test('test', () {
      schedule(() {
        expect(wrapFuture(pumpEventQueue().then((_) => 'foo')),
            completion(equals('foo')));
      });
    });
  });

  expectTestsPass("wrapFuture should pass through the error of the wrapped "
      "future", () {
    var error;
    test('test 1', () {
      schedule(() {
        wrapFuture(pumpEventQueue().then((_) {
          throw 'error';
        })).catchError(wrapAsync((e) {
          error = e.error;
        }));
      });
    });

    test('test 2', () {
      expect(error, equals('error'));
    });
  }, passing: ['test 2']);

  expectTestsPass("scheduled blocks whose return values are passed to "
      "wrapFuture should report exceptions once", () {
    var errors;
    test('test 1', () {
      currentSchedule.onException.schedule(() {
        errors = currentSchedule.errors;
      });

      wrapFuture(schedule(() {
        throw 'error';
      }));
    });

    test('test 2', () {
      expect(errors, everyElement(new isInstanceOf<ScheduleError>()));
      expect(errors.map((e) => e.error), equals(['error']));
    });
  }, passing: ['test 2']);

  expectTestsFail('an out-of-band error reported via signalError is '
      'handled', () {
    mock_clock.mock().run();
    test('test', () {
      schedule(() {
        sleep(1).then((_) => currentSchedule.signalError('bad'));
      });
      schedule(() => sleep(2));
    });
  });

  expectTestsFail('an out-of-band error reported via signalError that finished '
      'after the schedule is handled', () {
    mock_clock.mock().run();
    test('test', () {
      schedule(() {
        var done = wrapAsync((_) {});
        sleep(2).then((_) {
          currentSchedule.signalError('bad');
          done(null);
        });
      });
      schedule(() => sleep(1));
    });
  });

  expectTestsFail('a synchronous error reported via signalError is handled', () {
    test('test', () {
      currentSchedule.signalError('bad');
    });
  });

  expectTestsPass('the onComplete queue is run if a test is successful', () {
    var onCompleteRun = false;
    test('test 1', () {
      currentSchedule.onComplete.schedule(() {
        onCompleteRun = true;
      });

      schedule(() => expect('foo', equals('foo')));
    });

    test('test 2', () {
      expect(onCompleteRun, isTrue);
    });
  });

  expectTestsPass('the onComplete queue is run after an out-of-band callback',
      () {
    var outOfBandRun = false;
    test('test1', () {
      currentSchedule.onComplete.schedule(() {
        expect(outOfBandRun, isTrue);
      });

      pumpEventQueue().then(wrapAsync((_) {
        outOfBandRun = true;
      }));
    });
  });

  expectTestsPass('the onComplete queue is run after an out-of-band callback '
      'and waits for another out-of-band callback', () {
    var outOfBand1Run = false;
    var outOfBand2Run = false;
    test('test1', () {
      currentSchedule.onComplete.schedule(() {
        expect(outOfBand1Run, isTrue);

        pumpEventQueue().then(wrapAsync((_) {
          outOfBand2Run = true;
        }));
      });

      pumpEventQueue().then(wrapAsync((_) {
        outOfBand1Run = true;
      }));
    });

    test('test2', () => expect(outOfBand2Run, isTrue));
  });

  expectTestsFail('an out-of-band callback in the onComplete queue blocks the '
      'test', () {
    test('test', () {
      currentSchedule.onComplete.schedule(() {
        pumpEventQueue().then(wrapAsync((_) => expect('foo', equals('bar'))));
      });
    });
  });

  expectTestsPass('an out-of-band callback blocks onComplete even with an '
      'unrelated error', () {
    var outOfBandRun = false;
    var outOfBandSetInOnComplete = false;
    test('test 1', () {
      currentSchedule.onComplete.schedule(() {
        outOfBandSetInOnComplete = outOfBandRun;
      });

      pumpEventQueue().then(wrapAsync((_) {
        outOfBandRun = true;
      }));

      schedule(() => expect('foo', equals('bar')));
    });

    test('test 2', () => expect(outOfBandSetInOnComplete, isTrue));
  }, passing: ['test 2']);

  expectTestsPass('the onComplete queue is run after an asynchronous error',
      () {
    var onCompleteRun = false;
    test('test 1', () {
      currentSchedule.onComplete.schedule(() {
        onCompleteRun = true;
      });

      schedule(() => expect('foo', equals('bar')));
    });

    test('test 2', () {
      expect(onCompleteRun, isTrue);
    });
  }, passing: ['test 2']);

  expectTestsPass('the onComplete queue is run after a synchronous error', () {
    var onCompleteRun = false;
    test('test 1', () {
      currentSchedule.onComplete.schedule(() {
        onCompleteRun = true;
      });

      throw 'error';
    });

    test('test 2', () {
      expect(onCompleteRun, isTrue);
    });
  }, passing: ['test 2']);

  expectTestsPass('the onComplete queue is run after an out-of-band error', () {
    var onCompleteRun = false;
    test('test 1', () {
      currentSchedule.onComplete.schedule(() {
        onCompleteRun = true;
      });

      pumpEventQueue().then(wrapAsync((_) => expect('foo', equals('bar'))));
    });

    test('test 2', () {
      expect(onCompleteRun, isTrue);
    });
  }, passing: ['test 2']);

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

  expectTestsPass('onComplete tasks can be scheduled during normal tasks', () {
    var onCompleteRun = false;
    test('test 1', () {
      schedule(() {
        currentSchedule.onComplete.schedule(() {
          onCompleteRun = true;
        });
      });
    });

    test('test 2', () {
      expect(onCompleteRun, isTrue);
    });
  });

  expectTestsFail('failures in onComplete cause test failures', () {
    test('test', () {
      currentSchedule.onComplete.schedule(() {
        expect('foo', equals('bar'));
      });
    });
  });

  expectTestsPass('the onException queue is not run if a test is successful',
      () {
    var onExceptionRun = false;
    test('test 1', () {
      currentSchedule.onException.schedule(() {
        onExceptionRun = true;
      });

      schedule(() => expect('foo', equals('foo')));
    });

    test('test 2', () {
      expect(onExceptionRun, isFalse);
    });
  });

  expectTestsPass('the onException queue is run after an asynchronous error',
      () {
    var onExceptionRun = false;
    test('test 1', () {
      currentSchedule.onException.schedule(() {
        onExceptionRun = true;
      });

      schedule(() => expect('foo', equals('bar')));
    });

    test('test 2', () {
      expect(onExceptionRun, isTrue);
    });
  }, passing: ['test 2']);

  expectTestsPass('the onException queue is run after a synchronous error', () {
    var onExceptionRun = false;
    test('test 1', () {
      currentSchedule.onException.schedule(() {
        onExceptionRun = true;
      });

      throw 'error';
    });

    test('test 2', () {
      expect(onExceptionRun, isTrue);
    });
  }, passing: ['test 2']);

  expectTestsPass('the onException queue is run after an out-of-band error', () {
    var onExceptionRun = false;
    test('test 1', () {
      currentSchedule.onException.schedule(() {
        onExceptionRun = true;
      });

      pumpEventQueue().then(wrapAsync((_) => expect('foo', equals('bar'))));
    });

    test('test 2', () {
      expect(onExceptionRun, isTrue);
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

  expectTestsPass('currentSchedule.currentTask returns the current task while '
      'executing a task', () {
    test('test', () {
      schedule(() => expect('foo', equals('foo')), 'task 1');

      schedule(() {
        expect(currentSchedule.currentTask.description, equals('task 2'));
      }, 'task 2');

      schedule(() => expect('bar', equals('bar')), 'task 3');
    });
  });

  expectTestsPass('currentSchedule.currentTask is null before the schedule has '
      'started', () {
    test('test', () {
      schedule(() => expect('foo', equals('foo')));

      expect(currentSchedule.currentTask, isNull);
    });
  });

  expectTestsPass('currentSchedule.currentTask is null after the schedule has '
      'completed', () {
    test('test', () {
      schedule(() {
        expect(pumpEventQueue().then((_) {
          expect(currentSchedule.currentTask, isNull);
        }), completes);
      });

      schedule(() => expect('foo', equals('foo')));
    });
  });

  expectTestsPass('currentSchedule.currentQueue returns the current queue while '
      'executing a task', () {
    test('test', () {
      schedule(() {
        expect(currentSchedule.currentQueue.name, equals('tasks'));
      });
    });
  });

  expectTestsPass('currentSchedule.currentQueue is tasks before the schedule '
      'has started', () {
    test('test', () {
      schedule(() => expect('foo', equals('foo')));

      expect(currentSchedule.currentQueue.name, equals('tasks'));
    });
  });

  expectTestsPass('currentSchedule.state starts out as SET_UP', () {
    test('test', () {
      expect(currentSchedule.state, equals(ScheduleState.SET_UP));
    });
  });

  expectTestsPass('currentSchedule.state is RUNNING in tasks', () {
    test('test', () {
      schedule(() {
        expect(currentSchedule.state, equals(ScheduleState.RUNNING));
      });

      currentSchedule.onComplete.schedule(() {
        expect(currentSchedule.state, equals(ScheduleState.RUNNING));
      });
    });
  });

  expectTestsPass('currentSchedule.state is DONE after the test', () {
    var oldSchedule;
    test('test 1', () {
      oldSchedule = currentSchedule;
    });

    test('test 2', () {
      expect(oldSchedule.state, equals(ScheduleState.DONE));
    });
  });

  expectTestsPass('setUp is run before each test', () {
    var setUpRun = false;
    setUp(() {
      setUpRun = true;
    });

    test('test 1', () {
      expect(setUpRun, isTrue);
      setUpRun = false;
    });

    test('test 2', () {
      expect(setUpRun, isTrue);
      setUpRun = false;
    });
  });

  expectTestsPass('setUp can schedule events', () {
    var setUpRun = false;
    setUp(() {
      schedule(() {
        setUpRun = true;
      });
      currentSchedule.onComplete.schedule(() {
        setUpRun = false;
      });
    });

    test('test 1', () {
      expect(setUpRun, isFalse);
      schedule(() => expect(setUpRun, isTrue));
    });

    test('test 2', () {
      expect(setUpRun, isFalse);
      schedule(() => expect(setUpRun, isTrue));
    });
  });

  expectTestsFail('synchronous errors in setUp will cause tests to fail', () {
    setUp(() => expect('foo', equals('bar')));
    test('test 1', () => expect('foo', equals('foo')));
    test('test 2', () => expect('foo', equals('foo')));
  });

  expectTestsFail('scheduled errors in setUp will cause tests to fail', () {
    setUp(() => schedule(() => expect('foo', equals('bar'))));
    test('test 1', () => expect('foo', equals('foo')));
    test('test 2', () => expect('foo', equals('foo')));
  });

  expectTestsPass('synchronous errors in setUp will cause onException to run',
      () {
    var onExceptionRun = false;
    setUp(() {
      currentSchedule.onException.schedule(() {
        onExceptionRun = true;
      });

      if (!onExceptionRun) expect('foo', equals('bar'));
    });

    test('test 1', () => expect('foo', equals('foo')));
    test('test 2', () => expect(onExceptionRun, isTrue));
  }, passing: ['test 2']);

  expectTestsPass("setUp doesn't apply to child groups", () {
    var setUpRun = false;
    setUp(() {
      setUpRun = true;
      currentSchedule.onComplete.schedule(() {
        setUpRun = false;
      });
    });

    test('outer', () {
      expect(setUpRun, isTrue);
    });

    group('group', () {
      test('inner', () {
        expect(setUpRun, isFalse);
      });
    });
  });

  expectTestsPass("setUp doesn't apply to parent groups", () {
    var setUpRun = false;
    group('group', () {
      setUp(() {
        setUpRun = true;
        currentSchedule.onComplete.schedule(() {
          setUpRun = false;
        });
      });

      test('inner', () {
        expect(setUpRun, isTrue);
      });
    });

    test('outer', () {
      expect(setUpRun, isFalse);
    });
  });

  expectTestsPass("setUp doesn't apply to sibling groups", () {
    var setUpRun = false;
    group('group 1', () {
      setUp(() {
        setUpRun = true;
        currentSchedule.onComplete.schedule(() {
          setUpRun = false;
        });
      });

      test('test 1', () {
        expect(setUpRun, isTrue);
      });
    });

    group('group 2', () {
      test('test 2', () {
        expect(setUpRun, isFalse);
      });
    });
  });

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

  expectTestsPass("out-of-band schedule() runs its function immediately (but "
      "asynchronously)", () {
    mock_clock.mock().run();
    test('test', () {
      schedule(() {
        wrapFuture(sleep(1).then((_) {
          var nestedScheduleRun = false;
          schedule(() {
            nestedScheduleRun = true;
          });

          expect(nestedScheduleRun, isFalse);
          expect(pumpEventQueue().then((_) => nestedScheduleRun),
              completion(isTrue));
        }));
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

  expectTestsPass("out-of-band schedule() calls block their parent queue", () {
    mock_clock.mock().run();
    test('test', () {
      var scheduleRun = false;
      wrapFuture(sleep(1).then((_) {
        schedule(() => sleep(1).then((_) {
          scheduleRun = true;
        }));
      }));

      currentSchedule.onComplete.schedule(() => expect(scheduleRun, isTrue));
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
    var errors;
    test('test 1', () {
      currentSchedule.onException.schedule(() {
        errors = currentSchedule.errors;
      });

      schedule(() {
        wrapFuture(schedule(() {
          throw 'error';
        }));

        return pumpEventQueue();
      });
    });

    test('test 2', () {
      expect(errors, everyElement(new isInstanceOf<ScheduleError>()));
      expect(errors.map((e) => e.error), equals(['error']));
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

  expectTestsPass("expect(..., completes) with a completing future should pass",
      () {
    test('test', () {
      expect(pumpEventQueue(), completes);
    });
  });

  expectTestsPass("expect(..., completes) with a failing future should signal "
      "an out-of-band error", () {
    var errors;
    test('test 1', () {
      currentSchedule.onException.schedule(() {
        errors = currentSchedule.errors;
      });

      expect(pumpEventQueue().then((_) {
        throw 'error';
      }), completes);
    });

    test('test 2', () {
      expect(errors, everyElement(new isInstanceOf<ScheduleError>()));
      expect(errors.map((e) => e.error), equals(['error']));
    });
  }, passing: ['test 2']);

  expectTestsPass("expect(..., completion(...)) with a matching future should "
      "pass", () {
    test('test', () {
      expect(pumpEventQueue().then((_) => 'foo'), completion(equals('foo')));
    });
  });

  expectTestsPass("expect(..., completion(...)) with a non-matching future "
      "should signal an out-of-band error", () {
    var errors;
    test('test 1', () {
      currentSchedule.onException.schedule(() {
        errors = currentSchedule.errors;
      });

      expect(pumpEventQueue().then((_) => 'foo'), completion(equals('bar')));
    });

    test('test 2', () {
      expect(errors, everyElement(new isInstanceOf<ScheduleError>()));
      expect(errors.length, equals(1));
      expect(errors.first.error, new isInstanceOf<TestFailure>());
    });
  }, passing: ['test 2']);

  expectTestsPass("expect(..., completion(...)) with a failing future should "
      "signal an out-of-band error", () {
    var errors;
    test('test 1', () {
      currentSchedule.onException.schedule(() {
        errors = currentSchedule.errors;
      });

      expect(pumpEventQueue().then((_) {
        throw 'error';
      }), completion(equals('bar')));
    });

    test('test 2', () {
      expect(errors, everyElement(new isInstanceOf<ScheduleError>()));
      expect(errors.map((e) => e.error), equals(['error']));
    });
  }, passing: ['test 2']);

  expectTestsPass("aborting the schedule before it's started running should "
      "cause no tasks to be run", () {
    test('test', () {
      schedule(() {
        throw 'error';
      });

      currentSchedule.abort();
    });
  });

  expectTestsPass("aborting the schedule while it's running should stop future "
      "tasks from running", () {
    test('test', () {
      schedule(currentSchedule.abort);

      schedule(() {
        throw 'error';
      });
    });
  });

  expectTestsPass("aborting the schedule while it's running shouldn't stop "
      "tasks in other queues from running", () {
    var onCompleteRun = false;
    test('test 1', () {
      schedule(currentSchedule.abort);

      currentSchedule.onComplete.schedule(() {
        onCompleteRun = true;
      });
    });

    test('test 2', () {
      expect(onCompleteRun, isTrue);
    });
  });

  expectTestsPass("aborting the schedule while it's running shouldn't stop "
      "out-of-band callbacks", () {
    test('test', () {
      var outOfBandFinished = false;
      schedule(() {
        wrapFuture(pumpEventQueue().then((_) {
          outOfBandFinished = true;
        }));

        currentSchedule.abort();
      });

      currentSchedule.onComplete.schedule(() {
        expect(outOfBandFinished, isTrue);
      });
    });
  });

  expectTestsPass("aborting the schedule in a non-tasks queue should stop "
      "future tasks from running", () {
    test('test', () {
      currentSchedule.onComplete.schedule(() {
        currentSchedule.abort();
      });

      currentSchedule.onComplete.schedule(() {
        throw 'error';
      });
    });
  });

  expectTestsFail("aborting the schedule after an out-of-band error should "
      "still surface the error", () {
    test('test', () {
      schedule(() {
        currentSchedule.signalError('error');
        currentSchedule.abort();
      });
    });
  });
}
