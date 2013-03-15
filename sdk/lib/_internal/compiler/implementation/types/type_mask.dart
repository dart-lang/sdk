// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of types;

/**
 * A type mask represents a set of contained classes, but the
 * operations on it are not guaranteed to be precise and they may
 * yield conservative answers that contain too many classes.
 */
class TypeMask {

  static const int EMPTY    = 0;
  static const int EXACT    = 1;
  static const int SUBCLASS = 2;
  static const int SUBTYPE  = 3;

  final DartType base;
  final int flags;

  TypeMask(DartType base, int kind, bool isNullable)
      : this.internal(base, (kind << 1) | (isNullable ? 1 : 0));

  TypeMask.empty()
      : this.internal(null, (EMPTY << 1) | 1);
  TypeMask.exact(DartType base)
      : this.internal(base, (EXACT << 1) | 1);
  TypeMask.subclass(DartType base)
      : this.internal(base, (SUBCLASS << 1) | 1);
  TypeMask.subtype(DartType base)
      : this.internal(base, (SUBTYPE << 1) | 1);

  TypeMask.nonNullEmpty()
      : this.internal(null, EMPTY << 1);
  TypeMask.nonNullExact(DartType base)
      : this.internal(base, EXACT << 1);
  TypeMask.nonNullSubclass(DartType base)
      : this.internal(base, SUBCLASS << 1);
  TypeMask.nonNullSubtype(DartType base)
      : this.internal(base, SUBTYPE << 1);

  TypeMask.internal(DartType base, this.flags)
      : this.base = transformBase(base);

  // TODO(kasperl): We temporarily transform the base to be the raw
  // variant of the type. Long term, we're going to keep the class
  // element corresponding to the type in the mask instead.
  static DartType transformBase(DartType base) {
    if (base == null) {
      return null;
    } else if (base.kind != TypeKind.INTERFACE) {
      assert(base.kind == TypeKind.INTERFACE);
      return null;
    } else {
      assert(!base.isMalformed);
      return base.asRaw();
    }
  }

  bool get isEmpty => (flags >> 1) == EMPTY;
  bool get isExact => (flags >> 1) == EXACT;
  bool get isNullable => (flags & 1) != 0;

  // TODO(kasperl): Get rid of these. They should not be a visible
  // part of the implementation because they make it hard to add
  // proper union types if we ever want to.
  bool get isSubclass => (flags >> 1) == SUBCLASS;
  bool get isSubtype => (flags >> 1) == SUBTYPE;

  DartType get exactType => isExact ? base : null;

  /**
   * Returns a nullable variant of [this] type mask.
   */
  TypeMask nullable() {
    return isNullable ? this : new TypeMask.internal(base, flags | 1);
  }

  /**
   * Returns a non-nullable variant of [this] type mask.
   */
  TypeMask nonNullable() {
    return isNullable ? new TypeMask.internal(base, flags & ~1) : this;
  }

  /**
   * Returns whether or not this type mask contains the given type.
   */
  bool contains(DartType type, Compiler compiler) {
    if (isEmpty) {
      return false;
    } else if (identical(base.element, type.element)) {
      return true;
    } else if (isExact) {
      return false;
    } else if (isSubclass) {
      return isSubclassOf(type, base, compiler);
    } else {
      assert(isSubtype);
      return isSubtypeOf(type, base, compiler);
    }
  }

  /**
   * Returns whether or not this type mask contains all types.
   */
  bool containsAll(Compiler compiler) {
    if (isEmpty || isExact) return false;
    return identical(base.element, compiler.objectClass)
        || identical(base.element, compiler.dynamicClass);
  }

