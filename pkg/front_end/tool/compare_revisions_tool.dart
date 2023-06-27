// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:io";

import "benchmarker.dart" as benchmarker;

const String compileDartRelativePath = "pkg/front_end/tool/_fasta/compile.dart";

const int iterations = 3;

String? target;
String? changingWorkingDir;
String? sdkPath;
String? snapshotsPath;

void main(List<String> args) {
  if (args.contains("--help")) return _help();
  bool filter = false;
  bool raw = false;
  List<String> examines = [];
  List<String> extraVmArguments = [];
  for (String arg in args) {
    if (arg.startsWith("--target=")) {
      target = arg.substring("--target=".length);
    } else if (arg.startsWith("--changingWorkingDir=")) {
      changingWorkingDir = arg.substring("--changingWorkingDir=".length);
    } else if (arg.startsWith("--sdkPath=")) {
      sdkPath = arg.substring("--sdkPath=".length);
    } else if (arg.startsWith("--snapshotsPath=")) {
      snapshotsPath = arg.substring("--snapshotsPath=".length);
    } else if (arg == "--filter") {
      filter = true;
    } else if (arg == "--raw") {
      raw = true;
    } else if (arg.startsWith("--examine=")) {
      examines.addAll(arg.substring("--examine=".length).split(","));
    } else if (arg.startsWith("--extraVmArguments=")) {
      // E.g. "--old_gen_growth_rate=1000" in an attempt to even out GC stuff.
      extraVmArguments.add(arg.substring("--extraVmArguments=".length));
    } else {
      throw "Unknown argument: $arg";
    }
  }

  if (target == null) throw "Specify --target";
  if (changingWorkingDir == null) throw "Specify --changingWorkingDir";
  if (snapshotsPath == null) throw "Specify --snapshotsPath";
  if (sdkPath == null) throw "Specify --sdkPath";
  if (!new File("${sdkPath}bin/dart").existsSync()) {
    throw "--sdkPath doesn't contain bin/dart";
  }
  if (!new File("${sdkPath}bin/dartaotruntime").existsSync()) {
    throw "--sdkPath doesn't contain bin/dartaotruntime";
  }
  if (examines.isEmpty) {
    throw "Specify one or more commits to examine via --examine=";
  }

  for (String examine in examines) {
    if (examine.trim() == "") continue;
    _examine(examine, filter, raw, extraVmArguments);
  }
}

