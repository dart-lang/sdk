// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of masks;

/// A flat type mask is a type mask that has been flattened to contain a
/// base type.
class FlatTypeMask implements TypeMask {
  /// Tag used for identifying serialized [FlatTypeMask] objects in a
  /// debugging data stream.
  static const String tag = 'flat-type-mask';

  static const int EMPTY = 0;
  static const int EXACT = 1;
  static const int SUBCLASS = 2;
  static const int SUBTYPE = 3;

  final ClassEntity base;
  final int flags;

  factory FlatTypeMask.exact(ClassEntity base, JClosedWorld world) =>
      FlatTypeMask._canonicalize(base, EXACT, true, world);
  factory FlatTypeMask.subclass(ClassEntity base, JClosedWorld world) =>
      FlatTypeMask._canonicalize(base, SUBCLASS, true, world);
  factory FlatTypeMask.subtype(ClassEntity base, JClosedWorld world) =>
      FlatTypeMask._canonicalize(base, SUBTYPE, true, world);

  const FlatTypeMask.nonNullEmpty()
      : base = null,
        flags = 0;
  const FlatTypeMask.empty()
      : base = null,
        flags = 1;

  factory FlatTypeMask.nonNullExact(ClassEntity base, JClosedWorld world) =>
      FlatTypeMask._canonicalize(base, EXACT, false, world);
  factory FlatTypeMask.nonNullSubclass(ClassEntity base, JClosedWorld world) =>
      FlatTypeMask._canonicalize(base, SUBCLASS, false, world);
  factory FlatTypeMask.nonNullSubtype(ClassEntity base, JClosedWorld world) =>
      FlatTypeMask._canonicalize(base, SUBTYPE, false, world);

  factory FlatTypeMask._canonicalize(
      ClassEntity base, int kind, bool isNullable, JClosedWorld world) {
    if (base == world.commonElements.nullClass) {
      return FlatTypeMask.empty();
    }
    return FlatTypeMask._(base, (kind << 1) | (isNullable ? 1 : 0));
  }

  FlatTypeMask._(this.base, this.flags);

  /// Ensures that the generated mask is normalized, i.e., a call to
  /// [TypeMask.assertIsNormalized] with the factory's result returns `true`.
  factory FlatTypeMask.normalized(
      ClassEntity base, int flags, CommonMasks domain) {
    if (base == domain.commonElements.nullClass) {
      return FlatTypeMask.empty();
    }
    if ((flags >> 1) == EMPTY || ((flags >> 1) == EXACT)) {
      return new FlatTypeMask._(base, flags);
    }
    if ((flags >> 1) == SUBTYPE) {
      if (!domain._closedWorld.classHierarchy.hasAnyStrictSubtype(base) ||
          domain._closedWorld.classHierarchy.hasOnlySubclasses(base)) {
        flags = (flags & 0x1) | (SUBCLASS << 1);
      }
    }
    if (((flags >> 1) == SUBCLASS) &&
        !domain._closedWorld.classHierarchy.hasAnyStrictSubclass(base)) {
      flags = (flags & 0x1) | (EXACT << 1);
    }
    return domain.getCachedMask(
        base, flags, () => new FlatTypeMask._(base, flags));
  }

