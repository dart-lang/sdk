// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.parser;

import com.google.common.base.Joiner;
import com.google.dart.compiler.DartCompilerListener;
import com.google.dart.compiler.DartSourceTest;
import com.google.dart.compiler.ast.DartArrayLiteral;
import com.google.dart.compiler.ast.DartBinaryExpression;
import com.google.dart.compiler.ast.DartClass;
import com.google.dart.compiler.ast.DartComment;
import com.google.dart.compiler.ast.DartExprStmt;
import com.google.dart.compiler.ast.DartExpression;
import com.google.dart.compiler.ast.DartField;
import com.google.dart.compiler.ast.DartFieldDefinition;
import com.google.dart.compiler.ast.DartFunctionExpression;
import com.google.dart.compiler.ast.DartIdentifier;
import com.google.dart.compiler.ast.DartIntegerLiteral;
import com.google.dart.compiler.ast.DartMapLiteral;
import com.google.dart.compiler.ast.DartMethodDefinition;
import com.google.dart.compiler.ast.DartNode;
import com.google.dart.compiler.ast.DartPropertyAccess;
import com.google.dart.compiler.ast.DartStatement;
import com.google.dart.compiler.ast.DartStringInterpolation;
import com.google.dart.compiler.ast.DartStringLiteral;
import com.google.dart.compiler.ast.DartTryStatement;
import com.google.dart.compiler.ast.DartTypeExpression;
import com.google.dart.compiler.ast.DartTypeNode;
import com.google.dart.compiler.ast.DartUnaryExpression;
import com.google.dart.compiler.ast.DartUnit;
import com.google.dart.compiler.ast.DartVariableStatement;

import java.util.List;

public class SyntaxTest extends AbstractParserTest {

  public void test_getter() {
    parseUnit("getter.dart", Joiner.on("\n").join(
        "class G {",
        "  // Old getter syntax",
        "  int get g1() => 1;",
        "  // New getter syntax",
        "  int get g2 => 2;",
        "}"));
  }

  public void test_identifier_as() {
    parseUnit("identifier.dart", Joiner.on("\n").join(
        "class G {",
        "  int as = 0;",
        "}"));
  }

  public void test_index_literalMap() {
    parseUnit("test.dart", Joiner.on('\n').join(
        "main() {",
        "  try { {'1' : 1, '2' : 2}['1']++; } catch(var e) {}",
        "}"));
  }

  public void test_setter() {
    parseUnit("setter.dart", Joiner.on("\n").join(
        "class G {",
        "  void set g1(int v) {}",
        "}"));
  }

  public void test_cascade() {
    parseUnit("cascade.dart", Joiner.on("\n").join(
        "class C {",
        "  var f = g..m1()..m2()..f.a;",
        "  var f = g..[3].x()..y()();",
        "}"));
  }

  public void test_functionExpression_asStatement() {
    DartUnit unit = parseUnit("function.dart", Joiner.on("\n").join(
        "main() {",
        "  () {};",
        "}"
    ));
    assertNotNull(unit);
    assertEquals(1, unit.getTopLevelNodes().size());
    DartMethodDefinition function = (DartMethodDefinition) unit.getTopLevelNodes().get(0);
    assertNotNull(function);
    DartStatement statement = function.getFunction().getBody().getStatements().get(0);
    assertTrue(statement instanceof DartExprStmt);
    DartExpression expression = ((DartExprStmt) statement).getExpression();
    assertTrue(expression instanceof DartFunctionExpression);
  }

  public void test_functionExpression_inIsExpression() {
    DartUnit unit = parseUnit("function.dart", Joiner.on("\n").join(
        "main() {",
        "  (p) {} is String;",
        "}"
    ));
    assertNotNull(unit);
    assertEquals(1, unit.getTopLevelNodes().size());
    DartMethodDefinition function = (DartMethodDefinition) unit.getTopLevelNodes().get(0);
    assertNotNull(function);
    DartStatement statement = function.getFunction().getBody().getStatements().get(0);
    assertTrue(statement instanceof DartExprStmt);
    DartExpression expression = ((DartExprStmt) statement).getExpression();
    assertTrue(expression instanceof DartBinaryExpression);
    DartExpression lhs = ((DartBinaryExpression) expression).getArg1();
    assertTrue(lhs instanceof DartFunctionExpression);
  }

  public void test_const() {
    DartUnit unit = parseUnit(getName() + ".dart", makeCode(
        "// filler filler filler filler filler filler filler filler filler filler",
        "const T1 = 1;",
        "final T2 = 1;",
        "class A {",
        "  const F1 = 2;",
        "  static final F2 = 2;",
        "}"));
    // T1
    {
      DartFieldDefinition fieldDefinition = (DartFieldDefinition) unit.getTopLevelNodes().get(0);
      DartField field = fieldDefinition.getFields().get(0);
      assertEquals("T1", field.getName().getName());
      assertEquals(true, field.getModifiers().isConstant());
      assertEquals(false, field.getModifiers().isStatic());
      assertEquals(true, field.getModifiers().isFinal());
    }
    // T2
    {
      DartFieldDefinition fieldDefinition = (DartFieldDefinition) unit.getTopLevelNodes().get(1);
      DartField field = fieldDefinition.getFields().get(0);
      assertEquals("T2", field.getName().getName());
      assertEquals(false, field.getModifiers().isConstant());
      assertEquals(false, field.getModifiers().isStatic());
      assertEquals(true, field.getModifiers().isFinal());
    }
    // A
    {
      DartClass classA = (DartClass) unit.getTopLevelNodes().get(2);
      // F1
      {
        DartFieldDefinition fieldDefinition = (DartFieldDefinition) classA.getMembers().get(0);
        DartField field = fieldDefinition.getFields().get(0);
        assertEquals("F1", field.getName().getName());
        assertEquals(true, field.getModifiers().isConstant());
        assertEquals(false, field.getModifiers().isStatic());
        assertEquals(true, field.getModifiers().isFinal());
      }
      // F2
      {
        DartFieldDefinition fieldDefinition = (DartFieldDefinition) classA.getMembers().get(1);
        DartField field = fieldDefinition.getFields().get(0);
        assertEquals("F2", field.getName().getName());
        assertEquals(false, field.getModifiers().isConstant());
        assertEquals(true, field.getModifiers().isStatic());
        assertEquals(true, field.getModifiers().isFinal());
      }
    }
  }

