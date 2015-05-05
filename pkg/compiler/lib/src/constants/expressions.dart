// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.constants.expressions;

import '../dart2jslib.dart' show assertDebugMode;
import '../dart_types.dart';
import '../elements/elements.dart' show
    ConstructorElement,
    Element,
    FunctionElement,
    PrefixElement,
    VariableElement;
import '../resolution/operators.dart';
import '../universe/universe.dart' show CallStructure;
import 'values.dart';

enum ConstantExpressionKind {
  BINARY,
  BOOL,
  CONCATENATE,
  CONDITIONAL,
  CONSTRUCTED,
  DEFERRED,
  DOUBLE,
  ERRONEOUS,
  FUNCTION,
  IDENTICAL,
  INT,
  LIST,
  MAP,
  NULL,
  STRING,
  SYMBOL,
  TYPE,
  UNARY,
  VARIABLE,
}

/// An expression that is a compile-time constant.
///
/// Whereas [ConstantValue] represent a compile-time value, a
/// [ConstantExpression] represents an expression for creating a constant.
///
/// There is no one-to-one mapping between [ConstantExpression] and
/// [ConstantValue], because different expressions can denote the same constant.
/// For instance, multiple `const` constructors may be used to create the same
/// object, and different `const` variables may hold the same value.
abstract class ConstantExpression {
  int _hashCode;

  ConstantExpressionKind get kind;

  /// Returns the value of this constant expression.
  ConstantValue get value;

  // TODO(johnniwinther): Unify precedence handled between constants, front-end
  // and back-end.
  int get precedence => 16;

  accept(ConstantExpressionVisitor visitor, [context]);

  String getText() {
    ConstExpPrinter printer = new ConstExpPrinter();
    accept(printer);
    return printer.toString();
  }

  int _computeHashCode();

  int get hashCode {
    if (_hashCode == null) {
      _hashCode = _computeHashCode();
    }
    return _hashCode;
  }

  bool _equals(ConstantExpression other);

  bool operator ==(other) {
    if (identical(this, other)) return true;
    if (other is! ConstantExpression) return false;
    if (kind != other.kind) return false;
    if (hashCode != other.hashCode) return false;
    return _equals(other);
  }

  String toString() {
    assertDebugMode('Use ConstantExpression.getText() instead of '
                    'ConstantExpression.toString()');
    return getText();
  }
}

/// A synthetic constant used to recover from errors.
class ErroneousConstantExpression extends ConstantExpression {
  final PrimitiveConstantValue value = new NullConstantValue();

  ConstantExpressionKind get kind => ConstantExpressionKind.ERRONEOUS;

  accept(ConstantExpressionVisitor visitor, [context]) {
    // Do nothing. This is an error.
  }

  @override
  int _computeHashCode() => 13;

  @override
  bool _equals(ErroneousConstantExpression other) => true;
}

/// A boolean, int, double, string, or null constant.
abstract class PrimitiveConstantExpression extends ConstantExpression {
  final PrimitiveConstantValue value;

  PrimitiveConstantExpression(this.value);

  /// The primitive value of this contant expression.
  get primitiveValue;

  accept(ConstantExpressionVisitor visitor, [context]) {
    return visitor.visitPrimitive(this, context);
  }
}

/// Boolean literal constant.
class BoolConstantExpression extends PrimitiveConstantExpression {
  final bool primitiveValue;

  BoolConstantExpression(this.primitiveValue,
                         PrimitiveConstantValue value) : super(value);

  ConstantExpressionKind get kind => ConstantExpressionKind.BOOL;

  @override
  int _computeHashCode() => 13 * primitiveValue.hashCode;

  @override
  bool _equals(BoolConstantExpression other) {
    return primitiveValue == other.primitiveValue;
  }
}

/// Integer literal constant.
class IntConstantExpression extends PrimitiveConstantExpression {
  final int primitiveValue;

  IntConstantExpression(this.primitiveValue,
                        PrimitiveConstantValue value) : super(value);

