// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.backend.js;

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
import com.google.dart.compiler.backend.js.ast.JsExpression;
import com.google.dart.compiler.backend.js.ast.JsFor;
import com.google.dart.compiler.backend.js.ast.JsForIn;
import com.google.dart.compiler.backend.js.ast.JsFunction;
import com.google.dart.compiler.backend.js.ast.JsIf;
import com.google.dart.compiler.backend.js.ast.JsInvocation;
import com.google.dart.compiler.backend.js.ast.JsLabel;
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
import com.google.dart.compiler.backend.js.ast.JsStringLiteral;
import com.google.dart.compiler.backend.js.ast.JsSwitch;
import com.google.dart.compiler.backend.js.ast.JsThisRef;
import com.google.dart.compiler.backend.js.ast.JsThrow;
import com.google.dart.compiler.backend.js.ast.JsTry;
import com.google.dart.compiler.backend.js.ast.JsVars;
import com.google.dart.compiler.backend.js.ast.JsVisitor;
import com.google.dart.compiler.backend.js.ast.JsWhile;
import com.google.dart.compiler.backend.js.ast.JsVars.JsVar;

/**
 * Precedence indices from "JavaScript - The Definitive Guide" 4th Edition (page
 * 57)
 *
 * Precedence 17 is for indivisible primaries that either don't have children,
 * or provide their own delimiters.
 *
 * Precedence 16 is for really important things that have their own AST classes.
 *
 * Precedence 15 is for the new construct.
 *
 * Precedence 14 is for unary operators.
 *
 * Precedences 12 through 4 are for non-assigning binary operators.
 *
 * Precedence 3 is for the tertiary conditional.
 *
 * Precedence 2 is for assignments.
 *
 * Precedence 1 is for comma operations.
 */
class JsPrecedenceVisitor extends JsVisitor {

  static final int PRECEDENCE_NEW = 15;

  public static int exec(JsExpression expression) {
    JsPrecedenceVisitor visitor = new JsPrecedenceVisitor();
    visitor.accept(expression);
    if (visitor.answer < 0) {
      throw new RuntimeException("Precedence must be >= 0!");
    }
    return visitor.answer;
  }

  private int answer = -1;

  private JsPrecedenceVisitor() {
  }

  @Override
  public boolean visit(JsArrayAccess x, JsContext ctx) {
    answer = 16;
    return false;
  }

  @Override
  public boolean visit(JsArrayLiteral x, JsContext ctx) {
    answer = 17; // primary
    return false;
  }

  @Override
  public boolean visit(JsBinaryOperation x, JsContext ctx) {
    answer = x.getOperator().getPrecedence();
    return false;
  }

  @Override
  public boolean visit(JsBlock x, JsContext ctx) {
    throw new RuntimeException("Only expressions have precedence.");
  }

  @Override
  public boolean visit(JsBooleanLiteral x, JsContext ctx) {
    answer = 17; // primary
    return false;
  }

  @Override
  public boolean visit(JsBreak x, JsContext ctx) {
    throw new RuntimeException("Only expressions have precedence.");
  }

  @Override
  public boolean visit(JsCase x, JsContext ctx) {
    throw new RuntimeException("Only expressions have precedence.");
  }

  @Override
  public boolean visit(JsCatch x, JsContext ctx) {
    throw new RuntimeException("Only expressions have precedence.");
  }

  @Override
  public boolean visit(JsConditional x, JsContext ctx) {
    answer = 3;
    return false;
  }

  @Override
  public boolean visit(JsContinue x, JsContext ctx) {
    throw new RuntimeException("Only expressions have precedence.");
  }

  @Override
  public boolean visit(JsDebugger x, JsContext ctx) {
    throw new RuntimeException("Only expressions have precedence.");
  }

  @Override
  public boolean visit(JsDefault x, JsContext ctx) {
    throw new RuntimeException("Only expressions have precedence.");
  }

  @Override
  public boolean visit(JsDoWhile x, JsContext ctx) {
    throw new RuntimeException("Only expressions have precedence.");
  }

