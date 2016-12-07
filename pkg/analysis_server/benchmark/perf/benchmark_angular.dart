// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library server.performance.local;

import 'dart:async';

import 'benchmark_scenario.dart';
import 'memory_tests.dart';

main(List<String> args) async {
  int length = args.length;
  if (length < 1) {
    print(
        'Usage: dart benchmark_local.dart path_to_np8080 (an example ngdart project)'
        ' [benchmark_id]');
    return;
  }
  paths = new PathHolder(projectPath: args[0]);
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
  'ng-initialAnalysis': run_ng_initialAnalysis,
  'ng-change-dart': run_ng_change_dart,
  'ng-change-html': run_ng_change_html,
  'ng-memory-initialAnalysis': run_ng_memory_initialAnalysis,
};

PathHolder paths;

Future run_ng_change_dart(String id) async {
  String description = r'''
1. Open 'packages/np8080'.
2. Add an @Output to the class
3. Measure the time to finish analysis.
4. Rollback changes to the file and wait for analysis.
5. Go to (2).
''';
  List<int> times = await new BenchmarkScenario().waitAnalyze_change_analyze(
      roots: [paths.packageNp8080],
      file: paths.editorDart,
      fileChange: new FileChange(
          afterStr: 'showPreview = false;',
          insertStr: '@Output() EventEmitter<int> myEventEmitter;'),
      numOfRepeats: 10);
  printBenchmarkResults(id, description, times);
}

Future run_ng_change_html(String id) async {
  String description = r'''
1. Open 'packages/np8080'.
2. Change the contents of a mustache
3. Measure the time to finish analysis.
4. Rollback changes to the file and wait for analysis.
5. Go to (2).
''';
  List<int> times = await new BenchmarkScenario().waitAnalyze_change_analyze(
      roots: [paths.packageNp8080],
      file: paths.editorHtml,
      fileChange: new FileChange(
          afterStr: 'note.lastModified', afterStrBack: 4, insertStr: 'NewName'),
      numOfRepeats: 4);
  printBenchmarkResults(id, description, times);
}

Future run_ng_initialAnalysis(String id) async {
  String description = r'''
1. Start server, set 'package/np8080' analysis roots.
2. Measure the time to finish initial analysis.
3. Shutdown the server.
4. Go to (1).
''';
  List<int> times = await BenchmarkScenario.start_waitInitialAnalysis_shutdown(
      roots: [paths.packageNp8080], numOfRepeats: 5);
  printBenchmarkResults(id, description, times);
}

Future run_ng_memory_initialAnalysis(String id) async {
  String description = r'''
1. Start server, set 'package/np8080' as the analysis root.
2. Measure the memory usage after finishing initial analysis.
3. Shutdown the server.
4. Go to (1).
''';
  List<int> sizes = await AnalysisServerMemoryUsageTest
      .start_waitInitialAnalysis_shutdown(
          roots: <String>[paths.packageNp8080], numOfRepeats: 3);
  printMemoryResults(id, description, sizes);
}

typedef BenchmarkFunction(String id);

class PathHolder {
  String editorHtml;
  String editorDart;
  String packageNp8080;

  PathHolder({String projectPath}) {
    editorHtml = '$projectPath/lib/editor/editor_component.html';
    editorDart = '$projectPath/lib/editor/editor_component.dart';
    packageNp8080 = projectPath;
  }
}
