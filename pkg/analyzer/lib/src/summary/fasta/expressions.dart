// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Minimal AST used to represent constant and initializer expressions.
///
/// The AST definitions here are kept small by removing anything that we don't
/// need for the purpose of summarization:
///
///   * A tree representing constants will not contain nodes that are not
///   allowed. If a parsed program contains a subexpression that is invalid,
///   we'll represent it with an `Invalid` node.
///
///   * A tree representing initializers will only contain the subset of the
///   initializer expression that is needed to infer the type of the initialized
///   variable. For example, function closures, arguments to constructors, and
///   other similar bits are hidden using `Opaque` nodes.
library summary.src.expressions;

// We reuse the scanner constants to represent all binary and unary operators.
import 'visitor.dart';

export 'visitor.dart';

/// A cast expression.
class As extends Expression {
  final Expression exp;
  final TypeRef type;
  As(this.exp, this.type);

  bool get isAs => true;
  accept(v) => v.visitAs(this);
  toString() => '$exp as $type';
}

/// All binary expressions, including if-null.
class Binary extends Expression {
  final Expression left;
  final Expression right;
  final int operator;
  Binary(this.left, this.right, this.operator);

  bool get isBinary => true;
  accept(v) => v.visitBinary(this);
  toString() => '$left _ $right';
}

/// A literal like `false`.
class BoolLiteral extends Expression {
  final bool value;
  BoolLiteral(this.value);

  accept(v) => v.visitBool(this);
  toString() => '$value';
}

/// Expressions like `a ? b : c`.
class Conditional extends Expression {
  final Expression test;
  final Expression trueBranch;
  final Expression falseBranch;
  Conditional(this.test, this.trueBranch, this.falseBranch);

  bool get isConditional => true;
  accept(v) => v.visitConditional(this);
  toString() => '$test ? $trueBranch : $falseBranch';
}

/// A `const Foo()` creation.
class ConstCreation extends Expression {
  final ConstructorName constructor;

  /// Passed arguments, which can be expressions (if the argument is positional)
  /// or a [NamedArg].
  final List<Expression> positionalArgs;
  final List<NamedArg> namedArgs;
  ConstCreation(this.constructor, this.positionalArgs, this.namedArgs);

  accept(v) => v.visitConstCreation(this);
}

/// The type and possibly name of a constructor.
class ConstructorName {
  final TypeRef type;
  final String name;
  ConstructorName(this.type, this.name);

  toString() => "ctor: $type.$name";
}

/// A literal like `1.2`.
class DoubleLiteral extends Expression {
  final double value;
  DoubleLiteral(this.value);

  accept(v) => v.visitDouble(this);
  toString() => '$value';
}

/// Root of all expressions
abstract class Expression {
  bool get isAs => false;
  bool get isBinary => false;
  bool get isConditional => false;
  bool get isIdentical => false;
  bool get isIs => false;
  bool get isLoad => false;
  bool get isOpaqueOp => false;
  bool get isRef => false;
  bool get isUnary => false;

  accept(Visitor v);
}

/// An identical expression: `identical(a, b)`.
// TODO(sigmund): consider merging it into binary?
class Identical extends Expression {
  final Expression left;
  final Expression right;
  Identical(this.left, this.right);

  bool get isIdentical => true;
  accept(v) => v.visitIdentical(this);
  toString() => 'identical($left, $right)';
}

/// A literal like `1`.
class IntLiteral extends Expression {
  final int value;
  IntLiteral(this.value);

  accept(v) => v.visitInt(this);
  toString() => '$value';
}

/// An erroneous expression, typically encapsulates code that is not expected
/// in a constant context.
class Invalid extends Expression {
  String hint;
  Invalid({this.hint});
  accept(v) => v.visitInvalid(this);

  toString() => '(err: $hint)';
}

/// An instance check expression.
class Is extends Expression {
  final Expression exp;
  final TypeRef type;
  Is(this.exp, this.type);

