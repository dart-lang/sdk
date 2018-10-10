#!/usr/bin/env dart
// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Compare the old and new test results and list tests that pass the filters.
// The output contains additional details in the verbose mode. There is a human
// readable mode that explains the results and how they changed.

import 'dart:collection';
import 'dart:io';

import 'package:args/args.dart';

import 'results.dart';

class Result {
  final String name;
  final String outcome;
  final String expectation;
  final bool matches;
  final bool flaked;

  Result(this.name, this.outcome, this.expectation, this.matches, this.flaked);

  Result.fromMap(Map<String, dynamic> map, Map<String, dynamic> flakinessData)
      : name = map["name"],
        outcome = map["result"],
        expectation = map["expected"],
        matches = map["matches"],
        flaked = flakinessData != null &&
            flakinessData["outcomes"].contains(map["result"]);
}

class Event {
  final Result before;
  final Result after;

  Event(this.before, this.after);

  bool get isNew => before == null;
  bool get isNewPassing => before == null && after.matches;
  bool get isNewFailing => before == null && !after.matches;
  bool get changed => !unchanged;
  bool get unchanged => before != null && before.outcome == after.outcome;
  bool get remainedPassing => before.matches && after.matches;
  bool get remainedFailing => !before.matches && !after.matches;
  bool get flaked => after.flaked;
  bool get fixed => !before.matches && after.matches;
  bool get broke => before.matches && !after.matches;

  String get description {
    if (isNewPassing) {
      return "is new and succeeded";
    } else if (isNewFailing) {
      return "is new and failed";
    } else if (remainedPassing) {
      return "succeeded again";
    } else if (remainedFailing) {
      return "failed again";
    } else if (fixed) {
      return "was fixed";
    } else if (broke) {
      return "broke";
    } else {
      throw new Exception("Unreachable");
    }
  }
}

bool firstSection = true;

bool search(String description, String searchFor, List<Event> events,
    ArgResults options) {
  bool judgement = false;
  bool beganSection = false;
  int count = options["count"] != null ? int.parse(options["count"]) : null;

  for (final event in events) {
    if (searchFor == "passing" &&
        (event.after.flaked || !event.after.matches)) {
      continue;
    }
    if (searchFor == "flaky" && !event.after.flaked) {
      continue;
    }
    if (searchFor == "failing" && (event.after.flaked || event.after.matches)) {
      continue;
    }
    if (options["unchanged"] && !event.unchanged) continue;
    if (options["changed"] && !event.changed) continue;
    if (!beganSection) {
      if (options["human"]) {
        if (!firstSection) {
          print("");
        }
        firstSection = false;
        print("$description\n");
      }
    }
    beganSection = true;
    final before = event.before;
    final after = event.after;
    final name = event.after.name;
    if (!after.flaked && !after.matches) {
      judgement = true;
    }
    if (count != null) {
      if (--count <= 0) {
        if (options["human"]) {
          print("(And more)");
        }
        break;
      }
    }
    if (options["human"]) {
      if (options["verbose"]) {
        String expected =
            after.matches ? "" : ", expected ${after.expectation}";
        if (before == null || before.outcome == after.outcome) {
          print("${name} ${event.description} "
              "(${event.after.outcome}${expected})");
        } else {
          print("${name} ${event.description} "
              "(${event.before?.outcome} -> ${event.after.outcome}${expected})");
        }
      } else {
        print(name);
      }
    } else {
      if (options["verbose"]) {
        print("$name "
            "${before?.outcome} ${after.outcome} "
            "${before?.expectation} ${after.expectation} "
            "${before?.matches} ${after.matches} "
            "${before?.flaked} ${after.flaked}");
      } else {
        print(event.after.name);
      }
    }
  }

  return judgement;
}

