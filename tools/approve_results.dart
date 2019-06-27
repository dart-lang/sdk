#!/usr/bin/env dart
// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// List tests whose results are different from the previously approved results,
/// and ask whether to update the currently approved results, turning the bots
/// green.

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:args/args.dart';
import 'package:glob/glob.dart';

import 'bots/results.dart';

/// Returns whether two decoded JSON objects are identical.
bool isIdenticalJson(dynamic a, dynamic b) {
  if (a is Map<String, dynamic> && b is Map<String, dynamic>) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key)) return false;
      if (!isIdenticalJson(a[key], b[key])) return false;
    }
    return true;
  } else if (a is List<dynamic> && b is List<dynamic>) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (!isIdenticalJson(a[i], b[i])) return false;
    }
    return true;
  } else {
    return a == b;
  }
}

/// Returns whether two sets of approvals are identical.
bool isIdenticalApprovals(
    Map<String, Map<String, dynamic>> a, Map<String, Map<String, dynamic>> b) {
  if (a.length != b.length) return false;
  for (final key in a.keys) {
    if (!b.containsKey(key)) return false;
    if (!isIdenticalJson(a[key], b[key])) return false;
  }
  return true;
}

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

/// Represents a test on a bot with the baseline results (if tryrun), the
/// current result, the current approved result, and flakiness data.
class Test implements Comparable {
  final String bot;
  final Map<String, dynamic> baselineData;
  final Map<String, dynamic> resultData;
  final Map<String, dynamic> approvedResultData;
  final Map<String, dynamic> flakinessData;

