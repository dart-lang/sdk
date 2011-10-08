// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.end2end;

import junit.extensions.TestSetup;
import junit.framework.Test;
import junit.framework.TestSuite;

public class NonStrictResolutionTests extends TestSetup {

  public NonStrictResolutionTests(TestSuite test) {
    super(test);
  }

  public static Test suite() {
    TestSuite suite = new TestSuite("Dart Non-Strict Resolution end-to-end test suite.");
    suite.addTestSuite(NonStrictResolutionTest.class);
    return new NonStrictResolutionTests(suite);
  }
}
