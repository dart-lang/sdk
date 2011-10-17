// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.resolver;

import com.google.common.base.Joiner;
import com.google.dart.compiler.DartCompilerErrorCode;

/**
 * Tests the code in {@link CompileTimeConstantVisitor}
 */
public class CompileTimeConstantTest extends ResolverTestCase{

  // TODO(zundel) This test should pass, but the compiler doesn't currently
  // recursively resolve types in CompileTimeConstVisitor
  public void disabledTestForwardLookupExpressions() {
    resolveAndTest(Joiner.on("\n").join(
        "class Object {}",
        "class A {",
        "  static final value1 = value2 * 2;",
        "  static final value2 = value3 * 4;",
        "  static final value3 = 8;",
        "}"));
  }

  public void testConstantBinaryExpression() {
    resolveAndTest(Joiner.on("\n").join(
        "class Object {}",
        "class A {",
        " static final INT_LIT = 5;",
        " static final INT_LIT_REF = INT_LIT;",
        " static final DOUBLE_LIT = 1.5;",
        " static final BOOL_LIT = true;",
        " static final STRING_LIT = \"Hello\";",
        " static final BOP1_0 = INT_LIT + 1;",
        " static final BOP1_1 = 1 + INT_LIT;",
        " static final BOP1_2 = INT_LIT - 1;",
        " static final BOP1_3 = 1 - INT_LIT;",
        " static final BOP1_4 = INT_LIT * 1;",
        " static final BOP1_5 = 1 * INT_LIT;",
        " static final BOP1_6 = INT_LIT / 1;",
        " static final BOP1_7 = 1 / INT_LIT;",
        " static final BOP2_0 = DOUBLE_LIT + 1.5;",
        " static final BOP2_1 = 1.5 + DOUBLE_LIT;",
        " static final BOP2_2 = DOUBLE_LIT - 1.5;",
        " static final BOP2_3 = 1.5 - DOUBLE_LIT;",
        " static final BOP2_4 = DOUBLE_LIT * 1.5;",
        " static final BOP2_5 = 1.5 * DOUBLE_LIT;",
        " static final BOP2_6 = DOUBLE_LIT / 1.5;",
        " static final BOP2_7 = 1.5 / DOUBLE_LIT;",
        " static final BOP3_0 = 2 < INT_LIT;",
        " static final BOP3_1 = INT_LIT < 2;",
        " static final BOP3_2 = 2 > INT_LIT;",
        " static final BOP3_3 = INT_LIT > 2;",
        " static final BOP3_4 = 2 < DOUBLE_LIT;",
        " static final BOP3_5 = DOUBLE_LIT < 2;",
        " static final BOP3_6 = 2 > DOUBLE_LIT;",
        " static final BOP3_7 = DOUBLE_LIT > 2;",
        " static final BOP3_8 = 2 <= INT_LIT;",
        " static final BOP3_9 = INT_LIT <= 2;",
        " static final BOP3_10 = 2 >= INT_LIT;",
        " static final BOP3_11 = INT_LIT >= 2;",
        " static final BOP3_12 = 2.0 <= DOUBLE_LIT;",
        " static final BOP3_13 = DOUBLE_LIT <= 2.0;",
        " static final BOP3_14 = 2.0 >= DOUBLE_LIT;",
        " static final BOP3_15 = DOUBLE_LIT >= 2;",
        " static final BOP4_0 = 5 % INT_LIT;",
        " static final BOP4_1 = INT_LIT % 5;",
        " static final BOP4_2 = 5.0 % DOUBLE_LIT;",
        " static final BOP4_3 = DOUBLE_LIT % 5.0;",
        " static final BOP5_0 = 0x80 & 0x04;",
        " static final BOP5_1 = 0x80 | 0x04;",
        " static final BOP5_2 = 0x80 << 0x04;",
        " static final BOP5_3 = 0x80 >> 0x04;",
        " static final BOP5_4 = 0x80 ~/ 0x04;",
        " static final BOP5_5 = 0x80 ^ 0x04;",
        " static final BOP6 = BOOL_LIT && true;",
        " static final BOP7 = false || BOOL_LIT;",
        " static final BOP8 = STRING_LIT == \"World!\";",
        " static final BOP9 = \"Hello\" != STRING_LIT;",
        " static final BOP10 = INT_LIT === INT_LIT_REF;",
        " static final BOP11 = BOOL_LIT !== true;",
        "}"));

    resolveAndTest(Joiner.on("\n").join(
        "class Object {}",
        "class int {}",
        "class A {",
        " static int foo() { return 1; }",
        "}",
        "class B {",
        " static final BOP1 = A.foo() * 1;",
        " static final BOP2 = 1 * A.foo();",
        "}"),
        DartCompilerErrorCode.EXPECTED_CONSTANT_EXPRESSION,
        DartCompilerErrorCode.EXPECTED_CONSTANT_EXPRESSION_NUMBER,
        DartCompilerErrorCode.EXPECTED_CONSTANT_EXPRESSION,
        DartCompilerErrorCode.EXPECTED_CONSTANT_EXPRESSION_NUMBER);

    resolveAndTest(Joiner.on("\n").join(
        "class Object {}",
        "class int {}",
        "class String {}",
        "class A {",
        " static int foo() { return 1; }",
        " static String bar() { return \"1\"; }",
        "}",
        "class B {",
        " static final BOP1 = 2 < A.foo();",
        " static final BOP2 = A.foo() < 2;",
        " static final BOP3 = 2 < A.bar();",
        " static final BOP4 = A.bar() < 2;",
        "}"),
        DartCompilerErrorCode.EXPECTED_CONSTANT_EXPRESSION,
        DartCompilerErrorCode.EXPECTED_CONSTANT_EXPRESSION_NUMBER,
        DartCompilerErrorCode.EXPECTED_CONSTANT_EXPRESSION,
        DartCompilerErrorCode.EXPECTED_CONSTANT_EXPRESSION_NUMBER,
        DartCompilerErrorCode.EXPECTED_CONSTANT_EXPRESSION,
        DartCompilerErrorCode.EXPECTED_CONSTANT_EXPRESSION_NUMBER,
        DartCompilerErrorCode.EXPECTED_CONSTANT_EXPRESSION,
        DartCompilerErrorCode.EXPECTED_CONSTANT_EXPRESSION_NUMBER);

    resolveAndTest(Joiner.on("\n").join(
        "class Object {}",
        "class int {}",
        "class double {}",
        "class num {}",
        "class A {",
        " static final BOP1 = 0x80 & 2.0;",
        " static final BOP2 = 2.0 & 0x80;",
        "}"),
        DartCompilerErrorCode.EXPECTED_CONSTANT_EXPRESSION_INT,
        DartCompilerErrorCode.EXPECTED_CONSTANT_EXPRESSION_INT);

    resolveAndTest(Joiner.on("\n").join(
        "class Object {}",
        "class bool {}",
        "class int {}",
        "class double {}",
        "class num {}",
        "class A {",
        " static bool foo() { return true; }",
        "}",
        " class B {",
        " static final BOP3 = 45 && true;",
        " static final BOP4 = true || 45;",
        " static final BOP5 = true && A.foo();",
        " static final BOP6 = A.foo() && false;",
        "}"),
        DartCompilerErrorCode.EXPECTED_CONSTANT_EXPRESSION_BOOLEAN,
        DartCompilerErrorCode.EXPECTED_CONSTANT_EXPRESSION_BOOLEAN,
        DartCompilerErrorCode.EXPECTED_CONSTANT_EXPRESSION,
        DartCompilerErrorCode.EXPECTED_CONSTANT_EXPRESSION_BOOLEAN,
        DartCompilerErrorCode.EXPECTED_CONSTANT_EXPRESSION,
        DartCompilerErrorCode.EXPECTED_CONSTANT_EXPRESSION_BOOLEAN);

    resolveAndTest(Joiner.on("\n").join(
        "class Object {}",
        "class bool {}",
        "class int {}",
        "class double {}",
        "class num {}",
        "class A {",
        " static Object foo() { return true; }",
        "}",
        "class B {",
        " const B();",
        " static final OBJECT_LIT = const B();",
        " static final INT_LIT = 1;",
        " static final STRING_LIT = \"true\";",
        " static final BOP1 = STRING_LIT && true;",
        " static final BOP2 = false || STRING_LIT;",
        " static final BOP3 = 59 == OBJECT_LIT;",
        " static final BOP4 = OBJECT_LIT != 59;",
        " static final BOP5 = INT_LIT === OBJECT_LIT;",
        " static final BOP6 = OBJECT_LIT !== true;",
        "}"),
        DartCompilerErrorCode.EXPECTED_CONSTANT_EXPRESSION_BOOLEAN,
        DartCompilerErrorCode.EXPECTED_CONSTANT_EXPRESSION_BOOLEAN,
        DartCompilerErrorCode.EXPECTED_CONSTANT_EXPRESSION_STRING_NUMBER_BOOL,
        DartCompilerErrorCode.EXPECTED_CONSTANT_EXPRESSION_STRING_NUMBER_BOOL,
        DartCompilerErrorCode.EXPECTED_CONSTANT_EXPRESSION_STRING_NUMBER_BOOL,
        DartCompilerErrorCode.EXPECTED_CONSTANT_EXPRESSION_STRING_NUMBER_BOOL);

    resolveAndTest(Joiner.on("\n").join(
        "class Object {}",
        "class A {",
        "  static final INT_LIT = 5;",
        "  static final INT_LIT_REF = INT_LIT;",
        "  static final DOUBLE_LIT = 1.5;",
        "  static final BOOL_LIT = true;",
        "  // Multiple binary expresions",
        "  static final BOP1 = 1 * INT_LIT / 3 + INT_LIT + 9;",
        "  // Parenthized expression",
        "  static final BOP2 = ( 1 > 2 );",
        "  static final BOP3 = (1 * 2) + 3;",
        "  static final BOP4 = 3 + (1 * 2);",
        "}"));

    // Negative Tests
    resolveAndTest(Joiner.on("\n").join(
        "class Object {}",
        "class A {",
        "  static final INT_LIT = 5;",
        "  static final DOUBLE_LIT = 1.5;",
        "  const A();",
        "  static final OBJECT_LIT = const A();",
        "  // Multiple binary expresions",
        "  static final BOP1_0 = 0 + 1 + OBJECT_LIT;",
        "  static final BOP1_1 = 0 + OBJECT_LIT + 1;",
        "  static final BOP1_2 = OBJECT_LIT + 3 + 9;",
        "}"),
        DartCompilerErrorCode.EXPECTED_CONSTANT_EXPRESSION_NUMBER,
        DartCompilerErrorCode.EXPECTED_CONSTANT_EXPRESSION_NUMBER,
        DartCompilerErrorCode.EXPECTED_CONSTANT_EXPRESSION_NUMBER,
        DartCompilerErrorCode.EXPECTED_CONSTANT_EXPRESSION_NUMBER,
        DartCompilerErrorCode.EXPECTED_CONSTANT_EXPRESSION_NUMBER);

    resolveAndTest(Joiner.on("\n").join(
        "class Object {}",
        "class A {",
        "  static final INT_LIT = 5;",
        "  static final DOUBLE_LIT = 1.5;",
        "  const A();",
        "  static final OBJECT_LIT = new A();",
        "  // Multiple binary expresions",
        "  static final PP0 = 0 - (1 + OBJECT_LIT);",
        "  static final PP1 = 0 + (OBJECT_LIT + 1);",
        "  static final PP2 = (OBJECT_LIT + 3) + 9;",
        "  static final PP3 = (OBJECT_LIT) + 3 + 9;",
        "  static final PP4 = (OBJECT_LIT + 3 + 9);",
        "  static final PP5 = OBJECT_LIT + (3 + 9);",
        "}"),
        DartCompilerErrorCode.EXPECTED_CONSTANT_EXPRESSION,
        DartCompilerErrorCode.EXPECTED_CONSTANT_EXPRESSION_NUMBER,
        DartCompilerErrorCode.EXPECTED_CONSTANT_EXPRESSION_NUMBER,
        DartCompilerErrorCode.EXPECTED_CONSTANT_EXPRESSION_NUMBER,
        DartCompilerErrorCode.EXPECTED_CONSTANT_EXPRESSION_NUMBER,
        DartCompilerErrorCode.EXPECTED_CONSTANT_EXPRESSION_NUMBER,
        DartCompilerErrorCode.EXPECTED_CONSTANT_EXPRESSION_NUMBER,
        DartCompilerErrorCode.EXPECTED_CONSTANT_EXPRESSION_NUMBER,
        DartCompilerErrorCode.EXPECTED_CONSTANT_EXPRESSION_NUMBER,
        DartCompilerErrorCode.EXPECTED_CONSTANT_EXPRESSION_NUMBER,
        DartCompilerErrorCode.EXPECTED_CONSTANT_EXPRESSION_NUMBER,
        DartCompilerErrorCode.EXPECTED_CONSTANT_EXPRESSION_NUMBER);
  }

