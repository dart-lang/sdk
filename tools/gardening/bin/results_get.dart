// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';
import 'package:args/command_runner.dart';
import 'package:args/args.dart';
import 'package:gardening/src/luci.dart';
import 'package:gardening/src/luci_api.dart';
import 'package:gardening/src/results/status_expectations.dart';
import 'package:gardening/src/results/test_result_service.dart';
import 'package:gardening/src/util.dart';
import 'package:gardening/src/console_table.dart';
import 'package:gardening/src/results/result_models.dart' as models;
import 'package:gardening/src/results/util.dart';
import 'package:gardening/src/logdog_new.dart';
import 'package:gardening/src/logdog_rpc.dart';
import 'package:gardening/src/buildbucket.dart';
import 'package:gardening/src/extended_printer.dart';

/// Build standard arguments for input.
void buildArgs(ArgParser argParser) {
  argParser.addFlag('scripting',
      defaultsTo: false,
      abbr: 's',
      negatable: false,
      help: "Use flag to remove templated output.");
}

/// Get output table based on arguments passed in [argResults].
OutputTable getOutputTable(ArgResults argResults) {
  if (argResults["scripting"]) {
    return new ScriptTable();
  }
  return new ConsoleTable(template: rows);
}

/// Determine if arguments is a CQ url or commit-number + patchset.
bool isCqInput(ArgResults argResults) {
  if (argResults.rest.length == 1) {
    return isSwarmingTaskUrl(argResults.rest.first);
  }
  if (argResults.rest.length == 2) {
    return areNumbers(argResults.rest);
  }
  return false;
}

String howToUse = "Use by calling one of the following:\n\n"
    "\tget <command> <file>                     : where file is a local path.\n"
    "\tget <command> <uri_to_result_log>        : for direct links to result.logs.\n"
    "\tget <command> <uri_try_bot>              : for links to try bot builders.\n"
    "\tget <command> <commit_number> <patchset> : for links to try bot builders.\n"
    "\tget <command> <builder>                  : for a builder name.\n"
    "\tget <command> <builder> <build>          : for a builder and build number.\n"
    "\tget <command> <builder_group>            : for a builder group.\n";

/// Utility method to get a single test-result no matter what has been passed in
/// as arguments. The test-result can either be from a builder-group, a single
/// build on a builder or from a log.
Future<models.TestResult> getTestResult(ArgResults argResults) async {
  if (argResults.rest.length == 0) {
    print("No result.log file given as argument.");
    print(howToUse);
    return null;
  }

  var logger = createLogger();
  var cache = createCacheFunction(logger);
  var testResultService = new TestResultService(logger, cache);

  String firstArgument = argResults.rest.first;

  var luciApi = new LuciApi();
  bool isBuilderGroup = (await getBuilderGroups(luciApi, DART_CLIENT, cache()))
      .any((builder) => builder == firstArgument);
  bool isBuilder = (await getAllBuilders(luciApi, DART_CLIENT, cache()))
      .any((builder) => builder == firstArgument);

  if (argResults.rest.length == 1) {
    if (argResults.rest.first.startsWith("http")) {
      return testResultService.getTestResult(firstArgument);
    } else if (isBuilderGroup) {
      return testResultService.forBuilderGroup(firstArgument);
    } else if (isBuilder) {
      return testResultService.latestForBuilder(BUILDER_PROJECT, firstArgument);
    }
  }

  if (argResults.rest.length == 2 &&
      isBuilder &&
      isNumber(argResults.rest[1])) {
    var buildNumber = int.parse(argResults.rest[1]);
    return testResultService.forBuild(
        BUILDER_PROJECT, argResults.rest[0], buildNumber);
  }

  print("Too many arguments passed to command or arguments were incorrect.");
  print(howToUse);
  return null;
}

/// Utility method to get test results from the CQ.
Future<Iterable<BuildBucketTestResult>> getTestResultsFromCq(
    ArgResults argResults) async {
  if (argResults.rest.length == 0) {
    print("No result.log file given as argument.");
    print(howToUse);
    return null;
  }

  var logger = createLogger();
  var createCache = createCacheFunction(logger);
  var testResultService = new TestResultService(logger, createCache);

  String firstArgument = argResults.rest.first;

  if (argResults.rest.length == 1) {
    if (!isSwarmingTaskUrl(firstArgument)) {
      print("URI does not match "
          "`https://ci.chromium.org/swarming/task/<taskid>?server...`.");
      print(howToUse);
      return null;
    }
    String swarmingTaskId = getSwarmingTaskId(firstArgument);
    return await testResultService.getFromSwarmingTaskId(swarmingTaskId);
  }

  if (argResults.rest.length == 2 && areNumbers(argResults.rest)) {
    int changeNumber = int.parse(firstArgument);
    int patchset = int.parse(argResults.rest.last);
    return await testResultService.fromGerrit(changeNumber, patchset);
  }

  print("Too many arguments passed to command or arguments were incorrect.");
  print(howToUse);
  return null;
}

