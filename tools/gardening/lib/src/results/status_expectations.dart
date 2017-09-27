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
  await Future.forEach(testResult.configurations.keys, (key) async {
    var value = testResult.configurations[key];
    var statusFilesMap = await statusFileListerMap(value);
    expectationsMap[key] = {};
    await Future.forEach(statusFilesMap.keys, (suite) async {
      var statusFilesPaths = statusFilesMap[suite].where((sf) {
        return new File(sf).existsSync();
      }).toList();
      expectationsMap[key][suite] =
          await ExpectationSet.read(statusFilesPaths, value);
    });
  });
  List<TestExpectationResult> returnList = [];
  testResult.results.forEach((result) {
    try {
      var testSuite = getSuiteNameForTest(result.name);
      var qualifiedName = getQualifiedNameForTest(result.name);
      var expectationMap = expectationsMap[result.configuration];
      var expectationSuite = expectationMap[testSuite];
      var expectations = expectationSuite.expectations(qualifiedName);
      var outcome = Expectation.find(result.result);
      bool isSuccess = expectations.any((expectation) {
        return outcome.canBeOutcomeOf(expectation);
      });
      returnList.add(new TestExpectationResult(result.name, result.result,
          expectations.map((x) => x.toString()).toList(), isSuccess));
    } catch (ex, st) {
      print(ex);
      print(st);
    }
  });
  return returnList;
}

/// [TestExpectationResult] contains information about the result of running a
/// test, along with the expectation.
class TestExpectationResult {
  final String name;
  final String result;
  final List<String> expectation;
  final bool success;

  TestExpectationResult(this.name, this.result, this.expectation, this.success);
}
