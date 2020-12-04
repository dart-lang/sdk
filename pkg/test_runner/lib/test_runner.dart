// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Run tests like on the given builder and/or named configuration.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:smith/smith.dart';

import 'bot_results.dart';
import 'src/options.dart';

const int deflakingCount = 5;

/// Quotes a string in shell single quote mode. This function produces a single
/// shell argument that evaluates to the exact string provided, handling any
/// special characters in the input string. Shell single quote mode works uses
/// the single quote character as the delimiter and uses the characters
/// in-between verbatim without any special processing. To insert the single
/// quote character itself, escape single quote mode, insert an escaped single
/// quote, and then return to single quote mode.
///
/// Examples:
///   foo becomes 'foo'
///   foo bar becomes 'foo bar'
///   foo\ bar becomes 'foo\ bar'
///   foo's bar becomes 'foo '\''s bar'
///   foo "b"ar becomes 'foo "b"'
///   foo
///   bar becomes 'foo
///   bar'
String shellSingleQuote(String string) {
  return "'${string.replaceAll("'", "'\\''")}'";
}

/// Like [shellSingleQuote], but if the string only contains safe ASCII
/// characters, don't quote it. Note that it's not always safe to omit the
/// quotes even if the string only has safe characters, as doing so might match
/// a shell keyword or a shell builtin in the first argument in a command. It
/// should be safe to use this for the second argument onwards in a command.
String simpleShellSingleQuote(String string) {
  return RegExp(r"^[a-zA-Z0-9%+,./:_-]*$").hasMatch(string)
      ? string
      : shellSingleQuote(string);
}

/// Runs a process and exits likewise if the process exits non-zero.
Future<ProcessResult> runProcess(String executable, List<String> arguments,
    {bool runInShell = false}) async {
  var processResult =
      await Process.run(executable, arguments, runInShell: runInShell);
  if (processResult.exitCode != 0) {
    var command =
        [executable, ...arguments].map(simpleShellSingleQuote).join(" ");
    throw Exception("Command exited ${processResult.exitCode}: $command\n"
        "${processResult.stdout}\n${processResult.stderr}");
  }
  return processResult;
}

/// Runs a process and exits likewise if the process exits non-zero, but let the
/// child process inherit out stdio handles.
Future<ProcessResult> runProcessInheritStdio(
    String executable, List<String> arguments,
    {bool runInShell = false}) async {
  var process = await Process.start(executable, arguments,
      mode: ProcessStartMode.inheritStdio, runInShell: runInShell);
  var exitCode = await process.exitCode;
  var processResult = ProcessResult(process.pid, exitCode, "", "");
  if (processResult.exitCode != 0) {
    var command =
        [executable, ...arguments].map(simpleShellSingleQuote).join(" ");
    throw Exception("Command exited ${processResult.exitCode}: $command");
  }
  return processResult;
}

/// Finds the branch of a builder given the list of branches.
String branchOfBuilder(String builder, List<String> branches) {
  return branches.where((branch) => branch != "master").firstWhere(
      (branch) => builder.endsWith("-$branch"),
      orElse: () => "master");
}

/// Finds the named configuration to test according to the test matrix
/// information and the command line options.
Map<String, Set<Builder>> resolveNamedConfigurations(
    TestMatrix testMatrix,
    String requestedBranch,
    List<String> requestedNamedConfigurations,
    String requestedBuilder) {
  assert(requestedBranch != null);
  var testedConfigurations = <String, Set<Builder>>{};
  var foundBuilder = false;
  for (var builder in testMatrix.builders) {
    if (requestedBuilder != null && builder.name != requestedBuilder) {
      continue;
    }
    var branch = branchOfBuilder(builder.name, testMatrix.branches);
    if (branch != requestedBranch) {
      if (requestedBuilder == null) {
        continue;
      }
      stderr.writeln("error: Builder $requestedBuilder is on branch $branch "
          "rather than $requestedBranch");
      stderr.writeln("error: To compare with that branch, use: -B $branch");
      return null;
    }
    foundBuilder = true;
    for (var step in builder.steps.where((step) => step.isTestStep)) {
      var testedConfiguration = step.testedConfiguration;
      if (testedConfiguration == null) {
        // This test step does not use a configuration; for example,
        // because it is a simple script that does not produce results.
        continue;
      }
      var namedConfiguration = testedConfiguration.name;
      if (requestedNamedConfigurations.isEmpty ||
          requestedNamedConfigurations.contains(namedConfiguration)) {
        testedConfigurations
            .putIfAbsent(namedConfiguration, () => {})
            .add(builder);
      }
    }
  }
  if (requestedBuilder != null && !foundBuilder) {
    stderr.writeln("error: Builder $requestedBuilder doesn't exist");
    return null;
  }
  if (requestedBuilder != null &&
      requestedNamedConfigurations.isEmpty &&
      testedConfigurations.isEmpty) {
    stderr.writeln("error: Builder $requestedBuilder isn't testing any named "
        "configurations");
    return null;
  }
  if (requestedNamedConfigurations.isNotEmpty) {
    var hasUntestedConfiguration = false;
    for (var requestedConfiguration in requestedNamedConfigurations) {
      if (!testedConfigurations.containsKey(requestedConfiguration)) {
        var builder = requestedBuilder != null
            ? "builder $requestedBuilder"
            : "any builder";
        stderr.writeln("error: The named configuration "
            "$requestedConfiguration isn't tested on $builder");
        hasUntestedConfiguration = true;
      }
    }
    if (hasUntestedConfiguration) {
      return null;
    }
  }

  return testedConfigurations;
}

