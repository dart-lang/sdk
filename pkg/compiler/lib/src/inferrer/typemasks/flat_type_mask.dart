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
  static const int _USED_INDICES = 1;

  static const int _NONE_MASK = 0;
  static const int _NULL_MASK = 1 << _NULL_INDEX;
  static const int _ALL_MASK = (1 << _USED_INDICES) - 1;

  final ClassEntity base;
  final int flags;

  static int _computeFlags(_FlatTypeMaskKind kind, {bool hasNull: false}) {
    int mask = _NONE_MASK;
    if (hasNull) mask |= _NULL_MASK;
    return _computeFlagsRaw(kind.index, mask);
  }

  static int _computeFlagsRaw(int kind, int mask) =>
      kind << _USED_INDICES | mask;

  static _FlatTypeMaskKind _lookupKind(int flags) =>
      _FlatTypeMaskKind.values[flags >> _USED_INDICES];

  static bool _hasNullFlag(int flags) => flags & _NULL_MASK != _NONE_MASK;

  factory FlatTypeMask.exact(ClassEntity base, JClosedWorld world) =>
      FlatTypeMask._canonicalize(base, _FlatTypeMaskKind.exact, world,
          isNullable: true);
  factory FlatTypeMask.subclass(ClassEntity base, JClosedWorld world) =>
      FlatTypeMask._canonicalize(base, _FlatTypeMaskKind.subclass, world,
          isNullable: true);
  factory FlatTypeMask.subtype(ClassEntity base, JClosedWorld world) =>
      FlatTypeMask._canonicalize(base, _FlatTypeMaskKind.subtype, world,
          isNullable: true);

  factory FlatTypeMask.nonNullEmpty() => const FlatTypeMask._(null, _NONE_MASK);

  factory FlatTypeMask.empty() => const FlatTypeMask._(null, _NULL_MASK);

  factory FlatTypeMask.nonNullExact(ClassEntity base, JClosedWorld world) =>
      FlatTypeMask._canonicalize(base, _FlatTypeMaskKind.exact, world);
  factory FlatTypeMask.nonNullSubclass(ClassEntity base, JClosedWorld world) =>
      FlatTypeMask._canonicalize(base, _FlatTypeMaskKind.subclass, world);
  factory FlatTypeMask.nonNullSubtype(ClassEntity base, JClosedWorld world) =>
      FlatTypeMask._canonicalize(base, _FlatTypeMaskKind.subtype, world);

  factory FlatTypeMask._canonicalize(
      ClassEntity base, _FlatTypeMaskKind kind, JClosedWorld world,
      {bool isNullable: false}) {
    if (base == world.commonElements.nullClass) {
      return FlatTypeMask.empty();
    }
    return FlatTypeMask._(base, _computeFlags(kind, hasNull: isNullable));
  }

  const FlatTypeMask._(this.base, this.flags);

  /// Ensures that the generated mask is normalized, i.e., a call to
  /// [TypeMask.assertIsNormalized] with the factory's result returns `true`.
  factory FlatTypeMask.normalized(
      ClassEntity base, int flags, CommonMasks domain) {
    bool isNullable = _hasNullFlag(flags);
    if (base == domain.commonElements.nullClass) {
      return FlatTypeMask.empty();
    }
    _FlatTypeMaskKind kind = _lookupKind(flags);
    if (kind == _FlatTypeMaskKind.empty || kind == _FlatTypeMaskKind.exact) {
      return FlatTypeMask._(base, flags);
    }
    if (kind == _FlatTypeMaskKind.subtype) {
      if (!domain._closedWorld.classHierarchy.hasAnyStrictSubtype(base) ||
          domain._closedWorld.classHierarchy.hasOnlySubclasses(base)) {
        flags = _computeFlags(_FlatTypeMaskKind.subclass, hasNull: isNullable);
      }
    }
    if (kind == _FlatTypeMaskKind.subclass &&
        !domain._closedWorld.classHierarchy.hasAnyStrictSubclass(base)) {
      flags = _computeFlags(_FlatTypeMaskKind.exact, hasNull: isNullable);
    }
    return domain.getCachedMask(base, flags, () => FlatTypeMask._(base, flags));
  }

  /// Deserializes a [FlatTypeMask] object from [source].
  factory FlatTypeMask.readFromDataSource(
      DataSource source, CommonMasks domain) {
    source.begin(tag);
    ClassEntity base = source.readClassOrNull();
    int flags = source.readInt();
    source.end(tag);
    return domain.getCachedMask(base, flags, () => FlatTypeMask._(base, flags));
  }

  /// Serializes this [FlatTypeMask] to [sink].
  @override
  void writeToDataSink(DataSink sink) {
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
  bool get isNullable => _hasNullFlag(flags);

  @override
  bool get isUnion => false;
  @override
  bool get isContainer => false;
  @override
  bool get isSet => false;
  @override
  bool get isMap => false;
  @override
  bool get isDictionary => false;
  @override
  bool get isForwarding => false;
  @override
  bool get isValue => false;

  // TODO(kasperl): Get rid of these. They should not be a visible
  // part of the implementation because they make it hard to add
  // proper union types if we ever want to.
  bool get isSubclass => _kind == _FlatTypeMaskKind.subclass;
  bool get isSubtype => _kind == _FlatTypeMaskKind.subtype;

  @override
  FlatTypeMask withFlags({bool isNullable}) {
    int newFlags = _computeFlags(_kind, hasNull: isNullable ?? this.isNullable);
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
      return closedWorld.classHierarchy.isSubclassOf(other, base);
    } else {
      assert(isSubtype);
      return closedWorld.classHierarchy.isSubtypeOf(other, base);
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
    // The empty type contains no classes.
    if (isEmptyOrFlagged) return true;
    if (other.isEmptyOrFlagged) return false;
    other = TypeMask.nonForwardingMask(other);
    // If other is union, delegate to UnionTypeMask.containsMask.
    if (other is! FlatTypeMask) return other.containsMask(this, closedWorld);
    // The other must be flat, so compare base and flags.
    FlatTypeMask flatOther = other;
    ClassEntity otherBase = flatOther.base;
    // If other is exact, it only contains its base.
    // TODO(herhut): Get rid of _isSingleImplementationOf.
    if (flatOther.isExact) {
      return (isExact && base == otherBase) ||
          _isSingleImplementationOf(otherBase, closedWorld);
    }
    // If other is subclass, this has to be subclass, as well. Unless
    // flatOther.base covers all subtypes of this. Currently, we only
    // consider object to behave that way.
    // TODO(herhut): Add check whether flatOther.base is superclass of
    //               all subclasses of this.base.
    if (flatOther.isSubclass) {
      if (isSubtype)
        return (otherBase == closedWorld.commonElements.objectClass);
      return closedWorld.classHierarchy.isSubclassOf(base, otherBase);
    }
    assert(flatOther.isSubtype);
    // Check whether this TypeMask satisfies otherBase's interface.
    return satisfies(otherBase, closedWorld);
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
    if (closedWorld.classHierarchy.isSubtypeOf(base, cls)) return true;
    return false;
  }

  @override
  ClassEntity singleClass(JClosedWorld closedWorld) {
    if (isEmptyOrFlagged) return null;
    if (isNullable) return null; // It is Null and some other class.
    if (isExact) {
      return base;
    } else if (isSubclass) {
      return closedWorld.classHierarchy.hasAnyStrictSubclass(base)
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
    assert(other != null);
    assert(TypeMask.assertIsNormalized(this, closedWorld));
    assert(TypeMask.assertIsNormalized(other, closedWorld));
    if (other is! FlatTypeMask) return other.union(this, domain);
    FlatTypeMask flatOther = other;
    bool isNullable = this.isNullable || flatOther.isNullable;
    if (isEmptyOrFlagged) {
      return flatOther.withFlags(isNullable: isNullable);
    } else if (flatOther.isEmptyOrFlagged) {
      return withFlags(isNullable: isNullable);
    } else if (base == flatOther.base) {
      return unionSame(flatOther, domain);
    } else if (closedWorld.classHierarchy.isSubclassOf(flatOther.base, base)) {
      return unionStrictSubclass(flatOther, domain);
    } else if (closedWorld.classHierarchy.isSubclassOf(base, flatOther.base)) {
      return flatOther.unionStrictSubclass(this, domain);
    } else if (closedWorld.classHierarchy.isSubtypeOf(flatOther.base, base)) {
      return unionStrictSubtype(flatOther, domain);
    } else if (closedWorld.classHierarchy.isSubtypeOf(base, flatOther.base)) {
      return flatOther.unionStrictSubtype(this, domain);
    } else {
      return UnionTypeMask._internal(
          <FlatTypeMask>[withoutFlags(), flatOther.withoutFlags()],
          isNullable: isNullable);
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
      return FlatTypeMask.normalized(base, combined, domain);
    }
  }

  TypeMask unionStrictSubclass(FlatTypeMask other, CommonMasks domain) {
    assert(base != other.base);
    assert(domain._closedWorld.classHierarchy.isSubclassOf(other.base, base));
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
    assert(!domain._closedWorld.classHierarchy.isSubclassOf(other.base, base));
    assert(domain._closedWorld.classHierarchy.isSubtypeOf(other.base, base));
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
    assert(other != null);
    if (other is! FlatTypeMask) return other.intersection(this, domain);
    assert(TypeMask.assertIsNormalized(this, domain._closedWorld));
    assert(TypeMask.assertIsNormalized(other, domain._closedWorld));
    FlatTypeMask flatOther = other;

    ClassEntity otherBase = flatOther.base;

    bool includeNull = isNullable && flatOther.isNullable;

    if (isEmptyOrFlagged) {
      return withFlags(isNullable: includeNull);
    } else if (flatOther.isEmptyOrFlagged) {
      return other.withFlags(isNullable: includeNull);
    }

    SubclassResult result = domain._closedWorld.classHierarchy
        .commonSubclasses(base, _classQuery, otherBase, flatOther._classQuery);

    switch (result.kind) {
      case SubclassResultKind.EMPTY:
        return includeNull ? domain.nullType : domain.emptyType;
      case SubclassResultKind.EXACT1:
        assert(isExact);
        return includeNull ? this : nonNullable();
      case SubclassResultKind.EXACT2:
        assert(other.isExact);
        return includeNull ? other : other.nonNullable();
      case SubclassResultKind.SUBCLASS1:
        assert(isSubclass);
        return includeNull ? this : nonNullable();
      case SubclassResultKind.SUBCLASS2:
        assert(flatOther.isSubclass);
        return includeNull ? other : other.nonNullable();
      case SubclassResultKind.SUBTYPE1:
        assert(isSubtype);
        return includeNull ? this : nonNullable();
      case SubclassResultKind.SUBTYPE2:
        assert(flatOther.isSubtype);
        return includeNull ? other : other.nonNullable();
      case SubclassResultKind.SET:
      default:
        if (result.classes.isEmpty) {
          return includeNull ? domain.nullType : domain.emptyType;
        } else if (result.classes.length == 1) {
          ClassEntity cls = result.classes.first;
          return includeNull
              ? TypeMask.subclass(cls, domain._closedWorld)
              : TypeMask.nonNullSubclass(cls, domain._closedWorld);
        }

        List<FlatTypeMask> masks = List.from(result.classes.map(
            (ClassEntity cls) =>
                TypeMask.nonNullSubclass(cls, domain._closedWorld)));
        if (masks.length > UnionTypeMask.MAX_UNION_LENGTH) {
          return UnionTypeMask.flatten(masks, domain, includeNull: includeNull);
        }
        return UnionTypeMask._internal(masks, isNullable: includeNull);
    }
  }

  @override
  bool isDisjoint(TypeMask other, JClosedWorld closedWorld) {
    if (other is! FlatTypeMask) return other.isDisjoint(this, closedWorld);
    FlatTypeMask flatOther = other;

    if (isNullable && flatOther.isNullable) return false;
    if (isEmptyOrFlagged || flatOther.isEmptyOrFlagged) return true;
    if (base == flatOther.base) return false;
    if (isExact && flatOther.isExact) return true;

    if (isExact) return !flatOther.contains(base, closedWorld);
    if (flatOther.isExact) return !contains(flatOther.base, closedWorld);

    // Normalization guarantees that isExact === !isSubclass && !isSubtype.
    // Both are subclass or subtype masks, so if there is a subclass
    // relationship, they are not disjoint.
    if (closedWorld.classHierarchy.isSubclassOf(flatOther.base, base)) {
      return false;
    }
    if (closedWorld.classHierarchy.isSubclassOf(base, flatOther.base)) {
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
    var elements = a.isSubclass
        ? closedWorld.classHierarchy.strictSubclassesOf(a.base)
        : closedWorld.classHierarchy.strictSubtypesOf(a.base);
    for (var element in elements) {
      if (closedWorld.classHierarchy.isSubtypeOf(element, b.base)) return false;
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
    assert(domain._closedWorld.classHierarchy.isSubclassOf(other.base, base));
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
    return isNullable ? TypeMask.empty() : TypeMask.nonNullEmpty();
  }

  @override
  bool canHit(MemberEntity element, Name name, JClosedWorld closedWorld) {
    CommonElements commonElements = closedWorld.commonElements;
    assert(element.name == name.text);
    if (isEmptyOrFlagged) {
      return isNullable &&
          closedWorld.hasElementIn(commonElements.jsNullClass, name, element);
    }

    ClassEntity other = element.enclosingClass;
    if (other == commonElements.jsNullClass) {
      return isNullable;
    } else if (isExact) {
      return closedWorld.hasElementIn(base, name, element);
    } else if (isSubclass) {
      return closedWorld.hasElementIn(base, name, element) ||
          closedWorld.classHierarchy.isSubclassOf(other, base) ||
          closedWorld.hasAnySubclassThatMixes(base, other);
    } else {
      assert(isSubtype);
      bool result = closedWorld.hasElementIn(base, name, element) ||
          closedWorld.classHierarchy.isSubtypeOf(other, base) ||
          closedWorld.hasAnySubclassThatImplements(other, base) ||
          closedWorld.hasAnySubclassOfMixinUseThatImplements(other, base);
      if (result) return true;
      // If the class is used as a mixin, we have to check if the element
      // can be hit from any of the mixin applications.
      Iterable<ClassEntity> mixinUses = closedWorld.mixinUsesOf(base);
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
    if (isExact && base.isAbstract) return false;

    return closedWorld.needsNoSuchMethod(base, selector, _classQuery);
  }

  @override
  MemberEntity locateSingleMember(Selector selector, CommonMasks domain) {
    if (isEmptyOrFlagged) return null;
    JClosedWorld closedWorld = domain._closedWorld;
    if (closedWorld.includesClosureCallInDomain(selector, this, domain))
      return null;
    Iterable<MemberEntity> targets =
        closedWorld.locateMembersInDomain(selector, this, domain);
    if (targets.length != 1) return null;
    MemberEntity result = targets.first;
    ClassEntity enclosing = result.enclosingClass;
    // We only return the found element if it is guaranteed to be implemented on
    // all classes in the receiver type [this]. It could be found only in a
    // subclass or in an inheritance-wise unrelated class in case of subtype
    // selectors.
    if (isSubtype) {
      // if (closedWorld.isUsedAsMixin(enclosing)) {
      if (closedWorld.everySubtypeIsSubclassOfOrMixinUseOf(base, enclosing)) {
        return result;
      }
      //}
      return null;
    } else {
      if (closedWorld.classHierarchy.isSubclassOf(base, enclosing)) {
        return result;
      }
      if (closedWorld.isSubclassOfMixinUseOf(base, enclosing)) return result;
    }
    return null;
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
      if (isExact) 'exact=${base.name}',
      if (isSubclass) 'subclass=${base.name}',
      if (isSubtype) 'subtype=${base.name}',
    ], '|');
    buffer.write(']');
    return buffer.toString();
  }
}
