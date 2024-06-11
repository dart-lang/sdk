// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert' show jsonEncode;
import 'dart:io'
    show Directory, File, Platform, Process, ProcessResult, exitCode;

import 'package:args/args.dart' show ArgParser;
import 'package:args/src/arg_results.dart';

import '../tool/coverage_merger.dart' as coverageMerger;

part 'coverage_suite_expected.dart';

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
      "pkg/front_end/test/fasta/strong_suite.dart",
      "-DskipVm=true",
      "--shards=${options.numberOfWorkers}",
      "--shard=${i + 1}",
      "--coverage=${coverageTmpDir.path}/",
    ]));
  }

  // Wait for isolates to terminate and clean up.
  Iterable<ProcessResult> runResults = await Future.wait(futures);

  print("Run finished.");

  Map<Uri, coverageMerger.CoverageInfo>? coverageData =
      coverageMerger.mergeFromDirUri(
    Uri.base.resolve(".dart_tool/package_config.json"),
    coverageTmpDir.uri,
    silent: true,
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

  StringBuffer updatedExpectations = new StringBuffer();
  updatedExpectations.write("""
// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of "coverage_suite.dart";

// This is the currently recorded state
// using out/ReleaseX64/dart-sdk/bin/dart (which for instance makes a
// difference for compute_platform_binaries_location.dart).
const Map<String, ({int hitCount, int missCount})> _expect = {
""");

  for (MapEntry<Uri, coverageMerger.CoverageInfo> coverageEntry
      in coverageData.entries) {
    if (coverageEntry.value.error) {
      // TODO(jensj): More info here would be good.
      addResult(coverageEntry.key.toString(), false, log: "Error");
    } else {
      StringBuffer sb = new StringBuffer();
      int hitCount = coverageEntry.value.hitCount;
      int missCount = coverageEntry.value.missCount;
      double percent = (hitCount / (hitCount + missCount) * 100);
      if (options.updateExpectations) {
        updatedExpectations.writeln("  // $percent%.");
        updatedExpectations.writeln("  \"${coverageEntry.key}\": "
            "(hitCount: $hitCount, missCount: $missCount,),");
        continue;
      }
      bool pass = true;
      ({int hitCount, int missCount})? expected =
          _expect[coverageEntry.key.toString()];
      if (expected != null) {
        // TODO(jensj): Should we warn if hitCount goes down?
        // Or be ok with it if both hitCount and missCount goes up?
        // Or something else?
        double expectedPercent = (expected.hitCount /
            (expected.hitCount + expected.missCount) *
            100);
        int requireAtLeast = expectedPercent.floor();
        pass = percent >= requireAtLeast;
        if (!pass) {
          sb.write("${coverageEntry.value.visualization}");
          sb.write("\n\nExpected at least $requireAtLeast%, got $percent% "
              "($hitCount hits (expected: ${expected.hitCount}) and "
              "$missCount misses (expected: ${expected.missCount})).");
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
          sb.write("\n\n   Or update the expectations directly via");
          sb.write(
              "\n\n   dart$extraFlags pkg/front_end/test/coverage_suite.dart "
              "--tasks=${options.numberOfWorkers} --updateExpectations");
        }
      }
      addResult(coverageEntry.key.toString(), pass,
          log: sb.isEmpty ? null : sb.toString());
    }
  }

  updatedExpectations.writeln("};");
  if (options.updateExpectations) {
    File f = new File.fromUri(
        Uri.base.resolve("pkg/front_end/test/coverage_suite_expected.dart"));
    f.writeAsStringSync(updatedExpectations.toString());
    ProcessResult formatResult =
        Process.runSync(Platform.resolvedExecutable, ["format", f.path]);
    print("Formatting exit-code: ${formatResult.exitCode}");
  }

  // Write results.json and logs.json.
  Uri resultJsonUri = options.outputDirectory.resolve("results.json");
  Uri logsJsonUri = options.outputDirectory.resolve("logs.json");
  await writeLinesToFile(resultJsonUri, results);
  await writeLinesToFile(logsJsonUri, logs);
  print("Log files written to ${resultJsonUri.toFilePath()} and"
      " ${logsJsonUri.toFilePath()}");
  print("Entire run took ${totalRuntime.elapsed}.");

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
  final bool updateExpectations;
  final Uri outputDirectory;
  final int numberOfWorkers;

  Options(
    this.configurationName,
    this.verbose,
    this.debug,
    this.updateExpectations,
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
      ..addFlag("updateExpectations",
          help: "update expectations", defaultsTo: false)
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
    bool updateExpectations = parsedOptions["updateExpectations"];

    if (verbose) {
      print("NOTE: Created with options\n  "
          "named config = ${parsedOptions["named-configuration"]},\n  "
          "verbose = ${verbose},\n  "
          "debug = ${debug},\n  "
          "${outputDirectory},\n  "
          "numberOfWorkers: ${tasks},\n  "
          "updateExpectations = ${updateExpectations}");
    }

    return Options(
      parsedOptions["named-configuration"],
      verbose,
      debug,
      updateExpectations,
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
