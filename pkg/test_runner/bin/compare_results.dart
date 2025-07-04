#!/usr/bin/env dart
// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Compare the old and new test results and list tests that pass the filters.
// The output contains additional details in the verbose mode. There is a human
// readable mode that explains the results and how they changed.

import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:test_runner/bot_results.dart';
import 'package:test_runner/src/deflake_info.dart';

class Event {
  final Result? before;
  final Result after;

  Event(this.before, this.after);

  bool get isNew => before == null;
  bool get isNewPassing => before == null && after.matches;
  bool get isNewFailing => before == null && !after.matches;
  bool get changed => !unchanged;
  bool get unchanged =>
      before != null &&
      before!.outcome == after.outcome &&
      before!.expectation == after.expectation;
  bool get remainedPassing => before!.matches && after.matches;
  bool get remainedFailing => !before!.matches && !after.matches;
  bool get flaked => after.flaked;
  bool get fixed => !before!.matches && after.matches;
  bool get broke => before!.matches && !after.matches;

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
      throw Exception("Unreachable");
    }
  }

  String deflakeInfo(String name) {
    final isTimeout = after.outcome == 'Timeout';
    final lastTimeMs = before?.timeMs;
    return jsonEncode(DeflakeInfo(
      name: name,
      repeat: isTimeout ? 2 : 5,
      timeout: isTimeout && lastTimeMs != null
          ? ((2 * lastTimeMs) / 1000).ceil()
          : -1,
    ).toJson());
  }
}

class Options {
  Options(this._options);

  final ArgResults _options;

  bool get changed => _options["changed"] as bool;
  int? get count => _options["count"] is String
      ? int.parse(_options["count"] as String)
      : null;
  String? get flakinessData => _options["flakiness-data"] as String?;
  bool get help => _options["help"] as bool;
  bool get human => _options["human"] as bool;
  bool get judgement => _options["judgement"] as bool;
  String? get logs => _options["logs"] as String?;
  bool get logsOnly => _options["logs-only"] as bool;
  Iterable<String> get statusFilter => ["passing", "flaky", "failing"]
      .where((option) => _options[option] as bool);
  bool get unchanged => _options["unchanged"] as bool;
  bool get nameOnly => _options["name-only"] as bool;
  bool get verbose => _options["verbose"] as bool;
  List<String> get rest => _options.rest;
}

bool firstSection = true;

