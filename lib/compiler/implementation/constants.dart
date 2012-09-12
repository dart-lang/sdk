// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class ConstantVisitor<R> {
  R visitSentinel(SentinelConstant constant);
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
}

class Constant implements Hashable {
  const Constant();

  bool isNull() => false;
  bool isBool() => false;
  bool isTrue() => false;
  bool isFalse() => false;
  bool isInt() => false;
  bool isDouble() => false;
  bool isNum() => false;
  bool isString() => false;
  bool isList() => false;
  bool isMap() => false;
  bool isConstructedObject() => false;
  bool isFunction() => false;
  /** Returns true if the constant is null, a bool, a number or a string. */
  bool isPrimitive() => false;
  /** Returns true if the constant is a list, a map or a constructed object. */
  bool isObject() => false;
  bool isSentinel() => false;

  bool isNaN() => false;
  bool isMinusZero() => false;

  abstract DartType computeType(Compiler compiler);

  abstract List<Constant> getDependencies();

  abstract accept(ConstantVisitor);
}

class SentinelConstant extends Constant {
  const SentinelConstant();
  static final SENTINEL = const SentinelConstant();

  List<Constant> getDependencies() => const <Constant>[];

  // Just use a random value.
  int hashCode() => 24297418;

  bool isSentinel() => true;

  accept(ConstantVisitor visitor) => visitor.visitSentinel(this);
}

class FunctionConstant extends Constant {
  Element element;

  FunctionConstant(this.element);

  bool isFunction() => true;

  bool operator ==(var other) {
    if (other is !FunctionConstant) return false;
    return other.element === element;
  }

  String toString() => element.toString();
  List<Constant> getDependencies() => const <Constant>[];
  DartString toDartString() {
    return new DartString.literal(element.name.slowToString());
  }

  DartType computeType(Compiler compiler) {
    return compiler.functionClass.computeType(compiler);
  }

  int hashCode() => (17 * element.hashCode()) & 0x7fffffff;

  accept(ConstantVisitor visitor) => visitor.visitFunction(this);
}

class PrimitiveConstant extends Constant {
  abstract get value;
  const PrimitiveConstant();
  bool isPrimitive() => true;

  bool operator ==(var other) {
    if (other is !PrimitiveConstant) return false;
    PrimitiveConstant otherPrimitive = other;
    // We use == instead of === so that DartStrings compare correctly.
    return value == otherPrimitive.value;
  }

  String toString() => value.toString();
  // Primitive constants don't have dependencies.
  List<Constant> getDependencies() => const <Constant>[];
  abstract DartString toDartString();
}

class NullConstant extends PrimitiveConstant {
  /** The value a Dart null is compiled to in JavaScript. */
  static const String JsNull = "null";

  factory NullConstant() => const NullConstant._internal();
  const NullConstant._internal();
  bool isNull() => true;
  get value => null;

  DartType computeType(Compiler compiler) {
    return compiler.nullClass.computeType(compiler);
  }

  void _writeJsCode(CodeBuffer buffer, ConstantHandler handler) {
    buffer.add(JsNull);
  }

  // The magic constant has no meaning. It is just a random value.
  int hashCode() => 785965825;
  DartString toDartString() => const LiteralDartString("null");

  accept(ConstantVisitor visitor) => visitor.visitNull(this);
}

class NumConstant extends PrimitiveConstant {
  abstract num get value;
  const NumConstant();
  bool isNum() => true;
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
  bool isInt() => true;

