// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.constants.expressions;

import '../constants/constant_system.dart';
import '../core_types.dart';
import '../dart_types.dart';
import '../diagnostics/invariant.dart' show
    assertDebugMode;
import '../elements/elements.dart' show
    ConstructorElement,
    Element,
    FieldElement,
    FunctionElement,
    PrefixElement,
    VariableElement;
import '../resolution/operators.dart';
import '../tree/tree.dart' show
    DartString;
import '../universe/call_structure.dart' show
    CallStructure;
import 'evaluation.dart';
import 'values.dart';

enum ConstantExpressionKind {
  BINARY,
  BOOL,
  BOOL_FROM_ENVIRONMENT,
  CONCATENATE,
  CONDITIONAL,
  CONSTRUCTED,
  DEFERRED,
  DOUBLE,
  ERRONEOUS,
  FUNCTION,
  IDENTICAL,
  INT,
  INT_FROM_ENVIRONMENT,
  LIST,
  MAP,
  NULL,
  STRING,
  STRING_FROM_ENVIRONMENT,
  STRING_LENGTH,
  SYMBOL,
  SYNTHETIC,
  TYPE,
  UNARY,
  VARIABLE,

  POSITIONAL_REFERENCE,
  NAMED_REFERENCE,
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

  // TODO(johnniwinther): Unify precedence handled between constants, front-end
  // and back-end.
  int get precedence => 16;

  accept(ConstantExpressionVisitor visitor, [context]);

  /// Substitute free variables using arguments.
  ConstantExpression apply(NormalizedArguments arguments) => this;

  /// Compute the [ConstantValue] for this expression using the [environment]
  /// and the [constantSystem].
  ConstantValue evaluate(Environment environment,
                         ConstantSystem constantSystem);

  /// Returns the type of this constant expression, if it is independent of the
  /// environment values.
  DartType getKnownType(CoreTypes coreTypes) => null;

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
  ConstantExpressionKind get kind => ConstantExpressionKind.ERRONEOUS;

  accept(ConstantExpressionVisitor visitor, [context]) {
    // Do nothing. This is an error.
  }

  @override
  ConstantValue evaluate(Environment environment,
                         ConstantSystem constantSystem) {
    // TODO(johnniwinther): Use non-constant values for errors.
    return new NonConstantValue();
  }

  @override
  int _computeHashCode() => 13;

  @override
  bool _equals(ErroneousConstantExpression other) => true;
}

// TODO(johnniwinther): Avoid the need for this class.
class SyntheticConstantExpression extends ConstantExpression {
  final SyntheticConstantValue value;

  SyntheticConstantExpression(this.value);

  @override
  ConstantValue evaluate(Environment environment,
                         ConstantSystem constantSystem) {
    return value;
  }

  @override
  int _computeHashCode() => 13 * value.hashCode;

  accept(ConstantExpressionVisitor visitor, [context]) {
    throw "unsupported";
  }

  @override
  bool _equals(SyntheticConstantExpression other) {
    return value == other.value;
  }

  ConstantExpressionKind get kind => ConstantExpressionKind.SYNTHETIC;
}



/// A boolean, int, double, string, or null constant.
abstract class PrimitiveConstantExpression extends ConstantExpression {
  /// The primitive value of this contant expression.
  get primitiveValue;
}

/// Boolean literal constant.
class BoolConstantExpression extends PrimitiveConstantExpression {
  final bool primitiveValue;

  BoolConstantExpression(this.primitiveValue);

  ConstantExpressionKind get kind => ConstantExpressionKind.BOOL;

  accept(ConstantExpressionVisitor visitor, [context]) {
    return visitor.visitBool(this, context);
  }

  @override
  ConstantValue evaluate(Environment environment,
                         ConstantSystem constantSystem) {
    return constantSystem.createBool(primitiveValue);
  }

  @override
  int _computeHashCode() => 13 * primitiveValue.hashCode;

  @override
  bool _equals(BoolConstantExpression other) {
    return primitiveValue == other.primitiveValue;
  }

  @override
  DartType getKnownType(CoreTypes coreTypes) => coreTypes.boolType;
}

/// Integer literal constant.
class IntConstantExpression extends PrimitiveConstantExpression {
  final int primitiveValue;

  IntConstantExpression(this.primitiveValue);

  ConstantExpressionKind get kind => ConstantExpressionKind.INT;

  accept(ConstantExpressionVisitor visitor, [context]) {
    return visitor.visitInt(this, context);
  }

