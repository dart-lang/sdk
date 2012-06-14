// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
package com.google.dart.compiler.parser;

import com.google.common.base.Joiner;
import com.google.dart.compiler.CompilerTestCase;
import com.google.dart.compiler.ast.DartClass;
import com.google.dart.compiler.ast.DartIdentifier;
import com.google.dart.compiler.ast.DartMethodDefinition;
import com.google.dart.compiler.ast.DartNode;
import com.google.dart.compiler.ast.DartUnit;

import static com.google.dart.compiler.common.ErrorExpectation.assertErrors;
import static com.google.dart.compiler.common.ErrorExpectation.errEx;

import java.util.List;
import java.util.Set;

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
    assertEquals("foo", ((DartIdentifier) factory.getName()).getName());
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
    String actual = dartUnit.toSource().trim();
    if (!expected.equals(actual)) {
      System.err.println("Expected:\n" + expected);
      System.err.println("\nActual:\n" + actual);
    }
    assertEquals(expected, actual);
  }

  /**
   * Type parameters declaration is not finished.
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
        errEx(ParserErrorCode.EXPECTED_TOKEN, 4, 1, 1),
        errEx(ParserErrorCode.EXPECTED_CLASS_DECLARATION_LBRACE, 5, 1, 5));
    // check structure of AST
    DartUnit dartUnit = parserRunner.getDartUnit();
    assertEquals(
        Joiner.on("\n").join(
            "// unit " + getName(),
            "class ClassWithLongEnoughName {",
            "}",
            "",
            "class B<X> {",
            "}",
            "",
            "class C {",
            "}"),
        dartUnit.toSource().trim());
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
    assertErrors(parserRunner.getErrors(),
        errEx(ParserErrorCode.EXPECTED_TOKEN, 4, 1, 5));

    // check structure of AST
    DartUnit dartUnit = parserRunner.getDartUnit();
    assertEquals(
        Joiner.on("\n").join(
            "// unit " + getName(),
            "class ClassWithLongEnoughName {",
            "}",
            "",
            "class B<X> {",
            "}",
            "",
            "class C {",
            "}"),
        dartUnit.toSource().trim());
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

  public void testInvalidStringInterpolation() {
    parseExpectErrors(
        Joiner.on("\n").join(
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

  public void test_useExtendsInTypedef() {
    parseExpectErrors(Joiner.on("\n").join(
        "// filler filler filler filler filler filler filler filler filler filler",
        "typedef ParameterizedFun1<T, U extends bool, V>(T t, U u);",
        ""));
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
        errEx(ParserErrorCode.ABSTRACT_METHOD_WITH_BODY, 3, 12, 3));
  }

  public void test_incompleteExpressionInInterpolation() {
    parseExpectErrors(
        "var s = 'fib(3) = ${fib(3}';",
        errEx(ParserErrorCode.EXPECTED_COMMA_OR_RIGHT_PAREN, 1, 26, 1));
  }

  public void test_interfaceMethodWithBody() {
    parseExpectErrors(
        Joiner.on("\n").join(
            "// filler filler filler filler filler filler filler filler filler filler",
            "interface A {",
            "  foo() {",
            "  }",
            "}"),
        errEx(ParserErrorCode.INTERFACE_METHOD_WITH_BODY, 3, 3, 3));
  }

  /**
   * The Language Specification in the section 6.1 states: "It is a compile-time error to preface a
   * function declaration with the built-in identifier static."
   */
  public void test_staticFunction_topLevel() {
    parseExpectErrors(
        Joiner.on("\n").join(
            "// filler filler filler filler filler filler filler filler filler filler",
            "static foo() {",
            "}"),
        errEx(ParserErrorCode.TOP_LEVEL_CANNOT_BE_STATIC, 2, 1, 6));
  }

  /**
   * The Language Specification in the section 6.1 states: "It is a compile-time error to preface a
   * function declaration with the built-in identifier static."
   */
  public void test_staticFunction_local() {
    DartParserRunner parserRunner =
        parseExpectErrors(
            Joiner.on("\n").join(
                "// filler filler filler filler filler filler filler filler filler filler",
                "topLevelMethodWithLongEnoughNameToForceWrapping() {",
                "  static int localFunction() {",
                "  }",
                "}"),
            errEx(ParserErrorCode.LOCAL_CANNOT_BE_STATIC, 3, 3, 6));
    // Check that "static" was ignored and "int" parsed as return type.
    assertEquals(
        makeCode(
            "// unit " + getName(),
            "",
            "topLevelMethodWithLongEnoughNameToForceWrapping() {",
            "  int localFunction() {",
            "  };",
            "}"),
        parserRunner.getDartUnit().toSource());
  }

  public void test_positionalArgument_afterNamed() {
    parseExpectErrors(
        Joiner.on("\n").join(
            "// filler filler filler filler filler filler filler filler filler filler",
            "f(r1, [n1, n2]) {}",
            "foo() {",
            "  f(-1, n1: 1, 2);",
            "}"),
        errEx(ParserErrorCode.POSITIONAL_AFTER_NAMED_ARGUMENT, 4, 16, 1));
  }

  public void test_unaryPlus() {
    parseExpectErrors(
        Joiner.on("\n").join(
            "// filler filler filler filler filler filler filler filler filler filler",
            "var a = 1;",
            "var b = -1;",
            "var c = +1;",
            "var d = -a;",
            "var e = +a;",
            "var f = + 1;",
            ""),
        errEx(ParserErrorCode.NO_UNARY_PLUS_OPERATOR, 6, 9, 1),
        errEx(ParserErrorCode.NO_SPACE_AFTER_PLUS, 7, 9, 1));
  }

  public void test_functionDeclaration_name() {
    parseExpectErrors(
        Joiner.on("\n").join(
            "// filler filler filler filler filler filler filler filler filler filler",
            "foo() {",
            "  f1(p){};", // function declaration as statement, has name
            "  (p){}", // function declaration as statement, should have name
            "  var f2 = (p){};", // variable declaration, name of function literal is not required
            "}",
            ""),
        errEx(ParserErrorCode.MISSING_FUNCTION_NAME, 4, 3, 5));
  }

  /**
   * Separate test for invocation of function literal which has both return type and name.
   */
  public void test_invokeFunctionLiteral_returnType_name() {
    DartParserRunner parserRunner =
        parseExpectErrors(Joiner.on("\n").join(
            "// filler filler filler filler filler filler filler filler filler filler",
            "topLevelFunctionWithVeryLongNameToForceLineWrapping() {",
            "  int f(p){}(0);", // invocation of function literal in statement, has type and name
            "}",
            ""));
    assertEquals(
        makeCode(
            "// unit " + getName(),
            "",
            "topLevelFunctionWithVeryLongNameToForceLineWrapping() {",
            "  int f(p) {",
            "  }(0);",
            "}"),
        parserRunner.getDartUnit().toSource());
  }

  /**
   * Test with variants of function declarations and function literal invocations.
   */
  public void test_functionDeclaration_functionLiteral() {
    DartParserRunner parserRunner =
        parseExpectErrors(Joiner.on("\n").join(
            "// filler filler filler filler filler filler filler filler filler filler",
            "foo() {",
            "  f0(p){}", // declaration of function as statement
            "  int f1(p){}", // declaration of function as statement, has type
            "  var res = (p){}(1);", // invocation of function literal in assignment
            "  (p){}(2);", // invocation of function literal in statement, no name
            "  f2(p){}(3);", // invocation of function literal in statement, has name
            "  f3(p) => 4;", // function with => arrow ends with ';'
            "  (5);", // this is separate statement, not invocation of previous function
            "  join(promises, (p) => 6);", // function with => arrow as argument
            "  join(promises, (p) {return 7;});", // function with block as argument
            "}",
            ""));
    assertEquals(
        makeCode(
            "// unit " + getName(),
            "",
            "foo() {",
            "  f0(p) {",
            "  };",
            "  int f1(p) {",
            "  };",
            "  var res = (p) {",
            "  }(1);",
            "  (p) {",
            "  }(2);",
            "  f2(p) {",
            "  }(3);",
            "  f3(p) {",
            "    return 4;",
            "  };",
            "  (5);",
            "  join(promises, (p) {",
            "    return 6;",
            "  });",
            "  join(promises, (p) {",
            "    return 7;",
            "  });",
            "}"),
        parserRunner.getDartUnit().toSource());
  }

  /**
   * Test for {@link DartUnit#getTopDeclarationNames()}.
   */
  public void test_getTopDeclarationNames() throws Exception {
    DartParserRunner parserRunner =
        parseSource(Joiner.on("\n").join(
            "// filler filler filler filler filler filler filler filler filler filler",
            "class MyClass {}",
            "class MyInterface {}",
            "topLevelMethod() {}",
            "int get topLevelGetter() {return 0;}",
            "void set topLevelSetter(int v) {}",
            "typedef void MyTypeDef();",
            ""));
    DartUnit unit = parserRunner.getDartUnit();
    // Check top level declarations.
    Set<String> names = unit.getTopDeclarationNames();
    assertEquals(6, names.size());
    assertTrue(names.contains("MyClass"));
    assertTrue(names.contains("MyInterface"));
    assertTrue(names.contains("topLevelMethod"));
    assertTrue(names.contains("topLevelGetter"));
    assertTrue(names.contains("topLevelSetter"));
    assertTrue(names.contains("MyTypeDef"));
  }

  /**
   * Test for {@link DartUnit#getTopDeclarationNames()} and qualified top-level method name.
   * <p>
   * http://code.google.com/p/dart/issues/detail?id=1738
   */
  public void test_getTopDeclarationNames_badName() throws Exception {
    DartParserRunner parserRunner =
        parseSource(Joiner.on("\n").join(
            "// filler filler filler filler filler filler filler filler filler filler",
            "void my.method() {}",
            ""));
    DartUnit unit = parserRunner.getDartUnit();
    // We have top-level node...
    List<DartNode> topLevelNodes = unit.getTopLevelNodes();
    assertEquals(1, topLevelNodes.size());
    // ...but it has wrong name, so ignored.
    Set<String> names = unit.getTopDeclarationNames();
    assertEquals(0, names.size());
  }

  /**
   * Test for {@link DartUnit#getDeclarationNames()}.
   */
  public void test_getDeclarationNames() throws Exception {
    DartParserRunner parserRunner =
        parseSource(Joiner.on("\n").join(
            "// filler filler filler filler filler filler filler filler filler filler",
            "class MyClass<TypeVar> {",
            "  myMethod(int pA, int pB) {",
            "    int varA;",
            "    try {",
            "    } catch(var ex) {",
            "    }",
            "  }",
            "}",
            "topLevelMethod() {}",
            "int get topLevelGetter() {return 0;}",
            "void set topLevelSetter(int setterParam) {}",
            "typedef void MyTypeDef();",
            ""));
    DartUnit unit = parserRunner.getDartUnit();
    // Check all declarations.
    Set<String> names = unit.getDeclarationNames();
    assertEquals(12, names.size());
    assertTrue(names.contains("MyClass"));
    assertTrue(names.contains("TypeVar"));
    assertTrue(names.contains("myMethod"));
    assertTrue(names.contains("pA"));
    assertTrue(names.contains("pB"));
    assertTrue(names.contains("varA"));
    assertTrue(names.contains("ex"));
    assertTrue(names.contains("topLevelMethod"));
    assertTrue(names.contains("topLevelGetter"));
    assertTrue(names.contains("topLevelSetter"));
    assertTrue(names.contains("setterParam"));
    assertTrue(names.contains("MyTypeDef"));
  }

  /**
   * There was bug in diet parser, it did not understand new "arrow" syntax of function definition.
   */
  public void test_dietParser_functionArrow() {
    DartParserRunner parserRunner =
        DartParserRunner.parse(
            getName(),
            Joiner.on("\n").join(
                "class ClassWithVeryLongNameEnoughToForceLineWrapping {",
                "  foo() => return 0;",
                "}",
                ""),
            true);
    assertErrors(parserRunner.getErrors());
    assertEquals(
        Joiner.on("\n").join(
            "// unit " + getName(),
            "class ClassWithVeryLongNameEnoughToForceLineWrapping {",
            "",
            "  foo() {",
            "  }",
            "}"),
        parserRunner.getDartUnit().toSource().trim());
  }

  /**
   * "get" is valid name for method, it can cause warning, but not parsing failure.
   */
  public void test_methodNamed_get() {
    parseExpectErrors(Joiner.on("\n").join(
        "// filler filler filler filler filler filler filler filler filler filler",
        "class A {",
        "  void get() {}",
        "}",
        ""));
  }

  /**
   * "set" is valid name for method, it can cause warning, but not parsing failure.
   */
  public void test_methodNamed_set() {
    parseExpectErrors(Joiner.on("\n").join(
        "// filler filler filler filler filler filler filler filler filler filler",
        "class A {",
        "  void set() {}",
        "}",
        ""));
  }

  /**
   * "operator" is valid name for method, it can cause warning, but not parsing failure.
   */
  public void test_methodNamed_operator() {
    parseExpectErrors(Joiner.on("\n").join(
        "// filler filler filler filler filler filler filler filler filler filler",
        "class A {",
        "  void operator() {}",
        "}",
        ""));
  }

  /**
   * We can parse operator "call" declaration.
   */
  public void test_operator_call() {
    parseExpectErrors(Joiner.on("\n").join(
        "// filler filler filler filler filler filler filler filler filler filler",
        "class A {",
        "  operator call() {}",
        "}",
        ""));
  }
  
  /**
   * We can parse operator "equals" declaration.
   */
  public void test_operator_equals() {
    DartParserRunner runner = parseExpectErrors(Joiner.on("\n").join(
        "// filler filler filler filler filler filler filler filler filler filler",
        "class A {",
        "  operator equals(other) => false;",
        "}",
        ""));
    DartClass clazz = (DartClass) runner.getDartUnit().getTopLevelNodes().get(0);
    DartMethodDefinition method = (DartMethodDefinition) clazz.getMembers().get(0);
    assertTrue(method.getModifiers().isOperator());
  }

  /**
   * "native" can be specified only for classes.
   */
  public void test_native_inInterace() {
    parseExpectErrors(
        Joiner.on("\n").join(
            "// filler filler filler filler filler filler filler filler filler filler",
            "interface A native 'N' {",
            "}",
            ""),
        errEx(ParserErrorCode.NATIVE_ONLY_CLASS, 2, 13, 6));
  }

  /**
   * "native" can be specified only for classes without "extends".
   */
  public void test_native_classWithExtends() {
    parseExpectErrors(
        Joiner.on("\n").join(
            "// filler filler filler filler filler filler filler filler filler filler",
            "class A {",
            "}",
            "class B extends A native 'N' {",
            "}",
            ""),
        errEx(ParserErrorCode.NATIVE_ONLY_CORE_LIB, 4, 19, 6));
  }

  /**
   * "native" can be specified only in "corelib".
   */
  public void test_native_onlyCoreLib() {
    parseExpectErrors(
        Joiner.on("\n").join(
            "// filler filler filler filler filler filler filler filler filler filler",
            "class A native 'N' {",
            "}",
            ""),
        errEx(ParserErrorCode.NATIVE_ONLY_CORE_LIB, 2, 9, 6));
  }

  /**
   * "native" can be specified only in "corelib".
   */
  public void test_native_onlyCoreLib_factory() {
    parseExpectErrors(
        Joiner.on("\n").join(
            "// filler filler filler filler filler filler filler filler filler filler",
            "class A {",
            "  factory A() native;",
            "}",
            ""),
        errEx(ParserErrorCode.NATIVE_ONLY_CORE_LIB, 3, 15, 6));
  }

  /**
   * "native" can be specified only in "corelib".
   */
  public void test_native_onlyCoreLib_method() {
    parseExpectErrors(
        Joiner.on("\n").join(
            "// filler filler filler filler filler filler filler filler filler filler",
            "class A {",
            "  factory A() native;",
            "}",
            ""),
        errEx(ParserErrorCode.NATIVE_ONLY_CORE_LIB, 3, 15, 6));
  }

  /**
   * The spec in the section 10.28 says:
   * <p>
   * It is a compile-time error if a built-in identifier is used as the declared name of a class,
   * interface, type variable or type alias.
   * <p>
   * http://code.google.com/p/dart/issues/detail?id=3477
   */
  public void test_builtInIdentifier_asClassName() {
    parseExpectErrors(
        Joiner.on("\n").join(
            "// filler filler filler filler filler filler filler filler filler filler",
            "class abstract {}",
            "class assert {}",
            "class Dynamic {}",
            "class equals {}",
            "class factory {}",
            "class get {}",
            "class implements {}",
            "class interface {}",
            "class negate {}",
            "class operator {}",
            "class set {}",
            "class static {}",
            "class typedef {}",
            ""),
            errEx(ParserErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE_NAME, 2, 7, 8),
            errEx(ParserErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE_NAME, 3, 7, 6),
            errEx(ParserErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE_NAME, 4, 7, 7),
            errEx(ParserErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE_NAME, 5, 7, 6),
            errEx(ParserErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE_NAME, 6, 7, 7),
            errEx(ParserErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE_NAME, 7, 7, 3),
            errEx(ParserErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE_NAME, 8, 7, 10),
            errEx(ParserErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE_NAME, 9, 7, 9),
            errEx(ParserErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE_NAME, 10, 7, 6),
            errEx(ParserErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE_NAME, 11, 7, 8),
            errEx(ParserErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE_NAME, 12, 7, 3),
            errEx(ParserErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE_NAME, 13, 7, 6),
            errEx(ParserErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE_NAME, 14, 7, 7));
  }

  /**
   * The spec in the section 10.28 says:
   * <p>
   * It is a compile-time error if a built-in identifier is used as the declared name of a class,
   * interface, type variable or type alias.
   * <p>
   * http://code.google.com/p/dart/issues/detail?id=3477
   */
  public void test_builtInIdentifier_asInterfaceName() {
    parseExpectErrors(
        Joiner.on("\n").join(
            "// filler filler filler filler filler filler filler filler filler filler",
            "interface abstract {}",
            "interface assert {}",
            "interface Dynamic {}",
            "interface equals {}",
            "interface factory {}",
            "interface get {}",
            "interface implements {}",
            "interface interface {}",
            "interface negate {}",
            "interface operator {}",
            "interface set {}",
            "interface static {}",
            "interface typedef {}",
            ""),
        errEx(ParserErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE_NAME, 2, 11, 8),
        errEx(ParserErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE_NAME, 3, 11, 6),
        errEx(ParserErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE_NAME, 4, 11, 7),
        errEx(ParserErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE_NAME, 5, 11, 6),
        errEx(ParserErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE_NAME, 6, 11, 7),
        errEx(ParserErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE_NAME, 7, 11, 3),
        errEx(ParserErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE_NAME, 8, 11, 10),
        errEx(ParserErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE_NAME, 9, 11, 9),
        errEx(ParserErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE_NAME, 10, 11, 6),
        errEx(ParserErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE_NAME, 11, 11, 8),
        errEx(ParserErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE_NAME, 12, 11, 3),
        errEx(ParserErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE_NAME, 13, 11, 6),
        errEx(ParserErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE_NAME, 14, 11, 7));
  }

  /**
   * The spec in the section 10.28 says:
   * <p>
   * It is a compile-time error if a built-in identifier is used as the declared name of a class,
   * interface, type variable or type alias.
   * <p>
   * http://code.google.com/p/dart/issues/detail?id=3477
   */
  public void test_builtInIdentifier_asTypevariableName() {
    parseExpectErrors(
        Joiner.on("\n").join(
            "// filler filler filler filler filler filler filler filler filler filler",
            "class C01<abstract> {}",
            "class C02<assert> {}",
            "class C04<Dynamic> {}",
            "class C05<equals> {}",
            "class C06<factory> {}",
            "class C07<get> {}",
            "class C08<implements> {}",
            "class C09<interface> {}",
            "class C10<negate> {}",
            "class C11<operator> {}",
            "class C12<set> {}",
            "class C13<static> {}",
            "class C14<typedef> {}",
            ""),
        errEx(ParserErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE_VARIABLE_NAME, 2, 11, 8),
        errEx(ParserErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE_VARIABLE_NAME, 3, 11, 6),
        errEx(ParserErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE_VARIABLE_NAME, 4, 11, 7),
        errEx(ParserErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE_VARIABLE_NAME, 5, 11, 6),
        errEx(ParserErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE_VARIABLE_NAME, 6, 11, 7),
        errEx(ParserErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE_VARIABLE_NAME, 7, 11, 3),
        errEx(ParserErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE_VARIABLE_NAME, 8, 11, 10),
        errEx(ParserErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE_VARIABLE_NAME, 9, 11, 9),
        errEx(ParserErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE_VARIABLE_NAME, 10, 11, 6),
        errEx(ParserErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE_VARIABLE_NAME, 11, 11, 8),
        errEx(ParserErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE_VARIABLE_NAME, 12, 11, 3),
        errEx(ParserErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE_VARIABLE_NAME, 13, 11, 6),
        errEx(ParserErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE_VARIABLE_NAME, 14, 11, 7));
  }

  /**
   * The spec in the section 10.28 says:
   * <p>
   * It is a compile-time error if a built-in identifier is used as the declared name of a class,
   * interface, type variable or type alias.
   * <p>
   * http://code.google.com/p/dart/issues/detail?id=3477
   */
  public void test_builtInIdentifier_asTypedefName() {
    parseExpectErrors(
        Joiner.on("\n").join(
            "// filler filler filler filler filler filler filler filler filler filler",
            "typedef abstract();",
            "typedef assert();",
            "typedef Dynamic();",
            "typedef equals();",
            "typedef factory();",
            "typedef get();",
            "typedef implements();",
            "typedef interface();",
            "typedef negate();",
            "typedef operator();",
            "typedef set();",
            "typedef static();",
            "typedef typedef();",
            ""),
        errEx(ParserErrorCode.BUILT_IN_IDENTIFIER_AS_TYPEDEF_NAME, 2, 9, 8),
        errEx(ParserErrorCode.BUILT_IN_IDENTIFIER_AS_TYPEDEF_NAME, 3, 9, 6),
        errEx(ParserErrorCode.BUILT_IN_IDENTIFIER_AS_TYPEDEF_NAME, 4, 9, 7),
        errEx(ParserErrorCode.BUILT_IN_IDENTIFIER_AS_TYPEDEF_NAME, 5, 9, 6),
        errEx(ParserErrorCode.BUILT_IN_IDENTIFIER_AS_TYPEDEF_NAME, 6, 9, 7),
        errEx(ParserErrorCode.BUILT_IN_IDENTIFIER_AS_TYPEDEF_NAME, 7, 9, 3),
        errEx(ParserErrorCode.BUILT_IN_IDENTIFIER_AS_TYPEDEF_NAME, 8, 9, 10),
        errEx(ParserErrorCode.BUILT_IN_IDENTIFIER_AS_TYPEDEF_NAME, 9, 9, 9),
        errEx(ParserErrorCode.BUILT_IN_IDENTIFIER_AS_TYPEDEF_NAME, 10, 9, 6),
        errEx(ParserErrorCode.BUILT_IN_IDENTIFIER_AS_TYPEDEF_NAME, 11, 9, 8),
        errEx(ParserErrorCode.BUILT_IN_IDENTIFIER_AS_TYPEDEF_NAME, 12, 9, 3),
        errEx(ParserErrorCode.BUILT_IN_IDENTIFIER_AS_TYPEDEF_NAME, 13, 9, 6),
        errEx(ParserErrorCode.BUILT_IN_IDENTIFIER_AS_TYPEDEF_NAME, 14, 9, 7));
  }

  public void test_qualifiedType_inForIn() {
    parseExpectErrors(Joiner.on("\n").join(
        "// filler filler filler filler filler filler filler filler filler filler",
        "foo() {",
        "  for (pref.A a in elements) {",
        "  }",
        "}",
        ""));
  }
}
