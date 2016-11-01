// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of masks;

/**
 * A flat type mask is a type mask that has been flattened to contain a
 * base type.
 */
class FlatTypeMask implements TypeMask {
  static const int EMPTY = 0;
  static const int EXACT = 1;
  static const int SUBCLASS = 2;
  static const int SUBTYPE = 3;

  final Entity base;
  final int flags;

  FlatTypeMask(Entity base, int kind, bool isNullable)
      : this.internal(base, (kind << 1) | (isNullable ? 1 : 0));

  FlatTypeMask.exact(Entity base) : this.internal(base, (EXACT << 1) | 1);
  FlatTypeMask.subclass(Entity base) : this.internal(base, (SUBCLASS << 1) | 1);
  FlatTypeMask.subtype(Entity base) : this.internal(base, (SUBTYPE << 1) | 1);

  const FlatTypeMask.nonNullEmpty()
      : base = null,
        flags = 0;
  const FlatTypeMask.empty()
      : base = null,
        flags = 1;

  FlatTypeMask.nonNullExact(Entity base) : this.internal(base, EXACT << 1);
  FlatTypeMask.nonNullSubclass(Entity base)
      : this.internal(base, SUBCLASS << 1);
  FlatTypeMask.nonNullSubtype(Entity base) : this.internal(base, SUBTYPE << 1);

  bool _validateBase(ClassElement element) => element.isDeclaration;

  FlatTypeMask.internal(this.base, this.flags) {
    assert(base == null || _validateBase(base));
  }

  /**
   * Ensures that the generated mask is normalized, i.e., a call to
   * [TypeMask.assertIsNormalized] with the factory's result returns `true`.
   */
  factory FlatTypeMask.normalized(Entity base, int flags, ClosedWorld world) {
    if ((flags >> 1) == EMPTY || ((flags >> 1) == EXACT)) {
      return new FlatTypeMask.internal(base, flags);
    }
    if ((flags >> 1) == SUBTYPE) {
      if (!world.hasAnyStrictSubtype(base) || world.hasOnlySubclasses(base)) {
        flags = (flags & 0x1) | (SUBCLASS << 1);
      }
    }
    if (((flags >> 1) == SUBCLASS) && !world.hasAnyStrictSubclass(base)) {
      flags = (flags & 0x1) | (EXACT << 1);
    }
    return world.getCachedMask(
        base, flags, () => new FlatTypeMask.internal(base, flags));
  }

  bool get isEmpty => isEmptyOrNull && !isNullable;
  bool get isNull => isEmptyOrNull && isNullable;
  bool get isEmptyOrNull => (flags >> 1) == EMPTY;
  bool get isExact => (flags >> 1) == EXACT;
  bool get isNullable => (flags & 1) != 0;

  bool get isUnion => false;
  bool get isContainer => false;
  bool get isMap => false;
  bool get isDictionary => false;
  bool get isForwarding => false;
  bool get isValue => false;

  // TODO(kasperl): Get rid of these. They should not be a visible
  // part of the implementation because they make it hard to add
  // proper union types if we ever want to.
  bool get isSubclass => (flags >> 1) == SUBCLASS;
  bool get isSubtype => (flags >> 1) == SUBTYPE;

  TypeMask nullable() {
    return isNullable ? this : new FlatTypeMask.internal(base, flags | 1);
  }

  TypeMask nonNullable() {
    return isNullable ? new FlatTypeMask.internal(base, flags & ~1) : this;
  }

  bool contains(Entity other, ClosedWorld closedWorld) {
    assert(_validateBase(other));
    if (isEmptyOrNull) {
      return false;
    } else if (identical(base, other)) {
      return true;
    } else if (isExact) {
      return false;
    } else if (isSubclass) {
      return closedWorld.isSubclassOf(other, base);
    } else {
      assert(isSubtype);
      return closedWorld.isSubtypeOf(other, base);
    }
  }