  @override
  ConstantValue evaluate(Environment environment,
                         ConstantSystem constantSystem) {
    return constantSystem.createInt(primitiveValue);
  }

  @override
  int _computeHashCode() => 17 * primitiveValue.hashCode;

  @override
  bool _equals(IntConstantExpression other) {
    return primitiveValue == other.primitiveValue;
  }

  @override
  DartType getKnownType(CoreTypes coreTypes) => coreTypes.intType;
}

/// Double literal constant.
class DoubleConstantExpression extends PrimitiveConstantExpression {
  final double primitiveValue;

  DoubleConstantExpression(this.primitiveValue);

  ConstantExpressionKind get kind => ConstantExpressionKind.DOUBLE;

  accept(ConstantExpressionVisitor visitor, [context]) {
    return visitor.visitDouble(this, context);
  }

  @override
  ConstantValue evaluate(Environment environment,
                         ConstantSystem constantSystem) {
    return constantSystem.createDouble(primitiveValue);
  }

  @override
  int _computeHashCode() => 19 * primitiveValue.hashCode;

  @override
  bool _equals(DoubleConstantExpression other) {
    return primitiveValue == other.primitiveValue;
  }

  @override
  DartType getKnownType(CoreTypes coreTypes) => coreTypes.doubleType;
}

/// String literal constant.
class StringConstantExpression extends PrimitiveConstantExpression {
  final String primitiveValue;

  StringConstantExpression(this.primitiveValue);

  ConstantExpressionKind get kind => ConstantExpressionKind.STRING;

  accept(ConstantExpressionVisitor visitor, [context]) {
    return visitor.visitString(this, context);
  }

  @override
  ConstantValue evaluate(Environment environment,
                         ConstantSystem constantSystem) {
    return constantSystem.createString(new DartString.literal(primitiveValue));
  }

  @override
  int _computeHashCode() => 23 * primitiveValue.hashCode;

  @override
  bool _equals(StringConstantExpression other) {
    return primitiveValue == other.primitiveValue;
  }

  @override
  DartType getKnownType(CoreTypes coreTypes) => coreTypes.stringType;
}

/// Null literal constant.
class NullConstantExpression extends PrimitiveConstantExpression {
  NullConstantExpression();

  ConstantExpressionKind get kind => ConstantExpressionKind.NULL;

  accept(ConstantExpressionVisitor visitor, [context]) {
    return visitor.visitNull(this, context);
  }

  @override
  ConstantValue evaluate(Environment environment,
                         ConstantSystem constantSystem) {
    return constantSystem.createNull();
  }

  get primitiveValue => null;

  @override
  int _computeHashCode() => 29;

  @override
  bool _equals(NullConstantExpression other) => true;

  @override
  DartType getKnownType(CoreTypes coreTypes) => coreTypes.nullType;
}

/// Literal list constant.
class ListConstantExpression extends ConstantExpression {
  final InterfaceType type;
  final List<ConstantExpression> values;

  ListConstantExpression(this.type, this.values);

  ConstantExpressionKind get kind => ConstantExpressionKind.LIST;

  accept(ConstantExpressionVisitor visitor, [context]) {
    return visitor.visitList(this, context);
  }

  @override
  ConstantValue evaluate(Environment environment,
                         ConstantSystem constantSystem) {
    return constantSystem.createList(type,
        values.map((v) => v.evaluate(environment, constantSystem)).toList());
  }

  ConstantExpression apply(NormalizedArguments arguments) {
    return new ListConstantExpression(
        type, values.map((v) => v.apply(arguments)).toList());
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

  @override
  DartType getKnownType(CoreTypes coreTypes) => type;
}

/// Literal map constant.
class MapConstantExpression extends ConstantExpression {
  final InterfaceType type;
  final List<ConstantExpression> keys;
  final List<ConstantExpression> values;

  MapConstantExpression(this.type, this.keys, this.values);

  ConstantExpressionKind get kind => ConstantExpressionKind.MAP;

  accept(ConstantExpressionVisitor visitor, [context]) {
    return visitor.visitMap(this, context);
  }

  @override
  ConstantValue evaluate(Environment environment,
                         ConstantSystem constantSystem) {
    return constantSystem.createMap(environment.compiler,
        type,
        keys.map((k) => k.evaluate(environment, constantSystem)).toList(),
        values.map((v) => v.evaluate(environment, constantSystem)).toList());
  }

