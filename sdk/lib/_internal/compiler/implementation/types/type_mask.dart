// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of types;

/**
 * A type mask represents a set of contained classes, but the
 * operations on it are not guaranteed to be precise and they may
 * yield conservative answers that contain too many classes.
 */
abstract class TypeMask {
  factory TypeMask(ClassElement base,
                   int kind,
                   bool isNullable,
                   ClassWorld classWorld) {
    return new FlatTypeMask.normalized(
        base, (kind << 1) | (isNullable ? 1 : 0), classWorld);
  }

  const factory TypeMask.empty() = FlatTypeMask.empty;

  factory TypeMask.exact(ClassElement base, ClassWorld classWorld) {
    assert(invariant(base, classWorld.isInstantiated(base),
        message: "Cannot create extact type mask for uninstantiated class"));
    return new FlatTypeMask.exact(base);
  }

  factory TypeMask.exactOrEmpty(ClassElement base, ClassWorld classWorld) {
    if (classWorld.isInstantiated(base)) return new FlatTypeMask.exact(base);
    return const TypeMask.empty();
  }

  factory TypeMask.subclass(ClassElement base, ClassWorld classWorld) {
    if (classWorld.hasAnySubclass(base)) {
      return new FlatTypeMask.subclass(base);
    } else {
      return new TypeMask.exactOrEmpty(base, classWorld);
    }
  }

  factory TypeMask.subtype(ClassElement base, ClassWorld classWorld) {
    if (classWorld.hasOnlySubclasses(base)) {
      return new TypeMask.subclass(base, classWorld);
    }
    if (classWorld.hasAnySubtype(base)) {
      return new FlatTypeMask.subtype(base);
    } else {
      return new TypeMask.exactOrEmpty(base, classWorld);
    }
  }

  const factory TypeMask.nonNullEmpty() = FlatTypeMask.nonNullEmpty;

  factory TypeMask.nonNullExact(ClassElement base, ClassWorld classWorld) {
    assert(invariant(base, classWorld.isInstantiated(base),
        message: "Cannot create extact type mask for uninstantiated class"));
    return new FlatTypeMask.nonNullExact(base);
  }

  factory TypeMask.nonNullExactOrEmpty(ClassElement base,
      ClassWorld classWorld) {
    if (classWorld.isInstantiated(base)) {
      return new FlatTypeMask.nonNullExact(base);
    }
    return const TypeMask.nonNullEmpty();
  }

  factory TypeMask.nonNullSubclass(ClassElement base, ClassWorld classWorld) {
    if (classWorld.hasAnySubclass(base)) {
      return new FlatTypeMask.nonNullSubclass(base);
    } else {
      return new TypeMask.nonNullExactOrEmpty(base, classWorld);
    }
  }

  factory TypeMask.nonNullSubtype(ClassElement base, ClassWorld classWorld) {
    if (classWorld.hasOnlySubclasses(base)) {
      return new TypeMask.nonNullSubclass(base, classWorld);
    }
    if (classWorld.hasAnySubtype(base)) {
      return new FlatTypeMask.nonNullSubtype(base);
    } else {
      return new TypeMask.nonNullExactOrEmpty(base, classWorld);
    }
  }

  factory TypeMask.unionOf(Iterable<TypeMask> masks, ClassWorld classWorld) {
    return UnionTypeMask.unionOf(masks, classWorld);
  }

  /**
   * If [mask] is forwarding, returns the first non-forwarding [TypeMask] in
   * [mask]'s forwarding chain.
   */
  static TypeMask nonForwardingMask(mask) {
    while (mask.isForwarding) {
      mask = mask.forwardTo;
    }
    return mask;
  }

