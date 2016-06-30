// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library server.performance.local;

import 'dart:async';

import 'package:analysis_server/plugin/protocol/protocol.dart';

import 'benchmark_scenario.dart';
import 'memory_tests.dart';

main(List<String> args) async {
  int length = args.length;
  if (length < 1) {
    print(
        'Usage: dart benchmark_local.dart path_to_sdk_checkout [path_to_flutter_checkout]');
    return;
  } else if (length == 1) {
    paths = new PathHolder(sdkPath: args[0]);
  } else {
    paths = new PathHolder(sdkPath: args[0], flutterPath: args[1]);
  }
  String now = new DateTime.now().toUtc().toIso8601String();
  print('Benchmark started: $now');
  print('');
  print('');
  await run_local_initialAnalysis_1();
  await run_local_initialAnalysis_2();
  await run_local_initialAnalysis_3();
  await run_local_change_1();
  await run_local_change_2();
  await run_local_completion_1();
  await run_local_completion_2();
  await run_local_completion_3();
  await run_local_completion_4();
  await run_local_refactoring_1();

  await run_memory_initialAnalysis_1();
  await run_memory_initialAnalysis_2();
}

PathHolder paths;

Future run_local_change_1() async {
  String id = 'local-change-1';
  String description = r'''
1. Open 'analyzer'.
2. Change a method body in src/task/dart.dart.
3. Measure the time to finish analysis.
4. Rollback changes to the file and wait for analysis.
5. Go to (2).
''';
  List<int> times = await new BenchmarkScenario().waitAnalyze_change_analyze(
      roots: [paths.analyzer],
      file: '${paths.analyzer}/lib/src/task/dart.dart',
      fileChange: new FileChange(
          afterStr: 'if (hasDirectiveChange) {', insertStr: 'print(12345);'),
      numOfRepeats: 10);
  printBenchmarkResults(id, description, times);
}

Future run_local_change_2() async {
  String id = 'local-change-2';
  String description = r'''
1. Open 'analyzer'.
2. Change the name of a public method in src/task/dart.dart.
3. Measure the time to finish analysis.
4. Rollback changes to the file and wait for analysis.
5. Go to (2).
''';
  List<int> times = await new BenchmarkScenario().waitAnalyze_change_analyze(
      roots: [paths.analyzer],
      file: '${paths.analyzer}/lib/src/task/dart.dart',
      fileChange: new FileChange(
          afterStr: 'resolveDirective(An',
          afterStrBack: 3,
          insertStr: 'NewName'),
      numOfRepeats: 5);
  printBenchmarkResults(id, description, times);
}

Future run_local_completion_1() async {
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
          roots: [paths.analyzer],
          file: '${paths.analyzer}/lib/src/task/dart.dart',
          fileChange: new FileChange(
              afterStr: 'if (hasDirectiveChange) {',
              insertStr: 'print(12345);'),
          completeAfterStr: 'print(12345);',
          numOfRepeats: 10);
  printBenchmarkResults(id, description, times);
}

Future run_local_completion_2() async {
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
          roots: [paths.analyzer],
          file: '${paths.analyzer}/lib/src/task/dart.dart',
          fileChange: new FileChange(
              afterStr: 'DeltaResult validate(In',
              afterStrBack: 3,
              insertStr: 'NewName'),
          completeAfterStr: 'if (hasDirectiveChange) {',
          numOfRepeats: 5);
  printBenchmarkResults(id, description, times);
}

Future run_local_completion_3() async {
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
          roots: [paths.analysisServer, paths.analyzer],
          file: '${paths.analyzer}/lib/src/task/dart.dart',
          fileChange: new FileChange(
              afterStr: 'if (hasDirectiveChange) {',
              insertStr: 'print(12345);'),
          completeAfterStr: 'print(12345);',
          numOfRepeats: 10);
  printBenchmarkResults(id, description, times);
}

Future run_local_completion_4() async {
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
          roots: [paths.analysisServer, paths.analyzer],
          file: '${paths.analyzer}/lib/src/task/dart.dart',
          fileChange: new FileChange(
              afterStr: 'DeltaResult validate(In',
              afterStrBack: 3,
              insertStr: 'NewName'),
          completeAfterStr: 'if (hasDirectiveChange) {',
          numOfRepeats: 5);
  printBenchmarkResults(id, description, times);
}

