// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of masks;

/// An implementation of a [UniverseSelectorConstraints] that is consists if an
/// only increasing set of [TypeMask]s, that is, once a mask is added it cannot
/// be removed.
class IncreasingTypeMaskSet extends UniverseSelectorConstraints {
  bool isAll = false;
  Set<TypeMask>? _masks;

  @override
  bool canHit(MemberEntity element, Name name, JClosedWorld world) {
    if (isAll) return true;
    if (_masks == null) return false;
    for (TypeMask mask in _masks!) {
      if (mask.canHit(element, name, world)) return true;
    }
    return false;
  }

  @override
  bool needsNoSuchMethodHandling(Selector selector, JClosedWorld world) {
    if (isAll) {
      TypeMask mask =
          TypeMask.subclass(world.commonElements.objectClass, world);
      return mask.needsNoSuchMethodHandling(selector, world);
    }
    for (TypeMask mask in _masks!) {
      if (mask.needsNoSuchMethodHandling(selector, world)) {
        return true;
      }
    }
    return false;
  }

  @override
  bool addReceiverConstraint(TypeMask? mask) {
    if (isAll) return false;
    if (mask == null) {
      isAll = true;
      _masks = null;
      return true;
    }
    return (_masks ??= {}).add(mask);
  }

  @override
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

class TypeMaskStrategy implements AbstractValueStrategy {
  const TypeMaskStrategy();

  @override
  AbstractValueDomain createDomain(JClosedWorld closedWorld) {
    return CommonMasks(closedWorld);
  }

  @override
  SelectorConstraintsStrategy createSelectorStrategy() {
    return TypeMaskSelectorStrategy();
  }
}

class TypeMaskSelectorStrategy implements SelectorConstraintsStrategy {
  const TypeMaskSelectorStrategy();

  @override
  UniverseSelectorConstraints createSelectorConstraints(
      Selector selector, covariant TypeMask? initialConstraint) {
    return IncreasingTypeMaskSet()..addReceiverConstraint(initialConstraint);
  }

  @override
  bool appliedUnnamed(DynamicUse dynamicUse, MemberEntity member,
      covariant JClosedWorld world) {
    Selector selector = dynamicUse.selector;
    final mask = dynamicUse.receiverConstraint as TypeMask?;
    return selector.appliesUnnamed(member) &&
        (mask == null || mask.canHit(member, selector.memberName, world));
  }
}

/// Enum used for identifying [TypeMask] subclasses in serialization.
enum TypeMaskKind {
  flat,
  union,
  container,
  set,
  map,
  dictionary,
  record,
  value,
}

/// A type mask represents a set of contained classes, but the
/// operations on it are not guaranteed to be precise and they may
/// yield conservative answers that contain too many classes.
abstract class TypeMask implements AbstractValue {
  const TypeMask();

  factory TypeMask.empty({bool hasLateSentinel = false}) =>
      FlatTypeMask.empty(hasLateSentinel: hasLateSentinel);

  factory TypeMask.exact(ClassEntity base, JClosedWorld closedWorld,
      {bool hasLateSentinel = false}) {
    assert(
        closedWorld.classHierarchy.isInstantiated(base),
        failedAt(
            base,
            "Cannot create exact type mask for uninstantiated "
            "class $base.\n${closedWorld.classHierarchy.dump(base)}"));
    return FlatTypeMask.exact(base, closedWorld,
        hasLateSentinel: hasLateSentinel);
  }

  factory TypeMask.exactOrEmpty(ClassEntity base, JClosedWorld closedWorld,
      {bool hasLateSentinel = false}) {
    if (closedWorld.classHierarchy.isInstantiated(base)) {
      return FlatTypeMask.exact(base, closedWorld,
          hasLateSentinel: hasLateSentinel);
    }
    return TypeMask.empty(hasLateSentinel: hasLateSentinel);
  }