main(List<String> args) async {
  final parser = new ArgParser();
  parser.addFlag("changed",
      abbr: 'c',
      negatable: false,
      help: "Show only tests that changed results.");
  parser.addOption("count",
      abbr: "C",
      help: "Upper limit on how many tests to report in each section");
  parser.addFlag("failing",
      abbr: 'f', negatable: false, help: "Show failing tests.");
  parser.addOption("flakiness-data",
      abbr: 'd', help: "File containing flakiness data");
  parser.addFlag("judgement",
      abbr: 'j',
      negatable: false,
      help: "Exit 1 only if any of the filtered results failed.");
  parser.addFlag("flaky",
      abbr: 'F', negatable: false, help: "Show flaky tests.");
  parser.addFlag("help", help: "Show the program usage.", negatable: false);
  parser.addFlag("human",
      abbr: "h",
      help: "Prove you can't read machine readable output.",
      negatable: false);
  parser.addFlag("passing",
      abbr: 'p', negatable: false, help: "Show passing tests.");
  parser.addFlag("unchanged",
      abbr: 'u',
      negatable: false,
      help: "Show only tests with unchanged results.");
  parser.addFlag("verbose",
      abbr: "v",
      help: "Show the old and new result for each test",
      negatable: false);

  final options = parser.parse(args);
  if (options["help"]) {
    print("""
Usage: compare_results.dart [OPTION]... [BEFORE] [AFTER]
Compare the old and new test results and list tests that pass the filters.
All tests are listed if no filters are given.

The options are as follows:

${parser.usage}""");
    return;
  }

  if (options["changed"] && options["unchanged"]) {
    print(
        "error: The options --changed and --unchanged are mutually exclusive");
    exitCode = 2;
    return;
  }

  final parameters = options.rest;
  if (parameters.length != 2) {
    print("error: Expected two parameters (results before and results after)");
    exitCode = 2;
    return;
  }

  // Load the input and the flakiness data if specified.
  final before = await loadResultsMap(parameters[0]);
  final after = await loadResultsMap(parameters[1]);
  final flakinessData = options["flakiness-data"] != null
      ? await loadResultsMap(options["flakiness-data"])
      : <String, Map<String, dynamic>>{};

  // The names of every test that has a data point in the new data set.
  final names = new SplayTreeSet<String>.from(after.keys);

  final events = <Event>[];
  for (final name in names) {
    final mapBefore = before[name];
    final mapAfter = after[name];
    final resultBefore = mapBefore != null
        ? new Result.fromMap(mapBefore, flakinessData[name])
        : null;
    final resultAfter = new Result.fromMap(mapAfter, flakinessData[name]);
    final event = new Event(resultBefore, resultAfter);
    events.add(event);
  }

  // Report tests matching the filters.
  bool judgement = false;
  if (options["passing"] || options["flaky"] || options["failing"]) {
    if (options["passing"]) {
      String sectionHeader;
      if (options["unchanged"]) {
        sectionHeader = "The following tests continued to pass:";
      } else if (options["changed"]) {
        sectionHeader = "The following tests began passing:";
      } else {
        sectionHeader = "The following tests passed:";
      }
      search(sectionHeader, "passing", events, options);
    }
    if (options["flaky"]) {
      String sectionHeader;
      if (options["unchanged"]) {
        sectionHeader = "The following tests are known to flake but didn't:";
      } else if (options["changed"]) {
        sectionHeader = "The following tests flaked:";
      } else {
        sectionHeader = "The following tests are known to flake:";
      }
      search(sectionHeader, "flaky", events, options);
    }
    if (options["failing"]) {
      String sectionHeader;
      if (options["unchanged"]) {
        sectionHeader = "The following tests continued to fail:";
      } else if (options["changed"]) {
        sectionHeader = "The following tests began failing:";
      } else {
        sectionHeader = "The following tests failed:";
      }
      judgement = search(sectionHeader, "failing", events, options);
    }
  } else {
    String sectionHeader;
    if (options["unchanged"]) {
      sectionHeader = "The following tests had the same result:";
    } else if (options["changed"]) {
      sectionHeader = "The following tests changed result:";
    } else {
      sectionHeader = "The following tests ran:";
    }
    judgement = search(sectionHeader, null, events, options);
  }

  // Exit 1 only if --judgement and any test failed.
  if (options["judgement"]) {
    if (options["human"] && !firstSection) {
      print("");
    }
    String oldNew =
        options["unchanged"] ? "old " : options["changed"] ? "new " : "";
    if (judgement) {
      if (options["human"]) {
        print("There were ${oldNew}test failures.");
      }
      exitCode = 1;
    } else {
      if (options["human"]) {
        print("No ${oldNew}test failures were found.");
      }
    }
  }
}
