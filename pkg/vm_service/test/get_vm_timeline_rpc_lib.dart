// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer' as dev;

import 'common/test_helper.dart';

void primeTimeline() {
  dev.Timeline.startSync('apple');
  dev.Timeline.instantSync('ISYNC', arguments: {'fruit': 'banana'});
  dev.Timeline.finishSync();
  final parentTask = dev.TimelineTask.withTaskId(42);
  final task = dev.TimelineTask(parent: parentTask, filterKey: 'testFilter');
  task.start('TASK1', arguments: {'task1-start-key': 'task1-start-value'});
  task.instant(
    'ITASK',
    arguments: {'task1-instant-key': 'task1-instant-value'},
  );
  task.finish(arguments: {'task1-finish-key': 'task1-finish-value'});

  final flow = dev.Flow.begin(id: 123);
  dev.Timeline.startSync('peach', flow: flow);
  dev.Timeline.finishSync();
  dev.Timeline.startSync('watermelon', flow: dev.Flow.step(flow.id));
  dev.Timeline.finishSync();
  dev.Timeline.startSync('pear', flow: dev.Flow.end(flow.id));
  dev.Timeline.finishSync();
}

Future<void> main([List<String> args = const <String>[]]) {
  primeTimeline();
  return startServiceTest();
}