  ConstantExpressionKind get kind => ConstantExpressionKind.INT;

  @override
  int _computeHashCode() => 17 * primitiveValue.hashCode;

  @override
  bool _equals(IntConstantExpression other) {
    return primitiveValue == other.primitiveValue;
  }
}

/// Double literal constant.
class DoubleConstantExpression extends PrimitiveConstantExpression {
  final double primitiveValue;

  DoubleConstantExpression(this.primitiveValue,
                           PrimitiveConstantValue value) : super(value);

  ConstantExpressionKind get kind => ConstantExpressionKind.DOUBLE;

  @override
  int _computeHashCode() => 19 * primitiveValue.hashCode;

  @override
  bool _equals(DoubleConstantExpression other) {
    return primitiveValue == other.primitiveValue;
  }
}

/// String literal constant.
class StringConstantExpression extends PrimitiveConstantExpression {
  final String primitiveValue;

  StringConstantExpression(this.primitiveValue,
                           PrimitiveConstantValue value) : super(value);

  ConstantExpressionKind get kind => ConstantExpressionKind.STRING;

  @override
  int _computeHashCode() => 23 * primitiveValue.hashCode;

  @override
  bool _equals(StringConstantExpression other) {
    return primitiveValue == other.primitiveValue;
  }
}

/// Null literal constant.
class NullConstantExpression extends PrimitiveConstantExpression {
  NullConstantExpression(PrimitiveConstantValue value) : super(value);

  ConstantExpressionKind get kind => ConstantExpressionKind.NULL;

  get primitiveValue => null;

  @override
  int _computeHashCode() => 29;

  @override
  bool _equals(NullConstantExpression other) => true;
}

/// Literal list constant.
class ListConstantExpression extends ConstantExpression {
  final ListConstantValue value;
  final InterfaceType type;
  final List<ConstantExpression> values;

  ListConstantExpression(this.value, this.type, this.values);

  ConstantExpressionKind get kind => ConstantExpressionKind.LIST;

  accept(ConstantExpressionVisitor visitor, [context]) {
    return visitor.visitList(this, context);
  }

  @override
  int _computeHashCode() {
    int hashCode = 13 * type.hashCode + 17 * values.length;
    for (ConstantExpression value in values) {
      hashCode ^= 19 * value.hashCode;
    }
    return hashCode;
  }

  @override
  bool _equals(ListConstantExpression other) {
    if (type != other.type) return false;
    if (values.length != other.values.length) return false;
    for (int i = 0; i < values.length; i++) {
      if (values[i] != other.values[i]) return false;
    }
    return true;
  }
}

/// Literal map constant.
class MapConstantExpression extends ConstantExpression {
  final MapConstantValue value;
  final InterfaceType type;
  final List<ConstantExpression> keys;
  final List<ConstantExpression> values;

  MapConstantExpression(this.value, this.type, this.keys, this.values);

  ConstantExpressionKind get kind => ConstantExpressionKind.MAP;

  accept(ConstantExpressionVisitor visitor, [context]) {
    return visitor.visitMap(this, context);
  }

  @override
  int _computeHashCode() {
    int hashCode = 13 * type.hashCode + 17 * values.length;
    for (ConstantExpression value in values) {
      hashCode ^= 19 * value.hashCode;
    }
    return hashCode;
  }

  @override
  bool _equals(MapConstantExpression other) {
    if (type != other.type) return false;
    if (values.length != other.values.length) return false;
    for (int i = 0; i < values.length; i++) {
      if (keys[i] != other.keys[i]) return false;
      if (values[i] != other.values[i]) return false;
    }
    return true;
  }
}

/// Invocation of a const constructor.
class ConstructedConstantExpression extends ConstantExpression {
  final ConstantValue value;
  final InterfaceType type;
  final ConstructorElement target;
  final CallStructure callStructure;
  final List<ConstantExpression> arguments;