  bool isSingleImplementationOf(Entity cls, ClosedWorld closedWorld) {
    // Special case basic types so that, for example, JSString is the
    // single implementation of String.
    // The general optimization is to realize there is only one class that
    // implements [base] and [base] is not instantiated. We however do
    // not track correctly the list of truly instantiated classes.
    BackendClasses backendClasses = closedWorld.backendClasses;
    if (containsOnlyString(closedWorld)) {
      return cls == closedWorld.coreClasses.stringClass ||
          cls == backendClasses.stringImplementation;
    }
    if (containsOnlyBool(closedWorld)) {
      return cls == closedWorld.coreClasses.boolClass ||
          cls == backendClasses.boolImplementation;
    }
    if (containsOnlyInt(closedWorld)) {
      return cls == closedWorld.coreClasses.intClass ||
          cls == backendClasses.intImplementation ||
          cls == backendClasses.positiveIntImplementation ||
          cls == backendClasses.uint32Implementation ||
          cls == backendClasses.uint31Implementation;
    }
    if (containsOnlyDouble(closedWorld)) {
      return cls == closedWorld.coreClasses.doubleClass ||
          cls == backendClasses.doubleImplementation;
    }
    return false;
  }

  bool isInMask(TypeMask other, ClosedWorld closedWorld) {
    if (isEmptyOrNull) return isNullable ? other.isNullable : true;
    // The empty type contains no classes.
    if (other.isEmptyOrNull) return false;
    // Quick check whether to handle null.
    if (isNullable && !other.isNullable) return false;
    other = TypeMask.nonForwardingMask(other);
    // If other is union, delegate to UnionTypeMask.containsMask.
    if (other is! FlatTypeMask) return other.containsMask(this, closedWorld);
    // The other must be flat, so compare base and flags.
    FlatTypeMask flatOther = other;
    Entity otherBase = flatOther.base;
    // If other is exact, it only contains its base.
    // TODO(herhut): Get rid of isSingleImplementationOf.
    if (flatOther.isExact) {
      return (isExact && base == otherBase) ||
          isSingleImplementationOf(otherBase, closedWorld);
    }
    // If other is subclass, this has to be subclass, as well. Unless
    // flatOther.base covers all subtypes of this. Currently, we only
    // consider object to behave that way.
    // TODO(herhut): Add check whether flatOther.base is superclass of
    //               all subclasses of this.base.
    if (flatOther.isSubclass) {
      if (isSubtype) return (otherBase == closedWorld.coreClasses.objectClass);
      return closedWorld.isSubclassOf(base, otherBase);
    }
    assert(flatOther.isSubtype);
    // Check whether this TypeMask satisfies otherBase's interface.
    return satisfies(otherBase, closedWorld);
  }

  bool containsMask(TypeMask other, ClosedWorld closedWorld) {
    return other.isInMask(this, closedWorld);
  }

  bool containsOnlyInt(ClosedWorld closedWorld) {
    BackendClasses backendClasses = closedWorld.backendClasses;
    return base == closedWorld.coreClasses.intClass ||
        base == backendClasses.intImplementation ||
        base == backendClasses.positiveIntImplementation ||
        base == backendClasses.uint31Implementation ||
        base == backendClasses.uint32Implementation;
  }

  bool containsOnlyDouble(ClosedWorld closedWorld) {
    BackendClasses backendClasses = closedWorld.backendClasses;
    return base == closedWorld.coreClasses.doubleClass ||
        base == backendClasses.doubleImplementation;
  }

  bool containsOnlyNum(ClosedWorld closedWorld) {
    BackendClasses backendClasses = closedWorld.backendClasses;
    return containsOnlyInt(closedWorld) ||
        containsOnlyDouble(closedWorld) ||
        base == closedWorld.coreClasses.numClass ||
        base == backendClasses.numImplementation;
  }

  bool containsOnlyBool(ClosedWorld closedWorld) {
    BackendClasses backendClasses = closedWorld.backendClasses;
    return base == closedWorld.coreClasses.boolClass ||
        base == backendClasses.boolImplementation;
  }

  bool containsOnlyString(ClosedWorld closedWorld) {
    BackendClasses backendClasses = closedWorld.backendClasses;
    return base == closedWorld.coreClasses.stringClass ||
        base == backendClasses.stringImplementation;
  }

  bool containsOnly(Entity cls) {
    assert(_validateBase(cls));
    return base == cls;
  }

