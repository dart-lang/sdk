// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart' hide Timeline;
import 'package:vm_service_protos/vm_service_protos.dart';

import 'common/service_test_common.dart' show mapFromListOfDebugAnnotations;
import 'common/test_helper.dart';

const String shortFile = 'timeline_events_for_completed_microtasks_test.dart';

void primeTimeline() {
  for (int i = 0; i < 5; i++) {
    scheduleMicrotask(() {});
  }
}

Iterable<TrackEvent> extractTrackEventsFromTracePackets(
  List<TracePacket> packets,
) =>
    packets
        .where((packet) => packet.hasTrackEvent())
        .map((packet) => packet.trackEvent);

final tests = <IsolateTest>[
  (VmService service, IsolateRef isolateRef) async {
    final result = await service.getPerfettoVMTimeline();

    final trace = Trace.fromBuffer(base64Decode(result.trace!));
    final packets = trace.packet;
    final mainIsolateMicrotaskEvents =
        extractTrackEventsFromTracePackets(packets)
            .where((event) => event.name == 'Microtask')
            .where((event) {
      final debugAnnotations =
          mapFromListOfDebugAnnotations(event.debugAnnotations);
      return debugAnnotations['isolateId'] == isolateRef.id;
    });
    expect(mainIsolateMicrotaskEvents.length, greaterThanOrEqualTo(5));

    for (final event in mainIsolateMicrotaskEvents) {
      final debugAnnotations =
          mapFromListOfDebugAnnotations(event.debugAnnotations);
      expect(debugAnnotations['microtaskId'], isNotNull);
      expect(
        debugAnnotations['stack trace captured when microtask was enqueued'],
        contains(shortFile),
      );
    }
  },
];

void main([args = const <String>[]]) => runIsolateTests(
      args,
      tests,
      shortFile,
      testeeBefore: primeTimeline,
      extraArgs: ['--profile-microtasks', '--timeline-streams=Microtask'],
    );