  ConstructedConstantExpression(
      this.value,
      this.type,
      this.target,
      this.callStructure,
      this.arguments) {
    assert(type.element == target.enclosingClass);
  }

  ConstantExpressionKind get kind => ConstantExpressionKind.CONSTRUCTED;

  accept(ConstantExpressionVisitor visitor, [context]) {
    return visitor.visitConstructed(this, context);
  }

  @override
  int _computeHashCode() {
    int hashCode =
        13 * type.hashCode +
        17 * target.hashCode +
        19 * callStructure.hashCode;
    for (ConstantExpression value in arguments) {
      hashCode ^= 23 * value.hashCode;
    }
    return hashCode;
  }

  @override
  bool _equals(ConstructedConstantExpression other) {
    if (type != other.type) return false;
    if (target != other.target) return false;
    if (callStructure != other.callStructure) return false;
    for (int i = 0; i < arguments.length; i++) {
      if (arguments[i] != other.arguments[i]) return false;
    }
    return true;
  }
}

/// String literal with juxtaposition and/or interpolations.
class ConcatenateConstantExpression extends ConstantExpression {
  final StringConstantValue value;
  final List<ConstantExpression> arguments;

  ConcatenateConstantExpression(this.value, this.arguments);

  ConstantExpressionKind get kind => ConstantExpressionKind.CONCATENATE;

  accept(ConstantExpressionVisitor visitor, [context]) {
    return visitor.visitConcatenate(this, context);
  }

  @override
  int _computeHashCode() {
    int hashCode = 17 * arguments.length;
    for (ConstantExpression value in arguments) {
      hashCode ^= 19 * value.hashCode;
    }
    return hashCode;
  }

  @override
  bool _equals(ConcatenateConstantExpression other) {
    if (arguments.length != other.arguments.length) return false;
    for (int i = 0; i < arguments.length; i++) {
      if (arguments[i] != other.arguments[i]) return false;
    }
    return true;
  }
}

/// Symbol literal.
class SymbolConstantExpression extends ConstantExpression {
  final ConstructedConstantValue value;
  final String name;

  SymbolConstantExpression(this.value, this.name);

  ConstantExpressionKind get kind => ConstantExpressionKind.SYMBOL;

  accept(ConstantExpressionVisitor visitor, [context]) {
    return visitor.visitSymbol(this, context);
  }

  @override
  int _computeHashCode() => 13 * name.hashCode;

  @override
  bool _equals(SymbolConstantExpression other) {
    return name == other.name;
  }
}

/// Type literal.
class TypeConstantExpression extends ConstantExpression {
  final TypeConstantValue value;
  /// Either [DynamicType] or a raw [GenericType].
  final DartType type;

  TypeConstantExpression(this.value, this.type) {
    assert(type is GenericType || type is DynamicType);
  }

  ConstantExpressionKind get kind => ConstantExpressionKind.TYPE;

  accept(ConstantExpressionVisitor visitor, [context]) {
    return visitor.visitType(this, context);
  }

  @override
  int _computeHashCode() => 13 * type.hashCode;

  @override
  bool _equals(TypeConstantExpression other) {
    return type == other.type;
  }
}

/// Reference to a constant local, top-level, or static variable.
class VariableConstantExpression extends ConstantExpression {
  final ConstantValue value;
  final VariableElement element;

  VariableConstantExpression(this.value, this.element);

  ConstantExpressionKind get kind => ConstantExpressionKind.VARIABLE;

  accept(ConstantExpressionVisitor visitor, [context]) {
    return visitor.visitVariable(this, context);
  }

  @override
  int _computeHashCode() => 13 * element.hashCode;

  @override
  bool _equals(VariableConstantExpression other) {
    return element == other.element;
  }
}

/// Reference to a top-level or static function.
class FunctionConstantExpression extends ConstantExpression {
  final FunctionConstantValue value;
  final FunctionElement element;

  FunctionConstantExpression(this.value, this.element);

  ConstantExpressionKind get kind => ConstantExpressionKind.FUNCTION;