  public void testConstantUnaryExpression() {
    resolveAndTest(Joiner.on("\n").join(
        "class Object {}",
        "class A {",
        "  // Unary expression",
        "  static final BOOL_LIT = true;",
        "  static final INT_LIT = 123;",
        "  static final DOUBLE_LIT = 12.3;",
        "  static final UOP1_0 = !BOOL_LIT;",
        "  static final UOP1_1 = BOOL_LIT || !true;",
        "  static final UOP1_2 = !BOOL_LIT || true;",
        "  static final UOP1_3 = !(BOOL_LIT && true);",
        "  static final UOP2_0 = ~0xf0;",
        "  static final UOP2_1 = ~INT_LIT;",
        "  static final UOP2_2 = ~INT_LIT & 123;",
        "  static final UOP2_3 = ~(INT_LIT | 0xff);",
        "  static final UOP3_0 = -0xf0;",
        "  static final UOP3_1 = -INT_LIT;",
        "  static final UOP3_2 = -INT_LIT + 123;",
        "  static final UOP3_3 = -(INT_LIT * 0xff);",
        "  static final UOP3_4 = -0xf0;",
        "  static final UOP3_5 = -DOUBLE_LIT;",
        "  static final UOP3_6 = -DOUBLE_LIT + 123;",
        "  static final UOP3_7 = -(DOUBLE_LIT * 0xff);",
        "}"));

    resolveAndTest(Joiner.on("\n").join(
        "class Object {}",
        "class int {}",
        "class A {",
        "  // Unary expression",
        "  static final BOOL_LIT = true;",
        "  static int foo() { return 3; }",
        "  static final UOP1 = !5;",
        "  static final UOP2 = !foo();",
        "  static final UOP3 = !(5);",
        "  static final UOP4 = !(foo());",
        "}"),
        DartCompilerErrorCode.EXPECTED_CONSTANT_EXPRESSION_BOOLEAN,
        DartCompilerErrorCode.EXPECTED_CONSTANT_EXPRESSION,
        DartCompilerErrorCode.EXPECTED_CONSTANT_EXPRESSION_BOOLEAN,
        DartCompilerErrorCode.EXPECTED_CONSTANT_EXPRESSION_BOOLEAN,
        DartCompilerErrorCode.EXPECTED_CONSTANT_EXPRESSION,
        DartCompilerErrorCode.EXPECTED_CONSTANT_EXPRESSION_BOOLEAN);
  }