  bool satisfies(Entity cls, ClosedWorld closedWorld) {
    assert(_validateBase(cls));
    if (isEmptyOrNull) return false;
    if (closedWorld.isSubtypeOf(base, cls)) return true;
    return false;
  }

  /// Returns the [Entity] if this type represents a single class, otherwise
  /// returns `null`.  This method is conservative.
  Entity singleClass(ClosedWorld closedWorld) {
    if (isEmptyOrNull) return null;
    if (isNullable) return null; // It is Null and some other class.
    if (isExact) {
      return base;
    } else if (isSubclass) {
      return closedWorld.hasAnyStrictSubclass(base) ? null : base;
    } else {
      assert(isSubtype);
      return null;
    }
  }

  /**
   * Returns whether or not this type mask contains all types.
   */
  bool containsAll(ClosedWorld closedWorld) {
    if (isEmptyOrNull || isExact) return false;
    return identical(base, closedWorld.coreClasses.objectClass);
  }

  TypeMask union(TypeMask other, ClosedWorld closedWorld) {
    assert(other != null);
    assert(TypeMask.assertIsNormalized(this, closedWorld));
    assert(TypeMask.assertIsNormalized(other, closedWorld));
    if (other is! FlatTypeMask) return other.union(this, closedWorld);
    FlatTypeMask flatOther = other;
    if (isEmptyOrNull) {
      return isNullable ? flatOther.nullable() : flatOther;
    } else if (flatOther.isEmptyOrNull) {
      return flatOther.isNullable ? nullable() : this;
    } else if (base == flatOther.base) {
      return unionSame(flatOther, closedWorld);
    } else if (closedWorld.isSubclassOf(flatOther.base, base)) {
      return unionStrictSubclass(flatOther, closedWorld);
    } else if (closedWorld.isSubclassOf(base, flatOther.base)) {
      return flatOther.unionStrictSubclass(this, closedWorld);
    } else if (closedWorld.isSubtypeOf(flatOther.base, base)) {
      return unionStrictSubtype(flatOther, closedWorld);
    } else if (closedWorld.isSubtypeOf(base, flatOther.base)) {
      return flatOther.unionStrictSubtype(this, closedWorld);
    } else {
      return new UnionTypeMask._internal(<FlatTypeMask>[this, flatOther]);
    }
  }

  TypeMask unionSame(FlatTypeMask other, ClosedWorld closedWorld) {
    assert(base == other.base);
    assert(TypeMask.assertIsNormalized(this, closedWorld));
    assert(TypeMask.assertIsNormalized(other, closedWorld));
    // The two masks share the base type, so we must chose the least
    // constraining kind (the highest) of the two. If either one of
    // the masks are nullable the result should be nullable too.
    // As both masks are normalized, the result will be, too.
    int combined = (flags > other.flags)
        ? flags | (other.flags & 1)
        : other.flags | (flags & 1);
    if (flags == combined) {
      return this;
    } else if (other.flags == combined) {
      return other;
    } else {
      return new FlatTypeMask.normalized(base, combined, closedWorld);
    }
  }

