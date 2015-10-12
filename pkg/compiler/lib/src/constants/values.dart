// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.constants.values;

import '../common.dart';
import '../core_types.dart';
import '../dart_types.dart';
import '../elements/elements.dart'
    show ClassElement,
         Element,
         FieldElement,
         FunctionElement,
         PrefixElement;
import '../tree/tree.dart' hide unparse;
import '../util/util.dart' show Hashing;

abstract class ConstantValueVisitor<R, A> {
  const ConstantValueVisitor();

  R visitFunction(FunctionConstantValue constant, A arg);
  R visitNull(NullConstantValue constant, A arg);
  R visitInt(IntConstantValue constant, A arg);
  R visitDouble(DoubleConstantValue constant, A arg);
  R visitBool(BoolConstantValue constant, A arg);
  R visitString(StringConstantValue constant, A arg);
  R visitList(ListConstantValue constant, A arg);
  R visitMap(MapConstantValue constant, A arg);
  R visitConstructed(ConstructedConstantValue constant, A arg);
  R visitType(TypeConstantValue constant, A arg);
  R visitInterceptor(InterceptorConstantValue constant, A arg);
  R visitSynthetic(SyntheticConstantValue constant, A arg);
  R visitDeferred(DeferredConstantValue constant, A arg);
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
  bool get isMap => false;
  bool get isConstructedObject => false;
  bool get isFunction => false;
  /** Returns true if the constant is null, a bool, a number or a string. */
  bool get isPrimitive => false;
  /** Returns true if the constant is a list, a map or a constructed object. */
  bool get isObject => false;
  bool get isType => false;
  bool get isInterceptor => false;
  bool get isDummy => false;

  bool get isNaN => false;
  bool get isMinusZero => false;
  bool get isZero => false;
  bool get isOne => false;

  // TODO(johnniwinther): Replace with a 'type' getter.
  DartType getType(CoreTypes types);

  List<ConstantValue> getDependencies();

  accept(ConstantValueVisitor visitor, arg);

  /// The value of this constant in Dart syntax, if possible.
  ///
  /// For [ConstructedConstantValue]s there is no way to create a valid const
  /// expression from the value so the unparse of these is best effort.
  ///
  /// For the synthetic constants, [DeferredConstantValue],
  /// [SyntheticConstantValue], [InterceptorConstantValue] the unparse is
  /// descriptive only.
  String unparse();

  /// Returns a structured representation of this constant suited for debugging.
  String toStructuredString();

  String toString() {
    assertDebugMode("Use Constant.unparse() or Constant.toStructuredString() "
                    "instead of Constant.toString().");
    return toStructuredString();
  }
}

class FunctionConstantValue extends ConstantValue {
  FunctionElement element;

  FunctionConstantValue(this.element) {
    assert(element.type != null);
  }

  bool get isFunction => true;

  bool operator ==(var other) {
    if (other is !FunctionConstantValue) return false;
    return identical(other.element, element);
  }

  List<ConstantValue> getDependencies() => const <ConstantValue>[];

  DartString toDartString() {
    return new DartString.literal(element.name);
  }

  DartType getType(CoreTypes types) => element.type;

  int get hashCode => (17 * element.hashCode) & 0x7fffffff;

  accept(ConstantValueVisitor visitor, arg) => visitor.visitFunction(this, arg);

  String unparse() {
    if (element.isStatic) {
      return '${element.enclosingClass.name}.${element.name}';
    } else {
      return '${element.name}';
    }
  }

  String toStructuredString() {
    return 'FunctionConstant(${unparse()})';
  }
}

abstract class PrimitiveConstantValue extends ConstantValue {
  get primitiveValue;

  const PrimitiveConstantValue();

  bool get isPrimitive => true;

  bool operator ==(var other) {
    if (other is !PrimitiveConstantValue) return false;
    PrimitiveConstantValue otherPrimitive = other;
    // We use == instead of 'identical' so that DartStrings compare correctly.
    return primitiveValue == otherPrimitive.primitiveValue;
  }

  int get hashCode => throw new UnsupportedError('PrimitiveConstant.hashCode');

  // Primitive constants don't have dependencies.
  List<ConstantValue> getDependencies() => const <ConstantValue>[];

