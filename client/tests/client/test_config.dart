// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library("client_test_config");

#import("../../../tools/testing/dart/test_suite.dart");

class ClientTestSuite extends StandardTestSuite {
  ClientTestSuite(Map configuration)
      : super(configuration,
              "client",
              "client/tests/client",
              ["client/tests/client/client.status",
               "client/tests/client/client-leg.status"]);

  bool isTestFile(String filename) => filename.endsWith("_test.dart") ||
      filename.endsWith("Test.dart");

  bool listRecursively() => true;
}
