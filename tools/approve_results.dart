#!/usr/bin/env dart
// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// List tests whose results are different from the previously approved results,
/// and ask whether to update the currently approved results, turning the bots
/// green.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:args/args.dart';
import 'package:glob/glob.dart';

import 'bots/results.dart';

/// The bot names and named configurations are highly redundant if both are
/// listed. This function returns a simplified named configuration that doesn't
/// contain any aspects that's part of the bots name. This is used to get a more
/// compact and readable output.
String simplifyNamedConfiguration(String bot, String namedConfiguration) {
  final botComponents = new Set<String>.from(bot.split("-"));
  return namedConfiguration
      .split("-")
      .where((component) => !botComponents.contains(component))
      .join("-");
}

/// Represents a test on a bot with the current result, the current approved
/// result, and flakiness data.
class Test implements Comparable {
  final String bot;
  final String name;
  final Map<String, dynamic> resultData;
  final Map<String, dynamic> approvedResultData;
  final Map<String, dynamic> flakinessData;

  Test(this.bot, this.name, this.resultData, this.approvedResultData,
      this.flakinessData);

  int compareTo(Object other) {
    if (other is Test) {
      if (bot.compareTo(other.bot) < 0) return -1;
      if (other.bot.compareTo(bot) < 0) return 1;
      if (configuration.compareTo(other.configuration) < 0) return -1;
      if (other.configuration.compareTo(configuration) < 0) return 1;
      if (name.compareTo(other.name) < 0) return -1;
      if (other.name.compareTo(name) < 0) return 1;
    }
    return 0;
  }

  String get configuration => resultData["configuration"];
  String get result => resultData["result"];
  String get expected => resultData["expected"];
  bool get matches => resultData["matches"];
  String get approvedResult =>
      approvedResultData != null ? approvedResultData["result"] : null;
  bool get isApproved => result == approvedResult;
  List<String> get flakyModes =>
      flakinessData != null ? flakinessData["outcomes"].cast<String>() : null;
  bool get isFlake => flakinessData != null && flakyModes.contains(result);
}

/// Loads the results file as as a map if the file exists, otherwise returns the
/// empty map.
Future<Map<String, Map<String, dynamic>>> loadResultsMapIfExists(
        String path) async =>
    await new File(path).exists()
        ? loadResultsMap(path)
        : <String, Map<String, dynamic>>{};

/// Loads a log from logdog.
Future<String> loadLog(String id, String step) async {
  final logUrl = Uri.parse("https://logs.chromium.org/"
      "logs/dart/buildbucket/cr-buildbucket.appspot.com/"
      "$id/+/steps/$step?format=raw");
  final client = new HttpClient();
  final request =
      await client.getUrl(logUrl).timeout(const Duration(seconds: 60));
  final response = await request.close().timeout(const Duration(seconds: 60));
  if (response.statusCode != HttpStatus.ok) {
    throw new Exception("The log at $logUrl doesn't exist");
  }
  final contents = (await response
          .transform(new Utf8Decoder())
          .timeout(const Duration(seconds: 60))
          .toList())
      .join("");
  client.close();
  return contents;
}

