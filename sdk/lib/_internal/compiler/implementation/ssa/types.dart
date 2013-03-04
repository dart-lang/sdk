// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of ssa;

abstract class HType {
  const HType();

  /**
   * Returns an [HType] with the given type mask. The factory method
   * takes care to track whether or not the resulting type may be a
   * primitive type.
   */
  factory HType.fromMask(TypeMask mask, Compiler compiler) {
    Element element = mask.base.element;
    if (element.kind == ElementKind.TYPE_VARIABLE) {
      // TODO(ngeoffray): Can we do better here?
      DartType base = compiler.objectClass.computeType(compiler);
      mask = new TypeMask.internal(base, mask.flags);
      return new HBoundedType(mask);
    }

    bool isNullable = mask.isNullable;
    JavaScriptBackend backend = compiler.backend;
    if (element == compiler.intClass || element == backend.jsIntClass) {
      return isNullable ? HType.INTEGER_OR_NULL : HType.INTEGER;
    } else if (element == compiler.numClass
               || element == backend.jsNumberClass) {
      return isNullable ? HType.NUMBER_OR_NULL : HType.NUMBER;
    } else if (element == compiler.doubleClass
               || element == backend.jsDoubleClass) {
      return isNullable ? HType.DOUBLE_OR_NULL : HType.DOUBLE;
    } else if (element == compiler.stringClass
               || element == backend.jsStringClass) {
      return isNullable ? HType.STRING_OR_NULL : HType.STRING;
    } else if (element == compiler.boolClass
               || element == backend.jsBoolClass) {
      return isNullable ? HType.BOOLEAN_OR_NULL : HType.BOOLEAN;
    } else if (element == compiler.nullClass
               || element == backend.jsNullClass) {
      return HType.NULL;
    } else if (element == backend.jsArrayClass) {
      return isNullable
          ? HType.READABLE_ARRAY.union(HType.NULL, compiler)
          : HType.READABLE_ARRAY;
    }
    return new HBoundedType(mask);
  }

  factory HType.nonNullExactClass(DartType type, Compiler compiler) {
    TypeMask mask = new TypeMask.nonNullExact(type);
    return new HType.fromMask(mask, compiler);
  }

  factory HType.nonNullSubclass(DartType type, Compiler compiler) {
    TypeMask mask = new TypeMask.nonNullSubclass(type);
    return new HType.fromMask(mask, compiler);
  }

  factory HType.subtype(DartType type, Compiler compiler) {
    TypeMask mask = new TypeMask.subtype(type);
    return new HType.fromMask(mask, compiler);
  }

  factory HType.nonNullSubtype(DartType type, Compiler compiler) {
    TypeMask mask = new TypeMask.nonNullSubtype(type);
    return new HType.fromMask(mask, compiler);
  }

  factory HType.fromBaseType(BaseType baseType, Compiler compiler) {
    if (!baseType.isClass()) return HType.UNKNOWN;
    ClassBaseType classBaseType = baseType;
    ClassElement cls = classBaseType.element;
    // Special case the list and map classes that are used as types
    // for literals in the type inferrer.
    if (cls == compiler.listClass) {
      return HType.READABLE_ARRAY;
    } else if (cls == compiler.mapClass) {
      // TODO(ngeoffray): get the actual implementation of a map
      // literal.
      return new HType.nonNullSubtype(
          compiler.mapLiteralClass.computeType(compiler), compiler);
    } else {
      return new HType.nonNullExactClass(
          cls.computeType(compiler), compiler);
    }
  }

  factory HType.fromInferredType(ConcreteType concreteType, Compiler compiler) {
    if (concreteType == null) return HType.UNKNOWN;
    HType ssaType = HType.CONFLICTING;
    for (BaseType baseType in concreteType.baseTypes) {
      ssaType = ssaType.union(
          new HType.fromBaseType(baseType, compiler), compiler);
    }
    if (ssaType.isConflicting()) return HType.UNKNOWN;
    return ssaType;
  }

  factory HType.inferredForElement(Element element, Compiler compiler) {
    return new HType.fromInferredType(
        compiler.typesTask.getGuaranteedTypeOfElement(element),
        compiler);
  }

  factory HType.inferredForNode(
      Element owner, Node node, Compiler compiler) {
    return new HType.fromInferredType(
        compiler.typesTask.getGuaranteedTypeOfNode(owner, node),
        compiler);
  }

  // [type] is either an instance of [DartType] or special objects
  // like [native.SpecialType.JsObject], or [native.SpecialType.JsArray].
  factory HType.fromNativeType(type, Compiler compiler) {
    if (type == native.SpecialType.JsObject) {
      return new HType.nonNullExactClass(
          compiler.objectClass.computeType(compiler), compiler);
    } else if (type == native.SpecialType.JsArray) {
      return HType.READABLE_ARRAY;
    } else {
      return new HType.nonNullSubclass(type, compiler);
    }
  }

