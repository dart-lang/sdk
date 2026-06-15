// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'get_vm_timeline_rpc_lib.dart' as testee_lib;

List<TimelineEvent> filterForDartEvents(List<TimelineEvent> events) {
  return events.where((event) => event.json!['cat'] == 'Dart').toList();
}

bool mapContains(Map<String, dynamic> map, Map submap) {
  for (final key in submap.keys) {
    if (map[key] != submap[key]) {
      return false;
    }
  }
  return true;
}

bool eventsContains(
  List<TimelineEvent> events,
  String phase,
  String name, [
  Map? arguments,
]) {
  for (final timelineEvent in events) {
    final event = timelineEvent.json!;
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

int timeOrigin(List<TimelineEvent> events) {
  if (events.isEmpty) {
    return 0;
  }
  int smallest = events.first.json!['ts'];
  for (final timelineEvent in events) {
    final event = timelineEvent.json!;
    if (event['ts'] < smallest) {
      smallest = event['ts'];
    }
  }
  return smallest;
}

int timeDuration(List<TimelineEvent> events, int timeOrigin) {
  if (events.isEmpty) {
    return 0;
  }
  int biggestDuration = events.first.json!['ts'] - timeOrigin;
  for (final timelineEvent in events) {
    final event = timelineEvent.json!;
    final duration = event['ts'] - timeOrigin;
    if (duration > biggestDuration) {
      biggestDuration = duration;
    }
  }
  return biggestDuration;
}

void allEventsHaveIsolateNumber(List<TimelineEvent> events) {
  for (final timelineEvent in events) {
    final event = timelineEvent.json!;
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
    if (event['name'] == 'RSS' && event['ph'] == 'C') {
      // Skip RSS events, which don't have an isolate or isolate group.
      continue;
    }
    if (event['cat'] == 'Embedder' &&
        (event['name'] == 'DFE::ReadScript' ||
            event['name'] == 'CreateIsolateGroupAndSetupHelper' ||
            event['name'] == 'CreateAndSetupDartDevIsolate')) {
      continue;
    }
    final arguments = event['args'];
    expect(arguments, isA<Map>());
    expect(arguments['isolateGroupId'], isA<String>());
    if (!const ['GC', 'Compiler', 'CompilerVerbose'].contains(event['cat']) &&
        !const [
          'FinishTopLevelClassLoading',
          'FinishClassLoading',
          'ProcessPendingClasses',
        ].contains(event['name'])) {
      expect(arguments['isolateId'], isA<String>());
    }
  }
}

// NOTE: the original service test compiled the target program to kernel
// first, with the following comment providing an explanation:
//
// We first compile the testee to kernel and run the subprocess on the kernel
// file. That avoids cases where the testee has to run a lot of code in the
// kernel-isolate (e.g. due to ia32's kernel-service not being app-jit
// trained). We do that because otherwise the --complete-timeline will
// collect a lot of data, possibly leading to OOMs or timeouts.
//
// If this test times out on ia32, we may need to do the same.
void main([args = const <String>[]]) =>
    VMTestHarness('get_vm_timeline_rpc_lib.dart', args).addTest(
      (VmService service) async {
        var timeline = await service.getVMTimeline();
        var traceEvents = timeline.traceEvents!;
        final int numEvents = traceEvents.length;
        final dartEvents = filterForDartEvents(traceEvents);
        expect(dartEvents.length, greaterThanOrEqualTo(11));
        allEventsHaveIsolateNumber(dartEvents);
        allEventsHaveIsolateNumber(traceEvents);
        expect(
          eventsContains(dartEvents, 'i', 'ISYNC', {'fruit': 'banana'}),
          isTrue,
        );
        expect(eventsContains(dartEvents, 'B', 'apple'), isTrue);
        expect(eventsContains(dartEvents, 'E', 'apple'), isTrue);
        expect(
          eventsContains(
            dartEvents,
            'b',
            'TASK1',
            {
              'filterKey': 'testFilter',
              'task1-start-key': 'task1-start-value',
              'parentId': 42.toRadixString(16),
            },
          ),
          isTrue,
        );
        expect(
          eventsContains(
            dartEvents,
            'e',
            'TASK1',
            {
              'filterKey': 'testFilter',
              'task1-finish-key': 'task1-finish-value',
            },
          ),
          isTrue,
        );
        expect(
          eventsContains(
            dartEvents,
            'n',
            'ITASK',
            {
              'filterKey': 'testFilter',
              'task1-instant-key': 'task1-instant-value',
            },
          ),
          isTrue,
        );
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
        final origin = timeOrigin(dartEvents);
        final extent = timeDuration(dartEvents, origin);
        // Query for the timeline with the time window for Dart events.
        timeline = await service.getVMTimeline(
          timeOriginMicros: origin,
          timeExtentMicros: extent,
        );
        traceEvents = timeline.traceEvents!;
        // Verify that we received fewer events than before.
        expect(traceEvents.length, lessThan(numEvents));
        // Verify that we have the same number of Dart events.
        final dartEvents2 = filterForDartEvents(traceEvents);
        expect(dartEvents2.length, dartEvents.length);
      },
    ).run(
      testeeMain: testee_lib.main,
      extraArgs: ['--complete-timeline'],
    );
