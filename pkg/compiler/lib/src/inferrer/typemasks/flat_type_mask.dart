// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of masks;

enum FlatTypeMaskKind { empty, exact, subclass, subtype }

final _specialValueDomain =
    EnumSetDomain<TypeMaskSpecialValue>(0, TypeMaskSpecialValue.values);

final _powersetDomains = ComposedEnumSetDomains([_specialValueDomain]);

/// A flat type mask is a type mask that has been flattened to contain a
/// base type.
class FlatTypeMask extends TypeMask {
  /// Tag used for identifying serialized [FlatTypeMask] objects in a
  /// debugging data stream.
  static const String tag = 'flat-type-mask';

  static final Bitset _nullBit =
      _specialValueDomain.fromValue(TypeMaskSpecialValue.null_);
  static final Bitset _lateSentinelBit =
      _specialValueDomain.fromValue(TypeMaskSpecialValue.lateSentinel);

  final ClassEntity? base;
  final Bitset flags;

  // TODO(fishythefish): Derive other powerset bits.
  static Bitset _computeFlags(
          FlatTypeMaskKind kind, EnumSet<TypeMaskSpecialValue> specialValues) =>
      _computeFlagsRaw(kind, _specialValueDomain.fromEnumSet(specialValues));

  static Bitset _computeFlagsRaw(FlatTypeMaskKind kind, Bitset powerset) =>
      Bitset(kind.index << _powersetDomains.bitWidth | powerset.bits);

  static FlatTypeMaskKind _lookupKind(Bitset flags) =>
      FlatTypeMaskKind.values[flags.bits >> _powersetDomains.bitWidth];

  static bool _hasNullableFlag(Bitset flags) =>
      _specialValueDomain.contains(flags, TypeMaskSpecialValue.null_);

  static bool _hasLateSentinelFlag(Bitset flags) =>
      _specialValueDomain.contains(flags, TypeMaskSpecialValue.lateSentinel);

  factory FlatTypeMask.exact(ClassEntity base, JClosedWorld world,
          {bool hasLateSentinel = false}) =>
      FlatTypeMask._canonicalize(
          base,
          FlatTypeMaskKind.exact,
          _composeSpecialValues(
              isNullable: true, hasLateSentinel: hasLateSentinel),
          world);

  factory FlatTypeMask.subclass(ClassEntity base, JClosedWorld world,
          {bool hasLateSentinel = false}) =>
      FlatTypeMask._canonicalize(
          base,
          FlatTypeMaskKind.subclass,
          _composeSpecialValues(
              isNullable: true, hasLateSentinel: hasLateSentinel),
          world);

  factory FlatTypeMask.subtype(ClassEntity base, JClosedWorld world,
          {bool hasLateSentinel = false}) =>
      FlatTypeMask._canonicalize(
          base,
          FlatTypeMaskKind.subtype,
          _composeSpecialValues(
              isNullable: true, hasLateSentinel: hasLateSentinel),
          world);

  factory FlatTypeMask.nonNullEmpty({bool hasLateSentinel = false}) =>
      hasLateSentinel
          ? FlatTypeMask._(null,
              _specialValueDomain.fromValue(TypeMaskSpecialValue.lateSentinel))
          : FlatTypeMask._(null, Bitset.empty());

  factory FlatTypeMask.empty({bool hasLateSentinel = false}) => hasLateSentinel
      ? FlatTypeMask._(null, _specialValueDomain.allValues)
      : FlatTypeMask._(
          null, _specialValueDomain.fromValue(TypeMaskSpecialValue.null_));

  factory FlatTypeMask.nonNullExact(ClassEntity base, JClosedWorld world,
          {bool hasLateSentinel = false}) =>
      FlatTypeMask._canonicalize(
          base,
          FlatTypeMaskKind.exact,
          hasLateSentinel
              ? EnumSet.fromValue(TypeMaskSpecialValue.lateSentinel)
              : EnumSet.empty(),
          world);

  factory FlatTypeMask.nonNullSubclass(ClassEntity base, JClosedWorld world,
          {bool hasLateSentinel = false}) =>
      FlatTypeMask._canonicalize(
          base,
          FlatTypeMaskKind.subclass,
          hasLateSentinel
              ? EnumSet.fromValue(TypeMaskSpecialValue.lateSentinel)
              : EnumSet.empty(),
          world);

