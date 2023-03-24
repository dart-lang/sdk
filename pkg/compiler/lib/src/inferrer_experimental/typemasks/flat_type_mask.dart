// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of masks;

enum _FlatTypeMaskKind { empty, exact, subclass, subtype }

/// A flat type mask is a type mask that has been flattened to contain a
/// base type.
class FlatTypeMask extends TypeMask {
  /// Tag used for identifying serialized [FlatTypeMask] objects in a
  /// debugging data stream.
  static const String tag = 'flat-type-mask';

  static const int _NULL_INDEX = 0;
  static const int _LATE_SENTINEL_INDEX = 1;
  static const int _USED_INDICES = 2;

  static const int _NONE_MASK = 0;
  static const int _NULL_MASK = 1 << _NULL_INDEX;
  static const int _LATE_SENTINEL_MASK = 1 << _LATE_SENTINEL_INDEX;
  static const int _ALL_MASK = (1 << _USED_INDICES) - 1;

  final ClassEntity? base;
  final int flags;

  static int _computeFlags(_FlatTypeMaskKind kind,
      {bool isNullable = false, bool hasLateSentinel = false}) {
    int mask = _NONE_MASK;
    if (isNullable) mask |= _NULL_MASK;
    if (hasLateSentinel) mask |= _LATE_SENTINEL_MASK;
    return _computeFlagsRaw(kind.index, mask);
  }

  static int _computeFlagsRaw(int kind, int mask) =>
      kind << _USED_INDICES | mask;

  static _FlatTypeMaskKind _lookupKind(int flags) =>
      _FlatTypeMaskKind.values[flags >> _USED_INDICES];

  static bool _hasNullableFlag(int flags) => flags & _NULL_MASK != _NONE_MASK;

  static bool _hasLateSentinelFlag(int flags) =>
      flags & _LATE_SENTINEL_MASK != _NONE_MASK;

  factory FlatTypeMask.exact(ClassEntity base, JClosedWorld world,
          {bool hasLateSentinel = false}) =>
      FlatTypeMask._canonicalize(base, _FlatTypeMaskKind.exact, world,
          isNullable: true, hasLateSentinel: hasLateSentinel);
  factory FlatTypeMask.subclass(ClassEntity base, JClosedWorld world,
          {bool hasLateSentinel = false}) =>
      FlatTypeMask._canonicalize(base, _FlatTypeMaskKind.subclass, world,
          isNullable: true, hasLateSentinel: hasLateSentinel);
  factory FlatTypeMask.subtype(ClassEntity base, JClosedWorld world,
          {bool hasLateSentinel = false}) =>
      FlatTypeMask._canonicalize(base, _FlatTypeMaskKind.subtype, world,
          isNullable: true, hasLateSentinel: hasLateSentinel);

  factory FlatTypeMask.nonNullEmpty({bool hasLateSentinel = false}) =>
      hasLateSentinel
          ? const FlatTypeMask._(null, _LATE_SENTINEL_MASK)
          : const FlatTypeMask._(null, _NONE_MASK);

  factory FlatTypeMask.empty({bool hasLateSentinel = false}) => hasLateSentinel
      ? const FlatTypeMask._(null, _NULL_MASK | _LATE_SENTINEL_MASK)
      : const FlatTypeMask._(null, _NULL_MASK);

  factory FlatTypeMask.nonNullExact(ClassEntity base, JClosedWorld world,
          {bool hasLateSentinel = false}) =>
      FlatTypeMask._canonicalize(base, _FlatTypeMaskKind.exact, world,
          hasLateSentinel: hasLateSentinel);
  factory FlatTypeMask.nonNullSubclass(ClassEntity base, JClosedWorld world,
          {bool hasLateSentinel = false}) =>
      FlatTypeMask._canonicalize(base, _FlatTypeMaskKind.subclass, world,
          hasLateSentinel: hasLateSentinel);
  factory FlatTypeMask.nonNullSubtype(ClassEntity base, JClosedWorld world,
          {bool hasLateSentinel = false}) =>
      FlatTypeMask._canonicalize(base, _FlatTypeMaskKind.subtype, world,
          hasLateSentinel: hasLateSentinel);

