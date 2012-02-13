// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library("stub_generator_test_config");

#import("../../tools/testing/dart/test_suite.dart");

class StubGeneratorTestSuite extends StandardTestSuite {
  StubGeneratorTestSuite(Map configuration)
      : super(configuration,
              "stub-generator",
              "tests/stub-generator/src",
              ["tests/stub-generator/stub-generator.status"]);

  bool isTestFile(String filename) => filename.endsWith("-generatedTest.dart");
}
