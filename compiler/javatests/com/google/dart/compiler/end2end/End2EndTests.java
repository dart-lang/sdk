// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.end2end;

import com.google.dart.compiler.end2end.inc.IncrementalCompilationTest;

import junit.extensions.TestSetup;
import junit.framework.Test;
import junit.framework.TestSuite;

public class End2EndTests extends TestSetup {

  public End2EndTests(TestSuite test) {
    super(test);
  }

  public static Test suite() {
    TestSuite suite = new TestSuite("Dart end-to-end test suite.");

    suite.addTestSuite(BasicTest.class);
    suite.addTestSuite(MainMethodTest.class);
    suite.addTestSuite(IncrementalCompilationTest.class);
    return new End2EndTests(suite);
  }
}
