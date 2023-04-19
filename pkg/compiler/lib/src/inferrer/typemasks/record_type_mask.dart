// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of masks;

/// A [TypeMask] representing the type of a record or the union of multiple
/// records with the same shape.
class RecordTypeMask extends TypeMask {
  /// Tag used for identifying serialized [RecordTypeMask] objects in a
  /// debugging data stream.
  static const String tag = 'record-type-mask';

  /// Contains the type of each field represented in this record.
  final List<TypeMask> types;

  final RecordShape shape;
  @override
  final bool isNullable;
  @override
  final bool hasLateSentinel;

  static TypeMask createRecord(
      CommonMasks domain, List<TypeMask> types, RecordShape shape,
      {bool isNullable = false, bool hasLateSentinel = false}) {
    assert(types.length == shape.fieldCount);
    // If any field is empty then this record is not instantiable and we
    // simplify to an empty mask.
    if (types.any((e) => e.isEmpty)) {
      return domain.emptyType
          .withFlags(isNullable: isNullable, hasLateSentinel: hasLateSentinel);
    }
    return RecordTypeMask._(types, shape,
        isNullable: isNullable, hasLateSentinel: hasLateSentinel);
  }

  RecordTypeMask._(this.types, this.shape,
      {required this.isNullable, required this.hasLateSentinel})
      : assert(types.length == shape.fieldCount);

  /// Deserializes a [ContainerTypeMask] object from [source].
  factory RecordTypeMask.readFromDataSource(
      DataSourceReader source, CommonMasks domain) {
    source.begin(tag);
    final types =
        source.readList(() => TypeMask.readFromDataSource(source, domain));
    final shape = RecordShape.readFromDataSource(source);
    final isNullable = source.readBool();
    final hasLateSentinel = source.readBool();
    source.end(tag);
    return RecordTypeMask._(types, shape,
        isNullable: isNullable, hasLateSentinel: hasLateSentinel);
  }

  /// Serializes this [ContainerTypeMask] to [sink].
  @override
  void writeToDataSink(DataSinkWriter sink) {
    sink.writeEnum(TypeMaskKind.record);
    sink.begin(tag);
    sink.writeList(types, (TypeMask value) => value.writeToDataSink(sink));
    shape.writeToDataSink(sink);
    sink.writeBool(isNullable);
    sink.writeBool(hasLateSentinel);
    sink.end(tag);
  }

  @override
  RecordTypeMask withFlags({bool? isNullable, bool? hasLateSentinel}) {
    isNullable ??= this.isNullable;
    hasLateSentinel ??= this.hasLateSentinel;
    if (isNullable == this.isNullable &&
        hasLateSentinel == this.hasLateSentinel) {
      return this;
    }
    return RecordTypeMask._(types, shape,
        isNullable: isNullable, hasLateSentinel: hasLateSentinel);
  }

  @override
  TypeMask union(TypeMask other, CommonMasks domain) {
    other = TypeMask.nonForwardingMask(other);
    final newIsNullable = isNullable || other.isNullable;
    final newHasLateSentinel = hasLateSentinel || other.hasLateSentinel;
    if (other is RecordTypeMask) {
      // NB: We take the slightly lenient strategy of, assuming the same shape,
      // collapsing the union of two records into a single record unioning the
      // individual fields. This loses some precision as we don't track which
      // type in one field is associated with which type from another field.
      // The alternative approach is to have UnionTypeMask support tracking
      // uncollapsed records. While more precise, any useful application of this
      // would likely hit the k-limit set on UnionTypeMask. If the k-limit was
      // hit we would have to regress to this same behavior anyway.
      if (shape == other.shape) {
        final otherTypes = other.types;
        // Union each individual field on this mask.
        final unionedFields = List.generate(types.length, (index) {
          final type = types[index];
          final otherType = otherTypes[index];
          return type.union(otherType, domain);
        });
        return RecordTypeMask.createRecord(domain, unionedFields, shape,
            isNullable: newIsNullable, hasLateSentinel: newHasLateSentinel);
      } else {
        // If the two records have different shapes use the union of their flat
        // mask representations.
        return toFlatTypeMask(domain._closedWorld)
            .union(other.toFlatTypeMask(domain._closedWorld), domain);
      }
    }
    if (other is FlatTypeMask) {
      if (other.isEmptyOrFlagged) {
        return withFlags(
            isNullable: newIsNullable, hasLateSentinel: newHasLateSentinel);
      }
      final otherBase = other.base!;
      final recordClass = _classForRecord(domain._closedWorld);
      if (recordClass != null) {
        if (domain._closedWorld.classHierarchy
            .isSubclassOf(otherBase, recordClass)) {
          // Other is the same shape (though possibly a specialization) with
          // dynamic fields so just use the flat mask of this shape. This treats
          // all the fields as dynamic.
          return toFlatTypeMask(domain._closedWorld);
        } else if (domain._closedWorld.classHierarchy
            .isSubtypeOf(recordClass, otherBase)) {
          // Other is a supertype of this shape so it encompasses this shape as
          // well. Use a subtype check to check for the Record interface.
          return other.withFlags(
              isNullable: newIsNullable, hasLateSentinel: newHasLateSentinel);
        }
      }
    }

    // Default to union of type cone on record class with other mask.
    return toFlatTypeMask(domain._closedWorld).union(other, domain);
  }

