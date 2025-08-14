// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert' show jsonEncode;
import 'dart:io'
    show Directory, File, Platform, Process, ProcessResult, exitCode;

import 'package:args/args.dart' show ArgParser;
import 'package:args/src/arg_results.dart';

import '../tool/coverage_merger.dart' as coverageMerger;

bool debug = false;

Future<void> main([List<String> arguments = const <String>[]]) async {
  Directory coverageTmpDir =
      Directory.systemTemp.createTempSync("cfe_coverage");
  try {
    await _run(coverageTmpDir, arguments);
  } finally {
    if (debug) {
      print("Data available in $coverageTmpDir");
    } else {
      coverageTmpDir.deleteSync(recursive: true);
    }
  }
}

Future<void> _run(Directory coverageTmpDir, List<String> arguments) async {
  Stopwatch totalRuntime = new Stopwatch()..start();

  List<String> results = [];
  List<String> logs = [];
  Options options = Options.parse(arguments);
  debug = options.debug;
  List<Future<ProcessResult>> futures = [];

  if (options.verbose) {
    print("NOTE: Will run with ${options.numberOfWorkers} shards.");
    print("");
  }

  print("Note: Has ${Platform.numberOfProcessors} cores.");

  for (int i = 0; i < options.numberOfWorkers; i++) {
    print("Starting shard ${i + 1} of ${options.numberOfWorkers}");
    futures.add(Process.run(Platform.resolvedExecutable, [
      "--enable-asserts",
      "--deterministic",
      "pkg/front_end/test/strong_suite.dart",
      "-DskipVm=true",
      "--shards=${options.numberOfWorkers}",
      "--shard=${i + 1}",
      "--coverage=${coverageTmpDir.path}/",
    ]));
  }
  futures.add(Process.run(Platform.resolvedExecutable, [
    "--enable-asserts",
    "--deterministic",
    "pkg/front_end/test/parser_suite.dart",
    "--coverage=${coverageTmpDir.path}/",
  ]));
  futures.add(Process.run(Platform.resolvedExecutable, [
    "--enable-asserts",
    "--deterministic",
    "pkg/front_end/test/messages_suite.dart",
    "--coverage=${coverageTmpDir.path}/",
    // Skip spelling as it uses git which isn't supported with how this is run
    // on the try bots.
    "-DskipSpellCheck=true",
  ]));

  // Wait for isolates to terminate and clean up.
  Iterable<ProcessResult> runResults = await Future.wait(futures);

  print("Run finished.");

  Map<Uri, coverageMerger.CoverageInfo>? coverageData =
      await coverageMerger.mergeFromDirUri(
    Uri.base.resolve(".dart_tool/package_config.json"),
    coverageTmpDir.uri,
    silent: true,
    extraCoverageIgnores: ["coverage-ignore(suite):"],
    extraCoverageBlockIgnores: ["coverage-ignore-block(suite):"],
    addAndRemoveCommentsInFiles: options.addAndRemoveCommentsInFiles,
  );
  if (coverageData == null) throw "Failure in coverage.";

  void addResult(String testName, bool pass, {String? log}) {
    results.add(jsonEncode({
      "name": "coverage/$testName",
      "configuration": options.configurationName,
      "suite": "coverage",
      "test_name": testName,
      "expected": "Pass",
      "result": pass ? "Pass" : "Fail",
      "matches": pass,
    }));

    if (log != null) {
      logs.add(jsonEncode({
        "name": "coverage/$testName",
        "configuration": options.configurationName,
        "suite": "coverage",
        "test_name": testName,
        "result": pass ? "Pass" : "Fail",
        "log": log,
      }));
    }

    if (options.verbose || log != null) {
      String result = pass ? "PASS" : "FAIL";
      print("${testName}: ${result}");
      if (log != null) {
        print("  ${log.replaceAll('\n', '\n  ')}");
      }
    }
  }

  for (MapEntry<Uri, coverageMerger.CoverageInfo> coverageEntry
      in coverageData.entries) {
    if (coverageEntry.value.error) {
      // TODO(jensj): More info here would be good.
      addResult(coverageEntry.key.toString(), false, log: "Error");
    } else {
      StringBuffer sb = new StringBuffer();
      int hitCount = coverageEntry.value.hitCount;
      int missCount = coverageEntry.value.missCount;
      final bool pass = missCount == 0;
      if (!pass) {
        sb.write("${coverageEntry.value.visualization}");
        double percent = (hitCount / (hitCount + missCount) * 100);
        sb.write("\n\nExpected 100% coverage, but got $percent% "
            "($hitCount hits and $missCount misses).");
        sb.write("\n\nTo re-run this test, run:");
        var extraFlags = _assertsEnabled ? ' --enable-asserts' : '';
        // It looks like coverage results vary slightly based on the number of
        // tasks, so include a `--tasks=` argument in the repro instructions.
        //
        // TODO(paulberry): why do coverage results vary based on the number
        // of tasks? (Note: possibly due to
        // https://github.com/dart-lang/sdk/issues/42061)
        sb.write(
            "\n\n   dart$extraFlags pkg/front_end/test/coverage_suite.dart "
            "--tasks=${options.numberOfWorkers}");
        sb.write("\n\n   Or automatically insert ignore comments via");
        sb.write(
            "\n\n   dart$extraFlags pkg/front_end/test/coverage_suite.dart "
            "--tasks=${options.numberOfWorkers} "
            "--add-and-remove-comments");
        sb.write("\n\nIf that does not work, create a bug report and approve "
            "the failure.");
      }
      addResult(coverageEntry.key.toString(), pass,
          log: sb.isEmpty ? null : sb.toString());
    }
  }

  // Write results.json and logs.json.
  Uri resultJsonUri = options.outputDirectory.resolve("results.json");
  Uri logsJsonUri = options.outputDirectory.resolve("logs.json");
  await writeLinesToFile(resultJsonUri, results);
  await writeLinesToFile(logsJsonUri, logs);
  print("Log files written to ${resultJsonUri.toFilePath()} and"
      " ${logsJsonUri.toFilePath()}");
  print("Entire run took ${totalRuntime.elapsed}.");

  if (debug) {
    for (ProcessResult run in runResults) {
      if (run.exitCode != 0) {
        print(run.stdout);
      }
    }
  }

  bool timedOutOrCrashed = runResults.any((p) => p.exitCode != 0);
  if (timedOutOrCrashed) {
    print("Warning: At least one processes exited with a non-0 exit code.");
  }

  // Always return 0 or the try bot will become purple.
  exitCode = 0;
}

