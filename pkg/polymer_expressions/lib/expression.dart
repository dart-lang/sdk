// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library polymer_expressions.expression;

import 'visitor.dart';

// Helper functions for building expression trees programmatically

EmptyExpression empty() => new EmptyExpression();
Literal literal(v) => new Literal(v);
MapLiteral mapLiteral(List<MapLiteralEntry> entries) => new MapLiteral(entries);
MapLiteralEntry mapLiteralEntry(Literal key, Expression value) =>
    new MapLiteralEntry(key, value);
Identifier ident(String v) => new Identifier(v);
ParenthesizedExpression paren(Expression e) => new ParenthesizedExpression(e);
UnaryOperator unary(String op, Expression e) => new UnaryOperator(op, e);
BinaryOperator binary(Expression l, String op, Expression r) =>
    new BinaryOperator(l, op, r);
Invoke invoke(Expression e, String m, [List<Expression> a]) =>
    new Invoke(e, m, a);
InExpression inExpr(Expression l, Expression r) => new InExpression(l, r);


class AstFactory {
  EmptyExpression empty() => new EmptyExpression();

  Literal literal(v) => new Literal(v);

  MapLiteral mapLiteral(List<MapLiteralEntry> entries) =>
      new MapLiteral(entries);

  MapLiteralEntry mapLiteralEntry(Literal key, Expression value) =>
      new MapLiteralEntry(key, value);

  Identifier identifier(String v) => new Identifier(v);

  ParenthesizedExpression parenthesized(Expression e) =>
      new ParenthesizedExpression(e);

  UnaryOperator unary(String op, Expression e) => new UnaryOperator(op, e);

  BinaryOperator binary(Expression l, String op, Expression r) =>
      new BinaryOperator(l, op, r);

  Invoke invoke(Expression e, String m, [List<Expression> a]) =>
      new Invoke(e, m, a);

  InExpression inExpr(Expression l, Expression r) => new InExpression(l, r);
}

/// Base class for all expressions
abstract class Expression {
  accept(Visitor v);
}

class EmptyExpression extends Expression {
  accept(Visitor v) => v.visitEmptyExpression(this);
  bool operator ==(o) => o is EmptyExpression;
}

class Literal<T> extends Expression {
  final T value;

  Literal(this.value);

  accept(Visitor v) => v.visitLiteral(this);

  String toString() => (value is String) ? '"$value"' : '$value';

  bool operator ==(o) => o is Literal<T> && o.value == value;

  int get hashCode => value.hashCode;
}

class MapLiteral extends Expression {
  final List<MapLiteralEntry> entries;

  MapLiteral(this.entries);

  accept(Visitor v) => v.visitMapLiteral(this);

  String toString() => "{$entries}";

  bool operator ==(o) => o is MapLiteral && _listEquals(o.entries, entries);
}

class MapLiteralEntry extends Expression {
  final Literal key;
  final Expression entryValue;

  MapLiteralEntry(this.key, this.entryValue);

  accept(Visitor v) => v.visitMapLiteralEntry(this);

  String toString() => "$key: $entryValue";

  bool operator ==(o) => o is MapLiteralEntry && o.key == key
      && o.entryValue == entryValue;
}

class ParenthesizedExpression extends Expression {
  final Expression child;

  ParenthesizedExpression(this.child);

  accept(Visitor v) => v.visitParenthesizedExpression(this);

  String toString() => '($child)';

  bool operator ==(o) => o is ParenthesizedExpression && o.child == child;

  int get hashCode => child.hashCode;
}

class Identifier extends Expression {
  final String value;

  Identifier(this.value);

  accept(Visitor v) => v.visitIdentifier(this);

  String toString() => value;

  bool operator ==(o) => o is Identifier && o.value == value;

  int get hashCode => value.hashCode;
}

class UnaryOperator extends Expression {
  final String operator;
  final Expression child;

  UnaryOperator(this.operator, this.child);

  accept(Visitor v) => v.visitUnaryOperator(this);

  String toString() => '$operator $child';

  bool operator ==(o) => o is UnaryOperator && o.operator == operator
      && o.child == child;
}

class BinaryOperator extends Expression {
  final String operator;
  final Expression left;
  final Expression right;

  BinaryOperator(this.left, this.operator, this.right);

  accept(Visitor v) => v.visitBinaryOperator(this);

  String toString() => '($left $operator $right)';

  bool operator ==(o) => o is BinaryOperator && o.operator == operator
      && o.left == left && o.right == right;
}

class InExpression extends Expression {
  final Expression left;
  final Expression right;

  InExpression(this.left, this.right);

  accept(Visitor v) => v.visitInExpression(this);

  String toString() => '($left in $right)';

  bool operator ==(o) => o is InExpression && o.left == left
      && o.right == right;
}

/**
 * Represents a function or method invocation. If [method] is null, then
 * [receiver] is an expression that should evaluate to a function. If [method]
 * is not null, then [receiver] is an expression that should evaluate to an
 * object that has an appropriate method.
 */
class Invoke extends Expression {
  final Expression receiver;
  final String method;
  final List<Expression> arguments;

  Invoke(this.receiver, this.method, [this.arguments]);

  accept(Visitor v) => v.visitInvoke(this);

  bool get isGetter => arguments == null;

  String toString() => '$receiver.$method($arguments)';

  bool operator ==(o) =>
      o is Invoke
      && o.receiver == receiver
      && o.method == method
      && _listEquals(o.arguments, arguments);
}

bool _listEquals(List a, List b) {
  if (a == b) return true;
  if (a == null || b == null) return false;
  if (a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}