  /**
   * Checks whether this mask uses the smallest possible representation for
   * its types. Currently, we normalize subtype and subclass to exact if no
   * subtypes or subclasses are present and subtype to subclass if only
   * subclasses exist. We also normalize exact to empty if the corresponding
   * baseclass was never instantiated.
   */
  static bool isNormalized(TypeMask mask, ClassWorld classWorld) {
    mask = nonForwardingMask(mask);
    if (mask is FlatTypeMask) {
      if (mask.isEmpty) return true;
      if (mask.isExact) return classWorld.isInstantiated(mask.base);
      if (mask.isSubclass) return classWorld.hasAnySubclass(mask.base);
      assert(mask.isSubtype);
      return classWorld.hasAnySubtype(mask.base) &&
             !classWorld.hasOnlySubclasses(mask.base);
    } else if (mask is UnionTypeMask) {
      return mask.disjointMasks.every((mask) => isNormalized(mask, classWorld));
    }
    return false;
  }

  /**
   * Returns a nullable variant of [this] type mask.
   */
  TypeMask nullable();

  /**
   * Returns a non-nullable variant of [this] type mask.
   */
  TypeMask nonNullable();

  bool get isEmpty;
  bool get isNullable;
  bool get isExact;

  /// Returns true if this mask is a union type.
  bool get isUnion;

  /// Returns `true` if this mask is a [ContainerTypeMask].
  bool get isContainer;

  /// Returns `true` if this mask is a [MapTypeMask].
  bool get isMap;

  /// Returns `true` if this mask is a [MapTypeMask] in dictionary mode, i.e.,
  /// all keys are known string values and we have specific type information for
  /// corresponding values.
  bool get isDictionary;

  /// Returns `true` if this mask is wrapping another mask for the purpose of
  /// tracing.
  bool get isForwarding;

  /// Returns `true` if this mask holds encodes an exact value within a type.
  bool get isValue;

  bool containsOnlyInt(ClassWorld classWorld);
  bool containsOnlyDouble(ClassWorld classWorld);
  bool containsOnlyNum(ClassWorld classWorld);
  bool containsOnlyBool(ClassWorld classWorld);
  bool containsOnlyString(ClassWorld classWorld);
  bool containsOnly(ClassElement element);

  /**
   * Compares two [TypeMask] objects for structural equality.
   *
   * Note: This may differ from semantic equality in the set containment sense.
   *   Use [containsMask] and [isInMask] for that, instead.
   */
  bool operator==(other);

  /**
   * Returns `true` if [other] is a supertype of this mask, i.e., if
   * this mask is in [other].
   */
  bool isInMask(TypeMask other, ClassWorld classWorld);

  /**
   * Returns `true` if [other] is a subtype of this mask, i.e., if
   * this mask contains [other].
   */
  bool containsMask(TypeMask other, ClassWorld classWorld);

  /**
   * Returns whether this type mask is an instance of [cls].
   */
  bool satisfies(ClassElement cls, ClassWorld classWorld);

  /**
   * Returns whether or not this type mask contains the given type.
   */
  bool contains(ClassElement type, ClassWorld classWorld);

  /**
   * Returns whether or not this type mask contains all types.
   */
  bool containsAll(ClassWorld classWorld);

  /**
   * Returns the [ClassElement] if this type represents a single class,
   * otherwise returns `null`.  This method is conservative.
   */
  ClassElement singleClass(ClassWorld classWorld);

  /**
   * Returns a type mask representing the union of [this] and [other].
   */
  TypeMask union(TypeMask other, ClassWorld classWorld);

  /**
   * Returns a type mask representing the intersection of [this] and [other].
   */
  TypeMask intersection(TypeMask other, ClassWorld classWorld);

  /**
   * Returns whether this [TypeMask] applied to [selector] can hit a
   * [noSuchMethod].
   */
  bool needsNoSuchMethodHandling(Selector selector, ClassWorld classWorld);

  /**
   * Returns whether [element] is a potential target when being
   * invoked on this type mask. [selector] is used to ensure library
   * privacy is taken into account.
   */
  bool canHit(Element element, Selector selector, ClassWorld classWorld);

  /**
   * Returns the [element] that is known to always be hit at runtime
   * on this mask. Returns null if there is none.
   */
  // TODO(johnniwinther): Move this method to [World].
  Element locateSingleElement(Selector selector, Compiler compiler);
}
