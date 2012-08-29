// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler;

import junit.extensions.TestSetup;
import junit.framework.Test;
import junit.framework.TestSuite;

public class CompilerTests extends TestSetup {

  public CompilerTests(Test test) {
    super(test);
  }

  public static Test suite() {
    TestSuite suite = new TestSuite("DartC compiler test suite.");
    suite.addTestSuite(PackageLibraryManagerTest.class);
    suite.addTestSuite(PrettyErrorFormatterTest.class);
    suite.addTestSuite(SystemLibrariesReaderTest.class);
    return suite;
  }
}
