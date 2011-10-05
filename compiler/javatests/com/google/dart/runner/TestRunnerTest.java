// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.runner;

import junit.framework.TestCase;

import java.io.ByteArrayOutputStream;
import java.io.PrintStream;

public class TestRunnerTest extends TestCase {
  public void testMain() throws Throwable {
    try {
      PrintStream stream = new PrintStream(new ByteArrayOutputStream());
      TestRunner.throwingMain("NoSuchFile.dart".split(" "), stream, stream);
      fail("Expected a compilation failure.");
    } catch (RunnerError e) {
      // Expected this exception.
    }
  }
}
