// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.resolver;

import static com.google.dart.compiler.common.ErrorExpectation.errEx;

import com.google.common.base.Joiner;



/**
 * Tests the code in {@link CompileTimeConstantVisitor}
 */
public class CompileTimeConstantTest extends ResolverTestCase {

  /**
   * We should understand "const" keyword and temporary treat both "const" and "static final" as
   * constants.
   * <p>
   * http://code.google.com/p/dart/issues/detail?id=3550
   */
  public void test_temporaryConstSyntax() {
    resolveAndTestCtConst(Joiner.on("\n").join(
        "class Object {}",
        "const CT = 5;",
        "class A {",
        " const CF = 5;",
        " const C1 = CT + 1;",
        " const C2 = CF + 1;",
        " static final SF1 = CT + 1;",
        " static final SF2 = CF + 1;",
        "}"));
  }

  public void test_nonConstArg() {
    resolveAndTestCtConstExpectErrors(
        Joiner.on("\n").join(
            "class Object {}",
            "class A { const A(s); }",
            "main() {",
            "  var a = const A(new A(null));",
            "}"),
        errEx(ResolverErrorCode.EXPECTED_CONSTANT_EXPRESSION, 4, 19, 11));
  }

  /**
   * This is allowed in "Spec 0.11".
   * <p>
   * http://code.google.com/p/dart/issues/detail?id=3847
   */
  public void test_instanceVariable_nonConstInitializer() {
    resolveAndTestCtConstExpectErrors(Joiner.on("\n").join(
        "// filler filler filler filler filler filler filler filler filler filler",
        "class Object {}",
        "class A {",
        " var f = new Object();",
        "}"));
  }

  /**
   * We can not reference "this" directly or indirectly as reference to other fields.
   * <p>
   * http://code.google.com/p/dart/issues/detail?id=3847
   */
  public void test_instanceVariable_nonConstInitializer_cannotReferenceThis() {
    resolveAndTestCtConstExpectErrors(
        Joiner.on("\n").join(
            "// filler filler filler filler filler filler filler filler filler filler",
            "class Object {}",
            "class Val {",
            "  Val(var o) {}",
            "}",
            "class A {",
            " var f1 = new Val(1);",
            " var f2 = this;",
            " var f3 = new Val(f1);",
            "}",
            "class B extends A {",
            " var f2 = new Val(f3);",
            "}",
            ""),
        errEx(ResolverErrorCode.THIS_OUTSIDE_OF_METHOD, 8, 11, 4),
        errEx(ResolverErrorCode.CANNOT_USE_INSTANCE_FIELD_IN_INSTANCE_FIELD_INITIALIZER, 9, 19, 2),
        errEx(ResolverErrorCode.CANNOT_USE_INSTANCE_FIELD_IN_INSTANCE_FIELD_INITIALIZER, 12, 19, 2));
  }

  /**
   * We can reference top-level fields, because they are static.
   * <p>
   * http://code.google.com/p/dart/issues/detail?id=4400
   */
  public void test_instanceVariable_nonConstInitializer_topLevelField() {
    resolveAndTestCtConstExpectErrors(Joiner.on("\n").join(
        "// filler filler filler filler filler filler filler filler filler filler",
        "class Object {}",
        "final TOP = 1;",
        "class A {",
        " var f = TOP;",
        "}",
        ""));
  }

  /**
   * <p>
   * http://code.google.com/p/dart/issues/detail?id=1655
   */
  public void test_constConstructor_nonConstInitializerValue() {
    resolveAndTestCtConstExpectErrors(
        Joiner.on("\n").join(
            "// filler filler filler filler filler filler filler filler filler filler",
            "class Object {}",
            "foo() {}",
            "class A {",
            " final v;",
            " const A() : v = foo();",
            "}",
            ""),
        errEx(ResolverErrorCode.EXPECTED_CONSTANT_EXPRESSION, 6, 18, 5));
  }

  /**
   * <p>
   * http://code.google.com/p/dart/issues/detail?id=4294
   */
  public void test_constConstructor_redirectInvocation() throws Exception {
    resolveAndTestCtConstExpectErrors(
        Joiner.on("\n").join(
            "// filler filler filler filler filler filler filler filler filler filler",
            "class Object {}",
            "class A {",
            "  final v;",
            "  const A(this.v);",
            "  const A.hasValue() : this(generateValue());",
            "  static generateValue() => 42;",
            "}"),
        errEx(ResolverErrorCode.EXPECTED_CONSTANT_EXPRESSION, 6, 29, 15));
  }

