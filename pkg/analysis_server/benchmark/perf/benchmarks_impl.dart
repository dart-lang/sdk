// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as path;

import '../benchmarks.dart';
import 'memory_tests.dart';

/// benchmarks:
///   - analysis-server-warm-analysis
///   - analysis-server-warm-memory
///   - analysis-server-edit
///   - analysis-server-completion
class AnalysisBenchmark extends Benchmark {
  final AbstractBenchmarkTest Function() testConstructor;
  AnalysisBenchmark(ServerBenchmark benchmarkTest)
      : testConstructor = benchmarkTest.testConstructor,
        super(
            benchmarkTest.id,
            '${benchmarkTest.name} benchmarks of a large project, with an existing '
            'driver cache.',
            kind: 'group');

  @override
  Future<BenchMarkResult> run({
    bool quick = false,
    bool verbose = false,
  }) async {
    var stopwatch = Stopwatch()..start();

    var test = testConstructor();
    if (verbose) {
      test.debugStdio();
    }
    await test.setUp(getProjectRoots(quick: quick));
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

  Future<int> _calcCompletionTiming(AbstractBenchmarkTest test) async {
    const kGroupCount = 10;

    var filePath =
        path.join(analysisServerSrcPath, 'lib/src/analysis_server.dart');
    var contents = File(filePath).readAsStringSync();

    await test.openFile(filePath, contents);

    var completionCount = 0;
    var stopwatch = Stopwatch()..start();

    Future _complete(int offset) async {
      await test.complete(filePath, offset);
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
        await test.updateFile(filePath, contents);
      }
    }

    stopwatch.stop();

    await test.closeFile(filePath);

    return stopwatch.elapsedMicroseconds ~/ completionCount;
  }

  Future<int> _calcEditTiming(AbstractBenchmarkTest test) async {
    const kGroupCount = 5;

    var filePath =
        path.join(analysisServerSrcPath, 'lib/src/analysis_server.dart');
    var contents = File(filePath).readAsStringSync();

    await test.openFile(filePath, contents);
    await test.analysisFinished;

    var stopwatch = Stopwatch()..start();

    for (var i = 0; i < kGroupCount; i++) {
      var startIndex = i * (contents.length ~/ (kGroupCount + 2));
      var index = contents.indexOf(';', startIndex);
      contents = contents.substring(0, index + 1) +
          ' ' +
          contents.substring(index + 1);
      await test.updateFile(filePath, contents);
      await test.analysisFinished;
    }

    stopwatch.stop();

    await test.closeFile(filePath);

    return stopwatch.elapsedMicroseconds ~/ kGroupCount;
  }
}

/// benchmarks:
///   - analysis-server-cold-analysis
///   - analysis-server-cold-memory
class ColdAnalysisBenchmark extends Benchmark {
  final AbstractBenchmarkTest Function() testConstructor;
  ColdAnalysisBenchmark(ServerBenchmark benchmarkTest)
      : testConstructor = benchmarkTest.testConstructor,
        super(
            '${benchmarkTest.id}-cold',
            '${benchmarkTest.name} benchmarks of a large project on start-up, no '
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

    var test = testConstructor();
    await test.setUp(getProjectRoots(quick: quick));
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

class ServerBenchmark {
  static final das = ServerBenchmark('analysis-server', 'Analysis Server',
      () => AnalysisServerBenchmarkTest());
  static final lsp = ServerBenchmark('lsp-analysis-server',
      'LSP Analysis Server', () => LspAnalysisServerBenchmarkTest());
  final String id;

  final String name;
  final AbstractBenchmarkTest Function() testConstructor;

  ServerBenchmark(this.id, this.name, this.testConstructor);
}
