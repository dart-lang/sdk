// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of types;

/// An implementation of a [UniverseSelectorConstraints] that is consists if an only
/// increasing set of [TypeMask]s, that is, once a mask is added it cannot be
/// removed.
class IncreasingTypeMaskSet extends UniverseSelectorConstraints {
  bool isAll = false;
  Set<TypeMask> _masks;

  @override
  bool applies(Element element, Selector selector, ClassWorld world) {
    if (isAll) return true;
    if (_masks == null) return false;
    for (TypeMask mask in _masks) {
      if (mask.canHit(element, selector, world)) return true;
    }
    return false;
  }

  @override
  bool needsNoSuchMethodHandling(Selector selector, ClassWorld world) {
    if (isAll) {
      TypeMask mask =
          new TypeMask.subclass(world.objectClass, world);
      return mask.needsNoSuchMethodHandling(selector, world);
    }
    for (TypeMask mask in _masks) {
      if (mask.needsNoSuchMethodHandling(selector, world)) {
        return true;
      }
    }
    return false;
  }

  @override
  bool addReceiverConstraint(TypeMask mask) {
    if (isAll) return false;
    if (mask == null) {
      isAll = true;
      _masks = null;
      return true;
    }
    if (_masks == null) {
      _masks = new Setlet<TypeMask>();
    }
    return _masks.add(mask);
  }

  String toString() {
    if (isAll) {
      return '<all>';
    } else if (_masks != null) {
      return '$_masks';
    } else {
      return '<none>';
    }
  }
}

class TypeMaskStrategy implements SelectorConstraintsStrategy {
  const TypeMaskStrategy();

  @override
  UniverseSelectorConstraints createSelectorConstraints(Selector selector) {
    return new IncreasingTypeMaskSet();
  }
}

/**
 * A type mask represents a set of contained classes, but the
 * operations on it are not guaranteed to be precise and they may
 * yield conservative answers that contain too many classes.
 */
