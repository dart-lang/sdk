// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.test.suite_utils;

import 'dart:io';

import 'package:testing/src/chain.dart' show CreateContext;
import 'package:testing/src/log.dart' show Logger, StdoutLogger;
import 'package:testing/src/suite.dart' as testing show Suite;
import 'package:testing/testing.dart' show Step, TestDescription;

import '../coverage_helper.dart';
import 'testing/suite.dart';

Future<void> internalMain(
  CreateContext createContext, {
  List<String> arguments = const [],
  int? shards,
  int? shard,
  required String displayName,
  String? configurationPath,
}) async {
  Logger logger = const StdoutLogger();
  List<String>? argumentsTrimmed;
  Uri? coverageUri;
  for (int i = 0; i < arguments.length; i++) {
    String argument = arguments[i];
    bool trimmed = false;
    if (argument == "--traceStepTiming") {
      logger = new TracingLogger();
      trimmed = true;
    } else if (argument.startsWith("--coverage=")) {
      coverageUri = Uri.base
          .resolveUri(Uri.file(argument.substring("--coverage=".length)));
      trimmed = true;
    } else if (argument.startsWith("--shards=")) {
      shards = int.parse(argument.substring("--shards=".length));
      trimmed = true;
    } else if (argument.startsWith("--shard=")) {
      // Have this 1-indexed when given as an input.
      shard = int.parse(argument.substring("--shard=".length)) - 1;
      trimmed = true;
    }

    if (trimmed && argumentsTrimmed == null) {
      argumentsTrimmed = []..addAll(arguments.sublist(0, i));
    } else if (!trimmed && argumentsTrimmed != null) {
      argumentsTrimmed.add(argument);
    }
  }
  if (argumentsTrimmed != null) {
    arguments = argumentsTrimmed;
  }

  shards ??= 1;
  shard ??= 0;

  await runMe(
    arguments,
    createContext,
    configurationPath: configurationPath ?? "../../testing.json",
    shards: shards,
    shard: shard,
    logger: logger,
  );
  if (coverageUri != null) {
    File f = new File.fromUri(
        coverageUri.resolve("$displayName.$shard.$shards.coverage"));
    // Suites generally takes a while to run --- so setting force compile to
    // true shouldn't be a big issue. It seems to add something like a second
    // to the collection time.
    (await collectCoverage(displayName: displayName, forceCompile: true))
        ?.writeToFile(f);
  }
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
