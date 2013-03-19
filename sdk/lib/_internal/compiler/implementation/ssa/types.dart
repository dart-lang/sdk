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
    bool isNullable = mask.isNullable;
    if (mask.isEmpty) {
      return isNullable ? HType.NULL : HType.CONFLICTING;
    }

    Element element = mask.base.element;
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
    }

    // TODO(kasperl): A lot of the code in the system currently
    // expects the top type to be 'unknown'. I'll rework this.
    if (element == compiler.objectClass || element == compiler.dynamicClass) {
      return isNullable ? HType.UNKNOWN : HType.NON_NULL;
    }

    if (!isNullable) {
      if (element == backend.jsIndexableClass) {
        return HType.INDEXABLE_PRIMITIVE;
      } else if (element == backend.jsArrayClass) {
        return HType.READABLE_ARRAY;
      } else if (element == backend.jsMutableArrayClass) {
        return HType.MUTABLE_ARRAY;
      } else if (element == backend.jsFixedArrayClass) {
        return HType.FIXED_ARRAY;
      } else if (element == backend.jsExtendableArrayClass) {
        return HType.EXTENDABLE_ARRAY;
      }
    }
    return new HBoundedType(mask);
  }

  factory HType.exact(DartType type, Compiler compiler) {
    TypeMask mask = new TypeMask.exact(type);
    return new HType.fromMask(mask, compiler);
  }

  factory HType.subclass(DartType type, Compiler compiler) {
    TypeMask mask = new TypeMask.subclass(type);
    return new HType.fromMask(mask, compiler);
  }

  factory HType.subtype(DartType type, Compiler compiler) {
    TypeMask mask = new TypeMask.subtype(type);
    return new HType.fromMask(mask, compiler);
  }

  factory HType.nonNullExact(DartType type, Compiler compiler) {
    TypeMask mask = new TypeMask.nonNullExact(type);
    return new HType.fromMask(mask, compiler);
  }

  factory HType.nonNullSubclass(DartType type, Compiler compiler) {
    TypeMask mask = new TypeMask.nonNullSubclass(type);
    return new HType.fromMask(mask, compiler);
  }

  factory HType.nonNullSubtype(DartType type, Compiler compiler) {
    TypeMask mask = new TypeMask.nonNullSubtype(type);
    return new HType.fromMask(mask, compiler);
  }

  factory HType.fromInferredType(TypeMask mask, Compiler compiler) {
    if (mask == null) return HType.UNKNOWN;
    return new HType.fromMask(mask, compiler);
  }

  factory HType.inferredReturnTypeForElement(
      Element element, Compiler compiler) {
    return new HType.fromInferredType(
        compiler.typesTask.getGuaranteedReturnTypeOfElement(element),
        compiler);
  }

  factory HType.inferredTypeForElement(Element element, Compiler compiler) {
    return new HType.fromInferredType(
        compiler.typesTask.getGuaranteedTypeOfElement(element),
        compiler);
  }

  factory HType.inferredTypeForSelector(Selector selector, Compiler compiler) {
    return new HType.fromInferredType(
        compiler.typesTask.getGuaranteedTypeOfSelector(selector),
        compiler);
  }

  factory HType.inferredForNode(Element owner, Node node, Compiler compiler) {
    return new HType.fromInferredType(
        compiler.typesTask.getGuaranteedTypeOfNode(owner, node),
        compiler);
  }

  // [type] is either an instance of [DartType] or special objects
  // like [native.SpecialType.JsObject], or [native.SpecialType.JsArray].
  factory HType.fromNativeType(type, Compiler compiler) {
    if (type == native.SpecialType.JsObject) {
      return new HType.nonNullExact(
          compiler.objectClass.computeType(compiler), compiler);
    } else if (type == native.SpecialType.JsArray) {
      return HType.READABLE_ARRAY;
    } else if (type.element == compiler.nullClass) {
      return HType.NULL;
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

  static const HType CONFLICTING = const HConflictingType();
  static const HType UNKNOWN = const HUnknownType();
  static const HType NON_NULL = const HNonNullType();
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
  bool canBePrimitiveBoolean(Compiler compiler) => false;

  /** A type is useful it is not unknown, not conflicting, and not null. */
  bool isUseful() => !isUnknown() && !isConflicting() && !isNull();
  /** Alias for isReadableArray. */
  bool isArray() => isReadableArray();

  TypeMask computeMask(Compiler compiler);

  Selector refine(Selector selector, Compiler compiler) {
    // TODO(kasperl): Should we check if the refinement really is more
    // specialized than the starting point?
    TypeMask mask = computeMask(compiler);
    return new TypedSelector(mask, selector);
  }

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
  HType intersection(HType other, Compiler compiler) {
    TypeMask mask = computeMask(compiler);
    TypeMask otherMask = other.computeMask(compiler);
    TypeMask intersection = mask.intersection(otherMask, compiler);
    return new HType.fromMask(intersection, compiler);
  }

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
  HType union(HType other, Compiler compiler) {
    TypeMask mask = computeMask(compiler);
    TypeMask otherMask = other.computeMask(compiler);
    TypeMask union = mask.union(otherMask, compiler);
    return new HType.fromMask(union, compiler);
  }
}

/** Used to represent [HType.UNKNOWN] and [HType.CONFLICTING]. */
abstract class HAnalysisType extends HType {
  final String name;
  const HAnalysisType(this.name);
  String toString() => name;
}

class HUnknownType extends HAnalysisType {
  const HUnknownType() : super("unknown");
  bool canBePrimitive(Compiler compiler) => true;
  bool canBeNull() => true;
  bool canBePrimitiveNumber(Compiler compiler) => true;
  bool canBePrimitiveString(Compiler compiler) => true;
  bool canBePrimitiveArray(Compiler compiler) => true;
  bool canBePrimitiveBoolean(Compiler compiler) => true;

  TypeMask computeMask(Compiler compiler) {
    DartType base = compiler.objectClass.computeType(compiler);
    return new TypeMask.subclass(base);
  }
}

class HNonNullType extends HAnalysisType {
  const HNonNullType() : super("non-null");
  bool canBePrimitive(Compiler compiler) => true;
  bool canBeNull() => false;
  bool canBePrimitiveNumber(Compiler compiler) => true;
  bool canBePrimitiveString(Compiler compiler) => true;
  bool canBePrimitiveArray(Compiler compiler) => true;
  bool canBePrimitiveBoolean(Compiler compiler) => true;

  TypeMask computeMask(Compiler compiler) {
    DartType base = compiler.objectClass.computeType(compiler);
    return new TypeMask.nonNullSubclass(base);
  }
}

class HConflictingType extends HAnalysisType {
  const HConflictingType() : super("conflicting");
  bool canBePrimitive(Compiler compiler) => true;
  bool canBeNull() => false;

  TypeMask computeMask(Compiler compiler) {
    return new TypeMask.nonNullEmpty();
  }
}

abstract class HPrimitiveType extends HType {
  const HPrimitiveType();
  bool isPrimitive() => true;
  bool canBePrimitive(Compiler compiler) => true;
  bool isPrimitiveOrNull() => true;
}

class HNullType extends HPrimitiveType {
  const HNullType();
  bool canBeNull() => true;
  bool isNull() => true;
  String toString() => 'null type';
  bool isExact() => true;

  TypeMask computeMask(Compiler compiler) {
    return new TypeMask.empty();
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
  bool canBePrimitiveBoolean(Compiler compiler) => true;

  TypeMask computeMask(Compiler compiler) {
    JavaScriptBackend backend = compiler.backend;
    DartType base = backend.jsBoolClass.computeType(compiler);
    return new TypeMask.exact(base);
  }
}

class HBooleanType extends HPrimitiveType {
  const HBooleanType();
  bool isBoolean() => true;
  bool isBooleanOrNull() => true;
  String toString() => "boolean";
  bool isExact() => true;
  bool canBePrimitiveBoolean(Compiler compiler) => true;

  TypeMask computeMask(Compiler compiler) {
    JavaScriptBackend backend = compiler.backend;
    DartType base = backend.jsBoolClass.computeType(compiler);
    return new TypeMask.nonNullExact(base);
  }
}

class HNumberOrNullType extends HPrimitiveOrNullType {
  const HNumberOrNullType();
  bool isNumberOrNull() => true;
  String toString() => "number or null";
  bool canBePrimitiveNumber(Compiler compiler) => true;

  TypeMask computeMask(Compiler compiler) {
    JavaScriptBackend backend = compiler.backend;
    DartType base = backend.jsNumberClass.computeType(compiler);
    return new TypeMask.subclass(base);
  }
}

class HNumberType extends HPrimitiveType {
  const HNumberType();
  bool isNumber() => true;
  bool isNumberOrNull() => true;
  String toString() => "number";
  bool canBePrimitiveNumber(Compiler compiler) => true;

  TypeMask computeMask(Compiler compiler) {
    JavaScriptBackend backend = compiler.backend;
    DartType base = backend.jsNumberClass.computeType(compiler);
    return new TypeMask.nonNullSubclass(base);
  }
}

class HIntegerOrNullType extends HNumberOrNullType {
  const HIntegerOrNullType();
  bool isIntegerOrNull() => true;
  String toString() => "integer or null";

  TypeMask computeMask(Compiler compiler) {
    JavaScriptBackend backend = compiler.backend;
    DartType base = backend.jsIntClass.computeType(compiler);
    return new TypeMask.exact(base);
  }
}

class HIntegerType extends HNumberType {
  const HIntegerType();
  bool isInteger() => true;
  bool isIntegerOrNull() => true;
  String toString() => "integer";
  bool isExact() => true;

  TypeMask computeMask(Compiler compiler) {
    JavaScriptBackend backend = compiler.backend;
    DartType base = backend.jsIntClass.computeType(compiler);
    return new TypeMask.nonNullExact(base);
  }
}

class HDoubleOrNullType extends HNumberOrNullType {
  const HDoubleOrNullType();
  bool isDoubleOrNull() => true;
  String toString() => "double or null";

  TypeMask computeMask(Compiler compiler) {
    JavaScriptBackend backend = compiler.backend;
    DartType base = backend.jsDoubleClass.computeType(compiler);
    return new TypeMask.exact(base);
  }
}

class HDoubleType extends HNumberType {
  const HDoubleType();
  bool isDouble() => true;
  bool isDoubleOrNull() => true;
  String toString() => "double";
  bool isExact() => true;

  TypeMask computeMask(Compiler compiler) {
    JavaScriptBackend backend = compiler.backend;
    DartType base = backend.jsDoubleClass.computeType(compiler);
    return new TypeMask.nonNullExact(base);
  }
}

class HIndexablePrimitiveType extends HPrimitiveType {
  const HIndexablePrimitiveType();
  bool isIndexablePrimitive() => true;
  String toString() => "indexable";

  TypeMask computeMask(Compiler compiler) {
    JavaScriptBackend backend = compiler.backend;
    DartType base = backend.jsIndexableClass.computeType(compiler);
    return new TypeMask.nonNullSubtype(base);
  }
}

class HStringOrNullType extends HPrimitiveOrNullType {
  const HStringOrNullType();
  bool isStringOrNull() => true;
  String toString() => "String or null";
  bool canBePrimitiveString(Compiler compiler) => true;

  TypeMask computeMask(Compiler compiler) {
    JavaScriptBackend backend = compiler.backend;
    DartType base = backend.jsStringClass.computeType(compiler);
    return new TypeMask.exact(base);
  }
}

class HStringType extends HIndexablePrimitiveType {
  const HStringType();
  bool isString() => true;
  bool isStringOrNull() => true;
  String toString() => "String";
  bool isExact() => true;
  bool canBePrimitiveString(Compiler compiler) => true;

  TypeMask computeMask(Compiler compiler) {
    JavaScriptBackend backend = compiler.backend;
    DartType base = backend.jsStringClass.computeType(compiler);
    return new TypeMask.nonNullExact(base);
  }
}

class HReadableArrayType extends HIndexablePrimitiveType {
  const HReadableArrayType();
  bool isReadableArray() => true;
  String toString() => "readable array";
  bool canBePrimitiveArray(Compiler compiler) => true;

  TypeMask computeMask(Compiler compiler) {
    JavaScriptBackend backend = compiler.backend;
    DartType base = backend.jsArrayClass.computeType(compiler);
    return new TypeMask.nonNullSubclass(base);
  }
}

class HMutableArrayType extends HReadableArrayType {
  const HMutableArrayType();
  bool isMutableArray() => true;
  String toString() => "mutable array";

  TypeMask computeMask(Compiler compiler) {
    JavaScriptBackend backend = compiler.backend;
    DartType base = backend.jsMutableArrayClass.computeType(compiler);
    return new TypeMask.nonNullSubclass(base);
  }
}

class HFixedArrayType extends HMutableArrayType {
  const HFixedArrayType();
  bool isFixedArray() => true;
  String toString() => "fixed array";
  bool isExact() => true;

  TypeMask computeMask(Compiler compiler) {
    JavaScriptBackend backend = compiler.backend;
    DartType base = backend.jsFixedArrayClass.computeType(compiler);
    return new TypeMask.nonNullExact(base);
  }
}

class HExtendableArrayType extends HMutableArrayType {
  const HExtendableArrayType();
  bool isExtendableArray() => true;
  String toString() => "extendable array";
  bool isExact() => true;

  TypeMask computeMask(Compiler compiler) {
    JavaScriptBackend backend = compiler.backend;
    DartType base = backend.jsExtendableArrayClass.computeType(compiler);
    return new TypeMask.nonNullExact(base);
  }
}

class HBoundedType extends HType {
  final TypeMask mask;
  const HBoundedType(this.mask);

  bool isExact() => mask.isExact;

  bool canBeNull() => mask.isNullable;

  bool canBePrimitive(Compiler compiler) {
    return canBePrimitiveNumber(compiler)
        || canBePrimitiveArray(compiler)
        || canBePrimitiveBoolean(compiler)
        || canBePrimitiveString(compiler);
  }

  bool canBePrimitiveNumber(Compiler compiler) {
    JavaScriptBackend backend = compiler.backend;
    DartType jsNumberType = backend.jsNumberClass.computeType(compiler);
    return mask.contains(jsNumberType, compiler);
  }

  bool canBePrimitiveBoolean(Compiler compiler) {
    JavaScriptBackend backend = compiler.backend;
    DartType jsBoolType = backend.jsBoolClass.computeType(compiler);
    return mask.contains(jsBoolType, compiler);
  }

  bool canBePrimitiveArray(Compiler compiler) {
    JavaScriptBackend backend = compiler.backend;
    DartType jsArrayType = backend.jsArrayClass.rawType;
    DartType jsFixedArrayType = backend.jsFixedArrayClass.rawType;
    DartType jsExtendableArrayType = backend.jsExtendableArrayClass.rawType;
    return mask.contains(jsArrayType, compiler)
        || mask.contains(jsFixedArrayType, compiler)
        || mask.contains(jsExtendableArrayType, compiler);
  }

  bool canBePrimitiveString(Compiler compiler) {
    JavaScriptBackend backend = compiler.backend;
    DartType jsStringType = backend.jsStringClass.computeType(compiler);
    return mask.contains(jsStringType, compiler);
  }

  TypeMask computeMask(Compiler compiler) => mask;

  bool operator ==(HType other) {
    if (other is !HBoundedType) return false;
    HBoundedType bounded = other;
    return mask == bounded.mask;
  }

  String toString() {
    return 'BoundedType(mask=$mask)';
  }
}