  factory HType.fromNativeBehavior(native.NativeBehavior nativeBehavior,
                                   Compiler compiler) {
    if (nativeBehavior.typesInstantiated.isEmpty) return HType.UNKNOWN;

    HType ssaType = HType.CONFLICTING;
    for (final type in nativeBehavior.typesInstantiated) {
      ssaType = ssaType.union(
          new HType.fromNativeType(type, compiler), compiler);
    }
    assert(!ssaType.isConflicting());
    return ssaType;
  }

  factory HType.readableArrayOrNull(Compiler compiler) {
    return new HBoundedType(
        READABLE_ARRAY.computeMask(compiler).nullable());
  }

  factory HType.mutableArrayOrNull(Compiler compiler) {
    return new HBoundedType(
        MUTABLE_ARRAY.computeMask(compiler).nullable());
  }

  factory HType.fixedArrayOrNull(Compiler compiler) {
    return new HBoundedType(
        FIXED_ARRAY.computeMask(compiler).nullable());
  }

  factory HType.extendableArrayOrNull(Compiler compiler) {
    return new HBoundedType(
        EXTENDABLE_ARRAY.computeMask(compiler).nullable());
  }

  static const HType CONFLICTING = const HConflictingType();
  static const HType UNKNOWN = const HUnknownType();
  static const HType BOOLEAN = const HBooleanType();
  static const HType NUMBER = const HNumberType();
  static const HType INTEGER = const HIntegerType();
  static const HType DOUBLE = const HDoubleType();
  static const HType INDEXABLE_PRIMITIVE = const HIndexablePrimitiveType();
  static const HType STRING = const HStringType();
  static const HType READABLE_ARRAY = const HReadableArrayType();
  static const HType MUTABLE_ARRAY = const HMutableArrayType();
  static const HType FIXED_ARRAY = const HFixedArrayType();
  static const HType EXTENDABLE_ARRAY = const HExtendableArrayType();
  static const HType NULL = const HNullType();

  static const HType BOOLEAN_OR_NULL = const HBooleanOrNullType();
  static const HType NUMBER_OR_NULL = const HNumberOrNullType();
  static const HType INTEGER_OR_NULL = const HIntegerOrNullType();
  static const HType DOUBLE_OR_NULL = const HDoubleOrNullType();
  static const HType STRING_OR_NULL = const HStringOrNullType();

  bool isConflicting() => identical(this, CONFLICTING);
  bool isUnknown() => identical(this, UNKNOWN);
  bool isExact() => false;
  bool isNull() => false;
  bool isBoolean() => false;
  bool isNumber() => false;
  bool isInteger() => false;
  bool isDouble() => false;
  bool isString() => false;
  bool isIndexablePrimitive() => false;
  bool isFixedArray() => false;
  bool isReadableArray() => false;
  bool isMutableArray() => false;
  bool isExtendableArray() => false;
  bool isPrimitive() => false;

  bool isBooleanOrNull() => false;
  bool isNumberOrNull() => false;
  bool isIntegerOrNull() => false;
  bool isDoubleOrNull() => false;
  bool isStringOrNull() => false;
  bool isPrimitiveOrNull() => false;

  bool canBeNull() => false;
  bool canBePrimitive(Compiler compiler) => false;
  bool canBePrimitiveNumber(Compiler compiler) => false;
  bool canBePrimitiveString(Compiler compiler) => false;
  bool canBePrimitiveArray(Compiler compiler) => false;

  /** A type is useful it is not unknown, not conflicting, and not null. */
  bool isUseful() => !isUnknown() && !isConflicting() && !isNull();
  /** Alias for isReadableArray. */
  bool isArray() => isReadableArray();

  TypeMask computeMask(Compiler compiler);

  Selector refine(Selector selector, Compiler compiler) {
    TypeMask mask = computeMask(compiler);
    // TODO(kasperl): Should we check if the refinement really is more
    // specialized than the starting point?
    if (mask == null || mask.base.isMalformed) return selector;
    return new TypedSelector(mask, selector);
  }

  // TODO(kasperl): Try to get rid of these.
  DartType computeType(Compiler compiler);
  bool isTop(Compiler compiler) => false;

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
  HType intersection(HType other, Compiler compiler);

  /**
   * The union of two types is the union of its values. For example:
   *   * INTEGER.union(NUMBER) => NUMBER.
   *   * DOUBLE.union(INTEGER) => NUMBER.
   *   * MUTABLE_ARRAY.union(READABLE_ARRAY) => READABLE_ARRAY.
   *
   * When there is no predefined type to represent the union returns
   * [UNKNOWN].
   *
   * A union with [UNKNOWN] returns [UNKNOWN].
   * A union of [CONFLICTING] with any other types returns the other type.
   */
  HType union(HType other, Compiler compiler);
}

/** Used to represent [HType.UNKNOWN] and [HType.CONFLICTING]. */
abstract class HAnalysisType extends HType {
  final String name;
  const HAnalysisType(this.name);
  String toString() => name;

