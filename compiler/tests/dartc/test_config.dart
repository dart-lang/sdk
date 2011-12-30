// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library("junit_dartc_test_config");

#import("../../../tools/testing/dart/test_suite.dart");

class JUnitDartcTestSuite extends JUnitTestSuite {
  JUnitDartcTestSuite(Map configuration)
      : super(configuration,
              'dartc/junit_tests',
              'compiler/javatests/com/google/dart',
              'compiler/tests/dartc/dartc.status');
}