  /**
   * <p>
   * http://code.google.com/p/dart/issues/detail?id=4294
   */
  public void test_constConstructor_superInvocation() throws Exception {
    resolveAndTestCtConstExpectErrors(
        Joiner.on("\n").join(
            "// filler filler filler filler filler filler filler filler filler filler",
            "class Object {}",
            "class A {",
            "  final v;",
            "  const A(this.v);",
            "}",
            "class B extends A {",
            "  const B() : super(generateValue());",
            "  static generateValue() => 42;",
            "}",
            ""),
        errEx(ResolverErrorCode.EXPECTED_CONSTANT_EXPRESSION, 8, 21, 15));
  }

  /**
   * At compile time we "trust" user that parameter will have correct type.
   */
  public void test_constConstructor_constInitializerValue_plusDynamic() {
    resolveAndTestCtConstExpectErrors(
        Joiner.on("\n").join(
            "// filler filler filler filler filler filler filler filler filler filler",
            "class Object {}",
            "class A {",
            " final v;",
            " const A(var p) : v = 100 + p;",
            "}",
            ""));
  }
  
  public void test_constConstructor_constInitializerValue_boolNulls() {
    resolveAndTestCtConstExpectErrors(
        Joiner.on("\n").join(
            "// filler filler filler filler filler filler filler filler filler filler",
            "class Object {}",
            "class A {",
            " final a, b, c, d;",
            " const A(var p) : ",
            "   a = false || null,",
            "   b = null || false,",
            "   c = null || null,",
            "   d = !null;",
            "}",
            ""));
  }
  
  public void test_constConstructor_constInitializerValue_numNulls() {
    resolveAndTestCtConstExpectErrors(
        Joiner.on("\n").join(
            "// filler filler filler filler filler filler filler filler filler filler",
            "class Object {}",
            "class A {",
            " final a, b, c, d, e;",
            " const A(var p) : ",
            "   a = 1 ^ null,",
            "   b = 1 << null,",
            "   c = 1 & null,",
            "   d = ~null,",
            "   e = -null;",
            "}",
            ""));
  }

  public void test_nonConstantExpressions() {
    resolveAndTestCtConstExpectErrors(
        Joiner.on("\n").join(
            "var x = 0;",
            "const c1 = const {'$x' : 1};",
            "const c2 = const {'key': []};",
            "const c3 = const [new Object()];",
            "class Object {}",
            "class String {}",
            ""),
            errEx(ResolverErrorCode.EXPECTED_CONSTANT_EXPRESSION, 2, 21, 1),
            errEx(ResolverErrorCode.EXPECTED_CONSTANT_EXPRESSION, 3, 26,2),
            errEx(ResolverErrorCode.EXPECTED_CONSTANT_EXPRESSION, 4, 19, 12));
  }

  public void test_expressionsWithNull() {
    resolveAndTestCtConst(Joiner.on("\n").join(
        "class Object {}",
        "var b = null === '';"));
  }

  public void test_parameterDefaultValue_inLocalFunction() {
    resolveAndTestCtConstExpectErrors(
        Joiner.on("\n").join(
            "// filler filler filler filler filler filler filler filler filler filler",
            "main() {",
            " int x = 1;",
            " void func([var y = x]) {}",
            "}",
            "class Object {}",
            "class int {}",
            ""),
        errEx(ResolverErrorCode.EXPECTED_CONSTANT_EXPRESSION, 4, 21, 1));
  }

  public void test_stringInterpolation_referenceConstVar_num() {
    resolveAndTestCtConstExpectErrors(Joiner.on("\n").join(
        "// filler filler filler filler filler filler filler filler filler filler",
        "class Object {}",
        "final a = 'aaa';",
        "final v = '$a';",
        ""));
  }

  public void test_stringInterpolation_referenceConstVar_String() {
    resolveAndTestCtConstExpectErrors(Joiner.on("\n").join(
        "// filler filler filler filler filler filler filler filler filler filler",
        "class Object {}",
        "final a = 1.0;",
        "final v = '$a';",
        ""));
  }

  public void test_stringInterpolation_referenceConstVar_bool() {
    resolveAndTestCtConstExpectErrors(Joiner.on("\n").join(
        "// filler filler filler filler filler filler filler filler filler filler",
        "class Object {}",
        "final a = false;",
        "final v = '$a';",
        ""));
  }

  public void test_stringInterpolation_referenceConstVar_Object() {
    resolveAndTestCtConstExpectErrors(
        Joiner.on("\n").join(
            "// filler filler filler filler filler filler filler filler filler filler",
            "class Object {}",
            "class C {",
            "  const C();",
            "}",
            "final a = const C();",
            "final v = '$a';",
            ""),
        errEx(ResolverErrorCode.EXPECTED_CONSTANT_EXPRESSION_STRING_NUMBER_BOOL, 7, 13, 1));
  }

