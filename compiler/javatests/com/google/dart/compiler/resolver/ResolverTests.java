// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.resolver;

import junit.extensions.TestSetup;
import junit.framework.Test;
import junit.framework.TestSuite;

/**
 * Tests of the resolver.
 */
public class ResolverTests extends TestSetup {

  public ResolverTests(Test test) {
    super(test);
  }

  public static Test suite() {
    TestSuite suite = new TestSuite("Dart Resolver test suite.");

    suite.addTestSuite(ResolverTest.class);
    suite.addTestSuite(ResolverCompilerTest.class);
    suite.addTestSuite(NegativeResolverTest.class);
    suite.addTestSuite(CompileTimeConstantTest.class);
    return suite;
  }
}
