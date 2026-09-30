// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:convert";
import "dart:io";
import "dart:math";

import '../test/utils/io_utils.dart' show computeRepoDirUri;
import 'benchmarker_stats.dart';

late final Uri repoDir = computeRepoDirUri();

void main(List<String> args) {
  if (args.contains("--help")) return _help();
  checkEnvironment();
  bool doCacheBenchmarkingToo = false;
  bool doDisabledGcBenchmarkToo = false;
  bool silent = false;
  bool showAll = false;
  bool interleave = true;
  int? seed;
  int iterations = 5;
  int warmup = 1;
  int core = 7;
  int gcRuns = 1;
  String? aotRuntime;
  String? checkFileSize;
  String? rawOutputPath;
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
    } else if (arg.startsWith("--aotruntime=")) {
      aotRuntime = arg.substring("--aotruntime=".length);
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
    } else if (arg == "--show-all") {
      showAll = true;
    } else if (arg.startsWith("--raw-output=")) {
      rawOutputPath = arg.substring("--raw-output=".length);
      if (rawOutputPath.isEmpty) {
        throw "--raw-output requires a file name (e.g. --raw-output=out.json).";
      }
    } else if (arg == "--no-interleave") {
      interleave = false;
    } else if (arg.startsWith("--seed=")) {
      String value = arg.substring("--seed=".length);
      seed = int.tryParse(value);
      if (seed == null) throw "--seed must be an integer (got '$value').";
    } else if (arg.startsWith("--warmup=")) {
      String value = arg.substring("--warmup=".length);
      int? parsed = int.tryParse(value);
      if (parsed == null) throw "--warmup must be an integer (got '$value').";
      warmup = parsed;
    } else {
      throw "Don't know argument '$arg'";
    }
  }
  aotRuntime ??= _computeAotRuntime();

  if (snapshots.length < 2) {
    throw "Can't compare less than two snapshots. Specify using '--snapshot='";
  }
  if (iterations < 2) {
    // The t-test needs at least two samples per snapshot to estimate the
    // variance.
    throw "--iterations must be at least 2 (got $iterations).";
  }
  if (warmup < 0) {
    throw "--warmup must not be negative (got $warmup).";
  }
  if (arguments.isEmpty) {
    print("Note: Running without any arguments to the snapshots.");
  }
  while (snapshotSpecificArguments.length < snapshots.length) {
    snapshotSpecificArguments.add([]);
  }
  Random? random;
  if (interleave) {
    seed ??= new Random().nextInt(1 << 32);
    random = new Random(seed);
    print(
      "Interleaving runs in random order "
      "(seed $seed; pass --seed=$seed to reproduce).",
    );
    print("Results use a paired t-test on the per-round differences.");
  } else {
    print("Not interleaving runs.");
    print("Results use an unpaired t-test.");
  }
  RawOutput? rawOutput = rawOutputPath == null
      ? null
      : new RawOutput(
          commandLineArguments: args,
          snapshots: snapshots,
          snapshotSpecificArguments: snapshotSpecificArguments,
          arguments: arguments,
          core: core,
          interleave: interleave,
          seed: interleave ? seed : null,
        );

  _doRun(
    iterations,
    warmup,
    snapshots,
    aotRuntime,
    core,
    arguments,
    snapshotSpecificArguments,
    checkFileSize,
    cacheBenchmarking: false,
    silent: silent,
    showAll: showAll,
    gcRuns: gcRuns,
    rawOutput: rawOutput,
    random: random,
    phase: "default",
  );
  if (doCacheBenchmarkingToo) {
    print("");
    _doRun(
      iterations,
      warmup,
      snapshots,
      aotRuntime,
      core,
      arguments,
      snapshotSpecificArguments,
      checkFileSize,
      cacheBenchmarking: true,
      silent: silent,
      showAll: showAll,
      gcRuns: gcRuns,
      rawOutput: rawOutput,
      random: random,
      phase: "cache",
    );
  }
  if (doDisabledGcBenchmarkToo) {
    print("");
    _doRun(
      iterations,
      warmup,
      snapshots,
      aotRuntime,
      core,
      arguments,
      snapshotSpecificArguments,
      checkFileSize,
      cacheBenchmarking: false,
      silent: silent,
      showAll: showAll,
      gcRuns: 0,
      extraVmArguments: [
        "--new_gen_semi_initial_size=10000",
        "--new_gen_semi_max_size=20000",
      ],
      rawOutput: rawOutput,
      random: random,
      phase: "no-gc",
    );

    // TODO(jensj): Should we do a (number of) run(s) where we measure memory
    // usage?
  }

  if (rawOutput != null) {
    rawOutput.writeTo(rawOutputPath!);
    print("");
    print("Wrote raw measurements to $rawOutputPath");
  }
}