  Test(this.bot, this.baselineData, this.resultData, this.approvedResultData,
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

  Map<String, dynamic> get _sharedData =>
      resultData ?? baselineData ?? approvedResultData;
  String get name => _sharedData["name"];
  String get configuration => _sharedData["configuration"];
  String get key => "$configuration:$name";
  String get expected => _sharedData["expected"];
  String get result => (resultData ?? const {})["result"];
  bool get matches => _sharedData["matches"];
  String get baselineResult => (baselineData ?? const {})["result"];
  String get approvedResult => (approvedResultData ?? const {})["result"];
  bool get isDifferent => result != null && result != baselineResult;
  bool get isApproved => result == null || result == approvedResult;
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

/// Exception for when the results for a builder can't be found.
class NoResultsException implements Exception {
  final String message;
  final String buildUrl;

  NoResultsException(this.message, this.buildUrl);

  String toString() => message;
}

/// Loads a log from logdog.
Future<String> loadLog(String id, String step) async {
  final buildUrl = "https://ci.chromium.org/b/$id";
  final logUrl = Uri.parse("https://logs.chromium.org/"
      "logs/dart/buildbucket/cr-buildbucket.appspot.com/"
      "$id/+/steps/$step?format=raw");
  final client = new HttpClient();
  try {
    final request =
        await client.getUrl(logUrl).timeout(const Duration(seconds: 60));
    final response = await request.close().timeout(const Duration(seconds: 60));
    if (response.statusCode == HttpStatus.notFound) {
      await response.drain();
      throw new NoResultsException(
          "The log at $logUrl doesn't exist: ${response.statusCode}", buildUrl);
    }
    if (response.statusCode != HttpStatus.ok) {
      await response.drain();
      throw new Exception("Failed to download $logUrl: ${response.statusCode}");
    }
    final contents = (await response
            .cast<List<int>>()
            .transform(new Utf8Decoder())
            .timeout(const Duration(seconds: 60))
            .toList())
        .join("");
    return contents;
  } finally {
    client.close();
  }
}

/// TODO(https://github.com/dart-lang/sdk/issues/36015): The step name changed
/// incompatibly, allow both temporarily to reduce the user breakage. Remove
/// this 2019-03-25.
Future<String> todoFallbackLoadLog(
    String id, String primary, String secondary) async {
  try {
    return await loadLog(id, primary);
  } catch (e) {
    if (e.toString().startsWith("Exception: The log at ") &&
        e.toString().endsWith(" doesn't exist")) {
      return await loadLog(id, secondary);
    }
    rethrow;
  }
}

/// Loads the results from the bot.
Future<List<Test>> loadResultsFromBot(String bot, ArgResults options,
    String changeId, Map<String, dynamic> changelistBuild) async {
  if (options["verbose"]) {
    print("Loading $bot...");
  }
  // gsutil cp -r requires a destination directory, use a temporary one.
  final tmpdir = await Directory.systemTemp.createTemp("approve_results.");
  try {
    // The 'latest' file contains the name of the latest build that we
    // should download. When preapproving a changelist, we instead find out
    // which build the commit queue was rebased on.
    /// TODO(https://github.com/dart-lang/sdk/issues/36015): The step name
    /// changed incompatibly, allow both temporarily to reduce the user
    /// breakage. Remove this 2019-03-25.
    final build = (changeId != null
            ? await todoFallbackLoadLog(
                changelistBuild["id"],
                "download_previous_results/0/steps/gsutil_find_latest_build/0/logs/"
                    "raw_io.output_text_latest_/0",
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
        if (changeId != null) {
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

    // TODO: Remove 2019-04-08: Discard any invalid pre-approvals made with a
    // version of approve_results between 065910f0 and a13ac1b4. Pre-approving
    // a new test could add pre-approvals with null configuration and null name.
    approvedResults.remove("null:null");

    // Construct an object for every test containing its current result,
    // what the last approved result was, and whether it's flaky.
    final tests = <Test>[];
    final testResults = changeId != null ? tryResults : results;
    for (final key in testResults.keys) {
      final baselineResult = changeId != null ? results[key] : null;
      final testResult = testResults[key];
      final approvedResult = approvedResults[key];
      final flakiness = flaky[key];
      final test =
          new Test(bot, baselineResult, testResult, approvedResult, flakiness);
      tests.add(test);
    }
    // Add in approvals whose test was no longer in the results.
    for (final key in approvedResults.keys) {
      if (testResults.containsKey(key)) continue;
      final baselineResult = changeId != null ? results[key] : null;
      final approvedResult = approvedResults[key];
      final flakiness = flaky[key];
      final test =
          new Test(bot, baselineResult, null, approvedResult, flakiness);
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

Future<Map<String, dynamic>> loadJsonPrefixedAPI(String url) async {
  final client = new HttpClient();
  try {
    final request = await client
        .getUrl(Uri.parse(url))
        .timeout(const Duration(seconds: 30));
    final response = await request.close().timeout(const Duration(seconds: 30));
    if (response.statusCode != HttpStatus.ok) {
      throw new Exception("Failed to request $url: ${response.statusCode}");
    }
    final text = await response
        .cast<List<int>>()
        .transform(utf8.decoder)
        .join()
        .timeout(const Duration(seconds: 30));
    return jsonDecode(text.substring(5 /* ")]}'\n" */));
  } finally {
    client.close();
  }
}

Future<Map<String, dynamic>> loadChangelistDetails(
    String gerritHost, String changeId) async {
  // ?O=516714 requests the revisions field.
  final url = "https://$gerritHost/changes/$changeId/detail?O=516714";
  return await loadJsonPrefixedAPI(url);
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

See the documentation at https://goto.google.com/dart-status-file-free-workflow

The options are as follows:

${parser.usage}""");
    return;
  }

  if (options["no"] && options["yes"]) {
    stderr.writeln("The --no and --yes options are mutually incompatible");
    exitCode = 1;
    return;
  }

  if (options.rest.isNotEmpty) {
    stderr.writeln("Unexpected extra argument: ${options.rest.first}");
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
    // Only consider bots that use tools/test.py or custom test runners.
    if (!steps.any((step) =>
        step["script"] == null ||
        step["script"] == "tools/test.py" ||
        step["testRunner"] == true)) {
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
  final isPreapproval = options["preapprove"] != null;
  String changeId;
  if (isPreapproval) {
    if (options["verbose"]) {
      print("Loading changelist details...");
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
    if (!((components.length == 1 && int.tryParse(components[0]) != null) ||
        (components.length == 2 &&
            int.tryParse(components[0]) != null &&
            int.tryParse(components[1]) != null))) {
      stderr.writeln("error: $gerrit must be in the form of "
          "$prefix<changelist> or $prefix<changelist>/<patchset>");
      exitCode = 1;
      return;
    }
    final changelist = int.parse(components[0]);
    final details =
        await loadChangelistDetails(gerritHost, changelist.toString());
    changeId = details["change_id"];
    final patchset = 2 <= components.length
        ? int.parse(components[1])
        : details["revisions"][details["current_revision"]]["_number"];
    if (2 <= components.length) {
      print("Using Change-Id $changeId patchset $patchset");
    } else {
      print("Using Change-Id $changeId with the latest patchset $patchset");
    }
    if (options["verbose"]) {
      print("Loading list of try runs...");
    }
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
        .cast<List<int>>()
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
  final testListFutures = <Future<List<Test>>>[];
  final noResultsBuilds = new SplayTreeMap<String, String>();
  for (final String bot in bots) {
    testListFutures.add(new Future(() async {
      try {
        return await loadResultsFromBot(
            bot, options, changeId, changelistBuilds[bot]);
      } on NoResultsException catch (e) {
        print(
            "Error: Failed to find results for $bot build <${e.buildUrl}>: $e");
        noResultsBuilds[bot] = e.buildUrl;
        return <Test>[];
      }
    }));
  }

  // Collect all the tests from the synchronous downloads.
  final tests = <Test>[];
  for (final testList in await Future.wait(testListFutures)) {
    tests.addAll(testList);
  }
  tests.sort();
  print("");

  // Compute statistics and the set of interesting tests.
  final flakyTestsCount =
      tests.where((test) => test.resultData != null && test.isFlake).length;
  final failingTestsCount = tests
      .where(
          (test) => test.resultData != null && !test.isFlake && !test.matches)
      .length;
  final differentTests = tests
      .where((test) =>
          (isPreapproval ? test.isDifferent : !test.isApproved) &&
          !test.isFlake)
      .toList();
  final selectedTests = differentTests
      .where((test) => !(test.matches
          ? options["failures-only"]
          : options["successes-only"]))
      .toList();
  final fixedTests = selectedTests.where((test) => test.matches).toList();
  final brokenTests = selectedTests.where((test) => !test.matches).toList();

  // Find out which bots have multiple configurations.
  final configurationsForBots = <String, Set<String>>{};
  for (final test in tests) {
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
  for (final test in selectedTests) {
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

  // Warn about any builders where results weren't available.
  if (noResultsBuilds.isNotEmpty) {
    print("");
    noResultsBuilds.forEach((String builder, String buildUrl) {
      print("Warning: No results were found for $builder: <$buildUrl>");
    });
    print("Warning: Builders without results are usually due to infrastructure "
        "issues, please have a closer look at the affected builders and try "
        "the build again.");
  }

  // Stop if there's nothing to do.
  if (unapprovedBots.isEmpty) {
    print("\nEvery test result has already been approved.");
    return;
  }

  // Stop if this is a dry run.
  if (options["no"]) {
    if (selectedTests.length == 1) {
      print("1 test has a changed result and needs approval");
    } else {
      print("${selectedTests.length} "
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
      final builderPlural = bots.length == 1 ? "builder" : "builders";
      final tryBuilders = isPreapproval ? "try$builderPlural" : builderPlural;
      final tryCommit = isPreapproval ? "tryrun" : "commit";
      print("Note: Approving the failures will turn the "
          "$tryBuilders green on the next $tryCommit.");
    }
    while (true) {
      final approve = isPreapproval ? "pre-approve" : "approve";
      stdout.write("Do you want to $approve? (yes/no) [yes] ");
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
  final nowDate = new DateTime.now().toUtc();
  final now = nowDate.toIso8601String();

  // Deep clones a decoded json object.
  dynamic deepClone(dynamic object) {
    if (object is Map<String, dynamic>) {
      final result = <String, dynamic>{};
      for (final key in object.keys) {
        result[key] = deepClone(object[key]);
      }
      return result;
    } else if (object is List<dynamic>) {
      final result = <dynamic>[];
      for (final value in object) {
        result.add(deepClone(value));
      }
      return result;
    } else {
      return object;
    }
  }

  // Build the new approval data with the changes in test results applied.
  final newApprovalsForBuilders = <String, Map<String, Map<String, dynamic>>>{};

  if (isPreapproval) {
    // Import all the existing approval data, keeping tests that don't exist
    // anymore.
    for (final test in tests) {
      if (test.approvedResultData == null) continue;
      final approvalData = deepClone(test.approvedResultData);
      // TODO(https://github.com/dart-lang/sdk/issues/36279): Remove needless
      // fields that shouldn't be in the approvals data. Remove this 2019-04-03.
      approvalData.remove("bot_name");
      approvalData.remove("builder_name");
      approvalData.remove("build_number");
      approvalData.remove("changed");
      approvalData.remove("commit_hash");
      approvalData.remove("commit_time");
      approvalData.remove("commit_hash");
      approvalData.remove("flaky");
      approvalData.remove("previous_build_number");
      approvalData.remove("previous_commit_hash");
      approvalData.remove("previous_commit_time");
      approvalData.remove("previous_flaky");
      approvalData.remove("previous_result");
      approvalData.remove("time_ms");
      // Discard all the existing pre-approvals for this changelist.
      final preapprovals =
          approvalData.putIfAbsent("preapprovals", () => <String, dynamic>{});
      preapprovals.remove(changeId);
      final newApprovals = newApprovalsForBuilders.putIfAbsent(
          test.bot, () => new SplayTreeMap<String, Map<String, dynamic>>());
      newApprovals[test.key] = approvalData;
    }

    // Pre-approve all the regressions (no need to pre-approve fixed tests).
    for (final test in brokenTests) {
      final newApprovals = newApprovalsForBuilders.putIfAbsent(
          test.bot, () => new SplayTreeMap<String, Map<String, dynamic>>());
      final approvalData =
          newApprovals.putIfAbsent(test.key, () => <String, dynamic>{});
      approvalData["name"] = test.name;
      approvalData["configuration"] = test.configuration;
      approvalData["suite"] = test.resultData["suite"];
      approvalData["test_name"] = test.resultData["test_name"];
      final preapprovals =
          approvalData.putIfAbsent("preapprovals", () => <String, dynamic>{});
      final preapproval =
          preapprovals.putIfAbsent(changeId, () => <String, dynamic>{});
      preapproval["from"] = test.approvedResult;
      preapproval["result"] = test.result;
      preapproval["matches"] = test.matches;
      preapproval["expected"] = test.expected;
      preapproval["preapprover"] = username;
      preapproval["preapproved_at"] = now;
      preapproval["expires"] =
          nowDate.add(const Duration(days: 30)).toIso8601String();
    }
  } else {
    // Import all the existing approval data for tests, removing tests that
    // don't exist anymore unless they have pre-approvals.
    for (final test in tests) {
      if (test.approvedResultData == null) continue;
      if (test.result == null &&
          (test.approvedResultData["preapprovals"] ?? <dynamic>[]).isEmpty) {
        continue;
      }
      final approvalData = deepClone(test.approvedResultData);
      // TODO(https://github.com/dart-lang/sdk/issues/36279): Remove needless
      // fields that shouldn't be in the approvals data. Remove this 2019-04-03.
      approvalData.remove("bot_name");
      approvalData.remove("builder_name");
      approvalData.remove("build_number");
      approvalData.remove("changed");
      approvalData.remove("commit_hash");
      approvalData.remove("commit_time");
      approvalData.remove("commit_hash");
      approvalData.remove("flaky");
      approvalData.remove("previous_build_number");
      approvalData.remove("previous_commit_hash");
      approvalData.remove("previous_commit_time");
      approvalData.remove("previous_flaky");
      approvalData.remove("previous_result");
      approvalData.remove("time_ms");
      approvalData.putIfAbsent("preapprovals", () => <String, dynamic>{});
      final newApprovals = newApprovalsForBuilders.putIfAbsent(
          test.bot, () => new SplayTreeMap<String, Map<String, dynamic>>());
      newApprovals[test.key] = approvalData;
    }

    // Approve the changes in test results.
    for (final test in selectedTests) {
      final newApprovals = newApprovalsForBuilders.putIfAbsent(
          test.bot, () => new SplayTreeMap<String, Map<String, dynamic>>());
      final approvalData =
          newApprovals.putIfAbsent(test.key, () => <String, dynamic>{});
      approvalData["name"] = test.name;
      approvalData["configuration"] = test.configuration;
      approvalData["suite"] = test.resultData["suite"];
      approvalData["test_name"] = test.resultData["test_name"];
      approvalData["result"] = test.result;
      approvalData["expected"] = test.expected;
      approvalData["matches"] = test.matches;
      approvalData["approver"] = username;
      approvalData["approved_at"] = now;
      approvalData.putIfAbsent("preapprovals", () => <String, dynamic>{});
    }
  }

  // Reconstruct the old approvals so we can double check there was no race
  // condition when uploading.
  final oldApprovalsForBuilders = <String, Map<String, Map<String, dynamic>>>{};
  for (final test in tests) {
    if (test.approvedResultData == null) continue;
    final oldApprovals = oldApprovalsForBuilders.putIfAbsent(
        test.bot, () => new SplayTreeMap<String, Map<String, dynamic>>());
    oldApprovals[test.key] = test.approvedResultData;
  }
  for (final builder in newApprovalsForBuilders.keys) {
    oldApprovalsForBuilders.putIfAbsent(
        builder, () => <String, Map<String, dynamic>>{});
  }

  // Update approved_results.json for each builder with unapproved changes.
  final outDirectory =
      await Directory.systemTemp.createTemp("approved_results.");
  bool raceCondition = false;
  try {
    print("Uploading approved results...");
    final futures = <Future>[];
    for (final String builder in newApprovalsForBuilders.keys) {
      final approvals = newApprovalsForBuilders[builder].values;
      final localPath = "${outDirectory.path}/$builder.json";
      await new File(localPath).writeAsString(
          approvals.map((approval) => jsonEncode(approval) + "\n").join(""));
      final remotePath =
          "$approvedResultsStoragePath/$builder/approved_results.json";
      futures.add(new Future(() async {
        if (!options["yes"]) {
          if (options["verbose"]) {
            print("Checking for race condition on $builder...");
          }
          final oldApprovedResults = oldApprovalsForBuilders[builder];
          final oldApprovalPath = "${outDirectory.path}/$builder.json.old";
          await cpGsutil(remotePath, oldApprovalPath);
          final checkApprovedResults =
              await loadResultsMapIfExists(oldApprovalPath);
          if (!isIdenticalApprovals(oldApprovedResults, checkApprovedResults)) {
            print("error: Race condition: "
                "$builder approvals have changed, please try again.");
            raceCondition = true;
            return;
          }
        }
        if (options["verbose"]) {
          print("Uploading approved results for $builder...");
        }
        await cpGsutil(localPath, remotePath);
        print("Uploaded approved results for $builder");
      }));
    }
    await Future.wait(futures);
    if (raceCondition) {
      exitCode = 1;
      print("error: Somebody else has approved, please try again");
      return;
    }
    if (brokenTests.isNotEmpty) {
      final approved = isPreapproval ? "pre-approved" : "approved";
      final commit = isPreapproval ? "tryrun" : "commit";
      print("Successfully $approved results, the next $commit "
          "will turn builders green");
    } else {
      print("Successfully approved results");
    }
  } finally {
    await outDirectory.delete(recursive: true);
  }
}
