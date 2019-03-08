#!/usr/bin/env dart
// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Run tests like on the given builder.

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';

import 'bots/results.dart';

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
  return new RegExp(r"^[a-zA-Z0-9%+,./:_-]*$").hasMatch(string)
      ? string
      : shellSingleQuote(string);
}

/// Runs a process and exits likewise if the process exits non-zero.
Future<ProcessResult> runProcess(String executable, List<String> arguments,
    {bool runInShell = false}) async {
  final processResult =
      await Process.run(executable, arguments, runInShell: runInShell);
  if (processResult.exitCode != 0) {
    final command =
        ([executable]..addAll(arguments)).map(simpleShellSingleQuote).join(" ");
    throw new Exception("Command exited ${processResult.exitCode}: $command\n"
        "${processResult.stdout}\n${processResult.stderr}");
  }
  return processResult;
}

/// Runs a process and exits likewise if the process exits non-zero, but let the
/// child process inherit out stdio handles.
Future<ProcessResult> runProcessInheritStdio(
    String executable, List<String> arguments,
    {bool runInShell = false}) async {
  final process = await Process.start(executable, arguments,
      mode: ProcessStartMode.inheritStdio, runInShell: runInShell);
  final exitCode = await process.exitCode;
  final processResult = new ProcessResult(process.pid, exitCode, "", "");
  if (processResult.exitCode != 0) {
    final command =
        ([executable]..addAll(arguments)).map(simpleShellSingleQuote).join(" ");
    throw new Exception("Command exited ${processResult.exitCode}: $command");
  }
  return processResult;
}

/// Returns the operating system of a builder.
String systemOfBuilder(String builder) {
  return builder.split("-").firstWhere(
      (component) => ["linux", "mac", "win"].contains(component),
      orElse: () => null);
}

/// Returns the product mode of a builder.
String modeOfBuilder(String builder) {
  return builder.split("-").firstWhere(
      (component) => ["debug", "product", "release"].contains(component),
      orElse: () => null);
}

/// Returns the machine architecture of a builder.
String archOfBuilder(String builder) {
  return builder.split("-").firstWhere(
      (component) => [
            "arm",
            "arm64",
            "armsimdbc",
            "armsimdbc64",
            "ia32",
            "simarm",
            "simarm64",
            "simdbc",
            "simdbc64",
            "x64",
          ].contains(component),
      orElse: () => null);
}

/// Returns the runtime environment of a builder.
String runtimeOfBuilder(String builder) {
  return builder.split("-").firstWhere(
      (component) => ["chrome", "d8", "edge", "firefox", "ie11", "safari"]
          .contains(component),
      orElse: () => null);
}

/// Expands a variable in a test matrix step command.
String expandVariable(String string, String variable, String value) {
  return string.replaceAll("\${$variable}", value ?? "");
}

/// Expands all variables in a test matrix step command.
String expandVariables(String string, String builder) {
  string = expandVariable(string, "system", systemOfBuilder(builder));
  string = expandVariable(string, "mode", modeOfBuilder(builder));
  string = expandVariable(string, "arch", archOfBuilder(builder));
  string = expandVariable(string, "runtime", runtimeOfBuilder(builder));
  return string;
}

/// Finds the branch of a builder given the list of branches.
String branchOfBuilder(String builder, List<String> branches) {
  return branches.where((branch) => branch != "master").firstWhere(
      (branch) => builder.endsWith("-$branch"),
      orElse: () => "master");
}

