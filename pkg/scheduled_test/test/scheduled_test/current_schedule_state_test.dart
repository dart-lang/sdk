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
}
