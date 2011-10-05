// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Web-runner for JSON unit tests.
 */
class WebJsonTest extends UnitTestSuite {
  WebJsonTest() : super() {}

  void setUpTestSuite() {
    JsonTest.setUpTestSuite(this);
  }

  static void main() {
    new WebJsonTest().run();
  }

  // This operation is suitable for being invoked from a browser's console.
  static String runAllTests() {
    JsonTest.runAllTests();
    return 'Success!';
  }
}
