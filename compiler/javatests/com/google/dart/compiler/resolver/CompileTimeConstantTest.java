// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.resolver;

import com.google.common.base.Joiner;

import static com.google.dart.compiler.common.ErrorExpectation.errEx;



/**
 * Tests the code in {@link CompileTimeConstantVisitor}
 */
public class CompileTimeConstantTest extends ResolverTestCase {

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
   * Final variable does not have to have constant initializer.
   */
  public void test_finalIsNoConst() {
    resolveAndTestCtConstExpectErrors(Joiner.on("\n").join(
        "// filler filler filler filler filler filler filler filler filler filler",
        "class Object {}",
        "class int {}",
        "",
        "foo() => 10;",
        "final g1 = foo();",
        "var   g2 = foo();",
        "",
        "class A {",
        "  static final f1 = bar();",
        "  static var   f2 = bar();",
        "  bar() => 20;",
        "}",
        "main() {",
        "  final v1 = foo();",
        "}",
        ""));
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

  public void test_cascade() {
    resolveAndTestCtConstExpectErrors(
        Joiner.on("\n").join(
            "// filler filler filler filler filler filler filler filler filler filler",
            "main() {",
            " var v;",
            " const c = v..foo;",
            "}",
            "class Object {}",
            "class int {}",
            ""),
        errEx(ResolverErrorCode.EXPECTED_CONSTANT_EXPRESSION, 4, 12, 1),
        errEx(ResolverErrorCode.EXPECTED_CONSTANT_EXPRESSION, 4, 13, 5));
  }

  public void test_stringInterpolation_referenceConstVar_String() {
    resolveAndTestCtConstExpectErrors(Joiner.on("\n").join(
        "// filler filler filler filler filler filler filler filler filler filler",
        "class Object {}",
        "const a = 'aaa';",
        "const v = '$a';",
        ""));
  }

  public void test_stringInterpolation_referenceConstVar_num() {
    resolveAndTestCtConstExpectErrors(Joiner.on("\n").join(
        "// filler filler filler filler filler filler filler filler filler filler",
        "class Object {}",
        "const a = 1.0;",
        "const v = '$a';",
        ""));
  }

  public void test_stringInterpolation_referenceConstVar_bool() {
    resolveAndTestCtConstExpectErrors(Joiner.on("\n").join(
        "// filler filler filler filler filler filler filler filler filler filler",
        "class Object {}",
        "const a = false;",
        "const v = '$a';",
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
            "const a = const C();",
            "const v = '$a';",
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
        "const a = 'aaa';",
        "f() {",
        "  const Conster('$a');",
        "}",
        ""));
  }

  public void testConstantBinaryExpression1() {
    resolveAndTestCtConst(Joiner.on("\n").join(
        "class Object {}",
        "class A {",
        " static const INT_LIT = 5;",
        " static const BOP1_0 = INT_LIT + 1;",
        " static const BOP1_1 = 1 + INT_LIT;",
        " static const BOP1_2 = INT_LIT - 1;",
        " static const BOP1_3 = 1 - INT_LIT;",
        " static const BOP1_4 = INT_LIT * 1;",
        " static const BOP1_5 = 1 * INT_LIT;",
        " static const BOP1_6 = INT_LIT / 1;",
        " static const BOP1_7 = 1 / INT_LIT;",
        "}"));
  }

  public void testConstantBinaryExpression10() {
    resolveAndTestCtConst(Joiner.on("\n").join(
        "class Object {}",
        "class A {",
        "  static const INT_LIT = 5;",
        "  static const INT_LIT_REF = INT_LIT;",
        "  static const DOUBLE_LIT = 1.5;",
        "  static const BOOL_LIT = true;",
        "  // Multiple binary expresions",
        "  static const BOP1 = 1 * INT_LIT / 3 + INT_LIT + 9;",
        "  // Parenthized expression",
        "  static const BOP2 = ( 1 > 2 );",
        "  static const BOP3 = (1 * 2) + 3;",
        "  static const BOP4 = 3 + (1 * 2);",
        "}"));
  }

  public void testConstantBinaryExpression11() {
    resolveAndTestCtConst(Joiner.on("\n").join(
        "class Object {}",
        "class A {",
        "  static const INT_LIT = 5;",
        "  static const DOUBLE_LIT = 1.5;",
        "  const A();",
        "  static const OBJECT_LIT = const A();",
        "  // Multiple binary expresions",
        "  static const BOP1_0 = 0 + 1 + OBJECT_LIT;",
        "  static const BOP1_1 = 0 + OBJECT_LIT + 1;",
        "  static const BOP1_2 = OBJECT_LIT + 3 + 9;",
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
            "  static const F1 = F2;",
            "  static const F2 = F1;",
            "}"),
            errEx(ResolverErrorCode.CIRCULAR_REFERENCE, 3, 21, 2),
            errEx(ResolverErrorCode.CIRCULAR_REFERENCE, 4, 21, 2));
  }
  
  public void test_topLevelFunctionReference() {
    resolveAndTestCtConstExpectErrors(Joiner.on("\n").join(
        "// filler filler filler filler filler filler filler filler filler filler",
        "class Object {}",
        "m() {}",
        "class A {",
        "  static const V1 = m;",
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
        "  static const V1 = m;",
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
            "  static const V1 = m;",
            "}",
            "const V2 = A.m;",
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
        "  static const INT_LIT = 5;",
        "  static const DOUBLE_LIT = 1.5;",
        "  const A();",
        "  static const OBJECT_LIT = new A();",
        "  static const PP0 = 0 - (1 + OBJECT_LIT);",
        "  static const PP1 = 0 + (OBJECT_LIT + 1);",
        "  static const PP2 = (OBJECT_LIT + 3) + 9;",
        "  static const PP3 = (OBJECT_LIT) + 3 + 9;",
        "  static const PP4 = (OBJECT_LIT + 3 + 9);",
        "  static const PP5 = OBJECT_LIT + (3 + 9);",
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
        " static const DOUBLE_LIT = 1.5;",
        " static const BOP2_0 = DOUBLE_LIT + 1.5;",
        " static const BOP2_1 = 1.5 + DOUBLE_LIT;",
        " static const BOP2_2 = DOUBLE_LIT - 1.5;",
        " static const BOP2_3 = 1.5 - DOUBLE_LIT;",
        " static const BOP2_4 = DOUBLE_LIT * 1.5;",
        " static const BOP2_5 = 1.5 * DOUBLE_LIT;",
        " static const BOP2_6 = DOUBLE_LIT / 1.5;",
        " static const BOP2_7 = 1.5 / DOUBLE_LIT;",
        "}"));
  }

  public void testConstantBinaryExpression3() {
    resolveAndTestCtConst(Joiner.on("\n").join(
        "class Object {}",
        "class A {",
        " static const INT_LIT = 5;",
        " static const BOP3_0 = 2 < INT_LIT;",
        " static const BOP3_1 = INT_LIT < 2;",
        " static const BOP3_2 = 2 > INT_LIT;",
        " static const BOP3_3 = INT_LIT > 2;",
        "}"));

    resolveAndTestCtConst(Joiner.on("\n").join(
        "class Object {}",
        "class A {",
        " static const INT_LIT = 5;",
        " static const DOUBLE_LIT = 1.5;",
        " static const BOP3_4 = 2 < DOUBLE_LIT;",
        " static const BOP3_5 = DOUBLE_LIT < 2;",
        " static const BOP3_6 = 2 > DOUBLE_LIT;",
        " static const BOP3_7 = DOUBLE_LIT > 2;",
        " static const BOP3_8 = 2 <= INT_LIT;",
        " static const BOP3_9 = INT_LIT <= 2;",
        " static const BOP3_10 = 2 >= INT_LIT;",
        " static const BOP3_11 = INT_LIT >= 2;",
        " static const BOP3_12 = 2.0 <= DOUBLE_LIT;",
        " static const BOP3_13 = DOUBLE_LIT <= 2.0;",
        " static const BOP3_14 = 2.0 >= DOUBLE_LIT;",
        " static const BOP3_15 = DOUBLE_LIT >= 2;",
        "}"));
  }

  public void testConstantBinaryExpression4() {
    resolveAndTestCtConst(Joiner.on("\n").join(
        "class Object {}",
        "class A {",
        " static const INT_LIT = 5;",
        " static const INT_LIT_REF = INT_LIT;",
        " static const DOUBLE_LIT = 1.5;",
        " static const BOOL_LIT = true;",
        " static const STRING_LIT = 'Hello';",
        " static const BOP4_0 = 5 % INT_LIT;",
        " static const BOP4_1 = INT_LIT % 5;",
        " static const BOP4_2 = 5.0 % DOUBLE_LIT;",
        " static const BOP4_3 = DOUBLE_LIT % 5.0;",
        " static const BOP5_0 = 0x80 & 0x04;",
        " static const BOP5_1 = 0x80 | 0x04;",
        " static const BOP5_2 = 0x80 << 0x04;",
        " static const BOP5_3 = 0x80 >> 0x04;",
        " static const BOP5_4 = 0x80 ~/ 0x04;",
        " static const BOP5_5 = DOUBLE_LIT ~/ DOUBLE_LIT;",
        " static const BOP5_6 = 0x80 ^ 0x04;",
        " static const BOP6 = BOOL_LIT && true;",
        " static const BOP7 = false || BOOL_LIT;",
        " static const BOP8 = STRING_LIT == 'World!';",
        " static const BOP9 = 'Hello' != STRING_LIT;",
        " static const BOP10 = INT_LIT === INT_LIT_REF;",
        " static const BOP11 = BOOL_LIT !== true;",
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
        " static const BOP1 = A.foo() * 1;",
        " static const BOP2 = 1 * A.foo();",
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
        " static const BOP1 = 2 < A.foo();",
        " static const BOP2 = A.foo() < 2;",
        " static const BOP3 = A.foo();",
        " static const BOP4 = A.bar();",
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
        " static const BOP1 = 0x80 & 2.0;",
        " static const BOP2 = 2.0 & 0x80;",
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
        " static const BOP3 = 45 && true;",
        " static const BOP4 = true || 45;",
        " static const BOP5 = true && A.foo();",
        " static const BOP6 = A.foo() && false;",
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
        " static const OBJECT_LIT = const B();",
        " static const INT_LIT = 1;",
        " static const STRING_LIT = 'true';",
        " static const BOP1 = STRING_LIT && true;",
        " static const BOP2 = false || STRING_LIT;",
        " static const BOP3 = 59 == OBJECT_LIT;",
        " static const BOP4 = OBJECT_LIT != 59;",
        " static const BOP5 = INT_LIT === OBJECT_LIT;",
        " static const BOP6 = OBJECT_LIT !== true;",
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
        "  const a = const A();", // Constant constructor
        "}"));
  }

  public void testConstantConstructorAssign2() {
    // Negative tests
    resolveAndTestCtConst(Joiner.on("\n").join(
        "class Object {}",
        "class A {",
        "  const A();",
        "  const a = new A();", // Error: not a constant constructor
        "}"),
        ResolverErrorCode.EXPECTED_CONSTANT_EXPRESSION);
  }

  public void testConstantLiteralAssign1() {
    resolveAndTestCtConst(Joiner.on("\n").join(
        "class Object {}",
        "class A {",
        "  const b = true;",
        "  const s = 'apple';", // string literal
        "  const i = 1;", // integer literal
        "  const d = 3.3;", // double literal
        "  const h = 0xf;", // hex literal
        "  const n = null;", // null
        "}"));
  }

  public void testConstantLiteralAssign2() {
    resolveAndTestCtConst(Joiner.on("\n").join(
        "class Object {}",
        "class A {",
        "  foo() { return 'Eve';}",
        "  const person = 'earthling';",
        "  const s = 'Hello ${foo()}!';",
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
        "  const aList = const[1, 2, 3];", // array literal
        "  const map = const { '1': 'one', '2': 'banana' };", // map literal
        "  const val = aList[2];",
        "}"));
  }

  public void testConstantTypedLiteralAssign2() {
    resolveAndTestCtConst(Joiner.on("\n").join(
        "class Object {}",
        "class List<T> {}",
        "class A {",
        "  // array literal not const",
        "  const aList= [1, 2, 3];",
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
        "  const aList = const [foo(), 2, 3];",
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
        "  const aMap = { '1': 'one', '2': 'banana' };",
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
        "  const String s = 'apple';",
        "  // map literal contains non-const member",
        "  const map = const { '1': foo(), '2': 'banana' };",
        "  const stringInterp = 'It was that woman who gave me the ${s}';",
        "}"),
        ResolverErrorCode.EXPECTED_CONSTANT_EXPRESSION);
  }

  public void testConstantUnaryExpression1() {
    resolveAndTestCtConst(Joiner.on("\n").join(
        "class Object {}",
        "class A {",
        "  static const BOOL_LIT = true;",
        "  static const UOP1_0 = !BOOL_LIT;",
        "  static const UOP1_1 = BOOL_LIT || !true;",
        "  static const UOP1_2 = !BOOL_LIT || true;",
        "  static const UOP1_3 = !(BOOL_LIT && true);",
        "}"));
  }

  public void testConstantUnaryExpression2() {
    resolveAndTestCtConst(Joiner.on("\n").join(
        "class Object {}",
        "class A {",
        "  static const BOOL_LIT = true;",
        "  static const INT_LIT = 123;",
        "  static const DOUBLE_LIT = 12.3;",
        "  static const UOP2_0 = ~0xf0;",
        "  static const UOP2_1 = ~INT_LIT;",
        "  static const UOP2_2 = ~INT_LIT & 123;",
        "  static const UOP2_3 = ~(INT_LIT | 0xff);",
        "}"));
  }

  public void testConstantUnaryExpression3() {
    resolveAndTestCtConst(Joiner.on("\n").join(
        "class Object {}",
        "class A {",
        "  static const INT_LIT = 123;",
        "  static const DOUBLE_LIT = 12.3;",
        "  static const UOP3_0 = -0xf0;",
        "  static const UOP3_1 = -INT_LIT;",
        "  static const UOP3_2 = -INT_LIT + 123;",
        "  static const UOP3_3 = -(INT_LIT * 0xff);",
        "  static const UOP3_4 = -0xf0;",
        "  static const UOP3_5 = -DOUBLE_LIT;",
        "  static const UOP3_6 = -DOUBLE_LIT + 123;",
        "  static const UOP3_7 = -(DOUBLE_LIT * 0xff);",
        "}"));
  }

  public void testConstantUnaryExpression4() {
    resolveAndTestCtConst(Joiner.on("\n").join(
        "class Object {}",
        "class int {}",
        "class A {",
        "  // Unary expression",
        "  static const BOOL_LIT = true;",
        "  static int foo() { return 3; }",
        "  static const UOP1 = !5;",
        "  static const UOP2 = !foo();",
        "  static const UOP3 = !(5);",
        "  static const UOP4 = !(foo());",
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
        "  static const F = 1;",
        "}",
        "class B {",
        "  const i = 1;",
        "  const j = i;", // variable that is a compile-time constant
        "  const k = A.F;", // variable that is a compile-time constant
        "}"));
  }

  public void testConstantVariableAssign2() {
    resolveAndTestCtConst(Joiner.on("\n").join(
        "class Object {}",
        "class A {",
        " static foo() {return 1;}",
        " const i = foo();",  // Error: not a constant integer
        "}"),
        ResolverErrorCode.EXPECTED_CONSTANT_EXPRESSION);
  }

  public void testConstantVariableAssign3() {
      // Part of the regular resolver pass
      resolveAndTest(Joiner.on("\n").join(
          "class Object {}",
          "class A {",
          "  const foo;",
          "}"),
          ResolverErrorCode.CONST_REQUIRES_VALUE);
  }

  public void testForwardLookupExpressions() {
    resolveAndTestCtConst(Joiner.on("\n").join(
        "class Object {}",
        "class A {",
        "  const value1 = value2 * 2;",
        "  const value2 = value3 * 4;",
        "  const value3 = 8;",
        "}"));
  }

  public void testInvalidDefaultParameterWithField() {
    resolveAndTestCtConstExpectErrors(
        Joiner.on("\n").join(
            "class Object {}",
            "class Function {}",
            "Function get topLevelGetter => () {};",
            "topLevel([var x = topLevelGetter]) { x(); }",
            "main() { topLevel(); }"),
        errEx(ResolverErrorCode.EXPECTED_CONSTANT_EXPRESSION, 4, 19, 14),
        errEx(ResolverErrorCode.EXPECTED_CONSTANT_EXPRESSION, 3, 1, 37));
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
            "  const int value1 = (1 << 5) - 1;",
            "  const int value2 = value1 & 0xFFFF;",
            "  const int value3 = (1 << 5) + 1;",
            "  const int value4 = value3 & 0xFFFF;",
            "  const int value5 = (1 << 5) * 1;",
            "  const int value6 = value5 & 0xFFFF;",            
            "  const int value7 = (1 << 5) / 1;",
            "  const int value8 = value7 & 0xFFFF;",                        
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
            "  const double value1 = (1.0 * 5.0) - 1.0;",
            "  const double value2 = value1 + 99.0;",
            "  const double value3 = (1.0 * 5.0) + 1.0;",
            "  const double value4 = value3 * 99.0;",
            "  const double value5 = (1.0 * 5.0) * 1.0;",
            "  const double value6 = value5 * 99.0;",            
            "  const double value7 = (1.0 * 5.0) / 1.0;",
            "  const double value8 = value7 * 99.0;",                        
            "}"));    
  }  
  
  /**
   * Mixing doubles and ints in arithmetic should result in a double value.
   * Not explicitly called out for in the spec yet, but this is the runtime behavior.
   */
  public void testParenthizedMathExpressions3() {
    resolveAndTestCtConstExpectErrors(
        Joiner.on("\n").join(    
            "class Object {}",
            "interface double {}",
            "class A {",
            "  const double value1 = (1 * 5) - 1.0;",
            "  const double value2 = value1 + 99.0;",
            "  const double value3 = (1 * 5) + 1.0;",
            "  const double value4 = value3 * 99.0;",
            "  const double value5 = (1 * 5) * 1.0;",
            "  const double value6 = value5 * 99.0;",            
            "  const double value7 = (1 * 5) / 1.0;",
            "  const double value8 = value7 * 99.0;",                        
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
            "  const int value1 = ('Invalid') - 1;",
            "  const int value2 = value1 & 0xFFFF;",
            "}"),
            errEx(ResolverErrorCode.EXPECTED_CONSTANT_EXPRESSION_NUMBER, 4, 22, 11),
            // Unfortunately, the CTConst analyzer reports the same error twice 
            // because value1 is analyzed twice, once for original assignment, and a
            // second time when used in the RHS of the value2 definition.
            errEx(ResolverErrorCode.EXPECTED_CONSTANT_EXPRESSION_NUMBER, 4, 22, 11),
            errEx(ResolverErrorCode.EXPECTED_CONSTANT_EXPRESSION_INT, 5, 22, 6));
    
    resolveAndTestCtConstExpectErrors(
        Joiner.on("\n").join(            
            "class Object {}",
            "interface int {}",                             
            "class A {",
            "  const int value3 = ('Invalid') + 1;",
            "  const int value4 = value3 & 0xFFFF;",
            "}"),
            errEx(ResolverErrorCode.EXPECTED_CONSTANT_EXPRESSION_STRING, 4, 36, 1),
            errEx(ResolverErrorCode.EXPECTED_CONSTANT_EXPRESSION_STRING, 4, 36, 1),
            errEx(ResolverErrorCode.EXPECTED_CONSTANT_EXPRESSION_INT, 5, 22, 6));
    
    resolveAndTestCtConstExpectErrors(
        Joiner.on("\n").join(            
            "class Object {}",
            "interface int {}",
            "class A {",                             
            "  const int value5 = ('Invalid') * 1;",
            "  const int value6 = value5 & 0xFFFF;",            
            "}"),
            errEx(ResolverErrorCode.EXPECTED_CONSTANT_EXPRESSION_NUMBER, 4, 22, 11),
            errEx(ResolverErrorCode.EXPECTED_CONSTANT_EXPRESSION_NUMBER, 4, 22, 11),
            errEx(ResolverErrorCode.EXPECTED_CONSTANT_EXPRESSION_INT, 5, 22, 6));            
                             
    resolveAndTestCtConstExpectErrors(
        Joiner.on("\n").join(                
            "class Object {}",
            "interface int {}",
            "class A {",
            "  const int value7 = ('Invalid') / 1;",
            "  const int value8 = value7 & 0xFFFF;",                        
            "}"),
            errEx(ResolverErrorCode.EXPECTED_CONSTANT_EXPRESSION_NUMBER, 4, 22, 11),
            errEx(ResolverErrorCode.EXPECTED_CONSTANT_EXPRESSION_NUMBER, 4, 22, 11),
            errEx(ResolverErrorCode.EXPECTED_CONSTANT_EXPRESSION_INT, 5, 22, 6));            
  }
}
