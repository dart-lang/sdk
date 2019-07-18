// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.constants.expressions;

import 'dart:collection';

import '../common.dart';
import '../common_elements.dart';
import '../constants/constant_system.dart' as constant_system;
import '../elements/entities.dart';
import '../elements/operators.dart';
import '../elements/types.dart';
import '../universe/call_structure.dart' show CallStructure;
import '../util/util.dart';
import 'constructors.dart';
import 'evaluation.dart';
import 'values.dart';

enum ConstantExpressionKind {
  AS,
  BINARY,
  BOOL,
  BOOL_FROM_ENVIRONMENT,
  CONCATENATE,
  CONDITIONAL,
  CONSTRUCTED,
  DOUBLE,
  ERRONEOUS,
  FUNCTION,
  FIELD,
  IDENTICAL,
  INT,
  INT_FROM_ENVIRONMENT,
  LIST,
  SET,
  MAP,
  NULL,
  STRING,
  STRING_FROM_ENVIRONMENT,
  STRING_LENGTH,
  SYMBOL,
  TYPE,
  UNARY,
  LOCAL_VARIABLE,
  POSITIONAL_REFERENCE,
  NAMED_REFERENCE,
  ASSERT,
  INSTANTIATION,
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

  /// Compute the [ConstantValue] for this expression using the [environment].
  ConstantValue evaluate(EvaluationEnvironment environment);

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

  @override
  int get hashCode => _hashCode ??= _computeHashCode();

  bool _equals(covariant ConstantExpression other);

  @override
  bool operator ==(other) {
    if (identical(this, other)) return true;
    if (other is! ConstantExpression) return false;
    if (kind != other.kind) return false;
    if (hashCode != other.hashCode) return false;
    return _equals(other);
  }

  @override
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
  @override
  ConstantExpressionKind get kind => ConstantExpressionKind.ERRONEOUS;

  @override
  accept(ConstantExpressionVisitor visitor, [context]) {
    // Do nothing. This is an error.
  }