  /**
   * There was bug when "identA.identB" always considered as constructor declaration. But it can be
   * constructor only if "identA" is name of enclosing class.
   * <p>
   * http://code.google.com/p/dart/issues/detail?id=513
   */
  public void testQualifiedReturnType() {
    DartUnit unit = parseUnit("QualifiedReturnTypeB.dart");
    assertEquals(
        Joiner.on("\n").join(
            "// unit QualifiedReturnTypeB.dart",
            "library test;",
            "import \"QualifiedReturnTypeA.dart\" as pref;",
            "class A {",
            "",
            "  pref.A foo() {",
            "    return new pref.A();",
            "  }",
            "}"),
        unit.toSource().trim());
    DartClass classB = (DartClass) unit.getTopLevelNodes().get(0);
    DartMethodDefinition fooMethod = (DartMethodDefinition) classB.getMembers().get(0);
    DartTypeNode fooReturnType = fooMethod.getFunction().getReturnTypeNode();
    assertEquals(true, fooReturnType.getIdentifier() instanceof DartPropertyAccess);
  }

  @Override
  public void testStrings() {
    DartUnit unit = parseUnit("Strings.dart");

    // Inspect the first method and check that the strings were
    // parsed correctly
    List<DartNode> nodes = unit.getTopLevelNodes();
    assertEquals(1, nodes.size());
    DartClass clazz = (DartClass) nodes.get(0);
    List<DartNode> members = clazz.getMembers();
    assertEquals(1, members.size());
    DartMethodDefinition m = (DartMethodDefinition) members.get(0);
    assertEquals("method", m.getName().toString());
    List<DartStatement> body = m.getFunction().getBody().getStatements();

    String[] expectedStrings = new String[] {
        "a simple constant",
        "a simple constant",
        "an escaped quote \".",
        "an escaped quote \'.",
        "a new \n line",
        "a new \n line",
        "    multiline 1\n    multiline 2\n    ",
        "    multiline 1\n    multiline 2\n    ",
        "multiline 1\n    multiline 2\n    ",
        "multiline 1\n    multiline 2\n    "};
    assertEquals(expectedStrings.length + 1, body.size());
    assertTrue(body.get(0) instanceof DartVariableStatement);
    for (int i = 0; i < expectedStrings.length; i++) {
      DartStatement s = body.get(i + 1);
      assertTrue(s instanceof DartExprStmt);
      DartExprStmt es = (DartExprStmt) s;
      DartExpression e = es.getExpression();
      assertTrue(e instanceof DartBinaryExpression);
      e = ((DartBinaryExpression) e).getArg2();
      assertTrue(e instanceof DartStringLiteral);
      assertEquals(expectedStrings[i], ((DartStringLiteral) e).getValue());
    }
  }

  @Override
  public void testStringsErrors() {
    parseUnitErrors("StringsErrorsNegativeTest.dart",
        "Unexpected token 'ILLEGAL'", 7, 13,
        "Unexpected token 'ILLEGAL'", 9, 9,
        "Unexpected token 'ILLEGAL'", 11, 9);
  }

  public void testNullAssign() {
    String sourceCode = "= 123;";
    try {
      DartSourceTest dartSrc = new DartSourceTest(getName(), sourceCode, null);
      DartParser parser = makeParser(dartSrc, sourceCode, new DartCompilerListener.Empty());
      parser.parseExpression();
    }
    catch(Exception e) {
      fail("unexpected exception " + e);
    }
  }

  public void testFactoryInitializerError() {
    parseUnitErrors("FactoryInitializersNegativeTest.dart",
                    "Unexpected token ':' (expected '{')", 10, 22,
                    "Unexpected token '{' (expected ';')", 10, 35);
  }

  public void testTryCatch () {
    DartUnit unit = parseUnit("TryCatch.dart");

    List<DartNode> nodes = unit.getTopLevelNodes();
    assertEquals(7, nodes.size());

    DartTryStatement tryCatch;
    DartMethodDefinition a = (DartMethodDefinition) nodes.get(2);
    assertEquals("a", ((DartIdentifier)a.getName()).getName());
    tryCatch = (DartTryStatement) a.getFunction().getBody().getStatements().get(0);
    assertEquals(1, tryCatch.getCatchBlocks().size());
    assertNotNull(tryCatch.getFinallyBlock());

    DartMethodDefinition b = (DartMethodDefinition) nodes.get(3);
    assertEquals("b", ((DartIdentifier)b.getName()).getName());
    tryCatch = (DartTryStatement) b.getFunction().getBody().getStatements().get(0);
    assertEquals(1, tryCatch.getCatchBlocks().size());
    assertNull(tryCatch.getFinallyBlock());

    DartMethodDefinition c = (DartMethodDefinition) nodes.get(4);
    assertEquals("c", ((DartIdentifier)c.getName()).getName());
    tryCatch = (DartTryStatement) c.getFunction().getBody().getStatements().get(0);
    assertEquals(0, tryCatch.getCatchBlocks().size());
    assertNotNull(tryCatch.getFinallyBlock());

    DartMethodDefinition d = (DartMethodDefinition) nodes.get(5);
    assertEquals("d", ((DartIdentifier)d.getName()).getName());
    tryCatch = (DartTryStatement) d.getFunction().getBody().getStatements().get(0);
    assertEquals(2, tryCatch.getCatchBlocks().size());
    assertNull(tryCatch.getFinallyBlock());

    DartMethodDefinition e = (DartMethodDefinition) nodes.get(6);
    assertEquals("e", ((DartIdentifier)e.getName()).getName());
    tryCatch = (DartTryStatement) e.getFunction().getBody().getStatements().get(0);
    assertEquals(2, tryCatch.getCatchBlocks().size());
    assertNotNull(tryCatch.getFinallyBlock());

    parseUnitErrors("TryCatchNegative.dart",
      ParserErrorCode.CATCH_OR_FINALLY_EXPECTED, 8, 3);
  }

//  public void test_tryOn_catch() {
//    parseUnit("tryOn.dart", "f() {try {} catch (e) {}}");
//  }

//  public void test_tryOn_catchStack() {
//    parseUnit("tryOn.dart", "f() {try {} catch (e, s) {}}");
//  }

//  public void test_tryOn_on1Catch1() {
//    parseUnit("tryOn.dart", Joiner.on("\n").join(
//        "class Object {}",
//        "class E {}",
//        "f() {try {} on E catch (e) {}}"));
//  }

//  public void test_tryOn_on2Catch2() {
//    parseUnit("tryOn.dart", Joiner.on("\n").join(
//        "class Object {}",
//        "class E1 {}",
//        "class E2 {}",
//        "f() {try {} on E1 catch (e1) {} on E2 catch (e2) {}}"));
//  }

//  public void test_tryOn_on2Catch3() {
//    parseUnit("tryOn.dart", Joiner.on("\n").join(
//        "class Object {}",
//        "class E1 {}",
//        "class E2 {}",
//        "f() {try {} on E1 catch (e1) {} on E2 catch (e2) {} catch (e3) {}}"));
//  }

//  public void test_tryOn_on2Catch2Finally() {
//    parseUnit("tryOn.dart", Joiner.on("\n").join(
//        "class Object {}",
//        "class E1 {}",
//        "class E2 {}",
//        "f() {try {} on E1 catch (e1) {} on E2 catch (e2) {} finally {}}"));
//  }

