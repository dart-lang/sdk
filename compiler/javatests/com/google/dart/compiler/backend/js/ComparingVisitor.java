// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.backend.js;

import com.google.dart.compiler.backend.js.FlatteningVisitor.TreeNode;
import com.google.dart.compiler.backend.js.ast.JsArrayAccess;
import com.google.dart.compiler.backend.js.ast.JsArrayLiteral;
import com.google.dart.compiler.backend.js.ast.JsBinaryOperation;
import com.google.dart.compiler.backend.js.ast.JsBlock;
import com.google.dart.compiler.backend.js.ast.JsBooleanLiteral;
import com.google.dart.compiler.backend.js.ast.JsBreak;
import com.google.dart.compiler.backend.js.ast.JsCase;
import com.google.dart.compiler.backend.js.ast.JsCatch;
import com.google.dart.compiler.backend.js.ast.JsConditional;
import com.google.dart.compiler.backend.js.ast.JsContext;
import com.google.dart.compiler.backend.js.ast.JsContinue;
import com.google.dart.compiler.backend.js.ast.JsDebugger;
import com.google.dart.compiler.backend.js.ast.JsDefault;
import com.google.dart.compiler.backend.js.ast.JsDoWhile;
import com.google.dart.compiler.backend.js.ast.JsEmpty;
import com.google.dart.compiler.backend.js.ast.JsExprStmt;
import com.google.dart.compiler.backend.js.ast.JsFor;
import com.google.dart.compiler.backend.js.ast.JsForIn;
import com.google.dart.compiler.backend.js.ast.JsFunction;
import com.google.dart.compiler.backend.js.ast.JsIf;
import com.google.dart.compiler.backend.js.ast.JsInvocation;
import com.google.dart.compiler.backend.js.ast.JsLabel;
import com.google.dart.compiler.backend.js.ast.JsName;
import com.google.dart.compiler.backend.js.ast.JsNameRef;
import com.google.dart.compiler.backend.js.ast.JsNew;
import com.google.dart.compiler.backend.js.ast.JsNullLiteral;
import com.google.dart.compiler.backend.js.ast.JsNumberLiteral;
import com.google.dart.compiler.backend.js.ast.JsObjectLiteral;
import com.google.dart.compiler.backend.js.ast.JsParameter;
import com.google.dart.compiler.backend.js.ast.JsPostfixOperation;
import com.google.dart.compiler.backend.js.ast.JsPrefixOperation;
import com.google.dart.compiler.backend.js.ast.JsProgram;
import com.google.dart.compiler.backend.js.ast.JsPropertyInitializer;
import com.google.dart.compiler.backend.js.ast.JsRegExp;
import com.google.dart.compiler.backend.js.ast.JsReturn;
import com.google.dart.compiler.backend.js.ast.JsStatement;
import com.google.dart.compiler.backend.js.ast.JsStringLiteral;
import com.google.dart.compiler.backend.js.ast.JsSwitch;
import com.google.dart.compiler.backend.js.ast.JsThisRef;
import com.google.dart.compiler.backend.js.ast.JsThrow;
import com.google.dart.compiler.backend.js.ast.JsTry;
import com.google.dart.compiler.backend.js.ast.JsVars;
import com.google.dart.compiler.backend.js.ast.JsVisitable;
import com.google.dart.compiler.backend.js.ast.JsVisitor;
import com.google.dart.compiler.backend.js.ast.JsWhile;
import com.google.dart.compiler.backend.js.ast.JsVars.JsVar;

import junit.framework.Assert;
import junit.framework.TestCase;

import java.util.List;

class ComparingVisitor extends JsVisitor {

  public static void exec(List<JsStatement> expected, List<JsStatement> actual) {
    TreeNode expectedTree = FlatteningVisitor.exec(expected);
    TreeNode actualTree = FlatteningVisitor.exec(actual);
    compare(expectedTree, actualTree);
  }

  private static void compare(JsVisitable expected, JsVisitable actual) {
    if (expected == actual) {
      return;
    }
    Assert.assertNotNull(expected);
    Assert.assertNotNull(actual);
    ComparingVisitor visitor = new ComparingVisitor(expected);
    visitor.accept(actual);
  }

  private static void compare(TreeNode expected, TreeNode actual) {
    compare(expected.node, actual.node);
    List<TreeNode> expectedChildren = expected.children;
    List<TreeNode> actualChildren = actual.children;
    Assert.assertEquals(expectedChildren.size(), actualChildren.size());
    for (int i = 0; i < expectedChildren.size(); i++) {
      compare(expectedChildren.get(i), actualChildren.get(i));
    }
  }

