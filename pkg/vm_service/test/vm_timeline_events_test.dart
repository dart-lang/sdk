// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'vm_timeline_events_lib.dart' as testee_lib;

bool isDart(TimelineEvent event) => event.json!['cat'] == 'Dart';

List filterEvents(
  List<TimelineEvent> events,
  bool Function(TimelineEvent) filter,
) {
  return events.where(filter).toList();
}

void main([args = const <String>[]]) {
  final completer = Completer<void>();
  int eventCount = 0;

  void onTimelineEvent(Event event) {
    if (event.kind != EventKind.kTimelineEvents) {
      return;
    }
    eventCount++;
    expect(filterEvents(event.timelineEvents!, isDart).length, greaterThan(0));
    if (eventCount == 5) {
      completer.complete();
    }
  }

  IsolateTestHarness(
    'vm_timeline_events_lib.dart',
    args,
  ).addCustomTest((VmService service, IsolateRef isolateRef) async {
    // Subscribe to the Timeline stream.
    service.onTimelineEvent.listen(onTimelineEvent);
    await service.streamListen(EventStreams.kTimeline);
  }).addCustomTest((VmService service, IsolateRef isolateRef) async {
    // Ensure we don't get any events before enabling Dart.
    await Future.delayed(Duration(seconds: 2));
    expect(eventCount, 0);
  }).addCustomTest((VmService service, IsolateRef isolateRef) async {
    // Get the flags.
    final flags = await service.getVMTimelineFlags();
    // Confirm that 'Dart' is available.
    expect(flags.availableStreams!.contains('Dart'), true);
    // Confirm that nothing is being recorded.
    expect(flags.recordedStreams, isEmpty);
  }).addCustomTest((VmService service, IsolateRef isolateRef) async {
    // Enable the Dart category.
    await service.setVMTimelineFlags(['Dart']);
  }).addCustomTest((VmService service, IsolateRef isolateRef) async {
    // Wait to receive events.
    await completer.future;
    await service.streamCancel(EventStreams.kTimeline);
  }).run(testeeMain: testee_lib.main);
}
