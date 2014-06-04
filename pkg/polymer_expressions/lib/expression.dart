// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library polymer_expressions.expression;

import 'visitor.dart';

// Helper functions for building expression trees programmatically

EmptyExpression empty() => const EmptyExpression();
Literal literal(v) => new Literal(v);
ListLiteral listLiteral(List<Expression> items) => new ListLiteral(items);
MapLiteral mapLiteral(List<MapLiteralEntry> entries) => new MapLiteral(entries);
MapLiteralEntry mapLiteralEntry(Literal key, Expression value) =>
    new MapLiteralEntry(key, value);
Identifier ident(String v) => new Identifier(v);
ParenthesizedExpression paren(Expression e) => new ParenthesizedExpression(e);
UnaryOperator unary(String op, Expression e) => new UnaryOperator(op, e);
BinaryOperator binary(Expression l, String op, Expression r) =>
    new BinaryOperator(l, op, r);
Getter getter(Expression e, String m) => new Getter(e, m);
Index index(Expression e, Expression a) => new Index(e, a);
Invoke invoke(Expression e, String m, List<Expression> a) =>
    new Invoke(e, m, a);
InExpression inExpr(Expression l, Expression r) => new InExpression(l, r);
AsExpression asExpr(Expression l, Expression r) => new AsExpression(l, r);
TernaryOperator ternary(Expression c, Expression t, Expression f) =>
    new TernaryOperator(c, t, f);

class AstFactory {
  EmptyExpression empty() => const EmptyExpression();

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

  TernaryOperator ternary(Expression c, Expression t, Expression f) =>
      new TernaryOperator(c, t, f);

  Getter getter(Expression g, String n) => new Getter(g, n);

  Index index(Expression e, Expression a) => new Index(e, a);

  Invoke invoke(Expression e, String m, List<Expression> a) =>
      new Invoke(e, m, a);

  InExpression inExpr(Expression l, Expression r) => new InExpression(l, r);

  AsExpression asExpr(Expression l, Expression r) => new AsExpression(l, r);
}

/// Base class for all expressions
abstract class Expression {
  const Expression();
  accept(Visitor v);
}

abstract class HasIdentifier {
  String get identifier;
  Expression get expr;
}

class EmptyExpression extends Expression {
  const EmptyExpression();
  accept(Visitor v) => v.visitEmptyExpression(this);
}

class Literal<T> extends Expression {
  final T value;

  Literal(this.value);

  accept(Visitor v) => v.visitLiteral(this);

  String toString() => (value is String) ? '"$value"' : '$value';

  bool operator ==(o) => o is Literal<T> && o.value == value;

  int get hashCode => value.hashCode;
}

class ListLiteral extends Expression {
  final List<Expression> items;

  ListLiteral(this.items);

  accept(Visitor v) => v.visitListLiteral(this);

  String toString() => "$items";

  bool operator ==(o) => o is ListLiteral && _listEquals(o.items, items);

  int get hashCode => _hashList(items);
}

class MapLiteral extends Expression {
  final List<MapLiteralEntry> entries;

  MapLiteral(this.entries);

  accept(Visitor v) => v.visitMapLiteral(this);

  String toString() => "{$entries}";

  bool operator ==(o) => o is MapLiteral && _listEquals(o.entries, entries);

  int get hashCode => _hashList(entries);
}

class MapLiteralEntry extends Expression {
  final Literal key;
  final Expression entryValue;

  MapLiteralEntry(this.key, this.entryValue);

  accept(Visitor v) => v.visitMapLiteralEntry(this);

  String toString() => "$key: $entryValue";

  bool operator ==(o) => o is MapLiteralEntry && o.key == key
      && o.entryValue == entryValue;

  int get hashCode => _JenkinsSmiHash.hash2(key.hashCode, entryValue.hashCode);
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

  int get hashCode => _JenkinsSmiHash.hash2(operator.hashCode, child.hashCode);
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

  int get hashCode => _JenkinsSmiHash.hash3(operator.hashCode, left.hashCode,
      right.hashCode);
}

class TernaryOperator extends Expression {
  final Expression condition;
  final Expression trueExpr;
  final Expression falseExpr;

  TernaryOperator(this.condition, this.trueExpr, this.falseExpr);

  accept(Visitor v) => v.visitTernaryOperator(this);

  String toString() => '($condition ? $trueExpr : $falseExpr)';

  bool operator ==(o) => o is TernaryOperator
      && o.condition == condition
      && o.trueExpr == trueExpr
      && o.falseExpr == falseExpr;

  int get hashCode => _JenkinsSmiHash.hash3(condition.hashCode,
      trueExpr.hashCode, falseExpr.hashCode);
}

class InExpression extends Expression implements HasIdentifier {
  final Identifier left;
  final Expression right;

  InExpression(this.left, this.right);

  accept(Visitor v) => v.visitInExpression(this);

  String get identifier => left.value;

  Expression get expr => right;

  String toString() => '($left in $right)';

  bool operator ==(o) => o is InExpression && o.left == left
      && o.right == right;

  int get hashCode => _JenkinsSmiHash.hash2(left.hashCode, right.hashCode);
}

class AsExpression extends Expression implements HasIdentifier {
  final Expression left;
  final Identifier right;

  AsExpression(this.left, this.right);

  accept(Visitor v) => v.visitAsExpression(this);

  String get identifier => right.value;

  Expression get expr => left;

  String toString() => '($left as $right)';

  bool operator ==(o) => o is AsExpression && o.left == left
      && o.right == right;

  int get hashCode => _JenkinsSmiHash.hash2(left.hashCode, right.hashCode);
}

class Index extends Expression {
  final Expression receiver;
  final Expression argument;

  Index(this.receiver, this.argument);

  accept(Visitor v) => v.visitIndex(this);

  String toString() => '$receiver[$argument]';

  bool operator ==(o) =>
      o is Index
      && o.receiver == receiver
      && o.argument == argument;

  int get hashCode =>
      _JenkinsSmiHash.hash2(receiver.hashCode, argument.hashCode);
}

class Getter extends Expression {
  final Expression receiver;
  final String name;

  Getter(this.receiver, this.name);

  accept(Visitor v) => v.visitGetter(this);

  String toString() => '$receiver.$name';

  bool operator ==(o) =>
      o is Getter
      && o.receiver == receiver
      && o.name == name;

  int get hashCode => _JenkinsSmiHash.hash2(receiver.hashCode, name.hashCode);

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

  Invoke(this.receiver, this.method, this.arguments) {
    assert(arguments != null);
  }

  accept(Visitor v) => v.visitInvoke(this);

  String toString() => '$receiver.$method($arguments)';

  bool operator ==(o) =>
      o is Invoke
      && o.receiver == receiver
      && o.method == method
      && _listEquals(o.arguments, arguments);

  int get hashCode => _JenkinsSmiHash.hash3(receiver.hashCode, method.hashCode,
      _hashList(arguments));
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

int _hashList(List l) {
  var hash = l.fold(0,
      (h, item) => _JenkinsSmiHash.combine(h, item.hashCode));
  return _JenkinsSmiHash.finish(hash);
}

class _JenkinsSmiHash {
  // TODO: Bug 11617- This class should be optimized and standardized elsewhere.

  static int combine(int hash, int value) {
    hash = 0x1fffffff & (hash + value);
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) <<  3));
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }

  static int hash2(int a, int b) => finish(combine(combine(0, a), b));

  static int hash3(int a, int b, int c) =>
      finish(combine(combine(combine(0, a), b), c));

  static int hash4(int a, int b, int c, int d) =>
      finish(combine(combine(combine(combine(0, a), b), c), d));
}
