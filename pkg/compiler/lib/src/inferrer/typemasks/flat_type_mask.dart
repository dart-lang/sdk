// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'masks.dart';

enum FlatTypeMaskKind { empty, exact, subclass, subtype }

// The flags encode not only the powerset, but also the [FlatTypeMaskKind]. If
// we type both flags and powersets as [Bitset]s, we risk accidentally passing
// the wrong one when the other is expected. We can get type safety against this
// by introducing this extension type.
extension type _Flags(Bitset bitset) {}

/// A flat type mask is a type mask that has been flattened to contain a
/// base type.
class FlatTypeMask extends TypeMask {
  /// Tag used for identifying serialized [FlatTypeMask] objects in a
  /// debugging data stream.
  static const String tag = 'flat-type-mask';

  static final Bitset _nullBit = _specialValueDomain.fromValue(
    TypeMaskSpecialValue.null_,
  );
  static final Bitset _lateSentinelBit = _specialValueDomain.fromValue(
    TypeMaskSpecialValue.lateSentinel,
  );

  final ClassEntity? base;

  final _Flags _flags;

  static _Flags _computeFlags(FlatTypeMaskKind kind, Bitset powerset) =>
      _Flags(Bitset(kind.index << _powersetDomains.bitWidth | powerset.bits));

  static Bitset _powersetOfFlagsUnion(_Flags a, _Flags b) =>
      _getPowerset(_Flags(a.bitset.union(b.bitset)));

  static Bitset _powersetOfFlagsIntersection(_Flags a, _Flags b) =>
      _getPowerset(_Flags(_intersectPowersets(a.bitset, b.bitset)));

  static FlatTypeMaskKind _getKind(_Flags flags) =>
      FlatTypeMaskKind.values[flags.bitset.bits >> _powersetDomains.bitWidth];

  static Bitset _getPowerset(_Flags flags) =>
      _powersetDomains.restrict(flags.bitset);

  static EnumSet<TypeMaskSpecialValue> _composeSpecialValues({
    required bool isNullable,
    required bool hasLateSentinel,
  }) {
    var result = EnumSet<TypeMaskSpecialValue>.empty();
    if (isNullable) {
      result = result.add(TypeMaskSpecialValue.null_);
    }
    if (hasLateSentinel) {
      result = result.add(TypeMaskSpecialValue.lateSentinel);
    }
    return result;
  }

  factory FlatTypeMask.exact(
    ClassEntity base,
    CommonMasks domain, {
    bool hasLateSentinel = false,
  }) => FlatTypeMask._canonicalize(
    base,
    FlatTypeMaskKind.exact,
    _composeSpecialValues(isNullable: true, hasLateSentinel: hasLateSentinel),
    domain,
  );

  factory FlatTypeMask.subclass(
    ClassEntity base,
    CommonMasks domain, {
    bool hasLateSentinel = false,
  }) => FlatTypeMask._canonicalize(
    base,
    FlatTypeMaskKind.subclass,
    _composeSpecialValues(isNullable: true, hasLateSentinel: hasLateSentinel),
    domain,
  );

  factory FlatTypeMask.subtype(
    ClassEntity base,
    CommonMasks domain, {
    bool hasLateSentinel = false,
  }) => FlatTypeMask._canonicalize(
    base,
    FlatTypeMaskKind.subtype,
    _composeSpecialValues(isNullable: true, hasLateSentinel: hasLateSentinel),
    domain,
  );

  factory FlatTypeMask._emptyOrSpecial(CommonMasks domain, Bitset powerset) {
    assert(_isEmptyOrSpecialPowerset(powerset));
    return FlatTypeMask._cached(
      null,
      _computeFlags(FlatTypeMaskKind.empty, powerset),
      domain,
    );
  }

  factory FlatTypeMask.nonNullEmpty(
    CommonMasks domain, {
    bool hasLateSentinel = false,
  }) {
    final powerset = hasLateSentinel
        ? _specialValueDomain.fromValue(TypeMaskSpecialValue.lateSentinel)
        : Bitset.empty();

    return FlatTypeMask._emptyOrSpecial(domain, powerset);
  }