  accept(ConstantExpressionVisitor visitor, [context]) {
    return visitor.visitFunction(this, context);
  }

  @override
  int _computeHashCode() => 13 * element.hashCode;

  @override
  bool _equals(FunctionConstantExpression other) {
    return element == other.element;
  }
}

/// A constant binary expression like `a * b`.
class BinaryConstantExpression extends ConstantExpression {
  final ConstantValue value;
  final ConstantExpression left;
  final BinaryOperator operator;
  final ConstantExpression right;

  BinaryConstantExpression(this.value, this.left, this.operator, this.right) {
    assert(PRECEDENCE_MAP[operator.kind] != null);
  }

  ConstantExpressionKind get kind => ConstantExpressionKind.BINARY;

  accept(ConstantExpressionVisitor visitor, [context]) {
    return visitor.visitBinary(this, context);
  }

  int get precedence => PRECEDENCE_MAP[operator.kind];

  @override
  int _computeHashCode() {
    return 13 * operator.hashCode +
           17 * left.hashCode +
           19 * right.hashCode;
  }

  @override
  bool _equals(BinaryConstantExpression other) {
    return operator == other.operator &&
           left == other.left &&
           right == other.right;
  }

  static const Map<BinaryOperatorKind, int> PRECEDENCE_MAP = const {
    BinaryOperatorKind.EQ: 6,
    BinaryOperatorKind.NOT_EQ: 6,
    BinaryOperatorKind.LOGICAL_AND: 5,
    BinaryOperatorKind.LOGICAL_OR: 4,
    BinaryOperatorKind.XOR: 9,
    BinaryOperatorKind.AND: 10,
    BinaryOperatorKind.OR: 8,
    BinaryOperatorKind.SHR: 11,
    BinaryOperatorKind.SHL: 11,
    BinaryOperatorKind.ADD: 12,
    BinaryOperatorKind.SUB: 12,
    BinaryOperatorKind.MUL: 13,
    BinaryOperatorKind.DIV: 13,
    BinaryOperatorKind.IDIV: 13,
    BinaryOperatorKind.GT: 7,
    BinaryOperatorKind.LT: 7,
    BinaryOperatorKind.GTEQ: 7,
    BinaryOperatorKind.LTEQ: 7,
    BinaryOperatorKind.MOD: 13,
  };
}

/// A constant identical invocation like `identical(a, b)`.
class IdenticalConstantExpression extends ConstantExpression {
  final ConstantValue value;
  final ConstantExpression left;
  final ConstantExpression right;

  IdenticalConstantExpression(this.value, this.left, this.right);

  ConstantExpressionKind get kind => ConstantExpressionKind.IDENTICAL;

  accept(ConstantExpressionVisitor visitor, [context]) {
    return visitor.visitIdentical(this, context);
  }

  int get precedence => 15;

  @override
  int _computeHashCode() {
    return 17 * left.hashCode +
           19 * right.hashCode;
  }

  @override
  bool _equals(IdenticalConstantExpression other) {
    return left == other.left &&
           right == other.right;
  }
}

/// A unary constant expression like `-a`.
class UnaryConstantExpression extends ConstantExpression {
  final ConstantValue value;
  final UnaryOperator operator;
  final ConstantExpression expression;

  UnaryConstantExpression(this.value, this.operator, this.expression) {
    assert(PRECEDENCE_MAP[operator.kind] != null);
  }

  ConstantExpressionKind get kind => ConstantExpressionKind.UNARY;

  accept(ConstantExpressionVisitor visitor, [context]) {
    return visitor.visitUnary(this, context);
  }

  int get precedence => PRECEDENCE_MAP[operator.kind];

  @override
  int _computeHashCode() {
    return 13 * operator.hashCode +
           17 * expression.hashCode;
  }

  @override
  bool _equals(UnaryConstantExpression other) {
    return operator == other.operator &&
           expression == other.expression;
  }

