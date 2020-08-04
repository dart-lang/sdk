// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.constants.values;

import '../common.dart';
import '../common_elements.dart';
import '../elements/entities.dart';
import '../elements/types.dart';
import '../deferred_load.dart' show OutputUnit;
import '../js/js.dart' as js;
import '../util/util.dart';

enum ConstantValueKind {
  FUNCTION,
  NULL,
  INT,
  DOUBLE,
  BOOL,
  STRING,
  LIST,
  SET,
  MAP,
  CONSTRUCTED,
  TYPE,
  INTERCEPTOR,
  JS_NAME,
  DUMMY_INTERCEPTOR,
  UNREACHABLE,
  INSTANTIATION,
  DEFERRED_GLOBAL,
  NON_CONSTANT,
}

abstract class ConstantValueVisitor<R, A> {
  const ConstantValueVisitor();

  R visitFunction(covariant FunctionConstantValue constant, covariant A arg);
  R visitNull(covariant NullConstantValue constant, covariant A arg);
  R visitInt(covariant IntConstantValue constant, covariant A arg);
  R visitDouble(covariant DoubleConstantValue constant, covariant A arg);
  R visitBool(covariant BoolConstantValue constant, covariant A arg);
  R visitString(covariant StringConstantValue constant, covariant A arg);
  R visitList(covariant ListConstantValue constant, covariant A arg);
  R visitSet(covariant SetConstantValue constant, covariant A arg);
  R visitMap(covariant MapConstantValue constant, covariant A arg);
  R visitConstructed(
      covariant ConstructedConstantValue constant, covariant A arg);
  R visitType(covariant TypeConstantValue constant, covariant A arg);
  R visitInterceptor(
      covariant InterceptorConstantValue constant, covariant A arg);
  R visitDummyInterceptor(
      covariant DummyInterceptorConstantValue constant, covariant A arg);
  R visitUnreachable(
      covariant UnreachableConstantValue constant, covariant A arg);
  R visitJsName(covariant JsNameConstantValue constant, covariant A arg);
  R visitDeferredGlobal(
      covariant DeferredGlobalConstantValue constant, covariant A arg);
  R visitNonConstant(covariant NonConstantValue constant, covariant A arg);
  R visitInstantiation(
      covariant InstantiationConstantValue constant, covariant A arg);
}

abstract class ConstantValue {
  const ConstantValue();

  /// `true` if this is a valid constant value.
  bool get isConstant => true;

  bool get isNull => false;
  bool get isBool => false;
  bool get isTrue => false;
  bool get isFalse => false;
  bool get isInt => false;
  bool get isDouble => false;
  bool get isNum => false;
  bool get isString => false;
  bool get isList => false;
  bool get isSet => false;
  bool get isMap => false;
  bool get isConstructedObject => false;
  bool get isFunction => false;

  /// Returns true if the constant is null, a bool, a number or a string.
  bool get isPrimitive => false;

  /// Returns true if the constant is a list, a map or a constructed object.
  bool get isObject => false;
  bool get isType => false;
  bool get isInterceptor => false;
  bool get isDummy => false;

  bool get isNaN => false;
  bool get isMinusZero => false;
  bool get isZero => false;
  bool get isOne => false;
  bool get isPositiveInfinity => false;
  bool get isNegativeInfinity => false;

  // TODO(johnniwinther): Replace with a 'type' getter.
  DartType getType(CommonElements types);

  List<ConstantValue> getDependencies();

  accept(ConstantValueVisitor visitor, arg);

  /// The value of this constant in Dart syntax, if possible.
  ///
  /// For [ConstructedConstantValue]s there is no way to create a valid const
  /// expression from the value so the unparse of these is best effort.
  ///
  /// For the synthetic constants, [DeferredConstantValue],
  /// [DeferredGlobalConstantValue], [SyntheticConstantValue],
  /// [InterceptorConstantValue] the unparse is descriptive only.
  String toDartText(DartTypes dartTypes);

  /// Returns a structured representation of this constant suited for debugging.
  String toStructuredText(DartTypes dartTypes);

