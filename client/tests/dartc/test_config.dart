// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library("client_dartc_test_config");

#import("../../../tools/testing/dart/test_suite.dart");

class ClientDartcTestSuite extends DartcCompilationTestSuite {
  ClientDartcTestSuite(Map configuration)
      : super(configuration,
              "dartc",
              "client",
              ['async',
               'base',
               'box2d',
               'dom',
               'json',
               'observable',
               'samples',
               'streams',
               'testing',
               'tests',
               'touch',
               'util',
               'view',
               'weld'],
              ["client/tests/dartc/dartc.status"]);

  void isTestFile(String filename) {
    if (!filename.endsWith(".dart")) return false;
    var options = optionsFromFile(filename);
    return optionsFromFile(filename)["containsLeadingHash"];
  }

  void listRecursively() => true;
}