void _help() {
  print("CFE revision benchmarking tool");
  print("");
  print("Specify target, i.e. what we'll compile when benchmarking via");
  print("--target=<dart file>");
  print("Specify a git checkout that this script can manage");
  print("(and delete untracked files etc in) via");
  print("--changingWorkingDir=<checkout dir>");
  print("Specify the sdk to use via");
  print("--sdkPath=<path>");
  print("Specify where to save the snapshots via");
  print("--snapshotsPath=<path>");
  print("Specify which commit(s) to examine with");
  print("--examine=<revision>");
  print("(specify more either with more --examine= arguments,");
  print("or by comma-separation)");
  print("");
  print("Control output as needed with");
  print("--filter");
  print("and");
  print("--raw");
  print("");
  print("Specify extra arguments to pass to the VM with");
  print("--extraVmArguments=<whatever>");
  print("E.g. `--extraVmArguments=--old_gen_growth_rate=1000`");
  print("");
  print("Example run:");
  print("");
  print(r"out/ReleaseX64/dart-sdk/bin/dart \");
  print(r"  pkg/front_end/tool/compare_revisions_tool.dart \");
  print(r"  --target=pkg/front_end/tool/_fasta/compile.dart \");
  print(r"  --changingWorkingDir=/tmp/tmp-playing-with-git/sdk/ \");
  print(r"  --sdkPath=67e9580b042/dart-sdk/ \");
  print(r"  --snapshotsPath=67e9580b042 \");
  print(r"  --examine=e7deece1fb2,529e016a0a7,fd02fec0fc4 \");
}

void _compileRevision(String gitCommit, {Stopwatch? stopwatch}) {
  if (new File("$snapshotsPath/platform.dill.$gitCommit").existsSync() &&
      new File("$snapshotsPath/compile.aot.$gitCommit").existsSync()) {
    return;
  }
  stopwatch ??= new Stopwatch()..start();

  // Clean up the git checkout.
  ProcessResult processResult = Process.runSync("git", ["reset", "--hard"],
      workingDirectory: changingWorkingDir);
  if (processResult.exitCode != 0) {
    throw "Failed resetting hard for $gitCommit:\n"
        "stderr: ${processResult.stderr}\n"
        "stdout: ${processResult.stdout}";
  }
  processResult = Process.runSync("git", ["clean", "-d", "-f"],
      workingDirectory: changingWorkingDir);
  if (processResult.exitCode != 0) {
    throw "Failed cleaning for $gitCommit:\n"
        "stderr: ${processResult.stderr}\n"
        "stdout: ${processResult.stdout}";
  }

  // Checkout at the specific revision.
  processResult = Process.runSync("git", ["checkout", gitCommit],
      workingDirectory: changingWorkingDir);
  if (processResult.exitCode != 0) {
    throw "Failed checking out $gitCommit:\n"
        "stderr: ${processResult.stderr}\n"
        "stdout: ${processResult.stdout}";
  }
  print("Done running git checkout for $gitCommit after "
      "${stopwatch.elapsed.inSeconds} seconds.");

  // Clean up the git checkout.
  processResult = Process.runSync("git", ["reset", "--hard"],
      workingDirectory: changingWorkingDir);
  if (processResult.exitCode != 0) {
    throw "Failed resetting hard for $gitCommit:\n"
        "stderr: ${processResult.stderr}\n"
        "stdout: ${processResult.stdout}";
  }
  processResult = Process.runSync("git", ["clean", "-d", "-f"],
      workingDirectory: changingWorkingDir);
  if (processResult.exitCode != 0) {
    throw "Failed cleaning for $gitCommit:\n"
        "stderr: ${processResult.stderr}\n"
        "stdout: ${processResult.stdout}";
  }

  // Run `gclient sync`.
  processResult = Process.runSync("gclient", ["sync", "-D"],
      workingDirectory: changingWorkingDir);
  if (processResult.exitCode != 0) {
    throw "Failed gclient sync at $gitCommit:\n"
        "stderr: ${processResult.stderr}\n"
        "stdout: ${processResult.stdout}";
  }
  print("Done running `gclient sync` for $gitCommit "
      "after ${stopwatch.elapsed.inSeconds} seconds.");

  // Build the platform and copy it so we have it.
  processResult = Process.runSync(
      "python3", ["tools/build.py", "-ax64", "-mrelease", "vm_platform"],
      workingDirectory: changingWorkingDir);
  if (processResult.exitCode != 0) {
    throw "Failed compile vm platform at $gitCommit:\n"
        "stderr: ${processResult.stderr}\n"
        "stdout: ${processResult.stdout}";
  }
  new File("$changingWorkingDir/out/ReleaseX64/vm_platform_strong.dill")
      .copySync("$snapshotsPath/platform.dill.$gitCommit");
  print("Done building the platform for $gitCommit "
      "after ${stopwatch.elapsed.inSeconds} seconds.");

  // Compile the AOT snapshot.
  processResult = Process.runSync("${sdkPath}bin/dart", [
    "compile",
    "aot-snapshot",
    "$changingWorkingDir/$compileDartRelativePath",
    "-o",
    "$snapshotsPath/compile.aot.$gitCommit"
  ]);
  if (processResult.exitCode != 0) {
    throw "Failed compile aot-snapshot at $gitCommit:\n"
        "stderr: ${processResult.stderr}\n"
        "stdout: ${processResult.stdout}";
  }
  print("Compiled for $gitCommit "
      "after ${stopwatch.elapsed.inSeconds} seconds.");
}

void _examine(
    String revision, bool filter, bool raw, List<String> extraVmArguments) {
  ProcessResult processResult = Process.runSync(
      "git", ["log", "$revision^^...$revision", "--pretty=format:%h"],
      workingDirectory: changingWorkingDir);
  if (processResult.exitCode != 0) {
    throw "Failed to get log:\n"
        "stderr: ${processResult.stderr}\n"
        "stdout: ${processResult.stdout}";
  }

  List<String> revisions = processResult.stdout.split("\n").reversed.toList();
  if (revisions.length != 2) throw "Expected 2 revisions but got $revisions";
  if (revisions.last != revision) {
    throw "Expected $revision but got ${revisions.last}";
  }
  String prevRevision = revisions.first;

  print("Creating AOT-snapshots if needed.");
  _compileRevision(prevRevision);
  _compileRevision(revision);

  print("Will now examine $prevRevision -> $revision.");

  print("Running with verbose GC.");
  GCInfo gcPrev = _runVerboseGc(prevRevision, extraVmArguments);
  GCInfo gcCurrent = _runVerboseGc(revision, extraVmArguments);
  _printGcDiff(gcPrev, gcCurrent);

  print("Running $iterations iterations for $prevRevision.");
  List<Map<String, num>> benchmarkDataFrom = [];
  _run(iterations, prevRevision, extraVmArguments, benchmarkDataFrom);

  print("Running $iterations iterations for $revision.");
  List<Map<String, num>> benchmarkDataTo = [];
  _run(iterations, revision, extraVmArguments, benchmarkDataTo);

  if (filter) {
    // Filter to only "instructions:u".
    benchmarkDataFrom = _filterToInstructions(benchmarkDataFrom);
    benchmarkDataTo = _filterToInstructions(benchmarkDataTo);
  }
  if (raw) {
    print("From: $benchmarkDataFrom");
    print("To: $benchmarkDataTo");
  }

  print("Examine: $prevRevision -> $revision:");
  if (!benchmarker.compare(benchmarkDataFrom, benchmarkDataTo)) {
    print("No change.");
  }
}

void _printGcDiff(GCInfo prev, GCInfo current) {
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
    print("Notice combined GC time goes "
        "from ${prev.combinedTime.toStringAsFixed(0)} ms "
        "to ${current.combinedTime.toStringAsFixed(0)} ms "
        "(notice only 1 run each).");
  }
}

void _run(int iterations, String gitCommit, List<String> extraVmArguments,
    List<Map<String, num>> output) {
  for (int i = 0; i < iterations; i++) {
    try {
      output.add(benchmarker.benchmark(
          "$snapshotsPath/compile.aot.$gitCommit",
          extraVmArguments,
          [
            "--platform=$snapshotsPath/platform.dill.$gitCommit",
            target!,
          ],
          aotRuntime: "${sdkPath}bin/dartaotruntime"));
    } catch (e) {
      throw "Failed to run benchmark at $gitCommit";
    }
  }
}

GCInfo _runVerboseGc(String gitCommit, List<String> extraVmArguments) {
  ProcessResult processResult =
      Process.runSync("${sdkPath}bin/dartaotruntime", [
    "--deterministic",
    "--verbose-gc",
    ...extraVmArguments,
    "$snapshotsPath/compile.aot.$gitCommit",
    "--platform=$snapshotsPath/platform.dill.$gitCommit",
    target!
  ]);

  if (processResult.exitCode != 0) {
    throw "Run failed for $gitCommit with exit code "
        "${processResult.exitCode}.\n"
        "stdout:\n${processResult.stdout}\n\n"
        "stderr:\n${processResult.stderr}\n\n";
  }

  List<String> stderrLines = processResult.stderr.split("\n");
  double combinedTime = 0;
  Map<String, int> countWhat = {};
  for (String line in stderrLines) {
    if (!line.trim().startsWith("[")) continue;
    if (line.indexOf(",") < 0) continue;
    // Hardcoding this might not be the best solution, but works for now.
    List<String> cells = line.split(",");
    String spaceReason = cells[1].trim();
    double time = double.parse(cells[4].trim());
    combinedTime += time;
    countWhat[spaceReason] = (countWhat[spaceReason] ?? 0) + 1;
  }
  return new GCInfo(combinedTime, countWhat);
}

class GCInfo {
  final double combinedTime;
  final Map<String, int> countWhat;

  GCInfo(this.combinedTime, this.countWhat);
}

List<Map<String, num>> _filterToInstructions(List<Map<String, num>> input,
    {List<num>? extractedNumbers}) {
  List<Map<String, num>> result = [];
  for (Map<String, num> map in input) {
    num? instructionsValue = map["instructions:u"];
    if (instructionsValue != null) {
      result.add({"instructions:u": instructionsValue});
      extractedNumbers?.add(instructionsValue);
    }
  }
  return result;
}
