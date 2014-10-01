// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.constants.values;

import '../dart_types.dart';
import '../dart2jslib.dart'
    show assertDebugMode,
         Compiler;
import '../elements/elements.dart'
    show ClassElement,
         Element,
         FunctionElement,
         PrefixElement;
import '../tree/tree.dart' hide unparse;
import '../types/types.dart' as ti show TypeMask;
import '../util/util.dart' show SMI_MASK;

abstract class ConstantValueVisitor<R> {
  const ConstantValueVisitor();

  R visitFunction(FunctionConstantValue constant);
  R visitNull(NullConstantValue constant);
  R visitInt(IntConstantValue constant);
  R visitDouble(DoubleConstantValue constant);
  R visitTrue(TrueConstantValue constant);
  R visitFalse(FalseConstantValue constant);
  R visitString(StringConstantValue constant);
  R visitList(ListConstantValue constant);
  R visitMap(MapConstantValue constant);
  R visitConstructed(ConstructedConstantValue constant);
  R visitType(TypeConstantValue constant);
  R visitInterceptor(InterceptorConstantValue constant);
  R visitDummy(DummyConstantValue constant);
  R visitDeferred(DeferredConstantValue constant);
}

abstract class ConstantValue {
  const ConstantValue();

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
  DartType computeType(Compiler compiler);

  ti.TypeMask computeMask(Compiler compiler);

  List<ConstantValue> getDependencies();

  accept(ConstantValueVisitor visitor);

  /// The value of this constant in Dart syntax, if possible.
  ///
  /// For [ConstructedConstantValue]s there is no way to create a valid const
  /// expression from the value so the unparse of these is best effort.
  ///
  /// For the synthetic constants, [DeferredConstantValue],
  /// [DummyConstantValue], [InterceptorConstantValue] the unparse is
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
  Element element;

  FunctionConstantValue(this.element);

  bool get isFunction => true;

  bool operator ==(var other) {
    if (other is !FunctionConstantValue) return false;
    return identical(other.element, element);
  }

  List<ConstantValue> getDependencies() => const <ConstantValue>[];

  DartString toDartString() {
    return new DartString.literal(element.name);
  }

  // TODO(johnniwinther): remove computeType.
  DartType computeType(Compiler compiler) => element.computeType(compiler);

  ti.TypeMask computeMask(Compiler compiler) {
    return compiler.typesTask.functionType;
  }

  int get hashCode => (17 * element.hashCode) & 0x7fffffff;

  accept(ConstantValueVisitor visitor) => visitor.visitFunction(this);

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

  DartType computeType(Compiler compiler) {
    return compiler.nullClass.computeType(compiler);
  }

  ti.TypeMask computeMask(Compiler compiler) {
    return compiler.typesTask.nullType;
  }

  // The magic constant has no meaning. It is just a random value.
  int get hashCode => 785965825;

  DartString toDartString() => const LiteralDartString("null");

  accept(ConstantValueVisitor visitor) => visitor.visitNull(this);

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

  DartType computeType(Compiler compiler) {
    return compiler.intClass.rawType;
  }

  ti.TypeMask computeMask(Compiler compiler) {
    if (isUInt31()) return compiler.typesTask.uint31Type;
    if (isUInt32()) return compiler.typesTask.uint32Type;
    if (isPositive()) return compiler.typesTask.positiveIntType;
    return compiler.typesTask.intType;
  }

  // We have to override the equality operator so that ints and doubles are
  // treated as separate constants.
  // The is [:!IntConstant:] check at the beginning of the function makes sure
  // that we compare only equal to integer constants.
  bool operator ==(var other) {
    if (other is !IntConstantValue) return false;
    IntConstantValue otherInt = other;
    return primitiveValue == otherInt.primitiveValue;
  }

  int get hashCode => primitiveValue & SMI_MASK;

  DartString toDartString() {
    return new DartString.literal(primitiveValue.toString());
  }

  accept(ConstantValueVisitor visitor) => visitor.visitInt(this);

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

  DartType computeType(Compiler compiler) {
    return compiler.doubleClass.rawType;
  }

