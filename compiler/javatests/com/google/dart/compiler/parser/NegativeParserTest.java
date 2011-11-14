// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
package com.google.dart.compiler.parser;

import com.google.dart.compiler.CompilerTestCase;
import com.google.dart.compiler.DartCompilationError;
import com.google.dart.compiler.ast.DartIdentifier;
import com.google.dart.compiler.ast.DartMethodDefinition;
import com.google.dart.compiler.ast.DartUnit;

import java.util.List;

/**
 * Negative Parser/Syntax tests.
 */
public class NegativeParserTest extends CompilerTestCase {
  private void parseExpectErrors(String code, ErrorExpectation... expectedErrors) {
    List<DartCompilationError> errors = getParseErrors(code);
    assertErrors(errors, expectedErrors);
  }

  private List<DartCompilationError> getParseErrors(String code) {
    return DartParserRunner.parse(getName(), code, Integer.MAX_VALUE, false).getErrors();
  }

  public void testFieldInitializerInRedirectionConstructor1() {
    parseExpectErrors(
        "class A { A(x) { } A.foo() : this(5), y = 5; var y; }",
        errEx(ParserErrorCode.REDIRECTING_CONSTRUCTOR_OTHER, 1, 39, 5),
        errEx(ParserErrorCode.REDIRECTING_CONSTRUCTOR_ITSELF, 1, 30, 7));
  }

  public void testFieldInitializerInRedirectionConstructor2() {
    parseExpectErrors(
        "class A { A(x) { } A.foo() : y = 5, this(5); var y; }",
        errEx(ParserErrorCode.REDIRECTING_CONSTRUCTOR_OTHER, 1, 30, 5),
        errEx(ParserErrorCode.REDIRECTING_CONSTRUCTOR_ITSELF, 1, 37, 7));
  }

  public void testFieldInitializerInRedirectionConstructor3() {
    parseExpectErrors(
        "class A { A.foo(x) { } A() : y = 5, this.foo(5); var y; }",
        errEx(ParserErrorCode.REDIRECTING_CONSTRUCTOR_OTHER, 1, 30, 5),
        errEx(ParserErrorCode.REDIRECTING_CONSTRUCTOR_ITSELF, 1, 37, 11));
  }

  public void testFieldInitializerInRedirectionConstructor4() {
    parseExpectErrors(
        "class A { A(x) { } A.foo(this.y, this.z) : this(5); var y; var z;}",
        errEx(ParserErrorCode.REDIRECTING_CONSTRUCTOR_PARAM, 1, 26, 6),
        errEx(ParserErrorCode.REDIRECTING_CONSTRUCTOR_PARAM, 1, 34, 6),
        errEx(ParserErrorCode.REDIRECTING_CONSTRUCTOR_ITSELF, 1, 44, 7));
  }

  public void testFieldInitializerInRedirectionConstructor5() {
    parseExpectErrors(
        "class A { A(x) { } A.foo(this.y) : this(5), z = 7; var y; var z;}",
        errEx(ParserErrorCode.REDIRECTING_CONSTRUCTOR_PARAM, 1, 26, 6),
        errEx(ParserErrorCode.REDIRECTING_CONSTRUCTOR_OTHER, 1, 45, 5),
        errEx(ParserErrorCode.REDIRECTING_CONSTRUCTOR_ITSELF, 1, 36, 7));
  }

  public void testSuperInRedirectionConstructor1() {
    parseExpectErrors(
        "class A { A(x) { } A.foo() : this(5), super(); var y; }",
        errEx(ParserErrorCode.REDIRECTING_CONSTRUCTOR_OTHER, 1, 39, 7),
        errEx(ParserErrorCode.REDIRECTING_CONSTRUCTOR_ITSELF, 1, 30, 7));
  }

