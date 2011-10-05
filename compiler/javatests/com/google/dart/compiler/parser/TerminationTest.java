// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.parser;

import com.google.dart.compiler.CompilerTestCase;

public class TerminationTest extends CompilerTestCase {

  public void testNestedStatement() {
    assertTrue(DartParserRunner.parse("testNestedStatement",
      "class A { String foo foo; }").hasErrors());
  }

  public void testTypeParameterList() {
    assertTrue(DartParserRunner.parse("testTypeParameterList",
      "class A <X Y> { }").hasErrors());
  }

  public void testTypeParameterList2() {
    assertTrue(DartParserRunner.parse("testTypeParameterList2",
      "class A <X  ").hasErrors());
  }

  public void testVarDecl() {
    assertTrue(DartParserRunner.parse("testParseVarDecl",
      "class A  { int a b  ").hasErrors());
  }

  public void testInterfaceList() {
    assertTrue(DartParserRunner.parse("testInterfaceList",
      "class A implemented B C { } ").hasErrors());
  }

  public void testInvalidChainning() {
    assertTrue(DartParserRunner.parse("testInvalidChainning",
      "class A { f() { var a; if (a is A is A){}}}").hasErrors());
  }

  public void testTypeInitializerList() {
    assertTrue(DartParserRunner.parse("testTypeInitializerList",
      "class A { A() : x(1) y(1) {} } ").hasErrors());
  }

  public void testVarDeclInit() {
    assertTrue(DartParserRunner.parse("testVarDeclInit",
      "class A { a = 1, b = 2 c = 3; } ").hasErrors());
  }

  public void testStaticConstDeclList() {
    assertTrue(DartParserRunner.parse("testStaticConstDeclList",
      "class A { static const int a = 1, b = 2 c = 3 ; } ").hasErrors());
  }

  public void testExpressionList() {
    assertTrue(DartParserRunner.parse("testExpressionList",
      "class A { A() { for(i;;i++,i++ i++) { } } } ").hasErrors());
  }

  public void testExpressionList2() {
    assertTrue(DartParserRunner.parse("testExpressionList",
      "class A { A() { for(i;;i++,i++  class B {} ").hasErrors());
  }

  public void testArguments() {
    assertTrue(DartParserRunner.parse("testArguments",
      "class A { int foo() { var f = new A(1,2 3 ; } }").hasErrors());
  }

  public void testMapLiteral() {
    assertTrue(DartParserRunner.parse("testMapLiteral",
      "class A { int foo() { var f = {a: 1, b: 2  ; ").hasErrors());
  }

  public void testMapLiteral2() {
    assertTrue(DartParserRunner.parse("testMapLiteral2",
      "class A { int foo() { var f = {a: 1, b ").hasErrors());
  }

  public void testMapLiteral3() {
    assertTrue(DartParserRunner.parse("testMapLiteral3",
      "class A { int foo() { var f = {a: 1, b: 2 c:3 ; ").hasErrors());
  }

  public void testStringInterpolation() {
    assertTrue(DartParserRunner.parse("testStringInterpolation",
      "class A { int foo() { int a; s=\"x${a}   ${ \"  ").hasErrors());
  }

  public void testStringInterpolation2() {
    assertTrue(DartParserRunner.parse("testStringInterpolation2",
      "class A { int foo() { int a; s=\"x${a}  ").hasErrors());
  }

  public void testTryTypeSpecification() {
    assertTrue(DartParserRunner.parse("testTryTypeSpecification",
      "class A <a<b<c  { }  ").hasErrors());
  }

  public void testTryCatch() {
    assertTrue(DartParserRunner.parse("testTryCatch",
      "class A  { int foo() { try {} catch(int e) {} catch   ").hasErrors());
  }

  public void testSwitchCase() {
    assertTrue(DartParserRunner.parse("testSwitchCase",
      "class A  { int foo() { int a; switch(a) { case 1: break; case 2: break; ").hasErrors());
  }

  public void testInitVarList() {
    assertTrue(DartParserRunner.parse("testInitVarList",
      "class A  { int foo() { int a = 1, b = 2 , ").hasErrors());
  }

  public void testArrayInit() {
    assertTrue(DartParserRunner.parse("testArrayInit",
      "class A { foo(){ a = [1, 2      ").hasErrors());
  }

  public void testMalformedDietSource() {
    assertTrue(DartParserRunner.parse("testMalformedDietSource",
      "class A { foo() { { { } { } ", true).hasErrors());
  }
}