  DartType computeType(Compiler compiler) => null;
  TypeMask computeMask(Compiler compiler) => null;
}

class HUnknownType extends HAnalysisType {
  const HUnknownType() : super("unknown");
  bool canBePrimitive(Compiler compiler) => true;
  bool canBeNull() => true;

  HType union(HType other, Compiler compiler) => this;
  HType intersection(HType other, Compiler compiler) => other;
}

class HConflictingType extends HAnalysisType {
  const HConflictingType() : super("conflicting");
  bool canBePrimitive(Compiler compiler) => true;
  bool canBeNull() => true;

  HType union(HType other, Compiler compiler) => other;
  HType intersection(HType other, Compiler compiler) => this;
}

abstract class HPrimitiveType extends HType {
  const HPrimitiveType();
  bool isPrimitive() => true;
  bool canBePrimitive(Compiler compiler) => true;
  bool isPrimitiveOrNull() => true;
  bool isExact() => true;
}

class HNullType extends HPrimitiveType {
  const HNullType();
  bool canBeNull() => true;
  bool isNull() => true;
  String toString() => 'null type';

  DartType computeType(Compiler compiler) {
    JavaScriptBackend backend = compiler.backend;
    return backend.jsNullClass.computeType(compiler);
  }

  TypeMask computeMask(Compiler compiler) {
    return new TypeMask.exact(computeType(compiler));
  }

  HType union(HType other, Compiler compiler) {
    if (other.isConflicting()) return HType.NULL;
    if (other.isUnknown()) return HType.UNKNOWN;
    if (other.isString()) return HType.STRING_OR_NULL;
    if (other.isInteger()) return HType.INTEGER_OR_NULL;
    if (other.isDouble()) return HType.DOUBLE_OR_NULL;
    if (other.isNumber()) return HType.NUMBER_OR_NULL;
    if (other.isBoolean()) return HType.BOOLEAN_OR_NULL;
    // TODO(ngeoffray): Deal with the type of null more generally.
    if (other.isReadableArray()) return other.union(this, compiler);
    if (!other.canBeNull()) return HType.UNKNOWN;
    return other;
  }

  HType intersection(HType other, Compiler compiler) {
    if (other.isUnknown()) return HType.NULL;
    if (other.isConflicting()) return HType.CONFLICTING;
    if (!other.canBeNull()) return HType.CONFLICTING;
    return HType.NULL;
  }
}

abstract class HPrimitiveOrNullType extends HType {
  const HPrimitiveOrNullType();
  bool canBePrimitive(Compiler compiler) => true;
  bool canBeNull() => true;
  bool isPrimitiveOrNull() => true;
}

class HBooleanOrNullType extends HPrimitiveOrNullType {
  const HBooleanOrNullType();
  String toString() => "boolean or null";
  bool isBooleanOrNull() => true;

  DartType computeType(Compiler compiler) {
    JavaScriptBackend backend = compiler.backend;
    return backend.jsBoolClass.computeType(compiler);
  }

  TypeMask computeMask(Compiler compiler) {
    return new TypeMask.exact(computeType(compiler));
  }

  HType union(HType other, Compiler compiler) {
    if (other.isConflicting()) return HType.BOOLEAN_OR_NULL;
    if (other.isUnknown()) return HType.UNKNOWN;
    if (other.isBooleanOrNull()) return HType.BOOLEAN_OR_NULL;
    if (other.isBoolean()) return HType.BOOLEAN_OR_NULL;
    if (other.isNull()) return HType.BOOLEAN_OR_NULL;
    return HType.UNKNOWN;
  }

  HType intersection(HType other, Compiler compiler) {
    if (other.isConflicting()) return HType.CONFLICTING;
    if (other.isUnknown()) return HType.BOOLEAN_OR_NULL;
    if (other.isBoolean()) return HType.BOOLEAN;
    if (other.isBooleanOrNull()) return HType.BOOLEAN_OR_NULL;
    if (other.isTop(compiler)) {
      return other.canBeNull() ? this : HType.BOOLEAN;
    }
    if (other.canBeNull()) return HType.NULL;
    return HType.CONFLICTING;
  }
}

class HBooleanType extends HPrimitiveType {
  const HBooleanType();
  bool isBoolean() => true;
  bool isBooleanOrNull() => true;
  String toString() => "boolean";

  DartType computeType(Compiler compiler) {
    JavaScriptBackend backend = compiler.backend;
    return backend.jsBoolClass.computeType(compiler);
  }

  TypeMask computeMask(Compiler compiler) {
    return new TypeMask.nonNullExact(computeType(compiler));
  }

  HType union(HType other, Compiler compiler) {
    if (other.isConflicting()) return HType.BOOLEAN;
    if (other.isUnknown()) return HType.UNKNOWN;
    if (other.isBoolean()) return HType.BOOLEAN;
    if (other.isBooleanOrNull()) return HType.BOOLEAN_OR_NULL;
    if (other.isNull()) return HType.BOOLEAN_OR_NULL;
    return HType.UNKNOWN;
  }

