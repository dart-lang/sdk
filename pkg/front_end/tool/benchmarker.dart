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
  bool doCacheBenchmarkingToo = false;
  bool doDisabledGcBenchmarkToo = false;
  bool silent = false;
  int iterations = 5;
  int core = 7;
  int gcRuns = 1;
  String? aotRuntime;
  String? checkFileSize;
  List<String> snapshots = [];
  List<List<String>> snapshotSpecificArguments = [];
  List<String> arguments = [];
  for (String arg in args) {
    if (arg.startsWith("--iterations=")) {
      iterations = int.parse(arg.substring("--iterations=".length));
    } else if (arg.startsWith("--gcs=")) {
      gcRuns = int.parse(arg.substring("--gcs=".length));
    } else if (arg.startsWith("--core=")) {
      core = int.parse(arg.substring("--core=".length));
    } else if (arg.startsWith("--aotruntime")) {
      aotRuntime = arg.substring("--aotruntime".length);
    } else if (arg.startsWith("--snapshot=")) {
      snapshots.add(arg.substring("--snapshot=".length));
    } else if (arg.startsWith("--arguments=")) {
      arguments.add(arg.substring("--arguments=".length));
    } else if (arg.startsWith("--sarguments=")) {
      // "specific arguments" or "snapshot arguments".
      while (snapshotSpecificArguments.length < snapshots.length) {
        snapshotSpecificArguments.add([]);
      }
      snapshotSpecificArguments[snapshotSpecificArguments.length - 1].add(
        arg.substring("--sarguments=".length),
      );
    } else if (arg.startsWith("--filesize=")) {
      checkFileSize = arg.substring("--filesize=".length);
    } else if (arg == "--cache") {
      doCacheBenchmarkingToo = true;
    } else if (arg == "--no-gc") {
      doDisabledGcBenchmarkToo = true;
    } else if (arg == "--silent") {
      silent = true;
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
  while (snapshotSpecificArguments.length < snapshots.length) {
    snapshotSpecificArguments.add([]);
  }

  _doRun(
    iterations,
    snapshots,
    aotRuntime,
    core,
    arguments,
    snapshotSpecificArguments,
    checkFileSize,
    cacheBenchmarking: false,
    silent: silent,
    gcRuns: gcRuns,
  );
  if (doCacheBenchmarkingToo) {
    print("");
    _doRun(
      iterations,
      snapshots,
      aotRuntime,
      core,
      arguments,
      snapshotSpecificArguments,
      checkFileSize,
      cacheBenchmarking: true,
      silent: silent,
      gcRuns: gcRuns,
    );
  }
  if (doDisabledGcBenchmarkToo) {
    print("");
    _doRun(
      iterations,
      snapshots,
      aotRuntime,
      core,
      arguments,
      snapshotSpecificArguments,
      checkFileSize,
      cacheBenchmarking: false,
      silent: silent,
      gcRuns: 0,
      extraVmArguments: [
        "--new_gen_semi_initial_size=10000",
        "--new_gen_semi_max_size=20000",
      ],
    );

    // TODO(jensj): Should we do a (number of) run(s) where we measure memory
    // usage?
  }
}

void _doRun(
  int iterations,
  List<String> snapshots,
  String aotRuntime,
  int core,
  List<String> arguments,
  List<List<String>> snapshotSpecificArguments,
  String? checkFileSize, {
  required bool cacheBenchmarking,
  required bool silent,
  required int gcRuns,
  List<String>? extraVmArguments,
}) {
  print(
    "Will now run $iterations+$gcRuns iterations with "
    "${snapshots.length} snapshots.",
  );

  if (extraVmArguments != null && extraVmArguments.isNotEmpty) {
    print("Running with extra vm arguments: ${extraVmArguments.join(" ")}");
  }

  int lines;
  {
    try {
      lines = stdout.terminalLines;
    } catch (_) {
      lines = 80;
    }

    if (lines > 80) lines = 80;
    int totalNumberOfRuns = (iterations + gcRuns) * snapshots.length;
    if (totalNumberOfRuns < lines) lines = totalNumberOfRuns;
    List<int> charCodes = List.filled(lines, ".".codeUnitAt(0));
    for (int i = 9; i < charCodes.length; i += 10) {
      charCodes[i] = "|".codeUnitAt(0);
    }
    print(new String.fromCharCodes(charCodes));
  }

  List<List<Map<String, num>>> runResults = [];
  List<List<GCInfo>> gcInfos = [];
  Warnings warnings = new Warnings();
  int writes = 0;
  for (int snapshotNum = 0; snapshotNum < snapshots.length; snapshotNum++) {
    String snapshot = snapshots[snapshotNum];
    List<String> usedArguments = [
      ...arguments,
      ...snapshotSpecificArguments[snapshotNum],
    ];
    List<GCInfo> gcInfo = [];
    gcInfos.add(gcInfo);
    List<Map<String, num>> snapshotResults = [];
    runResults.add(snapshotResults);
    for (int iteration = 0; iteration < iterations; iteration++) {
      // We want this silent to mean no stdout print, but still want progress
      // info which is what the dot provides.
      if (silent) {
        writes = _silentWrite(writes, lines);
      }
      Map<String, num> benchmarkRun = _benchmark(
        aotRuntime,
        core,
        snapshot,
        extraVmArguments ?? [],
        usedArguments,
        warnings: warnings,
        cacheBenchmarking: cacheBenchmarking,
        silent: silent,
      );
      if (checkFileSize != null) {
        File f = new File(checkFileSize);
        if (f.existsSync()) {
          benchmarkRun["filesize"] = f.lengthSync();
        }
      }
      snapshotResults.add(benchmarkRun);
    }

    // Do GC runs too.
    for (int i = 0; i < gcRuns; i++) {
      if (silent) {
        writes = _silentWrite(writes, lines);
      }
      gcInfo.add(
        _verboseGcRun(aotRuntime, snapshot, [], usedArguments, silent: true),
      );
    }
  }
  stdout.write("\n\n");

  List<Map<String, num>> firstSnapshotResults = runResults.first;
  String snapshot1Name = _getName(snapshots[0]);
  if (snapshotSpecificArguments[0].isNotEmpty) {
    snapshot1Name += " ${snapshotSpecificArguments[0].join(" ")}";
  }
  for (int i = 1; i < runResults.length; i++) {
    if (i > 1) print("");
    String comparedToSnapshotName = _getName(snapshots[i]);
    if (snapshotSpecificArguments[i].isNotEmpty) {
      comparedToSnapshotName += " ${snapshotSpecificArguments[i].join(" ")}";
    }
    print(
      "Comparing snapshot #1 ($snapshot1Name) with "
      "snapshot #${i + 1} ($comparedToSnapshotName)",
    );
    List<Map<String, num>> compareToResults = runResults[i];
    if (!_compare(firstSnapshotResults, compareToResults)) {
      print("No change.");
    }
    if (gcRuns >= 3) {
      print("\nComparing GC runtimes:");
      if (!_compareSingle(
        gcInfos[i].map((gcInfo) => gcInfo.combinedTime).toList(),
        gcInfos[0].map((gcInfo) => gcInfo.combinedTime).toList(),
        "Combined GC time",
      )) {
        print("No change in combined time.");
      }
    } else if (gcRuns > 0) {
      print("\nComparing GC data:");
      bool printedAnything = false;
      for (int gcNum = 0; gcNum < gcRuns; gcNum++) {
        printedAnything |= printGcDiff(gcInfos[0][gcNum], gcInfos[i][gcNum]);
      }
      if (!printedAnything) {
        print("'No' GC change.");
      }
    }
  }

  if (warnings.scalingInEffect) {
    print("Be aware that the above was with scaling in effect.");
    print("As such the results are likely useless.");
    print("Possibly some other process is using the hardware counters.");
    print("Running this tool");
    print("sudo out/ReleaseX64/dart pkg/front_end/tool/perf_event_tool.dart");
    print("will attempt to give you such information.");
  }
}

int _silentWrite(int previousWriteCount, int lines) {
  if (previousWriteCount >= lines) {
    stdout.write("\n");
    previousWriteCount = 0;
  }
  stdout.write(".");
  previousWriteCount++;
  return previousWriteCount;
}

String _getName(String urlIsh) {
  return Uri.parse(urlIsh).pathSegments.last;
}

void _help() {
  print("CFE benchmarker tool");
  print("");
  print("First create 2 or more aot snapshots of the code");
  print("you want to benchmark. E.g. by running:");
  print("");
  print(r"out/ReleaseX64/dart-sdk/bin/dart \");
  print(r"  compile aot-snapshot \");
  print(r"  pkg/front_end/tool/compile.dart");
  print("");
  print("then moving with e.g.");
  print("");
  print(r"mv pkg/front_end/tool/compile.aot \");
  print(r"  pkg/front_end/tool/compile.aot.1");
  print("");
  print("Then applying your code-change and compiling again,");
  print("this time moving to somewhere else (e.g. .2)");
  print("");
  print("Then run this tool via for instance");
  print("");
  print(r"out/ReleaseX64/dart pkg/front_end/tool/benchmarker.dart \");
  print(r"  --iterations=3 \");
  print(r"  --snapshot=pkg/front_end/tool/compile.aot.1 \");
  print(r"  --snapshot=pkg/front_end/tool/compile.aot.2 \");
  print(r"  --arguments=pkg/front_end/tool/compile.dart");
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
          print(
            "Warning: "
            "$caption has values $fromForCaption and $toForCaption",
          );
          break;
        }
      }
    }
    if (fromForCaption.isEmpty || toForCaption.isEmpty) continue;
    somethingWasSignificant |= _compareSingle(
      toForCaption,
      fromForCaption,
      caption,
    );
  }
  return somethingWasSignificant;
}

bool _compareSingle(List<num> to, List<num> from, String caption) {
  TTestResult stats = SimpleTTestStat.ttest(to, from);
  if (stats.significant) {
    print(
      "$caption: ${stats.percentChangeIfSignificant(fractionDigits: 4)} "
      "(${stats.valueChangeIfSignificant(fractionDigits: 2)}) "
      "(${stats.meanChangeStringIfSignificant(fractionDigits: 2)})",
    );
    return true;
  }
  return false;
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
  String snapshot,
  List<String> extraVmArguments,
  List<String> arguments, {
  String? aotRuntime,
  int? core,
  bool cacheBenchmarking = false,
}) {
  return _benchmark(
    aotRuntime ?? _computeAotRuntime(),
    core ?? 7,
    snapshot,
    extraVmArguments,
    arguments,
    silent: true,
    cacheBenchmarking: cacheBenchmarking,
  );
}

late final RegExp _extractNumbers = new RegExp(
  r"([\d+\,\.]+)\s+(.+)\s*",
  caseSensitive: false,
);

Map<String, num> _benchmark(
  String aotRuntime,
  int core,
  String snapshot,
  List<String> extraVmArguments,
  List<String> arguments, {
  bool silent = false,
  Warnings? warnings,
  bool cacheBenchmarking = false,
}) {
  if (!silent) stdout.write(".");

  // These influence scaling, so only pick 3 (apparently that's now the
  // magic limit)
  String scalingEvents =
      "cycles:u,"
      "instructions:u,"
      "branch-misses:u";
  if (cacheBenchmarking) {
    scalingEvents =
        "L1-icache-load-misses:u,"
        "LLC-loads:u,"
        "LLC-load-misses:u";
  }
  ProcessResult processResult = Process.runSync("perf", [
    "stat",
    "-B",
    "-e",
    // These doesn't influence scaling
    "task-clock:u,context-switches:u,cpu-migrations:u,page-faults:u,"
        // These influence scaling
        "$scalingEvents",
    "taskset",
    "-c",
    "$core",
    aotRuntime,
    "--deterministic",
    ...extraVmArguments,
    snapshot,
    ...arguments,
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
    String? scaling;
    if (pos >= 0) {
      // Check for scaling e.g.
      // ```
      //   974,702,464      cycles:u     (74.32%)
      //   932,606,794      cycles:u     (76.01%)
      //   922,272,003      cycles:u     (75.84%)
      //   942,191,386      cycles:u     (74.01%)
      // ```
      String comment = line.substring(pos);
      if (comment.trim().endsWith("%)")) {
        int lastStartParen = comment.lastIndexOf("(");
        if (lastStartParen < 0) {
          throw "Thought it found scaling for '$comment' "
              "but it didn't look as expected.";
        }
        scaling = comment.substring(lastStartParen + 1, comment.length - 1);
      }
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
      if (scaling != null) {
        print("WARNING: $caption is scaled at $scaling!");
        warnings?.scalingInEffect = true;
      }
    }
  }

  return result;
}

GCInfo _verboseGcRun(
  String aotRuntime,
  String snapshot,
  List<String> extraVmArguments,
  List<String> arguments, {
  bool silent = false,
}) {
  if (!silent) stdout.write(".");
  ProcessResult processResult = Process.runSync(aotRuntime, [
    "--deterministic",
    "--verbose-gc",
    ...extraVmArguments,
    snapshot,
    ...arguments,
  ]);
  if (processResult.exitCode != 0) {
    throw "Run failed with exit code ${processResult.exitCode}.\n"
        "stdout:\n${processResult.stdout}\n\n"
        "stderr:\n${processResult.stderr}\n\n";
  }
  if (processResult.stdout != "" && !silent) {
    print(processResult.stdout);
  }
  return parseVerboseGcOutput(processResult);
}

String _computeAotRuntime() {
  File f = new File.fromUri(
    repoDir.resolve("out/ReleaseX64/dart-sdk/bin/dartaotruntime"),
  );
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

GCInfo parseVerboseGcOutput(ProcessResult processResult) {
  List<String> stderrLines = processResult.stderr.split("\n");
  return parseVerboseGcText(stderrLines);
}

GCInfo parseVerboseGcText(List<String> stderrLines) {
  double combinedTime = 0;
  Map<String, int> countWhat = {};
  for (String line in stderrLines) {
    if (!line.trim().startsWith("[")) continue;
    if (line.indexOf(",") < 0) continue;
    // Hardcoding this might not be the best solution, but works for now.
    // The data is space and comma delimited like this (cut off in both
    // directions):
    //
    // ```
    // [ GC isolate   | space (reason)           | GC# | start | time | [...]
    // [              |                          |     |  (s)  | (ms) | [...]
    // [ main         ,  StartCMark(    external),    1,   0.02,   0.7, [...]
    // [...]
    // ```
    //
    // and (currently) contains this information:
    // * [0]: GC isolate
    // * [1]: space (reason)
    // * [2]: GC#
    // * [3]: start (s)
    // * [4]: time (ms)
    // * [5]: new gen used (MB) before
    // * [6]: new gen used (MB) after
    // * [7]: new gen capacity (MB) before
    // * [8]: new gen capacity (MB) after
    // * [9]: new gen external (MB) before
    // * [10]: new gen external (MB) after
    // * [11]: old gen used (MB) before
    // * [12]: old gen used (MB) after
    // * [13]: old gen capacity (MB) before
    // * [14]: old gen capacity (MB) after
    // * [15]: old gen external (MB) before
    // * [16]: old gen external (MB) after
    // * [17]: store buffer before
    // * [18]: store buffer after
    // * [19]: delta used new (MB)
    // * [20]: delta used old (MB)
    // * [21]: (nothing, but the cell before ends in a comma)
    List<String> cells = line.split(",");
    String spaceReason = cells[1].trim();
    double time = double.parse(cells[4].trim());
    combinedTime += time;
    countWhat[spaceReason] = (countWhat[spaceReason] ?? 0) + 1;
  }
  return new GCInfo(combinedTime, countWhat);
}

void combinedGcDiff(List<GCInfo> prev, List<GCInfo> current) {
  prev.map((gcInfo) => gcInfo.combinedTime).toList();
}

bool printGcDiff(GCInfo prev, GCInfo current) {
  Set<String> allKeys = {...prev.countWhat.keys, ...current.countWhat.keys};
  bool printedAnything = false;
  for (String key in allKeys) {
    int prevValue = prev.countWhat[key] ?? 0;
    int currentValue = current.countWhat[key] ?? 0;
    if (prevValue == currentValue) continue;
    printedAnything = true;
    print("$key goes from $prevValue to $currentValue");
  }
  if (printedAnything) {
    print(
      "Notice combined GC time goes "
      "from ${prev.combinedTime.toStringAsFixed(0)} ms "
      "to ${current.combinedTime.toStringAsFixed(0)} ms "
      "(notice only 1 run each).",
    );
  }
  return printedAnything;
}

class GCInfo {
  final double combinedTime;
  final Map<String, int> countWhat;

  GCInfo(this.combinedTime, this.countWhat);
}

class Warnings {
  bool scalingInEffect = false;
}
