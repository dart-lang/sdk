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

  expectTestsPass('the onException queue is run after an out-of-band error',
      () {
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
}