  HType intersection(HType other, Compiler compiler) {
    if (other.isConflicting()) return HType.CONFLICTING;
    if (other.isUnknown()) return HType.BOOLEAN;
    if (other.isBooleanOrNull()) return HType.BOOLEAN;
    if (other.isBoolean()) return HType.BOOLEAN;
    return HType.CONFLICTING;
  }
}

class HNumberOrNullType extends HPrimitiveOrNullType {
  const HNumberOrNullType();
  bool isNumberOrNull() => true;
  String toString() => "number or null";
  bool isExact() => false;

  DartType computeType(Compiler compiler) {
    JavaScriptBackend backend = compiler.backend;
    return backend.jsNumberClass.computeType(compiler);
  }

  TypeMask computeMask(Compiler compiler) {
    return new TypeMask.subclass(computeType(compiler));
  }

  HType union(HType other, Compiler compiler) {
    if (other.isConflicting()) return HType.NUMBER_OR_NULL;
    if (other.isUnknown()) return HType.UNKNOWN;
    if (other.isNumberOrNull()) return HType.NUMBER_OR_NULL;
    if (other.isNumber()) return HType.NUMBER_OR_NULL;
    if (other.isNull()) return HType.NUMBER_OR_NULL;
    return HType.UNKNOWN;
  }

  HType intersection(HType other, Compiler compiler) {
    if (other.isConflicting()) return HType.CONFLICTING;
    if (other.isUnknown()) return HType.NUMBER_OR_NULL;
    if (other.isInteger()) return HType.INTEGER;
    if (other.isDouble()) return HType.DOUBLE;
    if (other.isNumber()) return HType.NUMBER;
    if (other.isIntegerOrNull()) return HType.INTEGER_OR_NULL;
    if (other.isDoubleOrNull()) return HType.DOUBLE_OR_NULL;
    if (other.isNumberOrNull()) return HType.NUMBER_OR_NULL;
    if (other.isTop(compiler)) {
      return other.canBeNull() ? this : HType.NUMBER;
    }
    if (other.canBeNull()) return HType.NULL;
    return HType.CONFLICTING;
  }
}

class HNumberType extends HPrimitiveType {
  const HNumberType();
  bool isNumber() => true;
  bool isNumberOrNull() => true;
  String toString() => "number";
  bool isExact() => false;

  DartType computeType(Compiler compiler) {
    JavaScriptBackend backend = compiler.backend;
    return backend.jsNumberClass.computeType(compiler);
  }

  TypeMask computeMask(Compiler compiler) {
    return new TypeMask.nonNullSubclass(computeType(compiler));
  }

  HType union(HType other, Compiler compiler) {
    if (other.isConflicting()) return HType.NUMBER;
    if (other.isUnknown()) return HType.UNKNOWN;
    if (other.isNumber()) return HType.NUMBER;
    if (other.isNumberOrNull()) return HType.NUMBER_OR_NULL;
    if (other.isNull()) return HType.NUMBER_OR_NULL;
    return HType.UNKNOWN;
  }

  HType intersection(HType other, Compiler compiler) {
    if (other.isConflicting()) return HType.CONFLICTING;
    if (other.isUnknown()) return HType.NUMBER;
    if (other.isNumber()) return other;
    if (other.isIntegerOrNull()) return HType.INTEGER;
    if (other.isDoubleOrNull()) return HType.DOUBLE;
    if (other.isNumberOrNull()) return HType.NUMBER;
    return HType.CONFLICTING;
  }
}

class HIntegerOrNullType extends HNumberOrNullType {
  const HIntegerOrNullType();
  bool isIntegerOrNull() => true;
  String toString() => "integer or null";

  DartType computeType(Compiler compiler) {
    JavaScriptBackend backend = compiler.backend;
    return backend.jsIntClass.computeType(compiler);
  }

  TypeMask computeMask(Compiler compiler) {
    return new TypeMask.exact(computeType(compiler));
  }

  HType union(HType other, Compiler compiler) {
    if (other.isConflicting()) return HType.INTEGER_OR_NULL;
    if (other.isUnknown()) return HType.UNKNOWN;
    if (other.isIntegerOrNull()) return HType.INTEGER_OR_NULL;
    if (other.isInteger()) return HType.INTEGER_OR_NULL;
    if (other.isNumber()) return HType.NUMBER_OR_NULL;
    if (other.isNumberOrNull()) return HType.NUMBER_OR_NULL;
    if (other.isNull()) return HType.INTEGER_OR_NULL;
    return HType.UNKNOWN;
  }