  factory FlatTypeMask._canonicalize(
      ClassEntity base, _FlatTypeMaskKind kind, JClosedWorld world,
      {bool isNullable = false, bool hasLateSentinel = false}) {
    if (base == world.commonElements.nullClass) {
      return FlatTypeMask.empty(hasLateSentinel: hasLateSentinel);
    }
    return FlatTypeMask._(
        base,
        _computeFlags(kind,
            isNullable: isNullable, hasLateSentinel: hasLateSentinel));
  }

  const FlatTypeMask._(this.base, this.flags);

  /// Ensures that the generated mask is normalized, i.e., a call to
  /// [TypeMask.assertIsNormalized] with the factory's result returns `true`.
  factory FlatTypeMask.normalized(
      ClassEntity? base, int flags, CommonMasks domain) {
    bool isNullable = _hasNullableFlag(flags);
    bool hasLateSentinel = _hasLateSentinelFlag(flags);
    if (base == domain.commonElements.nullClass) {
      return FlatTypeMask.empty(hasLateSentinel: hasLateSentinel);
    }
    _FlatTypeMaskKind kind = _lookupKind(flags);
    if (kind == _FlatTypeMaskKind.empty || kind == _FlatTypeMaskKind.exact) {
      return FlatTypeMask._(base, flags);
    }
    if (kind == _FlatTypeMaskKind.subtype) {
      if (!domain._closedWorld.classHierarchy.hasAnyStrictSubtype(base!) ||
          domain._closedWorld.classHierarchy.hasOnlySubclasses(base)) {
        flags = _computeFlags(_FlatTypeMaskKind.subclass,
            isNullable: isNullable, hasLateSentinel: hasLateSentinel);
      }
    }
    if (kind == _FlatTypeMaskKind.subclass &&
        !domain._closedWorld.classHierarchy.hasAnyStrictSubclass(base!)) {
      flags = _computeFlags(_FlatTypeMaskKind.exact,
          isNullable: isNullable, hasLateSentinel: hasLateSentinel);
    }
    return domain.getCachedMask(base, flags, () => FlatTypeMask._(base, flags));
  }

  /// Deserializes a [FlatTypeMask] object from [source].
  factory FlatTypeMask.readFromDataSource(
      DataSourceReader source, CommonMasks domain) {
    source.begin(tag);
    final base = source.readClassOrNull();
    int flags = source.readInt();
    source.end(tag);
    return domain.getCachedMask(base, flags, () => FlatTypeMask._(base, flags));
  }

  /// Serializes this [FlatTypeMask] to [sink].
  @override
  void writeToDataSink(DataSinkWriter sink) {
    sink.writeEnum(TypeMaskKind.flat);
    sink.begin(tag);
    sink.writeClassOrNull(base);
    sink.writeInt(flags);
    sink.end(tag);
  }

  _FlatTypeMaskKind get _kind => _lookupKind(flags);

  int get _mask => flags & _ALL_MASK;

  ClassQuery get _classQuery => isExact
      ? ClassQuery.EXACT
      : (isSubclass ? ClassQuery.SUBCLASS : ClassQuery.SUBTYPE);

  @override
  bool get isEmpty => isEmptyOrFlagged && _mask == _NONE_MASK;
  @override
  bool get isNull => isEmptyOrFlagged && _mask == _NULL_MASK;
  @override
  bool get isEmptyOrFlagged => _kind == _FlatTypeMaskKind.empty;
  @override
  bool get isExact => _kind == _FlatTypeMaskKind.exact;
  @override
  bool get isNullable => _hasNullableFlag(flags);
  @override
  bool get hasLateSentinel => _hasLateSentinelFlag(flags);
  @override
  AbstractBool get isLateSentinel {
    if (!hasLateSentinel) return AbstractBool.False;
    if (isEmptyOrFlagged && _mask == _LATE_SENTINEL_MASK) {
      return AbstractBool.True;
    }
    return AbstractBool.Maybe;
  }

