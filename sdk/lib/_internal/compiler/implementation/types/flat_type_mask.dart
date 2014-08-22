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

  bool contains(ClassElement type, Compiler compiler) {
    assert(type.isDeclaration);
    if (isEmpty) {
      return false;
    } else if (identical(base, type)) {
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

  bool isSingleImplementationOf(ClassElement cls, Compiler compiler) {
    // Special case basic types so that, for example, JSString is the
    // single implementation of String.
    // The general optimization is to realize there is only one class that
    // implements [base] and [base] is not instantiated. We however do
    // not track correctly the list of truly instantiated classes.
    Backend backend = compiler.backend;
    if (containsOnlyString(compiler)) {
      return cls == compiler.stringClass || cls == backend.stringImplementation;
    }
    if (containsOnlyBool(compiler)) {
      return cls == compiler.boolClass || cls == backend.boolImplementation;
    }
    if (containsOnlyInt(compiler)) {
      return cls == compiler.intClass
          || cls == backend.intImplementation
          || cls == backend.positiveIntImplementation
          || cls == backend.uint32Implementation
          || cls == backend.uint31Implementation;
    }
    if (containsOnlyDouble(compiler)) {
      return cls == compiler.doubleClass
          || cls == compiler.backend.doubleImplementation;
    }
    return false;
  }

  bool isInMask(TypeMask other, Compiler compiler) {
    // null is treated separately, so the empty mask might still contain it.
    if (isEmpty) return isNullable ? other.isNullable : true;
    // The empty type contains no classes.
    if (other.isEmpty) return false;
    // Quick check whether to handle null.
    if (isNullable && !other.isNullable) return false;
    other = TypeMask.nonForwardingMask(other);
    // If other is union, delegate to UnionTypeMask.containsMask.
    if (other is! FlatTypeMask) return other.containsMask(this, compiler);
    // The other must be flat, so compare base and flags.
    FlatTypeMask flatOther = other;
    ClassElement otherBase = flatOther.base;
    // If other is exact, it only contains its base.
    // TODO(herhut): Get rid of isSingleImplementationOf.
    if (flatOther.isExact) {
      return (isExact && base == otherBase)
          || isSingleImplementationOf(otherBase, compiler);
    }
    // If other is subclass, this has to be subclass, as well. Unless
    // flatOther.base covers all subtypes of this. Currently, we only
    // consider object to behave that way.
    // TODO(herhut): Add check whether flatOther.base is superclass of
    //               all subclasses of this.base.
    if (flatOther.isSubclass) {
      if (isSubtype) return (otherBase == compiler.objectClass);
      return base == otherBase || isSubclassOf(base, otherBase, compiler);
    }
    assert(flatOther.isSubtype);
    // Check whether this TypeMask satisfies otherBase's interface.
    return satisfies(otherBase, compiler);
  }

  bool containsMask(TypeMask other, Compiler compiler) {
    return other.isInMask(this, compiler);
  }

  bool containsOnlyInt(Compiler compiler) {
    return base == compiler.intClass
        || base == compiler.backend.intImplementation
        || base == compiler.backend.positiveIntImplementation
        || base == compiler.backend.uint31Implementation
        || base == compiler.backend.uint32Implementation;
  }

  bool containsOnlyDouble(Compiler compiler) {
    return base == compiler.doubleClass
        || base == compiler.backend.doubleImplementation;
  }

  bool containsOnlyNum(Compiler compiler) {
    return containsOnlyInt(compiler)
        || containsOnlyDouble(compiler)
        || base == compiler.numClass
        || base == compiler.backend.numImplementation;
  }

  bool containsOnlyBool(Compiler compiler) {
    return base == compiler.boolClass
        || base == compiler.backend.boolImplementation;
  }

  bool containsOnlyString(Compiler compiler) {
    return base == compiler.stringClass
        || base == compiler.backend.stringImplementation;
  }

  bool containsOnly(ClassElement cls) {
    assert(cls.isDeclaration);
    return base == cls;
  }

  bool satisfies(ClassElement cls, Compiler compiler) {
    assert(cls.isDeclaration);
    if (isEmpty) return false;
    if (base == cls) return true;
    if (isSubtypeOf(base, cls, compiler)) return true;
    return false;
  }

  /**
   * Returns the [ClassElement] if this type represents a single class,
   * otherwise returns `null`.  This method is conservative.
   */
  ClassElement singleClass(Compiler compiler) {
    if (isEmpty) return null;
    if (isNullable) return null;  // It is Null and some other class.
    if (isExact) {
      return base;
    } else if (isSubclass) {
      return compiler.world.hasAnySubclass(base) ? null : base;
    } else {
      assert(isSubtype);
      return null;
    }
  }

  /**
   * Returns whether or not this type mask contains all types.
   */
  bool containsAll(Compiler compiler) {
    if (isEmpty || isExact) return false;
    return identical(base, compiler.objectClass);
  }

  TypeMask union(TypeMask other, Compiler compiler) {
    assert(other != null);
    assert(TypeMask.isNormalized(this, compiler.world));
    assert(TypeMask.isNormalized(other, compiler.world));
    if (other is! FlatTypeMask) return other.union(this, compiler);
    FlatTypeMask flatOther = other;
    if (isEmpty) {
      return isNullable ? flatOther.nullable() : flatOther;
    } else if (flatOther.isEmpty) {
      return flatOther.isNullable ? nullable() : this;
    } else if (base == flatOther.base) {
      return unionSame(flatOther, compiler);
    } else if (isSubclassOf(flatOther.base, base, compiler)) {
      return unionSubclass(flatOther, compiler);
    } else if (isSubclassOf(base, flatOther.base, compiler)) {
      return flatOther.unionSubclass(this, compiler);
    } else if (isSubtypeOf(flatOther.base, base, compiler)) {
      return unionSubtype(flatOther, compiler);
    } else if (isSubtypeOf(base, flatOther.base, compiler)) {
      return flatOther.unionSubtype(this, compiler);
    } else {
      return new UnionTypeMask._internal(<FlatTypeMask>[this, flatOther]);
    }
  }

  TypeMask unionSame(FlatTypeMask other, Compiler compiler) {
    assert(base == other.base);
    assert(TypeMask.isNormalized(this, compiler.world));
    assert(TypeMask.isNormalized(other, compiler.world));
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

  TypeMask unionSubclass(FlatTypeMask other, Compiler compiler) {
    assert(isSubclassOf(other.base, base, compiler));
    assert(TypeMask.isNormalized(this, compiler.world));
    assert(TypeMask.isNormalized(other, compiler.world));
    int combined;
    if ((isExact && other.isExact) || base == compiler.objectClass) {
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
            : new FlatTypeMask.normalized(base, combined, compiler.world)
        : this;
  }

  TypeMask unionSubtype(FlatTypeMask other, Compiler compiler) {
    assert(!isSubclassOf(other.base, base, compiler));
    assert(isSubtypeOf(other.base, base, compiler));
    assert(TypeMask.isNormalized(this, compiler.world));
    assert(TypeMask.isNormalized(other, compiler.world));
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

  TypeMask intersection(TypeMask other, Compiler compiler) {
    assert(other != null);
    if (other is! FlatTypeMask) return other.intersection(this, compiler);
    assert(TypeMask.isNormalized(this, compiler.world));
    assert(TypeMask.isNormalized(other, compiler.world));
    FlatTypeMask flatOther = other;
    if (isEmpty) {
      return flatOther.isNullable ? this : nonNullable();
    } else if (flatOther.isEmpty) {
      return isNullable ? flatOther : other.nonNullable();
    } else if (base == flatOther.base) {
      return intersectionSame(flatOther, compiler);
    } else if (isSubclassOf(flatOther.base, base, compiler)) {
      return intersectionSubclass(flatOther, compiler);
    } else if (isSubclassOf(base, flatOther.base, compiler)) {
      return flatOther.intersectionSubclass(this, compiler);
    } else if (isSubtypeOf(flatOther.base, base, compiler)) {
      return intersectionSubtype(flatOther, compiler);
    } else if (isSubtypeOf(base, flatOther.base, compiler)) {
      return flatOther.intersectionSubtype(this, compiler);
    } else {
      return intersectionDisjoint(flatOther, compiler);
    }
  }

  TypeMask intersectionSame(FlatTypeMask other, Compiler compiler) {
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

  TypeMask intersectionSubclass(FlatTypeMask other, Compiler compiler) {
    assert(isSubclassOf(other.base, base, compiler));
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

  TypeMask intersectionSubtype(FlatTypeMask other, Compiler compiler) {
    assert(isSubtypeOf(other.base, base, compiler));
    if (!isSubtype) return intersectionHelper(other, compiler);
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

  TypeMask intersectionDisjoint(FlatTypeMask other, Compiler compiler) {
    assert(base != other.base);
    assert(!isSubtypeOf(base, other.base, compiler));
    assert(!isSubtypeOf(other.base, base, compiler));
    return intersectionHelper(other, compiler);
  }

  TypeMask intersectionHelper(FlatTypeMask other, Compiler compiler) {
    assert(base != other.base);
    assert(!isSubclassOf(base, other.base, compiler));
    assert(!isSubclassOf(other.base, base, compiler));
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
    // result will only be nullable if both masks are nullable. We have
    // to normalize here, as we generate types based on new base classes.
    int combined = (kind << 1) | (flags & other.flags & 1);
    Iterable<TypeMask> masks = candidates.map((ClassElement cls) {
      return new FlatTypeMask.normalized(cls, combined, compiler.world);
    });
    return UnionTypeMask.unionOf(masks, compiler);
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
  bool canHit(Element element, Selector selector, World world) {
    assert(element.name == selector.name);
    if (isEmpty) {
      if (!isNullable) return false;
      return hasElementIn(world.nullImplementation, selector, element);
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
    if (other == world.nullImplementation) {
      return isNullable;
    } else if (isExact) {
      return hasElementIn(self, selector, element);
    } else if (isSubclass) {
      assert(world.isClosed);
      return hasElementIn(self, selector, element)
          || other.isSubclassOf(self)
          || world.hasAnySubclassThatMixes(self, other);
    } else {
      assert(isSubtype);
      assert(world.isClosed);
      bool result = hasElementIn(self, selector, element)
          || other.implementsInterface(self)
          || world.hasAnySubclassThatImplements(other, base)
          || world.hasAnySubclassOfMixinUseThatImplements(other, base);
      if (result) return true;
      // If the class is used as a mixin, we have to check if the element
      // can be hit from any of the mixin applications.
      Iterable<ClassElement> mixinUses = world.mixinUses[self];
      if (mixinUses == null) return false;
      return mixinUses.any((mixinApplication) =>
           hasElementIn(mixinApplication, selector, element)
        || other.isSubclassOf(mixinApplication)
        || world.hasAnySubclassThatMixes(mixinApplication, other));
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

  bool needsNoSuchMethodHandling(Selector selector, World world) {
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
      if (!world.compiler.enqueuer.resolution.isInstantiated(cls)) {
        return false;
      }
      // We can just skip abstract classes because we know no
      // instance of them will be created at runtime, and
      // therefore there is no instance that will require
      // [noSuchMethod] handling.
      return !cls.isAbstract
          && !hasConcreteMatch(cls, selector, world);
    }

    bool baseNeedsNoSuchMethod = needsNoSuchMethod(base);
    if (isExact || baseNeedsNoSuchMethod) {
      return baseNeedsNoSuchMethod;
    }

    Iterable<ClassElement> subclassesToCheck;
    if (isSubtype) {
      subclassesToCheck = world.subtypesOf(base);
    } else {
      assert(isSubclass);
      subclassesToCheck = world.subclassesOf(base);
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

  static bool isSubclassOf(ClassElement x, ClassElement y, Compiler compiler) {
    assert(x.isDeclaration && y.isDeclaration);
    Set<ClassElement> subclasses = compiler.world.subclassesOf(y);
    return (subclasses != null) ? subclasses.contains(x) : false;
  }

  static bool isSubtypeOf(ClassElement x, ClassElement y, Compiler compiler) {
    assert(x.isDeclaration && y.isDeclaration);
    Set<ClassElement> subtypes = compiler.world.subtypesOf(y);
    if (subtypes != null && subtypes.contains(x)) return true;
    if (y != compiler.functionClass) return false;
    return x.callType != null;
  }

  static Set<ClassElement> commonContainedClasses(FlatTypeMask x,
                                                  FlatTypeMask y,
                                                  Compiler compiler) {
    Set<ClassElement> xSubset = containedSubset(x, compiler);
    if (xSubset == null) return null;
    Set<ClassElement> ySubset = containedSubset(y, compiler);
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

  static Set<ClassElement> containedSubset(FlatTypeMask x, Compiler compiler) {
    ClassElement element = x.base;
    if (x.isExact) {
      return null;
    } else if (x.isSubclass) {
      return compiler.world.subclassesOf(element);
    } else {
      assert(x.isSubtype);
      return compiler.world.subtypesOf(element);
    }
  }
}