/// Loads the results from the bot.
Future<List<Test>> loadResultsFromBot(String bot, ArgResults options,
    Map<String, dynamic> changelistBuild) async {
  if (options["verbose"]) {
    print("Loading $bot...");
  }
  // gsutil cp -r requires a destination directory, use a temporary one.
  final tmpdir = await Directory.systemTemp.createTemp("approve_results.");
  try {
    // The 'latest' file contains the name of the latest build that we
    // should download. When preapproving a changelist, we instead find out
    // which build the commit queue was rebased on.
    final build = (changelistBuild != null
            ? await loadLog(changelistBuild["id"],
                "gsutil_find_latest_build/0/logs/raw_io.output_text_latest_/0")
            : await readFile(bot, "latest"))
        .trim();

    // Asynchronously download the latest build and the current approved
    // results. Download try results from trybot try runs if preapproving.
    final tryResults = <String, Map<String, dynamic>>{};
    await Future.wait([
      cpRecursiveGsutil(buildCloudPath(bot, build), tmpdir.path),
      cpRecursiveGsutil(
          "$approvedResultsStoragePath/$bot/approved_results.json",
          "${tmpdir.path}/approved_results.json"),
      new Future(() async {
        if (changelistBuild != null) {
          tryResults.addAll(parseResultsMap(await loadLog(
              changelistBuild["id"], "test_results/0/logs/results.json/0")));
        }
      }),
    ]);

    // Check the build was properly downloaded.
    final buildPath = "${tmpdir.path}/$build";
    final buildDirectory = new Directory(buildPath);
    if (!await buildDirectory.exists()) {
      print("$bot: Build directory didn't exist");
      return <Test>[];
    }

    // Load the run.json to find the named configuration.
    final resultsFile = new File("$buildPath/results.json");
    if (!await resultsFile.exists()) {
      print("$bot: No results.json exists");
      return <Test>[];
    }

    // Load the current results, the approved resutls, and the flakiness
    // information.
    final results = await loadResultsMapIfExists("$buildPath/results.json");
    final flaky = await loadResultsMapIfExists("$buildPath/flaky.json");
    final approvedResults =
        await loadResultsMapIfExists("${tmpdir.path}/approved_results.json");

    // Construct an object for every test containing its current result,
    // what the last approved result was, and whether it's flaky.
    final tests = <Test>[];
    for (final key in results.keys) {
      final result = results[key];
      final approvedResult = approvedResults[key];
      final flakiness = flaky[key];
      // If preapproving results, allow new non-matching results that are
      // different from the baseline. The approved results will be the current
      // approved results, plus the difference between the tryrun's baseline and
      // the tryrun's results.
      if (tryResults.containsKey(key)) {
        final tryResult = tryResults[key];
        final wasFlake = flakiness != null &&
            (flakiness["outcomes"] as List<dynamic>)
                .contains(tryResult["result"]);
        // Pick the try run result if the try result was not a flake and it's a
        // non-matching result that's different than the approved result. If
        // there is no approved result yet, use the latest result from the
        // builder instead.
        final baseResult = approvedResult ?? result;
        if (!wasFlake &&
            !tryResult["matches"] &&
            tryResult["result"] != result["result"]) {
          // The approved_results.json format currently does not natively
          // support preapproval, so preapproving turning one failure into
          // another will turn the builder in question red until the CL lands.
          if (!baseResult["matches"] &&
              tryResult["result"] != baseResult["result"]) {
            print("Warning: Preapproving changed failure modes will turn the "
                "CI red until the CL is submitted: $bot: $key: "
                "${baseResult["result"]} -> ${tryResult["result"]}");
          }
          result.clear();
          result.addAll(tryResult);
        } else {
          if (approvedResult != null) {
            result.clear();
            result.addAll(approvedResult);
          }
        }
      } else if (tryResults.isNotEmpty && approvedResult != null) {
        result.clear();
        result.addAll(approvedResult);
      }
      final name = result["name"];
      final test = new Test(bot, name, result, approvedResult, flakiness);
      final dropApproval =
          test.matches ? options["failures-only"] : options["successes-only"];
      if (dropApproval && !test.isApproved) {
        if (approvedResult == null) continue;
        result.clear();
        result.addAll(approvedResult);
      }
      tests.add(test);
    }
    // If preapproving and the CL has introduced new tests, add the new tests
    // as well to the approved data.
    final newTestKeys = new Set<String>.from(tryResults.keys)
        .difference(new Set<String>.from(results.keys));
    for (final key in newTestKeys) {
      final result = tryResults[key];
      final flakiness = flaky[key];
      final name = result["name"];
      final test = new Test(bot, name, result, null, flakiness);
      tests.add(test);
    }
    if (options["verbose"]) {
      print("Loaded $bot (${tests.length} tests).");
    }
    return tests;
  } finally {
    // Always clean up the temporary directory when we don't need it.
    await tmpdir.delete(recursive: true);
  }
}