/// Finds the named configuration to test according to the test matrix
/// information and the command line options.
bool resolveNamedConfiguration(
    List<String> branches,
    List<dynamic> buildersConfigurations,
    String requestedBranch,
    String requestedNamedConfiguration,
    String requestedBuilder,
    Set<String> outputNamedConfiguration,
    Set<String> outputBuilders) {
  bool foundBuilder = false;
  for (final builderConfiguration in buildersConfigurations) {
    for (final builder in builderConfiguration["builders"]) {
      if (requestedBuilder != null && builder != requestedBuilder) {
        continue;
      }
      final branch = branchOfBuilder(builder, branches);
      if (branch != requestedBranch) {
        if (requestedBuilder == null) {
          continue;
        }
        stderr.writeln("error: Builder $requestedBuilder is on branch $branch "
            "rather than $requestedBranch");
        stderr.writeln("error: To compare with that branch, use: -B $branch");
        return false;
      }
      foundBuilder = true;
      final steps = (builderConfiguration["steps"] as List).cast<Map>();
      final testSteps = steps
          .where((step) =>
              !step.containsKey("script") || step["script"] == "tools/test.py")
          .toList();
      for (final step in testSteps) {
        final arguments = step["arguments"]
            .map((argument) => expandVariables(argument, builder))
            .toList();
        final namedConfiguration = arguments
            .firstWhere((argument) => (argument as String).startsWith("-n"))
            .substring(2);
        if (requestedNamedConfiguration == null ||
            requestedNamedConfiguration == namedConfiguration) {
          outputNamedConfiguration.add(namedConfiguration);
          outputBuilders.add(builder);
        }
      }
    }
  }
  if (requestedBuilder != null && !foundBuilder) {
    stderr.writeln("error: Builder $requestedBuilder doesn't exist");
    return false;
  }
  if (requestedBuilder != null &&
      requestedNamedConfiguration == null &&
      outputNamedConfiguration.isEmpty) {
    stderr.writeln("error: Builder $requestedBuilder isn't testing any named "
        "configurations");
    return false;
  }
  if (requestedBuilder != null &&
      requestedNamedConfiguration != null &&
      outputNamedConfiguration.isEmpty) {
    stderr.writeln("error: The builder $requestedBuilder isn't testing the "
        "named configuration $requestedNamedConfiguration");
    return false;
  }
  if (requestedNamedConfiguration != null && outputNamedConfiguration.isEmpty) {
    stderr.writeln("error: The named configuration "
        "$requestedNamedConfiguration doesn't exist");
    return false;
  }
  if (requestedNamedConfiguration != null && outputBuilders.isEmpty) {
    stderr.writeln("error: The named configuration "
        "$requestedNamedConfiguration isn't tested on any builders");
    return false;
  }
  return true;
}

/// Locates the merge base between head and the [branch] on the given [remote].
/// If a particular [commit] was requested, use that.
Future<String> findMergeBase(
    String commit, String remote, String branch) async {
  if (commit != null) {
    return commit;
  }
  final arguments = ["merge-base", "$remote/$branch", "HEAD"];
  final result =
      await Process.run("git", arguments, runInShell: Platform.isWindows);
  if (result.exitCode != 0) {
    throw new Exception("Failed to run: git ${arguments.join(' ')}\n"
        "stdout:\n${result.stdout}\n"
        "stderr:\n${result.stderr}\n");
  }
  return LineSplitter.split(result.stdout).first;
}

/// Locates the build number of the [commit] on the [builder], or throws an
/// exception if the builder hasn't built the commit.
Future<int> buildNumberOfCommit(String builder, String commit) async {
  final requestUrl = Uri.parse(
      "https://cr-buildbucket.appspot.com/_ah/api/buildbucket/v1/search"
      "?bucket=luci.dart.ci.sandbox"
      "&tag=builder%3A$builder"
      "&tag=buildset%3Acommit%2Fgit%2F$commit"
      "&fields=builds(status%2Ctags%2Curl)");
  final client = new HttpClient();
  final request = await client.getUrl(requestUrl);
  final response = await request.close();
  final Map<String, dynamic> object = await response
      .transform(new Utf8Decoder())
      .transform(new JsonDecoder())
      .first;
  client.close();
  final builds = object["builds"];
  if (builds == null || builds.isEmpty) {
    throw new Exception("Builder $builder hasn't built commit $commit");
  }
  final build = builds.last;
  final tags = (build["tags"] as List).cast<String>();
  final buildAddressTag =
      tags.firstWhere((tag) => tag.startsWith("build_address:"));
  final buildAddress = buildAddressTag.substring("build_address:".length);
  if (build["status"] != "COMPLETED") {
    throw new Exception("Build $buildAddress isn't completed yet");
  }
  return int.parse(buildAddress.split("/").last);
}

