// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library("css_test_config");

#import("../../../tools/testing/dart/test_suite.dart");

class CssTestSuite extends StandardTestSuite {
  CssTestSuite(Map configuration)
      : super(configuration,
              "css",
              "utils/tests/css/src",
              ["utils/tests/css/css.status"]);
}
