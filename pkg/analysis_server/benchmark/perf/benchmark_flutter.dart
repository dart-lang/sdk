// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';

import 'benchmark_scenario.dart';
import 'memory_tests.dart';

main(List<String> args) async {
  int length = args.length;
  if (length < 1) {
    print('Usage: dart benchmark_local.dart path_to_flutter_checkout'
        ' [benchmark_id]');
    return;
  }
  paths = new PathHolder(flutterPath: args[0]);
  String id = args.length >= 2 ? args[1] : null;
  if (id == null) {
    for (String id in benchmarks.keys) {
      BenchmarkFunction benchmark = benchmarks[id];
      await benchmark(id);
    }
  } else {
    BenchmarkFunction benchmark = benchmarks[id];
    if (benchmark != null) {
      benchmark(id);
    }
  }
}

const Map<String, BenchmarkFunction> benchmarks =
    const <String, BenchmarkFunction>{
  'flutter-initialAnalysis-1': run_flutter_initialAnalysis_1,
  'flutter-initialAnalysis-2': run_flutter_initialAnalysis_2,
  'flutter-change-1': run_flutter_change_1,
  'flutter-change-2': run_flutter_change_2,
  'flutter-completion-1': run_flutter_completion_1,
  'flutter-completion-2': run_flutter_completion_2,
  'flutter-refactoring-1': run_flutter_refactoring_1,
  'flutter-memory-initialAnalysis-1': run_flutter_memory_initialAnalysis_1,
  'flutter-memory-initialAnalysis-2': run_flutter_memory_initialAnalysis_2,
};

PathHolder paths;

Future run_flutter_change_1(String id) async {
  String description = r'''
1. Open 'packages/flutter'.
2. Change a method body in lib/src/painting/colors.dart
3. Measure the time to finish analysis.
4. Rollback changes to the file and wait for analysis.
5. Go to (2).
''';
  List<int> times = await new BenchmarkScenario().waitAnalyze_change_analyze(
      roots: [paths.packageFlutter],
      file: '${paths.packageFlutter}/lib/src/painting/colors.dart',
      fileChange: new FileChange(
          afterStr: 'final double h = hue % 360;', insertStr: 'print(12345);'),
      numOfRepeats: 10);
  printBenchmarkResults(id, description, times);
}

Future run_flutter_change_2(String id) async {
  String description = r'''
1. Open 'packages/flutter'.
2. Change the name of a public method in lib/src/painting/colors.dart
3. Measure the time to finish analysis.
4. Rollback changes to the file and wait for analysis.
5. Go to (2).
''';
  List<int> times = await new BenchmarkScenario().waitAnalyze_change_analyze(
      roots: [paths.packageFlutter],
      file: '${paths.packageFlutter}/lib/src/painting/colors.dart',
      fileChange: new FileChange(
          afterStr: 'withValue(dou', afterStrBack: 4, insertStr: 'NewName'),
      numOfRepeats: 5);
  printBenchmarkResults(id, description, times);
}

Future run_flutter_completion_1(String id) async {
  String description = r'''
1. Open 'packages/flutter'.
2. Change a method body in packages/flutter/lib/src/material/button.dart
3. Request code completion in this method and measure time to get results.
4. Rollback changes to the file and wait for analysis.
5. Go to (2).
''';
  String completionMarker = 'print(12345);';
  List<int> times = await new BenchmarkScenario()
      .waitAnalyze_change_getCompletion(
          roots: [paths.packageFlutter],
          file: '${paths.packageFlutter}/lib/src/material/button.dart',
          fileChange: new FileChange(
              afterStr: 'Widget build(BuildContext context) {',
              insertStr: completionMarker),
          completeAfterStr: completionMarker,
          numOfRepeats: 10);
  printBenchmarkResults(id, description, times);
}

