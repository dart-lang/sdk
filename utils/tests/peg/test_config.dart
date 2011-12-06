// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library("peg_test_config");

#import("../../../tools/testing/dart/test_suite.dart");

class PegTestSuite extends StandardTestSuite {
  PegTestSuite(Map configuration)
      : super(configuration,
              "peg",
              "utils/tests/peg/src",
              ["utils/tests/peg/peg.status"]);
}
