// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library("import_mapper_test_config");

#import("../../../tools/testing/dart/test_suite.dart");

class ImportMapperTestSuite extends StandardTestSuite {
  ImportMapperTestSuite(Map configuration)
      : super(configuration,
              "import_mapper",
              "utils/tests/import_mapper/src",
              ["utils/tests/import_mapper/import_mapper.status"]);

  bool isTestFile(String filename) => filename.endsWith("_tests.dart");
}
