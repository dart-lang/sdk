// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:io";

import '../test/simple_stats.dart';
import '../test/utils/io_utils.dart' show computeRepoDirUri;

late final Uri repoDir = computeRepoDirUri();

void main(List<String> args) {
  if (args.contains("--help")) return _help();
  _checkEnvironment();
  int iterations = 5;
  int core = 7;
  String? aotRuntime;
  List<String> snapshots = [];
  List<String> arguments = [];
  for (String arg in args) {
    if (arg.startsWith("--iterations=")) {
      iterations = int.parse(arg.substring("--iterations=".length));
    } else if (arg.startsWith("--core=")) {
      core = int.parse(arg.substring("--core=".length));
    } else if (arg.startsWith("--aotruntime")) {
      aotRuntime = arg.substring("--aotruntime".length);
    } else if (arg.startsWith("--snapshot=")) {
      snapshots.add(arg.substring("--snapshot=".length));
    } else if (arg.startsWith("--arguments=")) {
      arguments.add(arg.substring("--arguments=".length));
    } else {
      throw "Don't know argument '$arg'";
    }
  }
  aotRuntime ??= _computeAotRuntime();

  if (snapshots.length < 2) {
    throw "Can't compare less than two snapshots. Specify using '--snapshot='";
  }
  if (arguments.isEmpty) {
    print("Note: Running without any arguments to the snapshots.");
  }

  print("Will now run $iterations iterations with "
      "${snapshots.length} snapshots.");

  List<List<Map<String, num>>> runResults = [];
  for (String snapshot in snapshots) {
    List<Map<String, num>> snapshotResults = [];
    runResults.add(snapshotResults);
    for (int iteration = 0; iteration < iterations; iteration++) {
      snapshotResults
          .add(_benchmark(aotRuntime, core, snapshot, [], arguments));
    }
  }
  stdout.write("\n\n");

  List<Map<String, num>> firstSnapshotResults = runResults.first;
  for (int i = 1; i < runResults.length; i++) {
    if (i > 1) print("");
    print("Comparing snapshot #1 with snapshot #${i + 1}");
    List<Map<String, num>> compareToResults = runResults[i];
    if (!_compare(firstSnapshotResults, compareToResults)) {
      print("No change.");
    }
  }
}

