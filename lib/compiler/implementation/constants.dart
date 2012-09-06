// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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

  abstract void _writeJsCode(CodeBuffer buffer, ConstantHandler handler);
  /**
    * Unless the constant can be emitted multiple times (as for numbers and
    * strings) adds its canonical name to the buffer.
    */
  abstract void _writeCanonicalizedJsCode(CodeBuffer buffer,
                                          ConstantHandler handler);
  abstract List<Constant> getDependencies();
}

class SentinelConstant extends Constant {
  const SentinelConstant();
  static final SENTINEL = const SentinelConstant();

  void _writeJsCode(CodeBuffer buffer, ConstantHandler handler) {
    handler.compiler.internalError(
        "The parameter sentinel constant does not need specific JS code");
  }

  void _writeCanonicalizedJsCode(CodeBuffer buffer, ConstantHandler handler) {
    buffer.add(handler.compiler.namer.CURRENT_ISOLATE);
  }

  List<Constant> getDependencies() => const <Constant>[];

  // Just use a randome value.
  int hashCode() => 926429784158;

  bool isSentinel() => true;
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

  void _writeJsCode(CodeBuffer buffer, ConstantHandler handler) {
    handler.compiler.internalError(
        "A constant function does not need specific JS code");
  }

  void _writeCanonicalizedJsCode(CodeBuffer buffer, ConstantHandler handler) {
    buffer.add(handler.compiler.namer.isolatePropertiesAccess(element));
  }

  int hashCode() => (17 * element.hashCode()) & 0x7fffffff;
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

  void _writeCanonicalizedJsCode(CodeBuffer buffer, ConstantHandler handler) {
    _writeJsCode(buffer, handler);
  }
}

class NullConstant extends PrimitiveConstant {
  /** The value a Dart null is compiled to in JavaScript. */
  static const String JsNull = "null";

  factory NullConstant() => const NullConstant._internal();
  const NullConstant._internal();
  bool isNull() => true;
  get value => null;

  void _writeJsCode(CodeBuffer buffer, ConstantHandler handler) {
    buffer.add(JsNull);
  }

  // The magic constant has no meaning. It is just a random value.
  int hashCode() => 785965825;
  DartString toDartString() => const LiteralDartString("null");
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