  factory TypeMask.subclass(ClassEntity base, JClosedWorld closedWorld,
      {bool hasLateSentinel = false}) {
    assert(
        closedWorld.classHierarchy.isInstantiated(base),
        failedAt(
            base,
            "Cannot create subclass type mask for uninstantiated "
            "class $base.\n${closedWorld.classHierarchy.dump(base)}"));
    final topmost = closedWorld.getLubOfInstantiatedSubclasses(base);
    if (topmost == null) {
      return TypeMask.empty(hasLateSentinel: hasLateSentinel);
    } else if (closedWorld.classHierarchy.hasAnyStrictSubclass(topmost)) {
      return FlatTypeMask.subclass(topmost, closedWorld,
          hasLateSentinel: hasLateSentinel);
    } else {
      return TypeMask.exact(topmost, closedWorld,
          hasLateSentinel: hasLateSentinel);
    }
  }

  factory TypeMask.subtype(ClassEntity base, JClosedWorld closedWorld,
      {bool hasLateSentinel = false}) {
    final topmost = closedWorld.getLubOfInstantiatedSubtypes(base);
    if (topmost == null) {
      return TypeMask.empty(hasLateSentinel: hasLateSentinel);
    }
    if (closedWorld.classHierarchy.hasOnlySubclasses(topmost)) {
      return TypeMask.subclass(topmost, closedWorld,
          hasLateSentinel: hasLateSentinel);
    }
    if (closedWorld.classHierarchy.hasAnyStrictSubtype(topmost)) {
      return FlatTypeMask.subtype(topmost, closedWorld,
          hasLateSentinel: hasLateSentinel);
    } else {
      return TypeMask.exact(topmost, closedWorld,
          hasLateSentinel: hasLateSentinel);
    }
  }

  factory TypeMask.nonNullEmpty({bool hasLateSentinel = false}) =>
      FlatTypeMask.nonNullEmpty(hasLateSentinel: hasLateSentinel);

  factory TypeMask.nonNullExact(ClassEntity base, JClosedWorld closedWorld,
      {bool hasLateSentinel = false}) {
    assert(
        closedWorld.classHierarchy.isInstantiated(base),
        failedAt(
            base,
            "Cannot create exact type mask for uninstantiated "
            "class $base.\n${closedWorld.classHierarchy.dump(base)}"));
    return FlatTypeMask.nonNullExact(base, closedWorld,
        hasLateSentinel: hasLateSentinel);
  }

  factory TypeMask.nonNullExactOrEmpty(
      ClassEntity base, JClosedWorld closedWorld,
      {bool hasLateSentinel = false}) {
    if (closedWorld.classHierarchy.isInstantiated(base)) {
      return FlatTypeMask.nonNullExact(base, closedWorld,
          hasLateSentinel: hasLateSentinel);
    }
    return TypeMask.nonNullEmpty(hasLateSentinel: hasLateSentinel);
  }

  factory TypeMask.nonNullSubclass(ClassEntity base, JClosedWorld closedWorld,
      {bool hasLateSentinel = false}) {
    assert(
        closedWorld.classHierarchy.isInstantiated(base),
        failedAt(
            base,
            "Cannot create subclass type mask for uninstantiated "
            "class $base.\n${closedWorld.classHierarchy.dump(base)}"));
    final topmost = closedWorld.getLubOfInstantiatedSubclasses(base);
    if (topmost == null) {
      return TypeMask.nonNullEmpty(hasLateSentinel: hasLateSentinel);
    } else if (closedWorld.classHierarchy.hasAnyStrictSubclass(topmost)) {
      return FlatTypeMask.nonNullSubclass(topmost, closedWorld,
          hasLateSentinel: hasLateSentinel);
    } else {
      return TypeMask.nonNullExact(topmost, closedWorld,
          hasLateSentinel: hasLateSentinel);
    }
  }

  factory TypeMask.nonNullSubtype(ClassEntity base, JClosedWorld closedWorld,
      {bool hasLateSentinel = false}) {
    final topmost = closedWorld.getLubOfInstantiatedSubtypes(base);
    if (topmost == null) {
      return TypeMask.nonNullEmpty(hasLateSentinel: hasLateSentinel);
    }
    if (closedWorld.classHierarchy.hasOnlySubclasses(topmost)) {
      return TypeMask.nonNullSubclass(topmost, closedWorld,
          hasLateSentinel: hasLateSentinel);
    }
    if (closedWorld.classHierarchy.hasAnyStrictSubtype(topmost)) {
      return FlatTypeMask.nonNullSubtype(topmost, closedWorld,
          hasLateSentinel: hasLateSentinel);
    } else {
      return TypeMask.nonNullExact(topmost, closedWorld,
          hasLateSentinel: hasLateSentinel);
    }
  }