  factory FlatTypeMask.empty(
    CommonMasks domain, {
    bool hasLateSentinel = false,
  }) {
    final powerset = hasLateSentinel
        ? _specialValueDomain.allValues
        : _specialValueDomain.fromValue(TypeMaskSpecialValue.null_);

    return FlatTypeMask._emptyOrSpecial(domain, powerset);
  }
  factory FlatTypeMask.nonNullExact(
    ClassEntity base,
    CommonMasks domain, {
    bool hasLateSentinel = false,
  }) => FlatTypeMask._canonicalize(
    base,
    FlatTypeMaskKind.exact,
    hasLateSentinel
        ? EnumSet.fromValue(TypeMaskSpecialValue.lateSentinel)
        : EnumSet.empty(),
    domain,
  );

  factory FlatTypeMask.nonNullSubclass(
    ClassEntity base,
    CommonMasks domain, {
    bool hasLateSentinel = false,
  }) => FlatTypeMask._canonicalize(
    base,
    FlatTypeMaskKind.subclass,
    hasLateSentinel
        ? EnumSet.fromValue(TypeMaskSpecialValue.lateSentinel)
        : EnumSet.empty(),
    domain,
  );

  factory FlatTypeMask.nonNullSubtype(
    ClassEntity base,
    CommonMasks domain, {
    bool hasLateSentinel = false,
  }) => FlatTypeMask._canonicalize(
    base,
    FlatTypeMaskKind.subtype,
    hasLateSentinel
        ? EnumSet.fromValue(TypeMaskSpecialValue.lateSentinel)
        : EnumSet.empty(),
    domain,
  );

  factory FlatTypeMask._canonicalize(
    ClassEntity base,
    FlatTypeMaskKind kind,
    EnumSet<TypeMaskSpecialValue> specialValues,
    CommonMasks domain,
  ) {
    if (base == domain.commonElements.nullClass) {
      return FlatTypeMask.empty(
        domain,
        hasLateSentinel: specialValues.contains(
          TypeMaskSpecialValue.lateSentinel,
        ),
      );
    }

    final probe = domain._powersetCache[base];
    final powerset = switch (kind) {
      FlatTypeMaskKind.empty => throw StateError(
        'Unexpected empty kind with base $base',
      ),
      FlatTypeMaskKind.exact => probe.exact,
      FlatTypeMaskKind.subclass => probe.subclass,
      FlatTypeMaskKind.subtype => probe.subtype,
    }.union(_specialValueDomain.fromEnumSet(specialValues));

    return FlatTypeMask._cached(base, _computeFlags(kind, powerset), domain);
  }

  const FlatTypeMask._(this.base, this._flags);

  factory FlatTypeMask._cached(
    ClassEntity? base,
    _Flags flags,
    CommonMasks domain,
  ) => domain._getCachedMask(base, flags, () {
    final mask = FlatTypeMask._(base, flags);
    // Since this is the only place [FlatTypeMask]s are allocated, it is an
    // invariant that every [FlatTypeMask] is normalized.
    assert(TypeMask.assertIsNormalized(mask, domain.closedWorld));
    return mask;
  });

  /// Ensures that the generated mask is normalized, i.e., a call to
  /// [TypeMask.assertIsNormalized] with the factory's result returns `true`.
  factory FlatTypeMask.normalized(
    ClassEntity base,
    FlatTypeMaskKind kind,
    Bitset powerset,
    CommonMasks domain,
  ) {
    assert(kind != FlatTypeMaskKind.empty);
    assert(!_isEmptyOrSpecialPowerset(powerset));
    if (base == domain.commonElements.nullClass) {
      return FlatTypeMask.empty(
        domain,
        hasLateSentinel: _specialValueDomain.contains(
          powerset,
          TypeMaskSpecialValue.lateSentinel,
        ),
      );
    }
    if (kind == FlatTypeMaskKind.exact) {
      return FlatTypeMask._cached(base, _computeFlags(kind, powerset), domain);
    }
    if (kind == FlatTypeMaskKind.subtype) {
      if (!domain.closedWorld.classHierarchy.hasAnyStrictSubtype(base) ||
          domain.closedWorld.classHierarchy.hasOnlySubclasses(base)) {
        kind = FlatTypeMaskKind.subclass;
      }
    } else if (kind == FlatTypeMaskKind.subclass &&
        !domain.closedWorld.classHierarchy.hasAnyStrictSubclass(base)) {
      kind = FlatTypeMaskKind.exact;
    }
    final flags = _computeFlags(kind, powerset);
    return FlatTypeMask._cached(base, flags, domain);
  }

