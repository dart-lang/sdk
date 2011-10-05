// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.parser;

import com.google.dart.compiler.CompilerTestCase;

/**
 * Negative Parser/Syntax tests.
 */
public class NegativeParserTest extends CompilerTestCase {

  private void parseExpectErrors(String code, int expectedErrorCount) {
    assertEquals(expectedErrorCount, DartParserRunner.parse(getName(), code).getErrorCount());
  }

  private void parseExpectErrors(String code) {
    assertTrue("expected errors.", DartParserRunner.parse(getName(), code).hasErrors());
  }

  public void testFieldInitializerInRedirectionConstructor1() {
    parseExpectErrors("class A { A(x) { } A.foo() : this(5), y = 5; var y; }");
  }

  public void testFieldInitializerInRedirectionConstructor2() {
    parseExpectErrors("class A { A(x) { } A.foo() : y = 5, this(5); var y; }");
  }

  public void testFieldInitializerInRedirectionConstructor3() {
    parseExpectErrors("class A { A(x) { } A.foo(this.y) : this(5); var y; }", 1);
  }

  public void testSuperInRedirectionConstructor1() {
    parseExpectErrors("class A { A(x) { } A.foo(this.y) : this(5), super(); var y; }");
  }

  public void testSuperInRedirectionConstructor2() {
    parseExpectErrors("class A { A(x) { } A.foo(this.y) : super(), this(5); var y; }", 1);
  }

  public void testMultipleRedirectionConstructors() {
    parseExpectErrors("class A { A(x) { } A.foo(this.y) : this(1), this(2); }", 1);
  }
}
