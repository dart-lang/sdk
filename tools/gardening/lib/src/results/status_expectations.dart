// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:async';
import 'result_models.dart';
import 'testpy_wrapper.dart';
import 'expectation_set.dart';
import 'util.dart';
import 'package:status_file/expectation.dart';

/// Finds the expectation for each test found in the [testResult] results and
/// outputs if the test succeeded or failed.
Future<List<TestExpectationResult>> getTestResultsWithExpectation(
    TestResult testResult) async {
  // Build expectations from configurations. Each configuration may test
  // multiple test suites.
  Map<String, Map<String, ExpectationSet>> expectationsMap = {};
  await Future.wait(testResult.configurations.keys.map((key) async {
    var value = testResult.configurations[key];
    var statusFilesMap = await statusFileListerMap(value);
    expectationsMap[key] = {};
    await Future.wait(statusFilesMap.keys.map((suite) async {
      var statusFilePaths = statusFilesMap[suite].map((file) {
        return "${PathHelper.sdkRepositoryRoot()}/$file";
      }).where((sf) {
        return new File(sf).existsSync();
      }).toList();
      expectationsMap[key][suite] =
          await ExpectationSet.read(statusFilePaths, value);
    }));
  }));

  List<Future<TestExpectationResult>> futureList = [];
  testResult.results.forEach((result) {
    try {
      var testSuite = getSuiteNameForTest(result.name);
      var qualifiedName = getQualifiedNameForTest(result.name);
      var expectationMap = expectationsMap[result.configuration];
      var expectationSuite = expectationMap[testSuite];
      var expectations = expectationSuite.expectations(qualifiedName);
      futureList.add(new Future(() {
        return new TestExpectationResult(expectations, result,
            testResult.configurations[result.configuration]);
      }));
    } catch (ex, st) {
      print(ex);
      print(st);
    }
  });

  return Future.wait(futureList);
}

/// [TestExpectationResult] contains information about the result of running a
/// test, along with the expectation.
class TestExpectationResult {
  final Set<Expectation> expectations;
  final Result result;
  final Configuration configuration;

  TestExpectationResult(this.expectations, this.result, this.configuration);

  bool _isSuccess;

  /// Determines if a result matches its expectation.
  bool isSuccess() {
    if (_isSuccess != null) {
      return _isSuccess;
    }
    var outcome = Expectation.find(result.result);
    _isSuccess = _getTestExpectations().contains(outcome) ||
        expectations.any((expectation) {
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