  /// Deserializes a [FlatTypeMask] object from [source].
  factory FlatTypeMask.readFromDataSource(
    DataSourceReader source,
    CommonMasks domain,
  ) {
    source.begin(tag);
    final base = source.readClassOrNull();
    final flags = _Flags(Bitset(source.readInt()));
    source.end(tag);
    return FlatTypeMask._cached(base, flags, domain);
  }

  /// Serializes this [FlatTypeMask] to [sink].
  @override
  void writeToDataSink(DataSinkWriter sink) {
    sink.writeEnum(TypeMaskKind.flat);
    sink.begin(tag);
    sink.writeClassOrNull(base);
    sink.writeInt(_flags.bitset.bits);
    sink.end(tag);
  }

  FlatTypeMaskKind get _kind => _getKind(_flags);

  @override
  Bitset get powerset => _getPowerset(_flags);

  ClassQuery get _classQuery => isExact
      ? ClassQuery.exact
      : (isSubclass ? ClassQuery.subclass : ClassQuery.subtype);

  @override
  bool get isEmpty =>
      isEmptyOrSpecial && _specialValueDomain.isEmpty(_flags.bitset);
  @override
  bool get isNull =>
      isEmptyOrSpecial &&
      _specialValueDomain.restrict(_flags.bitset) == _nullBit;
  @override
  bool get isEmptyOrSpecial => _kind == FlatTypeMaskKind.empty;
  @override
  bool get isExact => _kind == FlatTypeMaskKind.exact;
  @override
  bool get isNullable =>
      _specialValueDomain.contains(_flags.bitset, TypeMaskSpecialValue.null_);
  @override
  bool get hasLateSentinel => _specialValueDomain.contains(
    _flags.bitset,
    TypeMaskSpecialValue.lateSentinel,
  );
  @override
  AbstractBool get isLateSentinel {
    if (!hasLateSentinel) return AbstractBool.false_;
    if (isEmptyOrSpecial &&
        _specialValueDomain.restrict(_flags.bitset) == _lateSentinelBit) {
      return AbstractBool.true_;
    }
    return AbstractBool.maybe;
  }

  // TODO(kasperl): Get rid of these. They should not be a visible
  // part of the implementation because they make it hard to add
  // proper union types if we ever want to.
  bool get isSubclass => _kind == FlatTypeMaskKind.subclass;
  bool get isSubtype => _kind == FlatTypeMaskKind.subtype;

  @override
  FlatTypeMask withPowerset(Bitset powerset, CommonMasks domain) {
    final newFlags = _computeFlags(_kind, powerset);
    if (newFlags == _flags) return this;
    return FlatTypeMask._cached(base, newFlags, domain);
  }

  @override
  bool contains(ClassEntity other, JClosedWorld closedWorld) {
    if (isEmptyOrSpecial) {
      return false;
    } else if (identical(base, other)) {
      return true;
    } else if (isExact) {
      return false;
    } else if (isSubclass) {
      return closedWorld.classHierarchy.isSubclassOf(other, base!);
    } else {
      assert(isSubtype);
      return closedWorld.classHierarchy.isSubtypeOf(other, base!);
    }
  }

  bool _isSingleImplementationOf(ClassEntity cls, JClosedWorld closedWorld) {
    // Special case basic types so that, for example, JSString is the
    // single implementation of String.
    // The general optimization is to realize there is only one class that
    // implements [base] and [base] is not instantiated. We however do
    // not track correctly the list of truly instantiated classes.
    CommonElements commonElements = closedWorld.commonElements;
    if (containsOnlyString(closedWorld)) {
      return cls == closedWorld.commonElements.stringClass ||
          cls == commonElements.jsStringClass;
    }
    if (containsOnlyBool(closedWorld)) {
      return cls == closedWorld.commonElements.boolClass ||
          cls == commonElements.jsBoolClass;
    }
    if (containsOnlyInt(closedWorld)) {
      return cls == closedWorld.commonElements.intClass ||
          cls == commonElements.jsIntClass ||
          cls == commonElements.jsPositiveIntClass ||
          cls == commonElements.jsUInt32Class ||
          cls == commonElements.jsUInt31Class;
    }
    return false;
  }