  public void test_stringInterpolation_inMethod() {
    resolveAndTestCtConstExpectErrors(Joiner.on("\n").join(
        "// filler filler filler filler filler filler filler filler filler filler",
        "class Object {}",
        "class Conster {",
        "  const Conster(this.value);",
        "  final value;",
        "}",
        "final a = 'aaa';",
        "f() {",
        "  const Conster('$a');",
        "}",
        ""));
  }

  public void testConstantBinaryExpression1() {
    resolveAndTestCtConst(Joiner.on("\n").join(
        "class Object {}",
        "class A {",
        " static final INT_LIT = 5;",
        " static final BOP1_0 = INT_LIT + 1;",
        " static final BOP1_1 = 1 + INT_LIT;",
        " static final BOP1_2 = INT_LIT - 1;",
        " static final BOP1_3 = 1 - INT_LIT;",
        " static final BOP1_4 = INT_LIT * 1;",
        " static final BOP1_5 = 1 * INT_LIT;",
        " static final BOP1_6 = INT_LIT / 1;",
        " static final BOP1_7 = 1 / INT_LIT;",
        "}"));
  }

  public void testConstantBinaryExpression10() {
    resolveAndTestCtConst(Joiner.on("\n").join(
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
  }

  public void testConstantBinaryExpression11() {
    resolveAndTestCtConst(Joiner.on("\n").join(
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
        ResolverErrorCode.EXPECTED_CONSTANT_EXPRESSION_NUMBER,
        ResolverErrorCode.EXPECTED_CONSTANT_EXPRESSION_NUMBER,
        ResolverErrorCode.EXPECTED_CONSTANT_EXPRESSION_NUMBER,
        ResolverErrorCode.EXPECTED_CONSTANT_EXPRESSION_NUMBER,
        ResolverErrorCode.EXPECTED_CONSTANT_EXPRESSION_NUMBER);
  }
  
  public void test_circularReference() {
    resolveAndTestCtConstExpectErrors(
        Joiner.on("\n").join(
            "class Object {}",
            "class A {",
            "  static final a = b;",
            "  static final b = a;",
            "}"),
            errEx(ResolverErrorCode.CIRCULAR_REFERENCE, 3, 20, 1),
            errEx(ResolverErrorCode.CIRCULAR_REFERENCE, 4, 20, 1));
  }
  
  public void test_topLevelFunctionReference() {
    resolveAndTestCtConstExpectErrors(Joiner.on("\n").join(
        "// filler filler filler filler filler filler filler filler filler filler",
        "class Object {}",
        "m() {}",
        "class A {",
        "  static final V1 = m;",
        "}",
        "final V2 = m;",
        ""));
  }
  
  public void test_staticMethodReference() {
    resolveAndTestCtConstExpectErrors(Joiner.on("\n").join(
        "// filler filler filler filler filler filler filler filler filler filler",
        "class Object {}",
        "class A {",
        "  static m() {}",
        "  static final V1 = m;",
        "}",
        "final V2 = A.m;",
        ""));
  }
  
  public void test_instanceMethodReference() {
    resolveAndTestCtConstExpectErrors(
        Joiner.on("\n").join(
            "// filler filler filler filler filler filler filler filler filler filler",
            "class Object {}",
            "class A {",
            "  m() {}",
            "  static final V1 = m;",
            "}",
            "final V2 = A.m;",
            ""),
        errEx(ResolverErrorCode.ILLEGAL_METHOD_ACCESS_FROM_STATIC, 5, 21, 1),
        errEx(ResolverErrorCode.NOT_A_STATIC_METHOD, 7, 14, 1),
        errEx(ResolverErrorCode.EXPECTED_CONSTANT_EXPRESSION, 5, 21, 1),
        errEx(ResolverErrorCode.EXPECTED_CONSTANT_EXPRESSION, 7, 12, 3));
  }

  public void testConstantBinaryExpression12() {
    // Multiple binary expressions
    resolveAndTestCtConst(Joiner.on("\n").join(
        "class Object {}",
        "class A {",
        "  static final INT_LIT = 5;",
        "  static final DOUBLE_LIT = 1.5;",
        "  const A();",
        "  static final OBJECT_LIT = new A();",
        "  static final PP0 = 0 - (1 + OBJECT_LIT);",
        "  static final PP1 = 0 + (OBJECT_LIT + 1);",
        "  static final PP2 = (OBJECT_LIT + 3) + 9;",
        "  static final PP3 = (OBJECT_LIT) + 3 + 9;",
        "  static final PP4 = (OBJECT_LIT + 3 + 9);",
        "  static final PP5 = OBJECT_LIT + (3 + 9);",
        "}"),
        ResolverErrorCode.EXPECTED_CONSTANT_EXPRESSION,
        ResolverErrorCode.EXPECTED_CONSTANT_EXPRESSION,
        ResolverErrorCode.EXPECTED_CONSTANT_EXPRESSION_NUMBER,
        ResolverErrorCode.EXPECTED_CONSTANT_EXPRESSION_NUMBER,
        ResolverErrorCode.EXPECTED_CONSTANT_EXPRESSION,
        ResolverErrorCode.EXPECTED_CONSTANT_EXPRESSION_NUMBER,
        ResolverErrorCode.EXPECTED_CONSTANT_EXPRESSION_NUMBER,
        ResolverErrorCode.EXPECTED_CONSTANT_EXPRESSION,
        ResolverErrorCode.EXPECTED_CONSTANT_EXPRESSION_NUMBER,
        ResolverErrorCode.EXPECTED_CONSTANT_EXPRESSION_NUMBER,
        ResolverErrorCode.EXPECTED_CONSTANT_EXPRESSION,
        ResolverErrorCode.EXPECTED_CONSTANT_EXPRESSION_NUMBER,
        ResolverErrorCode.EXPECTED_CONSTANT_EXPRESSION_NUMBER,
        ResolverErrorCode.EXPECTED_CONSTANT_EXPRESSION,
        ResolverErrorCode.EXPECTED_CONSTANT_EXPRESSION_NUMBER,
        ResolverErrorCode.EXPECTED_CONSTANT_EXPRESSION_NUMBER,
        ResolverErrorCode.EXPECTED_CONSTANT_EXPRESSION,
        ResolverErrorCode.EXPECTED_CONSTANT_EXPRESSION_NUMBER);
  }

  public void testConstantBinaryExpression2() {
    resolveAndTestCtConst(Joiner.on("\n").join(
        "class Object {}",
        "class A {",
        " static final DOUBLE_LIT = 1.5;",
        " static final BOP2_0 = DOUBLE_LIT + 1.5;",
        " static final BOP2_1 = 1.5 + DOUBLE_LIT;",
        " static final BOP2_2 = DOUBLE_LIT - 1.5;",
        " static final BOP2_3 = 1.5 - DOUBLE_LIT;",
        " static final BOP2_4 = DOUBLE_LIT * 1.5;",
        " static final BOP2_5 = 1.5 * DOUBLE_LIT;",
        " static final BOP2_6 = DOUBLE_LIT / 1.5;",
        " static final BOP2_7 = 1.5 / DOUBLE_LIT;",
        "}"));
  }

  public void testConstantBinaryExpression3() {
    resolveAndTestCtConst(Joiner.on("\n").join(
        "class Object {}",
        "class A {",
        " static final INT_LIT = 5;",
        " static final BOP3_0 = 2 < INT_LIT;",
        " static final BOP3_1 = INT_LIT < 2;",
        " static final BOP3_2 = 2 > INT_LIT;",
        " static final BOP3_3 = INT_LIT > 2;",
        "}"));

    resolveAndTestCtConst(Joiner.on("\n").join(
        "class Object {}",
        "class A {",
        " static final INT_LIT = 5;",
        " static final DOUBLE_LIT = 1.5;",
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
        "}"));
  }

  public void testConstantBinaryExpression4() {
    resolveAndTestCtConst(Joiner.on("\n").join(
        "class Object {}",
        "class A {",
        " static final INT_LIT = 5;",
        " static final INT_LIT_REF = INT_LIT;",
        " static final DOUBLE_LIT = 1.5;",
        " static final BOOL_LIT = true;",
        " static final STRING_LIT = 'Hello';",
        " static final BOP4_0 = 5 % INT_LIT;",
        " static final BOP4_1 = INT_LIT % 5;",
        " static final BOP4_2 = 5.0 % DOUBLE_LIT;",
        " static final BOP4_3 = DOUBLE_LIT % 5.0;",
        " static final BOP5_0 = 0x80 & 0x04;",
        " static final BOP5_1 = 0x80 | 0x04;",
        " static final BOP5_2 = 0x80 << 0x04;",
        " static final BOP5_3 = 0x80 >> 0x04;",
        " static final BOP5_4 = 0x80 ~/ 0x04;",
        " static final BOP5_5 = DOUBLE_LIT ~/ DOUBLE_LIT;",
        " static final BOP5_6 = 0x80 ^ 0x04;",
        " static final BOP6 = BOOL_LIT && true;",
        " static final BOP7 = false || BOOL_LIT;",
        " static final BOP8 = STRING_LIT == 'World!';",
        " static final BOP9 = 'Hello' != STRING_LIT;",
        " static final BOP10 = INT_LIT === INT_LIT_REF;",
        " static final BOP11 = BOOL_LIT !== true;",
        "}"));
  }

  public void testConstantBinaryExpression5() {
    resolveAndTestCtConst(Joiner.on("\n").join(
        "class Object {}",
        "class int {}",
        "class A {",
        " static int foo() { return 1; }",
        "}",
        "class B {",
        " static final BOP1 = A.foo() * 1;",
        " static final BOP2 = 1 * A.foo();",
        "}"),
        ResolverErrorCode.EXPECTED_CONSTANT_EXPRESSION,
        ResolverErrorCode.EXPECTED_CONSTANT_EXPRESSION_NUMBER,
        ResolverErrorCode.EXPECTED_CONSTANT_EXPRESSION,
        ResolverErrorCode.EXPECTED_CONSTANT_EXPRESSION_NUMBER);
  }

  public void testConstantBinaryExpression6() {
    resolveAndTestCtConst(Joiner.on("\n").join(
        "class Object {}",
        "class int {}",
        "class String {}",
        "class A {",
        " static int foo() { return 1; }",
        " static String bar() { return '1'; }",
        "}",
        "class B {",
        " static final BOP1 = 2 < A.foo();",
        " static final BOP2 = A.foo() < 2;",
        " static final BOP3 = A.foo();",
        " static final BOP4 = A.bar();",
        "}"),
        ResolverErrorCode.EXPECTED_CONSTANT_EXPRESSION,
        ResolverErrorCode.EXPECTED_CONSTANT_EXPRESSION_NUMBER,
        ResolverErrorCode.EXPECTED_CONSTANT_EXPRESSION,
        ResolverErrorCode.EXPECTED_CONSTANT_EXPRESSION_NUMBER,
        ResolverErrorCode.EXPECTED_CONSTANT_EXPRESSION,
        ResolverErrorCode.EXPECTED_CONSTANT_EXPRESSION);
  }

  public void testConstantBinaryExpression7() {
    resolveAndTestCtConst(Joiner.on("\n").join(
        "class Object {}",
        "class int {}",
        "class double {}",
        "class num {}",
        "class A {",
        " static final BOP1 = 0x80 & 2.0;",
        " static final BOP2 = 2.0 & 0x80;",
        "}"),
        ResolverErrorCode.EXPECTED_CONSTANT_EXPRESSION_INT,
        ResolverErrorCode.EXPECTED_CONSTANT_EXPRESSION_INT);
  }

  public void testConstantBinaryExpression8() {
    resolveAndTestCtConst(Joiner.on("\n").join(
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
        ResolverErrorCode.EXPECTED_CONSTANT_EXPRESSION_BOOLEAN,
        ResolverErrorCode.EXPECTED_CONSTANT_EXPRESSION_BOOLEAN,
        ResolverErrorCode.EXPECTED_CONSTANT_EXPRESSION,
        ResolverErrorCode.EXPECTED_CONSTANT_EXPRESSION_BOOLEAN,
        ResolverErrorCode.EXPECTED_CONSTANT_EXPRESSION,
        ResolverErrorCode.EXPECTED_CONSTANT_EXPRESSION_BOOLEAN);
  }

  public void testConstantBinaryExpression9() {
    resolveAndTestCtConst(Joiner.on("\n").join(
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
        " static final STRING_LIT = 'true';",
        " static final BOP1 = STRING_LIT && true;",
        " static final BOP2 = false || STRING_LIT;",
        " static final BOP3 = 59 == OBJECT_LIT;",
        " static final BOP4 = OBJECT_LIT != 59;",
        " static final BOP5 = INT_LIT === OBJECT_LIT;",
        " static final BOP6 = OBJECT_LIT !== true;",
        "}"),
        ResolverErrorCode.EXPECTED_CONSTANT_EXPRESSION_BOOLEAN,
        ResolverErrorCode.EXPECTED_CONSTANT_EXPRESSION_BOOLEAN,
        ResolverErrorCode.EXPECTED_CONSTANT_EXPRESSION_STRING_NUMBER_BOOL,
        ResolverErrorCode.EXPECTED_CONSTANT_EXPRESSION_STRING_NUMBER_BOOL,
        ResolverErrorCode.EXPECTED_CONSTANT_EXPRESSION_STRING_NUMBER_BOOL,
        ResolverErrorCode.EXPECTED_CONSTANT_EXPRESSION_STRING_NUMBER_BOOL);
  }

  public void testConstantConstructorAssign1() {
    resolveAndTestCtConst(Joiner.on("\n").join(
        "class Object {}",
        "class A {",
        "  const A();",
        "}",
        "class B {",
        "  static final a = const A();", // Constant constructor
        "}"));
  }

  public void testConstantConstructorAssign2() {
    // Negative tests
    resolveAndTestCtConst(Joiner.on("\n").join(
        "class Object {}",
        "class A {",
        "  const A();",
        " static final a = new A();", // Error: not a constant constructor
        "}"),
        ResolverErrorCode.EXPECTED_CONSTANT_EXPRESSION);
  }

  public void testConstantLiteralAssign1() {
    resolveAndTestCtConst(Joiner.on("\n").join(
        "class Object {}",
        "class A {",
        "  static final b = true;",
        "  static final s = 'apple';", // string literal
        "  static final i = 1;", // integer literal
        "  static final d = 3.3;", // double literal
        "  static final h = 0xf;", // hex literal
        "  static final n = null;", // null
        "}"));
  }

  public void testConstantLiteralAssign2() {
    resolveAndTestCtConst(Joiner.on("\n").join(
        "class Object {}",
        "class A {",
        "  foo() { return 'Eve';}",
        "  static final person = 'earthling';",
        "  static final s = 'Hello ${foo()}!';",
        "}"),
        ResolverErrorCode.EXPECTED_CONSTANT_EXPRESSION,
        ResolverErrorCode.EXPECTED_CONSTANT_EXPRESSION_STRING_NUMBER_BOOL);
  }

  public void testConstantTypedLiteralAssign1() {
    resolveAndTestCtConst(Joiner.on("\n").join(
        "class Object {}",
        "class String {}",
        "class List<T> {}",
        "class Map<K,V> {}",
        "class A {",
        "  static final aList = const[1, 2, 3];", // array literal
        "  static final map = const { '1': 'one', '2': 'banana' };", // map literal
        "  static final val = aList[2];",
        "}"));
  }

  public void testConstantTypedLiteralAssign2() {
    resolveAndTestCtConst(Joiner.on("\n").join(
        "class Object {}",
        "class List<T> {}",
        "class A {",
        "  // array literal not const",
        "  static final aList= [1, 2, 3];",
        "}"),
        ResolverErrorCode.EXPECTED_CONSTANT_EXPRESSION);
  }

  public void testConstantTypedLiteralAssign3() {
    resolveAndTestCtConst(Joiner.on("\n").join(
        "class Object {}",
        "class List<T> {}",
        "class A {",
        "  static foo() { return 1; }",
        "  // const array literal contains non-const member",
        "  static final aList = const [foo(), 2, 3];",
        "}"),
        ResolverErrorCode.EXPECTED_CONSTANT_EXPRESSION);
  }

  public void testConstantTypedLiteralAssign4() {
    resolveAndTestCtConst(Joiner.on("\n").join(
        "class Object {}",
        "class String {}",
        "class Map<K,V> {}",
        "class A {",
        "  // map literal is not const",
        "  static final aMap = { '1': 'one', '2': 'banana' };",
        "}"),
        ResolverErrorCode.EXPECTED_CONSTANT_EXPRESSION);
  }
  public void testConstantTypedLiteralAssign5() {
    resolveAndTestCtConst(Joiner.on("\n").join(
        "class Object {}",
        "class String {}",
        "class Map<K,V> {}",
        "class A {",
        "  static String foo() { return 'one'; }",
        "  static final String s = 'apple';",
        "  // map literal contains non-const member",
        "  static final map = const { '1': foo(), '2': 'banana' };",
        "  static final stringInterp = 'It was that woman who gave me the ${s}';",
        "}"),
        ResolverErrorCode.EXPECTED_CONSTANT_EXPRESSION);
  }

  public void testConstantUnaryExpression1() {
    resolveAndTestCtConst(Joiner.on("\n").join(
        "class Object {}",
        "class A {",
        "  static final BOOL_LIT = true;",
        "  static final UOP1_0 = !BOOL_LIT;",
        "  static final UOP1_1 = BOOL_LIT || !true;",
        "  static final UOP1_2 = !BOOL_LIT || true;",
        "  static final UOP1_3 = !(BOOL_LIT && true);",
        "}"));
  }

  public void testConstantUnaryExpression2() {
    resolveAndTestCtConst(Joiner.on("\n").join(
        "class Object {}",
        "class A {",
        "  static final BOOL_LIT = true;",
        "  static final INT_LIT = 123;",
        "  static final DOUBLE_LIT = 12.3;",
        "  static final UOP2_0 = ~0xf0;",
        "  static final UOP2_1 = ~INT_LIT;",
        "  static final UOP2_2 = ~INT_LIT & 123;",
        "  static final UOP2_3 = ~(INT_LIT | 0xff);",
        "}"));
  }

  public void testConstantUnaryExpression3() {
    resolveAndTestCtConst(Joiner.on("\n").join(
        "class Object {}",
        "class A {",
        "  static final INT_LIT = 123;",
        "  static final DOUBLE_LIT = 12.3;",
        "  static final UOP3_0 = -0xf0;",
        "  static final UOP3_1 = -INT_LIT;",
        "  static final UOP3_2 = -INT_LIT + 123;",
        "  static final UOP3_3 = -(INT_LIT * 0xff);",
        "  static final UOP3_4 = -0xf0;",
        "  static final UOP3_5 = -DOUBLE_LIT;",
        "  static final UOP3_6 = -DOUBLE_LIT + 123;",
        "  static final UOP3_7 = -(DOUBLE_LIT * 0xff);",
        "}"));
  }

  public void testConstantUnaryExpression4() {
    resolveAndTestCtConst(Joiner.on("\n").join(
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
        ResolverErrorCode.EXPECTED_CONSTANT_EXPRESSION_BOOLEAN,
        ResolverErrorCode.EXPECTED_CONSTANT_EXPRESSION,
        ResolverErrorCode.EXPECTED_CONSTANT_EXPRESSION_BOOLEAN,
        ResolverErrorCode.EXPECTED_CONSTANT_EXPRESSION_BOOLEAN,
        ResolverErrorCode.EXPECTED_CONSTANT_EXPRESSION,
        ResolverErrorCode.EXPECTED_CONSTANT_EXPRESSION_BOOLEAN);
  }

  public void testConstantVariableAssign1() {
    resolveAndTestCtConst(Joiner.on("\n").join(
        "class Object {}",
        "class A {",
        "  static final a = 1;",
        "}",
        "class B {",
        "  static final i = 1;",
        "  static final j = i;", // variable that is a compile-time constant
        "  static final k = A.a;", // variable that is a compile-time constant
        "}"));
  }

  public void testConstantVariableAssign2() {
    resolveAndTestCtConst(Joiner.on("\n").join(
        "class Object {}",
        "class A {",
        " static foo() {return 1;}",
        " static final i = foo();",  // Error: not a constant integer
        "}"),
        ResolverErrorCode.EXPECTED_CONSTANT_EXPRESSION);
  }

  public void testConstantVariableAssign3() {
      // Part of the regular resolver pass
      resolveAndTest(Joiner.on("\n").join(
          "class Object {}",
          "class A {",
          "  static final foo;",
          "}"),
          ResolverErrorCode.STATIC_FINAL_REQUIRES_VALUE);
  }

  public void testForwardLookupExpressions() {
    resolveAndTestCtConst(Joiner.on("\n").join(
        "class Object {}",
        "class A {",
        "  static final value1 = value2 * 2;",
        "  static final value2 = value3 * 4;",
        "  static final value3 = 8;",
        "}"));
  }

  public void testInvalidDefaultParameterWithField() {
    resolveAndTestCtConstExpectErrors(
        Joiner.on("\n").join(
            "class Object {}",
            "class Function {}",
            "Function get topLevelGetter() => () {};",
            "topLevel([var x = topLevelGetter]) { x(); }",
            "main() { topLevel(); }"),
        errEx(ResolverErrorCode.EXPECTED_CONSTANT_EXPRESSION, 4, 19, 14),
        errEx(ResolverErrorCode.EXPECTED_CONSTANT_EXPRESSION, 3, 1, 39));
  }
  
  /** 
   * Integers used in parenthesis result in integer values.
   * (A bug caused them to be demoted to 'num')
   */
  public void testParenthizedMathExpressions1() {
    resolveAndTestCtConstExpectErrors(
        Joiner.on("\n").join(    
            "class Object {}",
            "interface int {}",
            "class A {",
            "  static final int value1 = (1 << 5) - 1;",
            "  static final int value2 = value1 & 0xFFFF;",
            "  static final int value3 = (1 << 5) + 1;",
            "  static final int value4 = value3 & 0xFFFF;",
            "  static final int value5 = (1 << 5) * 1;",
            "  static final int value6 = value5 & 0xFFFF;",            
            "  static final int value7 = (1 << 5) / 1;",
            "  static final int value8 = value7 & 0xFFFF;",                        
            "}"));    
  }
  
  /** 
   * Doubles used in parenthesis result in double values.
   * (A bug caused them to be demoted to 'num')
   */  
  public void testParenthizedMathExpressions2() {
    resolveAndTestCtConstExpectErrors(
        Joiner.on("\n").join(    
            "class Object {}",
            "interface double {}",
            "class A {",
            "  static final double value1 = (1.0 * 5.0) - 1.0;",
            "  static final double value2 = value1 + 99.0;",
            "  static final double value3 = (1.0 * 5.0) + 1.0;",
            "  static final double value4 = value3 * 99.0;",
            "  static final double value5 = (1.0 * 5.0) * 1.0;",
            "  static final double value6 = value5 * 99.0;",            
            "  static final double value7 = (1.0 * 5.0) / 1.0;",
            "  static final double value8 = value7 * 99.0;",                        
            "}"));    
  }  
  
  /**
   * Mixing doubles and ints in aritmetic should result in a double value.
   * Not explicitly called out for in the spec yet, but this is the runtime behavior.
   */
  public void testParenthizedMathExpressions3() {
    resolveAndTestCtConstExpectErrors(
        Joiner.on("\n").join(    
            "class Object {}",
            "interface double {}",
            "class A {",
            "  static final double value1 = (1 * 5) - 1.0;",
            "  static final double value2 = value1 + 99.0;",
            "  static final double value3 = (1 * 5) + 1.0;",
            "  static final double value4 = value3 * 99.0;",
            "  static final double value5 = (1 * 5) * 1.0;",
            "  static final double value6 = value5 * 99.0;",            
            "  static final double value7 = (1 * 5) / 1.0;",
            "  static final double value8 = value7 * 99.0;",                        
            "}"));    
  }
  
  /**
   * Test mixing strings with ints and doubles in a compile time constant expression.
   * Should result in errors.
   */
  public void testParenthizedMathExpressions4() {
    resolveAndTestCtConstExpectErrors(
        Joiner.on("\n").join(    
            "class Object {}",
            "interface int {}",
            "class A {",
            "  static final int value1 = ('Invalid') - 1;",
            "  static final int value2 = value1 & 0xFFFF;",
            "}"),
            errEx(ResolverErrorCode.EXPECTED_CONSTANT_EXPRESSION_NUMBER, 4, 29, 11),
            // Unfortunately, the CTConst analyzer reports the same error twice 
            // because value1 is analyzed twice, once for original assignment, and a
            // second time when used in the RHS of the value2 definition.
            errEx(ResolverErrorCode.EXPECTED_CONSTANT_EXPRESSION_NUMBER, 4, 29, 11),
            errEx(ResolverErrorCode.EXPECTED_CONSTANT_EXPRESSION_INT, 5, 29, 6));
    
    resolveAndTestCtConstExpectErrors(
        Joiner.on("\n").join(            
            "class Object {}",
            "interface int {}",                             
            "class A {",
            "  static final int value3 = ('Invalid') + 1;",
            "  static final int value4 = value3 & 0xFFFF;",
            "}"),
            errEx(ResolverErrorCode.EXPECTED_CONSTANT_EXPRESSION_STRING, 4, 43, 1),
            errEx(ResolverErrorCode.EXPECTED_CONSTANT_EXPRESSION_STRING, 4, 43, 1),
            errEx(ResolverErrorCode.EXPECTED_CONSTANT_EXPRESSION_INT, 5, 29, 6));
    
    resolveAndTestCtConstExpectErrors(
        Joiner.on("\n").join(            
            "class Object {}",
            "interface int {}",
            "class A {",                             
            "  static final int value5 = ('Invalid') * 1;",
            "  static final int value6 = value5 & 0xFFFF;",            
            "}"),
            errEx(ResolverErrorCode.EXPECTED_CONSTANT_EXPRESSION_NUMBER, 4, 29, 11),
            errEx(ResolverErrorCode.EXPECTED_CONSTANT_EXPRESSION_NUMBER, 4, 29, 11),
            errEx(ResolverErrorCode.EXPECTED_CONSTANT_EXPRESSION_INT, 5, 29, 6));            
                             
    resolveAndTestCtConstExpectErrors(
        Joiner.on("\n").join(                
            "class Object {}",
            "interface int {}",
            "class A {",
            "  static final int value7 = ('Invalid') / 1;",
            "  static final int value8 = value7 & 0xFFFF;",                        
            "}"),
            errEx(ResolverErrorCode.EXPECTED_CONSTANT_EXPRESSION_NUMBER, 4, 29, 11),
            errEx(ResolverErrorCode.EXPECTED_CONSTANT_EXPRESSION_NUMBER, 4, 29, 11),
            errEx(ResolverErrorCode.EXPECTED_CONSTANT_EXPRESSION_INT, 5, 29, 6));            
  }
}
