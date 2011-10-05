// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.corelib;

import junit.framework.Test;
import junit.framework.TestCase;
import junit.framework.TestSuite;

/**
 * Test the configuration of SharedTests but without running all the tests.
 * This test is designed to be run from test.py which normally skips SharedTests.
 */
public class TestSharedTests extends SharedTests {

  public TestSharedTests(Test test) {
    super(test);
  }

  public static TestSuite suite() {
    final TestSuite suite = new TestSuite("Shared Dart tests configuration");

    new SuiteBuilder() {
      @Override
      protected TestSuite configurationProblem(TestSuite ignored, String message) {
        return super.configurationProblem(suite, message);
      }
    }.buildSuite();

    if (suite.countTestCases() == 0) {
      suite.addTest(new TestCase("configuration is fine") {
        @Override
        public void runBare() throws Throwable {
        }
      });
    }
    return suite;
  }
}