  @override
  bool isInMask(TypeMask other, CommonMasks domain) {
    // Quick check whether to handle null.
    if (isNullable && !other.isNullable) return false;
    if (hasLateSentinel && !other.hasLateSentinel) {
      return false;
    }
    // The empty type contains no classes.
    if (isEmptyOrSpecial) return true;
    if (other.isEmptyOrSpecial) return false;
    other = TypeMask.nonForwardingMask(other);
    // If other is union, delegate to UnionTypeMask.containsMask.
    if (other is! FlatTypeMask) return other.containsMask(this, domain);
    // The other must be flat, so compare base and flags.
    final otherBase = other.base;
    // If other is exact, it only contains its base.
    // TODO(herhut): Get rid of _isSingleImplementationOf.
    if (other.isExact) {
      return (isExact && base == otherBase) ||
          _isSingleImplementationOf(otherBase!, domain.closedWorld);
    }
    // If other is subclass, this has to be subclass, as well. Unless
    // other.base covers all subtypes of this. Currently, we only
    // consider object to behave that way.
    // TODO(herhut): Add check whether other.base is superclass of
    //               all subclasses of this.base.
    if (other.isSubclass) {
      if (isSubtype) {
        return (otherBase == domain.commonElements.objectClass);
      }
      return domain.classHierarchy.isSubclassOf(base!, otherBase!);
    }
    assert(other.isSubtype);
    // Check whether this TypeMask satisfies otherBase's interface.
    return satisfies(otherBase!, domain.closedWorld);
  }

  @override
  bool containsMask(TypeMask other, CommonMasks domain) {
    return other.isInMask(this, domain);
  }

  @override
  bool containsOnlyInt(JClosedWorld closedWorld) {
    CommonElements commonElements = closedWorld.commonElements;
    return base == commonElements.intClass ||
        base == commonElements.jsIntClass ||
        base == commonElements.jsPositiveIntClass ||
        base == commonElements.jsUInt31Class ||
        base == commonElements.jsUInt32Class;
  }

  @override
  bool containsOnlyNum(JClosedWorld closedWorld) {
    return containsOnlyInt(closedWorld) ||
        base == closedWorld.commonElements.doubleClass ||
        base == closedWorld.commonElements.jsNumNotIntClass ||
        base == closedWorld.commonElements.numClass ||
        base == closedWorld.commonElements.jsNumberClass;
  }

  @override
  bool containsOnlyBool(JClosedWorld closedWorld) {
    return base == closedWorld.commonElements.boolClass ||
        base == closedWorld.commonElements.jsBoolClass;
  }

  @override
  bool containsOnlyString(JClosedWorld closedWorld) {
    return base == closedWorld.commonElements.stringClass ||
        base == closedWorld.commonElements.jsStringClass;
  }

  @override
  bool containsOnly(ClassEntity cls) {
    return base == cls;
  }

  @override
  bool satisfies(ClassEntity cls, JClosedWorld closedWorld) {
    if (isEmptyOrSpecial) return false;
    if (closedWorld.classHierarchy.isSubtypeOf(base!, cls)) return true;
    return false;
  }

  @override
  ClassEntity? singleClass(JClosedWorld closedWorld) {
    if (isEmptyOrSpecial) return null;
    if (isNullable) return null; // It is Null and some other class.
    if (hasLateSentinel) return null;
    if (isExact) {
      return base;
    } else if (isSubclass) {
      return closedWorld.classHierarchy.hasAnyStrictSubclass(base!)
          ? null
          : base;
    } else {
      assert(isSubtype);
      return null;
    }
  }

  @override
  bool containsAll(JClosedWorld closedWorld) {
    if (isEmptyOrSpecial || isExact) return false;
    return identical(base, closedWorld.commonElements.objectClass);
  }

  @override
  TypeMask union(TypeMask other, CommonMasks domain) {
    JClosedWorld closedWorld = domain.closedWorld;
    if (other is! FlatTypeMask) return other.union(this, domain);
    final powerset = _powersetOfFlagsUnion(_flags, other._flags);
    if (isEmptyOrSpecial) {
      return other.withPowerset(powerset, domain);
    } else if (other.isEmptyOrSpecial) {
      return withPowerset(powerset, domain);
    } else if (base == other.base) {
      return unionSame(other, domain);
    } else if (closedWorld.classHierarchy.isSubclassOf(other.base!, base!)) {
      return unionStrictSubclass(other, domain);
    } else if (closedWorld.classHierarchy.isSubclassOf(base!, other.base!)) {
      return other.unionStrictSubclass(this, domain);
    } else if (closedWorld.classHierarchy.isSubtypeOf(other.base!, base!)) {
      return unionStrictSubtype(other, domain);
    } else if (closedWorld.classHierarchy.isSubtypeOf(base!, other.base!)) {
      return other.unionStrictSubtype(this, domain);
    } else {
      return UnionTypeMask._internal([
        withoutSpecialValues(domain) as FlatTypeMask,
        other.withoutSpecialValues(domain) as FlatTypeMask,
      ], powerset);
    }
  }

