// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart' hide Timeline;
import 'package:vm_service_protos/vm_service_protos.dart';

import 'common/service_test_common.dart';
import 'common/test_helper.dart';

void testeeMain() {
  print('Testee doing something.');
  final stopwatch = Stopwatch();
  stopwatch.start();
  while (stopwatch.elapsedMilliseconds < 10000) {}
  stopwatch.stop();
  print('Testee did something.');
}

final tests = <IsolateTest>[
  hasStoppedAtExit,
  (VmService service, IsolateRef isolateRef) async {
    // The purpose of this test is to ensure that when the `--profile-startup`
    // CLI flag is set, the profiler discards any samples collected after when
    // the sample buffer has filled up. This test does not check the contents of
    // the samples returned by [service.getPerfettoCpuSamples],
    // `get_perfetto_cpu_samples_rpc_test` does.
    //
    // `--max-profile-depth=2` and `--sample-buffer-duration=1` are passed to
    // [runIsolateTests] below, and [testeeMain] spins for 10 seconds, so the
    // profiler sample buffer should be full once [testeeMain] has finished
    // running. If `--profile-startup` is working as intended, then the two
    // [service.getPerfettoCpuSamples] calls below should deliver consistent
    // results, because no samples will ever be overwritten by newer ones.

    final result = await service.getPerfettoCpuSamples(isolateRef.id!);
    final trace = Trace.fromBuffer(base64Decode(result.samples!));
    final packets = trace.packet;
    final perfSamples = extractPerfSamplesFromTracePackets(packets);
    expect(perfSamples.length, isPositive);

    // Calculate the time window of events.
    final timeOriginNanos = computeTimeOriginNanos(packets);
    final timeExtentNanos = computeTimeExtentNanos(packets, timeOriginNanos);
    print(
      'Requesting CPU samples within the filter window of '
      'timeOriginNanos=$timeOriginNanos and timeExtentNanos=$timeExtentNanos',
    );
    // Query for the samples within the time window.
    final filteredResult = await service.getPerfettoCpuSamples(
      isolateRef.id!,
      timeOriginMicros: timeOriginNanos ~/ 1000,
      timeExtentMicros: timeExtentNanos ~/ 1000,
    );
    final filteredTrace =
        Trace.fromBuffer(base64Decode(filteredResult.samples!));
    final filteredPackets = filteredTrace.packet;
    final filteredTraceTimeOriginNanos =
        computeTimeOriginNanos(filteredPackets);
    final filteredTraceTimeExtentNanos = computeTimeExtentNanos(
      filteredPackets,
      filteredTraceTimeOriginNanos,
    );
    print(
      'The returned CPU samples span a time window of '
      'timeOriginNanos=$filteredTraceTimeOriginNanos and '
      'timeExtentNanos=$filteredTraceTimeExtentNanos',
    );
    // Verify that [result] and [filteredResult] have the same number of
    // [PerfSample]s.
    expect(
      extractPerfSamplesFromTracePackets(filteredPackets).length,
      perfSamples.length,
    );

    // The profiler gets another chance to collect samples when handling each
    // `getPerfettoCpuSamples` request, so we can verify that the sample buffer
    // was indeed full when the first `getPerfettoCpuSamples` request was made
    // by making another unfiltered request, and checking that the number of
    // samples in the response is the same as the number in the first response.
    final secondUnfilteredResult =
        await service.getPerfettoCpuSamples(isolateRef.id!);
    final secondUnfilteredTrace =
        Trace.fromBuffer(base64Decode(secondUnfilteredResult.samples!));
    expect(
      extractPerfSamplesFromTracePackets(secondUnfilteredTrace.packet).length,
      perfSamples.length,
    );
  },
];

Future<void> main([args = const <String>[]]) => runIsolateTests(
      args,
      tests,
      'profile_startup_cli_flag_test.dart',
      testeeBefore: testeeMain,
      pauseOnExit: true,
      extraArgs: [
        '--profiler',
        '--profile-startup',
        '--profile-period=2000',
        '--max-profile-depth=2',
        '--sample-buffer-duration=1',
      ],
    );