  HType intersection(HType other, Compiler compiler) {
    if (other.isConflicting()) return HType.CONFLICTING;
    if (other.isUnknown()) return HType.INTEGER_OR_NULL;
    if (other.isInteger()) return HType.INTEGER;
    if (other.isIntegerOrNull()) return HType.INTEGER_OR_NULL;
    if (other.isDouble()) return HType.CONFLICTING;
    if (other.isDoubleOrNull()) return HType.NULL;
    if (other.isNumber()) return HType.INTEGER;
    if (other.isNumberOrNull()) return HType.INTEGER_OR_NULL;
    if (other.isTop(compiler)) {
      return other.canBeNull() ? this : HType.INTEGER;
    }
    if (other.canBeNull()) return HType.NULL;
    return HType.CONFLICTING;
  }
}

class HIntegerType extends HNumberType {
  const HIntegerType();
  bool isInteger() => true;
  bool isIntegerOrNull() => true;
  String toString() => "integer";

  DartType computeType(Compiler compiler) {
    JavaScriptBackend backend = compiler.backend;
    return backend.jsIntClass.computeType(compiler);
  }

  TypeMask computeMask(Compiler compiler) {
    return new TypeMask.nonNullExact(computeType(compiler));
  }

  HType union(HType other, Compiler compiler) {
    if (other.isConflicting()) return HType.INTEGER;
    if (other.isUnknown()) return HType.UNKNOWN;
    if (other.isInteger()) return HType.INTEGER;
    if (other.isIntegerOrNull()) return HType.INTEGER_OR_NULL;
    if (other.isNumber()) return HType.NUMBER;
    if (other.isNumberOrNull()) return HType.NUMBER_OR_NULL;
    if (other.isNull()) return HType.INTEGER_OR_NULL;
    return HType.UNKNOWN;
  }

  HType intersection(HType other, Compiler compiler) {
    if (other.isConflicting()) return HType.CONFLICTING;
    if (other.isUnknown()) return HType.INTEGER;
    if (other.isIntegerOrNull()) return HType.INTEGER;
    if (other.isInteger()) return HType.INTEGER;
    if (other.isDouble()) return HType.CONFLICTING;
    if (other.isDoubleOrNull()) return HType.CONFLICTING;
    if (other.isNumber()) return HType.INTEGER;
    if (other.isNumberOrNull()) return HType.INTEGER;
    return HType.CONFLICTING;
  }
}

class HDoubleOrNullType extends HNumberOrNullType {
  const HDoubleOrNullType();
  bool isDoubleOrNull() => true;
  String toString() => "double or null";

  DartType computeType(Compiler compiler) {
    JavaScriptBackend backend = compiler.backend;
    return backend.jsDoubleClass.computeType(compiler);
  }

  TypeMask computeMask(Compiler compiler) {
    return new TypeMask.exact(computeType(compiler));
  }

  HType union(HType other, Compiler compiler) {
    if (other.isConflicting()) return HType.DOUBLE_OR_NULL;
    if (other.isUnknown()) return HType.UNKNOWN;
    if (other.isDoubleOrNull()) return HType.DOUBLE_OR_NULL;
    if (other.isDouble()) return HType.DOUBLE_OR_NULL;
    if (other.isNumber()) return HType.NUMBER_OR_NULL;
    if (other.isNumberOrNull()) return HType.NUMBER_OR_NULL;
    if (other.isNull()) return HType.DOUBLE_OR_NULL;
    return HType.UNKNOWN;
  }

  HType intersection(HType other, Compiler compiler) {
    if (other.isConflicting()) return HType.CONFLICTING;
    if (other.isUnknown()) return HType.DOUBLE_OR_NULL;
    if (other.isInteger()) return HType.CONFLICTING;
    if (other.isIntegerOrNull()) return HType.NULL;
    if (other.isDouble()) return HType.DOUBLE;
    if (other.isDoubleOrNull()) return HType.DOUBLE_OR_NULL;
    if (other.isNumber()) return HType.DOUBLE;
    if (other.isNumberOrNull()) return HType.DOUBLE_OR_NULL;
    if (other.isTop(compiler)) {
      return other.canBeNull() ? this : HType.DOUBLE;
    }
    if (other.canBeNull()) return HType.NULL;
    return HType.CONFLICTING;
  }
}

class HDoubleType extends HNumberType {
  const HDoubleType();
  bool isDouble() => true;
  bool isDoubleOrNull() => true;
  String toString() => "double";

  DartType computeType(Compiler compiler) {
    JavaScriptBackend backend = compiler.backend;
    return backend.jsDoubleClass.computeType(compiler);
  }

  TypeMask computeMask(Compiler compiler) {
    return new TypeMask.nonNullExact(computeType(compiler));
  }

  HType union(HType other, Compiler compiler) {
    if (other.isConflicting()) return HType.DOUBLE;
    if (other.isUnknown()) return HType.UNKNOWN;
    if (other.isDouble()) return HType.DOUBLE;
    if (other.isDoubleOrNull()) return HType.DOUBLE_OR_NULL;
    if (other.isNumber()) return HType.NUMBER;
    if (other.isNumberOrNull()) return HType.NUMBER_OR_NULL;
    if (other.isNull()) return HType.DOUBLE_OR_NULL;
    return HType.UNKNOWN;
  }

