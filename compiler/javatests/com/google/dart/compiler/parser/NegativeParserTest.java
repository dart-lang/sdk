// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
package com.google.dart.compiler.parser;

import static com.google.dart.compiler.common.ErrorExpectation.assertErrors;
import static com.google.dart.compiler.common.ErrorExpectation.errEx;

import com.google.common.base.Joiner;
import com.google.dart.compiler.CompilerTestCase;
import com.google.dart.compiler.ast.DartIdentifier;
import com.google.dart.compiler.ast.DartMethodDefinition;
import com.google.dart.compiler.ast.DartUnit;

/**
 * Negative Parser/Syntax tests.
 */
public class NegativeParserTest extends CompilerTestCase {
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

  public void test_defaultParameterValue_inInterfaceMethod() {
    parseExpectErrors(
        "interface A { f(int a, [int b = 12345]); }",
        errEx(ParserErrorCode.DEFAULT_VALUE_CAN_NOT_BE_SPECIFIED_IN_INTERFACE, 1, 33, 5));
  }

  public void test_defaultParameterValue_inAbstractMethod() {
    parseExpectErrors(
        "class A { abstract f(int a, [int b = 12345, int c]); }",
        errEx(ParserErrorCode.DEFAULT_VALUE_CAN_NOT_BE_SPECIFIED_IN_ABSTRACT, 1, 38, 5));
  }

  public void test_defaultParameterValue_inClosureTypedef() {
    parseExpectErrors(
        "typedef void f(int a, [int b = 12345, inc c]);",
        errEx(ParserErrorCode.DEFAULT_VALUE_CAN_NOT_BE_SPECIFIED_IN_TYPEDEF, 1, 32, 5));
  }

  public void test_defaultParameterValue_inClosure() {
    parseExpectErrors(
        "class A {void f(void cb(int a, [int b = 12345, int c])) {}}",
        errEx(ParserErrorCode.DEFAULT_VALUE_CAN_NOT_BE_SPECIFIED_IN_CLOSURE, 1, 41, 5));
  }

  public void test_namedParameterValue_inSetter() {
    parseExpectErrors(
        "class A { set f([int b]); }",
        errEx(ParserErrorCode.NAMED_PARAMETER_NOT_ALLOWED, 1, 18, 5));
  }

  public void test_namedParameterValue_inOperator() {
    parseExpectErrors(
        "class A { operator []=(int a, [int b]); }",
        errEx(ParserErrorCode.NAMED_PARAMETER_NOT_ALLOWED, 1, 32, 5));
  }

  /**
   * If keyword "extends" is mistyped in type parameters declaration, we should report about this
   * and then recover correctly.
   * <p>
   * http://code.google.com/p/dart/issues/detail?id=341
   */
  public void test_parseTypeParameter_expectedExtends_mistypedExtends() throws Exception {
    DartParserRunner parserRunner =
        parseSource(Joiner.on("\n").join(
            "class A {",
            "}",
            "class B<X ex> {",
            "}",
            "class C<X extneds A> {",
            "}",
            "class D<X extneds A, Y extends A> {",
            "}"));
    // check expected errors
    assertErrors(
        parserRunner.getErrors(),
        errEx(ParserErrorCode.EXPECTED_EXTENDS, 3, 11, 2),
        errEx(ParserErrorCode.EXPECTED_EXTENDS, 5, 11, 7),
        errEx(ParserErrorCode.EXPECTED_EXTENDS, 7, 11, 7));
    // check structure of AST
    DartUnit dartUnit = parserRunner.getDartUnit();
    String expected =
        Joiner.on("\n").join(
            "// unit " + getName(),
            "class A {",
            "}",
            "",
            "class B<X> {",
            "}",
            "",
            "class C<X extends A> {",
            "}",
            "",
            "class D<X extends A, Y extends A> {",
            "}");
    String actual = dartUnit.toDietSource().trim();
    if (!expected.equals(actual)) {
      System.err.println("Expected:\n" + expected);
      System.err.println("\nActual:\n" + actual);
    }
    assertEquals(expected, actual);
  }

  /**
   * Type parameters declaration is not finished, stop parsing and restart from next top level
   * element.
   * <p>
   * http://code.google.com/p/dart/issues/detail?id=341
   */
  public void test_parseTypeParameter_unfinishedTypeParameters() throws Exception {
    DartParserRunner parserRunner =
        parseSource(Joiner.on("\n").join(
            "class ClassWithLongEnoughName {",
            "}",
            "class B<X {",
            "}",
            "class C {",
            "}"));
    // check expected errors
    assertErrors(
        parserRunner.getErrors(),
        errEx(ParserErrorCode.EXPECTED_EXTENDS, 3, 11, 1),
        errEx(ParserErrorCode.SKIPPED_SOURCE, 3, 11, 3));
    // check structure of AST
    DartUnit dartUnit = parserRunner.getDartUnit();
    assertEquals(
        Joiner.on("\n").join(
            "// unit " + getName(),
            "class ClassWithLongEnoughName {",
            "}",
            "",
            "class C {",
            "}"),
        dartUnit.toDietSource().trim());
  }