  public void testArrayLiteral() {
    DartUnit unit = parseUnit("phony_array_literal.dart", "var x = <int>[1,2,3];");
    List<DartNode> nodes = unit.getTopLevelNodes();
    assertEquals(1, nodes.size());
    DartFieldDefinition f = (DartFieldDefinition)nodes.get(0);
    DartField fieldX = f.getFields().get(0);
    DartArrayLiteral array = (DartArrayLiteral) fieldX.getValue();
    assertEquals(3, array.getExpressions().size());
    assertEquals(1, ((DartIntegerLiteral)array.getExpressions().get(0)).getValue().intValue());
    assertEquals(2, ((DartIntegerLiteral)array.getExpressions().get(1)).getValue().intValue());
    assertEquals(3, ((DartIntegerLiteral)array.getExpressions().get(2)).getValue().intValue());
  }

  public void testAs() {
    DartUnit unit = parseUnit("phony_cast.dart", "var x = 3 as int;");
    List<DartNode> nodes = unit.getTopLevelNodes();
    assertEquals(1, nodes.size());
    DartFieldDefinition f = (DartFieldDefinition)nodes.get(0);
    DartField fieldX = f.getFields().get(0);
    DartBinaryExpression cast = (DartBinaryExpression) fieldX.getValue();
    assertTrue(cast.getArg1() instanceof DartIntegerLiteral);
    assertEquals(Token.AS, cast.getOperator());
    assertTrue(cast.getArg2() instanceof DartTypeExpression);
  }

  public void testMapLiteral() {
    DartUnit unit = parseUnit("phony_map_literal.dart", "var x = <int>{'a':1,'b':2,'c':3};");
    List<DartNode> nodes = unit.getTopLevelNodes();
    assertEquals(1, nodes.size());
    DartFieldDefinition f = (DartFieldDefinition)nodes.get(0);
    DartField fieldX = f.getFields().get(0);
    DartMapLiteral map = (DartMapLiteral) fieldX.getValue();
    assertEquals(3, map.getEntries().size());
    assertEquals(1, ((DartIntegerLiteral) (map.getEntries().get(0)).getValue()).getValue()
        .intValue());
  }
  public void testNestedParameterizedTypes1() {
    // token >>> is handled specially
    DartUnit unit = parseUnit ("phony_param_type1.dart",
                               Joiner.on("\n").join(
                                   "class A<K> {",
                                   "  A<A<A<K>>> member;",
                                   "}"));
    List<DartNode> nodes = unit.getTopLevelNodes();
    assertEquals(1, nodes.size());
  }

  public void testNestedParameterizedTypes2() {
    // token >> is handled specially
    DartUnit unit = parseUnit ("phony_param_type1.dart",
                               Joiner.on("\n").join(
                                   "class A<K> {",
                                   "  A<A<K>> member;",
                                   "}"));
    List<DartNode> nodes = unit.getTopLevelNodes();
    assertEquals(1, nodes.size());
  }

  public void testMethodDefinition1() {
    DartUnit unit = parseUnit ("phony_method_definition1.dart",
                               Joiner.on("\n").join(
                                   "class A {",
                                   "  pref.A foo() {",
                                   "    return new pref.A();",
                                   "  }",
                                   "}"));
                           List<DartNode> nodes = unit.getTopLevelNodes();
                           assertEquals(1, nodes.size());
  }

  public void testMultipleLabels() {
    parseUnit ("multiple_labels.dart",
      Joiner.on("\n").join(
        "class A {",
        "  void foo() {",
        "    a: b: foo();",
        "  }",
        "}"));
  }

  public void testAdjacentStrings1() {
    DartUnit unit = parseUnit ("phony_adjacent_strings_1.dart",
                               Joiner.on("\n").join(
                                   "var a = \"\" \"\";",
                                   "var b = \"1\" \"2\" \"3\";"));
    List<DartNode> nodes = unit.getTopLevelNodes();
    assertEquals(2, nodes.size());
    DartStringLiteral varA = (DartStringLiteral)((DartFieldDefinition)nodes.get(0))
        .getFields().get(0).getValue();
    assertEquals("", varA.getValue());
    DartStringLiteral varB = (DartStringLiteral)((DartFieldDefinition)nodes.get(1))
        .getFields().get(0).getValue();
    assertEquals("123", varB.getValue());

  }