  DartString toDartString();

  /// This value in Dart syntax.
  String unparse() => primitiveValue.toString();
}

class NullConstantValue extends PrimitiveConstantValue {
  /** The value a Dart null is compiled to in JavaScript. */
  static const String JsNull = "null";

  factory NullConstantValue() => const NullConstantValue._internal();

  const NullConstantValue._internal();

  bool get isNull => true;

  get primitiveValue => null;

  DartType getType(CoreTypes types) => types.nullType;

  // The magic constant has no meaning. It is just a random value.
  int get hashCode => 785965825;

  DartString toDartString() => const LiteralDartString("null");

  accept(ConstantValueVisitor visitor, arg) => visitor.visitNull(this, arg);

  String toStructuredString() => 'NullConstant';
}

abstract class NumConstantValue extends PrimitiveConstantValue {
  const NumConstantValue();

  num get primitiveValue;

  bool get isNum => true;
}

class IntConstantValue extends NumConstantValue {
  final int primitiveValue;

  factory IntConstantValue(int value) {
    switch (value) {
      case 0: return const IntConstantValue._internal(0);
      case 1: return const IntConstantValue._internal(1);
      case 2: return const IntConstantValue._internal(2);
      case 3: return const IntConstantValue._internal(3);
      case 4: return const IntConstantValue._internal(4);
      case 5: return const IntConstantValue._internal(5);
      case 6: return const IntConstantValue._internal(6);
      case 7: return const IntConstantValue._internal(7);
      case 8: return const IntConstantValue._internal(8);
      case 9: return const IntConstantValue._internal(9);
      case 10: return const IntConstantValue._internal(10);
      case -1: return const IntConstantValue._internal(-1);
      case -2: return const IntConstantValue._internal(-2);
      default: return new IntConstantValue._internal(value);
    }
  }

  const IntConstantValue._internal(this.primitiveValue);

  bool get isInt => true;

  bool isUInt31() => primitiveValue >= 0 && primitiveValue < (1 << 31);

  bool isUInt32() => primitiveValue >= 0 && primitiveValue < (1 << 32);

  bool isPositive() => primitiveValue >= 0;

  bool get isZero => primitiveValue == 0;

  bool get isOne => primitiveValue == 1;

  DartType getType(CoreTypes types) => types.intType;

  // We have to override the equality operator so that ints and doubles are
  // treated as separate constants.
  // The is [:!IntConstant:] check at the beginning of the function makes sure
  // that we compare only equal to integer constants.
  bool operator ==(var other) {
    if (other is !IntConstantValue) return false;
    IntConstantValue otherInt = other;
    return primitiveValue == otherInt.primitiveValue;
  }

  int get hashCode => primitiveValue & Hashing.SMI_MASK;

  DartString toDartString() {
    return new DartString.literal(primitiveValue.toString());
  }

  accept(ConstantValueVisitor visitor, arg) => visitor.visitInt(this, arg);

  String toStructuredString() => 'IntConstant(${unparse()})';
}

class DoubleConstantValue extends NumConstantValue {
  final double primitiveValue;

  factory DoubleConstantValue(double value) {
    if (value.isNaN) {
      return const DoubleConstantValue._internal(double.NAN);
    } else if (value == double.INFINITY) {
      return const DoubleConstantValue._internal(double.INFINITY);
    } else if (value == -double.INFINITY) {
      return const DoubleConstantValue._internal(-double.INFINITY);
    } else if (value == 0.0 && !value.isNegative) {
      return const DoubleConstantValue._internal(0.0);
    } else if (value == 1.0) {
      return const DoubleConstantValue._internal(1.0);
    } else {
      return new DoubleConstantValue._internal(value);
    }
  }

  const DoubleConstantValue._internal(this.primitiveValue);

  bool get isDouble => true;

  bool get isNaN => primitiveValue.isNaN;

  // We need to check for the negative sign since -0.0 == 0.0.
  bool get isMinusZero => primitiveValue == 0.0 && primitiveValue.isNegative;

  bool get isZero => primitiveValue == 0.0;

  bool get isOne => primitiveValue == 1.0;

  DartType getType(CoreTypes types) => types.doubleType;