  ConstantValueKind get kind;

  @override
  String toString() {
    assertDebugMode("Use ConstantValue.toDartText() or "
        "ConstantValue.toStructuredText() "
        "instead of ConstantValue.toString().");
    return toStructuredText(null);
  }
}

class FunctionConstantValue extends ConstantValue {
  final FunctionEntity element;
  // TODO(johnniwinther): Should the type be derived from [element].
  final FunctionType type;

  FunctionConstantValue(this.element, this.type);

  @override
  bool get isFunction => true;

  @override
  bool operator ==(var other) {
    if (other is! FunctionConstantValue) return false;
    return identical(other.element, element);
  }

  @override
  List<ConstantValue> getDependencies() => const <ConstantValue>[];

  @override
  FunctionType getType(CommonElements types) => type;

  @override
  int get hashCode => (17 * element.hashCode) & 0x7fffffff;

  @override
  accept(ConstantValueVisitor visitor, arg) => visitor.visitFunction(this, arg);

  @override
  ConstantValueKind get kind => ConstantValueKind.FUNCTION;

  @override
  String toDartText(DartTypes dartTypes) {
    if (element.enclosingClass != null) {
      return '${element.enclosingClass.name}.${element.name}';
    } else {
      return '${element.name}';
    }
  }

  @override
  String toStructuredText(DartTypes dartTypes) {
    return 'FunctionConstant(${toDartText(dartTypes)})';
  }
}

abstract class PrimitiveConstantValue extends ConstantValue {
  const PrimitiveConstantValue();

  @override
  bool get isPrimitive => true;

  @override
  bool operator ==(var other) {
    // Making this method abstract does not give us an error.
    throw new UnsupportedError('PrimitiveConstant.==');
  }

  @override
  int get hashCode => throw new UnsupportedError('PrimitiveConstant.hashCode');

  // Primitive constants don't have dependencies.
  @override
  List<ConstantValue> getDependencies() => const <ConstantValue>[];
}

class NullConstantValue extends PrimitiveConstantValue {
  /// The value a Dart null is compiled to in JavaScript.
  static const String JsNull = "null";

  const factory NullConstantValue() = NullConstantValue._internal;

  const NullConstantValue._internal();

  @override
  bool get isNull => true;

  @override
  DartType getType(CommonElements types) => types.nullType;

  @override
  bool operator ==(other) => other is NullConstantValue;

  // The magic constant has no meaning. It is just a random value.
  @override
  int get hashCode => 785965825;

  @override
  accept(ConstantValueVisitor visitor, arg) => visitor.visitNull(this, arg);

  @override
  ConstantValueKind get kind => ConstantValueKind.NULL;

  @override
  String toStructuredText(DartTypes dartTypes) => 'NullConstant';

  @override
  String toDartText(DartTypes dartTypes) => 'null';
}

abstract class NumConstantValue extends PrimitiveConstantValue {
  double get doubleValue;

  @override
  bool get isNum => true;

  const NumConstantValue();
}

class IntConstantValue extends NumConstantValue {
  final BigInt intValue;

  // Caching IntConstantValues representing -2 through 10 so that we don't have
  // to create new ones every time those values are used.
  static Map<BigInt, IntConstantValue> _cachedValues = {};

  @override
  double get doubleValue => intValue.toDouble();

  factory IntConstantValue(BigInt value) {
    var existing = _cachedValues[value];
    if (existing != null) return existing;
    var intConstantVal = new IntConstantValue._internal(value);
    var intValue = value.toInt();
    if (intValue <= -2 && intValue >= 10) {
      _cachedValues[value] = intConstantVal;
    }
    return intConstantVal;
  }

  const IntConstantValue._internal(this.intValue);

  @override
  bool get isInt => true;

  bool isUInt31() => intValue.toUnsigned(31) == intValue;

  bool isUInt32() => intValue.toUnsigned(32) == intValue;

  bool isPositive() => intValue >= BigInt.zero;

  @override
  bool get isZero => intValue == BigInt.zero;

