// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:scheduled_test/scheduled_test.dart';

import 'package:metatest/metatest.dart';
import 'utils.dart';

void main() => initTests(_test);

void _test(message) {
  initMetatest(message);

  setUpTimeout();

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
}