  public void testAdjacentStrings2() {
    DartUnit unit = parseUnit ("phony_adjacent_strings_2.dart",
                               Joiner.on("\n").join(
                               "var c = \"hello\" \"${world}\";",
                               "var d = \"${hello}\" \"world\";",
                               "var e = \"${hello}\" \"${world}\";"));
    List<DartNode> nodes = unit.getTopLevelNodes();
    assertEquals(3, nodes.size());
    DartStringInterpolation varC = (DartStringInterpolation)((DartFieldDefinition)nodes.get(0))
        .getFields().get(0).getValue();

    List<DartStringLiteral> strings = varC.getStrings();
    assertEquals(3, strings.size());
    assertEquals("hello", strings.get(0).getValue());
    assertEquals("", strings.get(1).getValue());
    assertEquals("", strings.get(2).getValue());
    List<DartExpression> expressions = varC.getExpressions();
    assertEquals(2, expressions.size());
    assertEquals("", ((DartStringLiteral)expressions.get(0)).getValue());
    DartIdentifier expr = (DartIdentifier)expressions.get(1);
    assertEquals("world", expr.getName());

    DartStringInterpolation varD = (DartStringInterpolation)((DartFieldDefinition)nodes.get(1))
        .getFields().get(0).getValue();
    strings = varD.getStrings();
    assertEquals(3, strings.size());
    assertEquals("", strings.get(0).getValue());
    assertEquals("", strings.get(1).getValue());
    assertEquals("world", strings.get(2).getValue());
    expressions = varD.getExpressions();
    assertEquals(2, expressions.size());
    expr = (DartIdentifier)expressions.get(0);
    assertEquals("hello", expr.getName());
    assertEquals("", ((DartStringLiteral)expressions.get(1)).getValue());

    DartStringInterpolation varE = (DartStringInterpolation)((DartFieldDefinition)nodes.get(2))
        .getFields().get(0).getValue();
    strings = varE.getStrings();
    assertEquals(4, strings.size());
    assertEquals("", strings.get(0).getValue());
    assertEquals("", strings.get(1).getValue());
    assertEquals("", strings.get(2).getValue());
    assertEquals("", strings.get(3).getValue());
    expressions = varE.getExpressions();
    assertEquals(3, expressions.size());
    expr = (DartIdentifier)expressions.get(0);
    assertEquals("hello", expr.getName());
    assertEquals("", ((DartStringLiteral)expressions.get(1)).getValue());
    expr = (DartIdentifier)expressions.get(2);
    assertEquals("world", expr.getName());
  }

  public void testAdjacentStrings3() {
    DartUnit unit = parseUnit ("phony_adjacent_strings_2.dart",
                               Joiner.on("\n").join(
                               "var f = \"hello\" \"${world}\" \"!\";",
                               "var g = \"${hello}\" \"world\" \"!\";"));
    List<DartNode> nodes = unit.getTopLevelNodes();
    assertEquals(2, nodes.size());
    DartStringInterpolation varF = (DartStringInterpolation)((DartFieldDefinition)nodes.get(0))
        .getFields().get(0).getValue();

    List<DartStringLiteral> strings = varF.getStrings();
    assertEquals(4, strings.size());
    assertEquals("hello", strings.get(0).getValue());
    assertEquals("", strings.get(1).getValue());
    assertEquals("", strings.get(2).getValue());
    assertEquals("!", strings.get(3).getValue());
    List<DartExpression> expressions = varF.getExpressions();
    assertEquals(3, expressions.size());
    assertEquals("", ((DartStringLiteral)expressions.get(0)).getValue());
    DartIdentifier expr = (DartIdentifier)expressions.get(1);
    assertEquals("world", expr.getName());
    assertEquals("", ((DartStringLiteral)expressions.get(2)).getValue());

    DartStringInterpolation varG = (DartStringInterpolation)((DartFieldDefinition)nodes.get(1))
        .getFields().get(0).getValue();
    strings = varG.getStrings();
    assertEquals(4, strings.size());
    assertEquals("", strings.get(0).getValue());
    assertEquals("", strings.get(1).getValue());
    assertEquals("world", strings.get(2).getValue());
    assertEquals("!", strings.get(3).getValue());
    expressions = varG.getExpressions();
    assertEquals(3, expressions.size());
    expr = (DartIdentifier)expressions.get(0);
    assertEquals("hello", expr.getName());
    assertEquals("", ((DartStringLiteral)expressions.get(1)).getValue());
    assertEquals("", ((DartStringLiteral)expressions.get(2)).getValue());
  }

