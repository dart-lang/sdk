// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';
import 'dart:io';

import 'package:observatory_2/service_io.dart';
import 'package:test/test.dart';

import 'test_helper.dart';

primeTimeline() {
  Timeline.startSync('apple');
  Timeline.instantSync('ISYNC', arguments: {'fruit': 'banana'});
  Timeline.finishSync();
  TimelineTask parentTask = TimelineTask.withTaskId(42);
  TimelineTask task = TimelineTask(parent: parentTask, filterKey: 'testFilter');
  task.start('TASK1', arguments: {'task1-start-key': 'task1-start-value'});
  task.instant('ITASK',
      arguments: {'task1-instant-key': 'task1-instant-value'});
  task.finish(arguments: {'task1-finish-key': 'task1-finish-value'});

  Flow flow = Flow.begin(id: 123);
  Timeline.startSync('peach', flow: flow);
  Timeline.finishSync();
  Timeline.startSync('watermelon', flow: Flow.step(flow.id));
  Timeline.finishSync();
  Timeline.startSync('pear', flow: Flow.end(flow.id));
  Timeline.finishSync();
}

List filterForDartEvents(List events) {
  return events.where((event) => event['cat'] == 'Dart').toList();
}

bool mapContains(Map map, Map submap) {
  for (var key in submap.keys) {
    if (map[key] != submap[key]) {
      return false;
    }
  }
  return true;
}

bool eventsContains(List events, String phase, String name, [Map arguments]) {
  for (Map event in events) {
    if ((event['ph'] == phase) && (event['name'] == name)) {
      if (arguments == null) {
        return true;
      } else if (mapContains(event['args'], arguments)) {
        return true;
      }
    }
  }
  return false;
}

int timeOrigin(List events) {
  if (events.length == 0) {
    return 0;
  }
  int smallest = events[0]['ts'];
  for (var i = 0; i < events.length; i++) {
    Map event = events[i];
    if (event['ts'] < smallest) {
      smallest = event['ts'];
    }
  }
  return smallest;
}

int timeDuration(List events, int timeOrigin) {
  if (events.length == 0) {
    return 0;
  }
  int biggestDuration = events[0]['ts'] - timeOrigin;
  for (var i = 0; i < events.length; i++) {
    Map event = events[i];
    int duration = event['ts'] - timeOrigin;
    if (duration > biggestDuration) {
      biggestDuration = duration;
    }
  }
  return biggestDuration;
}

void allEventsHaveIsolateNumber(List events) {
  for (Map event in events) {
    if (event['ph'] == 'M') {
      // Skip meta-data events.
      continue;
    }
    if (event['name'] == 'Runnable' && event['ph'] == 'i') {
      // Skip Runnable events which don't have an isolate.
      continue;
    }
    if (event['cat'] == 'VM') {
      // Skip VM category events which don't have an isolate.
      continue;
    }
    if (event['cat'] == 'API') {
      // Skip API category events which sometimes don't have an isolate.
      continue;
    }
    if (event['cat'] == 'Embedder' &&
        (event['name'] == 'DFE::ReadScript' ||
            event['name'] == 'CreateIsolateGroupAndSetupHelper')) {
      continue;
    }
    Map arguments = event['args'];
    expect(arguments, isA<Map>());
    expect(arguments['isolateGroupId'], isA<String>());
    if (event['cat'] != 'GC') {
      expect(arguments['isolateId'], isA<String>());
    }
  }
}

var tests = <VMTest>[
  (VM vm) async {
    Map result = await vm.invokeRpcNoUpgrade('getVMTimeline', {});
    expect(result['type'], equals('Timeline'));
    expect(result['traceEvents'], isA<List>());
    final int numEvents = result['traceEvents'].length;
    List dartEvents = filterForDartEvents(result['traceEvents']);
    expect(dartEvents.length, greaterThanOrEqualTo(11));
    allEventsHaveIsolateNumber(dartEvents);
    allEventsHaveIsolateNumber(result['traceEvents']);
    expect(
        eventsContains(dartEvents, 'i', 'ISYNC', {'fruit': 'banana'}), isTrue);
    expect(eventsContains(dartEvents, 'B', 'apple'), isTrue);
    expect(eventsContains(dartEvents, 'E', 'apple'), isTrue);
    expect(
        eventsContains(dartEvents, 'b', 'TASK1', {
          'filterKey': 'testFilter',
          'task1-start-key': 'task1-start-value',
          'parentId': 42.toRadixString(16)
        }),
        isTrue);
    expect(
        eventsContains(dartEvents, 'e', 'TASK1', {
          'filterKey': 'testFilter',
          'task1-finish-key': 'task1-finish-value',
        }),
        isTrue);
    expect(
        eventsContains(dartEvents, 'n', 'ITASK', {
          'filterKey': 'testFilter',
          'task1-instant-key': 'task1-instant-value',
        }),
        isTrue);
    expect(eventsContains(dartEvents, 'q', 'ITASK'), isFalse);
    expect(eventsContains(dartEvents, 'B', 'peach'), isTrue);
    expect(eventsContains(dartEvents, 'E', 'peach'), isTrue);
    expect(eventsContains(dartEvents, 'B', 'watermelon'), isTrue);
    expect(eventsContains(dartEvents, 'E', 'watermelon'), isTrue);
    expect(eventsContains(dartEvents, 'B', 'pear'), isTrue);
    expect(eventsContains(dartEvents, 'E', 'pear'), isTrue);
    expect(eventsContains(dartEvents, 's', '123'), isTrue);
    expect(eventsContains(dartEvents, 't', '123'), isTrue);
    expect(eventsContains(dartEvents, 'f', '123'), isTrue);
    // Calculate the time Window of Dart events.
    int origin = timeOrigin(dartEvents);
    int extent = timeDuration(dartEvents, origin);
    // Query for the timeline with the time window for Dart events.
    result = await vm.invokeRpcNoUpgrade('getVMTimeline',
        {'timeOriginMicros': origin, 'timeExtentMicros': extent});
    // Verify that we received fewer events than before.
    expect(result['traceEvents'].length, lessThan(numEvents));
    // Verify that we have the same number of Dart events.
    List dartEvents2 = filterForDartEvents(result['traceEvents']);
    expect(dartEvents2.length, dartEvents.length);
  },
];

main(List<String> args) async {
  // Running the subprocesses of this particular test in opt counter mode
  // will cause it to be slow and cause many compilations.
  //
  // Together with "--complete-timeline" this will create a huge number of
  // timeline events which can, on ia32, cause the process to hit OOM.
  //
  // So we filter out that particular argument.
  final executableArgs = Platform.executableArguments
      .where((String arg) => !arg.contains('optimization-counter-threshold'))
      .toList();

  await runVMTests(args, tests,
      testeeBefore: primeTimeline,
      extraArgs: ['--complete-timeline'],
      executableArgs: executableArgs);
}