  bool operator ==(var other) {
    if (other is !DoubleConstantValue) return false;
    DoubleConstantValue otherDouble = other;
    double otherValue = otherDouble.primitiveValue;
    if (primitiveValue == 0.0 && otherValue == 0.0) {
      return primitiveValue.isNegative == otherValue.isNegative;
    } else if (primitiveValue.isNaN) {
      return otherValue.isNaN;
    } else {
      return primitiveValue == otherValue;
    }
  }

  int get hashCode => primitiveValue.hashCode;

  DartString toDartString() {
    return new DartString.literal(primitiveValue.toString());
  }

  accept(ConstantValueVisitor visitor, arg) => visitor.visitDouble(this, arg);

  String toStructuredString() => 'DoubleConstant(${unparse()})';
}

abstract class BoolConstantValue extends PrimitiveConstantValue {
  factory BoolConstantValue(value) {
    return value ? new TrueConstantValue() : new FalseConstantValue();
  }

  const BoolConstantValue._internal();

  bool get isBool => true;

  DartType getType(CoreTypes types) => types.boolType;

  BoolConstantValue negate();

  accept(ConstantValueVisitor visitor, arg) => visitor.visitBool(this, arg);

  String toStructuredString() => 'BoolConstant(${unparse()})';
}

class TrueConstantValue extends BoolConstantValue {
  factory TrueConstantValue() => const TrueConstantValue._internal();

  const TrueConstantValue._internal() : super._internal();

  bool get isTrue => true;

  bool get primitiveValue => true;

  FalseConstantValue negate() => new FalseConstantValue();

  bool operator ==(var other) => identical(this, other);

  // The magic constant is just a random value. It does not have any
  // significance.
  int get hashCode => 499;

  DartString toDartString() => const LiteralDartString("true");
}

class FalseConstantValue extends BoolConstantValue {
  factory FalseConstantValue() => const FalseConstantValue._internal();

  const FalseConstantValue._internal() : super._internal();

  bool get isFalse => true;

  bool get primitiveValue => false;

  TrueConstantValue negate() => new TrueConstantValue();

  bool operator ==(var other) => identical(this, other);

  // The magic constant is just a random value. It does not have any
  // significance.
  int get hashCode => 536555975;

  DartString toDartString() => const LiteralDartString("false");
}

class StringConstantValue extends PrimitiveConstantValue {
  final DartString primitiveValue;

  final int hashCode;

  // TODO(floitsch): cache StringConstants.
  // TODO(floitsch): compute hashcode without calling toString() on the
  // DartString.
  StringConstantValue(DartString value)
      : this.primitiveValue = value,
        this.hashCode = value.slowToString().hashCode;

  bool get isString => true;

  DartType getType(CoreTypes types) => types.stringType;

  bool operator ==(var other) {
    if (other is !StringConstantValue) return false;
    StringConstantValue otherString = other;
    return hashCode == otherString.hashCode &&
           primitiveValue == otherString.primitiveValue;
  }

  DartString toDartString() => primitiveValue;

  int get length => primitiveValue.length;

  accept(ConstantValueVisitor visitor, arg) => visitor.visitString(this, arg);

  // TODO(johnniwinther): Ensure correct escaping.
  String unparse() => '"${primitiveValue.slowToString()}"';

  String toStructuredString() => 'StringConstant(${unparse()})';
}

abstract class ObjectConstantValue extends ConstantValue {
  final InterfaceType type;

  ObjectConstantValue(this.type);

  bool get isObject => true;

  DartType getType(CoreTypes types) => type;

