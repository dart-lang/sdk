// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'dart:convert' as json;
import 'dart:io';

import 'package:expect/expect.dart';
import 'package:compiler/src/js/js.dart';
import 'package:compiler/src/js/size_estimator.dart';
import 'debug_size_estimator.dart';

const String expressionsKey = 'expressions';
const String statementsKey = 'statements';
const String originalKey = 'original';
const String expectedKey = 'expected';
const String minifiedKey = 'minified';

DebugSizeEstimator debugSizeEstimator(Node node) {
  DebugSizeEstimator debugSizeEstimator = DebugSizeEstimator();
  debugSizeEstimator.visit(node);

  // Always verify the actual results from the [SizeEstimator].
  // This is the actual test, though DebugSizeEstimator is pretty trivial.
  int actualEstimate = estimateSize(node);
  Expect.equals(actualEstimate, debugSizeEstimator.charCount);
  return debugSizeEstimator;
}

abstract class TestSuite {
  String get key;
  Node parse(String testCase);

  String generateExpected(Node node) {
    return debugSizeEstimator(node).resultString;
  }

  String generateMinified(Node node) {
    return prettyPrint(node,
        enableMinification: true,
        preferSemicolonToNewlineInMinifiedOutput: true);
  }

  Map<String, String> goldenTestCase(goldenTestCaseJson) {
    String original = goldenTestCaseJson[originalKey];
    Node node = parse(original);
    return {
      originalKey: original,
      expectedKey: generateExpected(node),
      minifiedKey: generateMinified(node),
    };
  }

  List<Map<String, String>> regenerateGoldens(currentGoldensJson) {
    List<Map<String, String>> newGoldens = [];
    for (var testCaseJson in currentGoldensJson) {
      newGoldens.add(goldenTestCase(testCaseJson));
    }
    return newGoldens;
  }

  void verifyGoldens(goldensJson) {
    for (var goldenTestCase in goldensJson) {
      test(goldenTestCase[originalKey], goldenTestCase[expectedKey]);
    }
  }

  void test(String original, String expected) {
    var debugResults = debugSizeEstimator(parse(original));
    Expect.equals(expected, debugResults.resultString);
    Expect.equals(expected.length, debugResults.charCount);
  }
}

class ExpressionTestSuite extends TestSuite {
  @override
  String get key => expressionsKey;

  @override
  Node parse(String expression) => js(expression);
}

class StatementTestSuite extends TestSuite {
  @override
  String get key => statementsKey;

  @override
  Node parse(String statement) => js.statement(statement);
}

List<TestSuite> testSuites = [
  ExpressionTestSuite(),
  StatementTestSuite(),
];

void generateGoldens(currentGoldens,
    Map<String, List<Map<String, String>>> newGoldens, List<TestSuite> suites) {
  for (var suite in suites) {
    newGoldens[suite.key] = suite.regenerateGoldens(currentGoldens[suite.key]);
  }
}

void testGoldens(currentGoldens, List<TestSuite> suites) {
  for (var suite in suites) {
    suite.verifyGoldens(currentGoldens[suite.key]);
  }
}

void main(List<String> args) {
  var goldenFile = 'pkg/compiler/test/js/size_estimator_expectations.json';
  bool generate = args.contains('-g');
  var currentGoldens = json.jsonDecode(File(goldenFile).readAsStringSync());

  if (generate) {
    Map<String, List<Map<String, String>>> newGoldens = {};
    generateGoldens(currentGoldens, newGoldens, testSuites);

    File(goldenFile).writeAsStringSync(
        json.JsonEncoder.withIndent('  ').convert(newGoldens));
  } else {
    testGoldens(currentGoldens, testSuites);
  }
}