  TypeMask unionSame(FlatTypeMask other, CommonMasks domain) {
    assert(base == other.base);
    // The two masks share the base type, so we must chose the least
    // constraining kind (the highest) of the two. As both masks are normalized,
    // the result will be, too.
    final combined = _Flags(
      (_flags.bitset.bits > other._flags.bitset.bits)
          ? _flags.bitset.union(other.powerset)
          : other._flags.bitset.union(powerset),
    );
    if (_flags == combined) {
      return this;
    } else if (other._flags == combined) {
      return other;
    } else {
      return FlatTypeMask._cached(base, combined, domain);
    }
  }

  TypeMask unionStrictSubclass(FlatTypeMask other, CommonMasks domain) {
    assert(base != other.base);
    assert(domain.closedWorld.classHierarchy.isSubclassOf(other.base!, base!));
    final FlatTypeMaskKind combinedKind;
    final Bitset combinedPowerset = _powersetOfFlagsUnion(_flags, other._flags);
    if ((isExact && other.isExact) ||
        base == domain.commonElements.objectClass) {
      // Since the other mask is a subclass of this mask, we need the
      // resulting union to be a subclass too.
      combinedKind = FlatTypeMaskKind.subclass;
      if (combinedKind == _kind && combinedPowerset == powerset) {
        return this;
      }
    } else {
      // Both masks are at least subclass masks, so we pick the least
      // constraining kind (the highest) of the two.
      combinedKind = _getKind(
        _flags.bitset.bits > other._flags.bitset.bits ? _flags : other._flags,
      );
    }
    // If we weaken the constraint on this type, we have to make sure that
    // the result is normalized.
    return FlatTypeMask.normalized(
      base!,
      combinedKind,
      combinedPowerset,
      domain,
    );
  }

  TypeMask unionStrictSubtype(FlatTypeMask other, CommonMasks domain) {
    assert(base != other.base);
    assert(!domain.closedWorld.classHierarchy.isSubclassOf(other.base!, base!));
    assert(domain.closedWorld.classHierarchy.isSubtypeOf(other.base!, base!));
    // Since the other mask is a subtype of this mask, we need the
    // resulting union to be a subtype too.
    final combinedKind = FlatTypeMaskKind.subtype;
    final combinedPowerset = _powersetOfFlagsUnion(_flags, other._flags);
    return combinedKind == _kind && combinedPowerset == powerset
        ? this
        // If we weaken the constraint on this type, we have to make sure that
        // the result is normalized.
        : FlatTypeMask.normalized(
            base!,
            combinedKind,
            combinedPowerset,
            domain,
          );
  }

  @override
  TypeMask _nonEmptyIntersection(TypeMask other, CommonMasks domain) {
    return (domain._intersectionCache[this] ??= {})[other] ??= _intersection(
      other,
      domain,
    );
  }

