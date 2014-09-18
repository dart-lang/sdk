// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:scheduled_test/scheduled_test.dart';

import 'package:metatest/metatest.dart';
import '../utils.dart';

void main() => initTests(_test);

void _test(message) {
  initMetatest(message);

  setUpTimeout();

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
}