  void _writeJsCode(CodeBuffer buffer, ConstantHandler handler) {
    buffer.add("$value");
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

  void _writeJsCode(CodeBuffer buffer, ConstantHandler handler) {
    if (value.isNaN()) {
      buffer.add("(0/0)");
    } else if (value == double.INFINITY) {
      buffer.add("(1/0)");
    } else if (value == -double.INFINITY) {
      buffer.add("(-1/0)");
    } else {
      buffer.add("$value");
    }
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
}

class BoolConstant extends PrimitiveConstant {
  factory BoolConstant(value) {
    return value ? new TrueConstant() : new FalseConstant();
  }
  const BoolConstant._internal();
  bool isBool() => true;

  abstract BoolConstant negate();
}

class TrueConstant extends BoolConstant {
  final bool value = true;

  factory TrueConstant() => const TrueConstant._internal();
  const TrueConstant._internal() : super._internal();
  bool isTrue() => true;

  void _writeJsCode(CodeBuffer buffer, ConstantHandler handler) {
    buffer.add("true");
  }

  FalseConstant negate() => new FalseConstant();

  bool operator ==(var other) => this === other;
  // The magic constant is just a random value. It does not have any
  // significance.
  int hashCode() => 499;
  DartString toDartString() => const LiteralDartString("true");
}

class FalseConstant extends BoolConstant {
  final bool value = false;

  factory FalseConstant() => const FalseConstant._internal();
  const FalseConstant._internal() : super._internal();
  bool isFalse() => true;

  void _writeJsCode(CodeBuffer buffer, ConstantHandler handler) {
    buffer.add("false");
  }

  TrueConstant negate() => new TrueConstant();

  bool operator ==(var other) => this === other;
  // The magic constant is just a random value. It does not have any
  // significance.
  int hashCode() => 536555975;
  DartString toDartString() => const LiteralDartString("false");
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

  void _writeJsCode(CodeBuffer buffer, ConstantHandler handler) {
    buffer.add("'");
    ConstantHandler.writeEscapedString(value, buffer, (reason) {
      handler.compiler.reportError(node, reason);
    });
    buffer.add("'");
  }

  bool operator ==(var other) {
    if (other is !StringConstant) return false;
    StringConstant otherString = other;
    return (_hashCode == otherString._hashCode) && (value == otherString.value);
  }

  int hashCode() => _hashCode;
  DartString toDartString() => value;
  int get length => value.length;
}

class ObjectConstant extends Constant {
  final DartType type;

  ObjectConstant(this.type);
  bool isObject() => true;

  // TODO(1603): The class should be marked as abstract, but the VM doesn't
  // currently allow this.
  abstract int hashCode();

  void _writeCanonicalizedJsCode(CodeBuffer buffer, ConstantHandler handler) {
    String name = handler.getNameForConstant(this);
    buffer.add(handler.compiler.namer.isolatePropertiesAccessForConstant(name));
  }
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

  void _writeJsCode(CodeBuffer buffer, ConstantHandler handler) {
    // TODO(floitsch): we should not need to go through the compiler to make
    // the list constant.
    buffer.add("${handler.compiler.namer.ISOLATE}.makeConstantList");
    buffer.add("([");
    for (int i = 0; i < entries.length; i++) {
      if (i != 0) buffer.add(", ");
      Constant entry = entries[i];
      handler.writeConstant(buffer, entry);
    }
    buffer.add("])");
  }

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
}

class MapConstant extends ObjectConstant {
  /**
   * The [PROTO_PROPERTY] must not be used as normal property in any JavaScript
   * object. It would change the prototype chain.
   */
  static const String PROTO_PROPERTY = "__proto__";

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

  void _writeJsCode(CodeBuffer buffer, ConstantHandler handler) {

    void writeJsMap() {
      buffer.add("{");
      int valueIndex = 0;
      for (int i = 0; i < keys.entries.length; i++) {
        StringConstant key = keys.entries[i];
        if (key.value == const LiteralDartString(PROTO_PROPERTY)) continue;

        if (valueIndex != 0) buffer.add(", ");

        key._writeJsCode(buffer, handler);
        buffer.add(": ");
        Constant value = values[valueIndex++];
        handler.writeConstant(buffer, value);
      }
      buffer.add("}");
      if (valueIndex != values.length) {
        handler.compiler.internalError("Bad value count.");
      }
    }

    void badFieldCountError() {
      handler.compiler.internalError(
          "Compiler and ConstantMap disagree on number of fields.");
    }

    ClassElement classElement = type.element;
    buffer.add("new ");
    buffer.add(handler.getJsConstructor(classElement));
    buffer.add("(");
    // The arguments of the JavaScript constructor for any given Dart class
    // are in the same order as the members of the class element.
    int emittedArgumentCount = 0;
    classElement.forEachInstanceField(
        includeBackendMembers: true,
        includeSuperMembers: true,
        f: (ClassElement enclosing, Element field) {
      if (emittedArgumentCount != 0) buffer.add(", ");
      if (field.name == LENGTH_NAME) {
        buffer.add(keys.entries.length);
      } else if (field.name == JS_OBJECT_NAME) {
        writeJsMap();
      } else if (field.name == KEYS_NAME) {
        handler.writeConstant(buffer, keys);
      } else if (field.name == PROTO_VALUE) {
        assert(protoValue !== null);
        handler.writeConstant(buffer, protoValue);
      } else {
        badFieldCountError();
      }
      emittedArgumentCount++;
    });
    if ((protoValue === null && emittedArgumentCount != 3) ||
        (protoValue !== null && emittedArgumentCount != 4)) {
      badFieldCountError();
    }
    buffer.add(")");
  }

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

  void _writeJsCode(CodeBuffer buffer, ConstantHandler handler) {
    buffer.add("new ");
    buffer.add(handler.getJsConstructor(type.element));
    buffer.add("(");
    for (int i = 0; i < fields.length; i++) {
      if (i != 0) buffer.add(", ");
      Constant field = fields[i];
      handler.writeConstant(buffer, field);
    }
    buffer.add(")");
  }

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
}