  TypeMask _intersection(TypeMask other, CommonMasks domain) {
    if (other is! FlatTypeMask) return other.intersection(this, domain);

    final powerset = _powersetOfFlagsIntersection(_flags, other._flags);
    assert(!isEmptyOrSpecial);
    assert(!other.isEmptyOrSpecial);

    final includeNull = _specialValueDomain.contains(
      powerset,
      TypeMaskSpecialValue.null_,
    );
    final includeLateSentinel = _specialValueDomain.contains(
      powerset,
      TypeMaskSpecialValue.lateSentinel,
    );

    SubclassResult result = domain.closedWorld.classHierarchy.commonSubclasses(
      base!,
      _classQuery,
      other.base!,
      other._classQuery,
    );

    switch (result) {
      case SimpleSubclassResult.empty:
        return includeNull
            ? TypeMask.empty(domain, hasLateSentinel: includeLateSentinel)
            : TypeMask.nonNullEmpty(
                domain,
                hasLateSentinel: includeLateSentinel,
              );
      case SimpleSubclassResult.exact1:
        assert(isExact);
        return withPowerset(powerset, domain);
      case SimpleSubclassResult.exact2:
        assert(other.isExact);
        return other.withPowerset(powerset, domain);
      case SimpleSubclassResult.subclass1:
        assert(isSubclass);
        return withPowerset(powerset, domain);
      case SimpleSubclassResult.subclass2:
        assert(other.isSubclass);
        return other.withPowerset(powerset, domain);
      case SimpleSubclassResult.subtype1:
        assert(isSubtype);
        return withPowerset(powerset, domain);
      case SimpleSubclassResult.subtype2:
        assert(other.isSubtype);
        return other.withPowerset(powerset, domain);
      case SetSubclassResult(:final classes):
        if (classes.isEmpty) {
          return includeNull
              ? TypeMask.empty(domain, hasLateSentinel: includeLateSentinel)
              : TypeMask.nonNullEmpty(
                  domain,
                  hasLateSentinel: includeLateSentinel,
                );
        } else if (classes.length == 1) {
          ClassEntity cls = classes.first;
          return includeNull
              ? TypeMask.subclass(
                  cls,
                  domain,
                  hasLateSentinel: includeLateSentinel,
                )
              : TypeMask.nonNullSubclass(
                  cls,
                  domain,
                  hasLateSentinel: includeLateSentinel,
                );
        }

        List<FlatTypeMask> masks = List.from(
          classes.map(
            (ClassEntity cls) => TypeMask.nonNullSubclass(cls, domain),
          ),
        );
        if (masks.length > UnionTypeMask.maxUnionLength) {
          return UnionTypeMask.flatten(masks, domain, powerset);
        }
        return UnionTypeMask._internal(masks, powerset);
    }
  }

  @override
  bool _isNonTriviallyDisjoint(TypeMask other, JClosedWorld closedWorld) {
    if (other is! FlatTypeMask) {
      return other._isNonTriviallyDisjoint(this, closedWorld);
    }

    if (base == other.base) return false;
    if (isExact && other.isExact) return true;

    if (isExact) return !other.contains(base!, closedWorld);
    if (other.isExact) return !contains(other.base!, closedWorld);
    final thisBase = base!;
    final otherBase = other.base!;

    // Normalization guarantees that isExact === !isSubclass && !isSubtype.
    // Both are subclass or subtype masks, so if there is a subclass
    // relationship, they are not disjoint.
    if (closedWorld.classHierarchy.isSubclassOf(otherBase, thisBase)) {
      return false;
    }
    if (closedWorld.classHierarchy.isSubclassOf(thisBase, otherBase)) {
      return false;
    }

    // Two different base classes have no common subclass unless one is a
    // subclass of the other (checked above).
    if (isSubclass && other.isSubclass) return true;

    return _isDisjointHelper(this, other, closedWorld);
  }

  static bool _isDisjointHelper(
    FlatTypeMask a,
    FlatTypeMask b,
    JClosedWorld closedWorld,
  ) {
    if (!a.isSubclass && b.isSubclass) {
      return _isDisjointHelper(b, a, closedWorld);
    }
    assert(a.isSubclass || a.isSubtype);
    assert(b.isSubtype);
    final aBase = a.base!;
    var elements = a.isSubclass
        ? closedWorld.classHierarchy.strictSubclassesOf(aBase)
        : closedWorld.classHierarchy.strictSubtypesOf(aBase);
    for (var element in elements) {
      if (closedWorld.classHierarchy.isSubtypeOf(element, b.base!)) {
        return false;
      }
    }
    return true;
  }

  @override
  bool canHit(MemberEntity element, Name name, CommonMasks domain) {
    final closedWorld = domain.closedWorld;
    CommonElements commonElements = closedWorld.commonElements;
    assert(element.name == name.text);
    if (isEmptyOrSpecial) {
      return isNullable &&
          closedWorld.hasElementIn(commonElements.jsNullClass, name, element);
    }

    final other = element.enclosingClass;
    final thisBase = base!;
    if (other == commonElements.jsNullClass) {
      return isNullable;
    } else if (isExact) {
      return closedWorld.hasElementIn(thisBase, name, element);
    } else if (isSubclass) {
      return closedWorld.hasElementIn(thisBase, name, element) ||
          closedWorld.classHierarchy.isSubclassOf(other!, thisBase) ||
          closedWorld.hasAnySubclassThatMixes(thisBase, other);
    } else {
      assert(isSubtype);
      bool result =
          closedWorld.hasElementIn(thisBase, name, element) ||
          closedWorld.classHierarchy.isSubtypeOf(other!, thisBase) ||
          closedWorld.hasAnySubclassThatImplements(other, thisBase) ||
          closedWorld.hasAnySubclassOfMixinUseThatImplements(other, thisBase);
      if (result) return true;
      // If the class is used as a mixin, we have to check if the element
      // can be hit from any of the mixin applications.
      Iterable<ClassEntity> mixinUses = closedWorld.mixinUsesOf(thisBase);
      return mixinUses.any(
        (mixinApplication) =>
            closedWorld.hasElementIn(mixinApplication, name, element) ||
            closedWorld.classHierarchy.isSubclassOf(other, mixinApplication) ||
            closedWorld.hasAnySubclassThatMixes(mixinApplication, other),
      );
    }
  }

