// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// VMOptions=
// VMOptions=--timeline-recorder=none

import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:expect/expect.dart';
import 'package:path/path.dart' as path;
import 'package:vm_service_protos/vm_service_protos.dart';

import '../../../../pkg/perf_witness/test/common/test_utils.dart';
import 'use_flag_test_helper.dart';

@pragma('vm:never-inline')
int workload() {
  final sw = Stopwatch()..start();
  return Timeline.timeSync('workload-loop', () {
    var sum = 0;
    while (sw.elapsedMilliseconds < 500) {
      final l = <int>[];
      for (var i = 0; i < 10000; i++) {
        l.add(i * i);
      }
      sum += l[50];
    }
    return sum;
  });
}

Future<void> testPerfettoRecorder({
  required String tempDir,
  required bool withProfiler,
}) async {
  final perfettoTimeline = File(
    path.join(tempDir, 'timeline${withProfiler ? '-p' : ''}.pb'),
  );

  Expect.isFalse(perfettoTimeline.existsSync());

  NativeRuntime.streamTimelineTo(
    .perfetto,
    path: perfettoTimeline.path,
    enableProfiler: withProfiler,
  );
  workload();
  NativeRuntime.stopStreamingTimeline();

  Expect.isTrue(
    perfettoTimeline.existsSync(),
    '$perfettoTimeline does not exist',
  );

  final traceData = TraceData.fromBytes(perfettoTimeline.readAsBytesSync());

  Expect.isTrue(
    traceData.seenEvents.containsAll(['workload-loop', 'CollectNewGeneration']),
  );

  Expect.isTrue(
    traceData.seenTrackDescriptors.containsAll(traceData.seenTracks),
    '''
expected to see a track descriptor for every track:
  seen descriptors    ${traceData.seenTrackDescriptors}
  seen tracks         ${traceData.seenTracks}
  missing descriptors ${traceData.seenTracks.difference(traceData.seenTrackDescriptors)}
''',
  );

  if (withProfiler) {
    Expect.isTrue(
      traceData.hasSeenStack(['main', 'workload', 'Timeline.timeSync']),
    );
  } else {
    Expect.isEmpty(traceData.seenStacks);
  }
}

Future<void> testChromeRecorder({required String tempDir}) async {
  final chromeTimeline = File(path.join(tempDir, 'timeline.json'));

  Expect.isFalse(chromeTimeline.existsSync());

  NativeRuntime.streamTimelineTo(.chrome, path: chromeTimeline.path);
  workload();
  NativeRuntime.stopStreamingTimeline();

  Expect.isTrue(chromeTimeline.existsSync(), '$chromeTimeline does not exist');

  final timelineData =
      jsonDecode(chromeTimeline.readAsStringSync()) as List<dynamic>;
  final event = timelineData.firstWhereOrNull(
    (e) => e['name'] == 'workload-loop',
  );
  Expect.isNotNull(event);
  Expect.equals('Dart', event!['cat']);
  Expect.equals('B', event!['ph']);
}

void main() async {
  await withTempDir('stream_timeline_to_test', (tempDir) async {
    await testPerfettoRecorder(tempDir: tempDir, withProfiler: true);
    await testPerfettoRecorder(tempDir: tempDir, withProfiler: false);
    await testChromeRecorder(tempDir: tempDir);

    // Perfetto and Chrome recorders require file path for output.
    Expect.throws<ArgumentError>(
      () => NativeRuntime.streamTimelineTo(.perfetto),
    );
    Expect.throws<ArgumentError>(() => NativeRuntime.streamTimelineTo(.chrome));

    // Systrace requires no-path.
    Expect.throws<ArgumentError>(
      () => NativeRuntime.streamTimelineTo(.systrace, path: 'whatever'),
    );
    Expect.isFalse(File('whatever').existsSync());

    // Only Android, Fuchsia, Linux and Mac OS X support systrace recorder.
    if (!(Platform.isAndroid ||
        Platform.isFuchsia ||
        Platform.isLinux ||
        Platform.isMacOS)) {
      Expect.throws<ArgumentError>(
        () => NativeRuntime.streamTimelineTo(.systrace),
      );
    }

    // Systrace and Chrome recorders do not support profiler.
    Expect.throws<ArgumentError>(
      () => NativeRuntime.streamTimelineTo(.systrace, enableProfiler: true),
    );
    Expect.throws<ArgumentError>(
      () => NativeRuntime.streamTimelineTo(
        .chrome,
        path: 'whatever',
        enableProfiler: true,
      ),
    );
    Expect.isFalse(File('whatever').existsSync());
  });
}
