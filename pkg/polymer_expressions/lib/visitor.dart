// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library polymer_expressions.visitor;

import 'expression.dart';

abstract class Visitor {
  visit(Expression s) => s.accept(this);
  visitEmptyExpression(EmptyExpression e);
  visitParenthesizedExpression(ParenthesizedExpression e);
  visitGetter(Getter i);
  visitIndex(Index i);
  visitInvoke(Invoke i);
  visitLiteral(Literal l);
  visitListLiteral(ListLiteral l);
  visitMapLiteral(MapLiteral l);
  visitMapLiteralEntry(MapLiteralEntry l);
  visitIdentifier(Identifier i);
  visitBinaryOperator(BinaryOperator o);
  visitUnaryOperator(UnaryOperator o);
  visitTernaryOperator(TernaryOperator o);
  visitInExpression(InExpression c);
  visitAsExpression(AsExpression c);
}

class RecursiveVisitor extends Visitor {
  preVisitExpression(Expression e) {}
  visitExpression(Expression e) {}

  visitEmptyExpression(EmptyExpression e) {
    preVisitExpression(e);
    visitExpression(e);
  }

  visitParenthesizedExpression(ParenthesizedExpression e) {
    preVisitExpression(e);
    visit(e.child);
    visitExpression(e);
  }

  visitGetter(Getter i) {
    preVisitExpression(i);
    visit(i.receiver);
    visitExpression(i);
  }

  visitIndex(Index i) {
    preVisitExpression(i);
    visit(i.receiver);
    visit(i.argument);
    visitExpression(i);
  }

  visitInvoke(Invoke i) {
    preVisitExpression(i);
    visit(i.receiver);
    if (i.arguments != null) {
      for (var a in i.arguments) {
        visit(a);
      }
    }
    visitExpression(i);
  }

  visitLiteral(Literal l) {
    preVisitExpression(l);
    visitExpression(l);
  }

  visitListLiteral(ListLiteral l) {
    preVisitExpression(l);
    for (var i in l.items) {
      visit(i);
    }
    visitExpression(l);
  }

  visitMapLiteral(MapLiteral l) {
    preVisitExpression(l);
    for (var e in l.entries) {
      visit(e);
    }
    visitExpression(l);
  }

  visitMapLiteralEntry(MapLiteralEntry e) {
    preVisitExpression(e);
    visit(e.key);
    visit(e.entryValue);
    visitExpression(e);
  }

  visitIdentifier(Identifier i) {
    preVisitExpression(i);
    visitExpression(i);
  }

  visitBinaryOperator(BinaryOperator o) {
    preVisitExpression(o);
    visit(o.left);
    visit(o.right);
    visitExpression(o);
  }

  visitUnaryOperator(UnaryOperator o) {
    preVisitExpression(o);
    visit(o.child);
    visitExpression(o);
  }

  visitTernaryOperator(TernaryOperator o) {
    preVisitExpression(o);
    visit(o.condition);
    visit(o.trueExpr);
    visit(o.falseExpr);
    visitExpression(o);
  }

  visitInExpression(InExpression c) {
    preVisitExpression(c);
    visit(c.left);
    visit(c.right);
    visitExpression(c);
  }

  visitAsExpression(AsExpression c) {
    visit(c.left);
    visit(c.right);
    visitExpression(c);
  }
}
