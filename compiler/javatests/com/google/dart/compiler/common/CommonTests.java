// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.common;

import junit.extensions.TestSetup;
import junit.framework.Test;
import junit.framework.TestSuite;

public class CommonTests extends TestSetup {

  public CommonTests(TestSuite test) {
    super(test);
  }

  public static Test suite() {
    TestSuite suite = new TestSuite("Dart common test suite.");

    suite.addTestSuite(GenerateSourceMapTest.class);
    suite.addTestSuite(LibrarySourceFileTest.class);
    suite.addTestSuite(NameTest.class);
    suite.addTestSuite(NameFactoryTest.class);
    return new CommonTests(suite);
  }
}
