// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library("lib_test_config");

#import("../../tools/testing/dart/test_suite.dart");

class LibTestSuite extends StandardTestSuite {
  LibTestSuite(Map configuration)
      : super(configuration,
              "lib",
              "tests/lib/src",
              ["tests/lib/lib.status"]);

  bool listRecursively() => true;
}