Future run_local_initialAnalysis_1() async {
  String id = 'local-initialAnalysis-1';
  String description = r'''
1. Start server, set 'analyzer' analysis root.
2. Measure the time to finish initial analysis.
3. Shutdown the server.
4. Go to (1).
''';
  List<int> times = await BenchmarkScenario.start_waitInitialAnalysis_shutdown(
      roots: [paths.analyzer], numOfRepeats: 3);
  printBenchmarkResults(id, description, times);
}

Future run_local_initialAnalysis_2() async {
  String id = 'local-initialAnalysis-2';
  String description = r'''
1. Start server, set 'analyzer' and 'analysis_server' analysis roots.
2. Measure the time to finish initial analysis.
3. Shutdown the server.
4. Go to (1).
''';
  List<int> times = await BenchmarkScenario.start_waitInitialAnalysis_shutdown(
      roots: [paths.analyzer, paths.analysisServer], numOfRepeats: 3);
  printBenchmarkResults(id, description, times);
}

Future run_local_initialAnalysis_3() async {
  String id = 'local-initialAnalysis-3';
  String description = r'''
1. Start server, set 'hello_world' and 'stocks' analysis roots.
2. Measure the time to finish initial analysis.
3. Shutdown the server.
4. Go to (1).
''';
  List<int> times = await BenchmarkScenario.start_waitInitialAnalysis_shutdown(
      roots: [paths.flutterHelloWorld, paths.flutterStocks], numOfRepeats: 3);
  printBenchmarkResults(id, description, times);
}

Future run_local_refactoring_1() async {
  String id = 'local-refactoring-1';
  String description = r'''
1. Open 'analyzer'.
2. Change the name of a public method in src/context/cache.dart.
3. Request rename refactoring for `getSourcesWithFullName` and measure time to get results.
4. Rollback changes to the file and wait for analysis.
5. Go to (2).
''';
  List<int> times = await new BenchmarkScenario()
      .waitAnalyze_change_getRefactoring(
          roots: [paths.analyzer],
          file: '${paths.analyzer}/lib/src/context/cache.dart',
          fileChange: new FileChange(
              afterStr: 'getState(An', afterStrBack: 3, insertStr: 'NewName'),
          refactoringAtStr: 'getSourcesWithFullName(String path)',
          refactoringKind: RefactoringKind.RENAME,
          refactoringOptions: new RenameOptions('getSourcesWithFullName2'),
          numOfRepeats: 5);
  printBenchmarkResults(id, description, times);
}

Future run_memory_initialAnalysis_1() async {
  String id = 'memory-initialAnalysis-1';
  String description = r'''
1. Start server, set 'analyzer' and 'analysis_server' analysis roots.
2. Measure the memory usage after finishing initial analysis.
3. Shutdown the server.
4. Go to (1).
''';
  List<int> sizes = await AnalysisServerMemoryUsageTest
      .start_waitInitialAnalysis_shutdown(
          roots: <String>[paths.analyzer], numOfRepeats: 3);
  printMemoryResults(id, description, sizes);
}

Future run_memory_initialAnalysis_2() async {
  String id = 'memory-initialAnalysis-2';
  String description = r'''
1. Start server, set 'analyzer' and 'analysis_server' analysis roots.
2. Measure the memory usage after finishing initial analysis.
3. Shutdown the server.
4. Go to (1).
''';
  List<int> sizes = await AnalysisServerMemoryUsageTest
      .start_waitInitialAnalysis_shutdown(
          roots: <String>[paths.analyzer, paths.analysisServer],
          numOfRepeats: 3);
  printMemoryResults(id, description, sizes);
}

class PathHolder {
  String analysisServer;
  String analyzer;
  String flutterHelloWorld;
  String flutterStocks;

  PathHolder({String sdkPath, String flutterPath}) {
    analysisServer = '$sdkPath/pkg/analysis_server';
    analyzer = '$sdkPath/pkg/analyzer';
    flutterHelloWorld = '$flutterPath/examples/hello_world';
    flutterStocks = '$flutterPath/examples/stocks';
  }
}