  @override
  TypeMask intersection(TypeMask other, CommonMasks domain) {
    other = TypeMask.nonForwardingMask(other);
    final newIsNullable = isNullable && other.isNullable;
    final newHasLateSentinel = hasLateSentinel && other.hasLateSentinel;
    if (other is RecordTypeMask) {
      if (shape == other.shape) {
        // The two records must have the same shape to have any intersection.
        // If they do have the same shape then just intersect their fields.
        final otherTypes = other.types;
        final intersectedFields = List.generate(types.length, (index) {
          final type = types[index];
          final otherType = otherTypes[index];
          return type.intersection(otherType, domain);
        });
        return RecordTypeMask.createRecord(domain, intersectedFields, shape,
            isNullable: newIsNullable, hasLateSentinel: newHasLateSentinel);
      }
    } else if (other is FlatTypeMask && !other.isEmptyOrFlagged) {
      if (other.containsAll(domain._closedWorld)) {
        // Top type encompasses this record so just update flags.
        return withFlags(
            isNullable: newIsNullable, hasLateSentinel: newHasLateSentinel);
      }
      final otherBase = other.base!;
      final recordClass = _classForRecord(domain._closedWorld);
      if (recordClass != null) {
        // If a class for the shape does not exist then it must not be an
        // an instantiated shape (created for a type test) and the intersection
        // will default to empty.
        if (domain._closedWorld.classHierarchy
            .isSubtypeOf(recordClass, otherBase)) {
          // This record is encompassed in `other` so maintain the current
          // shape.
          return withFlags(
              isNullable: newIsNullable, hasLateSentinel: newHasLateSentinel);
        } else if (domain._closedWorld.classHierarchy
            .isSubclassOf(otherBase, recordClass)) {
          // Other is a specialization of this shape. We don't know the field
          // types on this specialization so we just use the class itself.
          return other.withFlags(
              isNullable: newIsNullable, hasLateSentinel: newHasLateSentinel);
        }
      }
    } else if (other is UnionTypeMask) {
      // Let `UnionTypeMask` handle intersecting its submasks.
      return other.intersection(this, domain);
    }
    // We weren't able to find any matching classes so we default to empty.
    return newIsNullable
        ? FlatTypeMask.empty(hasLateSentinel: newHasLateSentinel)
        : FlatTypeMask.nonNullEmpty(hasLateSentinel: newHasLateSentinel);
  }

  @override
  bool needsNoSuchMethodHandling(Selector selector, JClosedWorld closedWorld) {
    // Record inherits members from `Object`.
    if (Selectors.objectSelectors.contains(selector)) return false;
    // Records only support calls and getters on fields.
    if (!selector.isGetter && !selector.isCall) return true;
    // Need NSM handling if selector does not match any of the shape's getters.
    return !shape.nameMatchesGetter(selector.name);
  }

  @override
  bool contains(ClassEntity cls, JClosedWorld closedWorld) {
    final recordClass = _classForRecord(closedWorld);
    if (recordClass == null) return false;
    return closedWorld.classHierarchy.isSubclassOf(cls, recordClass);
  }

