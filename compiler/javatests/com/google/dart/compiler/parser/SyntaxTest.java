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
import com.google.dart.compiler.ast.DartExprStmt;
import com.google.dart.compiler.ast.DartExpression;
import com.google.dart.compiler.ast.DartField;
import com.google.dart.compiler.ast.DartFieldDefinition;
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
import com.google.dart.compiler.ast.DartTypeNode;
import com.google.dart.compiler.ast.DartUnit;
import com.google.dart.compiler.ast.DartVariableStatement;

import java.util.List;

public class SyntaxTest extends AbstractParserTest {

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
            "#library(\"test\");",
            "#import(\"QualifiedReturnTypeA.dart\", prefix : \"pref\");",
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
      DartScannerParserContext context =
        new DartScannerParserContext(dartSrc, sourceCode, new DartCompilerListener.Empty());
      DartParser parser = new DartParser(context);
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
}
