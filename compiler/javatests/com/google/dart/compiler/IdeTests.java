// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler;

import junit.extensions.TestSetup;
import junit.framework.Test;
import junit.framework.TestSuite;

public class IdeTests extends TestSetup {

  public IdeTests(Test test) {
    super(test);
  }

  public static Test suite() {
    TestSuite suite = new TestSuite("IDE/dartc integration test suite.");
    suite.addTestSuite(IdeTest.class);
    suite.addTestSuite(DeltaAnalyzerTest.class);
    suite.addTestSuite(CodeCompletionParseTest.class);
    return suite;
  }
}
