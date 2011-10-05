// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.util;

import junit.extensions.TestSetup;
import junit.framework.Test;
import junit.framework.TestSuite;

public class UtilTests extends TestSetup {

  public UtilTests(Test test) {
    super(test);
  }

  public static Test suite() {
    TestSuite suite = new TestSuite("Utilities for dartc");

    suite.addTestSuite(PathsTest.class);

    return suite;
  }
}
