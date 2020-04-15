// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'configuration.dart';
import 'path.dart';
import 'test_suite.dart';

class Co19TestSuite extends StandardTestSuite {
  static final _testRegExp = RegExp(r"t[0-9]{2,3}.dart$");

  Co19TestSuite(TestConfiguration configuration, String selector)
      : super(configuration, selector, Path("tests/$selector/src"), [
          // These files also need to be listed in the filesets in
          // test_matrix.json so they will be copied to the bots running the
          // test shards.
          "tests/$selector/$selector-co19.status",
          "tests/$selector/$selector-analyzer.status",
          "tests/$selector/$selector-runtime.status",
          "tests/$selector/$selector-dart2js.status",
          "tests/$selector/$selector-dartdevc.status",
          "tests/$selector/$selector-kernel.status"
        ]);

  bool isTestFile(String filename) => _testRegExp.hasMatch(filename);
  bool get listRecursively => true;
}