  @override
  ConstantValue evaluate(EvaluationEnvironment environment) {
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

/// Boolean literal constant.
class BoolConstantExpression extends ConstantExpression {
  final bool boolValue;

  BoolConstantExpression(this.boolValue);

  @override
  ConstantExpressionKind get kind => ConstantExpressionKind.BOOL;

  @override
  accept(ConstantExpressionVisitor visitor, [context]) {
    return visitor.visitBool(this, context);
  }

  @override
  void _createStructuredText(StringBuffer sb) {
    sb.write('Bool(value=${boolValue})');
  }

  @override
  ConstantValue evaluate(EvaluationEnvironment environment) {
    return constant_system.createBool(boolValue);
  }

  @override
  int _computeHashCode() => 13 * boolValue.hashCode;

  @override
  bool _equals(BoolConstantExpression other) {
    return boolValue == other.boolValue;
  }

  @override
  InterfaceType getKnownType(CommonElements commonElements) =>
      commonElements.boolType;
}

/// Integer literal constant.
class IntConstantExpression extends ConstantExpression {
  final BigInt intValue;

  IntConstantExpression(this.intValue);

  @override
  ConstantExpressionKind get kind => ConstantExpressionKind.INT;

  @override
  accept(ConstantExpressionVisitor visitor, [context]) {
    return visitor.visitInt(this, context);
  }

  @override
  void _createStructuredText(StringBuffer sb) {
    sb.write('Int(value=${intValue})');
  }

  @override
  ConstantValue evaluate(EvaluationEnvironment environment) {
    return constant_system.createInt(intValue);
  }

  @override
  int _computeHashCode() => 17 * intValue.hashCode;

  @override
  bool _equals(IntConstantExpression other) {
    return intValue == other.intValue;
  }

  @override
  InterfaceType getKnownType(CommonElements commonElements) =>
      commonElements.intType;
}

/// Double literal constant.
class DoubleConstantExpression extends ConstantExpression {
  final double doubleValue;

  DoubleConstantExpression(this.doubleValue);

  @override
  ConstantExpressionKind get kind => ConstantExpressionKind.DOUBLE;

  @override
  accept(ConstantExpressionVisitor visitor, [context]) {
    return visitor.visitDouble(this, context);
  }

  @override
  void _createStructuredText(StringBuffer sb) {
    sb.write('Double(value=${doubleValue})');
  }

  @override
  ConstantValue evaluate(EvaluationEnvironment environment) {
    return constant_system.createDouble(doubleValue);
  }

  @override
  int _computeHashCode() => 19 * doubleValue.hashCode;

  @override
  bool _equals(DoubleConstantExpression other) {
    return doubleValue == other.doubleValue;
  }

  @override
  InterfaceType getKnownType(CommonElements commonElements) =>
      commonElements.doubleType;
}

/// String literal constant.
class StringConstantExpression extends ConstantExpression {
  final String stringValue;

  StringConstantExpression(this.stringValue);

  @override
  ConstantExpressionKind get kind => ConstantExpressionKind.STRING;

  @override
  accept(ConstantExpressionVisitor visitor, [context]) {
    return visitor.visitString(this, context);
  }

  @override
  void _createStructuredText(StringBuffer sb) {
    sb.write('String(value=${stringValue})');
  }

  @override
  ConstantValue evaluate(EvaluationEnvironment environment) {
    return constant_system.createString(stringValue);
  }

  @override
  int _computeHashCode() => 23 * stringValue.hashCode;

  @override
  bool _equals(StringConstantExpression other) {
    return stringValue == other.stringValue;
  }

  @override
  InterfaceType getKnownType(CommonElements commonElements) =>
      commonElements.stringType;
}

/// Null literal constant.
class NullConstantExpression extends ConstantExpression {
  NullConstantExpression();

  @override
  ConstantExpressionKind get kind => ConstantExpressionKind.NULL;

  @override
  accept(ConstantExpressionVisitor visitor, [context]) {
    return visitor.visitNull(this, context);
  }

  @override
  void _createStructuredText(StringBuffer sb) {
    sb.write('Null()');
  }

  @override
  ConstantValue evaluate(EvaluationEnvironment environment) {
    return constant_system.createNull();
  }

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

  @override
  ConstantExpressionKind get kind => ConstantExpressionKind.LIST;

  @override
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
  ConstantValue evaluate(EvaluationEnvironment environment) {
    return constant_system.createList(
        type, values.map((v) => v.evaluate(environment)).toList());
  }

  @override
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

/// Literal set constant.
class SetConstantExpression extends ConstantExpression {
  final InterfaceType type;
  final List<ConstantExpression> values;

  SetConstantExpression(this.type, this.values);

  @override
  ConstantExpressionKind get kind => ConstantExpressionKind.SET;

  @override
  accept(ConstantExpressionVisitor visitor, [context]) {
    return visitor.visitSet(this, context);
  }

  @override
  ConstantExpression apply(NormalizedArguments arguments) =>
      new SetConstantExpression(
          type, values.map((v) => v.apply(arguments)).toList());

  @override
  ConstantValue evaluate(EvaluationEnvironment environment) {
    // TODO(fishythefish): Delete once the CFE provides these error messages.
    Set<ConstantValue> set = new LinkedHashSet<ConstantValue>();
    for (int i = 0; i < values.length; i++) {
      ConstantValue value = values[i].evaluate(environment);
      if (!value.isConstant) return new NonConstantValue();
      if (!set.add(value)) {
        environment.reportError(values[i], MessageKind.EQUAL_SET_ENTRY, {});
      }
    }

    return constant_system.createSet(
        environment.commonElements, type, set.toList());
  }

  @override
  DartType getKnownType(CommonElements commonElements) => type;

  @override
  void _createStructuredText(StringBuffer sb) {
    sb.write('Set(type=$type,values=[');
    String delimiter = '';
    for (ConstantExpression value in values) {
      sb.write(delimiter);
      value._createStructuredText(sb);
      delimiter = ',';
    }
    sb.write('])');
  }

  @override
  int _computeHashCode() => Hashing.listHash(values, Hashing.objectHash(type));

  @override
  bool _equals(SetConstantExpression other) {
    if (type != other.type) return false;
    if (values.length != other.values.length) return false;
    for (int i = 0; i < values.length; i++) {
      if (values[i] != other.values[i]) return false;
    }
    return true;
  }

  @override
  bool get isImplicit => false;

  @override
  bool get isPotential => values.any((v) => v.isPotential);
}

/// Literal map constant.
class MapConstantExpression extends ConstantExpression {
  final InterfaceType type;
  final List<ConstantExpression> keys;
  final List<ConstantExpression> values;

  MapConstantExpression(this.type, this.keys, this.values);

  @override
  ConstantExpressionKind get kind => ConstantExpressionKind.MAP;

  @override
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
  ConstantValue evaluate(EvaluationEnvironment environment) {
    // TODO(sigmund): delete once the CFE provides these error messages.
    return environment.evaluateMapBody(() {
      Map<ConstantValue, ConstantValue> map = <ConstantValue, ConstantValue>{};
      for (int i = 0; i < keys.length; i++) {
        ConstantValue key = keys[i].evaluate(environment);
        if (!key.isConstant) {
          return new NonConstantValue();
        }
        ConstantValue value = values[i].evaluate(environment);
        if (!value.isConstant) {
          return new NonConstantValue();
        }
        if (map.containsKey(key)) {
          environment.reportError(keys[i], MessageKind.EQUAL_MAP_ENTRY_KEY, {});
        }
        map[key] = value;
      }
      return constant_system.createMap(environment.commonElements, type,
          map.keys.toList(), map.values.toList());
    });
  }

  @override
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

  @override
  ConstantExpressionKind get kind => ConstantExpressionKind.CONSTRUCTED;

  @override
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

  InstanceData computeInstanceData(EvaluationEnvironment environment) {
    ConstantConstructor constantConstructor =
        environment.getConstructorConstant(target);
    assert(constantConstructor != null,
        failedAt(target, "No constant constructor computed for $target."));
    return constantConstructor.computeInstanceData(
        environment, arguments, callStructure);
  }

  InterfaceType computeInstanceType(EvaluationEnvironment environment) {
    return environment
        .getConstructorConstant(target)
        .computeInstanceType(environment, type);
  }

  @override
  ConstructedConstantExpression apply(NormalizedArguments arguments) {
    return new ConstructedConstantExpression(type, target, callStructure,
        this.arguments.map((a) => a.apply(arguments)).toList());
  }

  @override
  ConstantValue evaluate(EvaluationEnvironment environment) {
    InterfaceType instanceType = computeInstanceType(environment);
    return environment.evaluateConstructor(target, instanceType, () {
      InstanceData instanceData = computeInstanceData(environment);
      if (instanceData == null) {
        return new NonConstantValue();
      }
      bool isValidAsConstant = true;
      Map<FieldEntity, ConstantValue> fieldValues =
          <FieldEntity, ConstantValue>{};
      instanceData.fieldMap
          .forEach((FieldEntity field, ConstantExpression constant) {
        ConstantValue value = constant.evaluate(environment);
        assert(
            value != null,
            failedAt(CURRENT_ELEMENT_SPANNABLE,
                "No value computed for ${constant.toStructuredText()}."));
        if (value.isConstant) {
          fieldValues[field] = value;
        } else {
          isValidAsConstant = false;
        }
      });
      for (AssertConstantExpression assertion in instanceData.assertions) {
        if (!assertion.evaluate(environment).isConstant) {
          isValidAsConstant = false;
        }
      }
      if (isValidAsConstant) {
        return new ConstructedConstantValue(instanceType, fieldValues);
      } else {
        return new NonConstantValue();
      }
    });
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

  @override
  ConstantExpressionKind get kind => ConstantExpressionKind.CONCATENATE;

  @override
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

  @override
  ConstantExpression apply(NormalizedArguments arguments) {
    return new ConcatenateConstantExpression(
        expressions.map((a) => a.apply(arguments)).toList());
  }

  @override
  ConstantValue evaluate(EvaluationEnvironment environment) {
    bool isValid = true;
    StringBuffer sb = new StringBuffer();
    for (ConstantExpression expression in expressions) {
      ConstantValue value = expression.evaluate(environment);
      if (!value.isConstant) {
        isValid = false;
        // Use `continue` instead of `return` here to report all errors in the
        // expression and not just the first.
        continue;
      }
      if (value.isPrimitive) {
        if (value is StringConstantValue) {
          sb.write(value.stringValue);
        } else if (value is IntConstantValue) {
          sb.write(value.intValue);
        } else if (value is DoubleConstantValue) {
          sb.write(value.doubleValue);
        } else if (value is BoolConstantValue) {
          sb.write(value.boolValue);
        } else if (value is NullConstantValue) {
          sb.write(null);
        }
      } else {
        environment.reportError(
            expression, MessageKind.INVALID_CONSTANT_INTERPOLATION_TYPE, {
          'constant': expression,
          'type': value.getType(environment.commonElements)
        });
        isValid = false;
        // Use `continue` instead of `return` here to report all errors in the
        // expression and not just the first.
        continue;
      }
    }
    if (isValid) {
      return constant_system.createString(sb.toString());
    }
    return new NonConstantValue();
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

  @override
  ConstantExpressionKind get kind => ConstantExpressionKind.SYMBOL;

  @override
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
  ConstantValue evaluate(EvaluationEnvironment environment) {
    return constant_system.createSymbol(environment.commonElements, name);
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
    assert(type.isInterfaceType || type.isTypedef || type.isDynamic,
        "Unexpected type constant type: $type");
  }

  @override
  ConstantExpressionKind get kind => ConstantExpressionKind.TYPE;

  @override
  accept(ConstantExpressionVisitor visitor, [context]) {
    return visitor.visitType(this, context);
  }

  @override
  void _createStructuredText(StringBuffer sb) {
    sb.write('Type(type=$type)');
  }

  @override
  ConstantValue evaluate(EvaluationEnvironment environment) {
    return constant_system.createType(environment.commonElements, type);
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

/// Cast expressions: these may be from either explicit or implicit `as`
/// checks.
class AsConstantExpression extends ConstantExpression {
  final ConstantExpression expression;
  final DartType type;

  AsConstantExpression(this.expression, this.type);

  @override
  ConstantExpressionKind get kind => ConstantExpressionKind.AS;

  @override
  accept(ConstantExpressionVisitor visitor, [context]) {
    return visitor.visitAs(this, context);
  }

  @override
  void _createStructuredText(StringBuffer sb) {
    sb.write('As(value=');
    expression._createStructuredText(sb);
    sb.write(',type=$type)');
  }

  @override
  ConstantValue evaluate(EvaluationEnvironment environment) {
    // Running example for comments:
    //
    //     class A<T> {
    //       final T t;
    //       const A(dynamic t) : this.t = t; // implicitly `t as A.T`
    //     }
    //     class B<S> extends A<S> {
    //       const B(dynamic s) : super(s);
    //     }
    //     main() => const B<num>(0);
    //
    // We visit `t as A.T` while evaluating `const B<num>(0)`.

    // The expression value is `0`.
    ConstantValue expressionValue = expression.evaluate(environment);

    if (!environment.checkCasts) return expressionValue;

    // The expression type is `int`.
    DartType expressionType =
        expressionValue.getType(environment.commonElements);

    // The `as` type `A.T` in the context of `B<num>` is `num`.
    DartType typeInContext = environment.getTypeInContext(type);

    // Check that the expression type, `int`, is a subtype of the type in
    // context, `num`.
    if (!constant_system.isSubtype(
        environment.types, expressionType, typeInContext)) {
      // TODO(sigmund): consider reporting different messages and error
      // locations for implicit vs explicit casts.
      environment.reportError(expression, MessageKind.INVALID_CONSTANT_CAST,
          {'constant': expression, 'type': expressionType, 'castType': type});
      return new NonConstantValue();
    }
    return expressionValue;
  }

  @override
  ConstantExpression apply(NormalizedArguments arguments) {
    return new AsConstantExpression(expression.apply(arguments), type);
  }

  @override
  int _computeHashCode() => 13 * type.hashCode + 17 * expression.hashCode;

  @override
  bool _equals(AsConstantExpression other) {
    return expression == other.expression && type == other.type;
  }

  @override
  InterfaceType getKnownType(CommonElements commonElements) =>
      expression.getKnownType(commonElements);
}

/// Reference to a constant top-level or static field.
class FieldConstantExpression extends ConstantExpression {
  final FieldEntity element;

  FieldConstantExpression(this.element);

  @override
  ConstantExpressionKind get kind => ConstantExpressionKind.FIELD;

  @override
  accept(ConstantExpressionVisitor visitor, [context]) {
    return visitor.visitField(this, context);
  }

  @override
  void _createStructuredText(StringBuffer sb) {
    sb.write('Field(element=$element)');
  }

  @override
  ConstantValue evaluate(EvaluationEnvironment environment) {
    return environment.evaluateField(element, () {
      ConstantExpression constant = environment.getFieldConstant(element);
      return constant.evaluate(environment);
    });
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

  @override
  ConstantExpressionKind get kind => ConstantExpressionKind.LOCAL_VARIABLE;

  @override
  accept(ConstantExpressionVisitor visitor, [context]) {
    return visitor.visitLocalVariable(this, context);
  }

  @override
  void _createStructuredText(StringBuffer sb) {
    sb.write('LocalVariable(element=$element)');
  }

  @override
  ConstantValue evaluate(EvaluationEnvironment environment) {
    ConstantExpression constant = environment.getLocalConstant(element);
    return constant.evaluate(environment);
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

  @override
  ConstantExpressionKind get kind => ConstantExpressionKind.FUNCTION;

  @override
  accept(ConstantExpressionVisitor visitor, [context]) {
    return visitor.visitFunction(this, context);
  }

  @override
  void _createStructuredText(StringBuffer sb) {
    sb.write('Function(element=$element)');
  }

  @override
  ConstantValue evaluate(EvaluationEnvironment environment) {
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
    assert(PRECEDENCE_MAP[operator.kind] != null,
        "Missing precendence for binary operator: '$operator'.");
  }

  static bool potentialOperator(BinaryOperator operator) =>
      PRECEDENCE_MAP[operator.kind] != null;

  @override
  ConstantExpressionKind get kind => ConstantExpressionKind.BINARY;

  @override
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
  ConstantValue evaluate(EvaluationEnvironment environment) {
    ConstantValue leftValue = left.evaluate(environment);
    if (!leftValue.isConstant) return new NonConstantValue();
    ConstantValue rightValue;
    // Short-circuit && and || operators.
    switch (operator.kind) {
      case BinaryOperatorKind.LOGICAL_AND:
        if (leftValue.isBool && leftValue.isFalse) {
          rightValue = new FalseConstantValue();
        } else {
          rightValue = right.evaluate(environment);
        }
        break;

      case BinaryOperatorKind.LOGICAL_OR:
        if (leftValue.isBool && leftValue.isTrue) {
          rightValue = new TrueConstantValue();
        } else {
          rightValue = right.evaluate(environment);
        }
        break;
      default:
        rightValue = right.evaluate(environment);
    }

    if (!rightValue.isConstant) return new NonConstantValue();
    bool isValid = true;
    switch (operator.kind) {
      case BinaryOperatorKind.EQ:
      case BinaryOperatorKind.NOT_EQ:
        if (!leftValue.isPrimitive) {
          if (!rightValue.isNull) {
            environment.reportError(
                left, MessageKind.INVALID_CONSTANT_BINARY_PRIMITIVE_TYPE, {
              'constant': left,
              'type': leftValue.getType(environment.commonElements),
              'operator': operator
            });
            isValid = false;
          }
        }
        if (!rightValue.isPrimitive) {
          if (!leftValue.isNull) {
            environment.reportError(
                right, MessageKind.INVALID_CONSTANT_BINARY_PRIMITIVE_TYPE, {
              'constant': right,
              'type': rightValue.getType(environment.commonElements),
              'operator': operator
            });
            isValid = false;
          }
        }
        break;
      case BinaryOperatorKind.ADD:
        if (leftValue.isString) {
          if (!rightValue.isString) {
            environment.reportError(
                right, MessageKind.INVALID_CONSTANT_STRING_ADD_TYPE, {
              'constant': right,
              'type': rightValue.getType(environment.commonElements)
            });
            isValid = false;
          }
        } else if (leftValue.isNum) {
          if (!rightValue.isNum) {
            environment.reportError(
                right, MessageKind.INVALID_CONSTANT_NUM_ADD_TYPE, {
              'constant': right,
              'type': rightValue.getType(environment.commonElements)
            });
            isValid = false;
          }
        } else if (rightValue.isString) {
          if (!leftValue.isString) {
            environment.reportError(
                left, MessageKind.INVALID_CONSTANT_STRING_ADD_TYPE, {
              'constant': left,
              'type': leftValue.getType(environment.commonElements)
            });
            isValid = false;
          }
        } else if (rightValue.isNum) {
          if (!leftValue.isNum) {
            environment.reportError(
                left, MessageKind.INVALID_CONSTANT_NUM_ADD_TYPE, {
              'constant': left,
              'type': leftValue.getType(environment.commonElements)
            });
            isValid = false;
          }
        } else {
          environment
              .reportError(this, MessageKind.INVALID_CONSTANT_ADD_TYPES, {
            'leftConstant': left,
            'leftType': leftValue.getType(environment.commonElements),
            'rightConstant': right,
            'rightType': rightValue.getType(environment.commonElements)
          });
          isValid = false;
        }
        break;
      case BinaryOperatorKind.SUB:
      case BinaryOperatorKind.MUL:
      case BinaryOperatorKind.DIV:
      case BinaryOperatorKind.IDIV:
      case BinaryOperatorKind.MOD:
      case BinaryOperatorKind.GTEQ:
      case BinaryOperatorKind.GT:
      case BinaryOperatorKind.LTEQ:
      case BinaryOperatorKind.LT:
        if (!leftValue.isNum) {
          environment
              .reportError(left, MessageKind.INVALID_CONSTANT_BINARY_NUM_TYPE, {
            'constant': left,
            'type': leftValue.getType(environment.commonElements),
            'operator': operator
          });
          isValid = false;
        }
        if (!rightValue.isNum) {
          environment.reportError(
              right, MessageKind.INVALID_CONSTANT_BINARY_NUM_TYPE, {
            'constant': right,
            'type': rightValue.getType(environment.commonElements),
            'operator': operator
          });
          isValid = false;
        }
        if (isValid &&
            (operator.kind == BinaryOperatorKind.IDIV ||
                operator.kind == BinaryOperatorKind.MOD)) {
          if (rightValue.isZero) {
            environment.reportError(right, MessageKind.INVALID_CONSTANT_DIV,
                {'left': left, 'right': right, 'operator': operator});
            isValid = false;
          }
        }
        break;
      case BinaryOperatorKind.SHL:
      case BinaryOperatorKind.SHR:
      case BinaryOperatorKind.SHRU:
      case BinaryOperatorKind.AND:
      case BinaryOperatorKind.OR:
      case BinaryOperatorKind.XOR:
        if (!leftValue.isInt) {
          environment
              .reportError(left, MessageKind.INVALID_CONSTANT_BINARY_INT_TYPE, {
            'constant': left,
            'type': leftValue.getType(environment.commonElements),
            'operator': operator
          });
          isValid = false;
        }
        if (!rightValue.isInt) {
          environment.reportError(
              right, MessageKind.INVALID_CONSTANT_BINARY_INT_TYPE, {
            'constant': right,
            'type': rightValue.getType(environment.commonElements),
            'operator': operator
          });
          isValid = false;
        }
        if (isValid &&
            (operator.kind == BinaryOperatorKind.SHL ||
                operator.kind == BinaryOperatorKind.SHR ||
                operator.kind == BinaryOperatorKind.SHRU)) {
          IntConstantValue shift = rightValue;
          if (shift.intValue < BigInt.zero) {
            environment.reportError(right, MessageKind.INVALID_CONSTANT_SHIFT,
                {'left': left, 'right': right, 'operator': operator});
            isValid = false;
          }
        }
        break;
      case BinaryOperatorKind.LOGICAL_AND:
        if (!leftValue.isBool) {
          environment
              .reportError(left, MessageKind.INVALID_LOGICAL_AND_OPERAND_TYPE, {
            'constant': left,
            'type': leftValue.getType(environment.commonElements),
            'operator': operator
          });
          isValid = false;
        }
        if (!rightValue.isBool) {
          environment.reportError(
              right, MessageKind.INVALID_LOGICAL_AND_OPERAND_TYPE, {
            'constant': right,
            'type': rightValue.getType(environment.commonElements),
            'operator': operator
          });
          isValid = false;
        }
        break;
      case BinaryOperatorKind.LOGICAL_OR:
        if (!leftValue.isBool) {
          environment
              .reportError(left, MessageKind.INVALID_LOGICAL_OR_OPERAND_TYPE, {
            'constant': left,
            'type': leftValue.getType(environment.commonElements),
            'operator': operator
          });
          isValid = false;
        }
        if (!rightValue.isBool) {
          environment
              .reportError(right, MessageKind.INVALID_LOGICAL_OR_OPERAND_TYPE, {
            'constant': right,
            'type': rightValue.getType(environment.commonElements),
            'operator': operator
          });
          isValid = false;
        }
        break;
      case BinaryOperatorKind.INDEX:
        environment.reportError(this, MessageKind.INVALID_CONSTANT_INDEX, {});
        isValid = false;
        break;
      case BinaryOperatorKind.IF_NULL:
        // Valid since [leftValue] and [rightValue] are constants.
        break;
    }
    if (isValid) {
      switch (operator.kind) {
        case BinaryOperatorKind.NOT_EQ:
          BoolConstantValue equals =
              constant_system.equal.fold(leftValue, rightValue);
          return equals.negate();
        default:
          ConstantValue value = constant_system
              .lookupBinary(operator)
              .fold(leftValue, rightValue);
          if (value != null) {
            return value;
          }
          environment
              .reportError(this, MessageKind.NOT_A_COMPILE_TIME_CONSTANT, {});
      }
    }
    return new NonConstantValue();
  }

  @override
  ConstantExpression apply(NormalizedArguments arguments) {
    return new BinaryConstantExpression(
        left.apply(arguments), operator, right.apply(arguments));
  }

  @override
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
      case BinaryOperatorKind.SHL:
      case BinaryOperatorKind.SHR:
      case BinaryOperatorKind.SHRU:
        return commonElements.intType;
      case BinaryOperatorKind.IF_NULL:
      case BinaryOperatorKind.INDEX:
        throw new UnsupportedError(
            'Unexpected constant binary operator: $operator');
    }
  }

  @override
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
    BinaryOperatorKind.SHL: 11,
    BinaryOperatorKind.SHR: 11,
    BinaryOperatorKind.SHRU: 11,
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
    BinaryOperatorKind.INDEX: 3,
  };
}

/// A constant identical invocation like `identical(a, b)`.
class IdenticalConstantExpression extends ConstantExpression {
  final ConstantExpression left;
  final ConstantExpression right;

  IdenticalConstantExpression(this.left, this.right);

  @override
  ConstantExpressionKind get kind => ConstantExpressionKind.IDENTICAL;

  @override
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
  ConstantValue evaluate(EvaluationEnvironment environment) {
    ConstantValue leftValue = left.evaluate(environment);
    ConstantValue rightValue = right.evaluate(environment);
    if (leftValue.isConstant && rightValue.isConstant) {
      return constant_system.identity.fold(leftValue, rightValue);
    }
    return new NonConstantValue();
  }

  @override
  ConstantExpression apply(NormalizedArguments arguments) {
    return new IdenticalConstantExpression(
        left.apply(arguments), right.apply(arguments));
  }

  @override
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

  @override
  ConstantExpressionKind get kind => ConstantExpressionKind.UNARY;

  @override
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
  ConstantValue evaluate(EvaluationEnvironment environment) {
    ConstantValue expressionValue = expression.evaluate(environment);
    bool isValid = true;
    switch (operator.kind) {
      case UnaryOperatorKind.NOT:
        if (!expressionValue.isBool) {
          environment
              .reportError(expression, MessageKind.INVALID_CONSTANT_NOT_TYPE, {
            'constant': expression,
            'type': expressionValue.getType(environment.commonElements),
            'operator': operator
          });
          isValid = false;
        }
        break;
      case UnaryOperatorKind.NEGATE:
        if (!expressionValue.isNum) {
          environment.reportError(
              expression, MessageKind.INVALID_CONSTANT_NEGATE_TYPE, {
            'constant': expression,
            'type': expressionValue.getType(environment.commonElements),
            'operator': operator
          });
          isValid = false;
        }
        break;
      case UnaryOperatorKind.COMPLEMENT:
        if (!expressionValue.isInt) {
          environment.reportError(
              expression, MessageKind.INVALID_CONSTANT_COMPLEMENT_TYPE, {
            'constant': expression,
            'type': expressionValue.getType(environment.commonElements),
            'operator': operator
          });
          isValid = false;
        }
        break;
    }
    if (isValid) {
      ConstantValue value =
          constant_system.lookupUnary(operator).fold(expressionValue);
      if (value != null) {
        return value;
      }
    }
    return new NonConstantValue();
  }

  @override
  ConstantExpression apply(NormalizedArguments arguments) {
    return new UnaryConstantExpression(operator, expression.apply(arguments));
  }

  @override
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

  @override
  ConstantExpressionKind get kind => ConstantExpressionKind.STRING_LENGTH;

  @override
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
  ConstantValue evaluate(EvaluationEnvironment environment) {
    ConstantValue value = expression.evaluate(environment);
    if (!value.isString) {
      environment.reportError(
          expression, MessageKind.INVALID_CONSTANT_STRING_LENGTH_TYPE, {
        'constant': expression,
        'type': value.getType(environment.commonElements)
      });
      return new NonConstantValue();
    } else {
      StringConstantValue stringValue = value;
      return constant_system
          .createInt(new BigInt.from(stringValue.stringValue.length));
    }
  }

  @override
  ConstantExpression apply(NormalizedArguments arguments) {
    return new StringLengthConstantExpression(expression.apply(arguments));
  }

  @override
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

  @override
  ConstantExpressionKind get kind => ConstantExpressionKind.CONDITIONAL;

  @override
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

  @override
  ConstantExpression apply(NormalizedArguments arguments) {
    return new ConditionalConstantExpression(condition.apply(arguments),
        trueExp.apply(arguments), falseExp.apply(arguments));
  }

  @override
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
  ConstantValue evaluate(EvaluationEnvironment environment) {
    ConstantValue conditionValue = condition.evaluate(environment);
    ConstantValue trueValue = trueExp.evaluate(environment);
    ConstantValue falseValue = falseExp.evaluate(environment);
    bool isValid = true;
    if (!conditionValue.isBool) {
      environment.reportError(
          condition, MessageKind.INVALID_CONSTANT_CONDITIONAL_TYPE, {
        'constant': condition,
        'type': conditionValue.getType(environment.commonElements)
      });
      isValid = false;
    }
    if (isValid) {
      if (conditionValue.isTrue) {
        return trueValue;
      } else if (conditionValue.isFalse) {
        return falseValue;
      }
    }
    return new NonConstantValue();
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

  @override
  ConstantExpressionKind get kind {
    return ConstantExpressionKind.POSITIONAL_REFERENCE;
  }

  @override
  accept(ConstantExpressionVisitor visitor, [context]) {
    return visitor.visitPositional(this, context);
  }

  @override
  void _createStructuredText(StringBuffer sb) {
    sb.write('Positional(index=$index)');
  }

  @override
  ConstantExpression apply(NormalizedArguments arguments) {
    return arguments.getPositionalArgument(index);
  }

  @override
  int _computeHashCode() => 13 * index.hashCode;

  @override
  bool _equals(PositionalArgumentReference other) => index == other.index;

  @override
  ConstantValue evaluate(EvaluationEnvironment environment) {
    return new NonConstantValue();
  }

  @override
  bool get isPotential => true;
}

/// A reference to a named parameter.
class NamedArgumentReference extends ConstantExpression {
  final String name;

  NamedArgumentReference(this.name);

  @override
  ConstantExpressionKind get kind {
    return ConstantExpressionKind.NAMED_REFERENCE;
  }

  @override
  accept(ConstantExpressionVisitor visitor, [context]) {
    return visitor.visitNamed(this, context);
  }

  @override
  void _createStructuredText(StringBuffer sb) {
    sb.write('Named(name=$name)');
  }

  @override
  ConstantExpression apply(NormalizedArguments arguments) {
    return arguments.getNamedArgument(name);
  }

  @override
  int _computeHashCode() => 13 * name.hashCode;

  @override
  bool _equals(NamedArgumentReference other) => name == other.name;

  @override
  ConstantValue evaluate(EvaluationEnvironment environment) {
    return new NonConstantValue();
  }

  @override
  bool get isPotential => true;
}

abstract class FromEnvironmentConstantExpression extends ConstantExpression {
  final ConstantExpression name;
  final ConstantExpression defaultValue;

  FromEnvironmentConstantExpression(this.name, this.defaultValue);

  bool _checkNameFromEnvironment(EvaluationEnvironment environment,
      ConstantExpression name, ConstantValue nameValue) {
    if (!nameValue.isString) {
      environment.reportError(
          name, MessageKind.INVALID_FROM_ENVIRONMENT_NAME_TYPE, {
        'constant': name,
        'type': nameValue.getType(environment.commonElements)
      });
      return false;
    }
    return true;
  }

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

  @override
  ConstantExpressionKind get kind {
    return ConstantExpressionKind.BOOL_FROM_ENVIRONMENT;
  }

  @override
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
  ConstantValue evaluate(EvaluationEnvironment environment) {
    ConstantValue nameConstantValue = name.evaluate(environment);
    ConstantValue defaultConstantValue;
    if (defaultValue != null) {
      defaultConstantValue = defaultValue.evaluate(environment);
    } else {
      defaultConstantValue = constant_system.createBool(false);
    }
    if (!nameConstantValue.isConstant || !defaultConstantValue.isConstant) {
      return new NonConstantValue();
    }
    bool isValid =
        _checkNameFromEnvironment(environment, name, nameConstantValue);
    if (defaultValue != null) {
      if (!defaultConstantValue.isBool && !defaultConstantValue.isNull) {
        environment.reportError(defaultValue,
            MessageKind.INVALID_BOOL_FROM_ENVIRONMENT_DEFAULT_VALUE_TYPE, {
          'constant': defaultValue,
          'type': defaultConstantValue.getType(environment.commonElements)
        });
        isValid = false;
      }
    }
    if (isValid) {
      StringConstantValue nameStringConstantValue = nameConstantValue;
      String text =
          environment.readFromEnvironment(nameStringConstantValue.stringValue);
      if (text == 'true') {
        return constant_system.createBool(true);
      } else if (text == 'false') {
        return constant_system.createBool(false);
      } else {
        return defaultConstantValue;
      }
    }
    return new NonConstantValue();
  }

  @override
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

  @override
  ConstantExpressionKind get kind {
    return ConstantExpressionKind.INT_FROM_ENVIRONMENT;
  }

  @override
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
  ConstantValue evaluate(EvaluationEnvironment environment) {
    ConstantValue nameConstantValue = name.evaluate(environment);
    ConstantValue defaultConstantValue;
    if (defaultValue != null) {
      defaultConstantValue = defaultValue.evaluate(environment);
    } else {
      defaultConstantValue = constant_system.createNull();
    }
    if (!nameConstantValue.isConstant || !defaultConstantValue.isConstant) {
      return new NonConstantValue();
    }
    bool isValid =
        _checkNameFromEnvironment(environment, name, nameConstantValue);
    if (defaultValue != null) {
      if (!defaultConstantValue.isInt && !defaultConstantValue.isNull) {
        environment.reportError(defaultValue,
            MessageKind.INVALID_INT_FROM_ENVIRONMENT_DEFAULT_VALUE_TYPE, {
          'constant': defaultValue,
          'type': defaultConstantValue.getType(environment.commonElements)
        });
        isValid = false;
      }
    }
    if (isValid) {
      StringConstantValue nameStringConstantValue = nameConstantValue;
      String text =
          environment.readFromEnvironment(nameStringConstantValue.stringValue);
      BigInt value;
      if (text != null) {
        value = BigInt.tryParse(text);
      }
      if (value == null) {
        return defaultConstantValue;
      } else {
        return constant_system.createInt(value);
      }
    }
    return new NonConstantValue();
  }

  @override
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

  @override
  ConstantExpressionKind get kind {
    return ConstantExpressionKind.STRING_FROM_ENVIRONMENT;
  }

  @override
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
  ConstantValue evaluate(EvaluationEnvironment environment) {
    ConstantValue nameConstantValue = name.evaluate(environment);
    ConstantValue defaultConstantValue;
    if (defaultValue != null) {
      defaultConstantValue = defaultValue.evaluate(environment);
    } else {
      defaultConstantValue = constant_system.createNull();
    }
    if (!nameConstantValue.isConstant || !defaultConstantValue.isConstant) {
      return new NonConstantValue();
    }
    bool isValid =
        _checkNameFromEnvironment(environment, name, nameConstantValue);
    if (defaultValue != null) {
      if (!defaultConstantValue.isString && !defaultConstantValue.isNull) {
        environment.reportError(defaultValue,
            MessageKind.INVALID_STRING_FROM_ENVIRONMENT_DEFAULT_VALUE_TYPE, {
          'constant': defaultValue,
          'type': defaultConstantValue.getType(environment.commonElements)
        });
        isValid = false;
      }
    }
    if (isValid) {
      StringConstantValue nameStringConstantValue = nameConstantValue;
      String text =
          environment.readFromEnvironment(nameStringConstantValue.stringValue);
      if (text == null) {
        return defaultConstantValue;
      } else {
        return constant_system.createString(text);
      }
    }
    return new NonConstantValue();
  }

  @override
  ConstantExpression apply(NormalizedArguments arguments) {
    return new StringFromEnvironmentConstantExpression(name.apply(arguments),
        defaultValue != null ? defaultValue.apply(arguments) : null);
  }

  @override
  InterfaceType getKnownType(CommonElements commonElements) =>
      commonElements.stringType;
}

class AssertConstantExpression extends ConstantExpression {
  final ConstantExpression condition;
  final ConstantExpression message;

  AssertConstantExpression(this.condition, this.message);

  @override
  ConstantExpressionKind get kind => ConstantExpressionKind.ASSERT;

  @override
  bool _equals(AssertConstantExpression other) {
    return condition == other.condition && message == other.message;
  }

  @override
  int _computeHashCode() {
    return 13 * condition.hashCode + 17 * message.hashCode;
  }

  @override
  void _createStructuredText(StringBuffer sb) {
    sb.write('assert(');
    condition._createStructuredText(sb);
    sb.write(',message=');
    if (message != null) {
      message._createStructuredText(sb);
    } else {
      sb.write('null');
    }
    sb.write(')');
  }

  @override
  ConstantValue evaluate(EvaluationEnvironment environment) {
    ConstantValue conditionValue = condition.evaluate(environment);
    bool validAssert;
    if (environment.enableAssertions) {
      // Boolean conversion:
      validAssert =
          conditionValue is BoolConstantValue && conditionValue.boolValue;
    } else {
      validAssert = true;
    }
    if (!validAssert) {
      if (message != null) {
        ConstantValue value = message.evaluate(environment);
        if (value is StringConstantValue) {
          String text = '${value.stringValue}';
          environment.reportError(this,
              MessageKind.INVALID_ASSERT_VALUE_MESSAGE, {'message': text});
        } else {
          environment.reportError(this, MessageKind.INVALID_ASSERT_VALUE,
              {'assertion': condition.toDartText()});
          // TODO(johnniwinther): Report invalid constant message?
        }
      } else {
        environment.reportError(this, MessageKind.INVALID_ASSERT_VALUE,
            {'assertion': condition.toDartText()});
      }
      return new NonConstantValue();
    }

    // Return a valid constant value to signal that assertion didn't fail.
    return new NullConstantValue();
  }

  @override
  accept(ConstantExpressionVisitor visitor, [context]) {
    return visitor.visitAssert(this, context);
  }

  @override
  ConstantExpression apply(NormalizedArguments arguments) {
    return new AssertConstantExpression(
        condition.apply(arguments), message?.apply(arguments));
  }
}

class InstantiationConstantExpression extends ConstantExpression {
  final List<DartType> typeArguments;
  final ConstantExpression expression;

  InstantiationConstantExpression(this.typeArguments, this.expression);

  @override
  ConstantExpressionKind get kind => ConstantExpressionKind.INSTANTIATION;

  @override
  void _createStructuredText(StringBuffer sb) {
    sb.write('Instantiation(typeArguments=$typeArguments,expression=');
    expression._createStructuredText(sb);
    sb.write(')');
  }

  @override
  ConstantValue evaluate(EvaluationEnvironment environment) {
    List<DartType> typeArgumentsInContext =
        typeArguments.map(environment.getTypeInContext).toList();
    return new InstantiationConstantValue(
        typeArgumentsInContext, expression.evaluate(environment));
  }

  @override
  int _computeHashCode() {
    return Hashing.objectHash(expression, Hashing.listHash(typeArguments));
  }

  @override
  ConstantExpression apply(NormalizedArguments arguments) {
    return new InstantiationConstantExpression(
        typeArguments, expression.apply(arguments));
  }

  @override
  bool _equals(InstantiationConstantExpression other) {
    return equalElements(typeArguments, other.typeArguments) &&
        expression == other.expression;
  }

  @override
  accept(ConstantExpressionVisitor visitor, [context]) {
    return visitor.visitInstantiation(this, context);
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

  R visitAs(AsConstantExpression exp, A context);
  R visitBool(BoolConstantExpression exp, A context);
  R visitInt(IntConstantExpression exp, A context);
  R visitDouble(DoubleConstantExpression exp, A context);
  R visitString(StringConstantExpression exp, A context);
  R visitNull(NullConstantExpression exp, A context);
  R visitList(ListConstantExpression exp, A context);
  R visitSet(SetConstantExpression exp, A context);
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
  R visitAssert(AssertConstantExpression exp, A context);
  R visitInstantiation(InstantiationConstantExpression exp, A context);

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

  @override
  void visitAs(AsConstantExpression exp, [_]) {
    visit(exp.expression);
    sb.write(' as ');
    sb.write(exp.type);
  }

  @override
  void visitBool(BoolConstantExpression exp, [_]) {
    sb.write(exp.boolValue);
  }

  @override
  void visitDouble(DoubleConstantExpression exp, [_]) {
    sb.write(exp.doubleValue);
  }

  @override
  void visitInt(IntConstantExpression exp, [_]) {
    sb.write(exp.intValue);
  }

  @override
  void visitNull(NullConstantExpression exp, [_]) {
    sb.write(null);
  }

  @override
  void visitString(StringConstantExpression exp, [_]) {
    // TODO(johnniwinther): Ensure correct escaping.
    sb.write('"${exp.stringValue}"');
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
  void visitSet(SetConstantExpression exp, [_]) {
    sb.write('const ');
    writeTypeArguments(exp.type);
    sb.write('{');
    sb.writeAll(exp.values, ', ');
    sb.write('}');
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
        sb.write('${string.stringValue}');
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

  @override
  void visitAssert(AssertConstantExpression exp, [_]) {
    sb.write('assert(');
    visit(exp.condition);
    if (exp.message != null) {
      sb.write(', ');
      visit(exp.message);
    }
    sb.write(')');
  }

  @override
  void visitInstantiation(InstantiationConstantExpression exp, [_]) {
    sb.write('<');
    sb.write(exp.typeArguments.join(', '));
    sb.write('>(');
    visit(exp.expression);
    sb.write(')');
  }

  @override
  String toString() => sb.toString();
}