  factory FlatTypeMask.nonNullSubtype(ClassEntity base, JClosedWorld world,
          {bool hasLateSentinel = false}) =>
      FlatTypeMask._canonicalize(
          base,
          FlatTypeMaskKind.subtype,
          hasLateSentinel
              ? EnumSet.fromValue(TypeMaskSpecialValue.lateSentinel)
              : EnumSet.empty(),
          world);

  factory FlatTypeMask._canonicalize(ClassEntity base, FlatTypeMaskKind kind,
      EnumSet<TypeMaskSpecialValue> specialValues, JClosedWorld world) {
    if (base == world.commonElements.nullClass) {
      return FlatTypeMask.empty(
          hasLateSentinel:
              specialValues.contains(TypeMaskSpecialValue.lateSentinel));
    }
    return FlatTypeMask._(base, _computeFlags(kind, specialValues));
  }

  const FlatTypeMask._(this.base, this.flags);

  FlatTypeMask._internal(ClassEntity? base, FlatTypeMaskKind kind,
      EnumSet<TypeMaskSpecialValue> specialValues)
      : this._(base, _computeFlags(kind, specialValues));

  /// Ensures that the generated mask is normalized, i.e., a call to
  /// [TypeMask.assertIsNormalized] with the factory's result returns `true`.
  factory FlatTypeMask.normalized(ClassEntity? base, FlatTypeMaskKind kind,
      EnumSet<TypeMaskSpecialValue> specialValues, CommonMasks domain) {
    if (base == domain.commonElements.nullClass) {
      return FlatTypeMask.empty(
          hasLateSentinel:
              specialValues.contains(TypeMaskSpecialValue.lateSentinel));
    }
    if (kind == FlatTypeMaskKind.empty || kind == FlatTypeMaskKind.exact) {
      return FlatTypeMask._(base, _computeFlags(kind, specialValues));
    }
    if (kind == FlatTypeMaskKind.subtype) {
      if (!domain._closedWorld.classHierarchy.hasAnyStrictSubtype(base!) ||
          domain._closedWorld.classHierarchy.hasOnlySubclasses(base)) {
        kind = FlatTypeMaskKind.subclass;
      }
    } else if (kind == FlatTypeMaskKind.subclass &&
        !domain._closedWorld.classHierarchy.hasAnyStrictSubclass(base!)) {
      kind = FlatTypeMaskKind.exact;
    }
    return domain.getCachedMask(base, kind, specialValues,
        () => FlatTypeMask._(base, _computeFlags(kind, specialValues)));
  }

  /// Deserializes a [FlatTypeMask] object from [source].
  factory FlatTypeMask.readFromDataSource(
      DataSourceReader source, CommonMasks domain) {
    source.begin(tag);
    final base = source.readClassOrNull();
    final kind = source.readEnum(FlatTypeMaskKind.values);
    final specialValues =
        EnumSet<TypeMaskSpecialValue>.fromRawBits(source.readInt());
    source.end(tag);
    return domain.getCachedMask(base, kind, specialValues,
        () => FlatTypeMask._internal(base, kind, specialValues));
  }

  /// Serializes this [FlatTypeMask] to [sink].
  @override
  void writeToDataSink(DataSinkWriter sink) {
    sink.writeEnum(TypeMaskKind.flat);
    sink.begin(tag);
    sink.writeClassOrNull(base);
    sink.writeEnum(_kind);
    sink.writeInt(_specialValueDomain.toEnumSet(flags).mask.bits);
    sink.end(tag);
  }

  FlatTypeMaskKind get _kind => _lookupKind(flags);

  Bitset get _powerset => _powersetDomains.restrict(flags);

  ClassQuery get _classQuery => isExact
      ? ClassQuery.EXACT
      : (isSubclass ? ClassQuery.SUBCLASS : ClassQuery.SUBTYPE);

  @override
  bool get isEmpty => isEmptyOrSpecial && _specialValueDomain.isEmpty(flags);
  @override
  bool get isNull =>
      isEmptyOrSpecial && _specialValueDomain.restrict(flags) == _nullBit;
  @override
  bool get isEmptyOrSpecial => _kind == FlatTypeMaskKind.empty;
  @override
  bool get isExact => _kind == FlatTypeMaskKind.exact;
  @override
  bool get isNullable => _hasNullableFlag(flags);
  @override
  bool get hasLateSentinel => _hasLateSentinelFlag(flags);
  @override
  AbstractBool get isLateSentinel {
    if (!hasLateSentinel) return AbstractBool.False;
    if (isEmptyOrSpecial &&
        _specialValueDomain.restrict(flags) == _lateSentinelBit) {
      return AbstractBool.True;
    }
    return AbstractBool.Maybe;
  }