  HType intersection(HType other, Compiler compiler) {
    if (other.isConflicting()) return HType.CONFLICTING;
    if (other.isUnknown()) return HType.DOUBLE;
    if (other.isIntegerOrNull()) return HType.CONFLICTING;
    if (other.isInteger()) return HType.CONFLICTING;
    if (other.isDouble()) return HType.DOUBLE;
    if (other.isDoubleOrNull()) return HType.DOUBLE;
    if (other.isNumber()) return HType.DOUBLE;
    if (other.isNumberOrNull()) return HType.DOUBLE;
    return HType.CONFLICTING;
  }
}

class HIndexablePrimitiveType extends HPrimitiveType {
  const HIndexablePrimitiveType();
  bool isIndexablePrimitive() => true;
  String toString() => "indexable";

  DartType computeType(Compiler compiler) {
    // TODO(ngeoffray): Represent union types.
    return null;
  }

  TypeMask computeMask(Compiler compiler) {
    // TODO(ngeoffray): Represent union types.
    return null;
  }

  HType union(HType other, Compiler compiler) {
    if (other.isConflicting()) return HType.INDEXABLE_PRIMITIVE;
    if (other.isUnknown()) return HType.UNKNOWN;
    if (other.isIndexablePrimitive()) return HType.INDEXABLE_PRIMITIVE;
    if (other.canBePrimitiveString(compiler)) {
      // TODO(ngeoffray): Represent union types.
      return HType.UNKNOWN;
    }
    if (other.canBePrimitiveArray(compiler)) {
      // TODO(ngeoffray): Represent union types.
      return HType.UNKNOWN;
    }
    return HType.UNKNOWN;
  }

  HType intersection(HType other, Compiler compiler) {
    if (other.isConflicting()) return HType.CONFLICTING;
    if (other.isUnknown()) return HType.INDEXABLE_PRIMITIVE;
    if (other.isIndexablePrimitive()) return other;
    if (other.canBePrimitiveString(compiler)) return HType.STRING;
    if (other.canBePrimitiveArray(compiler)) return HType.READABLE_ARRAY;
    return HType.CONFLICTING;
  }
}

class HStringOrNullType extends HPrimitiveOrNullType {
  const HStringOrNullType();
  bool isStringOrNull() => true;
  String toString() => "String or null";

  DartType computeType(Compiler compiler) {
    JavaScriptBackend backend = compiler.backend;
    return backend.jsStringClass.computeType(compiler);
  }

  TypeMask computeMask(Compiler compiler) {
    return new TypeMask.exact(computeType(compiler));
  }

  HType union(HType other, Compiler compiler) {
    if (other.isConflicting()) return HType.STRING_OR_NULL;
    if (other.isUnknown()) return HType.UNKNOWN;
    if (other.isString()) return HType.STRING_OR_NULL;
    if (other.isStringOrNull()) return HType.STRING_OR_NULL;
    if (other.isIndexablePrimitive()) {
      // We don't have a type that represents the nullable indexable
      // primitive.
      return HType.UNKNOWN;
    }
    if (other.canBePrimitiveString(compiler)) {
      if (other.canBeNull()) {
        return other;
      } else {
        HBoundedType boundedType = other;
        return new HBoundedType(boundedType.mask.nullable());
      }
    }
    if (other.isNull()) return HType.STRING_OR_NULL;
    return HType.UNKNOWN;
  }

  HType intersection(HType other, Compiler compiler) {
    if (other.isConflicting()) return HType.CONFLICTING;
    if (other.isUnknown()) return HType.STRING_OR_NULL;
    if (other.isString()) return HType.STRING;
    if (other.isStringOrNull()) return HType.STRING_OR_NULL;
    if (other.isArray()) return HType.CONFLICTING;
    if (other.isIndexablePrimitive()) return HType.STRING;
    if (other.canBePrimitiveString(compiler)) {
      return other.canBeNull() ? HType.STRING_OR_NULL : HType.STRING;
    }
    if (other.isTop(compiler)) {
      return other.canBeNull() ? this : HType.STRING;
    }
    if (other.canBeNull()) return HType.NULL;
    return HType.CONFLICTING;
  }
}

class HStringType extends HIndexablePrimitiveType {
  const HStringType();
  bool isString() => true;
  bool isStringOrNull() => true;
  String toString() => "String";

  DartType computeType(Compiler compiler) {
    JavaScriptBackend backend = compiler.backend;
    return backend.jsStringClass.computeType(compiler);
  }

  TypeMask computeMask(Compiler compiler) {
    return new TypeMask.nonNullExact(computeType(compiler));
  }

  HType union(HType other, Compiler compiler) {
    if (other.isConflicting()) return HType.STRING;
    if (other.isUnknown()) return HType.UNKNOWN;
    if (other.isString()) return HType.STRING;
    if (other.isStringOrNull()) return HType.STRING_OR_NULL;
    if (other.isIndexablePrimitive()) return HType.INDEXABLE_PRIMITIVE;
    if (other.canBePrimitiveString(compiler)) return other;
    if (other.isNull()) return HType.STRING_OR_NULL;
    return HType.UNKNOWN;
  }