/// Locates the merge base between head and the [branch] on the given [remote].
Future<String> findMergeBase(String remote, String branch) async {
  var arguments = ["merge-base", "$remote/$branch", "HEAD"];
  var result =
      await Process.run("git", arguments, runInShell: Platform.isWindows);

  var stdout = result.stdout as String;
  var stderr = result.stderr as String;

  if (result.exitCode != 0) {
    throw Exception("Failed to run: git ${arguments.join(' ')}\n"
        "stdout:\n$stdout\n"
        "stderr:\n$stderr\n");
  }
  return LineSplitter.split(stdout).first;
}

/// Exception thrown when looking up the build for a commit failed.
class NoResultsForCommitException implements Exception {
  final String reason;

  NoResultsForCommitException(this.reason);

  String toString() => reason;
}

/// The result after searching for a build of a commit.
class BuildSearchResult {
  final int build;
  final String commit;

  BuildSearchResult(this.build, this.commit);
}

/// Locates the build number of the [commit] on the [builder], or throws an
/// exception if the builder hasn't built the commit.
Future<BuildSearchResult> searchForBuild(String builder, String commit) async {
  var requestUrl = Uri.parse(
      "https://cr-buildbucket.appspot.com/_ah/api/buildbucket/v1/search"
      "?bucket=luci.dart.ci.sandbox"
      "&tag=builder%3A$builder"
      "&tag=buildset%3Acommit%2Fgit%2F$commit"
      "&fields=builds(status%2Ctags%2Curl)");
  var client = HttpClient();
  var request = await client.getUrl(requestUrl);
  var response = await request.close();
  var object = await response
      .cast<List<int>>()
      .transform(const Utf8Decoder())
      .transform(const JsonDecoder())
      .first as Map<String, dynamic>;
  client.close();
  var builds = object["builds"] as List<dynamic>;
  if (builds == null || builds.isEmpty) {
    throw NoResultsForCommitException(
        "Builder $builder hasn't built commit $commit");
  }
  var build = builds.last;
  var tags = (build["tags"] as List).cast<String>();
  var buildAddressTag =
      tags.firstWhere((tag) => tag.startsWith("build_address:"));
  var buildAddress = buildAddressTag.substring("build_address:".length);
  var buildNumber = int.parse(buildAddress.split("/").last);
  if (build["status"] != "COMPLETED") {
    throw NoResultsForCommitException(
        "Build $buildAddress isn't completed yet");
  }
  var resultsPath = buildFileCloudPath(builder, "$buildNumber", "results.json");
  var flakyPath = buildFileCloudPath(builder, "$buildNumber", "flaky.json");
  if (await lsGsutil(resultsPath) == null ||
      await lsGsutil(flakyPath) == null) {
    throw NoResultsForCommitException(
        "Build $buildAddress did not upload results");
  }
  return BuildSearchResult(buildNumber, commit);
}