  public void testPseudokeywordMethodsAndFields() {
    DartUnit unit = parseUnit("phony_pseudokeyword_methods.dart",
        Joiner.on("\n").join(
            "class A { ",
            "  int get;",
            "  var set;",
            "  final operator;",
            "}",
            "class B {",
            "  var get = 1;",
            "  int set = 1;",
            "  final int operator = 1;",
            "}",
            "class C {",
            "  var get = 1;",
            "  int set = 1;",
            "  final operator = 1;",
            "}",
            "class D {",
            "  int get = 1;",
            "  final int set = 1;",
            "  var operator = 1;",
            "}",
            "class E {",
            "  int get() { }",
            "  void set() { }",
            "  operator() { }",
            "}",
            "class F {",
            "  operator negate () { }",
            "  operator + (arg) { }",
            "  operator [] (arg) { }",
            "  operator []= (arg, arg){ }",
            "}"));

    DartClass A = (DartClass)unit.getTopLevelNodes().get(0);
    DartFieldDefinition A_get = (DartFieldDefinition)A.getMembers().get(0);
    assertEquals("get", A_get.getFields().get(0).getName().getName());
    DartFieldDefinition A_set = (DartFieldDefinition)A.getMembers().get(1);
    assertEquals("set", A_set.getFields().get(0).getName().getName());
    DartFieldDefinition A_operator = (DartFieldDefinition)A.getMembers().get(2);
    assertEquals("operator", A_operator.getFields().get(0).getName().getName());
    DartClass B = (DartClass)unit.getTopLevelNodes().get(1);
    DartFieldDefinition B_get = (DartFieldDefinition)B.getMembers().get(0);
    assertEquals("get", B_get.getFields().get(0).getName().getName());
    DartFieldDefinition B_set = (DartFieldDefinition)B.getMembers().get(1);
    assertEquals("set", B_set.getFields().get(0).getName().getName());
    DartFieldDefinition B_operator = (DartFieldDefinition)B.getMembers().get(2);
    assertEquals("operator", B_operator.getFields().get(0).getName().getName());
    DartClass C = (DartClass)unit.getTopLevelNodes().get(2);
    DartFieldDefinition C_get = (DartFieldDefinition)C.getMembers().get(0);
    assertEquals("get", C_get.getFields().get(0).getName().getName());
    DartFieldDefinition C_set = (DartFieldDefinition)C.getMembers().get(1);
    assertEquals("set", C_set.getFields().get(0).getName().getName());
    DartFieldDefinition C_operator = (DartFieldDefinition)C.getMembers().get(2);
    assertEquals("operator", C_operator.getFields().get(0).getName().getName());
    DartClass D = (DartClass)unit.getTopLevelNodes().get(3);
    DartFieldDefinition D_get = (DartFieldDefinition)D.getMembers().get(0);
    assertEquals("get", D_get.getFields().get(0).getName().getName());
    DartFieldDefinition D_set = (DartFieldDefinition)D.getMembers().get(1);
    assertEquals("set", D_set.getFields().get(0).getName().getName());
    DartFieldDefinition D_operator = (DartFieldDefinition)D.getMembers().get(2);
    assertEquals("operator", D_operator.getFields().get(0).getName().getName());
    DartClass E = (DartClass)unit.getTopLevelNodes().get(4);
    DartMethodDefinition E_get = (DartMethodDefinition)E.getMembers().get(0);
    assertEquals("get", ((DartIdentifier)E_get.getName()).getName());
    DartMethodDefinition E_set = (DartMethodDefinition)E.getMembers().get(1);
    assertEquals("set", ((DartIdentifier)E_set.getName()).getName());
    DartMethodDefinition E_operator = (DartMethodDefinition)E.getMembers().get(2);
    assertEquals("operator", ((DartIdentifier)E_operator.getName()).getName());
    DartClass F = (DartClass)unit.getTopLevelNodes().get(5);
    DartMethodDefinition F_negate = (DartMethodDefinition)F.getMembers().get(0);
    assertEquals("negate", ((DartIdentifier)F_negate.getName()).getName());
    DartMethodDefinition F_plus = (DartMethodDefinition)F.getMembers().get(1);
    assertEquals("+", ((DartIdentifier)F_plus.getName()).getName());
    DartMethodDefinition F_access = (DartMethodDefinition)F.getMembers().get(2);
    assertEquals("[]", ((DartIdentifier)F_access.getName()).getName());
    DartMethodDefinition F_access_assign = (DartMethodDefinition)F.getMembers().get(3);
    assertEquals("[]=", ((DartIdentifier)F_access_assign.getName()).getName());
  }

  public void test_super_operator() {
    DartUnit unit = parseUnit("phony_super.dart", Joiner.on("\n").join(
        "class A {",
        "  void m() {",
        "    --super;",
        "  }",
        "}"));
    List<DartNode> nodes = unit.getTopLevelNodes();
    assertEquals(1, nodes.size());
    DartClass A = (DartClass) nodes.get(0);
    DartMethodDefinition m = (DartMethodDefinition) A.getMembers().get(0);
    DartExprStmt statement = (DartExprStmt) m.getFunction().getBody().getStatements().get(0);
    DartUnaryExpression value = (DartUnaryExpression) statement.getExpression();
    assertEquals(Token.SUB, value.getOperator());
    DartUnaryExpression inner = (DartUnaryExpression) value.getArg();
    assertEquals(Token.SUB, inner.getOperator());
  }

  /**
   * Typedef and interface are top level keywords that are also valid as identifiers.
   *
   * This test helps insure that the error recovery logic in the parser that detects
   * top level keywords out of place doesn't break this functionality.
   */
  public void testTopLevelKeywordsAsIdent() {
    parseUnit("phony_pseudokeyword_methods.dart",
        Joiner.on("\n").join(
            "var interface;",
            "bool interface;",
            "final interface;",
            "interface() { }",
            "String interface() { }",
            "interface();",
            "var typedef;",
            "bool typedef;",
            "final typedef;",
            "typedef() { }",
            "String typedef() { }",
            "typedef();",
            "class A { ",
            "  var interface;",
            "  bool interface;",
            "  final interface;",
            "  interface() { }",
            "  String interface() { }",
            "  interface();",
            "  var typedef;",
            "  bool typedef;",
            "  final typedef;",
            "  typedef() { }",
            "  String typedef() { }",
            "  typedef();",
            "}",
            "method() {",
            "  var interface;",
            "  bool interface;",
            "  final interface;",
            "  interface() { }",
            "  String interface() { }",
            "  interface();",
            "  var typedef;",
            "  bool typedef;",
            "  final typedef;",
            "  typedef() { }",
            "  String typedef() { }",
            "  typedef();",
            "}"));
  }

  /**
   * We should be able to parse "static(abstract) => 42" top-level function.
   * <p>
   * http://code.google.com/p/dart/issues/detail?id=1197
   */
  public void test_staticAsFunctionName() {
    DartUnit unit = parseUnit(
        getName(),
        Joiner.on("\n").join(
            "// filler filler filler filler filler filler filler filler filler filler",
            "static(abstract) => 42;",
            ""));
    assertEquals(1, unit.getTopLevelNodes().size());
    DartMethodDefinition method = (DartMethodDefinition) unit.getTopLevelNodes().get(0);
    assertEquals("static", method.getName().toSource());
    assertEquals("abstract", method.getFunction().getParameters().get(0).getName().toSource());
  }