  ConstantExpression apply(NormalizedArguments arguments) {
    return new MapConstantExpression(
        type,
        keys.map((k) => k.apply(arguments)).toList(),
        values.map((v) => v.apply(arguments)).toList());
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

  @override
  DartType getKnownType(CoreTypes coreTypes) => type;
}

/// Invocation of a const constructor.
class ConstructedConstantExpression extends ConstantExpression {
  final InterfaceType type;
  final ConstructorElement target;
  final CallStructure callStructure;
  final List<ConstantExpression> arguments;

  ConstructedConstantExpression(
      this.type,
      this.target,
      this.callStructure,
      this.arguments) {
    assert(type.element == target.enclosingClass);
    assert(!arguments.contains(null));
  }

  ConstantExpressionKind get kind => ConstantExpressionKind.CONSTRUCTED;

  accept(ConstantExpressionVisitor visitor, [context]) {
    return visitor.visitConstructed(this, context);
  }

  Map<FieldElement, ConstantExpression> computeInstanceFields() {
    return target.constantConstructor.computeInstanceFields(
        arguments, callStructure);
  }

  InterfaceType computeInstanceType() {
    return target.constantConstructor.computeInstanceType(type);
  }

  ConstructedConstantExpression apply(NormalizedArguments arguments) {
    return new ConstructedConstantExpression(
        type, target, callStructure,
        this.arguments.map((a) => a.apply(arguments)).toList());
  }

  @override
  ConstantValue evaluate(Environment environment,
                         ConstantSystem constantSystem) {
    Map<FieldElement, ConstantValue> fieldValues =
        <FieldElement, ConstantValue>{};
    computeInstanceFields().forEach(
        (FieldElement field, ConstantExpression constant) {
      fieldValues[field] = constant.evaluate(environment, constantSystem);
    });
    return new ConstructedConstantValue(computeInstanceType(), fieldValues);
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
  final List<ConstantExpression> expressions;

  ConcatenateConstantExpression(this.expressions);

  ConstantExpressionKind get kind => ConstantExpressionKind.CONCATENATE;

  accept(ConstantExpressionVisitor visitor, [context]) {
    return visitor.visitConcatenate(this, context);
  }

  ConstantExpression apply(NormalizedArguments arguments) {
    return new ConcatenateConstantExpression(
        expressions.map((a) => a.apply(arguments)).toList());
  }

  @override
  ConstantValue evaluate(Environment environment,
                         ConstantSystem constantSystem) {
    DartString accumulator;
    for (ConstantExpression expression in expressions) {
      ConstantValue value = expression.evaluate(environment, constantSystem);
      DartString valueString;
      if (value.isNum || value.isBool) {
        PrimitiveConstantValue primitive = value;
        valueString =
            new DartString.literal(primitive.primitiveValue.toString());
      } else if (value.isString) {
        PrimitiveConstantValue primitive = value;
        valueString = primitive.primitiveValue;
      } else {
        // TODO(johnniwinther): Specialize message to indicated that the problem
        // is not constness but the types of the const expressions.
        return new NonConstantValue();
      }
      if (accumulator == null) {
        accumulator = valueString;
      } else {
        accumulator = new DartString.concat(accumulator, valueString);
      }
    }
    return constantSystem.createString(accumulator);
  }

  @override
  int _computeHashCode() {
    int hashCode = 17 * expressions.length;
    for (ConstantExpression value in expressions) {
      hashCode ^= 19 * value.hashCode;
    }
    return hashCode;
  }

  @override
  bool _equals(ConcatenateConstantExpression other) {
    if (expressions.length != other.expressions.length) return false;
    for (int i = 0; i < expressions.length; i++) {
      if (expressions[i] != other.expressions[i]) return false;
    }
    return true;
  }

  @override
  DartType getKnownType(CoreTypes coreTypes) => coreTypes.stringType;
}

/// Symbol literal.
class SymbolConstantExpression extends ConstantExpression {
  final String name;

  SymbolConstantExpression(this.name);

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

  @override
  ConstantValue evaluate(Environment environment,
                         ConstantSystem constantSystem) {
    // TODO(johnniwinther): Implement this.
    throw new UnsupportedError('SymbolConstantExpression.evaluate');
  }

  @override
  DartType getKnownType(CoreTypes coreTypes) => coreTypes.symbolType;
}

/// Type literal.
class TypeConstantExpression extends ConstantExpression {
  /// Either [DynamicType] or a raw [GenericType].
  final DartType type;

  TypeConstantExpression(this.type) {
    assert(type is GenericType || type is DynamicType);
  }

  ConstantExpressionKind get kind => ConstantExpressionKind.TYPE;

