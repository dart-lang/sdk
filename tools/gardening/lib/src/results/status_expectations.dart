// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:async';
import 'package:gardening/src/results/configuration_environment.dart';
import 'package:gardening/src/results/status_files.dart';

import 'result_models.dart';
import 'testpy_wrapper.dart';
import 'util.dart';
import 'package:status_file/expectation.dart';

/// Finds the expectation for each test found in the [testResult] results and
/// outputs if the test succeeded or failed.
Future<List<TestExpectationResult>> getTestResultsWithExpectation(
    TestResult testResult) async {
  // Build expectations from configurations. Each configuration may test
  // multiple test suites.
  Map<String, ConfigurationEnvironment> configurationEnvironments = {};
  Map<String, Map<String, StatusFiles>> statusFilesMaps = {};
  await Future.wait(testResult.configurations.keys.map((key) async {
    Configuration configuration = testResult.configurations[key];
    configurationEnvironments[key] =
        new ConfigurationEnvironment(configuration);
    var statusFilePathsMap = await statusFileListerMap(configuration);
    statusFilesMaps[key] = {};
    statusFilePathsMap.keys.forEach((suite) {
      var statusFilePaths = statusFilePathsMap[suite].map((file) {
        return "${PathHelper.sdkRepositoryRoot()}/$file";
      }).where((sf) {
        return new File(sf).existsSync();
      }).toList();
      statusFilesMaps[key][suite] = StatusFiles.read(statusFilePaths);
    });
  }));

  List<TestExpectationResult> expectationResults = [];
  testResult.results.forEach((result) {
    try {
      ConfigurationEnvironment environment =
          configurationEnvironments[result.configuration];
      var testSuite = getSuiteNameForTest(result.name);
      StatusFiles expectationSuite =
          statusFilesMaps[result.configuration][testSuite];
      var qualifiedName = getQualifiedNameForTest(result.name);
      var statusFileEntries = expectationSuite.sectionsWithTestForConfiguration(
          environment, qualifiedName);
      expectationResults.add(new TestExpectationResult(statusFileEntries,
          result, testResult.configurations[result.configuration]));
    } catch (ex, st) {
      print(ex);
      print(st);
    }
  });

  return expectationResults;
}

/// [TestExpectationResult] contains information about the result of running a
/// test, along with the expectation.
class TestExpectationResult {
  final List<StatusSectionEntry> entries;
  final Result result;
  final Configuration configuration;

  TestExpectationResult(this.entries, this.result, this.configuration);

  bool _isSuccess;

  /// Gets all expectations from status file entries as a set.
  Set<Expectation> expectations() {
    Set<Expectation> expectationsFromEntries = entries
        .map((expectation) => expectation.entry.expectations)
        .expand((expectation) => expectation)
        .toSet();
    if (expectationsFromEntries.isEmpty) {
      expectationsFromEntries.add(Expectation.pass);
    }
    return expectationsFromEntries;
  }

  /// Determines if a result matches its expectation.
  bool isSuccess() {
    if (_isSuccess != null) {
      return _isSuccess;
    }
    Expectation outcome = Expectation.find(result.result);
    Set<Expectation> testExpectations = _getTestExpectations();
    Set<Expectation> expectationSet = expectations();
    _isSuccess = testExpectations.contains(outcome) ||
        expectationSet.contains(Expectation.skip) ||
        expectationSet.contains(Expectation.skipByDesign) ||
        expectationSet.any((expectation) {
          return outcome.canBeOutcomeOf(expectation);
        });
    return _isSuccess;
  }

  Set<Expectation> _getTestExpectations() {
    if (result.testExpectations == null) {
      return new Set<Expectation>();
    }
    return result.testExpectations.map((exp) {
      if (exp == "static-type-warning") {
        return Expectation.staticWarning;
      } else if (exp == "runtime-error") {
        return Expectation.runtimeError;
      } else if (exp == "compile-time-error") {
        return Expectation.compileTimeError;
      }
      return null;
    }).toSet();
  }
}