  factory TypeMask.unionOf(Iterable<TypeMask> masks, CommonMasks domain) {
    return UnionTypeMask.unionOf(masks, domain);
  }

  /// Deserializes a [TypeMask] object from [source].
  factory TypeMask.readFromDataSource(
      DataSourceReader source, CommonMasks domain) {
    TypeMaskKind kind = source.readEnum(TypeMaskKind.values);
    switch (kind) {
      case TypeMaskKind.flat:
        return FlatTypeMask.readFromDataSource(source, domain);
      case TypeMaskKind.union:
        return UnionTypeMask.readFromDataSource(source, domain);
      case TypeMaskKind.container:
        return ContainerTypeMask.readFromDataSource(source, domain);
      case TypeMaskKind.set:
        return SetTypeMask.readFromDataSource(source, domain);
      case TypeMaskKind.map:
        return MapTypeMask.readFromDataSource(source, domain);
      case TypeMaskKind.dictionary:
        return DictionaryTypeMask.readFromDataSource(source, domain);
      case TypeMaskKind.record:
        return RecordTypeMask.readFromDataSource(source, domain);
      case TypeMaskKind.value:
        return ValueTypeMask.readFromDataSource(source, domain);
    }
  }

  /// Serializes this [TypeMask] to [sink].
  void writeToDataSink(DataSinkWriter sink);

  /// If [mask] is forwarding, returns the first non-forwarding [TypeMask] in
  /// [mask]'s forwarding chain.
  static TypeMask nonForwardingMask(TypeMask mask) {
    while (mask is ForwardingTypeMask) {
      mask = mask.forwardTo;
    }
    return mask;
  }

  /// Asserts that this mask uses the smallest possible representation for
  /// its types. Currently, we normalize subtype and subclass to exact if no
  /// subtypes or subclasses are present and subtype to subclass if only
  /// subclasses exist. We also normalize exact to empty if the corresponding
  /// baseclass was never instantiated.
  static bool assertIsNormalized(TypeMask mask, JClosedWorld closedWorld) {
    final reason = getNotNormalizedReason(mask, closedWorld);
    assert(reason == null,
        failedAt(NO_LOCATION_SPANNABLE, '$mask is not normalized: $reason'));
    return true;
  }

  static String? getNotNormalizedReason(
      TypeMask mask, JClosedWorld closedWorld) {
    mask = nonForwardingMask(mask);
    if (mask is FlatTypeMask) {
      if (mask.isEmptyOrFlagged) return null;
      if (mask.base == closedWorld.commonElements.nullClass) {
        return 'The class ${mask.base} is not canonicalized.';
      }
      if (mask.isExact) {
        if (!closedWorld.classHierarchy.isInstantiated(mask.base!)) {
          return 'Exact ${mask.base} is not instantiated.';
        }
        return null;
      }
      if (mask.isSubclass) {
        if (!closedWorld.classHierarchy.hasAnyStrictSubclass(mask.base!)) {
          return 'Subclass ${mask.base} does not have any subclasses.';
        }
        return null;
      }
      assert(mask.isSubtype);
      if (!closedWorld.classHierarchy.hasAnyStrictSubtype(mask.base!)) {
        return 'Subtype ${mask.base} does not have any subclasses.';
      }
      if (closedWorld.classHierarchy.hasOnlySubclasses(mask.base!)) {
        return 'Subtype ${mask.base} only has subclasses.';
      }
      return null;
    } else if (mask is UnionTypeMask) {
      for (TypeMask submask in mask.disjointMasks) {
        final submaskReason = getNotNormalizedReason(submask, closedWorld);
        if (submaskReason != null) {
          return 'Submask $submask in $mask: $submaskReason.';
        }
      }
      return null;
    } else if (mask is RecordTypeMask) {
      for (TypeMask submask in mask.types) {
        final submaskReason = getNotNormalizedReason(submask, closedWorld);
        if (submaskReason != null) {
          return 'Submask $submask in $mask: $submaskReason.';
        }
      }
      return null;
    }
    return 'Unknown type mask $mask.';
  }

  /// Returns a nullable variant of [this] type mask.
  TypeMask nullable() => withFlags(isNullable: true);