  // TODO(kasperl): Get rid of these. They should not be a visible
  // part of the implementation because they make it hard to add
  // proper union types if we ever want to.
  bool get isSubclass => _kind == _FlatTypeMaskKind.subclass;
  bool get isSubtype => _kind == _FlatTypeMaskKind.subtype;

  @override
  FlatTypeMask withFlags({bool? isNullable, bool? hasLateSentinel}) {
    int newFlags = _computeFlags(_kind,
        isNullable: isNullable ?? this.isNullable,
        hasLateSentinel: hasLateSentinel ?? this.hasLateSentinel);
    if (newFlags == flags) return this;
    return FlatTypeMask._(base, newFlags);
  }

  @override
  bool contains(ClassEntity other, JClosedWorld closedWorld) {
    if (isEmptyOrFlagged) {
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
    if (isEmptyOrFlagged) return true;
    if (other.isEmptyOrFlagged) return false;
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
    if (isEmptyOrFlagged) return false;
    if (closedWorld.classHierarchy.isSubtypeOf(base!, cls)) return true;
    return false;
  }

  @override
  ClassEntity? singleClass(JClosedWorld closedWorld) {
    if (isEmptyOrFlagged) return null;
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
    if (isEmptyOrFlagged || isExact) return false;
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
    if (isEmptyOrFlagged) {
      return flatOther.withFlags(
          isNullable: isNullable, hasLateSentinel: hasLateSentinel);
    } else if (flatOther.isEmptyOrFlagged) {
      return withFlags(
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
      return UnionTypeMask._internal([
        withoutFlags() as FlatTypeMask,
        flatOther.withoutFlags() as FlatTypeMask
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
    int combined =
        (flags > other.flags) ? flags | other._mask : other.flags | _mask;
    if (flags == combined) {
      return this;
    } else if (other.flags == combined) {
      return other;
    } else {
      return FlatTypeMask.normalized(base!, combined, domain);
    }
  }

  TypeMask unionStrictSubclass(FlatTypeMask other, CommonMasks domain) {
    assert(base != other.base);
    assert(domain._closedWorld.classHierarchy.isSubclassOf(other.base!, base!));
    assert(TypeMask.assertIsNormalized(this, domain._closedWorld));
    assert(TypeMask.assertIsNormalized(other, domain._closedWorld));
    int combined;
    if ((isExact && other.isExact) ||
        base == domain.commonElements.objectClass) {
      // Since the other mask is a subclass of this mask, we need the
      // resulting union to be a subclass too. If either one of the
      // masks are nullable the result should be nullable too.
      combined = _computeFlagsRaw(
          _FlatTypeMaskKind.subclass.index, _mask | other._mask);
    } else {
      // Both masks are at least subclass masks, so we pick the least
      // constraining kind (the highest) of the two. If either one of
      // the masks are nullable the result should be nullable too.
      combined =
          (flags > other.flags) ? flags | other._mask : other.flags | _mask;
    }
    // If we weaken the constraint on this type, we have to make sure that
    // the result is normalized.
    return flags != combined
        ? FlatTypeMask.normalized(base, combined, domain)
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
    int combined =
        _computeFlagsRaw(_FlatTypeMaskKind.subtype.index, _mask | other._mask);
    // We know there is at least one subtype, [other.base], so no need
    // to normalize.
    return flags != combined
        ? FlatTypeMask.normalized(base, combined, domain)
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

    if (isEmptyOrFlagged) {
      return withFlags(
          isNullable: includeNull, hasLateSentinel: includeLateSentinel);
    } else if (flatOther.isEmptyOrFlagged) {
      return other.withFlags(
          isNullable: includeNull, hasLateSentinel: includeLateSentinel);
    }

    SubclassResult result = domain._closedWorld.classHierarchy.commonSubclasses(
        base!, _classQuery, otherBase!, flatOther._classQuery);

    switch (result.kind) {
      case SubclassResultKind.EMPTY:
        return includeNull
            ? TypeMask.empty(hasLateSentinel: includeLateSentinel)
            : TypeMask.nonNullEmpty(hasLateSentinel: includeLateSentinel);
      case SubclassResultKind.EXACT1:
        assert(isExact);
        return withFlags(
            isNullable: includeNull, hasLateSentinel: includeLateSentinel);
      case SubclassResultKind.EXACT2:
        assert(other.isExact);
        return other.withFlags(
            isNullable: includeNull, hasLateSentinel: includeLateSentinel);
      case SubclassResultKind.SUBCLASS1:
        assert(isSubclass);
        return withFlags(
            isNullable: includeNull, hasLateSentinel: includeLateSentinel);
      case SubclassResultKind.SUBCLASS2:
        assert(flatOther.isSubclass);
        return other.withFlags(
            isNullable: includeNull, hasLateSentinel: includeLateSentinel);
      case SubclassResultKind.SUBTYPE1:
        assert(isSubtype);
        return withFlags(
            isNullable: includeNull, hasLateSentinel: includeLateSentinel);
      case SubclassResultKind.SUBTYPE2:
        assert(flatOther.isSubtype);
        return other.withFlags(
            isNullable: includeNull, hasLateSentinel: includeLateSentinel);
      case SubclassResultKind.SET:
      default:
        if (result.classes.isEmpty) {
          return includeNull
              ? TypeMask.empty(hasLateSentinel: includeLateSentinel)
              : TypeMask.nonNullEmpty(hasLateSentinel: includeLateSentinel);
        } else if (result.classes.length == 1) {
          ClassEntity cls = result.classes.first;
          return includeNull
              ? TypeMask.subclass(cls, domain._closedWorld,
                  hasLateSentinel: includeLateSentinel)
              : TypeMask.nonNullSubclass(cls, domain._closedWorld,
                  hasLateSentinel: includeLateSentinel);
        }

        List<FlatTypeMask> masks = List.from(result.classes.map(
            (ClassEntity cls) =>
                TypeMask.nonNullSubclass(cls, domain._closedWorld)));
        if (masks.length > UnionTypeMask.MAX_UNION_LENGTH) {
          return UnionTypeMask.flatten(masks, domain,
              includeNull: includeNull,
              includeLateSentinel: includeLateSentinel);
        }
        return UnionTypeMask._internal(masks,
            isNullable: includeNull, hasLateSentinel: includeLateSentinel);
    }
  }

  @override
  bool isDisjoint(TypeMask other, JClosedWorld closedWorld) {
    if (other is! FlatTypeMask) return other.isDisjoint(this, closedWorld);
    FlatTypeMask flatOther = other;

    if (isNullable && flatOther.isNullable) return false;
    if (hasLateSentinel && flatOther.hasLateSentinel) return false;
    if (isEmptyOrFlagged || flatOther.isEmptyOrFlagged) return true;
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
    int combined = (flags < other.flags)
        ? flags & (other._mask | ~_ALL_MASK)
        : other.flags & (_mask | ~_ALL_MASK);
    if (flags == combined) {
      return this;
    } else if (other.flags == combined) {
      return other;
    } else {
      return FlatTypeMask.normalized(base, combined, domain);
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
    int combined = other.flags & (_mask | ~_ALL_MASK);
    if (other.flags == combined) {
      return other;
    } else {
      return FlatTypeMask.normalized(other.base, combined, domain);
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
    if (isEmptyOrFlagged) {
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
    if (isEmptyOrFlagged) return false;
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
    if (isEmptyOrFlagged) return null;
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
    if (isEmptyOrFlagged) return const [];
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
