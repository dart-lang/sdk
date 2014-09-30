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

abstract class ConstantVisitor<R> {
  const ConstantVisitor();

  R visitFunction(FunctionConstant constant);
  R visitNull(NullConstant constant);
  R visitInt(IntConstant constant);
  R visitDouble(DoubleConstant constant);
  R visitTrue(TrueConstant constant);
  R visitFalse(FalseConstant constant);
  R visitString(StringConstant constant);
  R visitList(ListConstant constant);
  R visitMap(MapConstant constant);
  R visitConstructed(ConstructedConstant constant);
  R visitType(TypeConstant constant);
  R visitInterceptor(InterceptorConstant constant);
  R visitDummy(DummyConstant constant);
  R visitDeferred(DeferredConstant constant);
}

// TODO(johnniwinther): Rename this to `ConstantValue`.
abstract class Constant {
  const Constant();

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

  List<Constant> getDependencies();

  accept(ConstantVisitor visitor);

  /// The value of this constant in Dart syntax, if possible.
  ///
  /// For [ConstructedConstant]s there is no way to create a valid const
  /// expression from the value so the unparse of these is best effort.
  ///
  /// For the synthetic constants, [DeferredConstant], [DummyConstant],
  /// [InterceptorConstant] the unparse is descriptive only.
  String unparse();

  /// Returns a structured representation of this constant suited for debugging.
  String toStructuredString();

  String toString() {
    assertDebugMode("Use Constant.unparse() or Constant.toStructuredString() "
                    "instead of Constant.toString().");
    return toStructuredString();
  }
}

class FunctionConstant extends Constant {
  Element element;

  FunctionConstant(this.element);

  bool get isFunction => true;

  bool operator ==(var other) {
    if (other is !FunctionConstant) return false;
    return identical(other.element, element);
  }

  List<Constant> getDependencies() => const <Constant>[];

  DartString toDartString() {
    return new DartString.literal(element.name);
  }

  // TODO(johnniwinther): remove computeType.
  DartType computeType(Compiler compiler) => element.computeType(compiler);

  ti.TypeMask computeMask(Compiler compiler) {
    return compiler.typesTask.functionType;
  }

  int get hashCode => (17 * element.hashCode) & 0x7fffffff;

  accept(ConstantVisitor visitor) => visitor.visitFunction(this);

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

abstract class PrimitiveConstant extends Constant {
  // TODO(johnniwinther): Rename to `primitiveValue`.
  get value;

  const PrimitiveConstant();

  bool get isPrimitive => true;

  bool operator ==(var other) {
    if (other is !PrimitiveConstant) return false;
    PrimitiveConstant otherPrimitive = other;
    // We use == instead of 'identical' so that DartStrings compare correctly.
    return value == otherPrimitive.value;
  }

  int get hashCode => throw new UnsupportedError('PrimitiveConstant.hashCode');

  // Primitive constants don't have dependencies.
  List<Constant> getDependencies() => const <Constant>[];

  DartString toDartString();

  /// This value in Dart syntax.
  String unparse() => value.toString();
}

class NullConstant extends PrimitiveConstant {
  /** The value a Dart null is compiled to in JavaScript. */
  static const String JsNull = "null";

  factory NullConstant() => const NullConstant._internal();

  const NullConstant._internal();

  bool get isNull => true;

  get value => null;

  DartType computeType(Compiler compiler) {
    return compiler.nullClass.computeType(compiler);
  }

  ti.TypeMask computeMask(Compiler compiler) {
    return compiler.typesTask.nullType;
  }

  // The magic constant has no meaning. It is just a random value.
  int get hashCode => 785965825;

  DartString toDartString() => const LiteralDartString("null");

  accept(ConstantVisitor visitor) => visitor.visitNull(this);

  String toStructuredString() => 'NullConstant';
}

abstract class NumConstant extends PrimitiveConstant {
  const NumConstant();

  num get value;

  bool get isNum => true;
}

class IntConstant extends NumConstant {
  final int value;