void main(List<String> args) async {
  final parser = new ArgParser();
  parser.addOption("builder",
      abbr: "b", help: "Run tests like on the given buider");
  parser.addOption("branch",
      abbr: "B",
      help: "Select the builders building this branch",
      defaultsTo: "master");
  parser.addOption("commit", abbr: "C", help: "Compare with this commit");
  parser.addOption("named-configuration",
      abbr: "n",
      help: "The named test configuration that supplies the\nvalues for all "
          "test options, specifying how tests\nshould be run.");
  parser.addOption("remote",
      abbr: "R",
      help: "Compare with this remote and git branch",
      defaultsTo: "origin");
  parser.addFlag("help", help: "Show the program usage.", negatable: false);

  final options = parser.parse(args);
  if (options["help"] ||
      (options["builder"] == null && options["named-configuration"] == null)) {
    print("""
Usage: test.dart -b [BUILDER] -n [CONFIGURATION] [OPTION]... [--]
                 [TEST.PY OPTION]... [SELECTOR]...

Run tests and compare with the results on the given builder. Either the -n or
the -b option, or both, must be used. Any options following -- and non-option
arguments will be forwarded to test.py invocations. The results for the specified
named configuration will be downloaded from the specified builder. If only a
named configuration is specified, the results are downloaded from the
appropriate builders. If only a builder is specified, the default named
configuration is used if the builder only has a single named configuration.
Otherwise the available named configurations are listed.

See the documentation at https://goto.google.com/dart-status-file-free-workflow

${parser.usage}""");
    return;
  }

  // Locate gsutil.py.
  gsutilPy =
      Platform.script.resolve("../third_party/gsutil/gsutil.py").toFilePath();

  // Load the test matrix.
  final scriptPath = Platform.script.toFilePath();
  final testMatrixPath =
      scriptPath.substring(0, scriptPath.length - "test.dart".length) +
          "bots/test_matrix.json";
  final testMatrix = jsonDecode(await new File(testMatrixPath).readAsString());
  final branches = (testMatrix["branches"] as List).cast<String>();
  final buildersConfigurations =
      testMatrix["builder_configurations"] as List<dynamic>;

  // Determine what named configuration to run and which builders to download
  // existing results from.
  final namedConfigurations = new SplayTreeSet<String>();
  final builders = new SplayTreeSet<String>();
  if (!resolveNamedConfiguration(
      branches,
      buildersConfigurations,
      options["branch"],
      options["named-configuration"],
      options["builder"],
      namedConfigurations,
      builders)) {
    exitCode = 1;
    return;
  }
  if (2 <= namedConfigurations.length) {
    final builder = builders.single;
    stderr.writeln(
        "error: The builder $builder is testing multiple named configurations");
    stderr.writeln(
        "error: Please select the desired named configuration using -n:");
    for (final namedConfiguration in namedConfigurations) {
      stderr.writeln("  -n $namedConfiguration");
    }
    exitCode = 1;
    return;
  }
  final namedConfiguration = namedConfigurations.single;
  for (final builder in builders) {
    print("Testing the named configuration $namedConfiguration "
        "compared with builder $builder");
  }

  // Find out where the current HEAD branched.
  final commit = await findMergeBase(
      options["commit"], options["remote"], options["branch"]);
  print("Base commit is $commit");

  // Store the downloaded results and our test results in a temporary directory.
  final outDirectory = await Directory.systemTemp.createTemp("test.dart.");
  try {
    final mergedResults = <String, Map<String, dynamic>>{};
    final mergedFlaky = <String, Map<String, dynamic>>{};

    // Use the buildbucket API to search for builds of the right commit.
    for (final builder in builders) {
      // Download the previous results and flakiness info from cloud storage.
      print("Finding build on builder $builder to compare with...");
      final buildNumber = await buildNumberOfCommit(builder, commit);
      print("Downloading results from builder $builder build $buildNumber...");
      await cpGsutil(
          buildFileCloudPath(builder, buildNumber.toString(), "results.json"),
          "${outDirectory.path}/previous.json");
      await cpGsutil(
          buildFileCloudPath(builder, buildNumber.toString(), "flaky.json"),
          "${outDirectory.path}/flaky.json");
      print("Downloaded baseline results from builder $builder");
      // Merge the results for the builders.
      if (2 <= builders.length) {
        mergedResults
            .addAll(await loadResultsMap("${outDirectory.path}/previous.json"));
        mergedFlaky
            .addAll(await loadResultsMap("${outDirectory.path}/flaky.json"));
      }
    }

    // Write out the merged results for the builders.
    if (2 <= builders.length) {
      print("Merging downloaded results from the builders...");
      await new File("${outDirectory.path}/previous.json").writeAsString(
          mergedResults.values.map((data) => jsonEncode(data) + "\n").join(""));
      await new File("${outDirectory.path}/flaky.json").writeAsString(
          mergedFlaky.values.map((data) => jsonEncode(data) + "\n").join(""));
    }

    // Run the tests.
    final arguments = [
      "--named-configuration=$namedConfiguration",
      "--output-directory=${outDirectory.path}",
      "--clean-exit",
      "--silent-failures",
      "--write-results",
      "--write-logs",
    ]..addAll(options.rest);
    print("".padLeft(80, "="));
    print("Running tests");
    print("".padLeft(80, "="));
    await runProcessInheritStdio("python", ["tools/test.py"]..addAll(arguments),
        runInShell: Platform.isWindows);

    // Find the list of tests to deflake.
    final deflakeListOutput = await runProcess(Platform.resolvedExecutable, [
      "tools/bots/compare_results.dart",
      "--changed",
      "--failing",
      "--passing",
      "--flakiness-data=${outDirectory.path}/flaky.json",
      "${outDirectory.path}/previous.json",
      "${outDirectory.path}/results.json",
    ]);
    final deflakeListPath = "${outDirectory.path}/deflake.list";
    final deflakeListFile = new File(deflakeListPath);
    await deflakeListFile.writeAsString(deflakeListOutput.stdout);

    // Deflake the changed tests.
    final deflakingResultsPaths = <String>[];
    for (int i = 1;
        deflakeListOutput.stdout != "" && i <= deflakingCount;
        i++) {
      print("".padLeft(80, "="));
      print("Running deflaking iteration $i");
      print("".padLeft(80, "="));
      final deflakeDirectory = new Directory("${outDirectory.path}/$i");
      await deflakeDirectory.create();
      final deflakeArguments = <String>[
        "--named-configuration=$namedConfiguration",
        "--output-directory=${deflakeDirectory.path}",
        "--clean-exit",
        "--silent-failures",
        "--write-results",
        "--test-list=$deflakeListPath",
      ]..addAll(options.rest);
      await runProcessInheritStdio(
          "python", ["tools/test.py"]..addAll(deflakeArguments),
          runInShell: Platform.isWindows);
      deflakingResultsPaths.add("${deflakeDirectory.path}/results.json");
    }

    // Update the flakiness information based on what we've learned.
    print("Updating flakiness information...");
    await runProcess(
        Platform.resolvedExecutable,
        [
          "tools/bots/update_flakiness.dart",
          "--input=${outDirectory.path}/flaky.json",
          "--output=${outDirectory.path}/flaky.json",
          "${outDirectory.path}/results.json",
        ]..addAll(deflakingResultsPaths));

    // Write out the final comparison.
    print("".padLeft(80, "="));
    print("Test Results");
    print("".padLeft(80, "="));
    final compareOutput = await runProcess(Platform.resolvedExecutable, [
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
  } finally {
    await outDirectory.delete(recursive: true);
  }
}