  /**
   * The token 'super' is valid by itself (not as a qualifier or assignment selector) in only some
   * cases.
   */
  public void testLoneSuperExpression1() {
    parseUnit("phony_lone_super_expression1.dart",
              Joiner.on("\n").join(
            "class A {",
            "  method() {",
            "    super;",
            "    super ? true : false;",
            "    true ? true : super;",
            "    true ? super : false;",
            "    if (super && true) { }",
            "    if (super || false) { }",
            "  }",
            "}"),
            ParserErrorCode.SUPER_IS_NOT_VALID_ALONE_OR_AS_A_BOOLEAN_OPERAND, 3, 5,
            ParserErrorCode.SUPER_IS_NOT_VALID_ALONE_OR_AS_A_BOOLEAN_OPERAND, 4, 5,
            ParserErrorCode.SUPER_IS_NOT_VALID_ALONE_OR_AS_A_BOOLEAN_OPERAND, 5, 19,
            ParserErrorCode.SUPER_IS_NOT_VALID_ALONE_OR_AS_A_BOOLEAN_OPERAND, 6, 12,
            ParserErrorCode.SUPER_IS_NOT_VALID_AS_A_BOOLEAN_OPERAND, 7, 9,
            ParserErrorCode.SUPER_IS_NOT_VALID_AS_A_BOOLEAN_OPERAND, 8, 9);
  }

  public void testLoneSuperExpression2() throws Exception {
    parseUnit("phony_lone_super_expression1.dart",
        Joiner.on("\n").join(
            "// filler filler filler filler filler filler filler filler filler filler",
            "class Object {}",
            "class A {",
            "  method() {",
            "    if (1 + super) { }", // error
            "    if (super + 1) { }",  // ok
            "    if (1 == super) { }", // error
            "    if (super == 1) { }",  // ok
            "    if (1 | super) { }", // error
            "    if (super | 1) { }",  // ok
            "    if (1 < super) { }", // error
            "    if (super < 1) { }",  // ok
            "    if (1 << super) { }", // error
            "    if (super << 1) { }",  // ok
            "    if (1 * super) { }", // error
            "    if (super * 1) { }",  // ok
            "    var f = -super;", // ok
            "  }",
            "}"),
            ParserErrorCode.SUPER_CANNOT_BE_USED_AS_THE_SECOND_OPERAND, 5, 13,
            ParserErrorCode.SUPER_CANNOT_BE_USED_AS_THE_SECOND_OPERAND, 7, 14,
            ParserErrorCode.SUPER_CANNOT_BE_USED_AS_THE_SECOND_OPERAND, 9, 13,
            ParserErrorCode.SUPER_CANNOT_BE_USED_AS_THE_SECOND_OPERAND, 11, 13,
            ParserErrorCode.SUPER_CANNOT_BE_USED_AS_THE_SECOND_OPERAND, 13, 14,
            ParserErrorCode.SUPER_CANNOT_BE_USED_AS_THE_SECOND_OPERAND, 15, 13);
  }

  public void testBreakOutsideLoop() throws Exception {
    parseUnit("phony_lone_super_expression1.dart",
        Joiner.on("\n").join(
            "class A {",
            "  method() {",
            "    while (true) { break; }", // ok
            "    break;",  // bad
            "    L1: break L1;", // ok
            "    while (true) { continue; }", // ok
            "    continue;", // bad
            "    L2: continue L2;", // bad
            "    while (true) { int f() { break; }; }", // bad
            "  }",
            "}"),
            ParserErrorCode.BREAK_OUTSIDE_OF_LOOP, 4, 10,
            ParserErrorCode.CONTINUE_OUTSIDE_OF_LOOP, 7, 13,
            ParserErrorCode.CONTINUE_OUTSIDE_OF_LOOP, 8, 18,
            ParserErrorCode.BREAK_OUTSIDE_OF_LOOP, 9, 35);
  }

  public void testContinueNoLabelInsideCase() throws Exception {
    parseUnit("phony_lone_super_expression1.dart",
        Joiner.on("\n").join(
            "class A {",
            "  method() {",
            "    switch(1) {",
            "      case 1: continue;", // error
            "    }",
            "    while (1) {",
            "      switch(1) {",
            "        case 1: continue;", // ok, refers to the while loop.
            "      }",
            "    }",
            "    L: switch(1) {",
            "     case 1: var result = f() { continue L; };", // bad
            "    }",
            "  }",
            "}"),
            ParserErrorCode.CONTINUE_IN_CASE_MUST_HAVE_LABEL, 4, 23,
            ParserErrorCode.CONTINUE_OUTSIDE_OF_LOOP, 12, 42);
  }

  public void testRedundantAbruptlyTermainatedCaseStatement() throws Exception {
    parseUnit("phony_reduntant_abruptly_terminated_case_statement.dart",
        Joiner.on("\n").join(
            "func () {",
            "  switch (0) {",
            "   case 0: ",
            "     return 0; ",
            "     break;", // warn dead code
            "   case 1: ",
            "     return 1; ",
            "     var foo = 1;", // warn dead code
            "   case 2:",
            "     return 2;",
            "     var bar = 2;", // warn dead code
            "     break;",    // no warning here
            "   default:",
            "     return -1;",
            "     var baz = -1;", // warn dead code
            "     break;",  // no warning here
            "  }",
            "}"),
            ParserErrorCode.UNREACHABLE_CODE_IN_CASE, 5, 6,
            ParserErrorCode.UNREACHABLE_CODE_IN_CASE, 8, 6,
            ParserErrorCode.UNREACHABLE_CODE_IN_CASE, 11, 6,
            ParserErrorCode.UNREACHABLE_CODE_IN_CASE, 15, 6);
  }

  public void testCornerCaseLabelInSwitch() throws Exception {
    // The parser used to just accept this statement.
    parseUnit("phony_reduntant_abruptly_terminated_case_statement.dart",
        Joiner.on("\n").join(
            "func () {",
            "  switch (0) {",
            "  label1: ",  // no case, default or statement follows.
            "  }",
            "}"),
            ParserErrorCode.LABEL_NOT_FOLLOWED_BY_CASE_OR_DEFAULT, 3, 9);
  }

