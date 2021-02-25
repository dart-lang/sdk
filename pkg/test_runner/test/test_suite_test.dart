// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'package:expect/expect.dart';

import 'package:test_runner/src/test_file.dart';

import 'utils.dart';

void main() {
  testNnbdRequirements();
  testVmOptions();
  testServiceTestVmOptions();
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
      [], testFiles, ["language/none_test", "language/legacy_test"]);

  expectTestCases(["--nnbd=legacy"], testFiles,
      ["language/none_test", "language/legacy_test"]);

  expectTestCases(["--nnbd=weak"], testFiles,
      ["language/none_test", "language/nnbd_test", "language/weak_test"]);

  expectTestCases(["--nnbd=strong"], testFiles,
      ["language/none_test", "language/nnbd_test", "language/strong_test"]);
}

void testVmOptions() {
  // Note: The backslashes are to avoid the test_runner thinking these are
  // Requirements markers for this file itself.
  var testFiles = [
    parseTestFile("", path: "vm_no_options_test.dart"),
    parseTestFile("/\/ VMOptions=--a", path: "vm_one_option_test.dart"),
    parseTestFile("/\/ VMOptions=--a --b\n/\/ VMOptions=--c",
        path: "vm_options_test.dart"),
  ];

  expectTestCases(
      [],
      testFiles,
      [
        "language/vm_no_options_test",
        "language/vm_one_option_test",
        "language/vm_options_test/0",
        "language/vm_options_test/1",
      ]);
}

void testServiceTestVmOptions() {
  // Note: The backslashes are to avoid the test_runner thinking these are
  // Requirements markers for this file itself.
  var testFiles = [
    parseTestFile("", path: "service_no_options_test.dart", suite: "service"),
    parseTestFile("/\/ VMOptions=--a",
        path: "service_one_option_test.dart", suite: "service"),
    parseTestFile("/\/ VMOptions=--a --b\n/\/ VMOptions=--c",
        path: "service_options_test.dart", suite: "service"),
  ];

  expectTestCases(
      [],
      testFiles,
      [
        "service/service_no_options_test/service",
        "service/service_no_options_test/dds",
        "service/service_one_option_test/service",
        "service/service_one_option_test/dds",
        "service/service_options_test/service_0",
        "service/service_options_test/service_1",
        "service/service_options_test/dds_0",
        "service/service_options_test/dds_1",
      ],
      suite: "service");
}

void expectTestCases(List<String> options, List<TestFile> testFiles,
    List<String> expectedCaseNames,
    {String suite = "language"}) {
  var configuration = makeConfiguration(options, suite);
  var testSuite = makeTestSuite(configuration, testFiles, suite);

  var testCaseNames = <String>[];
  testSuite.findTestCases((testCase) {
    testCaseNames.add(testCase.displayName);
  }, {});

  Expect.listEquals(expectedCaseNames, testCaseNames);
}
