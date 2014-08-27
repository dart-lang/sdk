// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of types;

/**
 * A flat type mask is a type mask that has been flatten to contain a
 * base type.
 */
class FlatTypeMask implements TypeMask {
  static const int EMPTY    = 0;
  static const int EXACT    = 1;
  static const int SUBCLASS = 2;
  static const int SUBTYPE  = 3;

  final ClassElement base;
  final int flags;

  FlatTypeMask(ClassElement base, int kind, bool isNullable)
      : this.internal(base, (kind << 1) | (isNullable ? 1 : 0));

  FlatTypeMask.exact(ClassElement base)
      : this.internal(base, (EXACT << 1) | 1);
  FlatTypeMask.subclass(ClassElement base)
      : this.internal(base, (SUBCLASS << 1) | 1);
  FlatTypeMask.subtype(ClassElement base)
      : this.internal(base, (SUBTYPE << 1) | 1);

  const FlatTypeMask.nonNullEmpty(): base = null, flags = 0;
  const FlatTypeMask.empty() : base = null, flags = 1;

  FlatTypeMask.nonNullExact(ClassElement base)
      : this.internal(base, EXACT << 1);
  FlatTypeMask.nonNullSubclass(ClassElement base)
      : this.internal(base, SUBCLASS << 1);
  FlatTypeMask.nonNullSubtype(ClassElement base)
      : this.internal(base, SUBTYPE << 1);

  FlatTypeMask.internal(this.base, this.flags) {
    assert(base == null || base.isDeclaration);
  }

  /**
   * Ensures that the generated mask is normalized, i.e., a call to
   * [TypeMask.isNormalized] with the factory's result returns `true`.
   */
  factory FlatTypeMask.normalized(ClassElement base, int flags, World world) {
    if ((flags >> 1) == EMPTY || ((flags >> 1) == EXACT)) {
      return new FlatTypeMask.internal(base, flags);
    }
    if ((flags >> 1) == SUBTYPE) {
      if (!world.hasAnySubtype(base) || world.hasOnlySubclasses(base)) {
        flags = (flags & 0x1) | (SUBCLASS << 1);
      }
    }
    if (((flags >> 1) == SUBCLASS) && !world.hasAnySubclass(base)) {
      flags = (flags & 0x1) | (EXACT << 1);
    }
    return new FlatTypeMask.internal(base, flags);
  }

  bool get isEmpty => (flags >> 1) == EMPTY;
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

  bool contains(ClassElement type, ClassWorld classWorld) {
    assert(type.isDeclaration);
    if (isEmpty) {
      return false;
    } else if (identical(base, type)) {
      return true;
    } else if (isExact) {
      return false;
    } else if (isSubclass) {
      return classWorld.isSubclassOf(type, base);
    } else {
      assert(isSubtype);
      return classWorld.isSubtypeOf(type, base);
    }
  }

  bool isSingleImplementationOf(ClassElement cls, ClassWorld classWorld) {
    // Special case basic types so that, for example, JSString is the
    // single implementation of String.
    // The general optimization is to realize there is only one class that
    // implements [base] and [base] is not instantiated. We however do
    // not track correctly the list of truly instantiated classes.
    Backend backend = classWorld.backend;
    if (containsOnlyString(classWorld)) {
      return cls == classWorld.stringClass ||
             cls == backend.stringImplementation;
    }
    if (containsOnlyBool(classWorld)) {
      return cls == classWorld.boolClass || cls == backend.boolImplementation;
    }
    if (containsOnlyInt(classWorld)) {
      return cls == classWorld.intClass
          || cls == backend.intImplementation
          || cls == backend.positiveIntImplementation
          || cls == backend.uint32Implementation
          || cls == backend.uint31Implementation;
    }
    if (containsOnlyDouble(classWorld)) {
      return cls == classWorld.doubleClass
          || cls == backend.doubleImplementation;
    }
    return false;
  }