  // TODO(kasperl): Get rid of these. They should not be a visible
  // part of the implementation because they make it hard to add
  // proper union types if we ever want to.
  bool get isSubclass => _kind == FlatTypeMaskKind.subclass;
  bool get isSubtype => _kind == FlatTypeMaskKind.subtype;

  @override
  FlatTypeMask withSpecialValues({bool? isNullable, bool? hasLateSentinel}) {
    final newFlags = _computeFlags(
        _kind,
        _composeSpecialValues(
            isNullable: isNullable ?? this.isNullable,
            hasLateSentinel: hasLateSentinel ?? this.hasLateSentinel));
    if (newFlags == flags) return this;
    return FlatTypeMask._(base, newFlags);
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
  bool isInMask(TypeMask other, JClosedWorld closedWorld) {
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
    if (other is! FlatTypeMask) return other.containsMask(this, closedWorld);
    // The other must be flat, so compare base and flags.
    FlatTypeMask flatOther = other;
    final otherBase = flatOther.base;
    // If other is exact, it only contains its base.
    // TODO(herhut): Get rid of _isSingleImplementationOf.
    if (flatOther.isExact) {
      return (isExact && base == otherBase) ||
          _isSingleImplementationOf(otherBase!, closedWorld);
    }
    // If other is subclass, this has to be subclass, as well. Unless
    // flatOther.base covers all subtypes of this. Currently, we only
    // consider object to behave that way.
    // TODO(herhut): Add check whether flatOther.base is superclass of
    //               all subclasses of this.base.
    if (flatOther.isSubclass) {
      if (isSubtype)
        return (otherBase == closedWorld.commonElements.objectClass);
      return closedWorld.classHierarchy.isSubclassOf(base!, otherBase!);
    }
    assert(flatOther.isSubtype);
    // Check whether this TypeMask satisfies otherBase's interface.
    return satisfies(otherBase!, closedWorld);
  }

  @override
  bool containsMask(TypeMask other, JClosedWorld closedWorld) {
    return other.isInMask(this, closedWorld);
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
    JClosedWorld closedWorld = domain._closedWorld;
    assert(TypeMask.assertIsNormalized(this, closedWorld));
    assert(TypeMask.assertIsNormalized(other, closedWorld));
    if (other is! FlatTypeMask) return other.union(this, domain);
    FlatTypeMask flatOther = other;
    bool isNullable = this.isNullable || flatOther.isNullable;
    bool hasLateSentinel = this.hasLateSentinel || flatOther.hasLateSentinel;
    if (isEmptyOrSpecial) {
      return flatOther.withSpecialValues(
          isNullable: isNullable, hasLateSentinel: hasLateSentinel);
    } else if (flatOther.isEmptyOrSpecial) {
      return withSpecialValues(
          isNullable: isNullable, hasLateSentinel: hasLateSentinel);
    } else if (base == flatOther.base) {
      return unionSame(flatOther, domain);
    } else if (closedWorld.classHierarchy
        .isSubclassOf(flatOther.base!, base!)) {
      return unionStrictSubclass(flatOther, domain);
    } else if (closedWorld.classHierarchy
        .isSubclassOf(base!, flatOther.base!)) {
      return flatOther.unionStrictSubclass(this, domain);
    } else if (closedWorld.classHierarchy.isSubtypeOf(flatOther.base!, base!)) {
      return unionStrictSubtype(flatOther, domain);
    } else if (closedWorld.classHierarchy.isSubtypeOf(base!, flatOther.base!)) {
      return flatOther.unionStrictSubtype(this, domain);
    } else {
      return UnionTypeMask._compose([
        withoutSpecialValues() as FlatTypeMask,
        flatOther.withoutSpecialValues() as FlatTypeMask
      ], isNullable: isNullable, hasLateSentinel: hasLateSentinel);
    }
  }

  TypeMask unionSame(FlatTypeMask other, CommonMasks domain) {
    assert(base == other.base);
    assert(TypeMask.assertIsNormalized(this, domain._closedWorld));
    assert(TypeMask.assertIsNormalized(other, domain._closedWorld));
    // The two masks share the base type, so we must chose the least
    // constraining kind (the highest) of the two. If either one of
    // the masks are nullable the result should be nullable too.
    // As both masks are normalized, the result will be, too.
    final combined = (flags.bits > other.flags.bits)
        ? flags.union(other._powerset)
        : other.flags.union(_powerset);
    if (flags == combined) {
      return this;
    } else if (other.flags == combined) {
      return other;
    } else {
      return FlatTypeMask.normalized(base!, _lookupKind(combined),
          _specialValueDomain.toEnumSet(combined), domain);
    }
  }

  TypeMask unionStrictSubclass(FlatTypeMask other, CommonMasks domain) {
    assert(base != other.base);
    assert(domain._closedWorld.classHierarchy.isSubclassOf(other.base!, base!));
    assert(TypeMask.assertIsNormalized(this, domain._closedWorld));
    assert(TypeMask.assertIsNormalized(other, domain._closedWorld));
    Bitset combined;
    if ((isExact && other.isExact) ||
        base == domain.commonElements.objectClass) {
      // Since the other mask is a subclass of this mask, we need the
      // resulting union to be a subclass too. If either one of the
      // masks are nullable the result should be nullable too.
      combined = _computeFlagsRaw(
          FlatTypeMaskKind.subclass, _powerset.union(other._powerset));
    } else {
      // Both masks are at least subclass masks, so we pick the least
      // constraining kind (the highest) of the two. If either one of
      // the masks are nullable the result should be nullable too.
      combined = (flags.bits > other.flags.bits)
          ? flags.union(other._powerset)
          : other.flags.union(_powerset);
    }
    // If we weaken the constraint on this type, we have to make sure that
    // the result is normalized.
    return flags != combined
        ? FlatTypeMask.normalized(base, _lookupKind(combined),
            _specialValueDomain.toEnumSet(combined), domain)
        : this;
  }

  TypeMask unionStrictSubtype(FlatTypeMask other, CommonMasks domain) {
    assert(base != other.base);
    assert(
        !domain._closedWorld.classHierarchy.isSubclassOf(other.base!, base!));
    assert(domain._closedWorld.classHierarchy.isSubtypeOf(other.base!, base!));
    assert(TypeMask.assertIsNormalized(this, domain._closedWorld));
    assert(TypeMask.assertIsNormalized(other, domain._closedWorld));
    // Since the other mask is a subtype of this mask, we need the
    // resulting union to be a subtype too. If either one of the masks
    // are nullable the result should be nullable too.
    final combined = _computeFlagsRaw(
        FlatTypeMaskKind.subtype, _powerset.union(other._powerset));
    // We know there is at least one subtype, [other.base], so no need
    // to normalize.
    return flags != combined
        ? FlatTypeMask.normalized(base, _lookupKind(combined),
            _specialValueDomain.toEnumSet(combined), domain)
        : this;
  }

  @override
  TypeMask intersection(TypeMask other, CommonMasks domain) {
    return (domain._intersectionCache[this] ??= {})[other] ??=
        _intersection(other, domain);
  }

  TypeMask _intersection(TypeMask other, CommonMasks domain) {
    if (other is! FlatTypeMask) return other.intersection(this, domain);
    assert(TypeMask.assertIsNormalized(this, domain._closedWorld));
    assert(TypeMask.assertIsNormalized(other, domain._closedWorld));
    FlatTypeMask flatOther = other;

    final otherBase = flatOther.base;

    bool includeNull = isNullable && flatOther.isNullable;
    bool includeLateSentinel = hasLateSentinel && flatOther.hasLateSentinel;

    if (isEmptyOrSpecial) {
      return withSpecialValues(
          isNullable: includeNull, hasLateSentinel: includeLateSentinel);
    } else if (flatOther.isEmptyOrSpecial) {
      return other.withSpecialValues(
          isNullable: includeNull, hasLateSentinel: includeLateSentinel);
    }

    SubclassResult result = domain._closedWorld.classHierarchy.commonSubclasses(
        base!, _classQuery, otherBase!, flatOther._classQuery);

    switch (result) {
      case SimpleSubclassResult.empty:
        return includeNull
            ? TypeMask.empty(hasLateSentinel: includeLateSentinel)
            : TypeMask.nonNullEmpty(hasLateSentinel: includeLateSentinel);
      case SimpleSubclassResult.exact1:
        assert(isExact);
        return withSpecialValues(
            isNullable: includeNull, hasLateSentinel: includeLateSentinel);
      case SimpleSubclassResult.exact2:
        assert(other.isExact);
        return other.withSpecialValues(
            isNullable: includeNull, hasLateSentinel: includeLateSentinel);
      case SimpleSubclassResult.subclass1:
        assert(isSubclass);
        return withSpecialValues(
            isNullable: includeNull, hasLateSentinel: includeLateSentinel);
      case SimpleSubclassResult.subclass2:
        assert(flatOther.isSubclass);
        return other.withSpecialValues(
            isNullable: includeNull, hasLateSentinel: includeLateSentinel);
      case SimpleSubclassResult.subtype1:
        assert(isSubtype);
        return withSpecialValues(
            isNullable: includeNull, hasLateSentinel: includeLateSentinel);
      case SimpleSubclassResult.subtype2:
        assert(flatOther.isSubtype);
        return other.withSpecialValues(
            isNullable: includeNull, hasLateSentinel: includeLateSentinel);
      case SetSubclassResult(:final classes):
        if (classes.isEmpty) {
          return includeNull
              ? TypeMask.empty(hasLateSentinel: includeLateSentinel)
              : TypeMask.nonNullEmpty(hasLateSentinel: includeLateSentinel);
        } else if (classes.length == 1) {
          ClassEntity cls = classes.first;
          return includeNull
              ? TypeMask.subclass(cls, domain._closedWorld,
                  hasLateSentinel: includeLateSentinel)
              : TypeMask.nonNullSubclass(cls, domain._closedWorld,
                  hasLateSentinel: includeLateSentinel);
        }

        List<FlatTypeMask> masks = List.from(classes.map((ClassEntity cls) =>
            TypeMask.nonNullSubclass(cls, domain._closedWorld)));
        if (masks.length > UnionTypeMask.MAX_UNION_LENGTH) {
          return UnionTypeMask.flatten(masks, domain,
              includeNull: includeNull,
              includeLateSentinel: includeLateSentinel);
        }
        return UnionTypeMask._compose(masks,
            isNullable: includeNull, hasLateSentinel: includeLateSentinel);
    }
  }

  @override
  bool isDisjoint(TypeMask other, JClosedWorld closedWorld) {
    if (other is! FlatTypeMask) return other.isDisjoint(this, closedWorld);
    FlatTypeMask flatOther = other;

    if (isNullable && flatOther.isNullable) return false;
    if (hasLateSentinel && flatOther.hasLateSentinel) return false;
    if (isEmptyOrSpecial || flatOther.isEmptyOrSpecial) return true;
    if (base == flatOther.base) return false;
    if (isExact && flatOther.isExact) return true;

    if (isExact) return !flatOther.contains(base!, closedWorld);
    if (flatOther.isExact) return !contains(flatOther.base!, closedWorld);
    final thisBase = base!;
    final otherBase = flatOther.base!;

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
    if (isSubclass && flatOther.isSubclass) return true;

    return _isDisjointHelper(this, flatOther, closedWorld);
  }

  static bool _isDisjointHelper(
      FlatTypeMask a, FlatTypeMask b, JClosedWorld closedWorld) {
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

  TypeMask intersectionSame(FlatTypeMask other, CommonMasks domain) {
    assert(base == other.base);
    // The two masks share the base type, so we must chose the most
    // constraining kind (the lowest) of the two. Only if both masks
    // are nullable, will the result be nullable too.
    // The result will be normalized, as the two inputs are normalized, too.
    final combined = (flags.bits < other.flags.bits)
        ? flags.intersection(other.flags.union(_powersetDomains.notMask))
        : other.flags.intersection(flags.union(_powersetDomains.notMask));

    if (flags == combined) {
      return this;
    } else if (other.flags == combined) {
      return other;
    } else {
      return FlatTypeMask.normalized(base, _lookupKind(combined),
          _specialValueDomain.toEnumSet(combined), domain);
    }
  }

  TypeMask intersectionStrictSubclass(FlatTypeMask other, CommonMasks domain) {
    assert(base != other.base);
    assert(domain._closedWorld.classHierarchy.isSubclassOf(other.base!, base!));
    // If this mask isn't at least a subclass mask, then the
    // intersection with the other mask is empty.
    if (isExact) return intersectionEmpty(other);
    // Only the other mask puts constraints on the intersection mask,
    // so base the combined flags on the other mask. Only if both
    // masks are nullable, will the result be nullable too.
    // The result is guaranteed to be normalized, as the other type
    // was normalized.
    final combined =
        other.flags.intersection(flags.union(_powersetDomains.notMask));
    if (other.flags == combined) {
      return other;
    } else {
      return FlatTypeMask.normalized(other.base, _lookupKind(combined),
          _specialValueDomain.toEnumSet(combined), domain);
    }
  }

  TypeMask intersectionEmpty(FlatTypeMask other) {
    bool isNullable = this.isNullable && other.isNullable;
    bool hasLateSentinel = this.hasLateSentinel && other.hasLateSentinel;
    return isNullable
        ? TypeMask.empty(hasLateSentinel: hasLateSentinel)
        : TypeMask.nonNullEmpty(hasLateSentinel: hasLateSentinel);
  }

  @override
  bool canHit(MemberEntity element, Name name, JClosedWorld closedWorld) {
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
      bool result = closedWorld.hasElementIn(thisBase, name, element) ||
          closedWorld.classHierarchy.isSubtypeOf(other!, thisBase) ||
          closedWorld.hasAnySubclassThatImplements(other, thisBase) ||
          closedWorld.hasAnySubclassOfMixinUseThatImplements(other, thisBase);
      if (result) return true;
      // If the class is used as a mixin, we have to check if the element
      // can be hit from any of the mixin applications.
      Iterable<ClassEntity> mixinUses = closedWorld.mixinUsesOf(thisBase);
      return mixinUses.any((mixinApplication) =>
          closedWorld.hasElementIn(mixinApplication, name, element) ||
          closedWorld.classHierarchy.isSubclassOf(other, mixinApplication) ||
          closedWorld.hasAnySubclassThatMixes(mixinApplication, other));
    }
  }

  @override
  bool needsNoSuchMethodHandling(
      Selector selector, covariant JClosedWorld closedWorld) {
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
    JClosedWorld closedWorld = domain._closedWorld;
    if (closedWorld.includesClosureCallInDomain(selector, this, domain))
      return null;
    Iterable<MemberEntity> targets =
        closedWorld.locateMembersInDomain(selector, this, domain);
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
          thisBase, enclosing)) {
        return result;
      }
      //}
      return null;
    } else {
      if (closedWorld.classHierarchy.isSubclassOf(thisBase, enclosing)) {
        return result;
      }
      if (closedWorld.isSubclassOfMixinUseOf(thisBase, enclosing))
        return result;
    }
    return null;
  }

  @override
  Iterable<DynamicCallTarget> findRootsOfTargets(Selector selector,
      MemberHierarchyBuilder memberHierarchyBuilder, JClosedWorld closedWorld) {
    if (isEmptyOrSpecial) return const [];
    final baseClass = base!;
    if (closedWorld.isDefaultSuperclass(baseClass)) {
      // Filter roots using the mask's class since each default superclass has
      // distinct roots.
      final results =
          memberHierarchyBuilder.rootsForSelector(baseClass, selector);
      return results.isEmpty ? const [] : results;
    }

    // Try to find a superclass that contains a matching member.
    final superclassMatch = memberHierarchyBuilder.findSuperclassTarget(
        baseClass, selector,
        isExact: isExact, isSubclass: isSubclass);

    // If this mask is exact then we should have found a matching target on a
    // superclass or need noSuchMethod handling and can quit early anyway.
    // Otherwise only return if we actually found a match.
    if (isExact || superclassMatch.isNotEmpty) return superclassMatch;

    // Default to a list of superclasses/supertypes that encompasses all
    // subclasses/subtypes of this type cone.
    return memberHierarchyBuilder.findMatchingAncestors(baseClass, selector,
        isSubtype: isSubtype);
  }

  @override
  bool operator ==(var other) {
    if (identical(this, other)) return true;
    if (other is! FlatTypeMask) return false;
    FlatTypeMask otherMask = other;
    return (flags == otherMask.flags) && (base == otherMask.base);
  }

  @override
  int get hashCode {
    return (base == null ? 0 : base.hashCode) + 31 * flags.hashCode;
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
    ], '|');
    buffer.write(']');
    return buffer.toString();
  }
}
