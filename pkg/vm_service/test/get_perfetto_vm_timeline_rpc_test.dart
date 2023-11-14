// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';
import 'dart:convert';
import 'dart:developer';

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart' hide Timeline;
import 'package:vm_service_protos/vm_service_protos.dart';

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

Iterable<TrackEvent> extractTrackEventsFromTracePackets(
  List<TracePacket> packets,
) {
  return packets
      .where((packet) => packet.hasTrackEvent())
      .map((packet) => packet.trackEvent);
}

Map<String, String> mapFromListOfDebugAnnotations(
  List<DebugAnnotation> debugAnnotations,
) {
  return HashMap.fromEntries(
    debugAnnotations.map((a) {
      if (a.hasStringValue()) {
        return MapEntry(a.name, a.stringValue);
      } else if (a.hasLegacyJsonValue()) {
        return MapEntry(a.name, a.legacyJsonValue);
      } else {
        throw 'We should not be writing annotations without values';
      }
    }),
  );
}

void checkThatAllEventsHaveIsolateNumbers(Iterable<TrackEvent> events) {
  for (TrackEvent event in events) {
    final debugAnnotations =
        mapFromListOfDebugAnnotations(event.debugAnnotations);
    expect(debugAnnotations['isolateGroupId'], isNotNull);
    expect(debugAnnotations['isolateId'], isNotNull);
  }
}

bool mapContains(Map<String, dynamic> map, Map<String, String> submap) {
  for (final key in submap.keys) {
    if (map[key] != submap[key]) {
      return false;
    }
  }
  return true;
}

int countNumberOfEventsOfType(
  Iterable<TrackEvent> events,
  TrackEvent_Type type,
) {
  return events.where((event) {
    return event.type == type;
  }).length;
}

bool eventsContains(
  Iterable<TrackEvent> events,
  TrackEvent_Type type, {
  String? name,
  int? flowId,
  Map<String, String>? arguments,
}) {
  return events.any((event) {
    if (event.type != type) {
      return false;
    }
    if (name != null && event.name != name) {
      return false;
    }
    if (flowId != null &&
        (event.flowIds.isEmpty || event.flowIds.first != flowId)) {
      return false;
    }
    if (event.debugAnnotations.isEmpty) {
      return arguments == null;
    } else {
      final Map<String, dynamic> dartArguments = jsonDecode(
        mapFromListOfDebugAnnotations(
          event.debugAnnotations,
        )['Dart Arguments']!,
      );
      if (arguments == null) {
        return dartArguments.isEmpty;
      } else {
        return mapContains(dartArguments, arguments);
      }
    }
  });
}

int computeTimeOriginNanos(List<TracePacket> packets) {
  final packetsWithEvents =
      packets.where((packet) => packet.hasTrackEvent()).toList();
  if (packetsWithEvents.isEmpty) {
    return 0;
  }
  int smallest = packetsWithEvents.first.timestamp.toInt();
  for (int i = 0; i < packetsWithEvents.length; i++) {
    if (packetsWithEvents[i].timestamp < smallest) {
      smallest = packetsWithEvents[i].timestamp.toInt();
    }
  }
  return smallest;
}

int computeTimeExtentNanos(List<TracePacket> packets, int timeOrigin) {
  final packetsWithEvents =
      packets.where((packet) => packet.hasTrackEvent()).toList();
  if (packetsWithEvents.isEmpty) {
    return 0;
  }
  int largestExtent = packetsWithEvents[0].timestamp.toInt() - timeOrigin;
  for (var i = 0; i < packetsWithEvents.length; i++) {
    final int duration = packetsWithEvents[i].timestamp.toInt() - timeOrigin;
    if (duration > largestExtent) {
      largestExtent = duration;
    }
  }
  return largestExtent;
}

final tests = <VMTest>[
  (VmService service) async {
    final result = await service.getPerfettoVMTimeline();
    expect(result.type, 'PerfettoTimeline');
    expect(result.timeOriginMicros, isPositive);
    expect(result.timeExtentMicros, isPositive);

    final trace = Trace.fromBuffer(base64Decode(result.trace!));
    final packets = trace.packet;
    final events = extractTrackEventsFromTracePackets(packets);
    expect(events.length, greaterThanOrEqualTo(12));
    checkThatAllEventsHaveIsolateNumbers(events);
    expect(
      countNumberOfEventsOfType(events, TrackEvent_Type.TYPE_SLICE_BEGIN),
      countNumberOfEventsOfType(events, TrackEvent_Type.TYPE_SLICE_END),
    );
    expect(
      eventsContains(
        events,
        TrackEvent_Type.TYPE_INSTANT,
        name: 'ISYNC',
        arguments: {'fruit': 'banana'},
      ),
      true,
    );
    expect(
      eventsContains(events, TrackEvent_Type.TYPE_SLICE_BEGIN, name: 'apple'),
      true,
    );
    expect(
      eventsContains(
        events,
        TrackEvent_Type.TYPE_SLICE_BEGIN,
        name: 'TASK1',
        arguments: {
          'filterKey': 'testFilter',
          'task1-start-key': 'task1-start-value',
          'parentId': 42.toRadixString(16),
        },
      ),
      true,
    );
    expect(
      eventsContains(
        events,
        TrackEvent_Type.TYPE_SLICE_END,
        arguments: {
          'filterKey': 'testFilter',
          'task1-finish-key': 'task1-finish-value',
        },
      ),
      true,
    );
    expect(
      eventsContains(
        events,
        TrackEvent_Type.TYPE_INSTANT,
        name: 'ITASK',
        arguments: {
          'filterKey': 'testFilter',
          'task1-instant-key': 'task1-instant-value',
        },
      ),
      true,
    );
    expect(
      eventsContains(
        events,
        TrackEvent_Type.TYPE_SLICE_BEGIN,
        name: 'peach',
        flowId: 123,
      ),
      true,
    );
    expect(
      eventsContains(
        events,
        TrackEvent_Type.TYPE_SLICE_BEGIN,
        name: 'watermelon',
        flowId: 123,
      ),
      true,
    );
    expect(
      eventsContains(
        events,
        TrackEvent_Type.TYPE_SLICE_BEGIN,
        name: 'pear',
        flowId: 123,
      ),
      true,
    );

    // Calculate the time window of events.
    final timeOriginNanos = computeTimeOriginNanos(packets);
    final timeExtentNanos = computeTimeExtentNanos(packets, timeOriginNanos);
    // Query for the timeline with the time window.
    final filteredResult = await service.getPerfettoVMTimeline(
      timeOriginMicros: timeOriginNanos ~/ 1000,
      timeExtentMicros: timeExtentNanos ~/ 1000,
    );
    // Verify that we have the same number of events.
    final filteredTrace = Trace.fromBuffer(base64Decode(filteredResult.trace!));
    expect(
      extractTrackEventsFromTracePackets(filteredTrace.packet).length,
      events.length,
    );
  },
];

void main([args = const <String>[]]) => runVMTests(
      args, tests, 'get_perfetto_vm_timeline_rpc_test.dart',
      testeeBefore: primeTimeline,
      // TODO(derekx): runtime/observatory/tests/service/get_vm_timeline_rpc_test
      // runs with --complete-timeline, but for performance reasons, we cannot do
      // the same until this [runVMTests] method supports the [executableArgs] and
      // [compileToKernelFirst] parameters.
      extraArgs: ['--timeline-streams=Dart'],
    );