  public void testBogusEscapedNewline() throws Exception {
    parseUnit("phony_bogus_escaped_newline.dart",
        Joiner.on("\n").join(
            "class A {",
            "  var foo = \"not really multiline\\\n",
            "\";",
            "}"),
            ParserErrorCode.UNEXPECTED_TOKEN,  2, 13,
            ParserErrorCode.EXPECTED_TOKEN,  4, 1);
  }

  public void testLabelledCaseStatements() throws Exception {
    parseUnit("phony_labelled_case_statements.dart",
        Joiner.on("\n").join(
            "method() {",
            "  switch(1) {",
            "  A: case 0:",
            "  B: C: case 1:",
            "    break;",
            "  }",
            "}"));
  }

  public void testRedirectingConstructorBody() throws Exception {
    parseUnit("phony_test_redirecting_constructor_body.dart",
        Joiner.on("\n").join(
            "class A {",
            "  A.c() {}",  // OK
            "  A.d() : this.c();", // OK
            "  A(): this.b() {}", // body not allowed
            "}"),
            ParserErrorCode.REDIRECTING_CONSTRUCTOR_CANNOT_HAVE_A_BODY, 4, 18);
  }

  public void test_missingFactoryBody() throws Exception {
    parseUnit("phony_test_missing_factory_body.dart",
        Joiner.on("\n").join(
            "class A {",
            "  abstract factory A.c();",  // error - no body
            "  A() {}",
            "}"),
            ParserErrorCode.FACTORY_CANNOT_BE_ABSTRACT, 2, 12,
            ParserErrorCode.EXPECTED_FUNCTION_STATEMENT_BODY, 2, 25);
  }

  public void test_factoryAbstractStatic() throws Exception {
  parseUnit("phony_test_factory_not_abstract.dart",
      Joiner.on("\n").join(
        "class A {",
        "  A() {}",
        "  abstract factory A.named1() { return new A();}",
        "  static factory A.named2() { return new A();}",
        "  static abstract factory A.named3() { return new A();}",
        "}"),
        ParserErrorCode.FACTORY_CANNOT_BE_ABSTRACT, 3, 12,
        ParserErrorCode.FACTORY_CANNOT_BE_STATIC, 4, 10,
        ParserErrorCode.STATIC_MEMBERS_CANNOT_BE_ABSTRACT, 5, 10,
        ParserErrorCode.FACTORY_CANNOT_BE_STATIC, 5, 19);
  }

  public void test_staticAbstractMember() throws Exception {
    parseUnit("phony_test_static_abstract_member.dart",
        Joiner.on("\n").join(
            "class A {",
            "  static abstract var foo;",
            "  static abstract bar();",
            "}"),
            ParserErrorCode.STATIC_MEMBERS_CANNOT_BE_ABSTRACT, 2, 10,
            ParserErrorCode.STATIC_MEMBERS_CANNOT_BE_ABSTRACT, 3, 10);
  }

  public void test_factoryInInterface() throws Exception {
    parseUnit("phony_test_factory_in_interface.dart",
        Joiner.on("\n").join(
            "interface A {",
            "  factory A();",
            "}"),
            ParserErrorCode.FACTORY_MEMBER_IN_INTERFACE, 2, 3,
            ParserErrorCode.EXPECTED_FUNCTION_STATEMENT_BODY, 2, 14);
  }

  public void test_AbstractVar() throws Exception {
    parseUnit("phony_test_abstract_var.dart",
        Joiner.on("\n").join(
            "class A {",
            "  abstract var a;",
            "  abstract final b;",
            "}"),
            ParserErrorCode.DISALLOWED_ABSTRACT_KEYWORD, 2, 3,
            ParserErrorCode.DISALLOWED_ABSTRACT_KEYWORD, 3, 3);
  }

  public void test_metadata_deprecated() {
    String code = makeCode(
        "// filler filler filler filler filler filler filler filler filler filler",
        "class A {",
        "  m0() {}",
        "  // @deprecated",
        "  m1() {}",
        "}",
        "");
    DartUnit unit = parseUnit(getName() + ".dart", code);
    // A
    {
      DartClass classA = (DartClass) unit.getTopLevelNodes().get(0);
      // m0()
      {
        DartMethodDefinition method = (DartMethodDefinition) classA.getMembers().get(0);
        assertEquals("m0", method.getName().toSource());
        assertEquals(false, method.getMetadata().isDeprecated());
      }
      // m1()
      {
        DartMethodDefinition method = (DartMethodDefinition) classA.getMembers().get(1);
        assertEquals("m1", method.getName().toSource());
        assertEquals(true, method.getMetadata().isDeprecated());
      }
    }
  }

  public void test_metadata_override() {
    String code = makeCode(
        "// filler filler filler filler filler filler filler filler filler filler",
        "class A {",
        "  m0() {}",
        "  // @override",
        "  m1() {}",
        "  /** Leading DartDoc comment */",
        "  // @override",
        "  m2() {}",
        "  /**",
        "   * DartDoc comment",
        "   * @override",
        "   */",
        "  m3() {}",
        "}",
        "");
    DartUnit unit = parseUnit(getName() + ".dart", code);
    // A
    {
      DartClass classA = (DartClass) unit.getTopLevelNodes().get(0);
      // m0()
      {
        DartMethodDefinition method = (DartMethodDefinition) classA.getMembers().get(0);
        assertEquals("m0", method.getName().toSource());
        assertEquals(false, method.getMetadata().isOverride());
        assertNull(method.getDartDoc());
      }
      // m1()
      {
        DartMethodDefinition method = (DartMethodDefinition) classA.getMembers().get(1);
        assertEquals("m1", method.getName().toSource());
        assertEquals(true, method.getMetadata().isOverride());
        assertNull(method.getDartDoc());
      }
      // m2()
      {
        DartMethodDefinition method = (DartMethodDefinition) classA.getMembers().get(2);
        assertEquals("m2", method.getName().toSource());
        assertEquals(true, method.getMetadata().isOverride());
        {
          DartComment dartDoc = method.getDartDoc();
          assertNotNull(dartDoc);
          assertEquals("/** Leading DartDoc comment */", getNodeSource(code, dartDoc));
        }
      }
      // m3()
      {
        DartMethodDefinition method = (DartMethodDefinition) classA.getMembers().get(3);
        assertEquals("m3", method.getName().toSource());
        assertEquals(true, method.getMetadata().isOverride());
        {
          DartComment dartDoc = method.getDartDoc();
          assertNotNull(dartDoc);
          String commentCode = getNodeSource(code, dartDoc);
          assertTrue(commentCode.contains("DartDoc comment"));
          assertTrue(commentCode.contains("@override"));
        }
      }
    }
  }