  @override
  bool get isOne => intValue == BigInt.one;

  @override
  DartType getType(CommonElements types) => types.intType;

  @override
  bool operator ==(var other) {
    // Ints and doubles are treated as separate constants.
    if (other is! IntConstantValue) return false;
    IntConstantValue otherInt = other;
    return intValue == otherInt.intValue;
  }

  @override
  int get hashCode => intValue.hashCode & Hashing.SMI_MASK;

  @override
  accept(ConstantValueVisitor visitor, arg) => visitor.visitInt(this, arg);

  @override
  ConstantValueKind get kind => ConstantValueKind.INT;

  @override
  String toStructuredText(DartTypes dartTypes) =>
      'IntConstant(${toDartText(dartTypes)})';

  @override
  String toDartText(DartTypes dartTypes) => intValue.toString();
}

class DoubleConstantValue extends NumConstantValue {
  @override
  final double doubleValue;

  factory DoubleConstantValue(double value) {
    if (value.isNaN) {
      return const DoubleConstantValue._internal(double.nan);
    } else if (value == double.infinity) {
      return const DoubleConstantValue._internal(double.infinity);
    } else if (value == -double.infinity) {
      return const DoubleConstantValue._internal(-double.infinity);
    } else if (value == 0.0 && !value.isNegative) {
      return const DoubleConstantValue._internal(0.0);
    } else if (value == 1.0) {
      return const DoubleConstantValue._internal(1.0);
    } else {
      return new DoubleConstantValue._internal(value);
    }
  }

  const DoubleConstantValue._internal(this.doubleValue);

  @override
  bool get isDouble => true;

  @override
  bool get isNaN => doubleValue.isNaN;

  // We need to check for the negative sign since -0.0 == 0.0.
  @override
  bool get isMinusZero => doubleValue == 0.0 && doubleValue.isNegative;

  @override
  bool get isZero => doubleValue == 0.0;

  @override
  bool get isOne => doubleValue == 1.0;

  @override
  bool get isPositiveInfinity => doubleValue == double.infinity;

  @override
  bool get isNegativeInfinity => doubleValue == -double.infinity;

  @override
  DartType getType(CommonElements types) => types.doubleType;

  @override
  bool operator ==(var other) {
    if (other is! DoubleConstantValue) return false;
    DoubleConstantValue otherDouble = other;
    double otherValue = otherDouble.doubleValue;
    if (doubleValue == 0.0 && otherValue == 0.0) {
      return doubleValue.isNegative == otherValue.isNegative;
    } else if (doubleValue.isNaN) {
      return otherValue.isNaN;
    } else {
      return doubleValue == otherValue;
    }
  }

  @override
  int get hashCode => doubleValue.hashCode;

  @override
  accept(ConstantValueVisitor visitor, arg) => visitor.visitDouble(this, arg);

  @override
  ConstantValueKind get kind => ConstantValueKind.DOUBLE;

  @override
  String toStructuredText(DartTypes dartTypes) =>
      'DoubleConstant(${toDartText(dartTypes)})';

  @override
  String toDartText(DartTypes dartTypes) => doubleValue.toString();
}

abstract class BoolConstantValue extends PrimitiveConstantValue {
  factory BoolConstantValue(value) {
    return value ? new TrueConstantValue() : new FalseConstantValue();
  }

  const BoolConstantValue._internal();

  @override
  bool get isBool => true;

  bool get boolValue;

  @override
  DartType getType(CommonElements types) => types.boolType;

  BoolConstantValue negate();

  @override
  accept(ConstantValueVisitor visitor, arg) => visitor.visitBool(this, arg);

  @override
  ConstantValueKind get kind => ConstantValueKind.BOOL;

  @override
  String toStructuredText(DartTypes dartTypes) =>
      'BoolConstant(${toDartText(dartTypes)})';
}

class TrueConstantValue extends BoolConstantValue {
  factory TrueConstantValue() => const TrueConstantValue._internal();

  const TrueConstantValue._internal() : super._internal();