  /**
   * We use a raw type here because Sun's javac will barf all over the casts and
   * instanceof tests we do all throughout this file.
   */
  private final JsVisitable other;

  private ComparingVisitor(JsVisitable other) {
    this.other = other;
  }

  @Override
  public boolean visit(JsArrayAccess x, JsContext ctx) {
    Assert.assertTrue(other instanceof JsArrayAccess);
    return false;
  }

  @Override
  public boolean visit(JsArrayLiteral x, JsContext ctx) {
    Assert.assertTrue(other instanceof JsArrayLiteral);
    return false;
  }

  @Override
  public boolean visit(JsBinaryOperation x, JsContext ctx) {
    Assert.assertTrue(other instanceof JsBinaryOperation);
    Assert.assertEquals(((JsBinaryOperation) other).getOperator().getSymbol(),
        x.getOperator().getSymbol());
    return false;
  }

  @Override
  public boolean visit(JsBlock x, JsContext ctx) {
    Assert.assertTrue(other instanceof JsBlock);
    Assert.assertEquals(((JsBlock) other).isGlobalBlock(), x.isGlobalBlock());
    return false;
  }

  @Override
  public boolean visit(JsBooleanLiteral x, JsContext ctx) {
    Assert.assertTrue(other instanceof JsBooleanLiteral);
    Assert.assertEquals(((JsBooleanLiteral) other).getValue(), x.getValue());
    return false;
  }

  @Override
  public boolean visit(JsBreak x, JsContext ctx) {
    Assert.assertTrue(other instanceof JsBreak);
    Assert.assertEquals(((JsBreak) other).getLabel().getIdent(), x.getLabel().getIdent());
    return false;
  }

  @Override
  public boolean visit(JsCase x, JsContext ctx) {
    Assert.assertTrue(other instanceof JsCase);
    return false;
  }

  @Override
  public boolean visit(JsCatch x, JsContext ctx) {
    Assert.assertTrue(other instanceof JsCatch);
    Assert.assertEquals(((JsCatch) other).getParameter().getName().getIdent(),
        x.getParameter().getName().getIdent());
    return false;
  }

  @Override
  public boolean visit(JsConditional x, JsContext ctx) {
    Assert.assertTrue(other instanceof JsConditional);
    return false;
  }

  @Override
  public boolean visit(JsContinue x, JsContext ctx) {
    Assert.assertTrue(other instanceof JsContinue);
    Assert.assertEquals(((JsContinue) other).getLabel().getIdent(), x.getLabel().getIdent());
    return false;
  }

  @Override
  public boolean visit(JsDebugger x, JsContext ctx) {
    Assert.assertTrue(other instanceof JsDebugger);
    return false;
  }

  @Override
  public boolean visit(JsDefault x, JsContext ctx) {
    Assert.assertTrue(other instanceof JsDefault);
    return false;
  }

  @Override
  public boolean visit(JsDoWhile x, JsContext ctx) {
    Assert.assertTrue(other instanceof JsDoWhile);
    return false;
  }

  @Override
  public boolean visit(JsEmpty x, JsContext ctx) {
    Assert.assertTrue(other instanceof JsEmpty);
    return false;
  }

  @Override
  public boolean visit(JsExprStmt x, JsContext ctx) {
    Assert.assertTrue(other instanceof JsExprStmt);
    return false;
  }

  @Override
  public boolean visit(JsFor x, JsContext ctx) {
    Assert.assertTrue(other instanceof JsFor);
    return false;
  }

  @Override
  public boolean visit(JsForIn x, JsContext ctx) {
    Assert.assertTrue(other instanceof JsForIn);
    return false;
  }

  @Override
  public boolean visit(JsFunction x, JsContext ctx) {
    Assert.assertTrue(other instanceof JsFunction);
    JsFunction otherFunc = (JsFunction) other;
    JsName otherName = otherFunc.getName();
    JsName name = x.getName();
    if (name != otherName) {
      Assert.assertEquals(otherName.getIdent(), name.getIdent());
    }
    return false;
  }

  @Override
  public boolean visit(JsIf x, JsContext ctx) {
    Assert.assertTrue(other instanceof JsIf);
    return false;
  }