  static const Map<UnaryOperatorKind, int> PRECEDENCE_MAP = const {
    UnaryOperatorKind.NOT: 14,
    UnaryOperatorKind.COMPLEMENT: 14,
    UnaryOperatorKind.NEGATE: 14,
  };
}

/// A constant conditional expression like `a ? b : c`.
class ConditionalConstantExpression extends ConstantExpression {
  final ConstantValue value;
  final ConstantExpression condition;
  final ConstantExpression trueExp;
  final ConstantExpression falseExp;

  ConditionalConstantExpression(this.value,
                                this.condition,
                                this.trueExp,
                                this.falseExp);

  ConstantExpressionKind get kind => ConstantExpressionKind.CONDITIONAL;

  accept(ConstantExpressionVisitor visitor, [context]) {
    return visitor.visitConditional(this, context);
  }

  int get precedence => 3;

  @override
  int _computeHashCode() {
    return 13 * condition.hashCode +
           17 * trueExp.hashCode +
           19 * falseExp.hashCode;
  }

  @override
  bool _equals(ConditionalConstantExpression other) {
    return condition == other.condition &&
           trueExp == other.trueExp &&
           falseExp == other.falseExp;
  }
}

/// A constant expression referenced with a deferred prefix.
/// For example `lib.C`.
class DeferredConstantExpression extends ConstantExpression {
  final ConstantValue value;
  final ConstantExpression expression;
  final PrefixElement prefix;

  DeferredConstantExpression(this.value, this.expression, this.prefix);

  ConstantExpressionKind get kind => ConstantExpressionKind.DEFERRED;

  @override
  int _computeHashCode() {
    return 13 * expression.hashCode;
  }

  @override
  bool _equals(DeferredConstantExpression other) {
    return expression == other.expression;
  }

  @override
  accept(ConstantExpressionVisitor visitor, [context]) {
    return visitor.visitDeferred(this, context);
  }
}

abstract class ConstantExpressionVisitor<C, R> {
  const ConstantExpressionVisitor();

  R visit(ConstantExpression constant, C context) {
    return constant.accept(this, context);
  }

  R visitPrimitive(PrimitiveConstantExpression exp, C context);
  R visitList(ListConstantExpression exp, C context);
  R visitMap(MapConstantExpression exp, C context);
  R visitConstructed(ConstructedConstantExpression exp, C context);
  R visitConcatenate(ConcatenateConstantExpression exp, C context);
  R visitSymbol(SymbolConstantExpression exp, C context);
  R visitType(TypeConstantExpression exp, C context);
  R visitVariable(VariableConstantExpression exp, C context);
  R visitFunction(FunctionConstantExpression exp, C context);
  R visitBinary(BinaryConstantExpression exp, C context);
  R visitIdentical(IdenticalConstantExpression exp, C context);
  R visitUnary(UnaryConstantExpression exp, C context);
  R visitConditional(ConditionalConstantExpression exp, C context);
  R visitDeferred(DeferredConstantExpression exp, C context);
}

/// Represents the declaration of a constant [element] with value [expression].
// TODO(johnniwinther): Where does this class belong?
class ConstDeclaration {
  final VariableElement element;
  final ConstantExpression expression;

  ConstDeclaration(this.element, this.expression);
}

class ConstExpPrinter extends ConstantExpressionVisitor {
  final StringBuffer sb = new StringBuffer();

  void write(ConstantExpression parent,
        ConstantExpression child,
        {bool leftAssociative: true}) {
    if (child.precedence < parent.precedence ||
        !leftAssociative && child.precedence == parent.precedence) {
      sb.write('(');
      child.accept(this);
      sb.write(')');
    } else {
      child.accept(this);
    }
  }

  void writeTypeArguments(InterfaceType type) {
    if (type.treatAsRaw) return;
    sb.write('<');
    bool needsComma = false;
    for (DartType value in type.typeArguments) {
      if (needsComma) {
        sb.write(', ');
      }
      sb.write(value);
      needsComma = true;
    }
    sb.write('>');
  }

