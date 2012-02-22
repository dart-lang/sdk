// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library("dartdoc_test_config");

#import("../../../tools/testing/dart/test_suite.dart");

class DartdocTestSuite extends StandardTestSuite {
  DartdocTestSuite(Map configuration)
      : super(configuration,
              "dartdoc",
              "utils/tests/dartdoc/src",
              ["utils/tests/dartdoc/dartdoc.status"]);

  List<String> additionalOptions(String filename) {
    if (configuration['component'].startsWith('frog')) {
      return ['--js_cmd=node --crankshaft'];
    } else {
      return [];
    }
  }


  bool isTestFile(String filename) => filename.endsWith("_tests.dart");
}
