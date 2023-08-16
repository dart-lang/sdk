// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

import 'dart:async' show Future;
import 'dart:convert' show LineSplitter, utf8;
import 'dart:io' show File, Platform, Process, exitCode;

Future<void> main(List<String> args) async {
  // General idea: Launch - in separate processes - whatever we want to run
  // concurrently, capturing the stdout and stderr, printing it with some
  // prepended identification.
  // When all runs are done, fail if any fails.
  // Later we might be able to move it to the "testRunner"-system, if that
  // offers any advantages.

  print("NOTE: This machine has ${Platform.numberOfProcessors} processors!"
      "\n\n");

  List<WrappedProcess> startedProcesses = [];

  {
    // Very slow: Leak-test.
    Uri leakTester =
        Platform.script.resolve("flutter_gallery_leak_tester.dart");
    if (!new File.fromUri(leakTester).existsSync()) {
      exitCode = 1;
      print("Couldn't find $leakTester");
    } else {
      // The tools/bots/flutter/compile_flutter.sh script passes `--path`
      // --- we'll just pass everything along.
      startedProcesses.add(await run(
        [
          leakTester.toString(),
          ...args,
        ],
        "leak test",
      ));
    }
  }

  {
    // Weak suite with fuzzing.
    Uri weakSuite = Platform.script.resolve("fasta/weak_suite.dart");
    if (!new File.fromUri(weakSuite).existsSync()) {
      exitCode = 1;
      print("Couldn't find $weakSuite");
    } else {
      startedProcesses.add(await run(
        [
          weakSuite.toString(),
          "-DsemiFuzz=true",
        ],
        "weak suite",
      ));
    }
  }

  {
    // Strong suite with fuzzing.
    Uri strongSuite = Platform.script.resolve("fasta/strong_suite.dart");
    if (!new File.fromUri(strongSuite).existsSync()) {
      exitCode = 1;
      print("Couldn't find $strongSuite");
    } else {
      startedProcesses.add(await run(
        [
          strongSuite.toString(),
          "-DsemiFuzz=true",
        ],
        "strong suite",
      ));
    }
  }

  {
    // Leak tests of incremental suite tests.
    Uri incrementalLeakTest =
        Platform.script.resolve("vm_service_for_leak_detection.dart");
    if (!new File.fromUri(incrementalLeakTest).existsSync()) {
      exitCode = 1;
      print("Couldn't find $incrementalLeakTest");
    } else {
      startedProcesses.add(await run([
        incrementalLeakTest.toString(),
        "--weekly",
      ], "incremental leak test"));
    }
  }

  {
    // Expression suite with fuzzing.
    Uri expressionSuite =
        Platform.script.resolve("fasta/expression_suite.dart");
    if (!new File.fromUri(expressionSuite).existsSync()) {
      exitCode = 1;
      print("Couldn't find $expressionSuite");
    } else {
      startedProcesses.add(await run(
        [
          expressionSuite.toString(),
          "-Dfuzz=true",
        ],
        "expression suite",
      ));
    }
  }

  // Wait for everything to finish.
  List<int> exitCodes =
      await Future.wait(startedProcesses.map((e) => e.process.exitCode));
  if (exitCodes.where((e) => e != 0).isNotEmpty) {
    print("\n\nFound failures!:\n");
    // At least one failed.
    for (WrappedProcess p in startedProcesses) {
      int pExitCode = await p.process.exitCode;
      if (pExitCode != 0) {
        print("${p.id} failed with exist-code $pExitCode");
      }
    }

    throw "There were failures!";
  }
}

Future<WrappedProcess> run(List<String> args, String id) async {
  Stopwatch stopwatch = new Stopwatch()..start();
  Process process = await Process.start(
      Platform.resolvedExecutable, ["--enable-asserts", ...args]);
  List<String> observatoryLines = [];
  process.stderr
      .transform(utf8.decoder)
      .transform(new LineSplitter())
      .listen((line) {
    print("$id stderr> $line");
    if (line.contains("The Dart VM service is listening on")) {
      observatoryLines.add(line);
    }
  });
  process.stdout
      .transform(utf8.decoder)
      .transform(new LineSplitter())
      .listen((line) {
    print("$id stdout> $line");
    if (line.contains("The Dart VM service is listening on")) {
      observatoryLines.add(line);
    }
  });
  // ignore: unawaited_futures
  process.exitCode.then((int exitCode) {
    stopwatch.stop();
    print("$id finished in ${stopwatch.elapsed.toString()} "
        "with exit code $exitCode");
  });
  return new WrappedProcess(process, id, observatoryLines);
}

class WrappedProcess {
  final Process process;
  final String id;
  final List<String> observatoryLines;

  WrappedProcess(this.process, this.id, this.observatoryLines);
}