  factory IntConstant(int value) {
    switch (value) {
      case 0: return const IntConstant._internal(0);
      case 1: return const IntConstant._internal(1);
      case 2: return const IntConstant._internal(2);
      case 3: return const IntConstant._internal(3);
      case 4: return const IntConstant._internal(4);
      case 5: return const IntConstant._internal(5);
      case 6: return const IntConstant._internal(6);
      case 7: return const IntConstant._internal(7);
      case 8: return const IntConstant._internal(8);
      case 9: return const IntConstant._internal(9);
      case 10: return const IntConstant._internal(10);
      case -1: return const IntConstant._internal(-1);
      case -2: return const IntConstant._internal(-2);
      default: return new IntConstant._internal(value);
    }
  }

  const IntConstant._internal(this.value);

  bool get isInt => true;

  bool isUInt31() => value >= 0 && value < (1 << 31);

  bool isUInt32() => value >= 0 && value < (1 << 32);

  bool isPositive() => value >= 0;

  bool get isZero => value == 0;

  bool get isOne => value == 1;

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
    if (other is !IntConstant) return false;
    IntConstant otherInt = other;
    return value == otherInt.value;
  }

  int get hashCode => value & SMI_MASK;

  DartString toDartString() => new DartString.literal(value.toString());

  accept(ConstantVisitor visitor) => visitor.visitInt(this);

  String toStructuredString() => 'IntConstant(${unparse()})';
}

class DoubleConstant extends NumConstant {
  final double value;

  factory DoubleConstant(double value) {
    if (value.isNaN) {
      return const DoubleConstant._internal(double.NAN);
    } else if (value == double.INFINITY) {
      return const DoubleConstant._internal(double.INFINITY);
    } else if (value == -double.INFINITY) {
      return const DoubleConstant._internal(-double.INFINITY);
    } else if (value == 0.0 && !value.isNegative) {
      return const DoubleConstant._internal(0.0);
    } else if (value == 1.0) {
      return const DoubleConstant._internal(1.0);
    } else {
      return new DoubleConstant._internal(value);
    }
  }

  const DoubleConstant._internal(this.value);

  bool get isDouble => true;

  bool get isNaN => value.isNaN;

  // We need to check for the negative sign since -0.0 == 0.0.
  bool get isMinusZero => value == 0.0 && value.isNegative;

  bool get isZero => value == 0.0;

  bool get isOne => value == 1.0;

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
    if (other is !DoubleConstant) return false;
    DoubleConstant otherDouble = other;
    double otherValue = otherDouble.value;
    if (value == 0.0 && otherValue == 0.0) {
      return value.isNegative == otherValue.isNegative;
    } else if (value.isNaN) {
      return otherValue.isNaN;
    } else {
      return value == otherValue;
    }
  }

  int get hashCode => value.hashCode;

  DartString toDartString() => new DartString.literal(value.toString());

  accept(ConstantVisitor visitor) => visitor.visitDouble(this);

  String toStructuredString() => 'DoubleConstant(${unparse()})';
}

abstract class BoolConstant extends PrimitiveConstant {
  factory BoolConstant(value) {
    return value ? new TrueConstant() : new FalseConstant();
  }

  const BoolConstant._internal();

  bool get isBool => true;

  DartType computeType(Compiler compiler) {
    return compiler.boolClass.rawType;
  }

  ti.TypeMask computeMask(Compiler compiler) {
    return compiler.typesTask.boolType;
  }

  BoolConstant negate();

  String toStructuredString() => 'BoolConstant(${unparse()})';
}

class TrueConstant extends BoolConstant {
  factory TrueConstant() => const TrueConstant._internal();

  const TrueConstant._internal() : super._internal();

  bool get isTrue => true;

  bool get value => true;

  FalseConstant negate() => new FalseConstant();

  bool operator ==(var other) => identical(this, other);

  // The magic constant is just a random value. It does not have any
  // significance.
  int get hashCode => 499;

  DartString toDartString() => const LiteralDartString("true");

  accept(ConstantVisitor visitor) => visitor.visitTrue(this);
}

class FalseConstant extends BoolConstant {
  factory FalseConstant() => const FalseConstant._internal();

  const FalseConstant._internal() : super._internal();

  bool get isFalse => true;

  bool get value => false;

  TrueConstant negate() => new TrueConstant();

  bool operator ==(var other) => identical(this, other);

  // The magic constant is just a random value. It does not have any
  // significance.
  int get hashCode => 536555975;

  DartString toDartString() => const LiteralDartString("false");