  @override
  bool get isTrue => true;

  @override
  bool get boolValue => true;

  @override
  FalseConstantValue negate() => new FalseConstantValue();

  @override
  bool operator ==(var other) => identical(this, other);

  // The magic constant is just a random value. It does not have any
  // significance.
  @override
  int get hashCode => 499;

  @override
  String toDartText(DartTypes dartTypes) => boolValue.toString();
}

class FalseConstantValue extends BoolConstantValue {
  factory FalseConstantValue() => const FalseConstantValue._internal();

  const FalseConstantValue._internal() : super._internal();

  @override
  bool get isFalse => true;

  @override
  bool get boolValue => false;

  @override
  TrueConstantValue negate() => new TrueConstantValue();

  @override
  bool operator ==(var other) => identical(this, other);

  // The magic constant is just a random value. It does not have any
  // significance.
  @override
  int get hashCode => 536555975;

  @override
  String toDartText(DartTypes dartTypes) => boolValue.toString();
}

class StringConstantValue extends PrimitiveConstantValue {
  final String stringValue;

  @override
  final int hashCode;

  // TODO(floitsch): cache StringConstants.
  StringConstantValue(String value)
      : this.stringValue = value,
        this.hashCode = value.hashCode;

  @override
  bool get isString => true;

  @override
  DartType getType(CommonElements types) => types.stringType;

  @override
  bool operator ==(var other) {
    if (identical(this, other)) return true;
    if (other is! StringConstantValue) return false;
    StringConstantValue otherString = other;
    return hashCode == otherString.hashCode &&
        stringValue == otherString.stringValue;
  }

  String toDartString() => stringValue;

  int get length => stringValue.length;

  @override
  accept(ConstantValueVisitor visitor, arg) => visitor.visitString(this, arg);

  @override
  ConstantValueKind get kind => ConstantValueKind.STRING;

  // TODO(johnniwinther): Ensure correct escaping.
  @override
  String toDartText(DartTypes dartTypes) => '"${stringValue}"';

  @override
  String toStructuredText(DartTypes dartTypes) =>
      'StringConstant(${toDartText(dartTypes)})';
}

abstract class ObjectConstantValue extends ConstantValue {
  final InterfaceType type;

  ObjectConstantValue(this.type);

  @override
  bool get isObject => true;

  @override
  DartType getType(CommonElements types) => type;

  void _unparseTypeArguments(DartTypes dartTypes, StringBuffer sb) {
    if (dartTypes == null || !dartTypes.treatAsRawType(type)) {
      sb.write('<');
      sb.write(type.typeArguments.join(', '));
      sb.write('>');
    }
  }
}

class TypeConstantValue extends ObjectConstantValue {
  /// The user type that this constant represents.
  final DartType representedType;

  TypeConstantValue(this.representedType, InterfaceType type) : super(type);

  @override
  bool get isType => true;

  @override
  bool operator ==(other) {
    return other is TypeConstantValue &&
        representedType == other.representedType;
  }

  @override
  int get hashCode => representedType.hashCode * 13;

  @override
  List<ConstantValue> getDependencies() => const <ConstantValue>[];

  @override
  accept(ConstantValueVisitor visitor, arg) => visitor.visitType(this, arg);

  @override
  ConstantValueKind get kind => ConstantValueKind.TYPE;

  @override
  String toDartText(DartTypes dartTypes) => '$representedType';

  @override
  String toStructuredText(DartTypes dartTypes) =>
      'TypeConstant(${representedType})';
}

class ListConstantValue extends ObjectConstantValue {
  final List<ConstantValue> entries;
  @override
  final int hashCode;

  ListConstantValue(InterfaceType type, List<ConstantValue> entries)
      : this.entries = entries,
        hashCode = Hashing.listHash(entries, Hashing.objectHash(type)),
        super(type);

  @override
  bool get isList => true;