  @override
  void visit(ConstantExpression constant, [_]) {
    return constant.accept(this, null);
  }

  @override
  void visitPrimitive(PrimitiveConstantExpression exp, [_]) {
    sb.write(exp.value.unparse());
  }

  @override
  void visitList(ListConstantExpression exp, [_]) {
    sb.write('const ');
    writeTypeArguments(exp.type);
    sb.write('[');
    bool needsComma = false;
    for (ConstantExpression value in exp.values) {
      if (needsComma) {
        sb.write(', ');
      }
      visit(value);
      needsComma = true;
    }
    sb.write(']');
  }

  @override
  void visitMap(MapConstantExpression exp, [_]) {
    sb.write('const ');
    writeTypeArguments(exp.type);
    sb.write('{');
    for (int index = 0; index < exp.keys.length; index++) {
      if (index > 0) {
        sb.write(', ');
      }
      visit(exp.keys[index]);
      sb.write(': ');
      visit(exp.values[index]);
    }
    sb.write('}');
  }

  @override
  void visitConstructed(ConstructedConstantExpression exp, [_]) {
    sb.write('const ');
    sb.write(exp.target.enclosingClass.name);
    if (exp.target.name != '') {
      sb.write('.');
      sb.write(exp.target.name);
    }
    writeTypeArguments(exp.type);
    sb.write('(');
    bool needsComma = false;

    int namedOffset = exp.callStructure.positionalArgumentCount;
    for (int index = 0; index < namedOffset; index++) {
      if (needsComma) {
        sb.write(', ');
      }
      visit(exp.arguments[index]);
      needsComma = true;
    }
    for (int index = 0; index < exp.callStructure.namedArgumentCount; index++) {
      if (needsComma) {
        sb.write(', ');
      }
      sb.write(exp.callStructure.namedArguments[index]);
      sb.write(': ');
      visit(exp.arguments[namedOffset + index]);
      needsComma = true;
    }
    sb.write(')');
  }

  @override
  void visitConcatenate(ConcatenateConstantExpression exp, [_]) {
    sb.write(exp.value.unparse());
  }

  @override
  void visitSymbol(SymbolConstantExpression exp, [_]) {
    sb.write('#');
    sb.write(exp.name);
  }

  @override
  void visitType(TypeConstantExpression exp, [_]) {
    sb.write(exp.type.name);
  }

  @override
  void visitVariable(VariableConstantExpression exp, [_]) {
    if (exp.element.isStatic) {
      sb.write(exp.element.enclosingClass.name);
      sb.write('.');
    }
    sb.write(exp.element.name);
  }

  @override
  void visitFunction(FunctionConstantExpression exp, [_]) {
    if (exp.element.isStatic) {
      sb.write(exp.element.enclosingClass.name);
      sb.write('.');
    }
    sb.write(exp.element.name);
  }

  @override
  void visitBinary(BinaryConstantExpression exp, [_]) {
    write(exp, exp.left);
    sb.write(' ');
    sb.write(exp.operator.name);
    sb.write(' ');
    write(exp, exp.right);
  }

  @override
  void visitIdentical(IdenticalConstantExpression exp, [_]) {
    sb.write('identical(');
    visit(exp.left);
    sb.write(', ');
    visit(exp.right);
    sb.write(')');
  }

  @override
  void visitUnary(UnaryConstantExpression exp, [_]) {
    sb.write(exp.operator);
    write(exp, exp.expression);
  }

  @override
  void visitConditional(ConditionalConstantExpression exp, [_]) {
    write(exp, exp.condition, leftAssociative: false);
    sb.write(' ? ');
    write(exp, exp.trueExp);
    sb.write(' : ');
    write(exp, exp.falseExp);
  }

  @override
  visitDeferred(DeferredConstantExpression exp, context) {
    sb.write(exp.prefix.deferredImport.prefix.source);
    sb.write('.');
    write(exp, exp.expression);
  }

  String toString() => sb.toString();
}