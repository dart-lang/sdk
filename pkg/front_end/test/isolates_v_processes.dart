// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:io";
import "dart:isolate";

import "package:testing/src/suite.dart";
import "package:testing/testing.dart";
import 'package:testing/src/log.dart' show Logger, StdoutLogger;

import "fasta/strong_suite.dart" as strong;

const bool doPrint = false;

enum What {
  Process,
  Isolate,
  Direct,
  Unknown;
}

Future<void> main(List<String> args) async {
  int j = 2;
  int x = 0;
  What what = What.Unknown;

  for (String arg in args) {
    if (arg.startsWith("-j")) {
      j = int.tryParse(arg.substring(2)) ?? (throw "invalid -j ($arg)");
    } else if (arg.startsWith("-x")) {
      x = int.tryParse(arg.substring(2)) ?? (throw "invalid -x ($arg)");
    } else if (arg == "--isolates") {
      what = What.Isolate;
    } else if (arg == "--processes") {
      what = What.Process;
    } else if (arg == "--direct") {
      what = What.Direct;
    }
  }
  Stopwatch stopwatch = new Stopwatch()..start();
  switch (what) {
    case What.Process:
      await useProcesses(j);
    case What.Isolate:
      await useIsolates(j);
    case What.Direct:
      await useDirect(j, x);
    case What.Unknown:
      throw "Specify with --isolates or --processes and optionally -j<num>";
  }
  print("All done after ${stopwatch.elapsed}");
}

Future<void> entry(List<int> args) async {
  await runMe(
    ["-DskipVm=true", "-DsemiFuzz=false"],
    strong.createContext,
    me: Platform.script.resolve("fasta/strong_suite.dart"),
    configurationPath: "../../testing.json",
    shards: args[0],
    shard: args[1],
    logger: doPrint ? const StdoutLogger() : const DevNullLogger(),
  );
}

Future<void> useDirect(int shards, int shard) async {
  List<Future> futures = [];
  futures.add(entry([shards, shard]));
  await Future.wait(futures);
}

Future<void> useIsolates(final int j) async {
  Stopwatch stopwatch = new Stopwatch()..start();
  print("Using $j isolates...");
  List<Future> futures = [];
  for (int i = 0; i <= j; i++) {
    ReceivePort exitPort = new ReceivePort();
    futures.add(exitPort.first.then((_) {
      if (i == j) {
        print("Isolate #$i (checking startup cost) finished after "
            "${stopwatch.elapsed}");
      } else {
        print("Isolate #$i finished after ${stopwatch.elapsed}");
      }
    }));
    await Isolate.spawn(entry, [j, i], onExit: exitPort.sendPort);
  }
  await Future.wait(futures);
}

Future<void> useProcesses(final int j) async {
  Stopwatch stopwatch = new Stopwatch()..start();
  print("Using $j processes...");
  String script = Platform.script.toFilePath();
  List<Future> futures = [];
  for (int i = 0; i <= j; i++) {
    futures.add(Process.run(Platform.resolvedExecutable, [
      script,
      "--direct",
      "-j$j",
      "-x$i",
    ]).then((_) {
      if (i == j) {
        print("Process #$i (checking startup cost) finished after "
            "${stopwatch.elapsed}");
      } else {
        print("Process #$i finished after ${stopwatch.elapsed}");
      }
    }));
  }
  await Future.wait(futures);
}

class DevNullLogger implements Logger {
  const DevNullLogger();

  @override
  void logExpectedResult(Suite suite, TestDescription description,
      Result result, Set<Expectation> expectedOutcomes) {}

  @override
  void logMessage(Object message) {}

  @override
  void logNumberedLines(String text) {}

  @override
  void logProgress(String message) {}

  @override
  void logStepComplete(int completed, int failed, int total, Suite suite,
      TestDescription description, Step<dynamic, dynamic, ChainContext> step) {}

  @override
  void logStepStart(int completed, int failed, int total, Suite suite,
      TestDescription description, Step<dynamic, dynamic, ChainContext> step) {}

  @override
  void logSuiteComplete(Suite suite) {}

  @override
  void logSuiteStarted(Suite suite) {}

  @override
  void logTestComplete(int completed, int failed, int total, Suite suite,
      TestDescription description) {}

  @override
  void logTestStart(int completed, int failed, int total, Suite suite,
      TestDescription description) {}

  @override
  void logUncaughtError(error, StackTrace stackTrace) {}

  @override
  void logUnexpectedResult(Suite suite, TestDescription description,
      Result result, Set<Expectation> expectedOutcomes) {}

  @override
  void noticeFrameworkCatchError(error, StackTrace stackTrace) {}
}
