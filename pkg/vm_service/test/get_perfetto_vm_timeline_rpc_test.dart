// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// VMOptions=
// VMOptions=--intern_strings_when_writing_perfetto_timeline

import 'dart:convert';
import 'dart:developer';
import 'dart:io' show Platform;

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart' hide Timeline;
import 'package:vm_service_protos/vm_service_protos.dart';

import 'common/service_test_common.dart' show mapFromListOfDebugAnnotations;
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

class Deinterner {
  final bool stringsShouldBeInterned = Platform.executableArguments
      .contains('--intern_strings_when_writing_perfetto_timeline');

  final Map<int, String> debugAnnotationNames = {};
  final Map<int, String> debugAnnotationStringValues = {};
  final Map<int, String> eventNames = {};
  final Map<int, String> eventCategories = {};

  /// Update the state of the interning dictionaries using [InternedData]
  /// from the given packet.
  void update(TracePacket packet) {
    // Clear the state if [TracePacket.sequenceFlags] instructs us to do so.
    if (packet.sequenceFlags &
            TracePacket_SequenceFlags.SEQ_INCREMENTAL_STATE_CLEARED.value !=
        0) {
      debugAnnotationNames.clear();
      debugAnnotationStringValues.clear();
      eventNames.clear();
      eventCategories.clear();
    }

    if (!packet.hasInternedData()) {
      return;
    }

    final internedData = packet.internedData;
    for (var e in internedData.debugAnnotationNames) {
      debugAnnotationNames[e.iid.toInt()] = e.name;
    }
    for (var e in internedData.debugAnnotationStringValues) {
      debugAnnotationStringValues[e.iid.toInt()] = utf8.decode(e.str);
    }
    for (var e in internedData.eventNames) {
      eventNames[e.iid.toInt()] = e.name;
    }
    for (var e in internedData.eventCategories) {
      eventCategories[e.iid.toInt()] = e.name;
    }
  }

  /// Deintern contents of the given [TrackEvent].
  void deintern(TrackEvent event) {
    if (event.hasName()) {
      expect(stringsShouldBeInterned, isFalse);
    }
    if (event.hasNameIid()) {
      expect(stringsShouldBeInterned, isTrue);
      expect(event.hasName(), isFalse);
      event.name = eventNames[event.nameIid.toInt()]!;
      event.clearNameIid();
    }

    if (event.categories.isNotEmpty) {
      expect(stringsShouldBeInterned, isFalse);
    }
    if (event.categoryIids.isNotEmpty) {
      expect(stringsShouldBeInterned, isTrue);
      expect(event.categories.isEmpty, isTrue);
      for (var iid in event.categoryIids) {
        event.categories.add(eventCategories[iid.toInt()]!);
      }
      event.categoryIids.clear();
    }
    for (var annotation in event.debugAnnotations) {
      if (annotation.hasStringValue()) {
        expect(stringsShouldBeInterned, isFalse);
      }
      if (annotation.hasStringValueIid()) {
        expect(stringsShouldBeInterned, isTrue);
        expect(annotation.hasStringValue(), isFalse);
        annotation.stringValue =
            debugAnnotationStringValues[annotation.stringValueIid.toInt()]!;
        annotation.clearStringValueIid();
      }

      if (annotation.hasName()) {
        expect(stringsShouldBeInterned, isFalse);
      }
      if (annotation.hasNameIid()) {
        expect(stringsShouldBeInterned, isTrue);
        expect(annotation.hasName(), isFalse);
        annotation.name = debugAnnotationNames[annotation.nameIid.toInt()]!;
        annotation.clearNameIid();
      }
    }
  }
}

List<TrackEvent> extractTrackEventsFromTracePackets(
  List<TracePacket> packets,
) {
  final result = <TrackEvent>[];
  final deinterner = Deinterner();
  for (var packet in packets) {
    deinterner.update(packet);
    if (packet.hasTrackEvent()) {
      deinterner.deintern(packet.trackEvent);
      result.add(packet.trackEvent);
    }
  }
  return result;
}

void checkThatAllEventsHaveIsolateNumbers(Iterable<TrackEvent> events) {
  for (final event in events) {
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
