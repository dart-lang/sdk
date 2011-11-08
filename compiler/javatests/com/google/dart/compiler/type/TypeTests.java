// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.type;

import junit.extensions.TestSetup;
import junit.framework.Test;
import junit.framework.TestSuite;

public class TypeTests extends TestSetup {

  public TypeTests(Test test) {
    super(test);
  }

  public static Test suite() {
    TestSuite suite = new TestSuite("Type system of dartc");

    suite.addTestSuite(TypeTest.class);
    suite.addTestSuite(FunctionTypeTest.class);
    suite.addTestSuite(TypeAnalyzerTest.class);
    suite.addTestSuite(TypeAnalyzerCompilerTest.class);

    return suite;
  }
}