  public void testSuperInRedirectionConstructor2() {
    parseExpectErrors(
        "class A { A(x) { } A.foo() : super(), this(5); var y; }",
        errEx(ParserErrorCode.REDIRECTING_CONSTRUCTOR_OTHER, 1, 30, 7),
        errEx(ParserErrorCode.REDIRECTING_CONSTRUCTOR_ITSELF, 1, 39, 7));
  }

  public void testMultipleRedirectionConstructors() {
    parseExpectErrors(
        "class A { A(x) { } A.foo() : this(1), this(2); }",
        errEx(ParserErrorCode.REDIRECTING_CONSTRUCTOR_MULTIPLE, 1, 30, 7),
        errEx(ParserErrorCode.REDIRECTING_CONSTRUCTOR_MULTIPLE, 1, 39, 7));
  }

  public void testSuperMultipleInvocationsTest() {
    String source =
        makeCode(
            "class A {",
            "    int a;",
            "    A(this.a);",
            "    A.foo(int x, int y);",
            "}",
            "",
            "class B extends A {",
            "    int b1;",
            "    int b2;",
            "    B(int x) : this.b1 = x, super(x), this.b2 = x, super.foo(x, x);",
            "}");
    parseExpectErrors(
        source,
        errEx(ParserErrorCode.SUPER_CONSTRUCTOR_MULTIPLE, 10, 29, 8),
        errEx(ParserErrorCode.SUPER_CONSTRUCTOR_MULTIPLE, 10, 52, 15));
  }

  public void testIncompleteClassDeclaration_noLBrace() {
    String sourceCode =
        makeCode(
            "class Baz",
            "class Foo<T> implements Bar<T> {",
            "  Foo(T head, Bar<T> tail);",
            "}");
    DartUnit unit =
        parseSourceUnitErrors(
            sourceCode,
            ParserErrorCode.EXPECTED_CLASS_DECLARATION_LBRACE.getMessage(),
            2,
            1);
    // check structure of AST, top level Baz and Foo expected
    assertEquals(2, unit.getTopLevelNodes().size());
    assertEquals(
        makeCode(
            "// unit Test.dart",
            "class Baz {",
            "}",
            "",
            "class Foo<T> implements Bar<T> {",
            "",
            "  Foo(T head, Bar<T> tail) ;",
            "}",
            ""),
        unit.toSource());
  }

  /**
   * Language specification requires that factory should be declared in class. However declaring
   * factory on top level should not cause exceptions in compiler. To ensure this we parse top level
   * factory into normal {@link DartMethodDefinition}.
   * <p>
   * http://code.google.com/p/dart/issues/detail?id=345
   */
  public void test_badTopLevelFactory() {
    DartUnit unit =
        parseSourceUnitErrors(
            "factory foo() {}",
            ParserErrorCode.DISALLOWED_FACTORY_KEYWORD.getMessage(),
            1,
            1);
    DartMethodDefinition factory = (DartMethodDefinition) unit.getTopLevelNodes().get(0);
    assertNotNull(factory);
    // this factory has name, which is allowed for normal method
    assertEquals(true, factory.getName() instanceof DartIdentifier);
    assertEquals("foo", ((DartIdentifier) factory.getName()).getTargetName());
  }

  /**
   * Language specification requires that factory should be declared in class. However declaring
   * factory on top level should not cause exceptions in compiler. To ensure this we parse top level
   * factory into normal {@link DartMethodDefinition}.
   * <p>
   * http://code.google.com/p/dart/issues/detail?id=345
   */
  public void test_badTopLevelFactory_withTypeParameters() {
    DartUnit unit =
        parseSourceUnitErrors(
            "factory foo<T>() {}",
            ParserErrorCode.DISALLOWED_FACTORY_KEYWORD.getMessage(),
            1,
            1);
    DartMethodDefinition factory = (DartMethodDefinition) unit.getTopLevelNodes().get(0);
    assertNotNull(factory);
    // normal method requires name, so we provide some name
    assertEquals(true, factory.getName() instanceof DartIdentifier);
    assertEquals("foo<T>", ((DartIdentifier) factory.getName()).getTargetName());
  }
}