  ti.TypeMask computeMask(Compiler compiler) {
    // We have to distinguish -0.0 from 0, but for all practical purposes
    // -0.0 is an integer.
    // TODO(17235): this kind of special casing should only happen in the
    // backend.
    if (isMinusZero && compiler.backend.constantSystem.isInt(this)) {
      return compiler.typesTask.uint31Type;
    }
    assert(!compiler.backend.constantSystem.isInt(this));
    return compiler.typesTask.doubleType;
  }

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

  accept(ConstantValueVisitor visitor) => visitor.visitDouble(this);

  String toStructuredString() => 'DoubleConstant(${unparse()})';
}

abstract class BoolConstantValue extends PrimitiveConstantValue {
  factory BoolConstantValue(value) {
    return value ? new TrueConstantValue() : new FalseConstantValue();
  }

  const BoolConstantValue._internal();

  bool get isBool => true;

  DartType computeType(Compiler compiler) {
    return compiler.boolClass.rawType;
  }

  ti.TypeMask computeMask(Compiler compiler) {
    return compiler.typesTask.boolType;
  }

  BoolConstantValue negate();

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

  accept(ConstantValueVisitor visitor) => visitor.visitTrue(this);
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

  accept(ConstantValueVisitor visitor) => visitor.visitFalse(this);
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

  DartType computeType(Compiler compiler) {
    return compiler.stringClass.rawType;
  }

  ti.TypeMask computeMask(Compiler compiler) {
    return compiler.typesTask.stringType;
  }

  bool operator ==(var other) {
    if (other is !StringConstantValue) return false;
    StringConstantValue otherString = other;
    return hashCode == otherString.hashCode &&
           primitiveValue == otherString.primitiveValue;
  }

  DartString toDartString() => primitiveValue;

  int get length => primitiveValue.length;

  accept(ConstantValueVisitor visitor) => visitor.visitString(this);

  // TODO(johnniwinther): Ensure correct escaping.
  String unparse() => '"${primitiveValue.slowToString()}"';

  String toStructuredString() => 'StringConstant(${unparse()})';
}

abstract class ObjectConstantValue extends ConstantValue {
  final InterfaceType  type;

  ObjectConstantValue(this.type);

  bool get isObject => true;

  DartType computeType(Compiler compiler) => type;

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

  ti.TypeMask computeMask(Compiler compiler) {
    return compiler.typesTask.typeType;
  }

  int get hashCode => representedType.hashCode * 13;

  List<ConstantValue> getDependencies() => const <ConstantValue>[];

  accept(ConstantValueVisitor visitor) => visitor.visitType(this);

  String unparse() => '$representedType';

  String toStructuredString() => 'TypeConstant(${representedType})';
}

class ListConstantValue extends ObjectConstantValue {
  final List<ConstantValue> entries;
  final int hashCode;

  ListConstantValue(InterfaceType type, List<ConstantValue> entries)
      : this.entries = entries,
        hashCode = _computeHash(type, entries),
        super(type);

  bool get isList => true;

  static int _computeHash(DartType type, List<ConstantValue> entries) {
    // TODO(floitsch): create a better hash.
    int hash = 7;
    for (ConstantValue input in entries) {
      hash ^= input.hashCode;
    }
    hash ^= type.hashCode;
    return hash;
  }

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

  ti.TypeMask computeMask(Compiler compiler) {
    return compiler.typesTask.constListType;
  }