Future<BuildSearchResult> searchForApproximateBuild(
    String builder, String commit) async {
  try {
    return await searchForBuild(builder, commit);
  } on NoResultsForCommitException catch (e) {
    print("Warning: $e, searching for an inexact previous build...");
    var limit = 25;
    var arguments = [
      "rev-list",
      "$commit~$limit..$commit~1",
      "--first-parent",
      "--topo-order"
    ];
    var processResult = await Process.run("git", arguments, runInShell: true);
    if (processResult.exitCode != 0) {
      throw Exception("Failed to list potential commits: git $arguments\n"
          "exitCode: ${processResult.exitCode}\n"
          "stdout: ${processResult.stdout}\n"
          "stdout: ${processResult.stderr}\n");
    }
    for (var fallbackCommit
        in LineSplitter.split(processResult.stdout as String)) {
      try {
        return await searchForBuild(builder, fallbackCommit);
      } catch (e) {
        print(
            "Warning: Searching for inexact baseline build: $e, continuing...");
      }
    }
    throw NoResultsForCommitException(
        "Failed to locate approximate baseline results for "
        "$commit in past $limit commits");
  }
}

void overrideConfiguration(Map<String, Map<String, dynamic>> results,
    String configuration, String newConfiguration) {
  results.forEach((String key, Map<String, dynamic> result) {
    if (result["configuration"] == configuration) {
      result["configuration"] = newConfiguration;
    }
  });
}

void printUsage(ArgParser parser, {String error, bool printOptions = false}) {
  if (error != null) {
    print("$error\n");
    exitCode = 1;
  }
  print("""
Usage: test.dart -b [BUILDER] -n [CONFIGURATION] [OPTION]... [--]
                 [TEST.PY OPTION]... [SELECTOR]...

Run tests and compare with the results on the given builder. Either the -n or
the -b option, or both, must be used. Any options following -- and non-option
arguments will be forwarded to test.py invocations. The specified named
configuration's results will be downloaded from the specified builder. If only a
named configuration is specified, the results are downloaded from the
appropriate builders. If only a builder is specified, the default named
configuration is used if the builder only has a single named configuration.
Otherwise the available named configurations are listed.

See the documentation at https://goto.google.com/dart-status-file-free-workflow
""");
  if (printOptions) {
    print(parser.usage);
  } else {
    print("Run test.dart --help to see all options.");
  }
}