  accept(ConstantExpressionVisitor visitor, [context]) {
    return visitor.visitType(this, context);
  }

  @override
  ConstantValue evaluate(Environment environment,
                         ConstantSystem constantSystem) {
    return constantSystem.createType(environment.compiler, type);
  }

  @override
  int _computeHashCode() => 13 * type.hashCode;

  @override
  bool _equals(TypeConstantExpression other) {
    return type == other.type;
  }

  @override
  DartType getKnownType(CoreTypes coreTypes) => coreTypes.typeType;
}

/// Reference to a constant local, top-level, or static variable.
class VariableConstantExpression extends ConstantExpression {
  final VariableElement element;

  VariableConstantExpression(this.element);

  ConstantExpressionKind get kind => ConstantExpressionKind.VARIABLE;

  accept(ConstantExpressionVisitor visitor, [context]) {
    return visitor.visitVariable(this, context);
  }

  @override
  ConstantValue evaluate(Environment environment,
                         ConstantSystem constantSystem) {
    return element.constant.evaluate(environment, constantSystem);
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
  final FunctionElement element;

  FunctionConstantExpression(this.element);

  ConstantExpressionKind get kind => ConstantExpressionKind.FUNCTION;

  accept(ConstantExpressionVisitor visitor, [context]) {
    return visitor.visitFunction(this, context);
  }

  @override
  ConstantValue evaluate(Environment environment,
                         ConstantSystem constantSystem) {
    return new FunctionConstantValue(element);
  }

  @override
  int _computeHashCode() => 13 * element.hashCode;

  @override
  bool _equals(FunctionConstantExpression other) {
    return element == other.element;
  }

  @override
  DartType getKnownType(CoreTypes coreTypes) => coreTypes.functionType;
}

/// A constant binary expression like `a * b`.
class BinaryConstantExpression extends ConstantExpression {
  final ConstantExpression left;
  final BinaryOperator operator;
  final ConstantExpression right;

  BinaryConstantExpression(this.left, this.operator, this.right) {
    assert(PRECEDENCE_MAP[operator.kind] != null);
  }

  ConstantExpressionKind get kind => ConstantExpressionKind.BINARY;

  accept(ConstantExpressionVisitor visitor, [context]) {
    return visitor.visitBinary(this, context);
  }

  @override
  ConstantValue evaluate(Environment environment,
                         ConstantSystem constantSystem) {
    return constantSystem.lookupBinary(operator).fold(
        left.evaluate(environment, constantSystem),
        right.evaluate(environment, constantSystem));
  }

  ConstantExpression apply(NormalizedArguments arguments) {
    return new BinaryConstantExpression(
        left.apply(arguments),
        operator,
        right.apply(arguments));
  }