/// [GetCommand] handles when given command 'get' and expect a sub-command.
class GetCommand extends Command {
  @override
  String get description => "Get results for files and test-suites.";

  @override
  String get name => "get";

  GetCommand() {
    addSubcommand(new GetTestsWithResultCommand());
    addSubcommand(new GetTestsWithResultAndExpectationCommand());
    addSubcommand(new GetTestFailuresCommand());
    addSubcommand(new GetTestMatrix());
  }
}

/// [GetTestsWithResultCommand] handles when given the sub-command 'tests' and
/// returns a list of tests with their respective results.
class GetTestsWithResultCommand extends Command {
  @override
  String get description => "Get results for tests.";

  @override
  String get name => "tests";

  GetTestsWithResultCommand() {
    buildArgs(argParser);
  }

  Future run() async {
    models.TestResult testResults = await getTestResult(argResults);
    if (testResults == null) {
      return;
    }
    var outputTable = getOutputTable(argResults)
      ..addHeader(new Column("Test", width: 60), (item) {
        return item.name;
      })
      ..addHeader(new Column("Result"), (item) {
        return item.result;
      });
    outputTable.print(testResults.results);
  }
}

/// [GetTestsWithResultAndExpectationCommand] handles when given the sub-command
/// 'result' and returns a list of tests with their result and expectations.
class GetTestsWithResultAndExpectationCommand extends Command {
  @override
  String get description => "Get results and expectations for tests.";

  @override
  String get name => "results";

  GetTestsWithResultAndExpectationCommand() {
    buildArgs(argParser);
  }

  Future run() async {
    models.TestResult testResult = null;

    if (isCqInput(argResults)) {
      Iterable<BuildBucketTestResult> buildBucketTestResults =
          await getTestResultsFromCq(argResults);
      Iterable<models.TestResult> testResults =
          buildBucketTestResults.map((build) => build.testResult);
      testResult = new models.TestResult()..combineWith(testResults);
    } else {
      testResult = await getTestResult(argResults);
    }

    if (testResult == null) {
      return;
    }

    List<TestExpectationResult> withExpectations =
        await getTestResultsWithExpectation(testResult);

    var outputTable = getOutputTable(argResults)
      ..addHeader(new Column("Test", width: 38), (TestExpectationResult item) {
        return item.result.name;
      })
      ..addHeader(new Column("Result", width: 18), (item) {
        return item.result.result;
      })
      ..addHeader(new Column("Expected"), (item) {
        return item.expectations.toString();
      })
      ..addHeader(new Column("Success", width: 4), (item) {
        return item.isSuccess() ? "OK" : "FAIL";
      });
    outputTable.print(withExpectations);
  }
}

/// [GetTestFailuresCommand] handles when given the sub-command 'failures' and
/// returns only the failing tests.
class GetTestFailuresCommand extends Command {
  @override
  String get description => "Get failures of tests.";

  @override
  String get name => "failures";

  GetTestFailuresCommand() {
    buildArgs(argParser);
  }

  Future run() {
    if (isCqInput(argResults)) {
      return handleCqInput(argResults);
    } else {
      return handleBuildbotInput(argResults);
    }
  }

  Future handleCqInput(ArgResults argResults) async {
    Iterable<BuildBucketTestResult> buildBucketTestResults =
        await getTestResultsFromCq(argResults);

    if (buildBucketTestResults == null) {
      return;
    }

    print("All result logs fetched.");
    print("Calling test.py to find statuses for each test.");
    print("");

    for (var buildResult in buildBucketTestResults) {
      printBuild(buildResult.build);
      List<TestExpectationResult> results =
          await getTestResultsWithExpectation(buildResult.testResult);
      printFailingTestExpectationResults(results);
      print("");
    }
  }