  void _unparseTypeArguments(StringBuffer sb) {
    if (!type.treatAsRaw) {
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

  bool get isType => true;

  bool operator ==(other) {
    return other is TypeConstantValue &&
           representedType == other.representedType;
  }

  int get hashCode => representedType.hashCode * 13;

  List<ConstantValue> getDependencies() => const <ConstantValue>[];

  accept(ConstantValueVisitor visitor, arg) => visitor.visitType(this, arg);

  String unparse() => '$representedType';

  String toStructuredString() => 'TypeConstant(${representedType})';
}

class ListConstantValue extends ObjectConstantValue {
  final List<ConstantValue> entries;
  final int hashCode;

  ListConstantValue(InterfaceType type, List<ConstantValue> entries)
      : this.entries = entries,
        hashCode = Hashing.listHash(entries, Hashing.objectHash(type)),
        super(type);

  bool get isList => true;

  bool operator ==(var other) {
    if (other is !ListConstantValue) return false;
    ListConstantValue otherList = other;
    if (hashCode != otherList.hashCode) return false;
    if (type != otherList.type) return false;
    if (entries.length != otherList.entries.length) return false;
    for (int i = 0; i < entries.length; i++) {
      if (entries[i] != otherList.entries[i]) return false;
    }
    return true;
  }

  List<ConstantValue> getDependencies() => entries;

  int get length => entries.length;

  accept(ConstantValueVisitor visitor, arg) => visitor.visitList(this, arg);

  String unparse() {
    StringBuffer sb = new StringBuffer();
    _unparseTypeArguments(sb);
    sb.write('[');
    for (int i = 0 ; i < length ; i++) {
      if (i > 0) sb.write(',');
      sb.write(entries[i].unparse());
    }
    sb.write(']');
    return sb.toString();
  }

  String toStructuredString() {
    StringBuffer sb = new StringBuffer();
    sb.write('ListConstant(');
    _unparseTypeArguments(sb);
    sb.write('[');
    for (int i = 0 ; i < length ; i++) {
      if (i > 0) sb.write(', ');
      sb.write(entries[i].toStructuredString());
    }
    sb.write('])');
    return sb.toString();
  }
}

class MapConstantValue extends ObjectConstantValue {
  final List<ConstantValue> keys;
  final List<ConstantValue> values;
  final int hashCode;

  MapConstantValue(InterfaceType type,
                   List<ConstantValue> keys,
                   List<ConstantValue> values)
      : this.keys = keys,
        this.values = values,
        this.hashCode = Hashing.listHash(values,
                            Hashing.listHash(keys,
                                Hashing.objectHash(type))),
        super(type) {
    assert(keys.length == values.length);
  }

  bool get isMap => true;

  bool operator ==(var other) {
    if (other is !MapConstantValue) return false;
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

  List<ConstantValue> getDependencies() {
    List<ConstantValue> result = <ConstantValue>[];
    result.addAll(keys);
    result.addAll(values);
    return result;
  }

  int get length => keys.length;

  accept(ConstantValueVisitor visitor, arg) => visitor.visitMap(this, arg);

  String unparse() {
    StringBuffer sb = new StringBuffer();
    _unparseTypeArguments(sb);
    sb.write('{');
    for (int i = 0 ; i < length ; i++) {
      if (i > 0) sb.write(',');
      sb.write(keys[i].unparse());
      sb.write(':');
      sb.write(values[i].unparse());
    }
    sb.write('}');
    return sb.toString();
  }

  String toStructuredString() {
    StringBuffer sb = new StringBuffer();
    sb.write('MapConstant(');
    _unparseTypeArguments(sb);
    sb.write('{');
    for (int i = 0; i < length; i++) {
      if (i > 0) sb.write(', ');
      sb.write(keys[i].toStructuredString());
      sb.write(': ');
      sb.write(values[i].toStructuredString());
    }
    sb.write('})');
    return sb.toString();
  }
}

class InterceptorConstantValue extends ConstantValue {
  /// The type for which this interceptor holds the methods.  The constant
  /// is a dispatch table for this type.
  final DartType dispatchedType;

  InterceptorConstantValue(this.dispatchedType);

  bool get isInterceptor => true;

  bool operator ==(other) {
    return other is InterceptorConstantValue
        && dispatchedType == other.dispatchedType;
  }

  int get hashCode => dispatchedType.hashCode * 43;

  List<ConstantValue> getDependencies() => const <ConstantValue>[];

  accept(ConstantValueVisitor visitor, arg) {
    return visitor.visitInterceptor(this, arg);
  }

  DartType getType(CoreTypes types) => const DynamicType();

  String unparse() {
    return 'interceptor($dispatchedType)';
  }

  String toStructuredString() {
    return 'InterceptorConstant(${dispatchedType.getStringAsDeclared("o")})';
  }
}

class SyntheticConstantValue extends ConstantValue {
  final payload;
  final kind;

  SyntheticConstantValue(this.kind, this.payload);

  bool get isDummy => true;

  bool operator ==(other) {
    return other is SyntheticConstantValue
        && payload == other.payload;
  }

  get hashCode => payload.hashCode * 17 + kind.hashCode;

  List<ConstantValue> getDependencies() => const <ConstantValue>[];

  accept(ConstantValueVisitor visitor, arg) {
    return visitor.visitSynthetic(this, arg);
  }

  DartType getType(CoreTypes types) => const DynamicType();

  String unparse() => 'synthetic($kind, $payload)';

  String toStructuredString() => 'SyntheticConstant($kind, $payload)';
}

class ConstructedConstantValue extends ObjectConstantValue {
  final Map<FieldElement, ConstantValue> fields;
  final int hashCode;

  ConstructedConstantValue(InterfaceType type,
                           Map<FieldElement, ConstantValue> fields)
    : this.fields = fields,
      hashCode = Hashing.mapHash(fields, Hashing.objectHash(type)),
      super(type) {
    assert(type != null);
    assert(!fields.containsValue(null));
  }

  bool get isConstructedObject => true;

  bool operator ==(var otherVar) {
    if (otherVar is !ConstructedConstantValue) return false;
    ConstructedConstantValue other = otherVar;
    if (hashCode != other.hashCode) return false;
    if (type != other.type) return false;
    if (fields.length != other.fields.length) return false;
    for (FieldElement field in fields.keys) {
      if (fields[field] != other.fields[field]) return false;
    }
    return true;
  }

  List<ConstantValue> getDependencies() => fields.values.toList();

  accept(ConstantValueVisitor visitor, arg) {
    return visitor.visitConstructed(this, arg);
  }

  String unparse() {
    StringBuffer sb = new StringBuffer();
    sb.write(type.name);
    _unparseTypeArguments(sb);
    sb.write('(');
    int i = 0;
    fields.forEach((FieldElement field, ConstantValue value) {
      if (i > 0) sb.write(',');
      sb.write(field.name);
      sb.write('=');
      sb.write(value.unparse());
      i++;
    });
    sb.write(')');
    return sb.toString();
  }

  String toStructuredString() {
    StringBuffer sb = new StringBuffer();
    sb.write('ConstructedConstant(');
    sb.write(type);
    sb.write('(');
    int i = 0;
    fields.forEach((FieldElement field, ConstantValue value) {
      if (i > 0) sb.write(',');
      sb.write(field.name);
      sb.write('=');
      sb.write(value.toStructuredString());
      i++;
    });
    sb.write('))');
    return sb.toString();
  }
}

/// A reference to a constant in another output unit.
/// Used for referring to deferred constants.
class DeferredConstantValue extends ConstantValue {
  DeferredConstantValue(this.referenced, this.prefix);

  final ConstantValue referenced;
  final PrefixElement prefix;

  bool get isReference => true;

  bool operator ==(other) {
    return other is DeferredConstantValue
        && referenced == other.referenced
        && prefix == other.prefix;
  }

  get hashCode => (referenced.hashCode * 17 + prefix.hashCode) & 0x3fffffff;

  List<ConstantValue> getDependencies() => <ConstantValue>[referenced];

  accept(ConstantValueVisitor visitor, arg) => visitor.visitDeferred(this, arg);

  DartType getType(CoreTypes types) => referenced.getType(types);

  String unparse() => 'deferred(${referenced.unparse()})';

  String toStructuredString() => 'DeferredConstant($referenced)';
}

/// A constant value resulting from a non constant or erroneous constant
/// expression.
// TODO(johnniwinther): Expand this to contain the error kind.
class NonConstantValue extends ConstantValue {
  bool get isConstant => false;

  @override
  accept(ConstantValueVisitor visitor, arg) {
    // TODO(johnniwinther): Should this be part of the visiting?
  }

  @override
  List<ConstantValue> getDependencies() => const <ConstantValue>[];

  @override
  DartType getType(CoreTypes types) => const DynamicType();

  @override
  String toStructuredString() => 'NonConstant';

  @override
  String unparse() => '>>non-constant<<';
}