  DartType getKnownType(CoreTypes coreTypes) {
    DartType knownLeftType = left.getKnownType(coreTypes);
    DartType knownRightType = right.getKnownType(coreTypes);
    switch (operator.kind) {
      case BinaryOperatorKind.EQ:
      case BinaryOperatorKind.NOT_EQ:
      case BinaryOperatorKind.LOGICAL_AND:
      case BinaryOperatorKind.LOGICAL_OR:
      case BinaryOperatorKind.GT:
      case BinaryOperatorKind.LT:
      case BinaryOperatorKind.GTEQ:
      case BinaryOperatorKind.LTEQ:
        return coreTypes.boolType;
      case BinaryOperatorKind.ADD:
        if (knownLeftType == coreTypes.stringType) {
          assert(knownRightType == coreTypes.stringType);
          return coreTypes.stringType;
        } else if (knownLeftType == coreTypes.intType &&
                   knownRightType == coreTypes.intType) {
          return coreTypes.intType;
        }
        assert(knownLeftType == coreTypes.doubleType ||
               knownRightType == coreTypes.doubleType);
        return coreTypes.doubleType;
      case BinaryOperatorKind.SUB:
      case BinaryOperatorKind.MUL:
      case BinaryOperatorKind.MOD:
        if (knownLeftType == coreTypes.intType &&
            knownRightType == coreTypes.intType) {
          return coreTypes.intType;
        }
        assert(knownLeftType == coreTypes.doubleType ||
               knownRightType == coreTypes.doubleType);
        return coreTypes.doubleType;
      case BinaryOperatorKind.DIV:
        return coreTypes.doubleType;
      case BinaryOperatorKind.IDIV:
        return coreTypes.intType;
      case BinaryOperatorKind.AND:
      case BinaryOperatorKind.OR:
      case BinaryOperatorKind.XOR:
      case BinaryOperatorKind.SHR:
      case BinaryOperatorKind.SHL:
        return coreTypes.intType;
      case BinaryOperatorKind.IF_NULL:
      case BinaryOperatorKind.INDEX:
        throw new UnsupportedError(
            'Unexpected constant binary operator: $operator');
    }
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
  final ConstantExpression left;
  final ConstantExpression right;

  IdenticalConstantExpression(this.left, this.right);

  ConstantExpressionKind get kind => ConstantExpressionKind.IDENTICAL;

  accept(ConstantExpressionVisitor visitor, [context]) {
    return visitor.visitIdentical(this, context);
  }

  @override
  ConstantValue evaluate(Environment environment,
                         ConstantSystem constantSystem) {
    return constantSystem.identity.fold(
        left.evaluate(environment, constantSystem),
        right.evaluate(environment, constantSystem));
  }

  ConstantExpression apply(NormalizedArguments arguments) {
    return new IdenticalConstantExpression(
        left.apply(arguments),
        right.apply(arguments));
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

  @override
  DartType getKnownType(CoreTypes coreTypes) => coreTypes.boolType;
}

/// A unary constant expression like `-a`.
class UnaryConstantExpression extends ConstantExpression {
  final UnaryOperator operator;
  final ConstantExpression expression;

  UnaryConstantExpression(this.operator, this.expression) {
    assert(PRECEDENCE_MAP[operator.kind] != null);
  }

  ConstantExpressionKind get kind => ConstantExpressionKind.UNARY;

  accept(ConstantExpressionVisitor visitor, [context]) {
    return visitor.visitUnary(this, context);
  }

  @override
  ConstantValue evaluate(Environment environment,
                         ConstantSystem constantSystem) {
    return constantSystem.lookupUnary(operator).fold(
        expression.evaluate(environment, constantSystem));
  }

  ConstantExpression apply(NormalizedArguments arguments) {
    return new UnaryConstantExpression(
        operator,
        expression.apply(arguments));
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

  @override
  DartType getKnownType(CoreTypes coreTypes) {
    return expression.getKnownType(coreTypes);
  }

  static const Map<UnaryOperatorKind, int> PRECEDENCE_MAP = const {
    UnaryOperatorKind.NOT: 14,
    UnaryOperatorKind.COMPLEMENT: 14,
    UnaryOperatorKind.NEGATE: 14,
  };
}


/// A string length constant expression like `a.length`.
class StringLengthConstantExpression extends ConstantExpression {
  final ConstantExpression expression;

  StringLengthConstantExpression(this.expression);

  ConstantExpressionKind get kind => ConstantExpressionKind.STRING_LENGTH;

  accept(ConstantExpressionVisitor visitor, [context]) {
    return visitor.visitStringLength(this, context);
  }

  @override
  ConstantValue evaluate(Environment environment,
                         ConstantSystem constantSystem) {
    ConstantValue value = expression.evaluate(environment, constantSystem);
    if (value.isString) {
      StringConstantValue stringValue = value;
      return constantSystem.createInt(stringValue.primitiveValue.length);
    }
    return new NonConstantValue();
  }

  ConstantExpression apply(NormalizedArguments arguments) {
    return new StringLengthConstantExpression(expression.apply(arguments));
  }

  int get precedence => 15;

  @override
  int _computeHashCode() {
    return 23 * expression.hashCode;
  }

  @override
  bool _equals(StringLengthConstantExpression other) {
    return expression == other.expression;
  }

  @override
  DartType getKnownType(CoreTypes coreTypes) => coreTypes.intType;
}

/// A constant conditional expression like `a ? b : c`.
class ConditionalConstantExpression extends ConstantExpression {
  final ConstantExpression condition;
  final ConstantExpression trueExp;
  final ConstantExpression falseExp;

  ConditionalConstantExpression(this.condition,
                                this.trueExp,
                                this.falseExp);

  ConstantExpressionKind get kind => ConstantExpressionKind.CONDITIONAL;

  accept(ConstantExpressionVisitor visitor, [context]) {
    return visitor.visitConditional(this, context);
  }

  ConstantExpression apply(NormalizedArguments arguments) {
    return new ConditionalConstantExpression(
        condition.apply(arguments),
        trueExp.apply(arguments),
        falseExp.apply(arguments));
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

  @override
  ConstantValue evaluate(Environment environment,
                         ConstantSystem constantSystem) {
    ConstantValue conditionValue =
        condition.evaluate(environment, constantSystem);
    ConstantValue trueValue =
        trueExp.evaluate(environment, constantSystem);
    ConstantValue falseValue =
        falseExp.evaluate(environment, constantSystem);
    if (conditionValue.isTrue) {
      return trueValue;
    } else if (conditionValue.isFalse) {
      return falseValue;
    } else {
      return new NonConstantValue();
    }
  }

  @override
  DartType getKnownType(CoreTypes coreTypes) {
    DartType trueType = trueExp.getKnownType(coreTypes);
    DartType falseType = falseExp.getKnownType(coreTypes);
    if (trueType == falseType) {
      return trueType;
    }
    return null;
  }
}

/// A reference to a position parameter.
class PositionalArgumentReference extends ConstantExpression {
  final int index;

  PositionalArgumentReference(this.index);

  ConstantExpressionKind get kind {
    return ConstantExpressionKind.POSITIONAL_REFERENCE;
  }

  accept(ConstantExpressionVisitor visitor, [context]) {
    return visitor.visitPositional(this, context);
  }

  ConstantExpression apply(NormalizedArguments arguments) {
    return arguments.getPositionalArgument(index);
  }

  @override
  int _computeHashCode() => 13 * index.hashCode;

  @override
  bool _equals(PositionalArgumentReference other) => index == other.index;

  @override
  ConstantValue evaluate(Environment environment,
                         ConstantSystem constantSystem) {
    throw new UnsupportedError('PositionalArgumentReference.evaluate');
  }
}

/// A reference to a named parameter.
class NamedArgumentReference extends ConstantExpression {
  final String name;

  NamedArgumentReference(this.name);

  ConstantExpressionKind get kind {
    return ConstantExpressionKind.NAMED_REFERENCE;
  }

  accept(ConstantExpressionVisitor visitor, [context]) {
    return visitor.visitNamed(this, context);
  }

  ConstantExpression apply(NormalizedArguments arguments) {
    return arguments.getNamedArgument(name);
  }

  @override
  int _computeHashCode() => 13 * name.hashCode;

  @override
  bool _equals(NamedArgumentReference other) => name == other.name;

  @override
  ConstantValue evaluate(Environment environment,
                         ConstantSystem constantSystem) {
    throw new UnsupportedError('NamedArgumentReference.evaluate');
  }
}

abstract class FromEnvironmentConstantExpression extends ConstantExpression {
  final ConstantExpression name;
  final ConstantExpression defaultValue;

  FromEnvironmentConstantExpression(this.name, this.defaultValue);

  @override
  int _computeHashCode() {
    return 13 * name.hashCode +
           17 * defaultValue.hashCode;
  }

  @override
  bool _equals(FromEnvironmentConstantExpression other) {
    return name == other.name &&
           defaultValue == other.defaultValue;
  }
}

/// A `const bool.fromEnvironment` constant.
class BoolFromEnvironmentConstantExpression
    extends FromEnvironmentConstantExpression {

  BoolFromEnvironmentConstantExpression(
      ConstantExpression name,
      ConstantExpression defaultValue)
      : super(name, defaultValue);

  ConstantExpressionKind get kind {
    return ConstantExpressionKind.BOOL_FROM_ENVIRONMENT;
  }

  accept(ConstantExpressionVisitor visitor, [context]) {
    return visitor.visitBoolFromEnvironment(this, context);
  }

  @override
  ConstantValue evaluate(Environment environment,
                         ConstantSystem constantSystem) {
    ConstantValue nameConstantValue =
        name.evaluate(environment, constantSystem);
    ConstantValue defaultConstantValue;
    if (defaultValue != null) {
      defaultConstantValue =
          defaultValue.evaluate(environment, constantSystem);
    } else {
      defaultConstantValue = constantSystem.createBool(false);
    }
    if (!nameConstantValue.isString) {
      return new NonConstantValue();
    }
    StringConstantValue nameStringConstantValue = nameConstantValue;
    String text = environment.readFromEnvironment(
        nameStringConstantValue.primitiveValue.slowToString());
    if (text == 'true') {
      return constantSystem.createBool(true);
    } else if (text == 'false') {
      return constantSystem.createBool(false);
    } else {
      return defaultConstantValue;
    }
  }

  ConstantExpression apply(NormalizedArguments arguments) {
    return new BoolFromEnvironmentConstantExpression(
        name.apply(arguments),
        defaultValue != null ? defaultValue.apply(arguments) : null);
  }

  @override
  DartType getKnownType(CoreTypes coreTypes) => coreTypes.boolType;
}

/// A `const int.fromEnvironment` constant.
class IntFromEnvironmentConstantExpression
    extends FromEnvironmentConstantExpression {

  IntFromEnvironmentConstantExpression(
      ConstantExpression name,
      ConstantExpression defaultValue)
      : super(name, defaultValue);

  ConstantExpressionKind get kind {
    return ConstantExpressionKind.INT_FROM_ENVIRONMENT;
  }

  accept(ConstantExpressionVisitor visitor, [context]) {
    return visitor.visitIntFromEnvironment(this, context);
  }

  @override
  ConstantValue evaluate(Environment environment,
                         ConstantSystem constantSystem) {
    ConstantValue nameConstantValue =
        name.evaluate(environment, constantSystem);
    ConstantValue defaultConstantValue;
    if (defaultValue != null) {
      defaultConstantValue =
          defaultValue.evaluate(environment, constantSystem);
    } else {
      defaultConstantValue = constantSystem.createNull();
    }
    if (!nameConstantValue.isString) {
      return new NonConstantValue();
    }
    StringConstantValue nameStringConstantValue = nameConstantValue;
    String text = environment.readFromEnvironment(
        nameStringConstantValue.primitiveValue.slowToString());
    int value;
    if (text != null) {
      value = int.parse(text, onError: (_) => null);
    }
    if (value == null) {
      return defaultConstantValue;
    } else {
      return constantSystem.createInt(value);
    }
  }

  ConstantExpression apply(NormalizedArguments arguments) {
    return new IntFromEnvironmentConstantExpression(
        name.apply(arguments),
        defaultValue != null ? defaultValue.apply(arguments) : null);
  }

  @override
  DartType getKnownType(CoreTypes coreTypes) => coreTypes.intType;
}

/// A `const String.fromEnvironment` constant.
class StringFromEnvironmentConstantExpression
    extends FromEnvironmentConstantExpression {

  StringFromEnvironmentConstantExpression(
      ConstantExpression name,
      ConstantExpression defaultValue)
      : super(name, defaultValue);

  ConstantExpressionKind get kind {
    return ConstantExpressionKind.STRING_FROM_ENVIRONMENT;
  }

  accept(ConstantExpressionVisitor visitor, [context]) {
    return visitor.visitStringFromEnvironment(this, context);
  }

  @override
  ConstantValue evaluate(Environment environment,
                         ConstantSystem constantSystem) {
    ConstantValue nameConstantValue =
        name.evaluate(environment, constantSystem);
    ConstantValue defaultConstantValue;
    if (defaultValue != null) {
      defaultConstantValue =
          defaultValue.evaluate(environment, constantSystem);
    } else {
      defaultConstantValue = constantSystem.createNull();
    }
    if (!nameConstantValue.isString) {
      return new NonConstantValue();
    }
    StringConstantValue nameStringConstantValue = nameConstantValue;
    String text = environment.readFromEnvironment(
        nameStringConstantValue.primitiveValue.slowToString());
    if (text == null) {
      return defaultConstantValue;
    } else {
      return constantSystem.createString(new DartString.literal(text));
    }
  }

  ConstantExpression apply(NormalizedArguments arguments) {
    return new StringFromEnvironmentConstantExpression(
        name.apply(arguments),
        defaultValue != null ? defaultValue.apply(arguments) : null);
  }

  @override
  DartType getKnownType(CoreTypes coreTypes) => coreTypes.stringType;
}

/// A constant expression referenced with a deferred prefix.
/// For example `lib.C`.
class DeferredConstantExpression extends ConstantExpression {
  final ConstantExpression expression;
  final PrefixElement prefix;

  DeferredConstantExpression(this.expression, this.prefix);

  ConstantExpressionKind get kind => ConstantExpressionKind.DEFERRED;

  @override
  ConstantValue evaluate(Environment environment,
                         ConstantSystem constantSystem) {
    return expression.evaluate(environment, constantSystem);
  }

  @override
  int _computeHashCode() {
    return 13 * expression.hashCode;
  }

  ConstantExpression apply(NormalizedArguments arguments) {
    return new DeferredConstantExpression(
        expression.apply(arguments), prefix);
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

abstract class ConstantExpressionVisitor<R, A> {
  const ConstantExpressionVisitor();

  R visit(ConstantExpression constant, A context) {
    return constant.accept(this, context);
  }

  R visitBool(BoolConstantExpression exp, A context);
  R visitInt(IntConstantExpression exp, A context);
  R visitDouble(DoubleConstantExpression exp, A context);
  R visitString(StringConstantExpression exp, A context);
  R visitNull(NullConstantExpression exp, A context);
  R visitList(ListConstantExpression exp, A context);
  R visitMap(MapConstantExpression exp, A context);
  R visitConstructed(ConstructedConstantExpression exp, A context);
  R visitConcatenate(ConcatenateConstantExpression exp, A context);
  R visitSymbol(SymbolConstantExpression exp, A context);
  R visitType(TypeConstantExpression exp, A context);
  R visitVariable(VariableConstantExpression exp, A context);
  R visitFunction(FunctionConstantExpression exp, A context);
  R visitBinary(BinaryConstantExpression exp, A context);
  R visitIdentical(IdenticalConstantExpression exp, A context);
  R visitUnary(UnaryConstantExpression exp, A context);
  R visitStringLength(StringLengthConstantExpression exp, A context);
  R visitConditional(ConditionalConstantExpression exp, A context);
  R visitBoolFromEnvironment(BoolFromEnvironmentConstantExpression exp,
                             A context);
  R visitIntFromEnvironment(IntFromEnvironmentConstantExpression exp,
                            A context);
  R visitStringFromEnvironment(StringFromEnvironmentConstantExpression exp,
                               A context);
  R visitDeferred(DeferredConstantExpression exp, A context);

  R visitPositional(PositionalArgumentReference exp, A context);
  R visitNamed(NamedArgumentReference exp, A context);
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

  void visitPrimitive(PrimitiveConstantExpression exp) {
    sb.write(exp.primitiveValue);
  }

  @override
  void visitBool(BoolConstantExpression exp, [_]) {
    visitPrimitive(exp);
  }

  @override
  void visitDouble(DoubleConstantExpression exp, [_]) {
    visitPrimitive(exp);
  }

  @override
  void visitInt(IntConstantExpression exp, [_]) {
    visitPrimitive(exp);
  }

  @override
  void visitNull(NullConstantExpression exp, [_]) {
    visitPrimitive(exp);
  }

  @override
  void visitString(StringConstantExpression exp, [_]) {
    // TODO(johnniwinther): Ensure correct escaping.
    sb.write('"${exp.primitiveValue}"');
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
    writeTypeArguments(exp.type);
    if (exp.target.name != '') {
      sb.write('.');
      sb.write(exp.target.name);
    }
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
    sb.write('"');
    for (ConstantExpression expression in exp.expressions) {
      if (expression.kind == ConstantExpressionKind.STRING) {
        StringConstantExpression string = expression;
        // TODO(johnniwinther): Ensure correct escaping.
        sb.write('${string.primitiveValue}');
      } else {
        sb.write(r"${");
        visit(expression);
        sb.write("}");
      }

    }
    sb.write('"');
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
  void visitStringLength(StringLengthConstantExpression exp, [_]) {
    write(exp, exp.expression, leftAssociative: false);
    sb.write('.length');
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
  void visitPositional(PositionalArgumentReference exp, [_]) {
    // TODO(johnniwinther): Maybe this should throw.
    sb.write('args[${exp.index}]');
  }

  @override
  void visitNamed(NamedArgumentReference exp, [_]) {
    // TODO(johnniwinther): Maybe this should throw.
    sb.write('args[${exp.name}]');
  }

  @override
  void visitDeferred(DeferredConstantExpression exp, context) {
    sb.write(exp.prefix.name);
    sb.write('.');
    write(exp, exp.expression);
  }

  @override
  void visitBoolFromEnvironment(BoolFromEnvironmentConstantExpression exp,
                                [_]) {
    sb.write('const bool.fromEnvironment(');
    visit(exp.name);
    if (exp.defaultValue != null) {
      sb.write(', defaultValue: ');
      visit(exp.defaultValue);
    }
    sb.write(')');
  }

  @override
  void visitIntFromEnvironment(IntFromEnvironmentConstantExpression exp, [_]) {
    sb.write('const int.fromEnvironment(');
    visit(exp.name);
    if (exp.defaultValue != null) {
      sb.write(', defaultValue: ');
      visit(exp.defaultValue);
    }
    sb.write(')');
  }

  @override
  void visitStringFromEnvironment(StringFromEnvironmentConstantExpression exp,
                                  [_]) {
    sb.write('const String.fromEnvironment(');
    visit(exp.name);
    if (exp.defaultValue != null) {
      sb.write(', defaultValue: ');
      visit(exp.defaultValue);
    }
    sb.write(')');
  }

  String toString() => sb.toString();
}