  HType intersection(HType other, Compiler compiler) {
    if (other.isConflicting()) return HType.CONFLICTING;
    if (other.isUnknown()) return HType.STRING;
    if (other.isString()) return HType.STRING;
    if (other.isArray()) return HType.CONFLICTING;
    if (other.isIndexablePrimitive()) return HType.STRING;
    if (other.isStringOrNull()) return HType.STRING;
    if (other.canBePrimitiveString(compiler)) return HType.STRING;
    return HType.CONFLICTING;
  }
}

class HReadableArrayType extends HIndexablePrimitiveType {
  const HReadableArrayType();
  bool isReadableArray() => true;
  String toString() => "readable array";

  DartType computeType(Compiler compiler) {
    JavaScriptBackend backend = compiler.backend;
    return backend.jsArrayClass.rawType;
  }

  TypeMask computeMask(Compiler compiler) {
    return new TypeMask.nonNullExact(computeType(compiler));
  }

  HType union(HType other, Compiler compiler) {
    if (other.isConflicting()) return HType.READABLE_ARRAY;
    if (other.isUnknown()) return HType.UNKNOWN;
    if (other.isReadableArray()) return HType.READABLE_ARRAY;
    if (other.isIndexablePrimitive()) return HType.INDEXABLE_PRIMITIVE;
    if (other.canBePrimitiveArray(compiler)) return other;
    if (other.isNull()) return new HType.readableArrayOrNull(compiler);
    return HType.UNKNOWN;
  }

  HType intersection(HType other, Compiler compiler) {
    if (other.isConflicting()) return HType.CONFLICTING;
    if (other.isUnknown()) return HType.READABLE_ARRAY;
    if (other.isString()) return HType.CONFLICTING;
    if (other.isReadableArray()) return other;
    if (other.isIndexablePrimitive()) return HType.READABLE_ARRAY;
    if (other.canBePrimitiveArray(compiler)) return HType.READABLE_ARRAY;
    return HType.CONFLICTING;
  }
}

class HMutableArrayType extends HReadableArrayType {
  const HMutableArrayType();
  bool isMutableArray() => true;
  String toString() => "mutable array";

  HType union(HType other, Compiler compiler) {
    if (other.isConflicting()) return HType.MUTABLE_ARRAY;
    if (other.isUnknown()) return HType.UNKNOWN;
    if (other.isMutableArray()) return HType.MUTABLE_ARRAY;
    if (other.isReadableArray()) return HType.READABLE_ARRAY;
    if (other.isIndexablePrimitive()) return HType.INDEXABLE_PRIMITIVE;
    if (other.canBePrimitiveArray(compiler)) return other;
    if (other.isNull()) return new HType.mutableArrayOrNull(compiler);
    return HType.UNKNOWN;
  }

  HType intersection(HType other, Compiler compiler) {
    if (other.isConflicting()) return HType.CONFLICTING;
    if (other.isUnknown()) return HType.MUTABLE_ARRAY;
    if (other.isMutableArray()) return other;
    if (other.isString()) return HType.CONFLICTING;
    if (other.isIndexablePrimitive()) return HType.MUTABLE_ARRAY;
    if (other.canBePrimitiveArray(compiler)) return HType.MUTABLE_ARRAY;
    return HType.CONFLICTING;
  }
}

class HFixedArrayType extends HMutableArrayType {
  const HFixedArrayType();
  bool isFixedArray() => true;
  String toString() => "fixed array";

  HType union(HType other, Compiler compiler) {
    if (other.isConflicting()) return HType.FIXED_ARRAY;
    if (other.isUnknown()) return HType.UNKNOWN;
    if (other.isFixedArray()) return HType.FIXED_ARRAY;
    if (other.isMutableArray()) return HType.MUTABLE_ARRAY;
    if (other.isReadableArray()) return HType.READABLE_ARRAY;
    if (other.isIndexablePrimitive()) return HType.INDEXABLE_PRIMITIVE;
    if (other.canBePrimitiveArray(compiler)) return other;
    if (other.isNull()) return new HType.fixedArrayOrNull(compiler);
    return HType.UNKNOWN;
  }

  HType intersection(HType other, Compiler compiler) {
    if (other.isConflicting()) return HType.CONFLICTING;
    if (other.isUnknown()) return HType.FIXED_ARRAY;
    if (other.isFixedArray()) return HType.FIXED_ARRAY;
    if (other.isExtendableArray()) return HType.CONFLICTING;
    if (other.isString()) return HType.CONFLICTING;
    if (other.isIndexablePrimitive()) return HType.FIXED_ARRAY;
    if (other.canBePrimitiveArray(compiler)) return HType.FIXED_ARRAY;
    return HType.CONFLICTING;
  }
}

