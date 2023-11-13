// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart' hide Timeline;
import 'package:vm_service_protos/vm_service_protos.dart';

import 'common/test_helper.dart';

int computeTimeOriginNanos(List<TracePacket> packets) {
  final packetsWithPerfSamples =
      packets.where((packet) => packet.hasPerfSample()).toList();
  if (packetsWithPerfSamples.isEmpty) {
    return 0;
  }
  int smallest = packetsWithPerfSamples.first.timestamp.toInt();
  for (int i = 0; i < packetsWithPerfSamples.length; i++) {
    if (packetsWithPerfSamples[i].timestamp < smallest) {
      smallest = packetsWithPerfSamples[i].timestamp.toInt();
    }
  }
  return smallest;
}

int computeTimeExtentNanos(List<TracePacket> packets, int timeOrigin) {
  final packetsWithPerfSamples =
      packets.where((packet) => packet.hasPerfSample()).toList();
  if (packetsWithPerfSamples.isEmpty) {
    return 0;
  }
  int largestExtent = packetsWithPerfSamples[0].timestamp.toInt() - timeOrigin;
  for (var i = 0; i < packetsWithPerfSamples.length; i++) {
    int duration = packetsWithPerfSamples[i].timestamp.toInt() - timeOrigin;
    if (duration > largestExtent) {
      largestExtent = duration;
    }
  }
  return largestExtent;
}

Iterable<PerfSample> extractPerfSamplesFromTracePackets(
    List<TracePacket> packets) {
  return packets
      .where((packet) => packet.hasPerfSample())
      .map((packet) => packet.perfSample);
}

final tests = <IsolateTest>[
  (VmService service, IsolateRef isolateRef) async {
    final result = await service.getPerfettoCpuSamples(isolateRef.id!);
    expect(result.type, 'PerfettoCpuSamples');
    expect(result.samplePeriod, isPositive);
    expect(result.maxStackDepth, isPositive);
    expect(result.sampleCount, isPositive);
    expect(result.timeOriginMicros, isPositive);
    expect(result.timeExtentMicros, isPositive);
    expect(result.pid, isNotNull);

    final trace = Trace.fromBuffer(base64Decode(result.samples!));
    final packets = trace.packet;
    int frameCount = 0;
    int callstackCount = 0;
    int perfSampleCount = 0;
    for (final packet in packets) {
      if (packet.hasInternedData()) {
        frameCount += packet.internedData.frames.length;
        callstackCount += packet.internedData.callstacks.length;
      }
      if (packet.hasPerfSample()) {
        perfSampleCount += 1;
      }
    }
    expect(frameCount, isPositive);
    expect(callstackCount, isPositive);
    expect(perfSampleCount, callstackCount);

    // Calculate the time window of events.
    final timeOriginNanos = computeTimeOriginNanos(packets);
    final timeExtentNanos = computeTimeExtentNanos(packets, timeOriginNanos);
    // Query for the samples within the time window.
    final filteredResult = await service.getPerfettoCpuSamples(isolateRef.id!,
        timeOriginMicros: timeOriginNanos ~/ 1000,
        timeExtentMicros: timeExtentNanos ~/ 1000);
    // Verify that we have the same number of [PerfSample]s.
    final filteredTrace =
        Trace.fromBuffer(base64Decode(filteredResult.samples!));
    expect(extractPerfSamplesFromTracePackets(filteredTrace.packet).length,
        extractPerfSamplesFromTracePackets(packets).length);
  },
];

main([args = const <String>[]]) async {
  await runIsolateTests(args, tests, 'get_perfetto_cpu_samples_rpc_test.dart',
      extraArgs: ['--profiler=true']);
}