  /// Returns a non-nullable variant of [this] type mask.
  TypeMask nonNullable() => withFlags(isNullable: false);

  /// Returns a variant of [this] type mask whose value is neither `null` nor
  /// the late sentinel.
  TypeMask withoutFlags() =>
      withFlags(isNullable: false, hasLateSentinel: false);

  TypeMask withFlags({bool? isNullable, bool? hasLateSentinel});

  /// Whether nothing matches this mask, not even null.
  bool get isEmpty;

  /// Whether null is a valid value of this mask.
  bool get isNullable;

  /// Whether the only possible value in this mask is Null.
  bool get isNull;

  /// Whether [this] is a sentinel for an uninitialized late variable.
  AbstractBool get isLateSentinel;

  /// Whether a late sentinel is a valid value of this mask.
  bool get hasLateSentinel => isLateSentinel.isPotentiallyTrue;

  /// Whether [this] mask is empty or only represents values tracked by flags
  /// (i.e. `null` and the late sentinel).
  bool get isEmptyOrFlagged;

  /// Whether this mask only includes instances of an exact class, and none of
  /// it's subclasses or subtypes.
  bool get isExact;

  bool containsOnlyInt(JClosedWorld closedWorld);
  bool containsOnlyNum(JClosedWorld closedWorld);
  bool containsOnlyBool(JClosedWorld closedWorld);
  bool containsOnlyString(JClosedWorld closedWorld);
  bool containsOnly(ClassEntity cls);

  /// Compares two [TypeMask] objects for structural equality.
  ///
  /// Note: This may differ from semantic equality in the set containment sense.
  ///   Use [containsMask] and [isInMask] for that, instead.
  @override
  bool operator ==(other);

  /// If this returns `true`, [other] is guaranteed to be a supertype of this
  /// mask, i.e., this mask is in [other]. However, the inverse does not hold.
  /// Enable [UnionTypeMask.PERFORM_EXTRA_CONTAINS_CHECK] to be notified of
  /// false negatives.
  bool isInMask(TypeMask other, JClosedWorld closedWorld);

  /// If this returns `true`, [other] is guaranteed to be a subtype of this
  /// mask, i.e. this mask contains [other]. However, the inverse does not hold.
  /// Enable [UnionTypeMask.PERFORM_EXTRA_CONTAINS_CHECK] to be notified of
  /// false negatives.
  bool containsMask(TypeMask other, JClosedWorld closedWorld);

  /// Returns whether this type mask is an instance of [cls].
  bool satisfies(ClassEntity cls, JClosedWorld closedWorld);

  /// Returns whether or not this type mask contains the given class [cls].
  bool contains(ClassEntity cls, JClosedWorld closedWorld);

  /// Returns whether or not this type mask contains all types.
  bool containsAll(JClosedWorld closedWorld);

  /// Returns the [ClassEntity] if this type represents a single class,
  /// otherwise returns `null`.  This method is conservative.
  ClassEntity? singleClass(JClosedWorld closedWorld);

  /// Returns a type mask representing the union of [this] and [other].
  TypeMask union(TypeMask other, CommonMasks domain);

  /// Returns whether the intersection of this and [other] is empty.
  bool isDisjoint(TypeMask other, JClosedWorld closedWorld);

  /// Returns a type mask representing the intersection of [this] and [other].
  TypeMask intersection(TypeMask other, CommonMasks domain);

  /// Returns whether [element] is a potential target when being invoked on this
  /// type mask.
  ///
  ///
  /// [name] is used to ensure library privacy is taken into account.
  bool canHit(MemberEntity element, Name name, JClosedWorld closedWorld);

  /// Returns whether this [TypeMask] applied to [selector] can hit a
  /// [noSuchMethod].
  bool needsNoSuchMethodHandling(Selector selector, JClosedWorld world);

  /// Returns the [element] that is known to always be hit at runtime
  /// on this mask. Returns null if there is none.
  MemberEntity? locateSingleMember(Selector selector, CommonMasks domain);

  /// Returns a set of members that are ancestors of all possible targets for
  /// a call targeting [selector] on a receiver with the type represented by
  /// this mask.
  Iterable<DynamicCallTarget> findRootsOfTargets(Selector selector,
      MemberHierarchyBuilder memberHierarchyBuilder, JClosedWorld closedWorld);
}
