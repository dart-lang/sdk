// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library server.performance.local;

import 'benchmark_scenario.dart';

main(List<String> args) async {
  String pathRepository = args[0];
  String pathServer = '$pathRepository/pkg/analysis_server';
  String pathAnalyzer = '$pathRepository/pkg/analyzer';
  {
    String now = new DateTime.now().toUtc().toIso8601String();
    print('Benchmark started: $now');
    print('');
    print('');
  }

  {
    String id = 'local-initialAnalysis-1';
    String description = r'''
1. Start server, set 'analyzer' analysis root.
2. Measure the time to finish initial analysis.
3. Shutdown the server.
4. Go to (1).
''';
    List<int> times = await BenchmarkScenario
        .start_waitInitialAnalysis_shutdown(
            roots: [pathAnalyzer], numOfRepeats: 3);
    printBenchmarkResults(id, description, times);
  }

  {
    String id = 'local-initialAnalysis-2';
    String description = r'''
1. Start server, set 'analyzer' and 'analysis_server' analysis roots.
2. Measure the time to finish initial analysis.
3. Shutdown the server.
4. Go to (1).
''';
    List<int> times = await BenchmarkScenario
        .start_waitInitialAnalysis_shutdown(
            roots: [pathAnalyzer, pathServer], numOfRepeats: 3);
    printBenchmarkResults(id, description, times);
  }

  {
    String id = 'local-change-1';
    String description = r'''
1. Open 'analyzer'.
2. Change a method body in src/task/dart.dart.
3. Measure the time to finish analysis.
4. Rollback changes to the file and wait for analysis.
5. Go to (2).
''';
    List<int> times = await new BenchmarkScenario().waitAnalyze_change_analyze(
        roots: [pathAnalyzer],
        file: '$pathAnalyzer/lib/src/task/dart.dart',
        fileChange: new FileChange(
            afterStr: 'if (hasDirectiveChange) {', insertStr: 'print(12345);'),
        numOfRepeats: 10);
    printBenchmarkResults(id, description, times);
  }

  {
    String id = 'local-change-2';
    String description = r'''
1. Open 'analyzer'.
2. Change the name of a public method in src/task/dart.dart.
3. Measure the time to finish analysis.
4. Rollback changes to the file and wait for analysis.
5. Go to (2).
''';
    List<int> times = await new BenchmarkScenario().waitAnalyze_change_analyze(
        roots: [pathAnalyzer],
        file: '$pathAnalyzer/lib/src/task/dart.dart',
        fileChange: new FileChange(
            afterStr: 'resolveDirective(An',
            afterStrBack: 3,
            insertStr: 'NewName'),
        numOfRepeats: 5);
    printBenchmarkResults(id, description, times);
  }

  {
    String id = 'local-completion-1';
    String description = r'''
1. Open 'analyzer'.
2. Change a method body in src/task/dart.dart.
3. Request code completion in this method and measure time to get results.
4. Rollback changes to the file and wait for analysis.
5. Go to (2).
''';
    List<int> times = await new BenchmarkScenario()
        .waitAnalyze_change_getCompletion(
            roots: [pathAnalyzer],
            file: '$pathAnalyzer/lib/src/task/dart.dart',
            fileChange: new FileChange(
                afterStr: 'if (hasDirectiveChange) {',
                insertStr: 'print(12345);'),
            completeAfterStr: 'print(12345);',
            numOfRepeats: 10);
    printBenchmarkResults(id, description, times);
  }

  {
    String id = 'local-completion-2';
    String description = r'''
1. Open 'analyzer'.
2. Change the name of a public method in src/task/dart.dart.
3. Request code completion in this method and measure time to get results.
4. Rollback changes to the file and wait for analysis.
5. Go to (2).
''';
    List<int> times = await new BenchmarkScenario()
        .waitAnalyze_change_getCompletion(
            roots: [pathAnalyzer],
            file: '$pathAnalyzer/lib/src/task/dart.dart',
            fileChange: new FileChange(
                afterStr: 'DeltaResult validate(In',
                afterStrBack: 3,
                insertStr: 'NewName'),
            completeAfterStr: 'if (hasDirectiveChange) {',
            numOfRepeats: 5);
    printBenchmarkResults(id, description, times);
  }

  {
    String id = 'local-completion-3';
    String description = r'''
1. Open 'analysis_server' and 'analyzer'.
2. Change a method body in src/task/dart.dart.
3. Request code completion in this method and measure time to get results.
4. Rollback changes to the file and wait for analysis.
5. Go to (2).
''';
    List<int> times = await new BenchmarkScenario()
        .waitAnalyze_change_getCompletion(
            roots: [pathServer, pathAnalyzer],
            file: '$pathAnalyzer/lib/src/task/dart.dart',
            fileChange: new FileChange(
                afterStr: 'if (hasDirectiveChange) {',
                insertStr: 'print(12345);'),
            completeAfterStr: 'print(12345);',
            numOfRepeats: 10);
    printBenchmarkResults(id, description, times);
  }

  {
    String id = 'local-completion-4';
    String description = r'''
1. Open 'analysis_server' and 'analyzer'.
2. Change the name of a public method in src/task/dart.dart.
3. Request code completion in this method and measure time to get results.
4. Rollback changes to the file and wait for analysis.
5. Go to (2).
''';
    List<int> times = await new BenchmarkScenario()
        .waitAnalyze_change_getCompletion(
            roots: [pathServer, pathAnalyzer],
            file: '$pathAnalyzer/lib/src/task/dart.dart',
            fileChange: new FileChange(
                afterStr: 'DeltaResult validate(In',
                afterStrBack: 3,
                insertStr: 'NewName'),
            completeAfterStr: 'if (hasDirectiveChange) {',
            numOfRepeats: 5);
    printBenchmarkResults(id, description, times);
  }
}