  DartType computeType(Compiler compiler) {
    return compiler.intClass.computeType(compiler);
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

  int hashCode() => value.hashCode();
  DartString toDartString() => new DartString.literal(value.toString());

  accept(ConstantVisitor visitor) => visitor.visitInt(this);
}

class DoubleConstant extends NumConstant {
  final double value;
  factory DoubleConstant(double value) {
    if (value.isNaN()) {
      return const DoubleConstant._internal(double.NAN);
    } else if (value == double.INFINITY) {
      return const DoubleConstant._internal(double.INFINITY);
    } else if (value == -double.INFINITY) {
      return const DoubleConstant._internal(-double.INFINITY);
    } else if (value == 0.0 && !value.isNegative()) {
      return const DoubleConstant._internal(0.0);
    } else if (value == 1.0) {
      return const DoubleConstant._internal(1.0);
    } else {
      return new DoubleConstant._internal(value);
    }
  }
  const DoubleConstant._internal(this.value);
  bool isDouble() => true;
  bool isNaN() => value.isNaN();
  // We need to check for the negative sign since -0.0 == 0.0.
  bool isMinusZero() => value == 0.0 && value.isNegative();

  DartType computeType(Compiler compiler) {
    return compiler.doubleClass.computeType(compiler);
  }

  bool operator ==(var other) {
    if (other is !DoubleConstant) return false;
    DoubleConstant otherDouble = other;
    double otherValue = otherDouble.value;
    if (value == 0.0 && otherValue == 0.0) {
      return value.isNegative() == otherValue.isNegative();
    } else if (value.isNaN()) {
      return otherValue.isNaN();
    } else {
      return value == otherValue;
    }
  }

  int hashCode() => value.hashCode();
  DartString toDartString() => new DartString.literal(value.toString());

  accept(ConstantVisitor visitor) => visitor.visitDouble(this);
}

class BoolConstant extends PrimitiveConstant {
  factory BoolConstant(value) {
    return value ? new TrueConstant() : new FalseConstant();
  }
  const BoolConstant._internal();
  bool isBool() => true;

  DartType computeType(Compiler compiler) {
    return compiler.boolClass.computeType(compiler);
  }

  abstract BoolConstant negate();
}

class TrueConstant extends BoolConstant {
  final bool value = true;

  factory TrueConstant() => const TrueConstant._internal();
  const TrueConstant._internal() : super._internal();
  bool isTrue() => true;

  FalseConstant negate() => new FalseConstant();

  bool operator ==(var other) => this === other;
  // The magic constant is just a random value. It does not have any
  // significance.
  int hashCode() => 499;
  DartString toDartString() => const LiteralDartString("true");

  accept(ConstantVisitor visitor) => visitor.visitTrue(this);
}

class FalseConstant extends BoolConstant {
  final bool value = false;

  factory FalseConstant() => const FalseConstant._internal();
  const FalseConstant._internal() : super._internal();
  bool isFalse() => true;

  TrueConstant negate() => new TrueConstant();

  bool operator ==(var other) => this === other;
  // The magic constant is just a random value. It does not have any
  // significance.
  int hashCode() => 536555975;
  DartString toDartString() => const LiteralDartString("false");

  accept(ConstantVisitor visitor) => visitor.visitFalse(this);
}

class StringConstant extends PrimitiveConstant {
  final DartString value;
  int _hashCode;
  final Node node;

  StringConstant(this.value, this.node) {
    // TODO(floitsch): cache StringConstants.
    // TODO(floitsch): compute hashcode without calling toString() on the
    // DartString.
    _hashCode = value.slowToString().hashCode();
  }
  bool isString() => true;

  DartType computeType(Compiler compiler) {
    return compiler.stringClass.computeType(compiler);
  }

  bool operator ==(var other) {
    if (other is !StringConstant) return false;
    StringConstant otherString = other;
    return (_hashCode == otherString._hashCode) && (value == otherString.value);
  }

  int hashCode() => _hashCode;
  DartString toDartString() => value;
  int get length => value.length;

  accept(ConstantVisitor visitor) => visitor.visitString(this);
}

class ObjectConstant extends Constant {
  final DartType type;

  ObjectConstant(this.type);
  bool isObject() => true;

  DartType computeType(Compiler compiler) => type;

