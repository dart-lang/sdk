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
  visitMapLiteral(MapLiteral l);
  visitMapLiteralEntry(MapLiteralEntry l);
  visitIdentifier(Identifier i);
  visitBinaryOperator(BinaryOperator o);
  visitUnaryOperator(UnaryOperator o);
  visitInExpression(InExpression c);
}

abstract class RecursiveVisitor extends Visitor {
  visitExpression(Expression e);

  visitEmptyExpression(EmptyExpression e) => visitExpression(e);

  visitParenthesizedExpression(ParenthesizedExpression e) {
    visit(e.child);
    visitExpression(e);
  }

  visitGetter(Getter i) {
    visit(i.receiver);
    visitExpression(i);
  }

  visitIndex(Index i) {
    visit(i.receiver);
    visit(i.argument);
    visitExpression(i);
  }

  visitInvoke(Invoke i) {
    visit(i.receiver);
    if (i.arguments != null) {
      for (var a in i.arguments) {
        visit(a);
      }
    }
    visitExpression(i);
  }

  visitLiteral(Literal l) => visitExpression(l);

  visitMapLiteral(MapLiteral l) {
    for (var e in l.entries) {
      visit(e);
    }
    visitExpression(l);
  }

  visitMapLiteralEntry(MapLiteralEntry e) {
    visit(e.key);
    visit(e.entryValue);
    visitExpression(e);
  }

  visitIdentifier(Identifier i) => visitExpression(i);

  visitBinaryOperator(BinaryOperator o) {
    visit(o.left);
    visit(o.right);
    visitExpression(o);
  }

  visitUnaryOperator(UnaryOperator o) {
    visit(o.child);
    visitExpression(o);
  }

  visitInExpression(InExpression c) {
    visit(c.left);
    visit(c.right);
    visitExpression(c);
  }
}