bool search(
    String description,
    String searchForStatus,
    Iterable<Event> events,
    Options options,
    Map<String, Map<String, dynamic>> logs,
    List<String>? logSection) {
  var judgement = false;
  var beganSection = false;
  var count = options.count;
  final configurations = <String>{};
  for (final event in events) {
    configurations.add(event.after.configuration);
    if (searchForStatus == "passing" &&
        (event.after.flaked || !event.after.matches)) {
      continue;
    }
    if (searchForStatus == "flaky" && !event.after.flaked) {
      continue;
    }
    if (searchForStatus == "failing" &&
        (event.after.flaked || event.after.matches)) {
      continue;
    }
    if (options.unchanged && !event.unchanged) continue;
    if (options.changed && !event.changed) continue;
    if (!beganSection) {
      if (options.human && !options.logsOnly) {
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
    // The --flaky option is used to get a list of tests to deflake within a
    // single named configuration. Therefore we can't right now always emit
    // the configuration name, so only do it if there's more than one in the
    // results being compared (that won't happen during deflaking.
    final name =
        configurations.length == 1 ? event.after.name : event.after.key;
    if (!after.flaked && !after.matches) {
      judgement = true;
    }
    if (count != null) {
      if (--count <= 0) {
        if (options.human) {
          print("(And more)");
        }
        break;
      }
    }
    String output;
    if (options.verbose) {
      if (options.human) {
        final expect = after.matches ? "" : ", expected ${after.expectation}";
        if (before == null || before.outcome == after.outcome) {
          output = "$name ${event.description} "
              "(${event.after.outcome}$expect)";
        } else {
          output = "$name ${event.description} "
              "(${event.before?.outcome} -> ${event.after.outcome}$expect)";
        }
      } else {
        output = "$name ${before?.outcome} ${after.outcome} "
            "${before?.expectation} ${after.expectation} "
            "${before?.matches} ${after.matches} "
            "${before?.flaked} ${after.flaked}";
      }
    } else if (options.nameOnly) {
      output = name;
    } else {
      output = event.deflakeInfo(name);
    }
    final log = logs[event.after.key];
    final bar = '=' * (output.length + 2);
    if (log != null) {
      logSection?.add("\n\n/$bar\\\n| $output |\n\\$bar/\n\n${log["log"]}");
    }
    if (!options.logsOnly) {
      print(output);
    }
  }

  return judgement;
}

void main(List<String> args) async {
  final parser = ArgParser();
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
  parser.addFlag("human", abbr: "h", negatable: false);
  parser.addFlag("passing",
      abbr: 'p', negatable: false, help: "Show passing tests.");
  parser.addFlag("unchanged",
      abbr: 'u',
      negatable: false,
      help: "Show only tests with unchanged results.");
  parser.addFlag("name-only",
      help: "Only show the test names.", negatable: false);
  parser.addFlag("verbose",
      abbr: "v",
      help: "Show the old and new result for each test",
      negatable: false);
  parser.addOption("logs",
      abbr: "l", help: "Path to file holding logs of failing and flaky tests.");
  parser.addFlag("logs-only",
      help: "Only print logs of failing and flaky tests, no other output",
      negatable: false);

  final options = Options(parser.parse(args));
  if (options.help) {
    print("""
Usage: compare_results.dart [OPTION]... BEFORE AFTER
Compare the old and new test results and list tests that pass the filters.
All tests are listed if no filters are given.

The options are as follows:

${parser.usage}""");
    return;
  }

  if (options.changed && options.unchanged) {
    print(
        "error: The options --changed and --unchanged are mutually exclusive");
    exitCode = 2;
    return;
  }

  final parameters = options.rest;
  if (parameters.length != 2) {
    print("error: Expected two parameters "
        "(results before, results after)");
    exitCode = 2;
    return;
  }

  // Load the input and the flakiness data if specified.
  final before = await loadResultsMap(parameters[0]);
  final after = await loadResultsMap(parameters[1]);
  final logs = options.logs == null
      ? <String, Map<String, dynamic>>{}
      : await loadResultsMap(options.logs!);
  final flakinessData = options.flakinessData == null
      ? <String, Map<String, dynamic>>{}
      : await loadResultsMap(options.flakinessData!);

  // The names of every test that has a data point in the new data set.
  final names = SplayTreeSet<String>.from(after.keys);

  final events = <Event>[];
  for (final name in names) {
    final mapBefore = before[name];
    final mapAfter = after[name]!;
    final resultBefore = mapBefore != null
        ? Result.fromMap(mapBefore, flakinessData[name])
        : null;
    final resultAfter = Result.fromMap(mapAfter, flakinessData[name]);
    final event = Event(resultBefore, resultAfter);
    events.add(event);
  }

  final filterDescriptions = {
    "passing": {
      "unchanged": "continued to pass",
      "changed": "began passing",
      null: "passed",
    },
    "flaky": {
      "unchanged": "are known to flake but didn't",
      "changed": "flaked",
      null: "are known to flake",
    },
    "failing": {
      "unchanged": "continued to fail",
      "changed": "began failing",
      null: "failed",
    },
    "any": {
      "unchanged": "had the same result",
      "changed": "changed result",
      null: "ran",
    },
  };

  final searchForStatuses = options.statusFilter;

  // Report tests matching the filters.
  final logSection = <String>[];
  var judgement = false;
  for (final searchForStatus
      in searchForStatuses.isNotEmpty ? searchForStatuses : <String>["any"]) {
    final searchForChanged = options.unchanged
        ? "unchanged"
        : options.changed
            ? "changed"
            : null;
    final aboutStatus = filterDescriptions[searchForStatus]![searchForChanged];
    final sectionHeader = "The following tests $aboutStatus:";
    final logSectionArg =
        searchForStatus == "failing" || searchForStatus == "flaky"
            ? logSection
            : null;
    final possibleJudgement = search(
        sectionHeader, searchForStatus, events, options, logs, logSectionArg);
    if (searchForStatus == "failing") {
      judgement = possibleJudgement;
    }
  }

  if (logSection.isNotEmpty) {
    print(logSection.join());
  }
  // Exit 1 only if --judgement and any test failed.
  if (options.judgement) {
    if (options.human && !options.logsOnly && !firstSection) {
      print("");
    }
    var oldNew = options.unchanged
        ? "old "
        : options.changed
            ? "new "
            : "";
    if (judgement) {
      if (options.human && !options.logsOnly) {
        print("There were ${oldNew}test failures.");
      }
      exitCode = 1;
    } else {
      if (options.human && !options.logsOnly) {
        print("No ${oldNew}test failures were found.");
      }
    }
  }
}
