// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';
import 'package:args/command_runner.dart';
import 'package:args/args.dart';
import 'package:gardening/src/results/status_expectations.dart';
import 'package:gardening/src/results/test_result.dart' as testResult;
import 'package:gardening/src/util.dart';
import 'package:gardening/src/console_table.dart';
import 'package:gardening/src/results/result_models.dart' as models;
import 'package:gardening/src/try.dart';
import 'package:gardening/src/results/util.dart';
import 'package:gardening/src/logdog_new.dart';
import 'package:gardening/src/logdog_rpc.dart';

/// Build standard arguments for input.
void buildArgs(ArgParser argParser) {
  argParser.addFlag('scripting',
      defaultsTo: false,
      abbr: 's',
      negatable: false,
      help: "Use flag to remove templated output.");
  argParser.addFlag('builder',
      defaultsTo: false,
      abbr: 'b',
      negatable: false,
      help: "Indicates that the argument is a builder name.");
  argParser.addFlag('builder-group',
      defaultsTo: false,
      abbr: 'g',
      negatable: false,
      help: "Indicates that the argument is a builder-group.");
  argParser.addFlag('cq',
      defaultsTo: false,
      negatable: false,
      help: "Indicates that the argument is a name for a try-bot.");
}

/// Get output table based on arguments passed in [argResults].
OutputTable getOutputTable(ArgResults argResults) {
  if (argResults["scripting"]) {
    return new ScriptTable();
  }
  return new ConsoleTable();
}

/// Utility method to get a single test-result no matter what has been passed in
/// as arguments. The test-result can either be from a builder-group, a single
/// build on a builder or from a log.
Future<Try<models.TestResult>> getTestResult(ArgResults argResults) {
  var logger = createLogger();
  var cache = createCacheFunction(logger);
  if (argResults["builder-group"]) {
    return testResult.getLatestTestResultForBuilderGroup(
        argResults.rest[0], logger, cache);
  } else if (argResults["builder"]) {
    // Check if there is a build number.
    String project = argResults["cq"] ? CQ_PROJECT : BUILDER_PROJECT;
    if (argResults.rest.length > 1) {
      var buildNumber = int.parse(argResults.rest[1]);
      return testResult.getTestResultForBuilder(
          project, argResults.rest[0], buildNumber, logger, cache);
    } else {
      return testResult.getLatestTestResultForBuilder(
          project, argResults.rest[0], logger, cache);
    }
  } else {
    return testResult.getTestResult(argResults.rest[0], logger, cache);
  }
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

/// [GetTestsWithResultCommand] answers to the sub-command 'get' and returns a
/// list of tests with their respective results.
class GetTestsWithResultCommand extends Command {
  @override
  String get description => "Get results for tests.";

  @override
  String get name => "tests";

  GetTestsWithResultCommand() {
    buildArgs(argParser);
  }

  Future run() async {
    if (argResults.rest.length == 0) {
      print("No result.log file given as argument.");
      return;
    }
    var testResult = await getTestResult(argResults);
    testResult.fold(exceptionPrint("Could not perform command."), (value) {
      var outputTable = getOutputTable(argResults)
        ..addHeader(new Column("Test", width: 60), (item) {
          return item.name;
        })
        ..addHeader(new Column("Result"), (item) {
          return item.result;
        });
      outputTable.print(value.results);
    });
  }
}

/// [GetTestsWithResultAndExpectationCommand] answers to the sub-command
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
    if (argResults.rest.length == 0) {
      print("No result.log file given as argument.");
      return;
    }
    var testResult = await getTestResult(argResults);
    (await testResult.bindAsync(getTestResultsWithExpectation))
        .fold(exceptionPrint("Could not perform command."), (value) {
      var outputTable = getOutputTable(argResults)
        ..addHeader(new Column("Test", width: 38), (item) {
          return item.name;
        })
        ..addHeader(new Column("Result", width: 18), (item) {
          return item.result;
        })
        ..addHeader(new Column("Expected"), (item) {
          return item.expectation.toString();
        })
        ..addHeader(new Column("Success", width: 4), (item) {
          return item.success ? "OK" : "FAIL";
        });
      outputTable.print(value);
    });
  }
}

/// [GetTestFailuresCommand] answers to 'failures' and returns only the failing
/// tests.
/// TODO(mkroghj): Negative tests are treated as errors.
class GetTestFailuresCommand extends Command {
  @override
  String get description => "Get failures of tests.";

  @override
  String get name => "failures";

  GetTestFailuresCommand() {
    buildArgs(argParser);
  }

  Future run() async {
    if (argResults.rest.length == 0) {
      print("No result.log file given as argument.");
      return;
    }
    var testResult = await getTestResult(argResults);
    (await testResult.bindAsync(getTestResultsWithExpectation))
        .fold(exceptionPrint("Could not perform command."), (value) {
      var outputTable = getOutputTable(argResults)
        ..addHeader(new Column("Test", width: 39), (item) {
          return item.name;
        })
        ..addHeader(new Column("Result", width: 18), (item) {
          return item.result;
        })
        ..addHeader(new Column("Expected"), (item) {
          return item.expectation.toString();
        });
      outputTable.print(value.where((x) => !x.success).toList());
    });
  }
}

/// [GetTestMatrix] answers to 'test-matrix' and returns all configurations for
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
    var buildNumbers = await getLatestBuilderNumbers(cache);
    var shardRegExp = new RegExp(r"(.*)-(\d)-(\d)-");
    var stepRegExp =
        new RegExp(r"read_results_of_(.*)\/0\/logs\/result\.log\/0");

    await buildNumbers.foldAsync(
        exceptionPrint(
            "Could not find builders and build numbers by querying logdog."),
        (buildNumbers) async {
      print(
          "builder;step;mode;arch;compiler;runtime;checked;strong;hostChecked;"
          "minified;csp;system;vmOptions;useSdk;builderTag;fastStartup;"
          "dart2JsWithKernel;enableAsserts;hotReload;"
          "hotReloadRollback;previewDart2;selectors");
      await Future.forEach(buildNumbers.keys, (builder) async {
        // Get steps for this builder and build number.
        var shardMatch = shardRegExp.firstMatch(builder);
        if (shardMatch != null && shardMatch.group(2) != "1") {
          // Shards run in the same configuration.
          return;
        }
        var logdog = new LogdogRpc();
        var buildNumber = buildNumbers[builder];
        var result = await logdog.query(
            BUILDER_PROJECT,
            "bb/client.dart/$builder/$buildNumber/+"
            "/recipes/steps/**/result.log/0",
            cache);
        if (result.isError) {
          print("Could not find any steps for $builder and $buildNumber.\n");
          return;
        }
        for (var stream in result.value) {
          var stepResult = await testResult.getTestResultFromLogdog(
              stream.path, logger, createCache);
          if (stepResult.isError) {
            print("Could not get test configuration from $builder.\n"
                "Tried getting the following log: ${stream.path}.");
            continue;
          }
          var configurations = stepResult.value.configurations;
          var configuration = configurations["conf1"];
          String builderName =
              shardMatch != null ? shardMatch.group(1) : builder;
          String step =
              stepRegExp.firstMatch(stream.path).group(1).replaceAll("_", " ");
          print("$builderName;$step;${configuration.toCsvString()}");
        }
      });
    });
  }
}
