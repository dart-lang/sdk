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

  DartType get exactType => isExact ? base : null;

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
    if (base.asRaw() == other.base.asRaw()) {
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
    assert(base.asRaw() == other.base.asRaw());
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
    assert(base.asRaw() != other.base.asRaw());
    assert(!isSubtypeOf(base, other.base, compiler));
    assert(!isSubtypeOf(other.base, base, compiler));
    // TODO(kasperl): Do this error handling earlier.
    if (base.kind != TypeKind.INTERFACE) return null;
    if (other.base.kind != TypeKind.INTERFACE) return null;
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
    // TODO(kasperl): Get rid of this hack when the rest of the system
    // is ready for not using HType.UNKNOWN everywhere.
    if (bestElement == compiler.objectClass) return null;
    return new TypeMask(bestElement.computeType(compiler),
                        bestKind,
                        isNullable || other.isNullable);
  }

  TypeMask intersection(TypeMask other, Compiler compiler) {
    if (base.asRaw() == other.base.asRaw()) {
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
    assert(base.asRaw() == other.base.asRaw());
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

  TypeMask intersectionDisjoint(TypeMask other, Compiler compiler) {
    assert(base.asRaw() != other.base.asRaw());
    assert(!isSubtypeOf(base, other.base, compiler));
    assert(!isSubtypeOf(other.base, base, compiler));
    // TODO(kasperl): Do this error handling earlier.
    if (base.kind != TypeKind.INTERFACE) return null;
    if (other.base.kind != TypeKind.INTERFACE) return null;
    // If one of the masks are exact or if both of them are subclass
    // masks, then the intersection is empty.
    if (isExact || other.isExact) return null;
    if (isSubclass && other.isSubclass) return null;
    assert(isSubtype || other.isSubtype);
    int kind = (isSubclass || other.isSubclass) ? SUBCLASS : SUBTYPE;
    // Compute the set of classes that are contained in both type masks.
    Set<ClassElement> common = commonContainedClasses(this, other, compiler);
    if (common == null || common.isEmpty) return null;
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
    if (flags != otherMask.flags) return false;
    if (base == null || otherMask.base == null) {
      return base == otherMask.base;
    } else {
      return base.asRaw() == otherMask.base.asRaw();
    }
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
