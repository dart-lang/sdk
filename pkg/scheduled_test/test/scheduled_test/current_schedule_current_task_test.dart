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

  expectTestsPass('currentSchedule.currentQueue returns the current queue '
      'while executing a task', () {
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
}
