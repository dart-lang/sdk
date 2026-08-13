// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart' hide Timeline;
import 'package:vm_service_protos/vm_service_protos.dart';

import 'common/service_test_common.dart'
    show IsolateTestHarness, mapFromListOfDebugAnnotations;
import 'timeline_events_for_completed_microtasks_lib.dart' as testee_lib;

Iterable<TrackEvent> extractTrackEventsFromTracePackets(
  List<TracePacket> packets,
) =>
    packets
        .where((packet) => packet.hasTrackEvent())
        .map((packet) => packet.trackEvent);

Future<void> testPerfettoVMTimeline(
  VmService service,
  IsolateRef isolateRef,
) async {
  final result = await service.getPerfettoVMTimeline();

  final trace = Trace.fromBuffer(base64Decode(result.trace!));
  final packets = trace.packet;
  final mainIsolateMicrotaskEvents = extractTrackEventsFromTracePackets(packets)
      .where((event) => event.name == 'Microtask')
      .where((event) {
    final debugAnnotations =
        mapFromListOfDebugAnnotations(event.debugAnnotations);
    return debugAnnotations['isolateId'] == isolateRef.id;
  });

  final testMicrotaskEvents = mainIsolateMicrotaskEvents.where((event) {
    final debugAnnotations =
        mapFromListOfDebugAnnotations(event.debugAnnotations);
    final stackTrace =
        debugAnnotations['stack trace captured when microtask was enqueued'];
    return stackTrace != null &&
        stackTrace
            .contains('timeline_events_for_completed_microtasks_lib.dart');
  }).toList();

  expect(testMicrotaskEvents.length, greaterThanOrEqualTo(5));

  for (final event in testMicrotaskEvents) {
    final debugAnnotations =
        mapFromListOfDebugAnnotations(event.debugAnnotations);
    expect(debugAnnotations['microtaskId'], isNotNull);
    expect(
      debugAnnotations['stack trace captured when microtask was enqueued'],
      contains('timeline_events_for_completed_microtasks_lib.dart'),
    );
  }
}

void main([args = const <String>[]]) => IsolateTestHarness(
      'timeline_events_for_completed_microtasks_lib.dart',
      args,
    ).addCustomTest(testPerfettoVMTimeline).run(
      testeeMain: testee_lib.main,
      extraArgs: ['--profile-microtasks', '--timeline-streams=Microtask'],
    );