  bool isInMask(TypeMask other, ClassWorld classWorld) {
    // null is treated separately, so the empty mask might still contain it.
    if (isEmpty) return isNullable ? other.isNullable : true;
    // The empty type contains no classes.
    if (other.isEmpty) return false;
    // Quick check whether to handle null.
    if (isNullable && !other.isNullable) return false;
    other = TypeMask.nonForwardingMask(other);
    // If other is union, delegate to UnionTypeMask.containsMask.
    if (other is! FlatTypeMask) return other.containsMask(this, classWorld);
    // The other must be flat, so compare base and flags.
    FlatTypeMask flatOther = other;
    ClassElement otherBase = flatOther.base;
    // If other is exact, it only contains its base.
    // TODO(herhut): Get rid of isSingleImplementationOf.
    if (flatOther.isExact) {
      return (isExact && base == otherBase)
          || isSingleImplementationOf(otherBase, classWorld);
    }
    // If other is subclass, this has to be subclass, as well. Unless
    // flatOther.base covers all subtypes of this. Currently, we only
    // consider object to behave that way.
    // TODO(herhut): Add check whether flatOther.base is superclass of
    //               all subclasses of this.base.
    if (flatOther.isSubclass) {
      if (isSubtype) return (otherBase == classWorld.objectClass);
      return classWorld.isSubclassOf(base, otherBase);
    }
    assert(flatOther.isSubtype);
    // Check whether this TypeMask satisfies otherBase's interface.
    return satisfies(otherBase, classWorld);
  }

  bool containsMask(TypeMask other, ClassWorld classWorld) {
    return other.isInMask(this, classWorld);
  }

  bool containsOnlyInt(ClassWorld classWorld) {
    Backend backend = classWorld.backend;
    return base == classWorld.intClass
        || base == backend.intImplementation
        || base == backend.positiveIntImplementation
        || base == backend.uint31Implementation
        || base == backend.uint32Implementation;
  }

  bool containsOnlyDouble(ClassWorld classWorld) {
    Backend backend = classWorld.backend;
    return base == classWorld.doubleClass
        || base == backend.doubleImplementation;
  }

  bool containsOnlyNum(ClassWorld classWorld) {
    Backend backend = classWorld.backend;
    return containsOnlyInt(classWorld)
        || containsOnlyDouble(classWorld)
        || base == classWorld.numClass
        || base == backend.numImplementation;
  }

  bool containsOnlyBool(ClassWorld classWorld) {
    Backend backend = classWorld.backend;
    return base == classWorld.boolClass
        || base == backend.boolImplementation;
  }

  bool containsOnlyString(ClassWorld classWorld) {
    Backend backend = classWorld.backend;
    return base == classWorld.stringClass
        || base == backend.stringImplementation;
  }

  bool containsOnly(ClassElement cls) {
    assert(cls.isDeclaration);
    return base == cls;
  }

  bool satisfies(ClassElement cls, ClassWorld classWorld) {
    assert(cls.isDeclaration);
    if (isEmpty) return false;
    if (classWorld.isSubtypeOf(base, cls)) return true;
    return false;
  }

  /**
   * Returns the [ClassElement] if this type represents a single class,
   * otherwise returns `null`.  This method is conservative.
   */
  ClassElement singleClass(ClassWorld classWorld) {
    if (isEmpty) return null;
    if (isNullable) return null;  // It is Null and some other class.
    if (isExact) {
      return base;
    } else if (isSubclass) {
      return classWorld.hasAnyStrictSubclass(base) ? null : base;
    } else {
      assert(isSubtype);
      return null;
    }
  }

  /**
   * Returns whether or not this type mask contains all types.
   */
  bool containsAll(ClassWorld classWorld) {
    if (isEmpty || isExact) return false;
    return identical(base, classWorld.objectClass);
  }

  TypeMask union(TypeMask other, ClassWorld classWorld) {
    assert(other != null);
    assert(TypeMask.isNormalized(this, classWorld));
    assert(TypeMask.isNormalized(other, classWorld));
    if (other is! FlatTypeMask) return other.union(this, classWorld);
    FlatTypeMask flatOther = other;
    if (isEmpty) {
      return isNullable ? flatOther.nullable() : flatOther;
    } else if (flatOther.isEmpty) {
      return flatOther.isNullable ? nullable() : this;
    } else if (base == flatOther.base) {
      return unionSame(flatOther, classWorld);
    } else if (classWorld.isSubclassOf(flatOther.base, base)) {
      return unionStrictSubclass(flatOther, classWorld);
    } else if (classWorld.isSubclassOf(base, flatOther.base)) {
      return flatOther.unionStrictSubclass(this, classWorld);
    } else if (classWorld.isSubtypeOf(flatOther.base, base)) {
      return unionStrictSubtype(flatOther, classWorld);
    } else if (classWorld.isSubtypeOf(base, flatOther.base)) {
      return flatOther.unionStrictSubtype(this, classWorld);
    } else {
      return new UnionTypeMask._internal(<FlatTypeMask>[this, flatOther]);
    }
  }

