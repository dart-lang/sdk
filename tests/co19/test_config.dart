// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library("co19_test_config");

#import("dart:io");
#import("../../tools/testing/dart/test_suite.dart");

class Co19TestSuite extends StandardTestSuite {
  RegExp _testRegExp = const RegExp(@"t[0-9]{2}.dart$");

  Co19TestSuite(Map configuration)
      : super(configuration,
              "co19",
              "tests/co19/src",
              ["tests/co19/co19-compiler.status",
               "tests/co19/co19-runtime.status",
               "tests/co19/co19-frog.status"]);

  // A Dart checkout may omit the check out of the co19 tests.
  void forEachTest(Function onTest, Map testCache, String globalTempDir(),
                   [Function onDone = null]) {
    Directory testDirectory =
        new Directory(TestUtils.dartDir() + '/tests/co19/src');
    if (testDirectory.existsSync()) {
      super.forEachTest(onTest, testCache, globalTempDir, onDone);
    } else {
      if (onDone != null) onDone();
    }
  }
 
  bool isTestFile(String filename) => _testRegExp.hasMatch(filename);
  bool listRecursively() => true;
  bool complexStatusMatching() => true;
}