  @override
  bool operator ==(var other) {
    if (identical(this, other)) return true;
    if (other is! ListConstantValue) return false;
    ListConstantValue otherList = other;
    if (hashCode != otherList.hashCode) return false;
    if (type != otherList.type) return false;
    if (entries.length != otherList.entries.length) return false;
    for (int i = 0; i < entries.length; i++) {
      if (entries[i] != otherList.entries[i]) return false;
    }
    return true;
  }

  @override
  List<ConstantValue> getDependencies() => entries;

  int get length => entries.length;

  @override
  accept(ConstantValueVisitor visitor, arg) => visitor.visitList(this, arg);

  @override
  ConstantValueKind get kind => ConstantValueKind.LIST;

  @override
  String toDartText(DartTypes dartTypes) {
    StringBuffer sb = new StringBuffer();
    _unparseTypeArguments(dartTypes, sb);
    sb.write('[');
    for (int i = 0; i < length; i++) {
      if (i > 0) sb.write(',');
      sb.write(entries[i].toDartText(dartTypes));
    }
    sb.write(']');
    return sb.toString();
  }

  @override
  String toStructuredText(DartTypes dartTypes) {
    StringBuffer sb = new StringBuffer();
    sb.write('ListConstant(');
    _unparseTypeArguments(dartTypes, sb);
    sb.write('[');
    for (int i = 0; i < length; i++) {
      if (i > 0) sb.write(', ');
      sb.write(entries[i].toStructuredText(dartTypes));
    }
    sb.write('])');
    return sb.toString();
  }
}

abstract class SetConstantValue extends ObjectConstantValue {
  final List<ConstantValue> values;
  @override
  final int hashCode;

  SetConstantValue(InterfaceType type, List<ConstantValue> values)
      : values = values,
        hashCode = Hashing.listHash(values, Hashing.objectHash(type)),
        super(type);

  @override
  bool get isSet => true;

  @override
  bool operator ==(var other) {
    if (identical(this, other)) return true;
    if (other is! SetConstantValue) return false;
    SetConstantValue otherSet = other;
    if (hashCode != otherSet.hashCode) return false;
    if (type != otherSet.type) return false;
    if (length != otherSet.length) return false;
    for (int i = 0; i < values.length; i++) {
      if (values[i] != otherSet.values[i]) return false;
    }
    return true;
  }

  @override
  List<ConstantValue> getDependencies() => values;

  int get length => values.length;

  @override
  accept(ConstantValueVisitor visitor, arg) => visitor.visitSet(this, arg);

  @override
  String toDartText(DartTypes dartTypes) {
    StringBuffer sb = new StringBuffer();
    _unparseTypeArguments(dartTypes, sb);
    sb.write('{');
    sb.writeAll(values.map((v) => v.toDartText(dartTypes)), ',');
    sb.write('}');
    return sb.toString();
  }

  @override
  String toStructuredText(DartTypes dartTypes) {
    StringBuffer sb = new StringBuffer();
    sb.write('SetConstant(');
    _unparseTypeArguments(dartTypes, sb);
    sb.write('{');
    sb.writeAll(
        values.map((v) => v.toStructuredText(
              dartTypes,
            )),
        ', ');
    sb.write('})');
    return sb.toString();
  }

  @override
  ConstantValueKind get kind => ConstantValueKind.SET;
}

abstract class MapConstantValue extends ObjectConstantValue {
  final List<ConstantValue> keys;
  final List<ConstantValue> values;
  @override
  final int hashCode;
  Map<ConstantValue, ConstantValue> _lookupMap;

  MapConstantValue(
      InterfaceType type, List<ConstantValue> keys, List<ConstantValue> values)
      : this.keys = keys,
        this.values = values,
        this.hashCode = Hashing.listHash(
            values, Hashing.listHash(keys, Hashing.objectHash(type))),
        super(type) {
    assert(keys.length == values.length);
  }

  @override
  bool get isMap => true;

  @override
  bool operator ==(var other) {
    if (identical(this, other)) return true;
    if (other is! MapConstantValue) return false;
    MapConstantValue otherMap = other;
    if (hashCode != otherMap.hashCode) return false;
    if (type != other.type) return false;
    if (length != other.length) return false;
    for (int i = 0; i < length; i++) {
      if (keys[i] != otherMap.keys[i]) return false;
      if (values[i] != otherMap.values[i]) return false;
    }
    return true;
  }