int getDefaultThreads() {
  int numberOfWorkers = 1;
  if (Platform.numberOfProcessors > 2) {
    numberOfWorkers = Platform.numberOfProcessors - 1;
  }
  if (numberOfWorkers > 5) numberOfWorkers = 5;
  return numberOfWorkers;
}

Future<void> writeLinesToFile(Uri uri, List<String> lines) async {
  await File.fromUri(uri).writeAsString(lines.map((line) => "$line\n").join());
}

class Options {
  final String? configurationName;
  final bool verbose;
  final bool debug;
  final bool addAndRemoveCommentsInFiles;
  final Uri outputDirectory;
  final int numberOfWorkers;

  Options(
    this.configurationName,
    this.verbose,
    this.debug,
    this.addAndRemoveCommentsInFiles,
    this.outputDirectory, {
    required this.numberOfWorkers,
  });

  static Options parse(List<String> args) {
    var parser = new ArgParser()
      ..addOption("named-configuration",
          abbr: "n",
          help: "configuration name to use for emitting json result files")
      ..addOption("output-directory",
          help: "directory to which results.json and logs.json are written")
      ..addFlag("verbose",
          abbr: "v", help: "print additional information", defaultsTo: false)
      ..addFlag("debug", help: "debug mode", defaultsTo: false)
      ..addOption("tasks",
          abbr: "j",
          help: "The number of parallel tasks to run.",
          defaultsTo: "${getDefaultThreads()}")
      ..addFlag("add-and-remove-comments",
          help: "Automatically remove old and then "
              "re-add ignore comments in files",
          defaultsTo: false)
      // These are not used but are here for compatibility with the test system.
      ..addOption("shards", help: "(Ignored) Number of shards", defaultsTo: "1")
      ..addOption("shard",
          help: "(Ignored) Which shard to run", defaultsTo: "1");
    ArgResults parsedOptions = parser.parse(args);
    String outputPath = parsedOptions["output-directory"] ?? ".";
    Uri outputDirectory = Uri.base.resolveUri(Uri.directory(outputPath));

    bool verbose = parsedOptions["verbose"];
    bool debug = parsedOptions["debug"];

    String tasksString = parsedOptions["tasks"];
    int? tasks = int.tryParse(tasksString);
    if (tasks == null || tasks < 1) {
      throw "--tasks (-j) has to be an integer >= 1";
    }
    bool addAndRemoveCommentsInFiles = parsedOptions["add-and-remove-comments"];

    if (verbose) {
      print("NOTE: Created with options\n  "
          "named config = ${parsedOptions["named-configuration"]},\n  "
          "verbose = ${verbose},\n  "
          "debug = ${debug},\n  "
          "${outputDirectory},\n  "
          "numberOfWorkers: ${tasks},\n  "
          "addAndRemoveCommentsInFiles = ${addAndRemoveCommentsInFiles}");
    }

    return Options(
      parsedOptions["named-configuration"],
      verbose,
      debug,
      addAndRemoveCommentsInFiles,
      outputDirectory,
      numberOfWorkers: tasks,
    );
  }
}

final bool _assertsEnabled = () {
  bool assertsEnabled = false;
  assert(assertsEnabled = true);
  return assertsEnabled;
}();