  @override
  bool needsNoSuchMethodHandling(
    Selector selector,
    covariant JClosedWorld closedWorld,
  ) {
    // A call on an empty type mask is either dead code, or a call on
    // `null`.
    if (isEmptyOrSpecial) return false;
    // A call on an exact mask for an abstract class is dead code.
    // TODO(johnniwinther): A type mask cannot be abstract. Remove the need
    // for this noise (currently used for super-calls in inference and mirror
    // usage).
    final thisBase = base!;
    if (isExact && thisBase.isAbstract) return false;

    return closedWorld.needsNoSuchMethod(thisBase, selector, _classQuery);
  }

  @override
  MemberEntity? locateSingleMember(Selector selector, CommonMasks domain) {
    if (isEmptyOrSpecial) return null;
    JClosedWorld closedWorld = domain.closedWorld;
    if (closedWorld.includesClosureCallInDomain(selector, this, domain)) {
      return null;
    }
    Iterable<MemberEntity> targets = closedWorld.locateMembersInDomain(
      selector,
      this,
      domain,
    );
    if (targets.length != 1) return null;
    MemberEntity result = targets.first;
    final enclosing = result.enclosingClass!;
    final thisBase = base!;
    // We only return the found element if it is guaranteed to be implemented on
    // all classes in the receiver type [this]. It could be found only in a
    // subclass or in an inheritance-wise unrelated class in case of subtype
    // selectors.
    if (isSubtype) {
      // if (closedWorld.isUsedAsMixin(enclosing)) {
      if (closedWorld.everySubtypeIsSubclassOfOrMixinUseOf(
        thisBase,
        enclosing,
      )) {
        return result;
      }
      //}
      return null;
    } else {
      if (closedWorld.classHierarchy.isSubclassOf(thisBase, enclosing)) {
        return result;
      }
      if (closedWorld.isSubclassOfMixinUseOf(thisBase, enclosing)) {
        return result;
      }
    }
    return null;
  }

  @override
  Iterable<DynamicCallTarget> findRootsOfTargets(
    Selector selector,
    MemberHierarchyBuilder memberHierarchyBuilder,
    JClosedWorld closedWorld,
  ) {
    if (isEmptyOrSpecial) return const [];
    final baseClass = base!;
    if (closedWorld.isDefaultSuperclass(baseClass)) {
      // Filter roots using the mask's class since each default superclass has
      // distinct roots.
      final results = memberHierarchyBuilder.rootsForSelector(
        baseClass,
        selector,
      );
      return results.isEmpty ? const [] : results;
    }

    // Try to find a superclass that contains a matching member.
    final superclassMatch = memberHierarchyBuilder.findSuperclassTarget(
      baseClass,
      selector,
      isExact: isExact,
      isSubclass: isSubclass,
    );

    // If this mask is exact then we should have found a matching target on a
    // superclass or need noSuchMethod handling and can quit early anyway.
    // Otherwise only return if we actually found a match.
    if (isExact || superclassMatch.isNotEmpty) return superclassMatch;

    // Default to a list of superclasses/supertypes that encompasses all
    // subclasses/subtypes of this type cone.
    return memberHierarchyBuilder.findMatchingAncestors(
      baseClass,
      selector,
      isSubtype: isSubtype,
    );
  }

  @override
  bool operator ==(var other) {
    if (identical(this, other)) return true;
    if (other is! FlatTypeMask) return false;
    return (_flags == other._flags) && (base == other.base);
  }