  TypeMask union(TypeMask other, Compiler compiler) {
    if (isEmpty) {
      return isNullable ? other.nullable() : other;
    } else if (other.isEmpty) {
      return other.isNullable ? nullable() : this;
    } else if (base == other.base) {
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
    if (candidates.isEmpty) {
      // TODO(kasperl): Get rid of this check. It can only happen when
      // at least one of the two base types is 'unseen'.
      return new TypeMask(compiler.objectClass.rawType,
                          SUBCLASS,
                          isNullable || other.isNullable);
    }
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
    if (isEmpty) {
      return other.isNullable ? this : nonNullable();
    } else if (other.isEmpty) {
      return isNullable ? other : other.nonNullable();
    } else if (base == other.base) {
      return intersectionSame(other, compiler);
    } else if (isSubclassOf(other.base, base, compiler)) {
      return intersectionSubclass(other, compiler);
    } else if (isSubclassOf(base, other.base, compiler)) {
      return other.intersectionSubclass(this, compiler);
    } else if (isSubtypeOf(other.base, base, compiler)) {
      return intersectionSubtype(other, compiler);
    } else if (isSubtypeOf(base, other.base, compiler)) {
      return other.intersectionSubtype(this, compiler);
    } else {
      return intersectionDisjoint(other, compiler);
    }
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
    if (isExact) return intersectionEmpty(other);
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
    if (!isSubtype) return intersectionEmpty(other);
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

  TypeMask intersectionDisjoint(TypeMask other, Compiler compiler) {
    assert(base != other.base);
    assert(!isSubtypeOf(base, other.base, compiler));
    assert(!isSubtypeOf(other.base, base, compiler));
    // If one of the masks are exact or if both of them are subclass
    // masks, then the intersection is empty.
    if (isExact || other.isExact) return intersectionEmpty(other);
    if (isSubclass && other.isSubclass) return intersectionEmpty(other);
    assert(isSubtype || other.isSubtype);
    int kind = (isSubclass || other.isSubclass) ? SUBCLASS : SUBTYPE;
    // Compute the set of classes that are contained in both type masks.
    Set<ClassElement> common = commonContainedClasses(this, other, compiler);
    if (common == null || common.isEmpty) return intersectionEmpty(other);
    // Narrow down the candidates by only looking at common classes
    // that do not have a superclass or supertype that will be a
    // better candidate.
    Iterable<ClassElement> candidates = common.where((ClassElement each) {
      bool containsSuperclass = common.contains(each.supertype.element);
      // If the superclass is also a candidate, then we don't want to
      // deal with this class. If we're only looking for a subclass we
      // know we don't have to look at the list of interfaces because
      // they can never be in the common set.
      if (containsSuperclass || kind == SUBCLASS) return !containsSuperclass;
      // Run through the direct supertypes of the class. If the common
      // set contains the direct supertype of the class, we ignore the
      // the class because the supertype is a better candidate.
      for (Link link = each.interfaces; !link.isEmpty; link = link.tail) {
        if (common.contains(link.head.element)) return false;
      }
      return true;
    });
    // Run through the list of candidates and compute the union. The
    // result will only be nullable if both masks are nullable.
    int combined = (kind << 1) | (flags & other.flags & 1);
    TypeMask result;
    for (ClassElement each in candidates) {
      TypeMask mask = new TypeMask.internal(each.rawType, combined);
      result = (result == null) ? mask : result.union(mask, compiler);
    }
    return result;
  }

  TypeMask intersectionEmpty(TypeMask other) {
    return new TypeMask(null, EMPTY, isNullable && other.isNullable);
  }

  Set<ClassElement> containedClasses(Compiler compiler) {
    ClassElement element = base.element;
    if (isExact) {
      return new Set<ClassElement>()..add(element);
    } else if (isSubclass) {
      return compiler.world.subclasses[element];
    } else {
      assert(isSubtype);
      return compiler.world.subtypes[element];
    }
  }

  bool operator ==(var other) {
    if (other is !TypeMask) return false;
    TypeMask otherMask = other;
    return (flags == otherMask.flags) && (base == otherMask.base);
  }

  String toString() {
    if (isEmpty) return isNullable ? '[null]' : '[empty]';
    StringBuffer buffer = new StringBuffer();
    if (isNullable) buffer.write('null|');
    if (isExact) buffer.write('exact=');
    if (isSubclass) buffer.write('subclass=');
    if (isSubtype) buffer.write('subtype=');
    buffer.write(base.element.name.slowToString());
    return "[$buffer]";
  }

  static bool isSubclassOf(DartType x, DartType y, Compiler compiler) {
    ClassElement xElement = x.element;
    ClassElement yElement = y.element;
    Set<ClassElement> subclasses = compiler.world.subclasses[yElement];
    return (subclasses != null) ? subclasses.contains(xElement) : false;
  }

  static bool isSubtypeOf(DartType x, DartType y, Compiler compiler) {
    ClassElement xElement = x.element;
    ClassElement yElement = y.element;
    Set<ClassElement> subtypes = compiler.world.subtypes[yElement];
    return (subtypes != null) ? subtypes.contains(xElement) : false;
  }

  static Set<ClassElement> commonContainedClasses(TypeMask x, TypeMask y,
                                                  Compiler compiler) {
    Set<ClassElement> xSubset = x.containedClasses(compiler);
    if (xSubset == null) return null;
    Set<ClassElement> ySubset = y.containedClasses(compiler);
    if (ySubset == null) return null;
    Set<ClassElement> smallSet, largeSet;
    if (xSubset.length <= ySubset.length) {
      smallSet = xSubset;
      largeSet = ySubset;
    } else {
      smallSet = ySubset;
      largeSet = xSubset;
    }
    var result = smallSet.where((ClassElement each) => largeSet.contains(each));
    return result.toSet();
  }
}