  @override
  bool containsMask(TypeMask other, JClosedWorld closedWorld) {
    other = TypeMask.nonForwardingMask(other);
    if (other.isNullable && !isNullable) return false;
    if (other.hasLateSentinel && !hasLateSentinel) return false;
    if (other is RecordTypeMask) {
      // Must match `other.shape` and each field on this must be a supertype of
      // other's corresponding field.
      if (shape != other.shape) return false;
      final otherTypes = other.types;
      for (var i = 0; i < types.length; i++) {
        final type = types[i];
        final otherType = otherTypes[i];
        if (!type.containsMask(otherType, closedWorld)) return false;
      }
      return true;
    } else if (other is UnionTypeMask) {
      // Must contain all submasks on `other`.
      return other.disjointMasks.every((e) => containsMask(e, closedWorld));
    } else if (other is FlatTypeMask) {
      if (other.isEmptyOrFlagged) return true;
    }
    // We don't handle flat type masks here because even if the class matches,
    // each field is considered dynamic. This is likely wider than the field
    // on this record and not worth checking.
    return false;
  }

  @override
  bool isDisjoint(TypeMask other, JClosedWorld closedWorld) {
    other = TypeMask.nonForwardingMask(other);
    // If both this record and `other` include `null` or the late sentinel then
    // they are trivially not disjoint.
    if ((isNullable && other.isNullable) ||
        (hasLateSentinel && other.hasLateSentinel)) {
      return false;
    }
    if (other is RecordTypeMask) {
      // Shapes must be different or at least one corresponding field must be
      // disjoint.
      if (shape != other.shape) return true;
      final otherTypes = other.types;
      for (var i = 0; i < types.length; i++) {
        final type = types[i];
        final otherType = otherTypes[i];
        if (type.isDisjoint(otherType, closedWorld)) return true;
      }
      return false;
    } else if (other is FlatTypeMask) {
      if (other.isEmptyOrFlagged) return true;
      if (other.containsAll(closedWorld)) return false;
      final otherBase = other.base!;
      final recordClass = _classForRecord(closedWorld);
      if (recordClass == null) {
        // If a class for the shape does not exist then it must not be an
        // an instantiated shape (created for a type test) and the intersection
        // is empty.
        return true;
      }
      if (closedWorld.classHierarchy.isSubtypeOf(recordClass, otherBase) ||
          closedWorld.classHierarchy.isSubclassOf(otherBase, recordClass)) {
        // The class for this record cannot be a subtype of `other.base` and it
        // `other.base` cannot be a subclass of this class. The subtype check
        // is to handle the general `Record` interface.
        return false;
      }
      return true;
    } else if (other is UnionTypeMask) {
      // Must be disjoint from all submasks on `other`.
      return other.disjointMasks.every((e) => isDisjoint(e, closedWorld));
    }
    return false;
  }

  @override
  bool isInMask(TypeMask other, JClosedWorld closedWorld) {
    other = TypeMask.nonForwardingMask(other);
    if (isNullable && !other.isNullable) return false;
    if (hasLateSentinel && !other.hasLateSentinel) return false;
    if (other is RecordTypeMask) {
      // Must match `other.shape` and each field on this must be a subtype of
      // other's corresponding field.
      if (shape != other.shape) return false;
      final otherTypes = other.types;
      for (var i = 0; i < types.length; i++) {
        final type = types[i];
        final otherType = otherTypes[i];
        if (!type.isInMask(otherType, closedWorld)) return false;
      }
      return true;
    } else if (other is FlatTypeMask) {
      if (other.isEmptyOrFlagged) return false;
      if (other.containsAll(closedWorld)) return true;
      final otherBase = other.base!;
      final recordClass = _classForRecord(closedWorld);
      if (recordClass == null) {
        // If a class for the shape does not exist then it must not be an
        // an instantiated shape (created for a type test) and this won't
        // be a subtype of that mask.
        return false;
      }
      if (closedWorld.classHierarchy.isSubtypeOf(recordClass, otherBase)) {
        // If this record class is a subtype of `other.base` then each field
        // on other is considered dynamic and therefore a supertype of each
        // field on this. Use subtype to check against the `Record` interface.
        return true;
      }
    } else if (other is UnionTypeMask) {
      // Must be contained by some submask on `other`.
      return other.disjointMasks.any((e) => isInMask(e, closedWorld));
    }
    return false;
  }