class HExtendableArrayType extends HMutableArrayType {
  const HExtendableArrayType();
  bool isExtendableArray() => true;
  String toString() => "extendable array";

  HType union(HType other, Compiler compiler) {
    if (other.isConflicting()) return HType.EXTENDABLE_ARRAY;
    if (other.isUnknown()) return HType.UNKNOWN;
    if (other.isExtendableArray()) return HType.EXTENDABLE_ARRAY;
    if (other.isMutableArray()) return HType.MUTABLE_ARRAY;
    if (other.isReadableArray()) return HType.READABLE_ARRAY;
    if (other.isIndexablePrimitive()) return HType.INDEXABLE_PRIMITIVE;
    if (other.canBePrimitiveArray(compiler)) return other;
    if (other.isNull()) return new HType.extendableArrayOrNull(compiler);
    return HType.UNKNOWN;
  }

  HType intersection(HType other, Compiler compiler) {
    if (other.isConflicting()) return HType.CONFLICTING;
    if (other.isUnknown()) return HType.EXTENDABLE_ARRAY;
    if (other.isExtendableArray()) return HType.EXTENDABLE_ARRAY;
    if (other.isString()) return HType.CONFLICTING;
    if (other.isFixedArray()) return HType.CONFLICTING;
    if (other.isIndexablePrimitive()) return HType.EXTENDABLE_ARRAY;
    if (other.canBePrimitiveArray(compiler)) return HType.EXTENDABLE_ARRAY;
    return HType.CONFLICTING;
  }
}

class HBoundedType extends HType {
  final TypeMask mask;
  const HBoundedType(this.mask);

  bool isExact() => mask.isExact;
  bool isTop(Compiler compiler) => mask.containsAll(compiler);

  bool canBeNull() => mask.isNullable;

  bool canBePrimitive(Compiler compiler) {
    return canBePrimitiveNumber(compiler)
        || canBePrimitiveArray(compiler)
        || canBePrimitiveString(compiler);
  }

  bool canBePrimitiveNumber(Compiler compiler) {
    JavaScriptBackend backend = compiler.backend;
    DartType jsNumberType = backend.jsNumberClass.computeType(compiler);
    return mask.contains(jsNumberType, compiler);
  }

  bool canBePrimitiveArray(Compiler compiler) {
    JavaScriptBackend backend = compiler.backend;
    DartType jsArrayType = backend.jsArrayClass.computeType(compiler);
    return mask.contains(jsArrayType, compiler);
  }

  bool canBePrimitiveString(Compiler compiler) {
    JavaScriptBackend backend = compiler.backend;
    DartType jsStringType = backend.jsStringClass.computeType(compiler);
    return mask.contains(jsStringType, compiler);
  }

  DartType computeType(Compiler compiler) => mask.base;
  TypeMask computeMask(Compiler compiler) => mask;

  bool operator ==(HType other) {
    if (other is !HBoundedType) return false;
    HBoundedType bounded = other;
    return mask == bounded.mask;
  }

  HType intersection(HType other, Compiler compiler) {
    if (this == other) return this;
    if (other.isConflicting()) return HType.CONFLICTING;
    if (isTop(compiler)) return other;
    if (other.isNull()) return canBeNull() ? HType.NULL : HType.CONFLICTING;

    if (canBePrimitiveArray(compiler)) {
      if (other.isArray()) return other;
      if (other.isStringOrNull()) {
        return other.isString() ? HType.CONFLICTING : HType.NULL;
      }
      if (other.isIndexablePrimitive()) return HType.READABLE_ARRAY;
    }

    if (canBePrimitiveString(compiler)) {
      if (other.isArray()) return HType.CONFLICTING;
      if (other.isString()) return HType.STRING;
      if (other.isStringOrNull()) {
        return canBeNull() ? HType.STRING_OR_NULL : HType.STRING;
      }
      if (other.isIndexablePrimitive()) return HType.STRING;
    }

    TypeMask otherMask = other.computeMask(compiler);
    if (otherMask != null) {
      TypeMask intersection = mask.intersection(otherMask, compiler.types);
      if (intersection != null) {
        if (intersection == mask) return this;
        return new HBoundedType(intersection);
      }
    }
    if (other.isUnknown()) return this;
    if (other.canBeNull() && canBeNull()) return HType.NULL;
    return HType.CONFLICTING;
  }

  HType union(HType other, Compiler compiler) {
    if (this == other) return this;
    if (isTop(compiler)) return this;
    if (other.isNull()) {
      if (canBeNull()) {
        return this;
      } else {
        return new HBoundedType(mask.nullable());
      }
    }

    TypeMask otherMask = other.computeMask(compiler);
    if (otherMask != null) {
      TypeMask union = mask.union(otherMask, compiler.types);
      if (union == null) return HType.UNKNOWN;
      if (union == mask) return this;
      return new HBoundedType(union);
    }
    if (other.isConflicting()) return this;
    return HType.UNKNOWN;
  }

  String toString() {
    return 'BoundedType(mask=$mask)';
  }
}
