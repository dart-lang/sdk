// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:gardening/src/cache_new.dart';
import 'package:gardening/src/extended_printer.dart';
import 'package:gardening/src/logger.dart';
import 'package:gardening/src/luci.dart';
import 'package:gardening/src/luci_api.dart';
import 'package:gardening/src/results/configuration_environment.dart';
import 'package:gardening/src/results/result_models.dart' as models;
import 'package:gardening/src/results/status_files_wrapper.dart';
import 'package:gardening/src/results/test_result_service.dart';
import 'package:gardening/src/results/testpy_wrapper.dart';
import 'package:gardening/src/results/util.dart';
import 'package:gardening/src/util.dart';
import 'package:gardening/src/workflow/workflow.dart';

import 'results_status_workflow.dart';

/// Class [StatusCommand] handles the 'status' subcommand and provides
/// sub-commands for interacting with status files.
class StatusCommand extends Command {
  @override
  String get description => "Tools for checking and updating status files.";

  @override
  String get name => "status";

  StatusCommand() {
    addSubcommand(new CheckStatusCommand());
    addSubcommand(new UpdateStatusCommand());
  }
}

/// Class [CheckStatusCommand] checks a suite of status files for overlapping
/// sections.
class CheckStatusCommand extends Command {
  String usage = "Usage: check <suite> or check <suite> <test>";

  @override
  String get description => "Checks a suite of status files for duplicate "
      "entries. $usage";

  @override
  String get name => "check";

  CheckStatusCommand() {
    argParser.addFlag("print-test",
        negatable: false, help: "Print entries in status files for each test");
  }

  Future run() async {
    if (argResults.rest.length == 0 || argResults.rest.length > 2) {
      print("Incorrect number of arguments.\n$usage");
      return;
    }

    var suite = argResults.rest.first;
    bool specificTest = argResults.rest.length == 2;

    String testArg = specificTest ? "$suite/${argResults.rest.last}" : suite;

    Map<String, Iterable<String>> statusFilesMap =
        await statusFileListerMapFromArgs([testArg]);

    var statusFilePaths = statusFilesMap[suite].map((file) {
      return "${PathHelper.sdkRepositoryRoot()}/$file";
    }).where((sf) {
      return new File(sf).existsSync();
    }).toList();

    print("We need to download all latest configurations. "
        "This may take some time...");

    Logger logger = createLogger();
    CreateCacheFunction createCache = createCacheFunction(logger);
    WithCacheFunction dayCache = createCache(duration: new Duration(days: 1));

    var luciApi = new LuciApi();
    var primaryBuilders =
        await getPrimaryBuilders(luciApi, DART_CLIENT, dayCache);
    var testResultService = new TestResultService(logger, createCache);

    StatusFilesWrapper statusFilesWrapper =
        StatusFilesWrapper.read(statusFilePaths);

    var dtStart = new DateTime.now();
    List<models.TestResult> testResults =
        await waitWithThrottle(primaryBuilders, 50, (builder) {
      return testResultService.latestForBuilder(BUILDER_PROJECT, builder);
    });
    var dtEnd = new DateTime.now();
    print("DURATION: ${dtEnd.difference(dtStart).inMilliseconds}");

    var allResults = testResults.fold<models.TestResult>(
        new models.TestResult(),
        (sum, testResult) => sum..combineWith([testResult]));

    var activeConfigurations = await futureWhere(
        allResults.configurations.values, (configuration) async {
      // Check that this configuration is using the suite from arguments.
      var confStatusFiles = await statusFileListerMap(configuration);
      return statusFilesMap.keys
          .any((testSuite) => confStatusFiles.containsKey(testSuite));
    });

    if (!specificTest) {
      // Get all tests from test.py and check every one.
      var suiteTests = await testsForSuite(suite);
      _checkTests(
          activeConfigurations,
          suiteTests.map((test) => getQualifiedNameForTest(test)),
          statusFilesWrapper);
    } else {
      _checkTests(
          activeConfigurations, [argResults.rest.last], statusFilesWrapper);
    }
  }

  void _checkTests(Iterable<models.Configuration> configurations,
      Iterable<String> tests, StatusFilesWrapper wrapper) {
    int configurationLength = configurations.length;
    int configurationCounter = 1;
    var printer = new ExtendedPrinter();
    for (var configuration in configurations) {
      printer.preceding = "";
      var conf = configuration
          .toArgs(includeSelectors: false)
          .map((arg) => arg.replaceAll("--", ""));
      printer.println("");
      printer.printLinePattern("=");
      printer.println("Configuration $configurationCounter of "
          "$configurationLength: ${conf.join(', ')}");
      printer.printLinePattern("=");
      printer.println("");
      ConfigurationEnvironment environment =
          new ConfigurationEnvironment(configuration);
      Map<String, Iterable<StatusSectionEntryResult>> results = {};
      for (var test in tests) {
        Iterable<StatusSectionEntryResult> result =
            wrapper.sectionsWithTestForConfiguration(environment, test);
        if (result.length > 1) {
          results.putIfAbsent(test, () => result);
        }
      }
      if (results.length > 0) {
        if (argResults["print-test"]) {
          printOverlappingSectionsForTest(printer, results);
        } else {
          printOverlappingSectionsForTestsGrouped(printer, results);
        }
      } else {
        printer.println("No overlapping status sections.");
      }
      configurationCounter++;
    }
  }

  void printOverlappingSectionsForTest(ExtendedPrinter printer,
      Map<String, Iterable<StatusSectionEntryResult>> testSectionEntries) {
    for (var test in testSectionEntries.keys) {
      printer.println(test);
      printer.printLinePattern("*");
      printer.printIterable(testSectionEntries[test],
          (StatusSectionEntryResult entry) {
        return "${entry.section.lineNumber}: [ ${entry.section.condition} ] \n"
            "\t${entry.entry.lineNumber}: ${entry.entry.path}: ${entry.expectations}";
      }, header: (StatusSectionEntryResult entry) {
        return entry.statusFile.path;
      }, itemPreceding: "\t");
    }
  }

  void printOverlappingSectionsForTestsGrouped(ExtendedPrinter printer,
      Map<String, Iterable<StatusSectionEntryResult>> testSectionEntries) {
    Iterable<StatusSectionEntryResult> expandedResult =
        testSectionEntries.values.expand((id) => id);
    var allFiles = expandedResult.map((result) => result.statusFile).toSet();
    for (var file in allFiles) {
      printer.preceding = "";
      printer.println(file.path);
      var all = expandedResult.where((x) => x.statusFile == file).toList();
      all.sort((a, b) => a.entry.lineNumber.compareTo(b.entry.lineNumber));
      var sections = all.map((entry) => entry.section).toSet();
      for (var section in sections) {
        printer.preceding = "\t";
        printer.println("${section.lineNumber}: [ ${section.condition} ]");
        var entries = all
            .where((entry) => entry.section == section)
            .map((entry) => entry.entry)
            .toSet();
        printer.preceding = "\t\t";
        for (var entry in entries) {
          printer.println("${entry.lineNumber}: "
              "${entry.path}: "
              "${entry.expectations}");
        }
        printer.println("");
      }
    }
  }
}

/// Class [UpdateStatusCommand] handles the 'status update' subcommand and
/// updates status files.
class UpdateStatusCommand extends Command {
  @override
  String get description => "Update status files, from failure data and "
      "existing status entries.";

  @override
  String get name => "update";

  Future run() async {
    var workflow = new Workflow();
    return workflow.start(new AskForLogs());
  }
}
