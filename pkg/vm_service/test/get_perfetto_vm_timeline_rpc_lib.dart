// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';

import 'common/test_helper.dart';

void primeTimeline() {
  Timeline.startSync('apple');
  Timeline.instantSync('ISYNC', arguments: {'fruit': 'banana'});
  Timeline.finishSync();

  final parentTask = TimelineTask.withTaskId(42);
  final task = TimelineTask(parent: parentTask, filterKey: 'testFilter');
  task.start('TASK1', arguments: {'task1-start-key': 'task1-start-value'});
  task.instant(
    'ITASK',
    arguments: {'task1-instant-key': 'task1-instant-value'},
  );
  task.finish(arguments: {'task1-finish-key': 'task1-finish-value'});

  final flow = Flow.begin(id: 123);
  Timeline.startSync('peach', flow: flow);
  Timeline.finishSync();
  Timeline.startSync('watermelon', flow: Flow.step(flow.id));
  Timeline.finishSync();
  Timeline.startSync('pear', flow: Flow.end(flow.id));
  Timeline.finishSync();
}

Future<void> main([List<String> args = const <String>[]]) {
  primeTimeline();
  return startServiceTest();
}
