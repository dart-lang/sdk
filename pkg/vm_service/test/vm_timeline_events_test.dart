// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:developer' as dev;

import 'package:vm_service/vm_service.dart';
import 'package:test/test.dart';

import 'common/test_helper.dart';

Future<void> primeDartTimeline() async {
  while (true) {
    dev.Timeline.startSync('apple');
    dev.Timeline.finishSync();
    // Give the VM a chance to send the timeline events. This test is
    // significantly slower if we loop without yielding control after each
    // iteration.
    await Future.delayed(const Duration(milliseconds: 1));
  }
}

bool isDart(TimelineEvent event) => event.json!['cat'] == 'Dart';

List filterEvents(
  List<TimelineEvent> events,
  bool Function(TimelineEvent) filter,
) {
  return events.where(filter).toList();
}

final completer = Completer<void>();
int eventCount = 0;

void onTimelineEvent(Event event) {
  if (event.kind != EventKind.kTimelineEvents) {
    return;
  }
  eventCount++;
  expect(filterEvents(event.timelineEvents!, isDart).length, greaterThan(0));
  if (eventCount == 5) {
    completer.complete(eventCount);
  }
}

final tests = <IsolateTest>[
  (VmService service, IsolateRef isolateRef) async {
    // Subscribe to the Timeline stream.
    service.onTimelineEvent.listen(onTimelineEvent);
    await service.streamListen(EventStreams.kTimeline);
  },
  (VmService service, IsolateRef isolateRef) async {
    // Ensure we don't get any events before enabling Dart.
    await Future.delayed(new Duration(seconds: 2));
    expect(eventCount, 0);
  },
  (VmService service, IsolateRef isolateRef) async {
    // Get the flags.
    final flags = await service.getVMTimelineFlags();
    // Confirm that 'Dart' is available.
    expect(flags.availableStreams!.contains('Dart'), true);
    // Confirm that nothing is being recorded.
    expect(flags.recordedStreams, isEmpty);
  },
  (VmService service, IsolateRef isolateRef) async {
    // Enable the Dart category.
    await service.setVMTimelineFlags(['Dart']);
  },
  (VmService service, IsolateRef isolateRef) async {
    // Wait to receive events.
    await completer.future;
    await service.streamCancel(EventStreams.kTimeline);
  },
];

void main([args = const <String>[]]) => runIsolateTests(
      args,
      tests,
      'vm_timeline_events_test.dart',
      testeeConcurrent: primeDartTimeline,
    );