  public void testConstantConstructorAssign() {

    resolveAndTest(Joiner.on("\n").join(
        "class Object {}",
        "class A {",
        "  const A();",
        "}",
        "class B {",
        "  static final a = const A();", // Constant constructor
        "}"));

    // Negative tests
    resolveAndTest(Joiner.on("\n").join(
        "class Object {}",
        "class A {",
        "  const A();",
        " static final a = new A();", // Error: not a constant constructor
        "}"),
        DartCompilerErrorCode.EXPECTED_CONSTANT_EXPRESSION);
  }

  public void testConstantLiteralAssign() {

    resolveAndTest(Joiner.on("\n").join(
        "class Object {}",
        "class A {",
        "  static final b = true;",
        "  static final s = \"apple\";", // string literal
        "  static final i = 1;", // integer literal
        "  static final d = 3.3;", // double literal
        "  static final h = 0xf;", // hex literal
        "  static final n = null;", // null
        "}"));

    // Negative tests
    resolveAndTest(Joiner.on("\n").join(
        "class Object {}",
        "class A {",
        "  foo() { return \"Eve\";}",
        "  static final person = \"earthling\";",
        "  static final s = \"Hello ${foo()}!\";",
        "}"),
        DartCompilerErrorCode.EXPECTED_CONSTANT_EXPRESSION);
  }