  Future handleBuildbotInput(ArgResults argResults) async {
    models.TestResult testResult = await getTestResult(argResults);

    if (testResult == null) {
      return;
    }

    print("All result logs fetched.");
    var estimatedTime =
        new Duration(milliseconds: testResult.results.length * 100 ~/ 1000);
    print("Calling test.py to find status files for the configuration and "
        "the expectation for ${testResult.results.length} tests. "
        "Estimated time remaining is ${estimatedTime.inSeconds} seconds...");
    List<TestExpectationResult> withExpectations =
        await getTestResultsWithExpectation(testResult);
    printFailingTestExpectationResults(withExpectations);
    print("");
  }
}

/// [GetTestMatrix] responds to 'test-matrix' and returns all configurations for
/// a client.
class GetTestMatrix extends Command {
  @override
  String get description => "Gets all invokations of test.py for each builder "
      "and output the result in csv form.";

  @override
  String get name => "test-matrix";

  GetTestMatrix() {
    argParser.addFlag('scripting',
        defaultsTo: false, abbr: 's', negatable: false);
  }

  Future run() async {
    // We first get all the last builds for all the bots. That will give us the
    // name as well.
    var logger = createLogger();
    var createCache = createCacheFunction(logger);
    var cache = createCache(duration: new Duration(days: 1));
    var shardRegExp = new RegExp(r"(.*)-(\d)-(\d)-");
    var stepRegExp =
        new RegExp(r"read_results_of_(.*)\/0\/logs\/result\.log\/0");

    print("builder;step;mode;arch;compiler;runtime;checked;strong;hostChecked;"
        "minified;csp;system;vmOptions;useSdk;builderTag;fastStartup;"
        "dart2JsWithKernel;enableAsserts;hotReload;"
        "hotReloadRollback;previewDart2;selectors");

    var logdog = new LogdogRpc();
    var testResultService = new TestResultService(logger, createCache);

    return getLatestBuildNumbers(cache).then((buildNumbers) {
      // Get steps for this builder and build number.
      // Shards run in the same configuration.
      return buildNumbers.keys.where((builder) {
        var shardMatch = shardRegExp.firstMatch(builder);
        return shardMatch == null || shardMatch.group(2) == 1;
      }).map((builder) {
        int buildNumber = buildNumbers[builder];
        return logdog
            .query(
                BUILDER_PROJECT,
                "bb/client.dart/$builder/${buildNumber}/+"
                "/recipes/steps/**/result.log/0",
                cache)
            .then((builderStreams) {
          return Future.wait(builderStreams.map((stream) {
            return testResultService.fromLogdog(stream.path).then((testResult) {
              var configuration = testResult.configurations["conf1"];
              var shardMatch = shardRegExp.firstMatch(builder);
              String builderName =
                  shardMatch != null ? shardMatch.group(1) : builder;
              String step = stepRegExp
                  .firstMatch(stream.path)
                  .group(1)
                  .replaceAll("_", " ");
              print("$builderName;$step;${configuration.toCsvString()}");
            }).catchError(
                errorLogger(logger, "Could not get log from $stream", null));
          }));
        }).catchError(errorLogger(
                logger,
                "Could not download steps for $builder with "
                "build number $buildNumber",
                new List<LogdogStream>()));
      });
    }).then(Future.wait);
  }
}

/// Prints a test result.
void printFailingTestExpectationResults(List<TestExpectationResult> results) {
  List<TestExpectationResult> failing =
      results.where((x) => !x.isSuccess()).toList();
  failing.sort((a, b) => a.result.name.compareTo(b.result.name));
  int index = 0;
  failing.forEach((fail) => printFailingTest(fail, index++));
  if (index == 0) {
    print("\tNo failures found.");
  }
}

/// Prints a builder to stdout.
void printBuild(BuildBucketBuild build) {
  new ExtendedPrinter()
    ..println("${build.builder}")
    ..printLinePattern("=");
}

/// Prints a failing test to stdout.
void printFailingTest(TestExpectationResult result, int index) {
  var conf = result.configuration
      .toArgs(includeSelectors: false)
      .map((arg) => arg.replaceAll("--", ""));

  var extPrint = new ExtendedPrinter(preceeding: "\t");
  if (index > 0) {
    extPrint.printLinePattern("-");
  }
  extPrint
    ..println("FAILED: ${getQualifiedNameForTest(result.result.name)}")
    ..println("Result: ${result.result.result}")
    ..println("Expected: ${result.expectations}")
    ..println("Configuration: ${conf.join(', ')}")
    ..println("")
    ..println(
        "To run locally (if you have the right architecture and runtime):")
    ..println(getReproductionCommand(result.configuration, result.result.name));
}
