// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library("corelib_test_config");

#import("../../tools/testing/dart/test_suite.dart");

class CorelibTestSuite extends StandardTestSuite {
  CorelibTestSuite(Map configuration)
      : super(configuration,
              "corelib",
              "tests/corelib/src",
              ["tests/corelib/corelib.status"]);
}