  @override
  List<ConstantValue> getDependencies() {
    List<ConstantValue> result = <ConstantValue>[];
    result.addAll(keys);
    result.addAll(values);
    return result;
  }

  int get length => keys.length;

  ConstantValue lookup(ConstantValue key) {
    var lookupMap = _lookupMap ??=
        new Map<ConstantValue, ConstantValue>.fromIterables(keys, values);
    return lookupMap[key];
  }

  @override
  accept(ConstantValueVisitor visitor, arg) => visitor.visitMap(this, arg);

  @override
  ConstantValueKind get kind => ConstantValueKind.MAP;

  @override
  String toDartText(DartTypes dartTypes) {
    StringBuffer sb = new StringBuffer();
    _unparseTypeArguments(dartTypes, sb);
    sb.write('{');
    for (int i = 0; i < length; i++) {
      if (i > 0) sb.write(',');
      sb.write(keys[i].toDartText(dartTypes));
      sb.write(':');
      sb.write(values[i].toDartText(dartTypes));
    }
    sb.write('}');
    return sb.toString();
  }

  @override
  String toStructuredText(DartTypes dartTypes) {
    StringBuffer sb = new StringBuffer();
    sb.write('MapConstant(');
    _unparseTypeArguments(dartTypes, sb);
    sb.write('{');
    for (int i = 0; i < length; i++) {
      if (i > 0) sb.write(', ');
      sb.write(keys[i].toStructuredText(dartTypes));
      sb.write(': ');
      sb.write(values[i].toStructuredText(dartTypes));
    }
    sb.write('})');
    return sb.toString();
  }
}

class InterceptorConstantValue extends ConstantValue {
  /// The class for which this interceptor holds the methods.  The constant
  /// is a dispatch table for this class.
  final ClassEntity cls;

  InterceptorConstantValue(this.cls);

  @override
  bool get isInterceptor => true;

  @override
  bool operator ==(other) {
    return other is InterceptorConstantValue && cls == other.cls;
  }

  @override
  int get hashCode => cls.hashCode * 43;

  @override
  List<ConstantValue> getDependencies() => const <ConstantValue>[];

  @override
  accept(ConstantValueVisitor visitor, arg) {
    return visitor.visitInterceptor(this, arg);
  }

  @override
  DartType getType(CommonElements types) => types.dynamicType;

  @override
  ConstantValueKind get kind => ConstantValueKind.INTERCEPTOR;

  @override
  String toDartText(DartTypes dartTypes) {
    return 'interceptor($cls)';
  }

  @override
  String toStructuredText(DartTypes dartTypes) {
    return 'InterceptorConstant(${cls.name})';
  }
}

class JsNameConstantValue extends ConstantValue {
  final js.LiteralString name;

  JsNameConstantValue(this.name);

  @override
  bool get isDummy => true;

  @override
  bool operator ==(other) {
    return other is JsNameConstantValue && name == other.name;
  }

  @override
  get hashCode => name.hashCode * 17;

  @override
  List<ConstantValue> getDependencies() => const <ConstantValue>[];

  @override
  accept(ConstantValueVisitor visitor, arg) {
    return visitor.visitJsName(this, arg);
  }

  @override
  DartType getType(CommonElements types) => types.dynamicType;

  @override
  ConstantValueKind get kind => ConstantValueKind.JS_NAME;

  @override
  String toDartText(DartTypes dartTypes) => 'js_name(${name})';

  @override
  String toStructuredText(DartTypes dartTypes) => 'JsNameConstant(${name})';
}

/// A constant used as the dummy receiver value for intercepted calls with
/// a known non-interceptor target.
// TODO(sra): Rename fo 'DummyReceiverConstantValue'.
class DummyInterceptorConstantValue extends ConstantValue {
  factory DummyInterceptorConstantValue() =>
      const DummyInterceptorConstantValue._();