  TypeMask unionSame(FlatTypeMask other, ClassWorld classWorld) {
    assert(base == other.base);
    assert(TypeMask.isNormalized(this, classWorld));
    assert(TypeMask.isNormalized(other, classWorld));
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
      return new FlatTypeMask.internal(base, combined);
    }
  }

  TypeMask unionStrictSubclass(FlatTypeMask other, ClassWorld classWorld) {
    assert(base != other.base);
    assert(classWorld.isSubclassOf(other.base, base));
    assert(TypeMask.isNormalized(this, classWorld));
    assert(TypeMask.isNormalized(other, classWorld));
    int combined;
    if ((isExact && other.isExact) || base == classWorld.objectClass) {
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
        ? (combined >> 1 == flags >> 1)
            ? new FlatTypeMask.internal(base, combined)
            : new FlatTypeMask.normalized(base, combined, classWorld)
        : this;
  }

  TypeMask unionStrictSubtype(FlatTypeMask other, ClassWorld classWorld) {
    assert(base != other.base);
    assert(!classWorld.isSubclassOf(other.base, base));
    assert(classWorld.isSubtypeOf(other.base, base));
    assert(TypeMask.isNormalized(this, classWorld));
    assert(TypeMask.isNormalized(other, classWorld));
    // Since the other mask is a subtype of this mask, we need the
    // resulting union to be a subtype too. If either one of the masks
    // are nullable the result should be nullable too.
    int combined = (SUBTYPE << 1) | ((flags | other.flags) & 1);
    // We know there is at least one subtype, [other.base], so no need
    // to normalize.
    return (flags != combined)
        ? new FlatTypeMask.internal(base, combined)
        : this;
  }

  TypeMask intersection(TypeMask other, ClassWorld classWorld) {
    assert(other != null);
    if (other is! FlatTypeMask) return other.intersection(this, classWorld);
    assert(TypeMask.isNormalized(this, classWorld));
    assert(TypeMask.isNormalized(other, classWorld));
    FlatTypeMask flatOther = other;
    if (isEmpty) {
      return flatOther.isNullable ? this : nonNullable();
    } else if (flatOther.isEmpty) {
      return isNullable ? flatOther : other.nonNullable();
    } else if (base == flatOther.base) {
      return intersectionSame(flatOther);
    } else if (classWorld.isSubclassOf(flatOther.base, base)) {
      return intersectionStrictSubclass(flatOther, classWorld);
    } else if (classWorld.isSubclassOf(base, flatOther.base)) {
      return flatOther.intersectionStrictSubclass(this, classWorld);
    } else if (classWorld.isSubtypeOf(flatOther.base, base)) {
      return intersectionStrictSubtype(flatOther, classWorld);
    } else if (classWorld.isSubtypeOf(base, flatOther.base)) {
      return flatOther.intersectionStrictSubtype(this, classWorld);
    } else {
      return intersectionDisjoint(flatOther, classWorld);
    }
  }

  TypeMask intersectionSame(FlatTypeMask other) {
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
      return new FlatTypeMask.internal(base, combined);
    }
  }

  TypeMask intersectionStrictSubclass(FlatTypeMask other, ClassWorld world) {
    assert(base != other.base);
    assert(world.isSubclassOf(other.base, base));
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
      return new FlatTypeMask.internal(other.base, combined);
    }
  }

  TypeMask intersectionStrictSubtype(FlatTypeMask other,
                                     ClassWorld classWorld) {
    assert(base != other.base);
    assert(classWorld.isSubtypeOf(other.base, base));
    if (!isSubtype) return intersectionHelper(other, classWorld);
    // Only the other mask puts constraints on the intersection mask,
    // so base the combined flags on the other mask. Only if both
    // masks are nullable, will the result be nullable too.
    // The result is guaranteed to be normalized, as the other type
    // was normalized.
    int combined = other.flags & ((flags & 1) | ~1);
    if (other.flags == combined) {
      return other;
    } else {
      return new FlatTypeMask.internal(other.base, combined);
    }
  }

  TypeMask intersectionDisjoint(FlatTypeMask other, ClassWorld classWorld) {
    assert(base != other.base);
    assert(!classWorld.isSubtypeOf(base, other.base));
    assert(!classWorld.isSubtypeOf(other.base, base));
    return intersectionHelper(other, classWorld);
  }

  TypeMask intersectionHelper(FlatTypeMask other, ClassWorld classWorld) {
    assert(base != other.base);
    assert(!classWorld.isSubclassOf(base, other.base));
    assert(!classWorld.isSubclassOf(other.base, base));
    // If one of the masks are exact or if both of them are subclass
    // masks, then the intersection is empty.
    if (isExact || other.isExact) return intersectionEmpty(other);
    if (isSubclass && other.isSubclass) return intersectionEmpty(other);
    assert(isSubtype || other.isSubtype);
    int kind = (isSubclass || other.isSubclass) ? SUBCLASS : SUBTYPE;
    // Compute the set of classes that are contained in both type masks.
    Set<ClassElement> common = commonContainedClasses(this, other, classWorld);
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
    Iterable<TypeMask> masks = candidates.map((ClassElement cls) {
      return new FlatTypeMask.normalized(cls, combined, classWorld);
    });
    return UnionTypeMask.unionOf(masks, classWorld);
  }

  TypeMask intersectionEmpty(FlatTypeMask other) {
    return isNullable && other.isNullable ? new TypeMask.empty()
        : new TypeMask.nonNullEmpty();
  }

  /**
   * Returns whether [element] will be the one used at runtime when being
   * invoked on an instance of [cls]. [selector] is used to ensure library
   * privacy is taken into account.
   */
  static bool hasElementIn(ClassElement cls,
                           Selector selector,
                           Element element) {
    // Use [:implementation:] of [element]
    // because our function set only stores declarations.
    Element result = findMatchIn(cls, selector);
    return result == null
        ? false
        : result.implementation == element.implementation;
  }

  static Element findMatchIn(ClassElement cls,
                             Selector selector) {
    // Use the [:implementation] of [cls] in case the found [element]
    // is in the patch class.
    return cls.implementation.lookupSelector(selector);
  }

  /**
   * Returns whether [element] is a potential target when being
   * invoked on this type mask. [selector] is used to ensure library
   * privacy is taken into account.
   */
  bool canHit(Element element, Selector selector, ClassWorld classWorld) {
    // TODO(johnniwinther): Remove the need for [World].
    World world = classWorld.compiler.world;
    Backend backend = classWorld.backend;
    assert(element.name == selector.name);
    if (isEmpty) {
      if (!isNullable) return false;
      return hasElementIn(backend.nullImplementation, selector, element);
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
    if (other == backend.nullImplementation) {
      return isNullable;
    } else if (isExact) {
      return hasElementIn(self, selector, element);
    } else if (isSubclass) {
      assert(world.isClosed);
      return hasElementIn(self, selector, element)
          || other.isSubclassOf(self)
          || classWorld.hasAnySubclassThatMixes(self, other);
    } else {
      assert(isSubtype);
      assert(world.isClosed);
      bool result = hasElementIn(self, selector, element)
          || other.implementsInterface(self)
          || world.hasAnySubclassThatImplements(other, base)
          || classWorld.hasAnySubclassOfMixinUseThatImplements(other, base);
      if (result) return true;
      // If the class is used as a mixin, we have to check if the element
      // can be hit from any of the mixin applications.
      Iterable<ClassElement> mixinUses = classWorld.mixinUsesOf(self);
      return mixinUses.any((mixinApplication) =>
           hasElementIn(mixinApplication, selector, element)
        || other.isSubclassOf(mixinApplication)
        || classWorld.hasAnySubclassThatMixes(mixinApplication, other));
    }
  }

  /**
   * Returns whether a [selector] call on an instance of [cls]
   * will hit a method at runtime, and not go through [noSuchMethod].
   */
  static bool hasConcreteMatch(ClassElement cls,
                               Selector selector,
                               World world) {
    assert(invariant(cls,
        world.compiler.enqueuer.resolution.isInstantiated(cls),
        message: '$cls has not been instantiated.'));
    Element element = findMatchIn(cls, selector);
    if (element == null) return false;

    if (element.isAbstract) {
      ClassElement enclosingClass = element.enclosingClass;
      return hasConcreteMatch(enclosingClass.superclass, selector, world);
    }
    return selector.appliesUntyped(element, world);
  }

  bool needsNoSuchMethodHandling(Selector selector, ClassWorld classWorld) {
    // A call on an empty type mask is either dead code, or a call on
    // `null`.
    if (isEmpty) return false;
    // A call on an exact mask for an abstract class is dead code.
    if (isExact && base.isAbstract) return false;
    // If the receiver is guaranteed to have a member that
    // matches what we're looking for, there's no need to
    // introduce a noSuchMethod handler. It will never be called.
    //
    // As an example, consider this class hierarchy:
    //
    //                   A    <-- noSuchMethod
    //                  / \
    //                 C   B  <-- foo
    //
    // If we know we're calling foo on an object of type B we
    // don't have to worry about the noSuchMethod method in A
    // because objects of type B implement foo. On the other hand,
    // if we end up calling foo on something of type C we have to
    // add a handler for it.

    // If the holders of all user-defined noSuchMethod
    // implementations that might be applicable to the receiver
    // type have a matching member for the current name and
    // selector, we avoid introducing a noSuchMethod handler.
    //
    // As an example, consider this class hierarchy:
    //
    //                       A    <-- foo
    //                      / \
    //   noSuchMethod -->  B   C  <-- bar
    //                     |   |
    //                     C   D  <-- noSuchMethod
    //
    // When calling foo on an object of type A, we know that the
    // implementations of noSuchMethod are in the classes B and D
    // that also (indirectly) implement foo, so we do not need a
    // handler for it.
    //
    // If we're calling bar on an object of type D, we don't need
    // the handler either because all objects of type D implement
    // bar through inheritance.
    //
    // If we're calling bar on an object of type A we do need the
    // handler because we may have to call B.noSuchMethod since B
    // does not implement bar.

    /// Returns `true` if [cls] is an instantiated class that does not have
    /// a concrete method matching [selector].
    bool needsNoSuchMethod(ClassElement cls) {
      // We can skip uninstantiated subclasses.
      // TODO(johnniwinther): Put filtering into the (Class)World.
      if (!classWorld.isInstantiated(cls)) {
        return false;
      }
      // We can just skip abstract classes because we know no
      // instance of them will be created at runtime, and
      // therefore there is no instance that will require
      // [noSuchMethod] handling.
      return !cls.isAbstract
          && !hasConcreteMatch(cls, selector, classWorld);
    }

    bool baseNeedsNoSuchMethod = needsNoSuchMethod(base);
    if (isExact || baseNeedsNoSuchMethod) {
      return baseNeedsNoSuchMethod;
    }

    Iterable<ClassElement> subclassesToCheck;
    if (isSubtype) {
      subclassesToCheck = classWorld.subtypesOf(base);
    } else {
      assert(isSubclass);
      subclassesToCheck = classWorld.subclassesOf(base);
    }

    return subclassesToCheck != null &&
           subclassesToCheck.any(needsNoSuchMethod);
  }

  Element locateSingleElement(Selector selector, Compiler compiler) {
    if (isEmpty) return null;
    Iterable<Element> targets = compiler.world.allFunctions.filter(selector);
    if (targets.length != 1) return null;
    Element result = targets.first;
    ClassElement enclosing = result.enclosingClass;
    // We only return the found element if it is guaranteed to be
    // implemented on the exact receiver type. It could be found in a
    // subclass or in an inheritance-wise unrelated class in case of
    // subtype selectors.
    return (base.isSubclassOf(enclosing)) ? result : null;
  }

  bool operator ==(var other) {
    if (other is !FlatTypeMask) return false;
    FlatTypeMask otherMask = other;
    return (flags == otherMask.flags) && (base == otherMask.base);
  }

  int get hashCode {
    return (base == null ? 0 : base.hashCode) + 31 * flags.hashCode;
  }

  String toString() {
    if (isEmpty) return isNullable ? '[null]' : '[empty]';
    StringBuffer buffer = new StringBuffer();
    if (isNullable) buffer.write('null|');
    if (isExact) buffer.write('exact=');
    if (isSubclass) buffer.write('subclass=');
    if (isSubtype) buffer.write('subtype=');
    buffer.write(base.name);
    return "[$buffer]";
  }

  static Set<ClassElement> commonContainedClasses(FlatTypeMask x,
                                                  FlatTypeMask y,
                                                  ClassWorld classWorld) {
    Iterable<ClassElement> xSubset = containedSubset(x, classWorld);
    if (xSubset == null) return null;
    Iterable<ClassElement> ySubset = containedSubset(y, classWorld);
    if (ySubset == null) return null;
    Iterable<ClassElement> smallSet, largeSet;
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

  static Iterable<ClassElement> containedSubset(FlatTypeMask x,
                                                ClassWorld classWorld) {
    ClassElement element = x.base;
    if (x.isExact) {
      return null;
    } else if (x.isSubclass) {
      return classWorld.subclassesOf(element);
    } else {
      assert(x.isSubtype);
      return classWorld.subtypesOf(element);
    }
  }
}