abstract class TypeMask implements ReceiverConstraint, AbstractValue {
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
        message: () => "Cannot create exact type mask for uninstantiated "
                       "class $base.\n${classWorld.dump(base)}"));
    return new FlatTypeMask.exact(base);
  }

  factory TypeMask.exactOrEmpty(ClassElement base, ClassWorld classWorld) {
    if (classWorld.isInstantiated(base)) return new FlatTypeMask.exact(base);
    return const TypeMask.empty();
  }

  factory TypeMask.subclass(ClassElement base, ClassWorld classWorld) {
    assert(invariant(base, classWorld.isInstantiated(base),
        message: () => "Cannot create subclass type mask for uninstantiated "
                       "class $base.\n${classWorld.dump(base)}"));
    ClassElement topmost = classWorld.getLubOfInstantiatedSubclasses(base);
    if (topmost == null) {
      return new TypeMask.empty();
    } else if (classWorld.hasAnyStrictSubclass(topmost)) {
      return new FlatTypeMask.subclass(topmost);
    } else {
      return new TypeMask.exact(topmost, classWorld);
    }
  }

  factory TypeMask.subtype(ClassElement base, ClassWorld classWorld) {
    ClassElement topmost = classWorld.getLubOfInstantiatedSubtypes(base);
    if (topmost == null) {
      return new TypeMask.empty();
    }
    if (classWorld.hasOnlySubclasses(topmost)) {
      return new TypeMask.subclass(topmost, classWorld);
    }
    if (classWorld.hasAnyStrictSubtype(topmost)) {
      return new FlatTypeMask.subtype(topmost);
    } else {
      return new TypeMask.exact(topmost, classWorld);
    }
  }

  const factory TypeMask.nonNullEmpty() = FlatTypeMask.nonNullEmpty;

  factory TypeMask.nonNullExact(ClassElement base, ClassWorld classWorld) {
    assert(invariant(base, classWorld.isInstantiated(base),
        message: () => "Cannot create exact type mask for uninstantiated "
                       "class $base.\n${classWorld.dump(base)}"));
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
    assert(invariant(base, classWorld.isInstantiated(base),
        message: () => "Cannot create subclass type mask for uninstantiated "
                       "class $base.\n${classWorld.dump(base)}"));
    ClassElement topmost = classWorld.getLubOfInstantiatedSubclasses(base);
    if (topmost == null) {
      return new TypeMask.nonNullEmpty();
    } else if (classWorld.hasAnyStrictSubclass(topmost)) {
      return new FlatTypeMask.nonNullSubclass(topmost);
    } else {
      return new TypeMask.nonNullExact(topmost, classWorld);
    }
  }

  factory TypeMask.nonNullSubtype(ClassElement base, ClassWorld classWorld) {
    ClassElement topmost = classWorld.getLubOfInstantiatedSubtypes(base);
    if (topmost == null) {
      return new TypeMask.nonNullEmpty();
    }
    if (classWorld.hasOnlySubclasses(topmost)) {
      return new TypeMask.nonNullSubclass(topmost, classWorld);
    }
    if (classWorld.hasAnyStrictSubtype(topmost)) {
      return new FlatTypeMask.nonNullSubtype(topmost);
    } else {
      return new TypeMask.nonNullExact(topmost, classWorld);
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
   * Asserts that this mask uses the smallest possible representation for
   * its types. Currently, we normalize subtype and subclass to exact if no
   * subtypes or subclasses are present and subtype to subclass if only
   * subclasses exist. We also normalize exact to empty if the corresponding
   * baseclass was never instantiated.
   */
  static bool assertIsNormalized(TypeMask mask, ClassWorld classWorld) {
    String reason = getNotNormalizedReason(mask, classWorld);
    return invariant(NO_LOCATION_SPANNABLE, reason == null,
        message: () => '$mask is not normalized: $reason');
  }

  static String getNotNormalizedReason(TypeMask mask, ClassWorld classWorld) {
    mask = nonForwardingMask(mask);
    if (mask is FlatTypeMask) {
      if (mask.isEmptyOrNull) return null;
      if (mask.isExact) {
        if (!classWorld.isInstantiated(mask.base)) {
          return 'Exact ${mask.base} is not instantiated.';
        }
        return null;
      }
      if (mask.isSubclass) {
        if (!classWorld.hasAnyStrictSubclass(mask.base)) {
          return 'Subclass ${mask.base} does not have any subclasses.';
        }
        return null;
      }
      assert(mask.isSubtype);
      if (!classWorld.hasAnyStrictSubtype(mask.base)) {
        return 'Subtype ${mask.base} does not have any subclasses.';
      }
      if (classWorld.hasOnlySubclasses(mask.base)) {
        return 'Subtype ${mask.base} only has subclasses.';
      }
      return null;
    } else if (mask is UnionTypeMask) {
      for (TypeMask submask in mask.disjointMasks) {
        String submaskReason = getNotNormalizedReason(submask, classWorld);
        if (submaskReason != null) {
          return 'Submask $submask in $mask: $submaskReason.';
        }
      }
      return null;
    }
    return 'Unknown type mask $mask.';
  }

  /**
   * Returns a nullable variant of [this] type mask.
   */
  TypeMask nullable();

  /**
   * Returns a non-nullable variant of [this] type mask.
   */
  TypeMask nonNullable();

  /// Whether nothing matches this mask, not even null.
  bool get isEmpty;

  /// Whether null is a valid value of this mask.
  bool get isNullable;

  /// Whether the only possible value in this mask is Null.
  bool get isNull;

  /// Whether [isEmpty] or [isNull] is true.
  bool get isEmptyOrNull;

  /// Whether this mask only includes instances of an exact class, and none of
  /// it's subclasses or subtypes.
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
   * If this returns `true`, [other] is guaranteed to be a supertype of this
   * mask, i.e., this mask is in [other]. However, the inverse does not hold.
   * Enable [UnionTypeMask.PERFORM_EXTRA_CONTAINS_CHECK] to be notified of
   * false negatives.
   */
  bool isInMask(TypeMask other, ClassWorld classWorld);

  /**
   * If this returns `true`, [other] is guaranteed to be a subtype of this mask,
   * i.e., this mask contains [other]. However, the inverse does not hold.
   * Enable [UnionTypeMask.PERFORM_EXTRA_CONTAINS_CHECK] to be notified of
   * false negatives.
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


  /// Returns whether the intersection of this and [other] is empty.
  bool isDisjoint(TypeMask other, ClassWorld classWorld);

  /**
   * Returns a type mask representing the intersection of [this] and [other].
   */
  TypeMask intersection(TypeMask other, ClassWorld classWorld);

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
  Element locateSingleElement(
      Selector selector,
      TypeMask mask,
      Compiler compiler);
}