  TypeMask unionStrictSubclass(FlatTypeMask other, ClosedWorld closedWorld) {
    assert(base != other.base);
    assert(closedWorld.isSubclassOf(other.base, base));
    assert(TypeMask.assertIsNormalized(this, closedWorld));
    assert(TypeMask.assertIsNormalized(other, closedWorld));
    int combined;
    if ((isExact && other.isExact) ||
        base == closedWorld.coreClasses.objectClass) {
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
    // If we weaken the constraint on this type, we have to make sure that
    // the result is normalized.
    return (flags != combined)
        ? new FlatTypeMask.normalized(base, combined, closedWorld)
        : this;
  }

  TypeMask unionStrictSubtype(FlatTypeMask other, ClosedWorld closedWorld) {
    assert(base != other.base);
    assert(!closedWorld.isSubclassOf(other.base, base));
    assert(closedWorld.isSubtypeOf(other.base, base));
    assert(TypeMask.assertIsNormalized(this, closedWorld));
    assert(TypeMask.assertIsNormalized(other, closedWorld));
    // Since the other mask is a subtype of this mask, we need the
    // resulting union to be a subtype too. If either one of the masks
    // are nullable the result should be nullable too.
    int combined = (SUBTYPE << 1) | ((flags | other.flags) & 1);
    // We know there is at least one subtype, [other.base], so no need
    // to normalize.
    return (flags != combined)
        ? new FlatTypeMask.normalized(base, combined, closedWorld)
        : this;
  }

  TypeMask intersection(TypeMask other, ClosedWorld closedWorld) {
    assert(other != null);
    if (other is! FlatTypeMask) return other.intersection(this, closedWorld);
    assert(TypeMask.assertIsNormalized(this, closedWorld));
    assert(TypeMask.assertIsNormalized(other, closedWorld));
    FlatTypeMask flatOther = other;
    if (isEmptyOrNull) {
      return flatOther.isNullable ? this : nonNullable();
    } else if (flatOther.isEmptyOrNull) {
      return isNullable ? flatOther : other.nonNullable();
    } else if (base == flatOther.base) {
      return intersectionSame(flatOther, closedWorld);
    } else if (closedWorld.isSubclassOf(flatOther.base, base)) {
      return intersectionStrictSubclass(flatOther, closedWorld);
    } else if (closedWorld.isSubclassOf(base, flatOther.base)) {
      return flatOther.intersectionStrictSubclass(this, closedWorld);
    } else if (closedWorld.isSubtypeOf(flatOther.base, base)) {
      return intersectionStrictSubtype(flatOther, closedWorld);
    } else if (closedWorld.isSubtypeOf(base, flatOther.base)) {
      return flatOther.intersectionStrictSubtype(this, closedWorld);
    } else {
      return intersectionDisjoint(flatOther, closedWorld);
    }
  }

  bool isDisjoint(TypeMask other, ClosedWorld closedWorld) {
    if (other is! FlatTypeMask) return other.isDisjoint(this, closedWorld);
    FlatTypeMask flatOther = other;

    if (isNullable && flatOther.isNullable) return false;
    if (isEmptyOrNull || flatOther.isEmptyOrNull) return true;
    if (base == flatOther.base) return false;
    if (isExact && flatOther.isExact) return true;

    if (isExact) return !flatOther.contains(base, closedWorld);
    if (flatOther.isExact) return !contains(flatOther.base, closedWorld);

    // Normalization guarantees that isExact === !isSubclass && !isSubtype.
    // Both are subclass or subtype masks, so if there is a subclass
    // relationship, they are not disjoint.
    if (closedWorld.isSubclassOf(flatOther.base, base)) return false;
    if (closedWorld.isSubclassOf(base, flatOther.base)) return false;

    // Two different base classes have no common subclass unless one is a
    // subclass of the other (checked above).
    if (isSubclass && flatOther.isSubclass) return true;

    return _isDisjointHelper(this, flatOther, closedWorld);
  }

  static bool _isDisjointHelper(
      FlatTypeMask a, FlatTypeMask b, ClosedWorld closedWorld) {
    if (!a.isSubclass && b.isSubclass) {
      return _isDisjointHelper(b, a, closedWorld);
    }
    assert(a.isSubclass || a.isSubtype);
    assert(b.isSubtype);
    var elements = a.isSubclass
        ? closedWorld.strictSubclassesOf(a.base)
        : closedWorld.strictSubtypesOf(a.base);
    for (var element in elements) {
      if (closedWorld.isSubtypeOf(element, b.base)) return false;
    }
    return true;
  }

  TypeMask intersectionSame(FlatTypeMask other, ClosedWorld closedWorld) {
    assert(base == other.base);
    // The two masks share the base type, so we must chose the most
    // constraining kind (the lowest) of the two. Only if both masks
    // are nullable, will the result be nullable too.
    // The result will be normalized, as the two inputs are normalized, too.
    int combined = (flags < other.flags)
        ? flags & ((other.flags & 1) | ~1)
        : other.flags & ((flags & 1) | ~1);
    if (flags == combined) {
      return this;
    } else if (other.flags == combined) {
      return other;
    } else {
      return new FlatTypeMask.normalized(base, combined, closedWorld);
    }
  }

  TypeMask intersectionStrictSubclass(
      FlatTypeMask other, ClosedWorld closedWorld) {
    assert(base != other.base);
    assert(closedWorld.isSubclassOf(other.base, base));
    // If this mask isn't at least a subclass mask, then the
    // intersection with the other mask is empty.
    if (isExact) return intersectionEmpty(other);
    // Only the other mask puts constraints on the intersection mask,
    // so base the combined flags on the other mask. Only if both
    // masks are nullable, will the result be nullable too.
    // The result is guaranteed to be normalized, as the other type
    // was normalized.
    int combined = other.flags & ((flags & 1) | ~1);
    if (other.flags == combined) {
      return other;
    } else {
      return new FlatTypeMask.normalized(other.base, combined, closedWorld);
    }
  }

  TypeMask intersectionStrictSubtype(
      FlatTypeMask other, ClosedWorld closedWorld) {
    assert(base != other.base);
    assert(closedWorld.isSubtypeOf(other.base, base));
    if (!isSubtype) return intersectionHelper(other, closedWorld);
    // Only the other mask puts constraints on the intersection mask,
    // so base the combined flags on the other mask. Only if both
    // masks are nullable, will the result be nullable too.
    // The result is guaranteed to be normalized, as the other type
    // was normalized.
    int combined = other.flags & ((flags & 1) | ~1);
    if (other.flags == combined) {
      return other;
    } else {
      return new FlatTypeMask.normalized(other.base, combined, closedWorld);
    }
  }

  TypeMask intersectionDisjoint(FlatTypeMask other, ClosedWorld closedWorld) {
    assert(base != other.base);
    assert(!closedWorld.isSubtypeOf(base, other.base));
    assert(!closedWorld.isSubtypeOf(other.base, base));
    return intersectionHelper(other, closedWorld);
  }

  TypeMask intersectionHelper(FlatTypeMask other, ClosedWorld closedWorld) {
    assert(base != other.base);
    assert(!closedWorld.isSubclassOf(base, other.base));
    assert(!closedWorld.isSubclassOf(other.base, base));
    // If one of the masks are exact or if both of them are subclass
    // masks, then the intersection is empty.
    if (isExact || other.isExact) return intersectionEmpty(other);
    if (isSubclass && other.isSubclass) return intersectionEmpty(other);
    assert(isSubtype || other.isSubtype);
    int kind = (isSubclass || other.isSubclass) ? SUBCLASS : SUBTYPE;
    // TODO(johnniwinther): Move this computation to [ClosedWorld].
    // Compute the set of classes that are contained in both type masks.
    Set<ClassElement> common = commonContainedClasses(this, other, closedWorld);
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
    // result will only be nullable if both masks are nullable. We have
    // to normalize here, as we generate types based on new base classes.
    int combined = (kind << 1) | (flags & other.flags & 1);
    Iterable<TypeMask> masks = candidates.map((Entity cls) {
      return new FlatTypeMask.normalized(cls, combined, closedWorld);
    });
    return UnionTypeMask.unionOf(masks, closedWorld);
  }

  TypeMask intersectionEmpty(FlatTypeMask other) {
    return isNullable && other.isNullable
        ? new TypeMask.empty()
        : new TypeMask.nonNullEmpty();
  }

  /**
   * Returns whether [element] is a potential target when being
   * invoked on this type mask. [selector] is used to ensure library
   * privacy is taken into account.
   */
  bool canHit(Element element, Selector selector, ClosedWorld closedWorld) {
    BackendClasses backendClasses = closedWorld.backendClasses;
    assert(element.name == selector.name);
    if (isEmpty) return false;
    if (isNull) {
      return closedWorld.hasElementIn(
          backendClasses.nullImplementation, selector, element);
    }

    // TODO(kasperl): Can't we just avoid creating typed selectors
    // based of function types?
    Element self = base;
    if (self.isTypedef) {
      // A typedef is a function type that doesn't have any
      // user-defined members.
      return false;
    }

    ClassElement other = element.enclosingClass;
    if (other == backendClasses.nullImplementation) {
      return isNullable;
    } else if (isExact) {
      return closedWorld.hasElementIn(self, selector, element);
    } else if (isSubclass) {
      return closedWorld.hasElementIn(self, selector, element) ||
          other.isSubclassOf(self) ||
          closedWorld.hasAnySubclassThatMixes(self, other);
    } else {
      assert(isSubtype);
      bool result = closedWorld.hasElementIn(self, selector, element) ||
          other.implementsInterface(self) ||
          closedWorld.hasAnySubclassThatImplements(other, base) ||
          closedWorld.hasAnySubclassOfMixinUseThatImplements(other, base);
      if (result) return true;
      // If the class is used as a mixin, we have to check if the element
      // can be hit from any of the mixin applications.
      Iterable<ClassElement> mixinUses = closedWorld.mixinUsesOf(self);
      return mixinUses.any((mixinApplication) =>
          closedWorld.hasElementIn(mixinApplication, selector, element) ||
          other.isSubclassOf(mixinApplication) ||
          closedWorld.hasAnySubclassThatMixes(mixinApplication, other));
    }
  }

  bool needsNoSuchMethodHandling(Selector selector, ClosedWorld closedWorld) {
    // A call on an empty type mask is either dead code, or a call on
    // `null`.
    if (isEmptyOrNull) return false;
    // A call on an exact mask for an abstract class is dead code.
    // TODO(johnniwinther): A type mask cannot be abstract. Remove the need
    // for this noise (currently used for super-calls in inference and mirror
    // usage).
    if (isExact && closedWorld.isAbstract(base)) return false;

    return closedWorld.needsNoSuchMethod(
        base,
        selector,
        isExact
            ? ClassQuery.EXACT
            : (isSubclass ? ClassQuery.SUBCLASS : ClassQuery.SUBTYPE));
  }

  Element locateSingleElement(Selector selector, Compiler compiler) {
    if (isEmptyOrNull) return null;
    Iterable<Element> targets =
        compiler.closedWorld.allFunctions.filter(selector, this);
    if (targets.length != 1) return null;
    Element result = targets.first;
    ClassElement enclosing = result.enclosingClass.declaration;
    // We only return the found element if it is guaranteed to be implemented on
    // all classes in the receiver type [this]. It could be found only in a
    // subclass or in an inheritance-wise unrelated class in case of subtype
    // selectors.
    ClosedWorld closedWorld = compiler.closedWorld;
    if (isSubtype) {
      // if (closedWorld.isUsedAsMixin(enclosing)) {
      if (closedWorld.everySubtypeIsSubclassOfOrMixinUseOf(base, enclosing)) {
        return result;
      }
      //}
      return null;
    } else {
      if (closedWorld.isSubclassOf(base, enclosing)) return result;
      if (closedWorld.isSubclassOfMixinUseOf(base, enclosing)) return result;
    }
    return null;
  }

  bool operator ==(var other) {
    if (identical(this, other)) return true;
    if (other is! FlatTypeMask) return false;
    FlatTypeMask otherMask = other;
    return (flags == otherMask.flags) && (base == otherMask.base);
  }

  int get hashCode {
    return (base == null ? 0 : base.hashCode) + 31 * flags.hashCode;
  }

  String toString() {
    if (isEmptyOrNull) return isNullable ? '[null]' : '[empty]';
    StringBuffer buffer = new StringBuffer();
    if (isNullable) buffer.write('null|');
    if (isExact) buffer.write('exact=');
    if (isSubclass) buffer.write('subclass=');
    if (isSubtype) buffer.write('subtype=');
    buffer.write(base.name);
    return "[$buffer]";
  }

  static Set<ClassElement> commonContainedClasses(
      FlatTypeMask x, FlatTypeMask y, ClosedWorld closedWorld) {
    Iterable<ClassElement> xSubset = containedSubset(x, closedWorld);
    if (xSubset == null) return null;
    Iterable<ClassElement> ySubset = containedSubset(y, closedWorld);
    if (ySubset == null) return null;
    return xSubset.toSet().intersection(ySubset.toSet());
  }

  static Iterable<ClassElement> containedSubset(
      FlatTypeMask x, ClosedWorld closedWorld) {
    ClassElement element = x.base;
    if (x.isExact) {
      return null;
    } else if (x.isSubclass) {
      return closedWorld.strictSubclassesOf(element);
    } else {
      assert(x.isSubtype);
      return closedWorld.strictSubtypesOf(element);
    }
  }
}