  accept(ConstantValueVisitor visitor) => visitor.visitList(this);

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
    sb.write('ListConstant([');
    for (int i = 0 ; i < length ; i++) {
      if (i > 0) sb.write(',');
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
        this.hashCode = computeHash(type, keys, values),
        super(type) {
    assert(keys.length == values.length);
  }

  bool get isMap => true;

  static int computeHash(DartType type,
                         List<ConstantValue> keys,
                         List<ConstantValue> values) {
    // TODO(floitsch): create a better hash.
    int hash = 0;
    for (ConstantValue key in keys) {
      hash ^= key.hashCode;
    }
    for (ConstantValue value in values) {
      hash ^= value.hashCode;
    }
    hash ^= type.hashCode;
    return hash;
  }

  ti.TypeMask computeMask(Compiler compiler) {
    return compiler.typesTask.constMapType;
  }

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

  accept(ConstantValueVisitor visitor) => visitor.visitMap(this);

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
    sb.write('MapConstant({');
    for (int i = 0; i < length; i++) {
      if (i > 0) sb.write(',');
      sb.write(keys[i].toStructuredString());
      sb.write(':');
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

  accept(ConstantValueVisitor visitor) => visitor.visitInterceptor(this);

  DartType computeType(Compiler compiler) => const DynamicType();

  ti.TypeMask computeMask(Compiler compiler) {
    return compiler.typesTask.nonNullType;
  }

  String unparse() {
    return 'interceptor($dispatchedType)';
  }

  String toStructuredString() {
    return 'InterceptorConstant(${dispatchedType.getStringAsDeclared("o")})';
  }
}

class DummyConstantValue extends ConstantValue {
  final ti.TypeMask typeMask;

  DummyConstantValue(this.typeMask);

  bool get isDummy => true;

  bool operator ==(other) {
    return other is DummyConstantValue
        && typeMask == other.typeMask;
  }

  get hashCode => typeMask.hashCode;

  List<ConstantValue> getDependencies() => const <ConstantValue>[];

  accept(ConstantValueVisitor visitor) => visitor.visitDummy(this);

  DartType computeType(Compiler compiler) => const DynamicType();

  ti.TypeMask computeMask(Compiler compiler) => typeMask;

  String unparse() => 'dummy($typeMask)';

  String toStructuredString() => 'DummyConstant($typeMask)';
}

class ConstructedConstantValue extends ObjectConstantValue {
  final List<ConstantValue> fields;
  final int hashCode;

  ConstructedConstantValue(InterfaceType type, List<ConstantValue> fields)
    : this.fields = fields,
      hashCode = computeHash(type, fields),
      super(type) {
    assert(type != null);
  }

  bool get isConstructedObject => true;

  static int computeHash(DartType type, List<ConstantValue> fields) {
    // TODO(floitsch): create a better hash.
    int hash = 0;
    for (ConstantValue field in fields) {
      hash ^= field.hashCode;
    }
    hash ^= type.hashCode;
    return hash;
  }

  bool operator ==(var otherVar) {
    if (otherVar is !ConstructedConstantValue) return false;
    ConstructedConstantValue other = otherVar;
    if (hashCode != other.hashCode) return false;
    if (type != other.type) return false;
    if (fields.length != other.fields.length) return false;
    for (int i = 0; i < fields.length; i++) {
      if (fields[i] != other.fields[i]) return false;
    }
    return true;
  }

  List<ConstantValue> getDependencies() => fields;

  ti.TypeMask computeMask(Compiler compiler) {
    if (compiler.backend.isInterceptorClass(type.element)) {
      return compiler.typesTask.nonNullType;
    }
    return new ti.TypeMask.nonNullExact(type.element, compiler.world);
  }

  accept(ConstantValueVisitor visitor) => visitor.visitConstructed(this);

  Map<Element, ConstantValue> get fieldElements {
    // TODO(ahe): Refactor constant system to store this information directly.
    ClassElement classElement = type.element;
    int count = 0;
    Map<Element, ConstantValue> result = new Map<Element, ConstantValue>();
    classElement.implementation.forEachInstanceField((holder, field) {
      result[field] = fields[count++];
    }, includeSuperAndInjectedMembers: true);
    return result;
  }

  String unparse() {
    StringBuffer sb = new StringBuffer();
    sb.write(type.name);
    _unparseTypeArguments(sb);
    sb.write('(');
    int i = 0;
    fieldElements.forEach((Element field, ConstantValue value) {
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
    fieldElements.forEach((Element field, ConstantValue value) {
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

  accept(ConstantValueVisitor visitor) => visitor.visitDeferred(this);

  DartType computeType(Compiler compiler) => referenced.computeType(compiler);

  ti.TypeMask computeMask(Compiler compiler) {
    return referenced.computeMask(compiler);
  }

  String unparse() => 'deferred(${referenced.unparse()})';

  String toStructuredString() => 'DeferredConstant($referenced)';
}