  /**
   * Type parameters declaration is not finished, next top level element beginning encountered. May
   * be use just types new class declaration before existing one.
   * <p>
   * http://code.google.com/p/dart/issues/detail?id=341
   */
  public void test_parseTypeParameter_nextTopLevelInTheMiddle() throws Exception {
    DartParserRunner parserRunner =
        parseSource(Joiner.on("\n").join(
            "class ClassWithLongEnoughName {",
            "}",
            "class B<X",
            "class C {",
            "}"));
    // check expected errors
    assertErrors(parserRunner.getErrors(), errEx(ParserErrorCode.SKIPPED_SOURCE, 3, 9, 1));
    // check structure of AST
    DartUnit dartUnit = parserRunner.getDartUnit();
    assertEquals(
        Joiner.on("\n").join(
            "// unit " + getName(),
            "class ClassWithLongEnoughName {",
            "}",
            "",
            "class C {",
            "}"),
        dartUnit.toDietSource().trim());
  }

  /**
   * Function signatures require the name to be an identifier; especially true at the top level.
   * <p>
   * http://code.google.com/p/dart/issues/detail?id=839
   */
  public void testTopLevelFunctionNotIdentifier() {
    parseExpectErrors(
        "foo.baz() {}",
        errEx(ParserErrorCode.FUNCTION_NAME_EXPECTED_IDENTIFIER, 1, 1, 7));
  }

  public void testReservedWordClass() {
    parseExpectErrors(
        Joiner.on("\n").join(
            "class foo {}",
            "main() {",
            "  int class = 10;",
            "  print(\"class = $class\");",
            "}"),
        errEx(ParserErrorCode.EXPECTED_TOKEN, 3, 7, 5),
        errEx(ParserErrorCode.UNEXPECTED_TOKEN, 4, 19, 5));
  }

  public void testInvalidStringInterpolation() {
    parseExpectErrors(Joiner.on("\n").join(
        "void main() {",
        "  print(\"1 ${42} 2 ${} 3\");",
        "  print(\"1 ${42} 2 ${10;} 3\");",
        "  print(\"1 ${42} 2 ${10,20} 3\");",
        "  print(\"1 ${42} 2 ${10 20} 3\");",
        "  print(\"$\");",
        "  print(\"$",
        "}"),
        errEx(ParserErrorCode.UNEXPECTED_TOKEN, 2, 22, 1),
        errEx(ParserErrorCode.EXPECTED_TOKEN, 2, 23, 3),
        errEx(ParserErrorCode.EXPECTED_TOKEN, 3, 24, 1),
        errEx(ParserErrorCode.UNEXPECTED_TOKEN_IN_STRING_INTERPOLATION, 3, 25, 1),
        errEx(ParserErrorCode.EXPECTED_TOKEN, 4, 24, 1),
        errEx(ParserErrorCode.UNEXPECTED_TOKEN_IN_STRING_INTERPOLATION, 4, 25, 2),
        errEx(ParserErrorCode.UNEXPECTED_TOKEN_IN_STRING_INTERPOLATION, 4, 27, 1),
        errEx(ParserErrorCode.EXPECTED_TOKEN, 5, 25, 2),
        errEx(ParserErrorCode.UNEXPECTED_TOKEN_IN_STRING_INTERPOLATION, 5, 27, 1),
        errEx(ParserErrorCode.UNEXPECTED_TOKEN_IN_STRING_INTERPOLATION, 6, 11, 0),
        errEx(ParserErrorCode.UNEXPECTED_TOKEN_IN_STRING_INTERPOLATION, 7, 11, 0),
        errEx(ParserErrorCode.UNEXPECTED_TOKEN_IN_STRING_INTERPOLATION, 7, 11, 1),
        errEx(ParserErrorCode.UNEXPECTED_TOKEN_IN_STRING_INTERPOLATION, 8, 1, 1),
        errEx(ParserErrorCode.INCOMPLETE_STRING_LITERAL, 8, 1, 1),
        errEx(ParserErrorCode.EXPECTED_COMMA_OR_RIGHT_PAREN, 8, 2, 0));
  }

  public void testDeprecatedFactoryInInterface() {
    parseExpectWarnings(
        "interface foo factory bar {}",
        errEx(ParserErrorCode.DEPRECATED_USE_OF_FACTORY_KEYWORD, 1, 15, 7));
  }

  public void test_abstractTopLevel_class() {
    parseExpectErrors(Joiner.on("\n").join(
        "// filler filler filler filler filler filler filler filler filler filler",
        "abstract class A {",
        "}"));
  }

  public void test_abstractTopLevel_interface() {
    parseExpectErrors(
        Joiner.on("\n").join(
            "// filler filler filler filler filler filler filler filler filler filler",
            "abstract interface A {",
            "}"),
        errEx(ParserErrorCode.ABSTRACT_TOP_LEVEL_ELEMENT, 2, 1, 8));
  }

  public void test_abstractTopLevel_typedef() {
    parseExpectErrors(
        "abstract typedef void f();",
        errEx(ParserErrorCode.ABSTRACT_TOP_LEVEL_ELEMENT, 1, 1, 8));
  }

  public void test_abstractTopLevel_method() {
    parseExpectErrors(
        "abstract void foo() {}",
        errEx(ParserErrorCode.ABSTRACT_TOP_LEVEL_ELEMENT, 1, 1, 8));
  }

  public void test_abstractMethodWithBody() {
    parseExpectErrors(
        Joiner.on("\n").join(
            "// filler filler filler filler filler filler filler filler filler filler",
            "class A {",
            "  abstract foo() {",
            "  }",
            "}"),
        errEx(ParserErrorCode.ABSTRACT_METHOD_WITH_BODY, 3, 3, 8));
  }
}
