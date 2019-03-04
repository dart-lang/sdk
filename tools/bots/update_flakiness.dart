#!/usr/bin/env dart
// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Update the flakiness data with a set of fresh results.

import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';

import 'results.dart';

main(List<String> args) async {
  final parser = new ArgParser();
  parser.addFlag('help', help: 'Show the program usage.', negatable: false);
  parser.addOption('input', abbr: 'i', help: "Input flakiness file.");
  parser.addOption('output', abbr: 'o', help: "Output flakiness file.");
  parser.addOption('build-id', help: "Logdog ID of this buildbot run");
  parser.addOption('commit', help: "Commit hash of this buildbot run");

  final options = parser.parse(args);
  if (options["help"]) {
    print("""
Usage: update_flakiness.dart [OPTION]... [RESULT-FILE]...
Update the flakiness data with a set of fresh results.

The options are as follows:

${parser.usage}""");
    return;
  }
  final parameters = options.rest;

  // Load the existing flakiness data, if any.
  final data = options["input"] != null
      ? await loadResultsMap(options["input"])
      : <String, Map<String, dynamic>>{};

  // Incrementally update the flakiness data with each observed result.
  for (final path in parameters) {
    final results = await loadResults(path);
    for (final resultObject in results) {
      final String configuration = resultObject["configuration"];
      final String name = resultObject["name"];
      final String result = resultObject["result"];
      final key = "$configuration:$name";
      newMap() => <String, dynamic>{};
      final Map<String, dynamic> testData = data.putIfAbsent(key, newMap);
      testData["configuration"] = configuration;
      testData["name"] = name;
      testData["expected"] = resultObject["expected"];
      final outcomes = testData.putIfAbsent("outcomes", () => []);
      final time = DateTime.now().toIso8601String();
      if (!outcomes.contains(result)) {
        outcomes
          ..add(result)
          ..sort();
        testData["last_new_result_seen"] = time;
      }
      if (testData["current"] == result) {
        testData["current_counter"]++;
      } else {
        testData["current"] = result;
        testData["current_counter"] = 1;
      }
      final occurrences = testData.putIfAbsent("occurrences", newMap);
      occurrences.putIfAbsent(result, () => 0);
      occurrences[result]++;
      final firstSeen = testData.putIfAbsent("first_seen", newMap);
      firstSeen.putIfAbsent(result, () => time);
      final lastSeen = testData.putIfAbsent("last_seen", newMap);
      lastSeen[result] = time;
      final matches = testData.putIfAbsent("matches", newMap);
      // TODO: Temporarily fill in the matches field for all other outcomes.
      // Remove this when all the builders have run at least once.
      for (final outcome in occurrences.keys) {
        matches[outcome] = resultObject["expected"] == "Fail"
            ? ["Fail", "CompileTimeError", "RuntimeError"].contains(outcome)
            : resultObject["expected"] == outcome;
      }
      matches[result] = resultObject["matches"];

      if (options["build-id"] != null) {
        final buildIds = testData.putIfAbsent("build_ids", newMap);
        buildIds[result] = options["build-id"];
      }
      if (options["commit"] != null) {
        final commits = testData.putIfAbsent("commits", newMap);
        commits[result] = options["commit"];
      }
    }
  }

  // Write out the new flakiness data, containing all the tests known to have
  // multiple outcomes.
  final sink = options["output"] != null
      ? new File(options["output"]).openWrite()
      : stdout;
  final keys = new List<String>.from(data.keys)..sort();
  for (final key in keys) {
    final testData = data[key];
    if (testData["outcomes"].length < 2) continue;
    // TODO: Temporarily discard entries for old tests that don't run. Remove
    // this when all the builders have run at least once.
    if (!testData.containsKey("matches")) {
      continue;
    }
    // Forgive tests that have become deterministic again. If they flake less
    // than once in a 100 (p<1%), then if they flake again, the probability of
    // them getting past 5 runs of deflaking is 1%^5 = 0.00000001%.
    if (100 <= testData["current_counter"]) {
      continue;
    }
    sink.writeln(jsonEncode(testData));
  }
}
