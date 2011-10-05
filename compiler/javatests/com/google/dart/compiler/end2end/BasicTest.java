// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.end2end;

/**
 * Basic end-to-end tests, covering expressions, statements, and so forth.
 */
public class BasicTest extends End2EndTestCase {

  public void testNative() throws Exception {
    runTest("NativeTestLib.dart");
  }

  public void testRedirectedConstructors() throws Exception {
    runTest("RedirectedConstructorTest.dart");
  }
}