Future run_flutter_completion_2(String id) async {
  String description = r'''
1. Open 'packages/flutter'.
2. Change the name of a public method in lib/src/rendering/layer.dart
3. Request code completion in this method and measure time to get results.
4. Rollback changes to the file and wait for analysis.
5. Go to (2).
''';
  List<int> times = await new BenchmarkScenario()
      .waitAnalyze_change_getCompletion(
          roots: [paths.packageFlutter],
          file: '${paths.packageFlutter}/lib/src/rendering/layer.dart',
          fileChange: new FileChange(
              replaceWhat: 'void removeAllChildren() {',
              replaceWith: 'void removeAllChildren2() {print(12345);parent.'),
          completeAfterStr: 'print(12345);parent.',
          numOfRepeats: 5);
  printBenchmarkResults(id, description, times);
}

Future run_flutter_initialAnalysis_1(String id) async {
  String description = r'''
1. Start server, set 'hello_world' analysis root.
2. Measure the time to finish initial analysis.
3. Shutdown the server.
4. Go to (1).
''';
  List<int> times = await BenchmarkScenario.start_waitInitialAnalysis_shutdown(
      roots: [paths.exampleHelloWorld], numOfRepeats: 5);
  printBenchmarkResults(id, description, times);
}

Future run_flutter_initialAnalysis_2(String id) async {
  String description = r'''
1. Start server, set 'hello_world' and 'flutter_gallery' analysis roots.
2. Measure the time to finish initial analysis.
3. Shutdown the server.
4. Go to (1).
''';
  List<int> times = await BenchmarkScenario.start_waitInitialAnalysis_shutdown(
      roots: [paths.exampleHelloWorld, paths.exampleGallery], numOfRepeats: 5);
  printBenchmarkResults(id, description, times);
}

Future run_flutter_memory_initialAnalysis_1(String id) async {
  String description = r'''
1. Start server, set 'packages/flutter' as the analysis root.
2. Measure the memory usage after finishing initial analysis.
3. Shutdown the server.
4. Go to (1).
''';
  List<int> sizes = await AnalysisServerMemoryUsageTest
      .start_waitInitialAnalysis_shutdown(
          roots: <String>[paths.packageFlutter], numOfRepeats: 3);
  printMemoryResults(id, description, sizes);
}

Future run_flutter_memory_initialAnalysis_2(String id) async {
  String description = r'''
1. Start server, set 'packages/flutter' and 'packages/flutter_markdown' analysis roots.
2. Measure the memory usage after finishing initial analysis.
3. Shutdown the server.
4. Go to (1).
''';
  List<int> sizes = await AnalysisServerMemoryUsageTest
      .start_waitInitialAnalysis_shutdown(
          roots: <String>[paths.packageFlutter, paths.packageMarkdown],
          numOfRepeats: 3);
  printMemoryResults(id, description, sizes);
}

Future run_flutter_refactoring_1(String id) async {
  String description = r'''
1. Open 'packages/flutter'.
2. Change the name of a public method in lib/src/rendering/layer.dart
3. Request rename refactoring for `getSourcesWithFullName` and measure time to get results.
4. Rollback changes to the file and wait for analysis.
5. Go to (2).
''';
  List<int> times = await new BenchmarkScenario()
      .waitAnalyze_change_getRefactoring(
          roots: [paths.packageFlutter],
          file: '${paths.packageFlutter}/lib/src/rendering/layer.dart',
          fileChange: new FileChange(
              replaceWhat: 'void removeAllChildren() {',
              replaceWith: 'void removeAllChildren2() {'),
          refactoringAtStr: 'addToScene(ui.SceneBuilder builder',
          refactoringKind: RefactoringKind.RENAME,
          refactoringOptions: new RenameOptions('addToScene2'),
          numOfRepeats: 5);
  printBenchmarkResults(id, description, times);
}

typedef BenchmarkFunction(String id);

class PathHolder {
  String exampleHelloWorld;
  String exampleGallery;
  String exampleStocks;
  String packageFlutter;
  String packageMarkdown;
  String packageSprites;

  PathHolder({String flutterPath}) {
    exampleHelloWorld = '$flutterPath/examples/hello_world';
    exampleGallery = '$flutterPath/examples/flutter_gallery';
    exampleStocks = '$flutterPath/examples/stocks';
    packageFlutter = '$flutterPath/packages/flutter';
    packageMarkdown = '$flutterPath/packages/flutter_markdown';
    packageSprites = '$flutterPath/packages/flutter_sprites';
  }
}
