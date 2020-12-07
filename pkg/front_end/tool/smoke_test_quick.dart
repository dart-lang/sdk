// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' show Platform, Process, ProcessResult, exitCode;

import '../test/utils/io_utils.dart' show computeRepoDir;

final String repoDir = computeRepoDir();

String get dartVm => Platform.executable;

main(List<String> args) async {
  Stopwatch stopwatch = new Stopwatch()..start();
  List<Future> futures = <Future>[];
  futures.add(run(
      "pkg/front_end/test/explicit_creation_test.dart", ["--front-end-only"],
      filter: false));
  futures.add(run(
    "pkg/front_end/test/fasta/messages_suite.dart",
    ["-DfastOnly=true"],
  ));
  futures.add(run("pkg/front_end/test/spelling_test_not_src_suite.dart", []));
  futures.add(run("pkg/front_end/test/spelling_test_src_suite.dart",
      ["--", "spelling_test_src/front_end/..."]));
  futures.add(
      run("pkg/front_end/test/lint_suite.dart", ["--", "lint/front_end/..."]));
  futures.add(run("pkg/front_end/test/deps_test.dart", [], filter: false));
  futures.add(run(
      "pkg/front_end/tool/_fasta/generate_experimental_flags_test.dart", [],
      filter: false));
  await Future.wait(futures);
  print("\n-----------------------\n");
  print("Done with exitcode $exitCode in ${stopwatch.elapsedMilliseconds} ms");
}

Future<void> run(String script, List<String> scriptArguments,
    {bool filter: true}) async {
  List<String> arguments = [];
  arguments.add("$script");
  arguments.addAll(scriptArguments);

  Stopwatch stopwatch = new Stopwatch()..start();
  ProcessResult result =
      await Process.run(dartVm, arguments, workingDirectory: repoDir);
  String runWhat = "${dartVm} ${arguments.join(' ')}";
  if (result.exitCode != 0) {
    exitCode = result.exitCode;
    print("-----");
    print("Running: $runWhat: "
        "Failed with exit code ${result.exitCode} "
        "in ${stopwatch.elapsedMilliseconds} ms.");
    String stdout = result.stdout.toString();
    if (filter) {
      List<String> lines = stdout.split("\n");
      int lastIgnored = -1;
      for (int i = 0; i < lines.length; i++) {
        if (lines[i].startsWith("[ ")) lastIgnored = i;
      }
      lines.removeRange(0, lastIgnored + 1);
      stdout = lines.join("\n");
    }
    stdout = stdout.trim();
    if (stdout.isNotEmpty) {
      print("--- stdout start ---");
      print(stdout);
      print("--- stdout end ---");
    }

    String stderr = result.stderr.toString().trim();
    if (stderr.isNotEmpty) {
      print("--- stderr start ---");
      print(stderr);
      print("--- stderr end ---");
    }
  } else {
    print("Running: $runWhat: Done in ${stopwatch.elapsedMilliseconds} ms.");
  }
}