  public void testConstantTypedLiteralAssign() {
    resolveAndTest(Joiner.on("\n").join(
        "class Object {}",
        "class List<T> {}",
        "class Map<K,V> {}",
        "class A {",
        "  static final aList = const[1, 2, 3];", // array literal
        "  static final map = const { \"1\": \"one\", \"2\": \"banana\" };", // map literal
        "  static final val = aList[2];",
        "}"));

    // Negative tests, on literals that are not compile time constants.
    resolveAndTest(Joiner.on("\n").join(
        "class Object {}",
        "class List<T> {}",
        "class A {",
        "  // array literal not const",
        "  static final aList= [1, 2, 3];",
        "}"),
        DartCompilerErrorCode.EXPECTED_CONSTANT_EXPRESSION);

    resolveAndTest(Joiner.on("\n").join(
        "class Object {}",
        "class List<T> {}",
        "class A {",
        "  static foo() { return 1; }",
        "  // const array literal contains non-const member",
        "  static final aList = const [foo(), 2, 3];",
        "}"),
        DartCompilerErrorCode.EXPECTED_CONSTANT_EXPRESSION);

    resolveAndTest(Joiner.on("\n").join(
        "class Object {}",
        "class Map<K,V> {}",
        "class A {",
        "  // map literal is not const",
        "  static final aMap = { \"1\": \"one\", \"2\": \"banana\" };",
        "}"),
        DartCompilerErrorCode.EXPECTED_CONSTANT_EXPRESSION);

    resolveAndTest(Joiner.on("\n").join(
        "class Object {}",
        "class String {}",
        "class Map<K,V> {}",
        "class A {",
        "  static String foo() { return \"one\"; }",
        "  static final String s = \"apple\";",
        "  // map literal contains non-const member",
        "  static final map = const { \"1\":foo(), \"2\": \"banana\" };",
        "  static final stringInterp = \"It was that woman who gave me the ${s}\";",
        "}"),
        DartCompilerErrorCode.EXPECTED_CONSTANT_EXPRESSION,
        DartCompilerErrorCode.EXPECTED_CONSTANT_EXPRESSION);
  }

  public void testConstantVariableAssign() {
    resolveAndTest(Joiner.on("\n").join(
        "class Object {}",
        "class A {",
        "  static final a = 1;",
        "}",
        "class B {",
        "  static final i = 1;",
        "  static final j = i;", // variable that is a compile-time constant
        "  static final k = A.a;", // variable that is a compile-time constant
        "}"));

    // Negative tests
    resolveAndTest(Joiner.on("\n").join(
        "class Object {}",
        "class A {",
        " static foo() {return 1;}",
        " static final i = foo();",  // Error: not a constant integer
        "}"),
        DartCompilerErrorCode.EXPECTED_CONSTANT_EXPRESSION);

    resolveAndTest(Joiner.on("\n").join(
        "class Object {}",
        "class A {",
        "  static final foo;",
        "}"),
        DartCompilerErrorCode.STATIC_FINAL_REQUIRES_VALUE);
  }
}
