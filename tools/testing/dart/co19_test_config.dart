// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library co19_test_config;

import 'path.dart';
import 'test_suite.dart';

class Co19TestSuite extends StandardTestSuite {
  RegExp _testRegExp = new RegExp(r"t[0-9]{2}.dart$");

  Co19TestSuite(Map configuration)
      : super(configuration,
              "co19",
              new Path("tests/co19/src"),
              ["tests/co19/co19-co19.status",
               "tests/co19/co19-analyzer.status",
               "tests/co19/co19-analyzer2.status",
               "tests/co19/co19-runtime.status",
               "tests/co19/co19-dart2dart.status",
               "tests/co19/co19-dart2js.status",
               "tests/co19/co19-dartium.status"]);

  bool isTestFile(String filename) => _testRegExp.hasMatch(filename);
  bool get listRecursively => true;
}