  const DummyInterceptorConstantValue._();

  @override
  bool get isDummy => true;

  @override
  List<ConstantValue> getDependencies() => const <ConstantValue>[];

  @override
  accept(ConstantValueVisitor visitor, arg) {
    return visitor.visitDummyInterceptor(this, arg);
  }

  @override
  DartType getType(CommonElements types) => types.dynamicType;

  @override
  ConstantValueKind get kind => ConstantValueKind.DUMMY_INTERCEPTOR;

  @override
  String toDartText(DartTypes dartTypes) => 'dummy_interceptor()';

  @override
  String toStructuredText(DartTypes dartTypes) => 'DummyInterceptorConstant()';
}

// A constant with an empty type used in [HInstruction]s of an expression
// in an unreachable context.
class UnreachableConstantValue extends ConstantValue {
  factory UnreachableConstantValue() => const UnreachableConstantValue._();

  const UnreachableConstantValue._();

  @override
  bool get isDummy => true;

  @override
  List<ConstantValue> getDependencies() => const <ConstantValue>[];

  @override
  accept(ConstantValueVisitor visitor, arg) {
    return visitor.visitUnreachable(this, arg);
  }

  @override
  DartType getType(CommonElements types) => types.dynamicType;

  @override
  ConstantValueKind get kind => ConstantValueKind.UNREACHABLE;

  @override
  String toDartText(DartTypes dartTypes) => 'unreachable()';

  @override
  String toStructuredText(DartTypes dartTypes) => 'UnreachableConstant()';
}

class ConstructedConstantValue extends ObjectConstantValue {
  // TODO(johnniwinther): Make [fields] private to avoid misuse of the map
  // ordering and mutability.
  final Map<FieldEntity, ConstantValue> fields;
  @override
  final int hashCode;

  ConstructedConstantValue(
      InterfaceType type, Map<FieldEntity, ConstantValue> fields)
      : this.fields = fields,
        hashCode = Hashing.unorderedMapHash(fields, Hashing.objectHash(type)),
        super(type) {
    assert(type != null);
    assert(!fields.containsKey(null));
    assert(!fields.containsValue(null));
  }

  @override
  bool get isConstructedObject => true;

  @override
  bool operator ==(var otherVar) {
    if (identical(this, otherVar)) return true;
    if (otherVar is! ConstructedConstantValue) return false;
    ConstructedConstantValue other = otherVar;
    if (hashCode != other.hashCode) return false;
    if (type != other.type) return false;
    if (fields.length != other.fields.length) return false;
    for (FieldEntity field in fields.keys) {
      if (fields[field] != other.fields[field]) return false;
    }
    return true;
  }

  @override
  List<ConstantValue> getDependencies() => fields.values.toList();

  @override
  accept(ConstantValueVisitor visitor, arg) {
    return visitor.visitConstructed(this, arg);
  }

  @override
  ConstantValueKind get kind => ConstantValueKind.CONSTRUCTED;

  Iterable<FieldEntity> get _fieldsSortedByName {
    return fields.keys.toList()..sort((a, b) => a.name.compareTo(b.name));
  }

  @override
  String toDartText(DartTypes dartTypes) {
    StringBuffer sb = new StringBuffer();
    sb.write(type.element.name);
    _unparseTypeArguments(dartTypes, sb);
    sb.write('(');
    int i = 0;
    for (FieldEntity field in _fieldsSortedByName) {
      ConstantValue value = fields[field];
      if (i > 0) sb.write(',');
      sb.write(field.name);
      sb.write('=');
      sb.write(value.toDartText(dartTypes));
      i++;
    }
    sb.write(')');
    return sb.toString();
  }

  @override
  String toStructuredText(DartTypes dartTypes) {
    StringBuffer sb = new StringBuffer();
    sb.write('ConstructedConstant(');
    sb.write(type);
    sb.write('(');
    int i = 0;
    for (FieldEntity field in _fieldsSortedByName) {
      ConstantValue value = fields[field];
      if (i > 0) sb.write(',');
      sb.write(field.name);
      sb.write('=');
      sb.write(value.toStructuredText(dartTypes));
      i++;
    }
    sb.write('))');
    return sb.toString();
  }
}

