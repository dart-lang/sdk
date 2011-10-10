// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.runner;

import junit.framework.Test;
import junit.framework.TestSuite;

public class AllTests {
  public static Test suite() {
    TestSuite suite = new TestSuite("Dartc test runner tests");

    suite.addTestSuite(DartRunnerTest.class);

    return suite;
  }
}
