// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of types;

/**
 * A type mask represents a set of concrete types, but the operations
 * on it are not guaranteed to be precise. When computing the union of
 * two masks you may get a mask that is too wide (like a common
 * superclass instead of a proper union type) and when computing the
 * intersection of two masks you may get a mask that is too narrow.
 */
class TypeMask {

  static const int EXACT    = 0;
  static const int SUBCLASS = 1;
  static const int SUBTYPE  = 2;

  final DartType base;
  final int flags;

  TypeMask(DartType base, int kind, bool isNullable)
      : this.internal(base, (kind << 1) | (isNullable ? 1 : 0));

  const TypeMask.exact(DartType base)
      : this.internal(base, (EXACT << 1) | 1);
  const TypeMask.subclass(DartType base)
      : this.internal(base, (SUBCLASS << 1) | 1);
  const TypeMask.subtype(DartType base)
      : this.internal(base, (SUBTYPE << 1) | 1);

  const TypeMask.nonNullExact(DartType base)
      : this.internal(base, EXACT << 1);
  const TypeMask.nonNullSubclass(DartType base)
      : this.internal(base, SUBCLASS << 1);
  const TypeMask.nonNullSubtype(DartType base)
      : this.internal(base, SUBTYPE << 1);

  const TypeMask.internal(this.base, this.flags);

  bool get isNullable => (flags & 1) != 0;
  bool get isExact => (flags >> 1) == EXACT;

  // TODO(kasperl): Get rid of these. They should not be a visible
  // part of the implementation because they make it hard to add
  // proper union types if we ever want to.
  bool get isSubclass => (flags >> 1) == SUBCLASS;
  bool get isSubtype => (flags >> 1) == SUBTYPE;

  /**
   * Returns a nullable variant of [this] type mask.
   */
  TypeMask nullable() {
    return isNullable ? this : new TypeMask.internal(base, flags | 1);
  }

  /**
   * Returns whether or not this type mask contains the given type.
   */
  bool contains(DartType type, Compiler compiler) {
    if (isExact) {
      return identical(base.element, type.element);
    } else if (isSubclass) {
      return isSubclassOf(type, base, compiler);
    } else {
      assert(isSubtype);
      return isSubtypeOf(type, base, compiler);
    }
  }

  // TODO(kasperl): Try to get rid of this method. It shouldn't really
  // be necessary.
  bool containsAll(Compiler compiler) {
    // TODO(kasperl): Do this error handling earlier.
    if (base.kind != TypeKind.INTERFACE) return false;
    // TODO(kasperl): Should we take nullability into account here?
    if (isExact) return false;
    ClassElement baseElement = base.element;
    return identical(baseElement, compiler.objectClass)
        || identical(baseElement, compiler.dynamicClass);
  }

  TypeMask union(TypeMask other, Compiler compiler) {
    if (base == other.base) {
      return unionSame(other, compiler);
    } else if (isSubclassOf(other.base, base, compiler)) {
      return unionSubclass(other, compiler);
    } else if (isSubclassOf(base, other.base, compiler)) {
      return other.unionSubclass(this, compiler);
    } else if (isSubtypeOf(other.base, base, compiler)) {
      return unionSubtype(other, compiler);
    } else if (isSubtypeOf(base, other.base, compiler)) {
      return other.unionSubtype(this, compiler);
    } else {
      return unionDisjoint(other, compiler);
    }
  }

  TypeMask unionSame(TypeMask other, Compiler compiler) {
    assert(base == other.base);
    // The two masks share the base type, so we must chose the least
    // constraining kind (the highest) of the two. If either one of
    // the masks are nullable the result should be nullable too.
    int combined = (flags > other.flags)
        ? flags | (other.flags & 1)
        : other.flags | (flags & 1);
    if (flags == combined) {
      return this;
    } else if (other.flags == combined) {
      return other;
    } else {
      return new TypeMask.internal(base, combined);
    }
  }

  TypeMask unionSubclass(TypeMask other, Compiler compiler) {
    assert(isSubclassOf(other.base, base, compiler));
    int combined;
    if (isExact && other.isExact) {
      // Since the other mask is a subclass of this mask, we need the
      // resulting union to be a subclass too. If either one of the
      // masks are nullable the result should be nullable too.
      combined = (SUBCLASS << 1) | ((flags | other.flags) & 1);
    } else {
      // Both masks are at least subclass masks, so we pick the least
      // constraining kind (the highest) of the two. If either one of
      // the masks are nullable the result should be nullable too.
      combined = (flags > other.flags)
          ? flags | (other.flags & 1)
          : other.flags | (flags & 1);
    }
    return (flags != combined)
        ? new TypeMask.internal(base, combined)
        : this;
  }

  TypeMask unionSubtype(TypeMask other, Compiler compiler) {
    assert(isSubtypeOf(other.base, base, compiler));
    // Since the other mask is a subtype of this mask, we need the
    // resulting union to be a subtype too. If either one of the masks
    // are nullable the result should be nullable too.
    int combined = (SUBTYPE << 1) | ((flags | other.flags) & 1);
    return (flags != combined)
        ? new TypeMask.internal(base, combined)
        : this;
  }