  accept(ConstantVisitor visitor) => visitor.visitFalse(this);
}

class StringConstant extends PrimitiveConstant {
  final DartString value;

  final int hashCode;

  // TODO(floitsch): cache StringConstants.
  // TODO(floitsch): compute hashcode without calling toString() on the
  // DartString.
  StringConstant(DartString value)
      : this.value = value,
        this.hashCode = value.slowToString().hashCode;

  bool get isString => true;

  DartType computeType(Compiler compiler) {
    return compiler.stringClass.rawType;
  }

  ti.TypeMask computeMask(Compiler compiler) {
    return compiler.typesTask.stringType;
  }

  bool operator ==(var other) {
    if (other is !StringConstant) return false;
    StringConstant otherString = other;
    return (hashCode == otherString.hashCode) && (value == otherString.value);
  }

  DartString toDartString() => value;

  int get length => value.length;

  accept(ConstantVisitor visitor) => visitor.visitString(this);

  // TODO(johnniwinther): Ensure correct escaping.
  String unparse() => '"${value.slowToString()}"';

  String toStructuredString() => 'StringConstant(${unparse()})';
}

abstract class ObjectConstant extends Constant {
  final InterfaceType  type;

  ObjectConstant(this.type);

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

class TypeConstant extends ObjectConstant {
  /// The user type that this constant represents.
  final DartType representedType;

  TypeConstant(this.representedType, InterfaceType type) : super(type);

  bool get isType => true;

  bool operator ==(other) {
    return other is TypeConstant && representedType == other.representedType;
  }

  ti.TypeMask computeMask(Compiler compiler) {
    return compiler.typesTask.typeType;
  }

  int get hashCode => representedType.hashCode * 13;

  List<Constant> getDependencies() => const <Constant>[];

  accept(ConstantVisitor visitor) => visitor.visitType(this);

  String unparse() => '$representedType';

  String toStructuredString() => 'TypeConstant(${representedType})';
}

class ListConstant extends ObjectConstant {
  final List<Constant> entries;
  final int hashCode;

  ListConstant(InterfaceType type, List<Constant> entries)
      : this.entries = entries,
        hashCode = _computeHash(type, entries),
        super(type);

  bool get isList => true;

  static int _computeHash(DartType type, List<Constant> entries) {
    // TODO(floitsch): create a better hash.
    int hash = 7;
    for (Constant input in entries) {
      hash ^= input.hashCode;
    }
    hash ^= type.hashCode;
    return hash;
  }

  bool operator ==(var other) {
    if (other is !ListConstant) return false;
    ListConstant otherList = other;
    if (hashCode != otherList.hashCode) return false;
    if (type != otherList.type) return false;
    if (entries.length != otherList.entries.length) return false;
    for (int i = 0; i < entries.length; i++) {
      if (entries[i] != otherList.entries[i]) return false;
    }
    return true;
  }

  List<Constant> getDependencies() => entries;

  int get length => entries.length;

  ti.TypeMask computeMask(Compiler compiler) {
    return compiler.typesTask.constListType;
  }

  accept(ConstantVisitor visitor) => visitor.visitList(this);

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

class MapConstant extends ObjectConstant {
  final List<Constant> keys;
  final List<Constant> values;
  final int hashCode;

  MapConstant(InterfaceType type, List<Constant> keys, List<Constant> values)
      : this.keys = keys,
        this.values = values,
        this.hashCode = computeHash(type, keys, values),
        super(type) {
    assert(keys.length == values.length);
  }

  bool get isMap => true;

  static int computeHash(DartType type,
                         List<Constant> keys,
                         List<Constant> values) {
    // TODO(floitsch): create a better hash.
    int hash = 0;
    for (Constant key in keys) {
      hash ^= key.hashCode;
    }
    for (Constant value in values) {
      hash ^= value.hashCode;
    }
    hash ^= type.hashCode;
    return hash;
  }

  ti.TypeMask computeMask(Compiler compiler) {
    return compiler.typesTask.constMapType;
  }

  bool operator ==(var other) {
    if (other is !MapConstant) return false;
    MapConstant otherMap = other;
    if (hashCode != otherMap.hashCode) return false;
    if (type != other.type) return false;
    if (length != other.length) return false;
    for (int i = 0; i < length; i++) {
      if (keys[i] != otherMap.keys[i]) return false;
      if (values[i] != otherMap.values[i]) return false;
    }
    return true;
  }

