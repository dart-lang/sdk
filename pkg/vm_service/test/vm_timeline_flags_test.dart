// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'vm_timeline_flags_lib.dart' as testee_lib;

bool isDart(TimelineEvent event) => event.json!['cat'] == 'Dart';
bool isMetaData(TimelineEvent event) => event.json!['ph'] == 'M';
bool isNotMetaData(TimelineEvent event) => !isMetaData(event);
bool isNotDartAndMetaData(TimelineEvent event) =>
    !isDart(event) && !isMetaData(event);

List<TimelineEvent> filterEvents(
  List<TimelineEvent> events,
  bool Function(TimelineEvent) filter,
) {
  return events.where(filter).toList();
}

int dartEventCount = 0;

void main([List<String> args = const <String>[]]) {
  IsolateTestHarness('vm_timeline_flags_lib.dart', args)
      .hasStoppedAtBreakpoint()
      .stoppedAtLine('LINE_B')
      .addCustomTest((VmService service, IsolateRef isolateRef) async {
        // Get the flags.
        final flags = await service.getVMTimelineFlags();
        // Confirm that 'Dart' is available.
        expect(flags.availableStreams!.contains('Dart'), true);
        // Confirm that nothing is being recorded.
        expect(flags.recordedStreams, isEmpty);
      })
      .addCustomTest((VmService service, IsolateRef isolateRef) async {
        // Get the timeline.
        final timeline = await service.getVMTimeline();
        // Confirm that it has no non-meta data events.
        expect(filterEvents(timeline.traceEvents!, isNotMetaData), isEmpty);
      })
      .addCustomTest((VmService service, IsolateRef isolateRef) async {
        final completer = Completer<void>();
        late final StreamSubscription sub;
        sub = service.onTimelineEvent.listen((event) async {
          expect(event.kind, EventKind.kTimelineStreamSubscriptionsUpdate);
          expect(event.updatedStreams!.length, 1);
          expect(event.updatedStreams!.first, 'Dart');
          await service.streamCancel(EventStreams.kTimeline);
          await sub.cancel();
          completer.complete();
        });
        await service.streamListen(EventStreams.kTimeline);

        // Enable the Dart category.
        await service.setVMTimelineFlags(['Dart']);
        await completer.future;
      })
      .addCustomTest((VmService service, IsolateRef isolateRef) async {
        // Get the flags.
        final flags = await service.getVMTimelineFlags();
        // Confirm that only Dart is being recorded.
        expect(flags.recordedStreams!.length, 1);
        expect(flags.recordedStreams!.contains('Dart'), true);
      })
      .resumeIsolate()
      .hasStoppedAtBreakpoint()
      .stoppedAtLine('LINE_B')
      .addCustomTest((VmService service, IsolateRef isolateRef) async {
        // Get the timeline.
        final timeline = await service.getVMTimeline();
        final traceEvents = timeline.traceEvents!;
        // Confirm that Dart events are added.
        expect(filterEvents(traceEvents, isDart), isNotEmpty);
        // Confirm that zero non-Dart events are added.
        expect(filterEvents(traceEvents, isNotDartAndMetaData), isEmpty);
      })
      .addCustomTest((VmService service, IsolateRef isolateRef) async {
        final completer = Completer<void>();
        late final StreamSubscription sub;
        sub = service.onTimelineEvent.listen((event) async {
          expect(event.kind, EventKind.kTimelineStreamSubscriptionsUpdate);
          expect(event.updatedStreams!.length, 0);
          await service.streamCancel(EventStreams.kTimeline);
          await sub.cancel();
          completer.complete();
        });
        await service.streamListen(EventStreams.kTimeline);

        // Disable the Dart category.
        await service.setVMTimelineFlags([]);
        await completer.future;

        // Grab the timeline and remember the number of Dart events.
        final timeline = await service.getVMTimeline();
        dartEventCount = filterEvents(timeline.traceEvents!, isDart).length;
      })
      .addCustomTest((VmService service, IsolateRef isolateRef) async {
        // Get the flags.
        final flags = await service.getVMTimelineFlags();
        // Confirm that nothing is being recorded.
        expect(flags.recordedStreams, isEmpty);
      })
      .resumeIsolate()
      .hasStoppedAtBreakpoint()
      .stoppedAtLine('LINE_B')
      .addCustomTest((VmService service, IsolateRef isolateRef) async {
        // Grab the timeline and verify that we haven't added any new Dart events.
        final timeline = await service.getVMTimeline();
        final traceEvents = timeline.traceEvents!;
        final updatedCount = filterEvents(traceEvents, isDart).length;
        expect(updatedCount, dartEventCount);

        // Confirm that zero non-Dart events are added.
        expect(filterEvents(traceEvents, isNotDartAndMetaData), isEmpty);
      })
      .run(testeeMain: testee_lib.main);
}