void _doRun(
  int iterations,
  int warmup,
  List<String> snapshots,
  String aotRuntime,
  int core,
  List<String> arguments,
  List<List<String>> snapshotSpecificArguments,
  String? checkFileSize, {
  required bool cacheBenchmarking,
  required bool silent,
  required bool showAll,
  required int gcRuns,
  List<String>? extraVmArguments,
  RawOutput? rawOutput,
  required String phase,

  // If non-null, the runs are interleaved, using `random` to pick the order
  // of the snapshots in each round. If null, all runs of one snapshot are
  // done before moving on to the next snapshot.
  required Random? random,
}) {
  print(
    "Will now run $iterations+$gcRuns iterations with "
    "${snapshots.length} snapshots.",
  );
  if (warmup > 0) {
    print(
      "Each snapshot will first be run $warmup extra time(s) as warm-up; "
      "these runs are not included in the results.",
    );
  }

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
    int totalNumberOfRuns = (warmup + iterations + gcRuns) * snapshots.length;
    if (totalNumberOfRuns < lines) lines = totalNumberOfRuns;
    List<int> charCodes = List.filled(lines, ".".codeUnitAt(0));
    for (int i = 9; i < charCodes.length; i += 10) {
      charCodes[i] = "|".codeUnitAt(0);
    }
    print(new String.fromCharCodes(charCodes));
  }

  List<List<Map<String, num>>> runResults = [
    for (int i = 0; i < snapshots.length; i++) [],
  ];
  List<List<GCInfo>> gcInfos = [for (int i = 0; i < snapshots.length; i++) []];
  Warnings warnings = new Warnings();
  int writes = 0;

  List<String> usedArgumentsFor(int snapshotNum) => [
    ...arguments,
    ...snapshotSpecificArguments[snapshotNum],
  ];

  // Runs [snapshotNum] under `perf stat`. If [isWarmup] is `true`, the result
  // is only recorded in the raw output, not used in the comparison.
  void measure(
    int snapshotNum,
    int iteration, {
    int? positionInRound,
    bool isWarmup = false,
  }) {
    // We want this silent to mean no stdout print, but still want progress
    // info which is what the dot provides.
    if (silent) {
      writes = _silentWrite(writes, lines);
    }
    DateTime startTime = new DateTime.now();
    Map<String, num> benchmarkRun = _benchmark(
      aotRuntime,
      core,
      snapshots[snapshotNum],
      extraVmArguments ?? [],
      usedArgumentsFor(snapshotNum),
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
    if (!isWarmup) runResults[snapshotNum].add(benchmarkRun);
    rawOutput?.addRun(
      phase: phase,
      kind: isWarmup ? "warmup" : "measure",
      snapshotIndex: snapshotNum,
      iteration: iteration,
      positionInRound: positionInRound,
      startTime: startTime,
      endTime: new DateTime.now(),
      values: benchmarkRun,
    );
  }

  void gcRun(int snapshotNum, int iteration, {int? positionInRound}) {
    if (silent) {
      writes = _silentWrite(writes, lines);
    }
    DateTime startTime = new DateTime.now();
    GCInfo info = _verboseGcRun(
      aotRuntime,
      snapshots[snapshotNum],
      [],
      usedArgumentsFor(snapshotNum),
      silent: true,
    );
    gcInfos[snapshotNum].add(info);
    rawOutput?.addRun(
      phase: phase,
      kind: "gc",
      snapshotIndex: snapshotNum,
      iteration: iteration,
      positionInRound: positionInRound,
      startTime: startTime,
      endTime: new DateTime.now(),
      values: {"combinedGcTimeMs": info.combinedTime, ...info.countWhat},
    );
  }

  if (random != null) {
    // Warm up (e.g. the file system cache and the CPU caches) before
    // measuring anything.
    for (int iteration = 0; iteration < warmup; iteration++) {
      List<int> order = _roundOrder(random, snapshots.length);
      for (int position = 0; position < order.length; position++) {
        measure(
          order[position],
          iteration,
          positionInRound: position,
          isWarmup: true,
        );
      }
    }
    // Interleave the runs: each round runs every snapshot once, in a random
    // order. This way slow drift in the machine's performance over the
    // course of the session affects all snapshots equally, instead of
    // showing up as a difference between them.
    for (int iteration = 0; iteration < iterations; iteration++) {
      List<int> order = _roundOrder(random, snapshots.length);
      for (int position = 0; position < order.length; position++) {
        measure(order[position], iteration, positionInRound: position);
      }
    }
    for (int i = 0; i < gcRuns; i++) {
      List<int> order = _roundOrder(random, snapshots.length);
      for (int position = 0; position < order.length; position++) {
        gcRun(order[position], i, positionInRound: position);
      }
    }
  } else {
    for (int snapshotNum = 0; snapshotNum < snapshots.length; snapshotNum++) {
      for (int iteration = 0; iteration < warmup; iteration++) {
        measure(snapshotNum, iteration, isWarmup: true);
      }
      for (int iteration = 0; iteration < iterations; iteration++) {
        measure(snapshotNum, iteration);
      }
      // Do GC runs too.
      for (int i = 0; i < gcRuns; i++) {
        gcRun(snapshotNum, i);
      }
    }
  }
  stdout.write("\n\n");

  // When the runs are interleaved, the i'th run of each snapshot was done in
  // the same round, so the measurements can be compared pairwise, which
  // cancels out drift in the machine's performance.
  bool paired = random != null;
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
    if (!_compare(
      firstSnapshotResults,
      compareToResults,
      showAll: showAll,
      paired: paired,
    )) {
      print("No change.");
    }
    if (gcRuns >= 3) {
      print("\nComparing GC runtimes:");
      if (!_compareSingle(
        gcInfos[i].map((gcInfo) => gcInfo.combinedTime).toList(),
        gcInfos[0].map((gcInfo) => gcInfo.combinedTime).toList(),
        "Combined GC time",
        showAll: showAll,
        paired: paired,
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

  print("");
  _checkDrift(runResults, interleaved: random != null);

  if (warnings.scalingInEffect) {
    print("Be aware that the above was with scaling in effect.");
    print("As such the results are likely useless.");
    print("Possibly some other process is using the hardware counters.");
    print("Running this tool");
    print("sudo out/ReleaseX64/dart pkg/front_end/tool/perf_event_tool.dart");
    print("will attempt to give you such information.");
  }
}

/// Checks whether any metric drifted (got steadily larger or smaller) over
/// the course of the runs of any snapshot, and prints a warning if so.
///
/// Drift means that the machine's performance wasn't stable during the
/// session. Without interleaving, drift shows up as a spurious difference
/// between the snapshots.
void _checkDrift(
  List<List<Map<String, num>>> runResults, {
  required bool interleaved,
}) {
  Set<String> allCaptions = {
    for (List<Map<String, num>> results in runResults)
      for (Map<String, num> entry in results) ...entry.keys,
  };
  int checks = 0;
  List<String> driftWarnings = [];
  for (String caption in allCaptions) {
    for (int i = 0; i < runResults.length; i++) {
      List<num> values = _extractDataForCaption(caption, runResults[i]);
      if (values.length < 3) continue;
      checks++;
      Trend trend = linearTrend(values);
      if (!trend.significant) continue;
      double? percentChange = trend.percentChangeOverSeries;
      double? percentConfidence = trend.percentConfidenceOverSeries;
      if (percentChange == null || percentConfidence == null) continue;
      driftWarnings.add(
        "$caption for snapshot #${i + 1} changed by "
        "${percentChange.toStringAsFixed(4)}% +/- "
        "${percentConfidence.toStringAsFixed(4)}% "
        "from the first to the last run.",
      );
    }
  }
  if (checks == 0) return;
  if (driftWarnings.isEmpty) {
    print("Drift check: no significant drift detected.");
    return;
  }
  print("Drift check: the following metrics drifted during the session:");
  for (String warning in driftWarnings) {
    print("  $warning");
  }
  print(
    "  (With $checks checks at the 95% confidence level, about "
    "${(checks * 0.05).toStringAsFixed(1)} false alarms are expected by "
    "chance.)",
  );
  if (interleaved) {
    print(
      "  Interleaving and the paired t-test compensate for slow drift, "
      "but drift suggests that the machine's performance isn't stable.",
    );
  } else {
    print(
      "  Because the runs weren't interleaved, drift can show up as a "
      "spurious difference between snapshots. Consider running without "
      "--no-interleave.",
    );
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

/// Returns the indices `0 .. count - 1` in a random order.
List<int> _roundOrder(Random random, int count) =>
    [for (int i = 0; i < count; i++) i]..shuffle(random);

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
  print("");
  print("Additional options:");
  print("");
  print("  --raw-output=<file>");
  print("    Write every individual measurement (with timestamps) to <file>");
  print("    as JSON, for offline analysis.");
  print("");
  print("  --show-all");
  print("    Print the comparison for every metric, including the standard");
  print("    deviations and whether the change is significant, instead of");
  print("    only printing the significant changes.");
  print("");
  print("  --no-interleave");
  print("    By default, the runs are interleaved: each round runs every");
  print("    snapshot once, in a random order, so that slow drift in the");
  print("    machine's performance affects all snapshots equally, and the");
  print("    results are computed with a paired t-test on the per-round");
  print("    differences. With this option, all runs of one snapshot are");
  print("    done before the next, and an unpaired t-test is used.");
  print("");
  print("  --seed=<n>");
  print("    Seed for the random order of interleaved runs (by default a");
  print("    random seed is chosen and printed).");
  print("");
  print("  --warmup=<n>");
  print("    Run each snapshot <n> extra times (default 1) before the");
  print("    measured runs. These runs aren't included in the results.");
}

bool compare(
  List<Map<String, num>> from,
  List<Map<String, num>> to, {
  bool showAll = false,
}) {
  return _compare(from, to, showAll: showAll, paired: false);
}

/// Compares the measurements in [from] and [to], printing the metrics that
/// changed significantly (or all metrics if [showAll] is `true`).
///
/// If [paired] is `true`, `from[i]` and `to[i]` must have been measured in
/// the same round, and a paired t-test is used. Otherwise the two lists are
/// treated as independent samples.
///
/// Returns whether any metric changed significantly.
bool _compare(
  List<Map<String, num>> from,
  List<Map<String, num>> to, {
  required bool showAll,
  required bool paired,
}) {
  bool somethingWasSignificant = false;
  Set<String> allCaptions = {};
  for (Map<String, num> entry in [...from, ...to]) {
    allCaptions.addAll(entry.keys);
  }
  for (String caption in allCaptions) {
    List<num> fromForCaption;
    List<num> toForCaption;
    if (paired) {
      (fromForCaption, toForCaption) = _extractPairedDataForCaption(
        caption,
        from,
        to,
      );
    } else {
      fromForCaption = _extractDataForCaption(caption, from);
      toForCaption = _extractDataForCaption(caption, to);
    }
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
    // A paired t-test needs at least two pairs to estimate the variance.
    if (paired && fromForCaption.length < 2) continue;
    somethingWasSignificant |= _compareSingle(
      toForCaption,
      fromForCaption,
      caption,
      showAll: showAll,
      paired: paired,
    );
  }
  return somethingWasSignificant;
}

/// Compares [to] against [from] for the metric [caption], printing the
/// result if it is significant (or if [showAll] is `true`).
///
/// If [paired] is `true`, `from[i]` and `to[i]` must have been measured in
/// the same round, and a paired t-test is used.
///
/// Returns whether the result was significant.
bool _compareSingle(
  List<num> to,
  List<num> from,
  String caption, {
  bool showAll = false,
  bool paired = false,
}) {
  Comparison comparison = paired
      ? comparePaired(from, to)
      : compareUnpaired(from, to);
  if (comparison.significant || showAll) {
    StringBuffer line = new StringBuffer(
      "$caption: "
      "${_formatPercent(comparison.percentDiff)} +/- "
      "${_formatPercent(comparison.percentConfidence)} "
      "(${comparison.diff.toStringAsFixed(2)} +/- "
      "${comparison.confidence.toStringAsFixed(2)}) "
      "(${comparison.fromMean.toStringAsFixed(2)} -> "
      "${comparison.toMean.toStringAsFixed(2)})",
    );
    if (showAll) {
      line.write(
        " (sd: ${comparison.fromStdDev.toStringAsFixed(2)} / "
        "${comparison.toStdDev.toStringAsFixed(2)}",
      );
      double? diffStdDev = comparison.diffStdDev;
      if (diffStdDev != null) {
        line.write("; sd of diff: ${diffStdDev.toStringAsFixed(2)}");
      }
      line.write(")");
      line.write(
        comparison.significant ? " [significant]" : " [not significant]",
      );
    }
    print(line);
  }
  return comparison.significant;
}

String _formatPercent(double? percent) =>
    percent == null ? "n/a%" : "${percent.toStringAsFixed(4)}%";

List<num> _extractDataForCaption(String caption, List<Map<String, num>> data) {
  List<num> result = [];
  for (Map<String, num> entry in data) {
    num? value = entry[caption];
    if (value != null) result.add(value);
  }
  return result;
}

/// Extracts the values for [caption] from [from] and [to], keeping only the
/// rounds where both have a value, so that the returned lists stay aligned
/// (the i'th element of each list comes from the same round).
(List<num>, List<num>) _extractPairedDataForCaption(
  String caption,
  List<Map<String, num>> from,
  List<Map<String, num>> to,
) {
  List<num> fromResult = [];
  List<num> toResult = [];
  int count = min(from.length, to.length);
  for (int i = 0; i < count; i++) {
    num? fromValue = from[i][caption];
    num? toValue = to[i][caption];
    if (fromValue != null && toValue != null) {
      fromResult.add(fromValue);
      toResult.add(toValue);
    }
  }
  return (fromResult, toResult);
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

late final RegExp _extractPerfNumbers = new RegExp(
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
  ProcessResult processResult = Process.runSync("time", [
    "-v",
    "perf",
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
    for (RegExpMatch match in _extractPerfNumbers.allMatches(line)) {
      String stringValue = match[1]!.trim();
      String caption = match[2]!.trim();
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
    String trimmed = line.trim();
    const String searchedTimeDashVCaption =
        "Maximum resident set size (kbytes): ";
    if (trimmed.startsWith(searchedTimeDashVCaption)) {
      String maxRssString = trimmed
          .substring(searchedTimeDashVCaption.length)
          .trim();
      result["maxRssKbytes"] = int.parse(maxRssString);
      result["maxRssBytes"] = int.parse(maxRssString) * 1024;
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

void checkEnvironment() {
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

  new(this.combinedTime, this.countWhat);
}

/// Collects every individual measurement so that it can be written to a JSON
/// file for offline analysis (e.g. plotting a metric against time to look for
/// drift).
class RawOutput {
  final List<String> commandLineArguments;
  final List<String> snapshots;
  final List<List<String>> snapshotSpecificArguments;
  final List<String> arguments;
  final int core;
  final bool interleave;
  final int? seed;
  final DateTime startTime = new DateTime.now();
  final List<Map<String, Object?>> _runs = [];

  new({
    required this.commandLineArguments,
    required this.snapshots,
    required this.snapshotSpecificArguments,
    required this.arguments,
    required this.core,
    required this.interleave,
    required this.seed,
  });

  /// Records a single run.
  ///
  /// [phase] identifies which set of runs this belongs to (e.g. "default",
  /// "cache" or "no-gc"), [kind] says what sort of run it was ("measure",
  /// "warmup" or "gc"), and [values] holds the counter values reported for
  /// the run. When runs are interleaved, [positionInRound] is the position
  /// of this run within its round.
  void addRun({
    required String phase,
    required String kind,
    required int snapshotIndex,
    required int iteration,
    int? positionInRound,
    required DateTime startTime,
    required DateTime endTime,
    required Map<String, num> values,
  }) {
    _runs.add({
      "sequence": _runs.length,
      "phase": phase,
      "kind": kind,
      "snapshotIndex": snapshotIndex,
      "snapshot": snapshots[snapshotIndex],
      "iteration": iteration,
      "positionInRound": positionInRound,
      "startTime": startTime.toIso8601String(),
      "endTime": endTime.toIso8601String(),
      "values": values,
    });
  }

  void writeTo(String path) {
    Map<String, Object?> json = {
      "commandLineArguments": commandLineArguments,
      "snapshots": snapshots,
      "snapshotSpecificArguments": snapshotSpecificArguments,
      "arguments": arguments,
      "core": core,
      "interleave": interleave,
      "seed": seed,
      "startTime": startTime.toIso8601String(),
      "endTime": new DateTime.now().toIso8601String(),
      "runs": _runs,
    };
    new File(path)
        .writeAsStringSync(new JsonEncoder.withIndent("  ").convert(json));
  }
}

class Warnings {
  bool scalingInEffect = false;
}