  @override
  int get hashCode {
    return (base == null ? 0 : base.hashCode) + 31 * _flags.hashCode;
  }

  @override
  String toString() {
    StringBuffer buffer = StringBuffer('[');
    buffer.writeAll([
      if (isEmpty) 'empty',
      if (isNullable) 'null',
      if (hasLateSentinel) 'sentinel',
      if (isExact) 'exact=${base!.name}',
      if (isSubclass) 'subclass=${base!.name}',
      if (isSubtype) 'subtype=${base!.name}',
      'powerset=${TypeMask.powersetToString(powerset)}',
    ], '|');
    buffer.write(']');
    return buffer.toString();
  }
}

typedef _CachedPowersets = ({Bitset exact, Bitset subclass, Bitset subtype});

class _PowersetCache {
  final JClosedWorld _closedWorld;
  final Set<ClassEntity> _interceptorCone;
  final Set<ClassEntity> _indexableCone;
  final Set<ClassEntity> _mutableIndexableCone;
  final Map<ClassEntity, _CachedPowersets> _cache = {};

  _PowersetCache(this._closedWorld)
    : _interceptorCone = _closedWorld.classHierarchy
          .subclassesOf(_closedWorld.commonElements.jsInterceptorClass)
          .toSet(),
      _indexableCone = _closedWorld.classHierarchy
          .subtypesOf(_closedWorld.commonElements.jsIndexableClass)
          .toSet(),
      _mutableIndexableCone = _closedWorld.classHierarchy
          .subtypesOf(_closedWorld.commonElements.jsMutableIndexableClass)
          .toSet();

  Bitset _computeExactPowerset(ClassEntity cls) {
    var powerset = Bitset.empty();
    if (!_closedWorld.classHierarchy.isExplicitlyInstantiated(cls)) {
      return powerset;
    }

    powerset = _interceptorDomain.add(
      powerset,
      _interceptorCone.contains(cls)
          ? TypeMaskInterceptorProperty.interceptor
          : TypeMaskInterceptorProperty.notInterceptor,
    );

    // TODO(sra): Set any other [TypeMaskArrayProperty] bits.
    if (cls == _closedWorld.commonElements.jsExtendableArrayClass) {
      powerset = _arrayDomain.add(powerset, TypeMaskArrayProperty.growable);
    } else if (cls == _closedWorld.commonElements.jsFixedArrayClass) {
      powerset = _arrayDomain.add(powerset, TypeMaskArrayProperty.fixedLength);
    } else if (cls == _closedWorld.commonElements.jsUnmodifiableArrayClass) {
      powerset = _arrayDomain.add(powerset, TypeMaskArrayProperty.unmodifiable);
    } else if (cls == _closedWorld.commonElements.jsArrayClass) {
      powerset = _arrayDomain.addAll(powerset, const [
        TypeMaskArrayProperty.growable,
        TypeMaskArrayProperty.fixedLength,
        TypeMaskArrayProperty.unmodifiable,
      ]);
    } else {
      powerset = _arrayDomain.add(powerset, TypeMaskArrayProperty.other);
    }

    // The order of these checks is important since `JSMutableIndexable` is a
    // subclass of `JSIndexable`.
    if (_mutableIndexableCone.contains(cls)) {
      powerset = _indexableDomain.add(
        powerset,
        TypeMaskIndexableProperty.mutableIndexable,
      );
    } else if (_indexableCone.contains(cls)) {
      powerset = _indexableDomain.add(
        powerset,
        TypeMaskIndexableProperty.indexable,
      );
    } else {
      powerset = _indexableDomain.add(
        powerset,
        TypeMaskIndexableProperty.notIndexable,
      );
    }

    return powerset;
  }

  _CachedPowersets operator [](ClassEntity cls) => _cache.putIfAbsent(cls, () {
    final exactPowerset = _computeExactPowerset(cls);

    var subclassPowerset = exactPowerset;
    for (final subclass in _closedWorld.classHierarchy.strictSubclassesOf(
      cls,
    )) {
      subclassPowerset = subclassPowerset.union(this[subclass].subclass);
    }

    var subtypePowerset = exactPowerset;
    for (final subtype in _closedWorld.classHierarchy.strictSubtypesOf(cls)) {
      subtypePowerset = subtypePowerset.union(this[subtype].subtype);
    }

    return (
      exact: exactPowerset,
      subclass: subclassPowerset,
      subtype: subtypePowerset,
    );
  });
}
