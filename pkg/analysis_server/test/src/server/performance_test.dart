// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server_plugin/src/correction/performance.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../lsp/server_abstract.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AdditionalTimingTest);
  });
}

@reflectiveTest
class AdditionalTimingTest extends AbstractLspAnalysisServerTest {
  /// Calls to getResolvedUnit should record time for their zone.
  Future<void> test_getResolvedUnit_zoneSpecific() async {
    await initialize();
    await openFile(mainFileUri, 'class A {}');
    await workspaceAnalysisComplete();

    var firstTiming = RequestPerformanceAdditionalTimings();
    var secondTiming = RequestPerformanceAdditionalTimings();
    var zoneKey = RequestPerformanceAdditionalTimings.zoneValueKey;
    var analysisKind = RequestPerformanceAdditionalTimingKind.analysis;

    // Run getResolvedUnit in two zones with their own instances of
    // RequestPerformanceAdditionalTimings.
    await Future.wait([
      runZoned(
        () => server.getResolvedUnit(mainFilePath)!,
        zoneValues: {zoneKey: firstTiming},
      ),
      runZoned(
        () => server.getResolvedUnit(mainFilePath)!,
        zoneValues: {zoneKey: secondTiming},
      ),
    ]);

    // Expect both instances to have entries for analysis.
    expect(firstTiming.timings.keys, contains(analysisKind));
    expect(secondTiming.timings.keys, contains(analysisKind));

    // Expect both have non-zero Stopwatches.
    expect(firstTiming.timings[analysisKind]!.elapsed, isNot(Duration.zero));
    expect(secondTiming.timings[analysisKind]!.elapsed, isNot(Duration.zero));
  }

  Future<void> test_handlesOverlappedTimings() async {
    var timing = RequestPerformanceAdditionalTimings();

    // Simulate 10 overlapped calls of analysis where the total time spent
    // is only around 100ms.
    for (var i = 0; i < 100; i++) {
      timing.pushAnalysis();
    }
    await Future.delayed(const Duration(milliseconds: 100));
    for (var i = 0; i < 100; i++) {
      timing.popAnalysis();
    }

    var stopwatch =
        timing.timings[RequestPerformanceAdditionalTimingKind.analysis]!;
    expect(stopwatch.isRunning, isFalse);

    // Time should be approximately 100ms, definitely not 100 * 100ms (10s).
    // Be generous for slow bots, but don't allow 10 because that could
    // indicate double-counting.
    expect(stopwatch.elapsed.inMilliseconds, greaterThanOrEqualTo(90));
    expect(stopwatch.elapsed.inSeconds, lessThan(8));
  }
}
