// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.parser;

import com.google.common.base.Joiner;
import com.google.dart.compiler.DartCompilationError;
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
        "Unexpected token 'ILLEGAL'", 9, 9);
  }

  public void testNullAssign() {
    String sourceCode = "= 123;";
    try {
      DartSourceTest dartSrc = new DartSourceTest(getName(), sourceCode, null);
      DartScannerParserContext context =
        new DartScannerParserContext(dartSrc, sourceCode, new DartCompilerListener() {
        @Override
        public void onError(DartCompilationError event) {
        }
        @Override
        public void unitCompiled(DartUnit unit) {
        }
      });
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
    assertEquals("a", ((DartIdentifier)a.getName()).getTargetName());
    tryCatch = (DartTryStatement) a.getFunction().getBody().getStatements().get(0);
    assertEquals(1, tryCatch.getCatchBlocks().size());
    assertNotNull(tryCatch.getFinallyBlock());

    DartMethodDefinition b = (DartMethodDefinition) nodes.get(3);
    assertEquals("b", ((DartIdentifier)b.getName()).getTargetName());
    tryCatch = (DartTryStatement) b.getFunction().getBody().getStatements().get(0);
    assertEquals(1, tryCatch.getCatchBlocks().size());
    assertNull(tryCatch.getFinallyBlock());

    DartMethodDefinition c = (DartMethodDefinition) nodes.get(4);
    assertEquals("c", ((DartIdentifier)c.getName()).getTargetName());
    tryCatch = (DartTryStatement) c.getFunction().getBody().getStatements().get(0);
    assertEquals(0, tryCatch.getCatchBlocks().size());
    assertNotNull(tryCatch.getFinallyBlock());

    DartMethodDefinition d = (DartMethodDefinition) nodes.get(5);
    assertEquals("d", ((DartIdentifier)d.getName()).getTargetName());
    tryCatch = (DartTryStatement) d.getFunction().getBody().getStatements().get(0);
    assertEquals(2, tryCatch.getCatchBlocks().size());
    assertNull(tryCatch.getFinallyBlock());

    DartMethodDefinition e = (DartMethodDefinition) nodes.get(6);
    assertEquals("e", ((DartIdentifier)e.getName()).getTargetName());
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
}
