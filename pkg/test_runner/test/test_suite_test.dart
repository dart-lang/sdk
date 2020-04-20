// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'package:expect/expect.dart';

import 'package:test_runner/src/test_file.dart';

import 'utils.dart';

void main() {
  testNnbdRequirements();
}

void testNnbdRequirements() {
  // Note: The backslashes are to avoid the test_runner thinking these are
  // Requirements markers for this file itself.
  var testFiles = [
    parseTestFile("", path: "none_test.dart"),
    parseTestFile("/\/ Requirements=nnbd", path: "nnbd_test.dart"),
    parseTestFile("/\/ Requirements=nnbd-legacy", path: "legacy_test.dart"),
    parseTestFile("/\/ Requirements=nnbd-weak", path: "weak_test.dart"),
    parseTestFile("/\/ Requirements=nnbd-strong", path: "strong_test.dart"),
  ];

  expectTestCases(
      [], testFiles, ["language_2/none_test", "language_2/legacy_test"]);

  expectTestCases(["--nnbd=legacy"], testFiles,
      ["language_2/none_test", "language_2/legacy_test"]);

  expectTestCases(["--nnbd=weak"], testFiles,
      ["language_2/none_test", "language_2/nnbd_test", "language_2/weak_test"]);

  expectTestCases(
      ["--nnbd=strong"],
      testFiles,
      [
        "language_2/none_test",
        "language_2/nnbd_test",
        "language_2/strong_test"
      ]);
}

void expectTestCases(List<String> options, List<TestFile> testFiles,
    List<String> expectedCaseNames) {
  var configuration = makeConfiguration(options);
  var suite = makeTestSuite(configuration, testFiles);

  var testCaseNames = <String>[];
  suite.findTestCases((testCase) {
    testCaseNames.add(testCase.displayName);
  }, {});

  Expect.listEquals(expectedCaseNames, testCaseNames);
}