  public void test_positionalDefaultValue() throws Exception {
    parseUnit("phony_test_abstract_var.dart",
        Joiner.on("\n").join(
            "method(arg=1) {",
            "}"),
            ParserErrorCode.DEFAULT_POSITIONAL_PARAMETER, 1, 8);
  }

  public void test_abstractInInterface() throws Exception {
    parseUnit("phony_test_abstract_in_interface.dart",
        Joiner.on("\n").join(
            "interface A {",
            "  abstract var foo;",
            "  abstract bar();",
            "}"),
            ParserErrorCode.ABSTRACT_MEMBER_IN_INTERFACE, 2, 3,
            ParserErrorCode.ABSTRACT_MEMBER_IN_INTERFACE, 3, 3);
  }

  public void test_voidParameterField() throws Exception {
    parseUnit("phony_test_abstract_in_interface.dart",
        Joiner.on("\n").join(
            "method(void arg) { }",
            "void field;",
            "class C {",
            "  method(void arg) { }",
            "  void field;",
            "}"),
            ParserErrorCode.VOID_PARAMETER, 1, 8,
            ParserErrorCode.VOID_FIELD, 2, 1,
            ParserErrorCode.VOID_PARAMETER, 4, 10,
            ParserErrorCode.VOID_FIELD, 5, 3);
  }

  public void test_unexpectedTypeArgument() throws Exception {
    // This is valid code that was previously rejected.
    // Invoking a named constructor in a prefixed library should work.
    parseUnit("phony_test_unexpected_type_argument.dart",
        Joiner.on("\n").join(
            "method() {",
            "  new prefix.Type.named<T>();",
            "}"));
  }

  public void test_staticOperator() throws Exception {
    parseUnit("phony_static_operator.dart",
        Joiner.on("\n").join(
            "class C {",
            "  static operator +(arg) {}",
            "}"),
            ParserErrorCode.OPERATOR_CANNOT_BE_STATIC, 2, 10);
  }

  public void test_nonFinalStaticMemberInInterface() throws Exception {
    parseUnit("phony_non_final_static_member_in_interface.dart",
        Joiner.on("\n").join(
            "interface I {",
            "  static foo();",
            "  static var bar;",
            "}"),
            ParserErrorCode.NON_FINAL_STATIC_MEMBER_IN_INTERFACE, 2, 3,
            ParserErrorCode.NON_FINAL_STATIC_MEMBER_IN_INTERFACE, 3, 3);
  }

  public void test_invalidOperatorChaining() throws Exception {
    parseUnit("phony_invalid_operator_chaining.dart",
        Joiner.on("\n").join(
            "method() {",
            "  if (a < b < c) {}",
            "  if (a is b is c) {}",
            "}"),
            ParserErrorCode.INVALID_OPERATOR_CHAINING, 2, 11,
            ParserErrorCode.INVALID_OPERATOR_CHAINING, 3, 12);
  }

  public void test_expectedArrayOrMapLiteral() throws Exception {
    parseUnit("phony_expected_array_or_map_literal.dart",
        Joiner.on("\n").join(
            "method() {",
            "  var a = <int>;",
            "}"),
            ParserErrorCode.EXPECTED_ARRAY_OR_MAP_LITERAL, 2, 9,
            ParserErrorCode.EXPECTED_TOKEN, 2, 15);
  }

  public void test_assignToNonAssignable() throws Exception {
    parseUnit("phony_assign_to_non_assignable.dart",
        Joiner.on("\n").join(
            "method() {",
            "  1 + 2 = 3;",
            "}"),
            ParserErrorCode.ILLEGAL_ASSIGNMENT_TO_NON_ASSIGNABLE, 2, 7);
  }

  public void test_forComplexVariable() throws Exception {
    parseUnit("phony_for_complex_variable.dart",
        Joiner.on("\n").join(
            "method() {",
            "  for (foo + 1 in a) { }",
            "}"),
            ParserErrorCode.FOR_IN_WITH_COMPLEX_VARIABLE, 2, 8);
  }

  public void test_forMultipleVariable() throws Exception {
    parseUnit("phony_for_multiple_variable.dart",
        Joiner.on("\n").join(
            "method() {",
            "  for (var foo, bar in a) { }",
            "}"),
            ParserErrorCode.FOR_IN_WITH_MULTIPLE_VARIABLES, 2, 17);
  }

  public void test_forVariableInitializer() throws Exception {
    parseUnit("phony_for_multiple_variable.dart",
        Joiner.on("\n").join(
            "method() {",
            "  for (var foo = 1 in a) { }",
            "}"),
            ParserErrorCode.FOR_IN_WITH_VARIABLE_INITIALIZER, 2, 18);
  }

  public void test_varInFunctionType() throws Exception {
    parseUnit("phony_var_in_function_type.dart",
            "typedef func(var arg());",
            ParserErrorCode.FUNCTION_TYPED_PARAMETER_IS_VAR, 1, 18);
  }

  public void test_finalInFunctionType() throws Exception {
    parseUnit("phony_var_in_function_type.dart",
            "typedef func(final arg());",
            ParserErrorCode.FUNCTION_TYPED_PARAMETER_IS_FINAL, 1, 20);
  }
}
