// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.constants.expressions;

import '../common.dart';
import '../constants/constant_system.dart';
import '../common_elements.dart';
import '../elements/entities.dart';
import '../elements/operators.dart';
import '../elements/types.dart';
import '../universe/call_structure.dart' show CallStructure;
import 'constructors.dart';
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
  FIELD,
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
  LOCAL_VARIABLE,
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
  ConstantValue evaluate(
      EvaluationEnvironment environment, ConstantSystem constantSystem);

  /// Returns the type of this constant expression, if it is independent of the
  /// environment values.
  DartType getKnownType(CommonElements commonElements) => null;

  /// Returns a text string resembling the Dart code creating this constant.
  String toDartText() {
    ConstExpPrinter printer = new ConstExpPrinter();
    accept(printer);
    return printer.toString();
  }

  /// Returns a text string showing the structure of this constant.
  String toStructuredText() {
    StringBuffer sb = new StringBuffer();
    _createStructuredText(sb);
    return sb.toString();
  }

  /// Writes the structure of the constant into [sb].
  void _createStructuredText(StringBuffer sb);

  int _computeHashCode();

  int get hashCode => _hashCode ??= _computeHashCode();

  bool _equals(covariant ConstantExpression other);

  bool operator ==(other) {
    if (identical(this, other)) return true;
    if (other is! ConstantExpression) return false;
    if (kind != other.kind) return false;
    if (hashCode != other.hashCode) return false;
    return _equals(other);
  }

  String toString() {
    assertDebugMode('Use ConstantExpression.toDartText() or '
        'ConstantExpression.toStructuredText() instead of '
        'ConstantExpression.toString()');
    return toDartText();
  }

  /// Returns `true` if this expression is implicitly constant, that is, that
  /// it doesn't declare its constness with the 'const' keyword.
  ///
  /// Implicit constants are simple literals, like bool, int and string
  /// literals, constant references and compositions of implicit constants.
  /// Explicit constants are constructor constants, and constant map and list
  /// literals.
  bool get isImplicit => true;

  /// Returns `true` if this expression is only potentially constant, that is,
  /// if it contains positional or named references, used to define constant
  /// constructors.
  // TODO(johnniwinther): Maybe make this final if we use it outside assertions.
  bool get isPotential => false;
}

/// A synthetic constant used to recover from errors.
class ErroneousConstantExpression extends ConstantExpression {
  ConstantExpressionKind get kind => ConstantExpressionKind.ERRONEOUS;

  accept(ConstantExpressionVisitor visitor, [context]) {
    // Do nothing. This is an error.
  }

  @override
  ConstantValue evaluate(
      EvaluationEnvironment environment, ConstantSystem constantSystem) {
    // TODO(johnniwinther): Use non-constant values for errors.
    return new NonConstantValue();
  }