Future<void> runTests(List<String> args) async {
  var parser = ArgParser();
  parser.addOption("builder",
      abbr: "b", help: "Run tests like on the given builder");
  parser.addOption("branch",
      abbr: "B",
      help: "Select the builders building this branch",
      defaultsTo: "master");
  parser.addOption("commit", abbr: "C", help: "Compare with this commit");
  parser.addFlag("deflake",
      help: "Re-run failing newly tests $deflakingCount times.");
  parser.addFlag("report-flakes",
      help: "Report test failures for tests known to be flaky.\n"
          "This ignores all flakiness data from CI but flakes\n"
          "detected by --deflake will remain hidden");
  parser.addFlag("list-configurations",
      help: "Output list of configurations.", negatable: false);
  parser.addMultiOption("named-configuration",
      abbr: "n",
      help: "The named test configuration(s) that supplies the\nvalues for all "
          "test options, specifying how tests\nshould be run.");
  parser.addOption("local-configuration",
      abbr: "N",
      help: "Use a different named configuration for local\ntesting than the "
          "named configuration the baseline\nresults were downloaded for. The "
          "results may be\ninexact if the baseline configuration is "
          "different.");
  parser.addOption("remote",
      abbr: "R",
      help: "Compare with this remote and git branch",
      defaultsTo: "origin");
  parser.addFlag("help", help: "Show the program usage.", negatable: false);

  ArgResults options;
  try {
    options = parser.parse(args);
  } on FormatException catch (exception) {
    printUsage(parser, error: exception.message);
    return;
  }

  if (options["help"] as bool) {
    printUsage(parser, printOptions: true);
    return;
  }

  if (options["list-configurations"] as bool) {
    listConfigurations({"system": "all"});
    return;
  }

  var requestedBuilder = options["builder"] as String;
  var requestedNamedConfigurations =
      (options["named-configuration"] as List).cast<String>();
  var localConfiguration = options["local-configuration"] as String;

  if (requestedBuilder == null && requestedNamedConfigurations.isEmpty) {
    printUsage(parser,
        error: "Please specify either a configuration (-n) or "
            "a builder (-b)");
    return;
  }

  if (localConfiguration != null && requestedNamedConfigurations.length > 1) {
    printUsage(parser,
        error: "Local configuration (-N) can only be used with a"
            " single named configuration (-n)");
    return;
  }

  // Locate gsutil.py.
  gsutilPy =
      Platform.script.resolve("../third_party/gsutil/gsutil.py").toFilePath();

  // Load the test matrix.
  var testMatrixPath = Platform.script.resolve("bots/test_matrix.json");
  var testMatrix = TestMatrix.fromPath(testMatrixPath.toFilePath());
  // Determine what named configuration to run and which builders to download
  // existing results from.
  var testedConfigurations = resolveNamedConfigurations(
      testMatrix,
      options["branch"] as String,
      requestedNamedConfigurations,
      requestedBuilder);
  if (testedConfigurations == null) {
    // No valid configuration could be found. The error has already been
    // reported by [resolveConfigurations].
    exitCode = 1;
    return;
  }
  var namedConfigurations = testedConfigurations.keys.toSet().toList();
  var builders =
      testedConfigurations.values.expand((builders) => builders).toSet();

  // Print information about the resolved builders to compare with.
  for (var namedConfiguration in namedConfigurations) {
    var testedBuilders = testedConfigurations[namedConfiguration];
    var onWhichBuilders = testedBuilders.length == 1
        ? "builder ${testedBuilders.single.name}"
        : "builders${testedBuilders.map((b) => "\n  ${b.name}").join()}";
    if (localConfiguration != null) {
      print("Testing named configuration $localConfiguration "
          "compared with configuration $namedConfiguration "
          "on $onWhichBuilders");
    } else {
      print("Testing named configuration $namedConfiguration "
          "compared with $onWhichBuilders");
    }
  }

  // Use given commit or find out where the current HEAD branched.
  var commit = options["commit"] as String ??
      await findMergeBase(
          options["remote"] as String, options["branch"] as String);
  print("Base commit is $commit");

  // Store the downloaded results and our test results in a temporary directory.
  var outDirectory = await Directory.systemTemp.createTemp("test.dart.");
  try {
    var tasks = <Future>[];
    var needsConfigurationOverride = localConfiguration != null &&
        localConfiguration != namedConfigurations.single;
    var needsMerge = builders.length > 1;
    var inexactBuilds = <String, String>{};
    var previousFileName = "previous.json";
    var flakyFileName = "flaky.json";
    var downloadNumber = 0;

    // Download the previous results and flakiness info from cloud storage.
    for (var builder in builders) {
      var builderName = builder.name;
      if (needsMerge) {
        previousFileName = "previous-$downloadNumber.json";
        flakyFileName = "flaky-$downloadNumber.json";
        downloadNumber++;
      }

      // Use the buildbucket API to search for builds of the right commit.
      print("Finding build on builder $builderName to compare with...");
      var buildSearchResult =
          await searchForApproximateBuild(builderName, commit);
      if (buildSearchResult.commit != commit) {
        print("Warning: Using commit ${buildSearchResult.commit} "
            "as baseline instead of $commit for $builderName");
        inexactBuilds[builderName] = buildSearchResult.commit;
      }

      var buildNumber = buildSearchResult.build.toString();
      print("Downloading results from builder $builderName "
          "build $buildNumber...");
      tasks.add(cpGsutil(
          buildFileCloudPath(builderName, buildNumber, "results.json"),
          "${outDirectory.path}/$previousFileName"));
      if (!(options["report-flakes"] as bool)) {
        tasks.add(cpGsutil(
            buildFileCloudPath(builderName, buildNumber, "flaky.json"),
            "${outDirectory.path}/$flakyFileName"));
      }
    }

    // Run the tests.
    var configurationsToRun = localConfiguration != null
        ? <String>[localConfiguration]
        : namedConfigurations;
    print("".padLeft(80, "="));
    print("Running tests");
    print("".padLeft(80, "="));
    await runProcessInheritStdio(
        "python",
        [
          "tools/test.py",
          "--named-configuration=${configurationsToRun.join(",")}",
          "--output-directory=${outDirectory.path}",
          "--clean-exit",
          "--silent-failures",
          "--write-results",
          "--write-logs",
          ...options.rest,
        ],
        runInShell: Platform.isWindows);
    // Wait for the downloads and the test run to complete.
    await Future.wait(tasks);
    // Merge the results and flaky data downloaded from the builders.
    var mergedResults = <String, Map<String, dynamic>>{};
    var mergedFlaky = <String, Map<String, dynamic>>{};
    if (needsMerge || needsConfigurationOverride) {
      for (var i = 0; i < downloadNumber; ++i) {
        previousFileName = needsMerge ? "previous-$i.json" : "previous.json";
        var results =
            await loadResultsMap("${outDirectory.path}/$previousFileName");
        if (needsConfigurationOverride) {
          overrideConfiguration(
              results, namedConfigurations.single, localConfiguration);
        }
        mergedResults.addAll(results);
        if (!(options["report-flakes"] as bool)) {
          flakyFileName = needsMerge ? "flaky-$i.json" : "flaky.json";
          var flakyTests =
              await loadResultsMap("${outDirectory.path}/$flakyFileName");
          if (needsConfigurationOverride) {
            overrideConfiguration(
                flakyTests, namedConfigurations.single, localConfiguration);
          }
          mergedFlaky.addAll(flakyTests);
        }
      }
    }
    // Write out the merged results for the builders.
    if (needsMerge || needsConfigurationOverride) {
      await File("${outDirectory.path}/previous.json").writeAsString(
          mergedResults.values.map((data) => jsonEncode(data) + "\n").join(""));
    }
    // Ensure that there is a flaky.json even if it wasn't downloaded.
    if (needsMerge ||
        needsConfigurationOverride ||
        options["report-flakes"] as bool) {
      await File("${outDirectory.path}/flaky.json").writeAsString(
          mergedFlaky.values.map((data) => jsonEncode(data) + "\n").join(""));
    }
    // Deflake results of the tests if required.
    if (options["deflake"] as bool) {
      await deflake(outDirectory, configurationsToRun, options.rest);
    }
    // Write out the final comparison.
    print("".padLeft(80, "="));
    print("Test Results");
    print("".padLeft(80, "="));
    var compareOutput = await runProcess(Platform.resolvedExecutable, [
      "tools/bots/compare_results.dart",
      "--human",
      "--verbose",
      "--changed",
      "--failing",
      "--passing",
      "--flakiness-data=${outDirectory.path}/flaky.json",
      "--logs=${outDirectory.path}/logs.json",
      "${outDirectory.path}/previous.json",
      "${outDirectory.path}/results.json",
    ]);
    if (compareOutput.stdout == "") {
      print("There were no test failures.");
    } else {
      stdout.write(compareOutput.stdout);
    }
    if (inexactBuilds.isNotEmpty) {
      print("");
      var builders = inexactBuilds.keys.toList()..sort();
      for (var builder in builders) {
        var inexactCommit = inexactBuilds[builder];
        print("Warning: Results may be inexact because commit $inexactCommit "
            "was used as the baseline for $builder instead of $commit");
      }
    }
  } finally {
    await outDirectory.delete(recursive: true);
  }
}