  @Override
  public boolean visit(JsInvocation x, JsContext ctx) {
    Assert.assertTrue(other instanceof JsInvocation);
    return false;
  }

  @Override
  public boolean visit(JsLabel x, JsContext ctx) {
    Assert.assertTrue(other instanceof JsLabel);
    Assert.assertEquals(((JsLabel) other).getName().getIdent(), x.getName().getIdent());
    return false;
  }

  @Override
  public boolean visit(JsNameRef x, JsContext ctx) {
    Assert.assertTrue(other instanceof JsNameRef);
    Assert.assertEquals(((JsNameRef) other).getIdent(), x.getIdent());
    return false;
  }

  @Override
  public boolean visit(JsNew x, JsContext ctx) {
    Assert.assertTrue(other instanceof JsNew);
    return false;
  }

  @Override
  public boolean visit(JsNullLiteral x, JsContext ctx) {
    Assert.assertTrue(other instanceof JsNullLiteral);
    return false;
  }

  @Override
  public boolean visit(JsNumberLiteral x, JsContext ctx) {
    Assert.assertTrue(other instanceof JsNumberLiteral);
    Assert.assertEquals(((JsNumberLiteral) other).getValue(), x.getValue());
    return false;
  }

  @Override
  public boolean visit(JsObjectLiteral x, JsContext ctx) {
    Assert.assertTrue(other instanceof JsObjectLiteral);
    return false;
  }

  @Override
  public boolean visit(JsParameter x, JsContext ctx) {
    Assert.assertTrue(other instanceof JsParameter);
    Assert.assertEquals(((JsParameter) other).getName().getIdent(), x.getName().getIdent());
    return false;
  }

  @Override
  public boolean visit(JsPostfixOperation x, JsContext ctx) {
    Assert.assertTrue(other instanceof JsPostfixOperation);
    Assert.assertEquals(((JsPostfixOperation) other).getOperator().getSymbol(),
        x.getOperator().getSymbol());
    return false;
  }

  @Override
  public boolean visit(JsPrefixOperation x, JsContext ctx) {
    Assert.assertTrue(other instanceof JsPrefixOperation);
    Assert.assertEquals(((JsPrefixOperation) other).getOperator().getSymbol(),
        x.getOperator().getSymbol());
    return false;
  }

  @Override
  public boolean visit(JsProgram x, JsContext ctx) {
    Assert.assertTrue(other instanceof JsProgram);
    return false;
  }

  @Override
  public boolean visit(JsPropertyInitializer x, JsContext ctx) {
    Assert.assertTrue(other instanceof JsPropertyInitializer);
    return false;
  }

  @Override
  public boolean visit(JsRegExp x, JsContext ctx) {
    Assert.assertTrue(other instanceof JsRegExp);
    Assert.assertEquals(((JsRegExp) other).getFlags(), x.getFlags());
    Assert.assertEquals(((JsRegExp) other).getPattern(), x.getPattern());
    return false;
  }

  @Override
  public boolean visit(JsReturn x, JsContext ctx) {
    Assert.assertTrue(other instanceof JsReturn);
    return false;
  }

  @Override
  public boolean visit(JsStringLiteral x, JsContext ctx) {
    Assert.assertTrue(other instanceof JsStringLiteral);
    Assert.assertEquals(((JsStringLiteral) other).getValue(), x.getValue());
    return false;
  }

  @Override
  public boolean visit(JsSwitch x, JsContext ctx) {
    Assert.assertTrue(other instanceof JsSwitch);
    return false;
  }

  @Override
  public boolean visit(JsThisRef x, JsContext ctx) {
    Assert.assertTrue(other instanceof JsThisRef);
    return false;
  }

  @Override
  public boolean visit(JsThrow x, JsContext ctx) {
    Assert.assertTrue(other instanceof JsThrow);
    return false;
  }

  @Override
  public boolean visit(JsTry x, JsContext ctx) {
    Assert.assertTrue(other instanceof JsTry);
    return false;
  }

  @Override
  public boolean visit(JsVar x, JsContext ctx) {
    TestCase.assertTrue(other instanceof JsVar);
    TestCase.assertEquals(((JsVar) other).getName().getIdent(), x.getName().getIdent());
    return false;
  }

  public boolean visit(JsVars x, JsContext ctx) {
    TestCase.assertTrue(other instanceof JsVars);
    return false;
  }

  public boolean visit(JsWhile x, JsContext ctx) {
    TestCase.assertTrue(other instanceof JsWhile);
    return false;
  }
}
