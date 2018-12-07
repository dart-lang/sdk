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
    for (final result in results) {
      final String configuration = result["configuration"];
      final String name = result["name"];
      final key = "$configuration:$name";
      final Map<String, dynamic> testData =
          data.putIfAbsent(key, () => <String, dynamic>{});
      testData["configuration"] = configuration;
      testData["name"] = name;
      final outcomes = testData.putIfAbsent("outcomes", () => []);
      if (!outcomes.contains(result["result"])) {
        outcomes.add(result["result"]);
        outcomes..sort();
      }
      if (testData["current"] == result["result"]) {
        testData["current_counter"]++;
      } else {
        testData["current"] = result["result"];
        testData["current_counter"] = 1;
      }
      final occurences =
          testData.putIfAbsent("occurences", () => <String, dynamic>{});
      occurences.putIfAbsent(result["result"], () => 0);
      occurences[result["result"]]++;
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
    // Forgive tests that have become deterministic again. If they flake less
    // than once in a 100 (p<1%), then if they flake again, the probability of
    // them getting past 5 runs of deflaking is 1%^5 = 0.00000001%.
    // TODO(sortie): Transitional compatibility until all flaky.json files have
    // this new field.
    if (testData["current_counter"] != null &&
        100 <= testData["current_counter"]) {
      continue;
    }
    sink.writeln(jsonEncode(testData));
  }
}