  List<Constant> getDependencies() {
    List<Constant> result = <Constant>[];
    result.addAll(keys);
    result.addAll(values);
    return result;
  }

  int get length => keys.length;

  accept(ConstantVisitor visitor) => visitor.visitMap(this);

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

class InterceptorConstant extends Constant {
  /// The type for which this interceptor holds the methods.  The constant
  /// is a dispatch table for this type.
  final DartType dispatchedType;

  InterceptorConstant(this.dispatchedType);

  bool get isInterceptor => true;

  bool operator ==(other) {
    return other is InterceptorConstant
        && dispatchedType == other.dispatchedType;
  }

  int get hashCode => dispatchedType.hashCode * 43;

  List<Constant> getDependencies() => const <Constant>[];

  accept(ConstantVisitor visitor) => visitor.visitInterceptor(this);

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

class DummyConstant extends Constant {
  final ti.TypeMask typeMask;

  DummyConstant(this.typeMask);

  bool get isDummy => true;

  bool operator ==(other) {
    return other is DummyConstant
        && typeMask == other.typeMask;
  }

  get hashCode => typeMask.hashCode;

  List<Constant> getDependencies() => const <Constant>[];

  accept(ConstantVisitor visitor) => visitor.visitDummy(this);

  DartType computeType(Compiler compiler) => const DynamicType();

  ti.TypeMask computeMask(Compiler compiler) => typeMask;

  String unparse() => 'dummy($typeMask)';

  String toStructuredString() => 'DummyConstant($typeMask)';
}

class ConstructedConstant extends ObjectConstant {
  final List<Constant> fields;
  final int hashCode;

  ConstructedConstant(InterfaceType type, List<Constant> fields)
    : this.fields = fields,
      hashCode = computeHash(type, fields),
      super(type) {
    assert(type != null);
  }

  bool get isConstructedObject => true;

  static int computeHash(DartType type, List<Constant> fields) {
    // TODO(floitsch): create a better hash.
    int hash = 0;
    for (Constant field in fields) {
      hash ^= field.hashCode;
    }
    hash ^= type.hashCode;
    return hash;
  }

  bool operator ==(var otherVar) {
    if (otherVar is !ConstructedConstant) return false;
    ConstructedConstant other = otherVar;
    if (hashCode != other.hashCode) return false;
    if (type != other.type) return false;
    if (fields.length != other.fields.length) return false;
    for (int i = 0; i < fields.length; i++) {
      if (fields[i] != other.fields[i]) return false;
    }
    return true;
  }

  List<Constant> getDependencies() => fields;

  ti.TypeMask computeMask(Compiler compiler) {
    if (compiler.backend.isInterceptorClass(type.element)) {
      return compiler.typesTask.nonNullType;
    }
    return new ti.TypeMask.nonNullExact(type.element, compiler.world);
  }

  accept(ConstantVisitor visitor) => visitor.visitConstructed(this);

  Map<Element, Constant> get fieldElements {
    // TODO(ahe): Refactor constant system to store this information directly.
    ClassElement classElement = type.element;
    int count = 0;
    Map<Element, Constant> result = new Map<Element, Constant>();
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
    fieldElements.forEach((Element field, Constant value) {
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
    fieldElements.forEach((Element field, Constant value) {
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
class DeferredConstant extends Constant {
  DeferredConstant(this.referenced, this.prefix);

  final Constant referenced;
  final PrefixElement prefix;

  bool get isReference => true;

  bool operator ==(other) {
    return other is DeferredConstant
        && referenced == other.referenced
        && prefix == other.prefix;
  }

  get hashCode => (referenced.hashCode * 17 + prefix.hashCode) & 0x3fffffff;

  List<Constant> getDependencies() => <Constant>[referenced];

  accept(ConstantVisitor visitor) => visitor.visitDeferred(this);

  DartType computeType(Compiler compiler) => referenced.computeType(compiler);

  ti.TypeMask computeMask(Compiler compiler) {
    return referenced.computeMask(compiler);
  }

  String unparse() => 'deferred(${referenced.unparse()})';

  String toStructuredString() => 'DeferredConstant($referenced)';
}
