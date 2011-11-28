// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.backend.js.analysis;

import junit.extensions.TestSetup;
import junit.framework.Test;
import junit.framework.TestSuite;


public class JsAnalysisTests extends TestSetup {

  public JsAnalysisTests(TestSuite test) {
    super(test);
  }

  public static Test suite() {
    TestSuite suite = new TestSuite("Dart Javascript analysis test suite.");

    suite.addTestSuite(TopLevelElementIndexerTest.class);
    suite.addTestSuite(DependencyComputerTest.class);
    
    return new JsAnalysisTests(suite);
  }
}