  bool get isIs => true;
  accept(v) => v.visitIs(this);
  toString() => '$exp is $type';
}

/// An entry in a map literal.
class KeyValuePair {
  final Expression key;
  final Expression value;
  KeyValuePair(this.key, this.value);

  toString() => '(p: $key, $value)';
}

/// A list literal like: `[1, 2]`.
class ListLiteral extends Expression {
  final TypeRef elementType;
  final List<Expression> values;
  final bool isConst;
  ListLiteral(this.elementType, this.values, this.isConst);

  accept(v) => v.visitList(this);
  toString() => '(list<$elementType>$values)';
}

/// A property extraction expression, such as: `(e).foo`
// TODO(sigmund): consider merging it into binary?
class Load extends Expression {
  final Expression left;
  final String name;
  Load(this.left, this.name);

  bool get isLoad => true;
  accept(v) => v.visitLoad(this);
  toString() => '$left.$name';
}

/// A map literal like: `{'a': 2}`.
class MapLiteral extends Expression {
  final List<TypeRef> types;
  final List<KeyValuePair> values;
  final bool isConst;

  MapLiteral(this.types, this.values, this.isConst) {
    assert(types.length <= 2);
  }

  accept(v) => v.visitMap(this);
  toString() => '(map<${types.map((t) => "$t").join(", ")}>: $values)';
}

/// Representation for a named argument.
class NamedArg {
  final String name;
  final Expression value;
  NamedArg(this.name, this.value);
}

/// The `null` literal.
class NullLiteral extends Expression {
  NullLiteral();

  accept(v) => v.visitNull(this);
  toString() => 'null';
}

/// An opaque expression with possibly a known type.
class Opaque extends Expression {
  final TypeRef type;
  final String hint;

  Opaque({this.type, this.hint});

  accept(v) => v.visitOpaque(this);

  toString() {
    var sb = new StringBuffer();
    sb.write('(o:');
    if (hint != null) sb.write(' $hint');
    if (type != null) sb.write(' $type');
    return '$sb)';
  }
}

/// Marker that some part of the AST was abstracted away.
///
/// This node does not provide additional information, other than indicating
/// that the AST does not include the full initializer. For example,
/// this is in assignments, pre and postfix operators, and cascades to indicate
/// that we ignored part of those complex expressions.
class OpaqueOp extends Expression {
  final Expression exp;
  final String hint;
  OpaqueOp(this.exp, {this.hint});

  bool get isOpaqueOp => true;
  accept(v) => v.visitOpaqueOp(this);
}

/// A name reference.
class Ref extends Expression {
  final String name;
  final Ref prefix;

  Ref(this.name, [this.prefix]) {
    assert(prefixDepth <= 2);
  }

  bool get isRef => true;

  int get prefixDepth => prefix == null ? 0 : prefix.prefixDepth;
  accept(v) => v.visitRef(this);
  toString() => 'r:${prefix == null ? "" : "$prefix."}$name';
}

/// A literal like `"foo"`.
class StringLiteral extends Expression {
  final String value;
  StringLiteral(this.value);

  accept(v) => v.visitString(this);
  toString() => '$value';
}

/// A literal like `#foo.bar`.
class SymbolLiteral extends Expression {
  final String value;
  SymbolLiteral(this.value);

  accept(v) => v.visitSymbol(this);
  toString() => '#$value';
}

/// A reference to a type (used for opaque nodes, is checks, and as checks).
///
/// Note that types are not nodes in the expression tree.
class TypeRef {
  final Ref name;
  final List<TypeRef> typeArguments;
  TypeRef(this.name, this.typeArguments);

  toString() {
    var args = typeArguments == null ? "" : "<${typeArguments.join(', ')}>";
    return 't:$name$args';
  }
}

/// All unary expressions, such as `-1` or `!b`
class Unary extends Expression {
  final Expression exp;
  final int operator;
  Unary(this.exp, this.operator);

  bool get isUnary => true;
  accept(v) => v.visitUnary(this);
  toString() => '_ $exp';
}