void _help() {
  print("CFE benchmarker tool");
  print("");
  print("First create 2 or more aot snapshots of the code");
  print("you want to benchmark. E.g. by running:");
  print("");
  print(r"out/ReleaseX64/dart-sdk/bin/dart \");
  print(r"  compile aot-snapshot \");
  print(r"  pkg/front_end/tool/_fasta/compile.dart");
  print("");
  print("then moving with e.g.");
  print("");
  print(r"mv pkg/front_end/tool/_fasta/compile.aot \");
  print(r"  pkg/front_end/tool/_fasta/compile.aot.1");
  print("");
  print("Then applying your code-change and compiling again,");
  print("this time moving to somewhere else (e.g. .2)");
  print("");
  print("Then run this tool via for instance");
  print("");
  print(r"out/ReleaseX64/dart pkg/front_end/tool/benchmarker.dart \");
  print(r"  --iterations=3 \");
  print(r"  --snapshot=pkg/front_end/tool/_fasta/compile.aot.1 \");
  print(r"  --snapshot=pkg/front_end/tool/_fasta/compile.aot.2 \");
  print(r"  --arguments=pkg/front_end/tool/_fasta/compile.dart");
  print("");
  print("This will run the 2 snapshots 3 times each, each time asking it");
  print("to compile compile.dart, then do statistics on the data returned");
  print("by `perf stat` where especially `instructions:u` and `branches:u`");
  print("has been observed to be stable.");
}

bool compare(List<Map<String, num>> from, List<Map<String, num>> to) {
  return _compare(from, to);
}

bool _compare(List<Map<String, num>> from, List<Map<String, num>> to) {
  bool somethingWasSignificant = false;
  Set<String> allCaptions = {};
  for (Map<String, num> entry in [...from, ...to]) {
    allCaptions.addAll(entry.keys);
  }
  for (String caption in allCaptions) {
    List<num> fromForCaption = _extractDataForCaption(caption, from);
    List<num> toForCaption = _extractDataForCaption(caption, to);
    if (caption.startsWith("context-switches") ||
        caption.startsWith("cpu-migrations")) {
      // These are seemingly always 0 --- if they're not we'll print a warning.
      for (num value in [...fromForCaption, ...toForCaption]) {
        if (value != 0) {
          print("Warning: "
              "$caption has values $fromForCaption and $toForCaption");
          break;
        }
      }
    }
    if (fromForCaption.isEmpty || toForCaption.isEmpty) continue;
    TTestResult stats = SimpleTTestStat.ttest(toForCaption, fromForCaption);
    if (stats.significant) {
      somethingWasSignificant = true;
      print("$caption: ${stats.percentChangeIfSignificant(fractionDigits: 4)} "
          "(${stats.valueChangeIfSignificant(fractionDigits: 2)})");
    }
  }
  return somethingWasSignificant;
}

List<num> _extractDataForCaption(String caption, List<Map<String, num>> data) {
  List<num> result = [];
  for (Map<String, num> entry in data) {
    num? value = entry[caption];
    if (value != null) result.add(value);
  }
  return result;
}

Map<String, num> benchmark(
    String snapshot, List<String> extraVmArguments, List<String> arguments,
    {String? aotRuntime, int? core}) {
  return _benchmark(aotRuntime ?? _computeAotRuntime(), core ?? 7, snapshot,
      extraVmArguments, arguments,
      silent: true);
}

late final RegExp _extractNumbers =
    new RegExp(r"([\d+\,\.]+)\s+(.+)\s*", caseSensitive: false);

Map<String, num> _benchmark(String aotRuntime, int core, String snapshot,
    List<String> extraVmArguments, List<String> arguments,
    {bool silent = false}) {
  if (!silent) stdout.write(".");
  ProcessResult processResult = Process.runSync("perf", [
    "stat",
    "-B",
    "taskset",
    "-c",
    "$core",
    aotRuntime,
    "--deterministic",
    ...extraVmArguments,
    snapshot,
    ...arguments
  ]);
  if (processResult.exitCode != 0) {
    throw "Run failed with exit code ${processResult.exitCode}.\n"
        "stdout:\n${processResult.stdout}\n\n"
        "stderr:\n${processResult.stderr}\n\n";
  }
  if (processResult.stdout != "" && !silent) {
    print(processResult.stdout);
  }
  String stderr = processResult.stderr;
  List<String> lines = stderr.split("\n");
  Map<String, num> result = new Map<String, num>();
  for (String line in lines) {
    int pos = line.indexOf("#");
    if (pos >= 0) {
      line = line.substring(0, pos);
    }
    for (RegExpMatch match in _extractNumbers.allMatches(line)) {
      String stringValue = match.group(1)!.trim();
      String caption = match.group(2)!.trim();
      stringValue = stringValue.replaceAll(",", "");
      num value;
      if (stringValue.contains(".")) {
        value = double.parse(stringValue);
      } else {
        value = int.parse(stringValue);
      }
      result[caption] = value;
    }
  }

  return result;
}

String _computeAotRuntime() {
  File f = new File.fromUri(
      repoDir.resolve("out/ReleaseX64/dart-sdk/bin/dartaotruntime"));
  if (f.existsSync()) {
    return f.path;
  } else {
    throw "Couldn't find the aot runtime. Have you compiled everything?";
  }
}

void _checkEnvironment() {
  if (!Platform.isLinux) {
    throw "This (probably) only works in Linux";
  }
  if (!_whichOk("taskset")) {
    throw "Couldn't find 'taskset'. Please install that.";
  }
  if (!_whichOk("perf")) {
    throw "Couldn't find 'perf'. Please install that.";
  }
}

bool _whichOk(String what) {
  ProcessResult result = Process.runSync("which", [what]);
  return result.exitCode == 0;
}