  @override
  void _createStructuredText(StringBuffer sb) {
    sb.write('Erroneous()');
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
  ConstantValue evaluate(
      EvaluationEnvironment environment, ConstantSystem constantSystem) {
    return value;
  }

  @override
  void _createStructuredText(StringBuffer sb) {
    sb.write('Synthetic(value=${value.toStructuredText()})');
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

  @override
  bool get isImplicit => false;
}

/// A boolean, int, double, string, or null constant.
abstract class PrimitiveConstantExpression extends ConstantExpression {
  /// The primitive value of this constant expression.
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
  void _createStructuredText(StringBuffer sb) {
    sb.write('Bool(value=${primitiveValue})');
  }

  @override
  ConstantValue evaluate(
      EvaluationEnvironment environment, ConstantSystem constantSystem) {
    return constantSystem.createBool(primitiveValue);
  }

  @override
  int _computeHashCode() => 13 * primitiveValue.hashCode;

  @override
  bool _equals(BoolConstantExpression other) {
    return primitiveValue == other.primitiveValue;
  }

  @override
  InterfaceType getKnownType(CommonElements commonElements) =>
      commonElements.boolType;
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
  void _createStructuredText(StringBuffer sb) {
    sb.write('Int(value=${primitiveValue})');
  }

  @override
  ConstantValue evaluate(
      EvaluationEnvironment environment, ConstantSystem constantSystem) {
    return constantSystem.createInt(primitiveValue);
  }

  @override
  int _computeHashCode() => 17 * primitiveValue.hashCode;

  @override
  bool _equals(IntConstantExpression other) {
    return primitiveValue == other.primitiveValue;
  }

  @override
  InterfaceType getKnownType(CommonElements commonElements) =>
      commonElements.intType;
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
  void _createStructuredText(StringBuffer sb) {
    sb.write('Double(value=${primitiveValue})');
  }

  @override
  ConstantValue evaluate(
      EvaluationEnvironment environment, ConstantSystem constantSystem) {
    return constantSystem.createDouble(primitiveValue);
  }

  @override
  int _computeHashCode() => 19 * primitiveValue.hashCode;

  @override
  bool _equals(DoubleConstantExpression other) {
    return primitiveValue == other.primitiveValue;
  }

  @override
  InterfaceType getKnownType(CommonElements commonElements) =>
      commonElements.doubleType;
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
  void _createStructuredText(StringBuffer sb) {
    sb.write('String(value=${primitiveValue})');
  }

  @override
  ConstantValue evaluate(
      EvaluationEnvironment environment, ConstantSystem constantSystem) {
    return constantSystem.createString(primitiveValue);
  }

  @override
  int _computeHashCode() => 23 * primitiveValue.hashCode;

  @override
  bool _equals(StringConstantExpression other) {
    return primitiveValue == other.primitiveValue;
  }

  @override
  InterfaceType getKnownType(CommonElements commonElements) =>
      commonElements.stringType;
}

/// Null literal constant.
class NullConstantExpression extends PrimitiveConstantExpression {
  NullConstantExpression();

  ConstantExpressionKind get kind => ConstantExpressionKind.NULL;

  accept(ConstantExpressionVisitor visitor, [context]) {
    return visitor.visitNull(this, context);
  }

  @override
  void _createStructuredText(StringBuffer sb) {
    sb.write('Null()');
  }

  @override
  ConstantValue evaluate(
      EvaluationEnvironment environment, ConstantSystem constantSystem) {
    return constantSystem.createNull();
  }

  get primitiveValue => null;

  @override
  int _computeHashCode() => 29;

  @override
  bool _equals(NullConstantExpression other) => true;

  @override
  InterfaceType getKnownType(CommonElements commonElements) =>
      commonElements.nullType;
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
  void _createStructuredText(StringBuffer sb) {
    sb.write('List(type=$type,values=[');
    String delimiter = '';
    for (ConstantExpression value in values) {
      sb.write(delimiter);
      value._createStructuredText(sb);
      delimiter = ',';
    }
    sb.write('])');
  }

  @override
  ConstantValue evaluate(
      EvaluationEnvironment environment, ConstantSystem constantSystem) {
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
  DartType getKnownType(CommonElements commonElements) => type;

  @override
  bool get isImplicit => false;

  @override
  bool get isPotential => values.any((e) => e.isPotential);
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
  void _createStructuredText(StringBuffer sb) {
    sb.write('Map(type=$type,entries=[');
    for (int index = 0; index < keys.length; index++) {
      if (index > 0) {
        sb.write(',');
      }
      keys[index]._createStructuredText(sb);
      sb.write('->');
      values[index]._createStructuredText(sb);
    }
    sb.write('])');
  }

  @override
  ConstantValue evaluate(
      EvaluationEnvironment environment, ConstantSystem constantSystem) {
    Map<ConstantValue, ConstantValue> valueMap =
        <ConstantValue, ConstantValue>{};
    for (int index = 0; index < keys.length; index++) {
      ConstantValue key = keys[index].evaluate(environment, constantSystem);
      ConstantValue value = values[index].evaluate(environment, constantSystem);
      valueMap[key] = value;
    }
    return constantSystem.createMap(environment.commonElements, type,
        valueMap.keys.toList(), valueMap.values.toList());
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
  DartType getKnownType(CommonElements commonElements) => type;

  @override
  bool get isImplicit => false;

  @override
  bool get isPotential {
    return keys.any((e) => e.isPotential) || values.any((e) => e.isPotential);
  }
}

/// Invocation of a const constructor.
class ConstructedConstantExpression extends ConstantExpression {
  final InterfaceType type;
  final ConstructorEntity target;
  final CallStructure callStructure;
  final List<ConstantExpression> arguments;

  ConstructedConstantExpression(
      this.type, this.target, this.callStructure, this.arguments) {
    assert(type.element == target.enclosingClass);
    assert(!arguments.contains(null));
  }

  ConstantExpressionKind get kind => ConstantExpressionKind.CONSTRUCTED;

  accept(ConstantExpressionVisitor visitor, [context]) {
    return visitor.visitConstructed(this, context);
  }

  @override
  void _createStructuredText(StringBuffer sb) {
    sb.write('Constructed(type=$type,constructor=$target,'
        'callStructure=$callStructure,arguments=[');
    String delimiter = '';
    for (ConstantExpression value in arguments) {
      sb.write(delimiter);
      value._createStructuredText(sb);
      delimiter = ',';
    }
    sb.write('])');
  }

  Map<FieldEntity, ConstantExpression> computeInstanceFields(
      EvaluationEnvironment environment) {
    ConstantConstructor constantConstructor =
        environment.getConstructorConstant(target);
    assert(constantConstructor != null,
        failedAt(target, "No constant constructor computed for $target."));
    return constantConstructor.computeInstanceFields(
        environment, arguments, callStructure);
  }

  InterfaceType computeInstanceType(EvaluationEnvironment environment) {
    return environment
        .getConstructorConstant(target)
        .computeInstanceType(environment, type);
  }

  ConstructedConstantExpression apply(NormalizedArguments arguments) {
    return new ConstructedConstantExpression(type, target, callStructure,
        this.arguments.map((a) => a.apply(arguments)).toList());
  }

  @override
  ConstantValue evaluate(
      EvaluationEnvironment environment, ConstantSystem constantSystem) {
    Map<FieldEntity, ConstantValue> fieldValues =
        <FieldEntity, ConstantValue>{};
    computeInstanceFields(environment)
        .forEach((FieldEntity field, ConstantExpression constant) {
      fieldValues[field] = constant.evaluate(environment, constantSystem);
    });
    return new ConstructedConstantValue(
        computeInstanceType(environment), fieldValues);
  }

  @override
  int _computeHashCode() {
    int hashCode =
        13 * type.hashCode + 17 * target.hashCode + 19 * callStructure.hashCode;
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

  @override
  bool get isImplicit => false;

  @override
  bool get isPotential {
    return arguments.any((e) => e.isPotential);
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

  @override
  void _createStructuredText(StringBuffer sb) {
    sb.write('Concatenate(expressions=[');
    String delimiter = '';
    for (ConstantExpression value in expressions) {
      sb.write(delimiter);
      value._createStructuredText(sb);
      delimiter = ',';
    }
    sb.write('])');
  }

  ConstantExpression apply(NormalizedArguments arguments) {
    return new ConcatenateConstantExpression(
        expressions.map((a) => a.apply(arguments)).toList());
  }

  @override
  ConstantValue evaluate(
      EvaluationEnvironment environment, ConstantSystem constantSystem) {
    StringBuffer sb = new StringBuffer();
    for (ConstantExpression expression in expressions) {
      ConstantValue value = expression.evaluate(environment, constantSystem);
      if (value.isPrimitive) {
        PrimitiveConstantValue primitive = value;
        sb.write(primitive.primitiveValue);
      } else {
        // TODO(johnniwinther): Specialize message to indicated that the problem
        // is not constness but the types of the const expressions.
        return new NonConstantValue();
      }
    }
    return constantSystem.createString(sb.toString());
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
  InterfaceType getKnownType(CommonElements commonElements) =>
      commonElements.stringType;

  @override
  bool get isPotential {
    return expressions.any((e) => e.isPotential);
  }
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
  void _createStructuredText(StringBuffer sb) {
    sb.write('Symbol(name=$name)');
  }

  @override
  int _computeHashCode() => 13 * name.hashCode;

  @override
  bool _equals(SymbolConstantExpression other) {
    return name == other.name;
  }

  @override
  ConstantValue evaluate(
      EvaluationEnvironment environment, ConstantSystem constantSystem) {
    return constantSystem.createSymbol(environment.commonElements, name);
  }

  @override
  InterfaceType getKnownType(CommonElements commonElements) =>
      commonElements.symbolType;
}

/// Type literal.
class TypeConstantExpression extends ConstantExpression {
  /// Either [DynamicType] or a raw [GenericType].
  final DartType type;
  final String name;

  TypeConstantExpression(this.type, this.name) {
    assert(
        type.isInterfaceType ||
            type.isTypedef ||
            type.isFunctionType ||
            type.isDynamic,
        "Unexpected type constant type: $type");
  }

  ConstantExpressionKind get kind => ConstantExpressionKind.TYPE;

  accept(ConstantExpressionVisitor visitor, [context]) {
    return visitor.visitType(this, context);
  }

  @override
  void _createStructuredText(StringBuffer sb) {
    sb.write('Type(type=$type)');
  }

  @override
  ConstantValue evaluate(
      EvaluationEnvironment environment, ConstantSystem constantSystem) {
    return constantSystem.createType(environment.commonElements, type);
  }

  @override
  int _computeHashCode() => 13 * type.hashCode;

  @override
  bool _equals(TypeConstantExpression other) {
    return type == other.type;
  }

  @override
  InterfaceType getKnownType(CommonElements commonElements) =>
      commonElements.typeType;
}

/// Reference to a constant top-level or static field.
class FieldConstantExpression extends ConstantExpression {
  final FieldEntity element;

  FieldConstantExpression(this.element);

  ConstantExpressionKind get kind => ConstantExpressionKind.FIELD;

  accept(ConstantExpressionVisitor visitor, [context]) {
    return visitor.visitField(this, context);
  }

  @override
  void _createStructuredText(StringBuffer sb) {
    sb.write('Field(element=$element)');
  }

  @override
  ConstantValue evaluate(
      EvaluationEnvironment environment, ConstantSystem constantSystem) {
    ConstantExpression constant = environment.getFieldConstant(element);
    return constant.evaluate(environment, constantSystem);
  }

  @override
  int _computeHashCode() => 13 * element.hashCode;

  @override
  bool _equals(FieldConstantExpression other) {
    return element == other.element;
  }
}

/// Reference to a constant local variable.
class LocalVariableConstantExpression extends ConstantExpression {
  final Local element;

  LocalVariableConstantExpression(this.element);

  ConstantExpressionKind get kind => ConstantExpressionKind.LOCAL_VARIABLE;

  accept(ConstantExpressionVisitor visitor, [context]) {
    return visitor.visitLocalVariable(this, context);
  }

  @override
  void _createStructuredText(StringBuffer sb) {
    sb.write('LocalVariable(element=$element)');
  }

  @override
  ConstantValue evaluate(
      EvaluationEnvironment environment, ConstantSystem constantSystem) {
    ConstantExpression constant = environment.getLocalConstant(element);
    return constant.evaluate(environment, constantSystem);
  }

  @override
  int _computeHashCode() => 13 * element.hashCode;

  @override
  bool _equals(LocalVariableConstantExpression other) {
    return element == other.element;
  }
}

/// Reference to a top-level or static function.
class FunctionConstantExpression extends ConstantExpression {
  final FunctionEntity element;
  final FunctionType type;

  FunctionConstantExpression(this.element, this.type);

  ConstantExpressionKind get kind => ConstantExpressionKind.FUNCTION;

  accept(ConstantExpressionVisitor visitor, [context]) {
    return visitor.visitFunction(this, context);
  }

  @override
  void _createStructuredText(StringBuffer sb) {
    sb.write('Function(element=$element)');
  }

  @override
  ConstantValue evaluate(
      EvaluationEnvironment environment, ConstantSystem constantSystem) {
    return new FunctionConstantValue(element, type);
  }

  @override
  int _computeHashCode() => 13 * element.hashCode;

  @override
  bool _equals(FunctionConstantExpression other) {
    return element == other.element;
  }

  @override
  InterfaceType getKnownType(CommonElements commonElements) =>
      commonElements.functionType;
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
  void _createStructuredText(StringBuffer sb) {
    sb.write('Binary(left=');
    left._createStructuredText(sb);
    sb.write(',op=$operator,right=');
    right._createStructuredText(sb);
    sb.write(')');
  }

  @override
  ConstantValue evaluate(
      EvaluationEnvironment environment, ConstantSystem constantSystem) {
    ConstantValue leftValue = left.evaluate(environment, constantSystem);
    ConstantValue rightValue = right.evaluate(environment, constantSystem);
    switch (operator.kind) {
      case BinaryOperatorKind.NOT_EQ:
        BoolConstantValue equals =
            constantSystem.equal.fold(leftValue, rightValue);
        return equals.negate();
      default:
        return constantSystem
            .lookupBinary(operator)
            .fold(leftValue, rightValue);
    }
  }

  ConstantExpression apply(NormalizedArguments arguments) {
    return new BinaryConstantExpression(
        left.apply(arguments), operator, right.apply(arguments));
  }

  // ignore: MISSING_RETURN
  InterfaceType getKnownType(CommonElements commonElements) {
    DartType knownLeftType = left.getKnownType(commonElements);
    DartType knownRightType = right.getKnownType(commonElements);
    switch (operator.kind) {
      case BinaryOperatorKind.EQ:
      case BinaryOperatorKind.NOT_EQ:
      case BinaryOperatorKind.LOGICAL_AND:
      case BinaryOperatorKind.LOGICAL_OR:
      case BinaryOperatorKind.GT:
      case BinaryOperatorKind.LT:
      case BinaryOperatorKind.GTEQ:
      case BinaryOperatorKind.LTEQ:
        return commonElements.boolType;
      case BinaryOperatorKind.ADD:
        if (knownLeftType == commonElements.stringType) {
          assert(knownRightType == commonElements.stringType);
          return commonElements.stringType;
        } else if (knownLeftType == commonElements.intType &&
            knownRightType == commonElements.intType) {
          return commonElements.intType;
        }
        assert(knownLeftType == commonElements.doubleType ||
            knownRightType == commonElements.doubleType);
        return commonElements.doubleType;
      case BinaryOperatorKind.SUB:
      case BinaryOperatorKind.MUL:
      case BinaryOperatorKind.MOD:
        if (knownLeftType == commonElements.intType &&
            knownRightType == commonElements.intType) {
          return commonElements.intType;
        }
        assert(knownLeftType == commonElements.doubleType ||
            knownRightType == commonElements.doubleType);
        return commonElements.doubleType;
      case BinaryOperatorKind.DIV:
        return commonElements.doubleType;
      case BinaryOperatorKind.IDIV:
        return commonElements.intType;
      case BinaryOperatorKind.AND:
      case BinaryOperatorKind.OR:
      case BinaryOperatorKind.XOR:
      case BinaryOperatorKind.SHR:
      case BinaryOperatorKind.SHL:
        return commonElements.intType;
      case BinaryOperatorKind.IF_NULL:
      case BinaryOperatorKind.INDEX:
        throw new UnsupportedError(
            'Unexpected constant binary operator: $operator');
    }
  }

  int get precedence => PRECEDENCE_MAP[operator.kind];

  @override
  int _computeHashCode() {
    return 13 * operator.hashCode + 17 * left.hashCode + 19 * right.hashCode;
  }

  @override
  bool _equals(BinaryConstantExpression other) {
    return operator == other.operator &&
        left == other.left &&
        right == other.right;
  }

  @override
  bool get isPotential {
    return left.isPotential || right.isPotential;
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
    BinaryOperatorKind.IF_NULL: 3,
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
  void _createStructuredText(StringBuffer sb) {
    sb.write('Identical(left=');
    left._createStructuredText(sb);
    sb.write(',right=');
    right._createStructuredText(sb);
    sb.write(')');
  }

  @override
  ConstantValue evaluate(
      EvaluationEnvironment environment, ConstantSystem constantSystem) {
    return constantSystem.identity.fold(
        left.evaluate(environment, constantSystem),
        right.evaluate(environment, constantSystem));
  }

  ConstantExpression apply(NormalizedArguments arguments) {
    return new IdenticalConstantExpression(
        left.apply(arguments), right.apply(arguments));
  }

  int get precedence => 15;

  @override
  int _computeHashCode() {
    return 17 * left.hashCode + 19 * right.hashCode;
  }

  @override
  bool _equals(IdenticalConstantExpression other) {
    return left == other.left && right == other.right;
  }

  @override
  InterfaceType getKnownType(CommonElements commonElements) =>
      commonElements.boolType;

  @override
  bool get isPotential {
    return left.isPotential || right.isPotential;
  }
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
  void _createStructuredText(StringBuffer sb) {
    sb.write('Unary(op=$operator,expression=');
    expression._createStructuredText(sb);
    sb.write(')');
  }

  @override
  ConstantValue evaluate(
      EvaluationEnvironment environment, ConstantSystem constantSystem) {
    return constantSystem
        .lookupUnary(operator)
        .fold(expression.evaluate(environment, constantSystem));
  }

  ConstantExpression apply(NormalizedArguments arguments) {
    return new UnaryConstantExpression(operator, expression.apply(arguments));
  }

  int get precedence => PRECEDENCE_MAP[operator.kind];

  @override
  int _computeHashCode() {
    return 13 * operator.hashCode + 17 * expression.hashCode;
  }

  @override
  bool _equals(UnaryConstantExpression other) {
    return operator == other.operator && expression == other.expression;
  }

  @override
  DartType getKnownType(CommonElements commonElements) {
    return expression.getKnownType(commonElements);
  }

  @override
  bool get isPotential {
    return expression.isPotential;
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
  void _createStructuredText(StringBuffer sb) {
    sb.write('StringLength(expression=');
    expression._createStructuredText(sb);
    sb.write(')');
  }

  @override
  ConstantValue evaluate(
      EvaluationEnvironment environment, ConstantSystem constantSystem) {
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
  InterfaceType getKnownType(CommonElements commonElements) =>
      commonElements.intType;

  @override
  bool get isPotential {
    return expression.isPotential;
  }
}

/// A constant conditional expression like `a ? b : c`.
class ConditionalConstantExpression extends ConstantExpression {
  final ConstantExpression condition;
  final ConstantExpression trueExp;
  final ConstantExpression falseExp;

  ConditionalConstantExpression(this.condition, this.trueExp, this.falseExp);

  ConstantExpressionKind get kind => ConstantExpressionKind.CONDITIONAL;

  accept(ConstantExpressionVisitor visitor, [context]) {
    return visitor.visitConditional(this, context);
  }

  @override
  void _createStructuredText(StringBuffer sb) {
    sb.write('Conditional(condition=');
    condition._createStructuredText(sb);
    sb.write(',true=');
    trueExp._createStructuredText(sb);
    sb.write(',false=');
    falseExp._createStructuredText(sb);
    sb.write(')');
  }

  ConstantExpression apply(NormalizedArguments arguments) {
    return new ConditionalConstantExpression(condition.apply(arguments),
        trueExp.apply(arguments), falseExp.apply(arguments));
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
  ConstantValue evaluate(
      EvaluationEnvironment environment, ConstantSystem constantSystem) {
    ConstantValue conditionValue =
        condition.evaluate(environment, constantSystem);
    ConstantValue trueValue = trueExp.evaluate(environment, constantSystem);
    ConstantValue falseValue = falseExp.evaluate(environment, constantSystem);
    if (conditionValue.isTrue) {
      return trueValue;
    } else if (conditionValue.isFalse) {
      return falseValue;
    } else {
      return new NonConstantValue();
    }
  }

  @override
  DartType getKnownType(CommonElements commonElements) {
    DartType trueType = trueExp.getKnownType(commonElements);
    DartType falseType = falseExp.getKnownType(commonElements);
    if (trueType == falseType) {
      return trueType;
    }
    return null;
  }

  @override
  bool get isPotential {
    return condition.isPotential || trueExp.isPotential || falseExp.isPotential;
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

  @override
  void _createStructuredText(StringBuffer sb) {
    sb.write('Positional(index=$index)');
  }

  ConstantExpression apply(NormalizedArguments arguments) {
    return arguments.getPositionalArgument(index);
  }

  @override
  int _computeHashCode() => 13 * index.hashCode;

  @override
  bool _equals(PositionalArgumentReference other) => index == other.index;

  @override
  ConstantValue evaluate(
      EvaluationEnvironment environment, ConstantSystem constantSystem) {
    throw new UnsupportedError('PositionalArgumentReference.evaluate');
  }

  @override
  bool get isPotential => true;
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

  @override
  void _createStructuredText(StringBuffer sb) {
    sb.write('Named(name=$name)');
  }

  ConstantExpression apply(NormalizedArguments arguments) {
    return arguments.getNamedArgument(name);
  }

  @override
  int _computeHashCode() => 13 * name.hashCode;

  @override
  bool _equals(NamedArgumentReference other) => name == other.name;

  @override
  ConstantValue evaluate(
      EvaluationEnvironment environment, ConstantSystem constantSystem) {
    throw new UnsupportedError('NamedArgumentReference.evaluate');
  }

  @override
  bool get isPotential => true;
}

abstract class FromEnvironmentConstantExpression extends ConstantExpression {
  final ConstantExpression name;
  final ConstantExpression defaultValue;

  FromEnvironmentConstantExpression(this.name, this.defaultValue);

  @override
  int _computeHashCode() {
    return 13 * name.hashCode + 17 * defaultValue.hashCode;
  }

  @override
  bool _equals(FromEnvironmentConstantExpression other) {
    return name == other.name && defaultValue == other.defaultValue;
  }

  @override
  bool get isImplicit {
    return false;
  }

  @override
  bool get isPotential {
    return name.isPotential ||
        (defaultValue != null && defaultValue.isPotential);
  }
}

/// A `const bool.fromEnvironment` constant.
class BoolFromEnvironmentConstantExpression
    extends FromEnvironmentConstantExpression {
  BoolFromEnvironmentConstantExpression(
      ConstantExpression name, ConstantExpression defaultValue)
      : super(name, defaultValue);

  ConstantExpressionKind get kind {
    return ConstantExpressionKind.BOOL_FROM_ENVIRONMENT;
  }

  accept(ConstantExpressionVisitor visitor, [context]) {
    return visitor.visitBoolFromEnvironment(this, context);
  }

  @override
  void _createStructuredText(StringBuffer sb) {
    sb.write('bool.fromEnvironment(name=');
    name._createStructuredText(sb);
    sb.write(',defaultValue=');
    if (defaultValue != null) {
      defaultValue._createStructuredText(sb);
    } else {
      sb.write('null');
    }
    sb.write(')');
  }

  @override
  ConstantValue evaluate(
      EvaluationEnvironment environment, ConstantSystem constantSystem) {
    ConstantValue nameConstantValue =
        name.evaluate(environment, constantSystem);
    ConstantValue defaultConstantValue;
    if (defaultValue != null) {
      defaultConstantValue = defaultValue.evaluate(environment, constantSystem);
    } else {
      defaultConstantValue = constantSystem.createBool(false);
    }
    if (!nameConstantValue.isString) {
      return new NonConstantValue();
    }
    StringConstantValue nameStringConstantValue = nameConstantValue;
    String text =
        environment.readFromEnvironment(nameStringConstantValue.primitiveValue);
    if (text == 'true') {
      return constantSystem.createBool(true);
    } else if (text == 'false') {
      return constantSystem.createBool(false);
    } else {
      return defaultConstantValue;
    }
  }

  ConstantExpression apply(NormalizedArguments arguments) {
    return new BoolFromEnvironmentConstantExpression(name.apply(arguments),
        defaultValue != null ? defaultValue.apply(arguments) : null);
  }

  @override
  InterfaceType getKnownType(CommonElements commonElements) =>
      commonElements.boolType;
}

/// A `const int.fromEnvironment` constant.
class IntFromEnvironmentConstantExpression
    extends FromEnvironmentConstantExpression {
  IntFromEnvironmentConstantExpression(
      ConstantExpression name, ConstantExpression defaultValue)
      : super(name, defaultValue);

  ConstantExpressionKind get kind {
    return ConstantExpressionKind.INT_FROM_ENVIRONMENT;
  }

  accept(ConstantExpressionVisitor visitor, [context]) {
    return visitor.visitIntFromEnvironment(this, context);
  }

  @override
  void _createStructuredText(StringBuffer sb) {
    sb.write('int.fromEnvironment(name=');
    name._createStructuredText(sb);
    sb.write(',defaultValue=');
    if (defaultValue != null) {
      defaultValue._createStructuredText(sb);
    } else {
      sb.write('null');
    }
    sb.write(')');
  }

  @override
  ConstantValue evaluate(
      EvaluationEnvironment environment, ConstantSystem constantSystem) {
    ConstantValue nameConstantValue =
        name.evaluate(environment, constantSystem);
    ConstantValue defaultConstantValue;
    if (defaultValue != null) {
      defaultConstantValue = defaultValue.evaluate(environment, constantSystem);
    } else {
      defaultConstantValue = constantSystem.createNull();
    }
    if (!nameConstantValue.isString) {
      return new NonConstantValue();
    }
    StringConstantValue nameStringConstantValue = nameConstantValue;
    String text =
        environment.readFromEnvironment(nameStringConstantValue.primitiveValue);
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
    return new IntFromEnvironmentConstantExpression(name.apply(arguments),
        defaultValue != null ? defaultValue.apply(arguments) : null);
  }

  @override
  InterfaceType getKnownType(CommonElements commonElements) =>
      commonElements.intType;
}

/// A `const String.fromEnvironment` constant.
class StringFromEnvironmentConstantExpression
    extends FromEnvironmentConstantExpression {
  StringFromEnvironmentConstantExpression(
      ConstantExpression name, ConstantExpression defaultValue)
      : super(name, defaultValue);

  ConstantExpressionKind get kind {
    return ConstantExpressionKind.STRING_FROM_ENVIRONMENT;
  }

  accept(ConstantExpressionVisitor visitor, [context]) {
    return visitor.visitStringFromEnvironment(this, context);
  }

  @override
  void _createStructuredText(StringBuffer sb) {
    sb.write('String.fromEnvironment(name=');
    name._createStructuredText(sb);
    sb.write(',defaultValue=');
    if (defaultValue != null) {
      defaultValue._createStructuredText(sb);
    } else {
      sb.write('null');
    }
    sb.write(')');
  }

  @override
  ConstantValue evaluate(
      EvaluationEnvironment environment, ConstantSystem constantSystem) {
    ConstantValue nameConstantValue =
        name.evaluate(environment, constantSystem);
    ConstantValue defaultConstantValue;
    if (defaultValue != null) {
      defaultConstantValue = defaultValue.evaluate(environment, constantSystem);
    } else {
      defaultConstantValue = constantSystem.createNull();
    }
    if (!nameConstantValue.isString) {
      return new NonConstantValue();
    }
    StringConstantValue nameStringConstantValue = nameConstantValue;
    String text =
        environment.readFromEnvironment(nameStringConstantValue.primitiveValue);
    if (text == null) {
      return defaultConstantValue;
    } else {
      return constantSystem.createString(text);
    }
  }

  ConstantExpression apply(NormalizedArguments arguments) {
    return new StringFromEnvironmentConstantExpression(name.apply(arguments),
        defaultValue != null ? defaultValue.apply(arguments) : null);
  }

  @override
  InterfaceType getKnownType(CommonElements commonElements) =>
      commonElements.stringType;
}

/// A constant expression referenced with a deferred prefix.
/// For example `lib.C`.
class DeferredConstantExpression extends ConstantExpression {
  final ConstantExpression expression;
  final Entity prefix;

  DeferredConstantExpression(this.expression, this.prefix);

  ConstantExpressionKind get kind => ConstantExpressionKind.DEFERRED;

  @override
  void _createStructuredText(StringBuffer sb) {
    sb.write('Deferred(prefix=$prefix,expression=');
    expression._createStructuredText(sb);
    sb.write(')');
  }

  @override
  ConstantValue evaluate(
      EvaluationEnvironment environment, ConstantSystem constantSystem) {
    return new DeferredConstantValue(
        expression.evaluate(environment, constantSystem), prefix);
  }

  @override
  int _computeHashCode() {
    return 13 * expression.hashCode;
  }

  ConstantExpression apply(NormalizedArguments arguments) {
    return new DeferredConstantExpression(expression.apply(arguments), prefix);
  }

  @override
  bool _equals(DeferredConstantExpression other) {
    return expression == other.expression;
  }

  @override
  accept(ConstantExpressionVisitor visitor, [context]) {
    return visitor.visitDeferred(this, context);
  }

  @override
  bool get isPotential {
    return expression.isPotential;
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
  R visitLocalVariable(LocalVariableConstantExpression exp, A context);
  R visitField(FieldConstantExpression exp, A context);
  R visitFunction(FunctionConstantExpression exp, A context);
  R visitBinary(BinaryConstantExpression exp, A context);
  R visitIdentical(IdenticalConstantExpression exp, A context);
  R visitUnary(UnaryConstantExpression exp, A context);
  R visitStringLength(StringLengthConstantExpression exp, A context);
  R visitConditional(ConditionalConstantExpression exp, A context);
  R visitBoolFromEnvironment(
      BoolFromEnvironmentConstantExpression exp, A context);
  R visitIntFromEnvironment(
      IntFromEnvironmentConstantExpression exp, A context);
  R visitStringFromEnvironment(
      StringFromEnvironmentConstantExpression exp, A context);
  R visitDeferred(DeferredConstantExpression exp, A context);

  R visitPositional(PositionalArgumentReference exp, A context);
  R visitNamed(NamedArgumentReference exp, A context);
}

class ConstExpPrinter extends ConstantExpressionVisitor {
  final StringBuffer sb = new StringBuffer();

  void write(ConstantExpression parent, ConstantExpression child,
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
    sb.write(exp.name);
  }

  @override
  void visitField(FieldConstantExpression exp, [_]) {
    if (exp.element.isStatic) {
      sb.write(exp.element.enclosingClass.name);
      sb.write('.');
    }
    sb.write(exp.element.name);
  }

  @override
  void visitLocalVariable(LocalVariableConstantExpression exp, [_]) {
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
