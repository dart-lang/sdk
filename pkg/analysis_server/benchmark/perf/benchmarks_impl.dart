// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:analysis_server/src/protocol_server.dart';
import 'package:path/path.dart' as path;

import '../../test/integration/support/integration_tests.dart';
import '../benchmarks.dart';
import 'memory_tests.dart';

/// benchmarks:
///   - analysis-server-warm-analysis
///   - analysis-server-warm-memory
///   - analysis-server-edit
///   - analysis-server-completion
class AnalysisBenchmark extends Benchmark {
  AnalysisBenchmark()
      : super(
            'analysis-server',
            'Analysis server benchmarks of a large project, with an existing '
                'driver cache.',
            kind: 'group');

  @override
  Future<BenchMarkResult> run({
    bool quick = false,
    bool verbose = false,
  }) async {
    var stopwatch = Stopwatch()..start();

    var test = AnalysisServerMemoryUsageTest();
    if (verbose) {
      test.debugStdio();
    }
    await test.setUp();
    await test.subscribeToStatusNotifications();
    await test.sendAnalysisSetAnalysisRoots(getProjectRoots(quick: quick), []);
    await test.analysisFinished;

    stopwatch.stop();
    var usedBytes = await test.getMemoryUsage();

    var result = CompoundBenchMarkResult(id);
    result.add('warm-analysis',
        BenchMarkResult('micros', stopwatch.elapsedMicroseconds));
    result.add('warm-memory', BenchMarkResult('bytes', usedBytes));

    if (!quick) {
      // change timing
      var editMicros = await _calcEditTiming(test);
      result.add('edit', BenchMarkResult('micros', editMicros));

      // code completion
      var completionMicros = await _calcCompletionTiming(test);
      result.add('completion', BenchMarkResult('micros', completionMicros));
    }

    await test.shutdown();

    return result;
  }

  Future<int> _calcCompletionTiming(
      AbstractAnalysisServerIntegrationTest test) async {
    const kGroupCount = 10;

    var filePath =
        path.join(analysisServerSrcPath, 'lib/src/analysis_server.dart');
    var contents = File(filePath).readAsStringSync();

    await test
        .sendAnalysisUpdateContent({filePath: AddContentOverlay(contents)});

    var completionCount = 0;
    var stopwatch = Stopwatch()..start();

    Future _complete(int offset) async {
      // Create a new non-broadcast stream and subscribe to
      // test.onCompletionResults before sending a request.
      // Otherwise we could skip results which where posted to
      // test.onCompletionResults after request is sent but
      // before subscribing to test.onCompletionResults.
      final completionResults = StreamController<CompletionResultsParams>();
      completionResults.sink.addStream(test.onCompletionResults);

      var result = await test.sendCompletionGetSuggestions(filePath, offset);

      var future = completionResults.stream
          .where((CompletionResultsParams params) =>
              params.id == result.id && params.isLast)
          .first;
      await future;

      completionCount++;
    }

    for (var i = 0; i < kGroupCount; i++) {
      var startIndex = i * (contents.length ~/ (kGroupCount + 2));
      // Look for a line with a period in it that ends with a semi-colon.
      var index =
          contents.indexOf(RegExp(r'\..*;$', multiLine: true), startIndex);

      await _complete(index - 10);
      await _complete(index - 1);
      await _complete(index);
      await _complete(index + 1);
      await _complete(index + 10);

      if (i + 1 < kGroupCount) {
        // mutate
        index = contents.indexOf(';', index);
        contents = contents.substring(0, index + 1) +
            ' ' +
            contents.substring(index + 1);
        await test
            .sendAnalysisUpdateContent({filePath: AddContentOverlay(contents)});
      }
    }

    stopwatch.stop();

    return stopwatch.elapsedMicroseconds ~/ completionCount;
  }

  Future<int> _calcEditTiming(
      AbstractAnalysisServerIntegrationTest test) async {
    const kGroupCount = 5;

    var filePath =
        path.join(analysisServerSrcPath, 'lib/src/analysis_server.dart');
    var contents = File(filePath).readAsStringSync();

    await test
        .sendAnalysisUpdateContent({filePath: AddContentOverlay(contents)});

    var stopwatch = Stopwatch()..start();

    for (var i = 0; i < kGroupCount; i++) {
      var startIndex = i * (contents.length ~/ (kGroupCount + 2));
      var index = contents.indexOf(';', startIndex);
      contents = contents.substring(0, index + 1) +
          ' ' +
          contents.substring(index + 1);
      await test
          .sendAnalysisUpdateContent({filePath: AddContentOverlay(contents)});
      await test.analysisFinished;
    }

    stopwatch.stop();

    return stopwatch.elapsedMicroseconds ~/ kGroupCount;
  }
}

/// benchmarks:
///   - analysis-server-cold-analysis
///   - analysis-server-cold-memory
class ColdAnalysisBenchmark extends Benchmark {
  ColdAnalysisBenchmark()
      : super(
            'analysis-server-cold',
            'Analysis server benchmarks of a large project on start-up, no '
                'existing driver cache.',
            kind: 'group');

  @override
  int get maxIterations => 3;

  @override
  Future<BenchMarkResult> run({
    bool quick = false,
    bool verbose = false,
  }) async {
    if (!quick) {
      deleteServerCache();
    }

    var stopwatch = Stopwatch()..start();

    var test = AnalysisServerMemoryUsageTest();
    await test.setUp();
    await test.subscribeToStatusNotifications();
    await test.sendAnalysisSetAnalysisRoots(getProjectRoots(quick: quick), []);
    await test.analysisFinished;

    stopwatch.stop();
    var usedBytes = await test.getMemoryUsage();

    var result = CompoundBenchMarkResult(id);
    result.add(
        'analysis', BenchMarkResult('micros', stopwatch.elapsedMicroseconds));
    result.add('memory', BenchMarkResult('bytes', usedBytes));

    await test.shutdown();

    return result;
  }
}