  // TODO(1603): The class should be marked as abstract, but the VM doesn't
  // currently allow this.
  abstract int hashCode();
}

class ListConstant extends ObjectConstant {
  final List<Constant> entries;
  int _hashCode;

  ListConstant(DartType type, this.entries) : super(type) {
    // TODO(floitsch): create a better hash.
    int hash = 0;
    for (Constant input in entries) hash ^= input.hashCode();
    _hashCode = hash;
  }
  bool isList() => true;

  bool operator ==(var other) {
    if (other is !ListConstant) return false;
    ListConstant otherList = other;
    if (hashCode() != otherList.hashCode()) return false;
    // TODO(floitsch): verify that the generic types are the same.
    if (entries.length != otherList.entries.length) return false;
    for (int i = 0; i < entries.length; i++) {
      if (entries[i] != otherList.entries[i]) return false;
    }
    return true;
  }

  int hashCode() => _hashCode;

  List<Constant> getDependencies() => entries;

  int get length => entries.length;

  accept(ConstantVisitor visitor) => visitor.visitList(this);
}

class MapConstant extends ObjectConstant {
  /**
   * The [PROTO_PROPERTY] must not be used as normal property in any JavaScript
   * object. It would change the prototype chain.
   */
  static const LiteralDartString PROTO_PROPERTY =
      const LiteralDartString("__proto__");

  /** The dart class implementing constant map literals. */
  static const SourceString DART_CLASS = const SourceString("ConstantMap");
  static const SourceString DART_PROTO_CLASS =
      const SourceString("ConstantProtoMap");
  static const SourceString LENGTH_NAME = const SourceString("length");
  static const SourceString JS_OBJECT_NAME = const SourceString("_jsObject");
  static const SourceString KEYS_NAME = const SourceString("_keys");
  static const SourceString PROTO_VALUE = const SourceString("_protoValue");

  final ListConstant keys;
  final List<Constant> values;
  final Constant protoValue;
  int _hashCode;

  MapConstant(DartType type, this.keys, this.values, this.protoValue)
      : super(type) {
    // TODO(floitsch): create a better hash.
    int hash = 0;
    for (Constant value in values) hash ^= value.hashCode();
    _hashCode = hash;
  }
  bool isMap() => true;

  bool operator ==(var other) {
    if (other is !MapConstant) return false;
    MapConstant otherMap = other;
    if (hashCode() != otherMap.hashCode()) return false;
    // TODO(floitsch): verify that the generic types are the same.
    if (keys != otherMap.keys) return false;
    for (int i = 0; i < values.length; i++) {
      if (values[i] != otherMap.values[i]) return false;
    }
    return true;
  }

  int hashCode() => _hashCode;

  List<Constant> getDependencies() {
    List<Constant> result = <Constant>[keys];
    result.addAll(values);
    return result;
  }

  int get length => keys.length;

  accept(ConstantVisitor visitor) => visitor.visitMap(this);
}

class ConstructedConstant extends ObjectConstant {
  final List<Constant> fields;
  int _hashCode;

  ConstructedConstant(DartType type, this.fields) : super(type) {
    assert(type !== null);
    // TODO(floitsch): create a better hash.
    int hash = 0;
    for (Constant field in fields) {
      hash ^= field.hashCode();
    }
    hash ^= type.element.hashCode();
    _hashCode = hash;
  }
  bool isConstructedObject() => true;

  bool operator ==(var otherVar) {
    if (otherVar is !ConstructedConstant) return false;
    ConstructedConstant other = otherVar;
    if (hashCode() != other.hashCode()) return false;
    // TODO(floitsch): verify that the (generic) types are the same.
    if (type.element != other.type.element) return false;
    if (fields.length != other.fields.length) return false;
    for (int i = 0; i < fields.length; i++) {
      if (fields[i] != other.fields[i]) return false;
    }
    return true;
  }

  int hashCode() => _hashCode;
  List<Constant> getDependencies() => fields;

  accept(ConstantVisitor visitor) => visitor.visitConstructed(this);
}