class InstantiationConstantValue extends ConstantValue {
  final List<DartType> typeArguments;
  final FunctionConstantValue function;

  InstantiationConstantValue(this.typeArguments, this.function);

  @override
  bool operator ==(other) {
    if (identical(this, other)) return true;
    return other is InstantiationConstantValue &&
        function == other.function &&
        equalElements(typeArguments, other.typeArguments);
  }

  @override
  int get hashCode {
    return Hashing.objectHash(function, Hashing.listHash(typeArguments));
  }

  @override
  List<ConstantValue> getDependencies() => <ConstantValue>[function];

  @override
  accept(ConstantValueVisitor visitor, arg) =>
      visitor.visitInstantiation(this, arg);

  @override
  DartType getType(CommonElements types) {
    FunctionType type = function.getType(types);
    return types.dartTypes.instantiate(type, typeArguments);
  }

  @override
  ConstantValueKind get kind => ConstantValueKind.INSTANTIATION;

  @override
  String toDartText(DartTypes dartTypes) =>
      '<${typeArguments.join(', ')}>(${function.toDartText(dartTypes)})';

  @override
  String toStructuredText(DartTypes dartTypes) {
    return 'InstantiationConstant($typeArguments,'
        '${function.toStructuredText(dartTypes)})';
  }
}

/// A reference to a constant in another output unit.
///
/// Used for referring to deferred constants that appear as initializers of
/// final (non-const) global fields.
///
// TODO(sigmund): this should eventually not be a constant value. In particular,
// [DeferredConstantValue] is introduced by the constant evaluator when it first
// sees constants used in the program. [DeferredGlobalConstantValue] are
// introduced later by the SSA builder and should be represented
// with a dedicated JEntity instead. We currently model them as a regular
// constant to take advantage of the machinery we already have in place to
// generate deferred constants in the emitter.
class DeferredGlobalConstantValue extends ConstantValue {
  DeferredGlobalConstantValue(this.referenced, this.unit);

  final ConstantValue referenced;
  final OutputUnit unit;

  bool get isReference => true;

  @override
  bool operator ==(other) {
    return other is DeferredGlobalConstantValue &&
        referenced == other.referenced &&
        unit == other.unit;
  }

  @override
  get hashCode => (referenced.hashCode * 17 + unit.hashCode) & 0x3fffffff;

  @override
  List<ConstantValue> getDependencies() => <ConstantValue>[referenced];

  @override
  accept(ConstantValueVisitor visitor, arg) =>
      visitor.visitDeferredGlobal(this, arg);

  @override
  DartType getType(CommonElements types) => referenced.getType(types);

  @override
  ConstantValueKind get kind => ConstantValueKind.DEFERRED_GLOBAL;

  @override
  String toDartText(DartTypes dartTypes) =>
      'deferred_global(${referenced.toDartText(dartTypes)})';

  @override
  String toStructuredText(DartTypes dartTypes) {
    return 'DeferredGlobalConstant(${referenced.toStructuredText(dartTypes)})';
  }
}

/// A constant value resulting from a non constant or erroneous constant
/// expression.
// TODO(johnniwinther): Expand this to contain the error kind.
class NonConstantValue extends ConstantValue {
  @override
  bool get isConstant => false;

  @override
  accept(ConstantValueVisitor visitor, arg) {
    return visitor.visitNonConstant(this, arg);
  }

  @override
  List<ConstantValue> getDependencies() => const <ConstantValue>[];

  @override
  DartType getType(CommonElements types) => types.dynamicType;

  @override
  ConstantValueKind get kind => ConstantValueKind.NON_CONSTANT;

  @override
  String toStructuredText(DartTypes dartTypes) => 'NonConstant';

  @override
  String toDartText(DartTypes dartTypes) => '>>non-constant<<';
}
