// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.test.suite_utils;

import 'package:testing/testing.dart' show Step, TestDescription;
import 'package:testing/src/chain.dart' show CreateContext;
import 'package:testing/src/log.dart' show Logger, StdoutLogger;
import 'package:testing/src/suite.dart' as testing show Suite;

import 'testing/suite.dart';

Future<void> internalMain(CreateContext createContext,
    {List<String> arguments = const [], int shards = 1, int shard = 0}) async {
  Logger logger = const StdoutLogger();
  if (arguments.contains("--traceStepTiming")) {
    logger = new TracingLogger();
    arguments = arguments.toList()..remove("--traceStepTiming");
  }
  await runMe(
    arguments,
    createContext,
    configurationPath: "../../testing.json",
    shards: shards,
    shard: shard,
    logger: logger,
  );
}

class TracingLogger extends StdoutLogger {
  Map<TestDescription, Map<Step, Stopwatch>> stopwatches = {};

  @override
  void logStepStart(int completed, int failed, int total, testing.Suite? suite,
      TestDescription description, Step step) {
    Map<Step, Stopwatch> map = stopwatches[description] ??= {};
    Stopwatch stopwatch = map[step] ??= new Stopwatch();
    if (stopwatch.isRunning) throw "unexpectedly already running @ $step";
    stopwatch.start();
    super.logStepStart(completed, failed, total, suite, description, step);
  }

  @override
  void logStepComplete(int completed, int failed, int total,
      testing.Suite? suite, TestDescription description, Step step) {
    Map<Step, Stopwatch> map = stopwatches[description]!;
    Stopwatch stopwatch = map[step] = map[step]!;
    if (!stopwatch.isRunning) throw "unexpectedly not running";
    stopwatch.stop();
    super.logStepComplete(completed, failed, total, suite, description, step);
  }

  @override
  void logSuiteComplete(testing.Suite suite) {
    Map<String, Duration> totalRuntimesForSteps = {};
    // Make sure not to overwrite existing text about number of tests run,
    // failures etc.
    print("");
    print("");

    for (MapEntry<TestDescription, Map<Step, Stopwatch>> entryMap
        in stopwatches.entries) {
      for (MapEntry<Step, Stopwatch> entry in entryMap.value.entries) {
        if (entry.value.isRunning) throw "unexpectedly already running";
        entry.value.elapsed + entry.value.elapsed;
        totalRuntimesForSteps[entry.key.name] =
            (totalRuntimesForSteps[entry.key.name] ?? new Duration()) +
                entry.value.elapsed;
      }
    }
    List<MapEntry<String, Duration>> entries =
        totalRuntimesForSteps.entries.toList();
    entries.sort((a, b) => a.value.compareTo(b.value));
    for (MapEntry<String, Duration> entry in entries) {
      const int maxLength = 25;
      String key = (entry.key.length > maxLength)
          ? entry.key.substring(0, maxLength)
          : entry.key.padLeft(maxLength);
      print("$key: ${entry.value} ms");
    }
    super.logSuiteComplete(suite);
  }
}
