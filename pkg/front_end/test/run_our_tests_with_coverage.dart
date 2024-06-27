// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'utils/io_utils.dart';

final Uri repoDirUri = computeRepoDirUri();

Future<void> main() async {
  String? coverage = Platform.environment["CFE_COVERAGE"];
  if (coverage == null) {
    throw "Set coverage path via 'CFE_COVERAGE' environment!";
  }

  List<String> testPaths = [];
  for (String path in [
    "pkg/_fe_analyzer_shared/test/",
    "pkg/front_end/test/",
    "pkg/frontend_server/test/",
    "pkg/kernel/test/",
  ]) {
    for (FileSystemEntity entry
        in new Directory.fromUri(repoDirUri.resolve(path))
            .listSync(recursive: true)) {
      if (entry is! File) continue;
      if (!entry.path.endsWith("_test.dart")) continue;
      testPaths.add(entry.path);
    }
  }

  Uri coverageRunner =
      repoDirUri.resolve("pkg/front_end/tool/coverage_runner.dart");
  if (!new File.fromUri(coverageRunner).existsSync()) {
    throw "The coverage runner tool doesn't exist.";
  }

  final int processes = Platform.numberOfProcessors;
  int processesLeft = processes;
  int processesRunning = 0;
  Completer<void> completer = new Completer();
  print("Will run ${testPaths.length} tests in $processes processes.");
  Stopwatch totalRuntimeStopwatch = new Stopwatch()..start();
  void log(String s) {
    print("${totalRuntimeStopwatch.elapsed}: $s");
  }

  while (testPaths.isNotEmpty) {
    while (processesLeft <= 0) {
      await completer.future;
    }
    processesLeft--;
    processesRunning++;
    String testPath = testPaths.removeLast();
    Stopwatch stopwatch = new Stopwatch()..start();
    // ignore: unawaited_futures
    Process.run(Platform.resolvedExecutable, [
      coverageRunner.toFilePath(),
      "--enable-asserts",
      testPath
    ]).then((ProcessResult value) {
      log("$testPath ended with "
          "exit code ${value.exitCode} "
          "in ${stopwatch.elapsed}");
      processesRunning--;
      processesLeft++;
      Completer<void> oldCompleter = completer;
      completer = new Completer();
      oldCompleter.complete();
    });
  }
  while (processesRunning > 0) {
    log("Awaiting $processesRunning processes");
    await completer.future;
  }
  log("Done");
}
