// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.vm;

import junit.framework.Test;
import junit.framework.TestSuite;
import junit.extensions.TestSetup;

/**
 * @author johnlenz@google.com (John Lenz)
 */
public class LibOptTests extends TestSetup {

  public LibOptTests(TestSuite test) {
    super(test);
  }

  public static Test suite() {
    TestSuite suite = new TestSuite(
        "Dart optimized imported library test suite.");

    suite.addTestSuite(ImportedLibOptTest.class);
    return new LibOptTests(suite);
  }
}
