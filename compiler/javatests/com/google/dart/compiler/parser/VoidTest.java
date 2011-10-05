// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.parser;

import com.google.dart.compiler.CompilerTestCase;

/**
 * Tests for void-as-a-keyword.  This could be extended to be a general keyword test.  
 */
public class VoidTest extends CompilerTestCase {
  private void assertHasErrorsEquals(boolean expected, String code) {
    DartParserRunner runner = DartParserRunner.parse(getName(), code);
    assertEquals(expected, runner.hasErrors());
  }
  
  private void assertHasErrorsIsFalse(String code) {
    assertHasErrorsEquals(false, code);
  }
  
  private void assertHasErrorsIsTrue(String code) {
    assertHasErrorsEquals(true, code);
  }
  
  public void testExtendVoid() {
    assertHasErrorsIsTrue("class A extends void { }");
  }

  public void testImplementsVoid() {
    assertHasErrorsIsTrue("class A implements void { }");
  }

  public void testVoidClass() {
    assertHasErrorsIsTrue("class void { }");
    assertHasErrorsIsTrue("class void<T> { }");
  }

  public void testVoidFactory() {
    assertHasErrorsIsTrue("interface A factory void { }");
  }
  
  public void testVoidFieldType() {
    assertHasErrorsIsTrue("class A { void x; }");
  }  
  
  public void testVoidFunctionAlias() {
    assertHasErrorsIsFalse("typedef void a();");
  }
  
  public void testVoidFunctionParamName() {
    assertHasErrorsIsTrue("class A { int x( int void ) {} }");
  }
  
  public void testVoidFunctionParamType() {
    assertHasErrorsIsFalse("class A { int x( void y() ) {} }");
  }
  
  public void testVoidFunctionLiteral() {
    assertHasErrorsIsTrue("class A { int x() { function void(){} } }");
  }
  
  public void testVoidLocalVar() {
    assertHasErrorsIsTrue("class A { void x() { void y; } }");
  }
  
  public void testVoidLocalVarName() {
    assertHasErrorsIsTrue("class A { void x() { int void; } }");
  }

  public void testVoidMethodName() {
    assertHasErrorsIsTrue("class A { int void() {} }");
  }

  public void testVoidParamType() {
    assertHasErrorsIsTrue("class A { int x( void y ) {} }");
  }
  
  public void testVoidTypeParameter() {
    assertHasErrorsIsTrue("class a<void> { }");
  }
}
