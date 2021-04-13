// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

import 'dart:async' show Future;
import 'dart:convert' show LineSplitter, utf8;
import 'dart:io' show File, Platform, Process, exitCode;

main(List<String> args) async {
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
      startedProcesses
          .add(await run([leakTester.toString(), ...args], "leak test"));
    }
  }
  {
    // Slow: Leak-test with alternative invalidation.
    Uri leakTester =
        Platform.script.resolve("flutter_gallery_leak_tester.dart");
    if (!new File.fromUri(leakTester).existsSync()) {
      exitCode = 1;
      print("Couldn't find $leakTester");
    } else {
      // Note that the leak test run above will start checking out flutter
      // gallery (etc) and that it has to finish before starting this.
      // We therefore wait for the observatory line being printed before
      // starting. Wait at most 10 minutes though.

      // ignore: unawaited_futures
      () async {
        for (int i = 0; i < 10 * 60; i++) {
          if (observatoryLines.isNotEmpty) break;
          await Future.delayed(new Duration(seconds: 1));
        }

        // The tools/bots/flutter/compile_flutter.sh script passes `--path`
        // --- we'll just pass everything along.
        startedProcesses.add(await run(
            [leakTester.toString(), ...args, "--alternativeInvalidation"],
            "leak test alternative invalidation"));
      }();
    }
  }

  {
    // Weak suite with fuzzing.
    Uri weakSuite = Platform.script.resolve("fasta/weak_suite.dart");
    if (!new File.fromUri(weakSuite).existsSync()) {
      exitCode = 1;
      print("Couldn't find $weakSuite");
    } else {
      startedProcesses.add(
          await run([weakSuite.toString(), "-DsemiFuzz=true"], "weak suite"));
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
          [strongSuite.toString(), "-DsemiFuzz=true"], "strong suite"));
    }
  }

  // Wait for everything to finish.
  List<int> exitCodes =
      await Future.wait(startedProcesses.map((e) => e.process.exitCode));
  if (exitCodes.where((e) => e != 0).isNotEmpty) {
    // At least one failed.
    exitCode = 1;
    for (WrappedProcess p in startedProcesses) {
      int pExitCode = await p.process.exitCode;
      if (pExitCode != 0) {
        print("${p.id} failed with exist-code $pExitCode");
      }
    }
  }
}

List<String> observatoryLines = [];

Future<WrappedProcess> run(List<String> args, String id) async {
  Process process = await Process.start(
      Platform.resolvedExecutable, ["--enable-asserts", ...args]);
  process.stderr
      .transform(utf8.decoder)
      .transform(new LineSplitter())
      .listen((line) {
    print("$id stderr> $line");
    if (line.contains("Observatory listening on")) {
      observatoryLines.add(line);
    }
  });
  process.stdout
      .transform(utf8.decoder)
      .transform(new LineSplitter())
      .listen((line) {
    print("$id stdout> $line");
    if (line.contains("Observatory listening on")) {
      observatoryLines.add(line);
    }
  });
  return new WrappedProcess(process, id);
}

class WrappedProcess {
  final Process process;
  final String id;

  WrappedProcess(this.process, this.id);
}
