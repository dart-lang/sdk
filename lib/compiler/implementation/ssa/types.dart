// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class HType {
  const HType();

  factory HType.fromType(Type type, Compiler compiler) {
    Element element = type.element;
    if (element.kind === ElementKind.TYPE_VARIABLE) {
      compiler.unimplemented("type variables");
    }

    if (element === compiler.intClass) {
      return HType.INTEGER;
    } else if (element === compiler.numClass) {
      return HType.NUMBER;
    } else if (element === compiler.doubleClass) {
      return HType.DOUBLE;
    } else if (element === compiler.stringClass) {
      return HType.STRING;
    } else {
      // TODO(ngeoffray): Introduce a new HType class for representing
      // this type.
      return null;
    }
  }

  static final HType CONFLICTING = const HAnalysisType("conflicting");
  static final HType UNKNOWN = const HAnalysisType("unknown");
  static final HType BOOLEAN = const HBooleanType();
  static final HType NUMBER = const HNumberType();
  static final HType INTEGER = const HIntegerType();
  static final HType DOUBLE = const HDoubleType();
  static final HType INDEXABLE_PRIMITIVE = const HIndexablePrimitiveType();
  static final HType STRING = const HStringType();
  static final HType READABLE_ARRAY = const HReadableArrayType();
  static final HType MUTABLE_ARRAY = const HMutableArrayType();
  static final HType EXTENDABLE_ARRAY = const HExtendableArrayType();

  bool isConflicting() => this === CONFLICTING;
  bool isUnknown() => this === UNKNOWN;
  bool isBoolean() => false;
  bool isNumber() => false;
  bool isInteger() => false;
  bool isDouble() => false;
  bool isString() => false;
  bool isIndexablePrimitive() => false;
  bool isReadableArray() => false;
  bool isMutableArray() => false;
  bool isExtendableArray() => false;
  bool isPrimitive() => false;
  bool isNonPrimitive() => false;

  /** A type is useful it is not unknown and not conflicting. */
  bool isUseful() => !isUnknown() && !isConflicting();
  /** Alias for isReadableArray. */
  bool isArray() => isReadableArray();

  /**
   * The intersection of two types is the intersection of its values. For
   * example:
   *   * INTEGER.intersect(NUMBER) => INTEGER.
   *   * DOUBLE.intersect(INTEGER) => CONFLICTING.
   *   * MUTABLE_ARRAY.intersect(READABLE_ARRAY) => MUTABLE_ARRAY.
   *
   * When there is no predefined type to represent the intersection returns
   * [CONFLICTING].
   *
   * An intersection with [UNKNOWN] returns the non-UNKNOWN type. An
   * intersection with [CONFLICTING] returns [CONFLICTING].
   */
  abstract HType intersection(HType other);

  /**
   * The union of two types is the union of its values. For example:
   *   * INTEGER.union(NUMBER) => NUMBER.
   *   * DOUBLE.union(INTEGER) => NUMBER.
   *   * MUTABLE_ARRAY.union(READABLE_ARRAY) => READABLE_ARRAY.
   *
   * When there is no predefined type to represent the union returns
   * [CONFLICTING].
   *
   * A union with [UNKNOWN] returns the non-UNKNOWN type. A union with
   * [CONFLICTING] returns [CONFLICTING].
   */
  abstract HType union(HType other);
}

/** Used to represent [HType.UNKNOWN] and [HType.CONFLICTING]. */
class HAnalysisType extends HType {
  final String name;
  const HAnalysisType(this.name);
  String toString() => name;

  HType combine(HType other) {
    if (isUnknown()) return other;
    if (other.isUnknown()) return this;
    return HType.CONFLICTING;
  }

  HType union(HType other) => combine(other);
  HType intersection(HType other) => combine(other);
}

abstract class HPrimitiveType extends HType {
  const HPrimitiveType();
  bool isPrimitive() => true;
}

class HBooleanType extends HPrimitiveType {
  const HBooleanType();
  bool isBoolean() => true;
  String toString() => "boolean";

  HType combine(HType other) {
    if (other.isBoolean() || other.isUnknown()) return HType.BOOLEAN;
    return HType.CONFLICTING;
  }

  // Since the boolean type is a one-element set the union and intersection are
  // the same.
  HType union(HType other) => combine(other);
  HType intersection(HType other) => combine(other);
}

class HNumberType extends HPrimitiveType {
  const HNumberType();
  bool isNumber() => true;
  String toString() => "number";

  HType union(HType other) {
    if (other.isNumber() || other.isUnknown()) return HType.NUMBER;
    return HType.CONFLICTING;
  }

  HType intersection(HType other) {
    if (other.isUnknown()) return HType.NUMBER;
    if (other.isNumber()) return other;
    return HType.CONFLICTING;
  }
}

class HIntegerType extends HNumberType {
  const HIntegerType();
  bool isInteger() => true;
  String toString() => "integer";

  HType union(HType other) {
    if (other.isInteger() || other.isUnknown()) return HType.INTEGER;
    if (other.isNumber()) return HType.NUMBER;
    return HType.CONFLICTING;
  }