  @override
  bool satisfies(ClassEntity cls, JClosedWorld closedWorld) {
    // The class of this record must be a subtype of `cls`. Use subtype check to
    // match Record interface as well.
    final recordClass = _classForRecord(closedWorld);
    if (recordClass == null) return false;
    return closedWorld.classHierarchy.isSubtypeOf(recordClass, cls);
  }

  ClassEntity? _classForRecord(JClosedWorld closedWorld) {
    return closedWorld.recordData.representationForShape(shape)?.cls;
  }

  FlatTypeMask toFlatTypeMask(JClosedWorld closedWorld) {
    final recordClass = _classForRecord(closedWorld) ??
        closedWorld.commonElements.recordArityClass(shape.fieldCount);
    if (closedWorld.classHierarchy.hasAnyStrictSubclass(recordClass)) {
      return isNullable
          ? FlatTypeMask.subclass(recordClass, closedWorld,
              hasLateSentinel: hasLateSentinel)
          : FlatTypeMask.nonNullSubclass(recordClass, closedWorld,
              hasLateSentinel: hasLateSentinel);
    } else {
      return isNullable
          ? FlatTypeMask.exact(recordClass, closedWorld,
              hasLateSentinel: hasLateSentinel)
          : FlatTypeMask.nonNullExact(recordClass, closedWorld,
              hasLateSentinel: hasLateSentinel);
    }
  }

  @override
  bool canHit(MemberEntity element, Name name, JClosedWorld closedWorld) {
    if (element.enclosingClass == closedWorld.commonElements.jsNullClass) {
      return isNullable;
    }
    // Delegate the check to a flat mask for this record. The field-specific
    // information on this record isn't useful here.
    if (isNullable &&
        closedWorld.hasElementIn(
            closedWorld.commonElements.jsNullClass, name, element)) {
      return true;
    }

    return toFlatTypeMask(closedWorld).canHit(element, name, closedWorld);
  }

  @override
  MemberEntity? locateSingleMember(Selector selector, CommonMasks domain) {
    // Delegate the check to the flat mask for the record class of this record.
    // The field-specific information on this record isn't useful here.
    return toFlatTypeMask(domain._closedWorld)
        .locateSingleMember(selector, domain);
  }

  @override
  ClassEntity? singleClass(JClosedWorld closedWorld) =>
      _classForRecord(closedWorld);

  @override
  bool operator ==(other) {
    if (identical(this, other)) return true;
    if (other is! RecordTypeMask) return false;
    return isNullable == other.isNullable &&
        hasLateSentinel == other.hasLateSentinel &&
        shape == other.shape &&
        equalElements(types, other.types);
  }

  @override
  int get hashCode => Hashing.listHash(
      types,
      Hashing.objectHash(
          shape, Hashing.objectsHash(isNullable, hasLateSentinel)));

  @override
  String toString() {
    return '[Record($shape, $types)]';
  }

  @override
  bool containsAll(JClosedWorld closedWorld) => false;

  @override
  bool containsOnly(ClassEntity cls) => false;

  @override
  bool containsOnlyBool(JClosedWorld closedWorld) => false;

  @override
  bool containsOnlyInt(JClosedWorld closedWorld) => false;

  @override
  bool containsOnlyNum(JClosedWorld closedWorld) => false;

  @override
  bool containsOnlyString(JClosedWorld closedWorld) => false;

  @override
  bool get isExact => types.every((e) => e.isExact);

  @override
  bool get isEmpty => false;

  @override
  bool get isEmptyOrFlagged => false;

  @override
  AbstractBool get isLateSentinel => AbstractBool.maybeOrFalse(hasLateSentinel);

  @override
  bool get isNull => false;

  @override
  Iterable<DynamicCallTarget> findRootsOfTargets(Selector selector,
      MemberHierarchyBuilder memberHierarchyBuilder, JClosedWorld closedWorld) {
    final recordClass = _classForRecord(closedWorld);
    return memberHierarchyBuilder.rootsForCall(
        recordClass != null
            ? closedWorld.abstractValueDomain.createNonNullSubclass(recordClass)
            : null,
        selector);
  }
}
