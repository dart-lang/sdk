// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';
import 'package:args/command_runner.dart';
import 'package:args/args.dart';
import 'package:gardening/src/results/status_expectations.dart';
import 'package:gardening/src/results/status_files.dart';
import 'package:gardening/src/results/test_result_helper.dart';
import 'package:gardening/src/results/test_result_service.dart';
import 'package:gardening/src/util.dart';
import 'package:gardening/src/console_table.dart';
import 'package:gardening/src/results/result_json_models.dart' as models;
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

String howToUse(String command) {
  return "Use by calling one of the following:\n\n"
      "\tget $command <file>                     : for a local result.log file.\n"
      "\tget $command <uri_to_result_log>        : for direct links to result.logs.\n"
      "\tget $command <uri_try_bot>              : for links to try bot builders.\n"
      "\tget $command <commit_number> <patchset> : for links to try bot builders.\n"
      "\tget $command <builder>                  : for a builder name.\n"
      "\tget $command <builder> <build>          : for a builder and build number.\n"
      "\tget $command <builder_group>            : for a builder group.\n";
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
  }
}

/// [GetTestsWithResultCommand] handles when given the sub-command 'tests' and
/// returns a list of tests with their respective results.
class GetTestsWithResultCommand extends Command {
  @override
  String get description => "Get a list of tests with their respective "
      "results from result.logs found from input.";

  @override
  String get name => "tests";

  GetTestsWithResultCommand() {
    buildArgs(argParser);
  }

  Future run() async {
    models.TestResult testResults =
        await getTestResultFromBuilder(argResults.rest);
    if (testResults == null) {
      print(howToUse("tests"));
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
  String get description => "Get a list of tests with their respective "
      "results and expectations from result.logs found from input.";

  @override
  String get name => "tests-with-expectations";

  GetTestsWithResultAndExpectationCommand() {
    buildArgs(argParser);
  }

  Future run() async {
    models.TestResult testResult = null;

    if (isCqInput(argResults.rest)) {
      Iterable<BuildBucketTestResult> buildBucketTestResults =
          await getTestResultsFromCq(argResults.rest);
      if (buildBucketTestResults != null) {
        testResult = buildBucketTestResults.fold<models.TestResult>(
            new models.TestResult(),
            (combined, buildResult) => combined..combineWith([buildResult]));
      }
    } else {
      testResult = await getTestResultFromBuilder(argResults.rest);
    }

    if (testResult == null) {
      print(howToUse("results"));
      return;
    }

    var statusExpectations = new StatusExpectations(testResult);
    await statusExpectations.loadStatusFiles();
    List<TestExpectationResult> withExpectations =
        statusExpectations.getTestResultsWithExpectation();

    var outputTable = getOutputTable(argResults)
      ..addHeader(new Column("Test", width: 38), (item) {
        return item.result.name;
      })
      ..addHeader(new Column("Result", width: 18), (item) {
        return item.result.result;
      })
      ..addHeader(new Column("Expected"), (item) {
        return item.entries.toString();
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
  String get description => "Get a list of tests with their respective "
      "results and expectations from result.logs found from input.";

  @override
  String get name => "failures";

  GetTestFailuresCommand() {
    buildArgs(argParser);
  }

  Future run() async {
    List<models.TestResult> testResults = [];
    if (isCqInput(argResults.rest)) {
      var buildBucketResults = await getTestResultsFromCq(argResults.rest);
      if (buildBucketResults == null) {
        print(howToUse("failures"));
        return;
      }
      testResults.addAll(buildBucketResults);
    } else {
      var testResult = await getTestResultFromBuilder(argResults.rest);
      if (testResult == null) {
        print(howToUse("failures"));
        return;
      }
      testResults.add(testResult);
    }

    print("All result logs fetched.");
    print("Calling test.py to find statuses for each test.");
    print("");

    for (var testResult in testResults) {
      if (testResult is BuildBucketTestResult) {
        printBuild(testResult.build);
      }
      var statusExpectations = new StatusExpectations(testResult);
      await statusExpectations.loadStatusFiles();
      List<TestExpectationResult> results =
          statusExpectations.getTestResultsWithExpectation();
      printFailingTestExpectationResults(results);
      print("");
    }
  }
}

/// Prints a test result.
void printFailingTestExpectationResults(List<TestExpectationResult> results) {
  List<TestExpectationResult> failing =
      results.where((x) => !x.isSuccess()).toList();
  failing.sort((a, b) => a.result.name.compareTo(b.result.name));
  int index = 0;
  print("");
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

  var extPrint = new ExtendedPrinter();
  if (index > 0) {
    extPrint.printLinePattern("*");
    extPrint.println("");
  }
  extPrint
    ..println("FAILED: ${getQualifiedNameForTest(result.result.name)}")
    ..printLinePattern("-")
    ..println("Result: ${result.result.result}")
    ..println("Expected: ${result.expectations()}");
  printStatusEntries(result.entries, extPrint);
  extPrint
    ..println("Configuration: ${conf.join(', ')}")
    ..println("")
    ..println(
        "To run locally (if you have the right architecture and runtime):")
    ..println(getReproductionCommand(result.configuration, result.result.name))
    ..println("");
}

void printStatusEntries(
    List<StatusSectionEntry> entries, ExtendedPrinter printer) {
  var oldPreceding = printer.preceding;
  printer.preceding = "  ";
  for (StatusSectionEntry entry in entries) {
    printer.println("${entry.statusFile.path}");
    printer.println("  [ ${entry.section.condition} ]");
    printer.println("    line ${entry.entry.lineNumber}: ${entry.entry.path} : "
        "${entry.entry.expectations}");
  }
  printer.preceding = oldPreceding;
}
