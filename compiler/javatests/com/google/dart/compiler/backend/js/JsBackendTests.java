// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
package com.google.dart.compiler.backend.js;

import com.google.dart.compiler.backend.common.TypeHeuristicImplementationTest;

import junit.extensions.TestSetup;
import junit.framework.Test;
import junit.framework.TestSuite;

public class JsBackendTests extends TestSetup {
  public JsBackendTests(TestSuite test) {
    super(test);
  }

  public static Test suite() {
    TestSuite suite = new TestSuite("Dart Javascript backend test suite.");
    suite.addTestSuite(JavaScriptStringTest.class);
    //suite.addTestSuite(JsParserTest.class);
    //suite.addTestSuite(JsToStringGenerationVisitorAccuracyTest.class);
    //suite.addTestSuite(JsToStringGenerationVisitorConcisenessTest.class);
    suite.addTestSuite(ClosureJsCodingConventionTest.class);
    suite.addTestSuite(JsArrayExprOptTest.class);
    suite.addTestSuite(JsBinaryExprOptTest.class);
    suite.addTestSuite(JsClosureExprOptTest.class);
    suite.addTestSuite(JsCompoundBinaryExprOptTest.class);
    suite.addTestSuite(JsConstExprOptTest.class);
    suite.addTestSuite(JsConstructorOptTest.class);
    suite.addTestSuite(JsFieldAccessOptTest.class);
    suite.addTestSuite(JsScopeTest.class);
    suite.addTestSuite(JsUnaryExprOptTest.class);
    suite.addTestSuite(RttTest.class);
    suite.addTestSuite(TypeHeuristicImplementationTest.class);
    return new JsBackendTests(suite);
  }
}