  TypeMask unionDisjoint(TypeMask other, Compiler compiler) {
    assert(base != other.base);
    assert(!isSubtypeOf(base, other.base, compiler));
    assert(!isSubtypeOf(other.base, base, compiler));
    // If either type mask is a subtype type mask, we cannot use a
    // subclass type mask to represent their union.
    bool useSubclass = !isSubtype && !other.isSubtype;
    // Compute the common supertypes of the two types.
    ClassElement thisElement = base.element;
    ClassElement otherElement = other.base.element;
    Iterable<ClassElement> candidates =
        compiler.world.commonSupertypesOf(thisElement, otherElement);
    if (candidates.isEmpty) return null;
    // Compute the best candidate and its kind.
    ClassElement bestElement;
    int bestKind;
    int bestSize;
    for (ClassElement candidate in candidates) {
      Set<ClassElement> subclasses = useSubclass
          ? compiler.world.subclasses[candidate]
          : null;
      int size;
      int kind;
      if (subclasses != null &&
          subclasses.contains(thisElement) &&
          subclasses.contains(otherElement)) {
        // If both [this] and [other] are subclasses of the supertype,
        // then we prefer to construct a subclass type mask because it
        // will always be at least as small as the corresponding
        // subtype type mask.
        kind = SUBCLASS;
        size = subclasses.length;
        assert(size <= compiler.world.subtypes[candidate].length);
      } else {
        kind = SUBTYPE;
        size = compiler.world.subtypes[candidate].length;
      }
      // Update the best candidate if the new one is better.
      if (bestElement == null || size < bestSize) {
        bestElement = candidate;
        bestSize = size;
        bestKind = kind;
      }
    }
    return new TypeMask(bestElement.computeType(compiler),
                        bestKind,
                        isNullable || other.isNullable);
  }

  TypeMask intersection(TypeMask other, Compiler compiler) {
    if (base == other.base) {
      return intersectionSame(other, compiler);
    } else if (isSubclassOf(other.base, base, compiler)) {
      return intersectionSubclass(other, compiler);
    } else if (isSubclassOf(base, other.base, compiler)) {
      return other.intersectionSubclass(this, compiler);
    } else if (isSubtypeOf(other.base, base, compiler)) {
      return intersectionSubtype(other, compiler);
    } else if (isSubtypeOf(base, other.base, compiler)) {
      return other.intersectionSubtype(this, compiler);
    }
    return null;
  }

  TypeMask intersectionSame(TypeMask other, Compiler compiler) {
    assert(base == other.base);
    // The two masks share the base type, so we must chose the most
    // constraining kind (the lowest) of the two. Only if both masks
    // are nullable, will the result be nullable too.
    int combined = (flags < other.flags)
        ? flags & ((other.flags & 1) | ~1)
        : other.flags & ((flags & 1) | ~1);
    if (flags == combined) {
      return this;
    } else if (other.flags == combined) {
      return other;
    } else {
      return new TypeMask.internal(base, combined);
    }
  }

  TypeMask intersectionSubclass(TypeMask other, Compiler compiler) {
    assert(isSubclassOf(other.base, base, compiler));
    // If this mask isn't at least a subclass mask, then the
    // intersection with the other mask is empty.
    if (isExact) return null;
    // Only the other mask puts constraints on the intersection mask,
    // so base the combined flags on the other mask. Only if both
    // masks are nullable, will the result be nullable too.
    int combined = other.flags & ((flags & 1) | ~1);
    if (other.flags == combined) {
      return other;
    } else {
      return new TypeMask.internal(other.base, combined);
    }
  }

  TypeMask intersectionSubtype(TypeMask other, Compiler compiler) {
    assert(isSubtypeOf(other.base, base, compiler));
    // If this mask isn't a subtype mask, then the intersection with
    // the other mask is empty.
    if (!isSubtype) return null;
    // Only the other mask puts constraints on the intersection mask,
    // so base the combined flags on the other mask. Only if both
    // masks are nullable, will the result be nullable too.
    int combined = other.flags & ((flags & 1) | ~1);
    if (other.flags == combined) {
      return other;
    } else {
      return new TypeMask.internal(other.base, combined);
    }
  }

  bool operator ==(var other) {
    if (other is !TypeMask) return false;
    TypeMask otherMask = other;
    return (base == otherMask.base) && (flags == otherMask.flags);
  }

  String toString() {
    StringBuffer buffer = new StringBuffer();
    if (isNullable) buffer.write('null|');
    if (isExact) buffer.write('exact=');
    if (isSubclass) buffer.write('subclass=');
    if (isSubtype) buffer.write('subtype=');
    buffer.write(base.element.name.slowToString());
    return "[$buffer]";
  }

  static bool isSubclassOf(DartType x, DartType y, Compiler compiler) {
    // TODO(kasperl): Do this error handling earlier.
    if (x.kind != TypeKind.INTERFACE) return false;
    if (y.kind != TypeKind.INTERFACE) return false;
    ClassElement xElement = x.element;
    ClassElement yElement = y.element;
    Set<ClassElement> subclasses = compiler.world.subclasses[yElement];
    return (subclasses != null) ? subclasses.contains(xElement) : false;
  }

  static bool isSubtypeOf(DartType x, DartType y, Compiler compiler) {
    // TODO(kasperl): Do this error handling earlier.
    if (x.kind != TypeKind.INTERFACE) return false;
    if (y.kind != TypeKind.INTERFACE) return false;
    ClassElement xElement = x.element;
    ClassElement yElement = y.element;
    Set<ClassElement> subtypes = compiler.world.subtypes[yElement];
    return (subtypes != null) ? subtypes.contains(xElement) : false;
  }
}