  @Override
  public boolean visit(JsEmpty x, JsContext ctx) {
    throw new RuntimeException("Only expressions have precedence.");
  }

  @Override
  public boolean visit(JsExprStmt x, JsContext ctx) {
    throw new RuntimeException("Only expressions have precedence.");
  }

  @Override
  public boolean visit(JsFor x, JsContext ctx) {
    throw new RuntimeException("Only expressions have precedence.");
  }

  @Override
  public boolean visit(JsForIn x, JsContext ctx) {
    throw new RuntimeException("Only expressions have precedence.");
  }

  @Override
  public boolean visit(JsFunction x, JsContext ctx) {
    answer = 17; // primary
    return false;
  }

  @Override
  public boolean visit(JsIf x, JsContext ctx) {
    throw new RuntimeException("Only expressions have precedence.");
  }

  @Override
  public boolean visit(JsInvocation x, JsContext ctx) {
    answer = 16;
    return false;
  }

  @Override
  public boolean visit(JsLabel x, JsContext ctx) {
    throw new RuntimeException("Only expressions have precedence.");
  }

  @Override
  public boolean visit(JsNameRef x, JsContext ctx) {
    if (x.isLeaf()) {
      answer = 17; // primary
    } else {
      answer = 16; // property access
    }
    return false;
  }

  @Override
  public boolean visit(JsNew x, JsContext ctx) {
    answer = PRECEDENCE_NEW;
    return false;
  }

  @Override
  public boolean visit(JsNullLiteral x, JsContext ctx) {
    answer = 17; // primary
    return false;
  }

  @Override
  public boolean visit(JsNumberLiteral x, JsContext ctx) {
    answer = 17; // primary
    return false;
  }

  @Override
  public boolean visit(JsObjectLiteral x, JsContext ctx) {
    answer = 17; // primary
    return false;
  }

  @Override
  public boolean visit(JsParameter x, JsContext ctx) {
    throw new RuntimeException("Only expressions have precedence.");
  }

  @Override
  public boolean visit(JsPostfixOperation x, JsContext ctx) {
    answer = x.getOperator().getPrecedence();
    return false;
  }

  @Override
  public boolean visit(JsPrefixOperation x, JsContext ctx) {
    answer = x.getOperator().getPrecedence();
    return false;
  }

  @Override
  public boolean visit(JsProgram x, JsContext ctx) {
    throw new RuntimeException("Only expressions have precedence.");
  }

  @Override
  public boolean visit(JsPropertyInitializer x, JsContext ctx) {
    answer = 17; // primary
    return false;
  }

  @Override
  public boolean visit(JsRegExp x, JsContext ctx) {
    answer = 17; // primary
    return false;
  }

  @Override
  public boolean visit(JsReturn x, JsContext ctx) {
    throw new RuntimeException("Only expressions have precedence.");
  }

  @Override
  public boolean visit(JsStringLiteral x, JsContext ctx) {
    answer = 17; // primary
    return false;
  }

  @Override
  public boolean visit(JsSwitch x, JsContext ctx) {
    throw new RuntimeException("Only expressions have precedence.");
  }

  @Override
  public boolean visit(JsThisRef x, JsContext ctx) {
    answer = 17; // primary
    return false;
  }

  @Override
  public boolean visit(JsThrow x, JsContext ctx) {
    throw new RuntimeException("Only expressions have precedence.");
  }

  @Override
  public boolean visit(JsTry x, JsContext ctx) {
    throw new RuntimeException("Only expressions have precedence.");
  }

  @Override
  public boolean visit(JsVar x, JsContext ctx) {
    throw new RuntimeException("Only expressions have precedence.");
  }

  @Override
  public boolean visit(JsVars x, JsContext ctx) {
    throw new RuntimeException("Only expressions have precedence.");
  }

  @Override
  public boolean visit(JsWhile x, JsContext ctx) {
    throw new RuntimeException("Only expressions have precedence.");
  }
}