  HType intersection(HType other) {
    if (other.isUnknown()) return HType.INTEGER;
    if (other.isDouble()) return HType.CONFLICTING;
    if (other.isNumber()) return this;
    return HType.CONFLICTING;
  }
}

class HDoubleType extends HNumberType {
  const HDoubleType();
  bool isDouble() => true;
  String toString() => "double";

  HType union(HType other) {
    if (other.isDouble() || other.isUnknown()) return HType.DOUBLE;
    if (other.isNumber()) return HType.NUMBER;
    return HType.CONFLICTING;
  }

  HType intersection(HType other) {
    if (other.isUnknown()) return HType.DOUBLE;
    if (other.isInteger()) return HType.CONFLICTING;
    if (other.isNumber()) return this;
    return HType.CONFLICTING;
  }
}

class HIndexablePrimitiveType extends HPrimitiveType {
  const HIndexablePrimitiveType();
  bool isIndexablePrimitive() => true;
  String toString() => "indexable";

  HType union(HType other) {
    if (other.isIndexablePrimitive() || other.isUnknown()) {
      return HType.INDEXABLE_PRIMITIVE;
    }
    return HType.CONFLICTING;
  }

  HType intersection(HType other) {
    if (other.isUnknown()) return HType.INDEXABLE_PRIMITIVE;
    if (other.isIndexablePrimitive()) return other;
    return HType.CONFLICTING;
  }
}

class HStringType extends HIndexablePrimitiveType {
  const HStringType();
  bool isString() => true;
  String toString() => "String";

  HType union(HType other) {
    if (other.isString() || other.isUnknown()) return HType.STRING;
    if (other.isIndexablePrimitive()) return HType.INDEXABLE_PRIMITIVE;
    return HType.CONFLICTING;
  }

  HType intersection(HType other) {
    if (other.isString() || other.isUnknown()) return HType.STRING;
    if (other.isArray()) return HType.CONFLICTING;
    if (other.isIndexablePrimitive()) return HType.STRING;
    return HType.CONFLICTING;
  }
}

class HReadableArrayType extends HIndexablePrimitiveType {
  const HReadableArrayType();
  bool isReadableArray() => true;
  String toString() => "readable array";

  HType union(HType other) {
    if (other.isReadableArray() || other.isUnknown()) {
      return HType.READABLE_ARRAY;
    }
    if (other.isIndexablePrimitive()) return HType.INDEXABLE_PRIMITIVE;
    return HType.CONFLICTING;
  }

  HType intersection(HType other) {
    if (this === other || other.isUnknown()) return HType.READABLE_ARRAY;
    if (other.isString()) return HType.CONFLICTING;
    if (other.isReadableArray()) return other;
    if (other.isIndexablePrimitive()) return this;
    return HType.CONFLICTING;
  }
}

class HMutableArrayType extends HReadableArrayType {
  const HMutableArrayType();
  bool isMutableArray() => true;
  String toString() => "mutable array";

  HType union(HType other) {
    if (other.isMutableArray() || other.isUnknown()) {
      return HType.MUTABLE_ARRAY;
    }
    if (other.isReadableArray()) return HType.READABLE_ARRAY;
    if (other.isIndexablePrimitive()) return HType.INDEXABLE_PRIMITIVE;
    return HType.CONFLICTING;
  }

  HType intersection(HType other) {
    if (this === other || other.isUnknown()) return HType.MUTABLE_ARRAY;
    if (other.isString()) return HType.CONFLICTING;
    if (other.isMutableArray()) return other;
    if (other.isIndexablePrimitive()) return HType.MUTABLE_ARRAY;
    return HType.CONFLICTING;
  }
}

class HExtendableArrayType extends HMutableArrayType {
  const HExtendableArrayType();
  bool isExtendableArray() => true;
  String toString() => "extendable array";

  HType union(HType other) {
    if (other.isExtendableArray() || other.isUnknown()) {
      return HType.EXTENDABLE_ARRAY;
    }
    if (other.isMutableArray()) return HType.MUTABLE_ARRAY;
    if (other.isReadableArray()) return HType.READABLE_ARRAY;
    if (other.isIndexablePrimitive()) return HType.INDEXABLE_PRIMITIVE;
    return HType.CONFLICTING;
  }

  HType intersection(HType other) {
    if (this === other || other.isUnknown()) return HType.EXTENDABLE_ARRAY;
    if (other.isString()) return HType.CONFLICTING;
    if (other.isIndexablePrimitive()) return HType.EXTENDABLE_ARRAY;
    return HType.CONFLICTING;
  }
}

class HNonPrimitiveType extends HType {
  final Type type;

  const HNonPrimitiveType(Type this.type);
  bool isNonPrimitive() => true;
  String toString() => type.toString();

  HType combine(HType other) {
    if (other.isNonPrimitive()) {
      HNonPrimitiveType temp = other;
      if (this.type === temp.type) return this;
    }
    if (other.isUnknown()) return this;
    return HType.CONFLICTING;
  }

  // As long as we don't keep track of super/sub types for non-primitive types
  // the intersection and union is the same.
  HType intersection(HType other) => combine(other);
  HType union(HType other) => combine(other);

  Element lookupMember(SourceString name) {
    ClassElement classElement = type.element;
    return classElement.lookupMember(name);
  }
}
