// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library("stub_generator_test_config");

#import("../../tools/testing/dart/test_suite.dart");

class StubGeneratorTestSuite extends StandardTestSuite {
  StubGeneratorTestSuite(Map configuration)
      : super(configuration,
              "tests/stub-generator/src",
              ["tests/stub-generator/stub-generator.status"]) {
    // TODO(ager): Support the stub generation part of this test on
    // dartc.
    if (configuration["component"] == "dartc") {
      print("Warning: stub-generator tests on dartc do not test generation");
    }
  }

  bool isTestFile(String filename) => filename.contains("-generatedTest.dart");
}