Future<void> deflake(Directory outDirectory, List<String> configurations,
    List<String> testPyArgs) async {
  // Find the list of tests to deflake.
  var deflakeListOutput = await runProcess(Platform.resolvedExecutable, [
    "tools/bots/compare_results.dart",
    "--changed",
    "--failing",
    "--passing",
    "--flakiness-data=${outDirectory.path}/flaky.json",
    "${outDirectory.path}/previous.json",
    "${outDirectory.path}/results.json",
  ]);
  var deflakeListPath = "${outDirectory.path}/deflake.list";
  var deflakeListFile = File(deflakeListPath);
  await deflakeListFile.writeAsString(deflakeListOutput.stdout as String);

  // Deflake the changed tests.
  var deflakingResultsPaths = <String>[];
  for (var i = 1; deflakeListOutput.stdout != "" && i <= deflakingCount; i++) {
    print("".padLeft(80, "="));
    print("Running deflaking iteration $i");
    print("".padLeft(80, "="));
    var deflakeDirectory = Directory("${outDirectory.path}/$i");
    await deflakeDirectory.create();
    var deflakeArguments = [
      "--named-configuration=${configurations.join(",")}",
      "--output-directory=${deflakeDirectory.path}",
      "--clean-exit",
      "--silent-failures",
      "--write-results",
      "--test-list=$deflakeListPath",
      ...testPyArgs,
    ];

    await runProcessInheritStdio(
        "python", ["tools/test.py", ...deflakeArguments],
        runInShell: Platform.isWindows);
    deflakingResultsPaths.add("${deflakeDirectory.path}/results.json");
  }

  // Update the flakiness information based on what we've learned.
  print("Updating flakiness information...");
  await runProcess(Platform.resolvedExecutable, [
    "tools/bots/update_flakiness.dart",
    "--input=${outDirectory.path}/flaky.json",
    "--output=${outDirectory.path}/flaky.json",
    "${outDirectory.path}/results.json",
    ...deflakingResultsPaths,
  ]);
}