  /// Deserializes a [FlatTypeMask] object from [source].
  factory FlatTypeMask.readFromDataSource(
      DataSource source, CommonMasks domain) {
    source.begin(tag);
    ClassEntity base = source.readClassOrNull();
    int flags = source.readInt();
    source.end(tag);
    return domain.getCachedMask(
        base, flags, () => new FlatTypeMask._(base, flags));
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

  ClassQuery get _classQuery => isExact
      ? ClassQuery.EXACT
      : (isSubclass ? ClassQuery.SUBCLASS : ClassQuery.SUBTYPE);

  @override
  bool get isEmpty => isEmptyOrNull && !isNullable;
  @override
  bool get isNull => isEmptyOrNull && isNullable;
  @override
  bool get isEmptyOrNull => (flags >> 1) == EMPTY;
  @override
  bool get isExact => (flags >> 1) == EXACT;
  @override
  bool get isNullable => (flags & 1) != 0;

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
  bool get isSubclass => (flags >> 1) == SUBCLASS;
  bool get isSubtype => (flags >> 1) == SUBTYPE;

  @override
  TypeMask nullable() {
    return isNullable ? this : new FlatTypeMask._(base, flags | 1);
  }

  @override
  TypeMask nonNullable() {
    return isNullable ? new FlatTypeMask._(base, flags & ~1) : this;
  }

  @override
  bool contains(ClassEntity other, JClosedWorld closedWorld) {
    if (isEmptyOrNull) {
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

  bool isSingleImplementationOf(ClassEntity cls, JClosedWorld closedWorld) {
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
    if (containsOnlyDouble(closedWorld)) {
      return cls == closedWorld.commonElements.doubleClass ||
          cls == commonElements.jsDoubleClass;
    }
    return false;
  }

  @override
  bool isInMask(TypeMask other, JClosedWorld closedWorld) {
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
    ClassEntity otherBase = flatOther.base;
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
    return base == closedWorld.commonElements.intClass ||
        base == commonElements.jsIntClass ||
        base == commonElements.jsPositiveIntClass ||
        base == commonElements.jsUInt31Class ||
        base == commonElements.jsUInt32Class;
  }

  @override
  bool containsOnlyDouble(JClosedWorld closedWorld) {
    return base == closedWorld.commonElements.doubleClass ||
        base == closedWorld.commonElements.jsDoubleClass;
  }

  @override
  bool containsOnlyNum(JClosedWorld closedWorld) {
    return containsOnlyInt(closedWorld) ||
        containsOnlyDouble(closedWorld) ||
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
    if (isEmptyOrNull) return false;
    if (closedWorld.classHierarchy.isSubtypeOf(base, cls)) return true;
    return false;
  }

  @override
  ClassEntity singleClass(JClosedWorld closedWorld) {
    if (isEmptyOrNull) return null;
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
    if (isEmptyOrNull || isExact) return false;
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
    if (isEmptyOrNull) {
      return isNullable ? flatOther.nullable() : flatOther;
    } else if (flatOther.isEmptyOrNull) {
      return flatOther.isNullable ? nullable() : this;
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
      return new UnionTypeMask._internal(
          <FlatTypeMask>[this.nonNullable(), flatOther.nonNullable()],
          isNullable || other.isNullable);
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
    int combined = (flags > other.flags)
        ? flags | (other.flags & 1)
        : other.flags | (flags & 1);
    if (flags == combined) {
      return this;
    } else if (other.flags == combined) {
      return other;
    } else {
      return new FlatTypeMask.normalized(base, combined, domain);
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
        ? new FlatTypeMask.normalized(base, combined, domain)
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
    int combined = (SUBTYPE << 1) | ((flags | other.flags) & 1);
    // We know there is at least one subtype, [other.base], so no need
    // to normalize.
    return (flags != combined)
        ? new FlatTypeMask.normalized(base, combined, domain)
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

    if (isEmptyOrNull) {
      return includeNull ? this : nonNullable();
    } else if (flatOther.isEmptyOrNull) {
      return includeNull ? other : other.nonNullable();
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
              ? new TypeMask.subclass(cls, domain._closedWorld)
              : new TypeMask.nonNullSubclass(cls, domain._closedWorld);
        }

        List<FlatTypeMask> masks = List.from(result.classes.map(
            (ClassEntity cls) =>
                TypeMask.nonNullSubclass(cls, domain._closedWorld)));
        if (masks.length > UnionTypeMask.MAX_UNION_LENGTH) {
          return UnionTypeMask.flatten(masks, includeNull, domain);
        }
        return new UnionTypeMask._internal(masks, includeNull);
    }
  }

  @override
  bool isDisjoint(TypeMask other, JClosedWorld closedWorld) {
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
        ? flags & ((other.flags & 1) | ~1)
        : other.flags & ((flags & 1) | ~1);
    if (flags == combined) {
      return this;
    } else if (other.flags == combined) {
      return other;
    } else {
      return new FlatTypeMask.normalized(base, combined, domain);
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
    int combined = other.flags & ((flags & 1) | ~1);
    if (other.flags == combined) {
      return other;
    } else {
      return new FlatTypeMask.normalized(other.base, combined, domain);
    }
  }

  TypeMask intersectionEmpty(FlatTypeMask other) {
    return isNullable && other.isNullable
        ? new TypeMask.empty()
        : new TypeMask.nonNullEmpty();
  }

  @override
  bool canHit(MemberEntity element, Name name, JClosedWorld closedWorld) {
    CommonElements commonElements = closedWorld.commonElements;
    assert(element.name == name.text);
    if (isEmpty) return false;
    if (isNull) {
      return closedWorld.hasElementIn(
          commonElements.jsNullClass, name, element);
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
    if (isEmptyOrNull) return false;
    // A call on an exact mask for an abstract class is dead code.
    // TODO(johnniwinther): A type mask cannot be abstract. Remove the need
    // for this noise (currently used for super-calls in inference and mirror
    // usage).
    if (isExact && base.isAbstract) return false;

    return closedWorld.needsNoSuchMethod(base, selector, _classQuery);
  }

  @override
  MemberEntity locateSingleMember(Selector selector, CommonMasks domain) {
    if (isEmptyOrNull) return null;
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
    if (isEmptyOrNull) return isNullable ? '[null]' : '[empty]';
    StringBuffer buffer = new StringBuffer();
    if (isNullable) buffer.write('null|');
    if (isExact) buffer.write('exact=');
    if (isSubclass) buffer.write('subclass=');
    if (isSubtype) buffer.write('subtype=');
    buffer.write(base.name);
    return "[$buffer]";
  }
}