main(List<String> args) async {
  final parser = new ArgParser();
  parser.addFlag("automated-approver",
      help: "Record the approval as done by an automated process.",
      negatable: false);
  parser.addMultiOption("bot",
      abbr: "b",
      help: "Select the bots matching the glob pattern [option is repeatable]",
      splitCommas: false);
  parser.addFlag("help", help: "Show the program usage.", negatable: false);
  parser.addFlag("failures-only",
      help: "Approve failures only.", negatable: false);
  parser.addFlag("list",
      abbr: "l", help: "List the available bots.", negatable: false);
  parser.addFlag("no",
      abbr: "n",
      help: "Show changed results but don't approve.",
      negatable: false);
  parser.addOption("preapprove",
      abbr: "p", help: "Preapprove the new failures in a gerrit CL.");
  parser.addFlag("successes-only",
      help: "Approve successes only.", negatable: false);
  parser.addFlag("verbose",
      abbr: "v", help: "Describe asynchronous operations.", negatable: false);
  parser.addFlag("yes",
      abbr: "y", help: "Approve the results.", negatable: false);
  parser.addOption("table",
      abbr: "T",
      help: "Select table format.",
      allowed: ["markdown", "indent"],
      defaultsTo: "markdown");

  final options = parser.parse(args);
  if ((options["preapprove"] == null &&
          options["bot"].isEmpty &&
          !options["list"]) ||
      options["help"]) {
    print("""
Usage: approve_results.dart [OPTION]...
List tests whose results are different from the previously approved results, and
ask whether to update the currently approved results, turning the bots green.

The options are as follows:

${parser.usage}""");
    return;
  }

  if (options["no"] && options["yes"]) {
    stderr.writeln("The --no and --yes options are mutually incompatible");
    exitCode = 1;
    return;
  }

  // Locate gsutil.py.
  gsutilPy =
      Platform.script.resolve("../third_party/gsutil/gsutil.py").toFilePath();

  // Load the list of bots according to the test matrix.
  final testMatrixPath =
      Platform.script.resolve("bots/test_matrix.json").toFilePath();
  final testMatrix = jsonDecode(await new File(testMatrixPath).readAsString());
  final builderConfigurations = testMatrix["builder_configurations"];
  final testMatrixBots = <String>[];
  for (final builderConfiguration in builderConfigurations) {
    final steps = builderConfiguration["steps"];
    // Only consider bots that use tools/test.py.
    if (!steps.any((step) =>
        step["script"] == null || step["script"] == "tools/test.py")) {
      continue;
    }
    final builders = builderConfiguration["builders"].cast<String>();
    testMatrixBots.addAll(builders);
  }

  // Load the list of bots that have data in cloud storage.
  if (options["verbose"]) {
    print("Loading list of bots...");
  }
  final botsWithData = (await listBots())
      .where((bot) => !bot.endsWith("-try"))
      .where((bot) => !bot.endsWith("-dev"))
      .where((bot) => !bot.endsWith("-stable"));
  if (options["verbose"]) {
    print("Loaded list of bots.");
  }

  // The currently active bots are the bots both mentioned in the test matrix
  // and that have results in cloud storage.
  final allBots = new Set<String>.from(testMatrixBots)
      .intersection(new Set<String>.from(botsWithData))
      .toList()
        ..sort();

  // List the currently active bots if requested.
  if (options["list"]) {
    for (final bot in allBots) {
      print(bot);
    }
    return;
  }

  // Determine which builders have run for the changelist.
  final changelistBuilds = <String, Map<String, dynamic>>{};
  if (options["preapprove"] != null) {
    if (options["verbose"]) {
      print("Loading list of try runs...");
    }
    final gerritHost = "dart-review.googlesource.com";
    final gerritProject = "sdk";
    final prefix = "https://$gerritHost/c/$gerritProject/+/";
    final gerrit = options["preapprove"];
    if (!gerrit.startsWith(prefix)) {
      stderr.writeln("error: $gerrit doesn't start with $prefix");
      exitCode = 1;
      return;
    }
    final components = gerrit.substring(prefix.length).split("/");
    if (components.length != 2 ||
        int.tryParse(components[0]) == null ||
        int.tryParse(components[1]) == null) {
      stderr.writeln("error: $gerrit must be in the form of "
          "$prefix<changelist>/<patchset>");
      exitCode = 1;
      return;
    }
    final changelist = int.parse(components[0]);
    final patchset = int.parse(components[1]);
    final buildset = "buildset:patch/gerrit/$gerritHost/$changelist/$patchset";
    final url = Uri.parse(
        "https://cr-buildbucket.appspot.com/_ah/api/buildbucket/v1/search"
        "?bucket=luci.dart.try"
        "&tag=${Uri.encodeComponent(buildset)}"
        "&fields=builds(id%2Ctags%2Cstatus%2Cstarted_ts)");
    final client = new HttpClient();
    final request =
        await client.getUrl(url).timeout(const Duration(seconds: 30));
    final response = await request.close().timeout(const Duration(seconds: 30));
    if (response.statusCode != HttpStatus.ok) {
      throw new Exception("Failed to request try runs for $gerrit");
    }
    final Map<String, dynamic> object = await response
        .transform(new Utf8Decoder())
        .transform(new JsonDecoder())
        .first
        .timeout(const Duration(seconds: 30));
    client.close();
    final builds = object["builds"];
    if (builds == null) {
      stderr.writeln(
          "error: $prefix$changelist has no try runs for patchset $patchset");
      exitCode = 1;
      return;
    }

    // Prefer the newest completed build.
    Map<String, dynamic> preferredBuild(
        Map<String, dynamic> a, Map<String, dynamic> b) {
      if (a != null && b == null) return a;
      if (a == null && b != null) return b;
      if (a != null && b != null) {
        if (a["status"] == "COMPLETED" && b["status"] != "COMPLETED") return a;
        if (a["status"] != "COMPLETED" && b["status"] == "COMPLETED") return b;
        if (a["started_ts"] == null && b["started_ts"] != null) return a;
        if (a["started_ts"] != null && b["started_ts"] == null) return b;
        if (a["started_ts"] != null && b["started_ts"] != null) {
          if (int.parse(a["started_ts"]) > int.parse(b["started_ts"])) return a;
          if (int.parse(a["started_ts"]) < int.parse(b["started_ts"])) return b;
        }
      }
      return b;
    }

    for (final build in builds) {
      final tags = (build["tags"] as List<dynamic>).cast<String>();
      final builder = tags
          .firstWhere((tag) => tag.startsWith("builder:"))
          .substring("builder:".length);
      final ciBuilder = builder.replaceFirst(new RegExp("-try\$"), "");
      if (!allBots.contains(ciBuilder)) {
        continue;
      }
      changelistBuilds[ciBuilder] =
          preferredBuild(changelistBuilds[ciBuilder], build);
    }
    if (options["verbose"]) {
      print("Loaded list of try runs.");
    }
  }
  final changelistBuilders = new Set<String>.from(changelistBuilds.keys);

  // Select all the bots matching the glob patterns,
  final finalBotList =
      options["preapprove"] != null ? changelistBuilders : allBots;
  final botPatterns = options["preapprove"] != null && options["bot"].isEmpty
      ? ["*"]
      : options["bot"];
  final bots = new Set<String>();
  for (final botPattern in botPatterns) {
    final glob = new Glob(botPattern);
    bool any = false;
    for (final bot in finalBotList) {
      if (glob.matches(bot)) {
        bots.add(bot);
        any = true;
      }
    }
    if (!any) {
      stderr.writeln("error: No bots matched pattern: $botPattern");
      stderr.writeln("Try --list to get the list of bots, or --help for help");
      exitCode = 1;
      return;
    }
  }
  for (final bot in bots) {
    print("Selected bot: $bot");
  }

  // Error out if any of the requested try runs are incomplete.
  bool anyIncomplete = false;
  for (final bot in bots) {
    if (options["preapprove"] != null &&
        changelistBuilds[bot]["status"] != "COMPLETED") {
      stderr.writeln("error: The try run for $bot isn't complete yet: " +
          changelistBuilds[bot]["status"]);
      anyIncomplete = true;
    }
  }
  if (anyIncomplete) {
    exitCode = 1;
    return;
  }

  // Load all the latest results for the selected bots, as well as flakiness
  // data, and the set of currently approved results. Each bot's latest build
  // is downloaded in parallel to make this phase faster.
  final testListFutures = <Future>[];
  for (final String bot in bots) {
    testListFutures
        .add(loadResultsFromBot(bot, options, changelistBuilds[bot]));
  }

  // Collect all the tests from the synchronous downloads.
  final tests = <Test>[];
  for (final testList in await Future.wait(testListFutures)) {
    tests.addAll(testList);
  }
  tests.sort();
  print("");

  // Compute statistics and the set of interesting tests.
  final flakyTestsCount = tests.where((test) => test.isFlake).length;
  final failingTestsCount =
      tests.where((test) => !test.isFlake && !test.matches).length;
  final unapprovedTests =
      tests.where((test) => !test.isFlake && !test.isApproved).toList();
  final fixedTests = unapprovedTests.where((test) => test.matches).toList();
  final brokenTests = unapprovedTests.where((test) => !test.matches).toList();

  // Find out which bots have multiple configurations.
  final outcomes = new Set<String>();
  final configurationsForBots = <String, Set<String>>{};
  for (final test in tests) {
    outcomes.add(test.result);
    var configurationSet = configurationsForBots[test.bot];
    if (configurationSet == null) {
      configurationsForBots[test.bot] = configurationSet = new Set<String>();
    }
    configurationSet.add(test.configuration);
  }

  // Compute a nice displayed name for the bot and configuration. If the bot
  // only has a single configuration, then only mention the bot. Otherwise,
  // remove the redundant parts from configuration and present it compactly.
  // This is needed to avoid the tables becoming way too large.
  String getBotDisplayName(String bot, String configuration) {
    if (configurationsForBots[bot].length == 1) {
      return bot;
    } else {
      final simpleConfig = simplifyNamedConfiguration(bot, configuration);
      return "$bot/$simpleConfig";
    }
  }

  // Compute the width of the fields in the below tables.
  final unapprovedBots = new Set<String>();
  int longestBot = "BOT/CONFIG".length;
  int longestTest = "TEST".length;
  int longestResult = "RESULT".length;
  int longestExpected = "EXPECTED".length;
  for (final test in unapprovedTests) {
    unapprovedBots.add(test.bot);
    final botDisplayName = getBotDisplayName(test.bot, test.configuration);
    longestBot = max(longestBot, botDisplayName.length);
    longestTest = max(longestTest, test.name.length);
    longestResult = max(longestResult, test.result.length);
    longestExpected = max(longestExpected, test.expected.length);
  }
  longestTest = min(longestTest, 120); // Some tests names are extremely long.

  // Table of lists that now succeed.
  if (fixedTests.isNotEmpty) {
    print("The following tests are now succeeding:\n");
    if (options["table"] == "markdown") {
      print("| ${'BOT/CONFIG'.padRight(longestBot)} "
          "| ${'TEST'.padRight(longestTest)} |");
      print("| ${'-' * longestBot} "
          "| ${'-' * longestTest} |");
    } else if (options["table"] == "indent") {
      print("${'BOT/CONFIG'.padRight(longestBot)}  "
          "TEST");
    }
    for (final test in fixedTests) {
      final botDisplayName = getBotDisplayName(test.bot, test.configuration);
      if (options["table"] == "markdown") {
        print("| ${botDisplayName.padRight(longestBot)} "
            "| ${test.name.padRight(longestTest)} |");
      } else if (options["table"] == "indent") {
        print("${botDisplayName.padRight(longestBot)}  "
            "${test.name}");
      }
    }
    print("");
  }

  /// Table of lists that now fail.
  if (brokenTests.isNotEmpty) {
    print("The following tests are now failing:\n");
    if (options["table"] == "markdown") {
      print("| ${'BOT'.padRight(longestBot)} "
          "| ${'TEST'.padRight(longestTest)} "
          "| ${'RESULT'.padRight(longestResult)} "
          "| ${'EXPECTED'.padRight(longestExpected)} | ");
      print("| ${'-' * longestBot} "
          "| ${'-' * longestTest} "
          "| ${'-' * longestResult} "
          "| ${'-' * longestExpected} | ");
    } else if (options["table"] == "indent") {
      print("${'BOT'.padRight(longestBot)}  "
          "${'TEST'.padRight(longestTest)}  "
          "${'RESULT'.padRight(longestResult)}  "
          "EXPECTED");
    }
    for (final test in brokenTests) {
      final botDisplayName = getBotDisplayName(test.bot, test.configuration);
      if (options["table"] == "markdown") {
        print("| ${botDisplayName.padRight(longestBot)} "
            "| ${test.name.padRight(longestTest)} "
            "| ${test.result.padRight(longestResult)} "
            "| ${test.expected.padRight(longestExpected)} |");
      } else if (options["table"] == "indent") {
        print("${botDisplayName.padRight(longestBot)}  "
            "${test.name.padRight(longestTest)}  "
            "${test.result.padRight(longestResult)}  "
            "${test.expected}");
      }
    }
    print("");
  }

  // Provide statistics on how well the bots are doing.
  void statistic(int numerator, int denominator, String what) {
    double percent = numerator / denominator * 100.0;
    String percentString = percent.toStringAsFixed(2) + "%";
    print("$numerator of $denominator $what ($percentString)");
  }

  statistic(failingTestsCount, tests.length, "tests are failing");
  statistic(flakyTestsCount, tests.length, "tests are flaky");
  statistic(
      fixedTests.length, tests.length, "tests were fixed since last approval");
  statistic(brokenTests.length, tests.length,
      "tests were broken since last approval");

  // Stop if there's nothing to do.
  if (unapprovedBots.isEmpty) {
    print("\nEvery test result has already been approved.");
    return;
  }

  // Stop if this is a dry run.
  if (options["no"]) {
    if (unapprovedTests.length == 1) {
      print("1 test has a changed result and needs approval");
    } else {
      print("${unapprovedTests.length} "
          "tests have changed results and need approval");
    }
    return;
  }

  // Confirm the approval if run interactively.
  if (!options["yes"]) {
    print("");
    print("Note: It is assumed bugs have been filed about the above failures "
        "before they are approved here.");
    if (brokenTests.isNotEmpty) {
      final botPlural = bots.length == 1 ? "bot" : "bots";
      print("Note: Approving the failures will turn the "
          "$botPlural green on the next commit.");
    }
    if (options["preapprove"] != null) {
      print("Warning: Preapproval is currently not sticky and somebody else "
          "approving before your CL has landed will undo your preapproval.");
    }
    while (true) {
      stdout.write("Do you want to approve? (yes/no) [yes] ");
      final line = stdin.readLineSync();
      // End of file condition is considered no.
      if (line == null) {
        print("n");
        return;
      }
      if (line.toLowerCase() == "n" || line.toLowerCase() == "no") {
        return;
      }
      if (line == "" ||
          line.toLowerCase() == "y" ||
          line.toLowerCase() == "yes") {
        break;
      }
    }
  } else {
    print("Note: It is assumed bugs have been filed about the above failures.");
  }
  print("");

  // Log who approved these results.
  final username =
      (options["automated-approver"] ? "automatic-approval" : null) ??
          Platform.environment["LOGNAME"] ??
          Platform.environment["USER"] ??
          Platform.environment["USERNAME"];
  if (username == null || username == "") {
    stderr.writeln("error: Your identity could not be established. "
        "Please set one of the LOGNAME, USER, USERNAME environment variables.");
    exitCode = 1;
    return;
  }
  final now = new DateTime.now().toUtc().toIso8601String();

  // Update approved_results.json for each bot with unapproved changes.
  final outDirectory =
      await Directory.systemTemp.createTemp("approved_results.");
  try {
    final testsForBots = <String, List<Test>>{};
    for (final test in tests) {
      if (!testsForBots.containsKey(test.bot)) {
        testsForBots[test.bot] = <Test>[test];
      } else {
        testsForBots[test.bot].add(test);
      }
    }
    print("Uploading approved results...");
    final futures = <Future>[];
    for (final String bot in unapprovedBots) {
      Map<String, dynamic> approveData(Test test) {
        final data = new Map<String, dynamic>.from(test.resultData);
        if (!test.isApproved) {
          data["approver"] = username;
          data["approved_at"] = now;
        }
        return data;
      }

      final dataList = testsForBots[bot].map(approveData).toList();
      final localPath = "${outDirectory.path}/$bot.json";
      await new File(localPath).writeAsString(
          dataList.map((data) => jsonEncode(data) + "\n").join(""));
      final remotePath =
          "$approvedResultsStoragePath/$bot/approved_results.json";
      futures.add(cpGsutil(localPath, remotePath)
          .then((_) => print("Uploaded approved results for $bot")));
    }
    await Future.wait(futures);
    if (brokenTests.isNotEmpty) {
      print(
          "Successfully approved results, the next commit will turn bots green");
    } else {
      print("Successfully approved results");
    }
  } finally {
    await outDirectory.delete(recursive: true);
  }
}
