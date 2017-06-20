// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of masks;

class UnionTypeMask implements TypeMask {
  final Iterable<FlatTypeMask> disjointMasks;

  static const int MAX_UNION_LENGTH = 4;

  // Set this flag to `true` to perform a set-membership based containment check
  // instead of relying on normalized types. This is quite slow but can be
  // helpful in debugging.
  static const bool PERFORM_EXTRA_CONTAINS_CHECK = false;

  UnionTypeMask._internal(this.disjointMasks) {
    assert(disjointMasks.length > 1);
    assert(disjointMasks.every((TypeMask mask) => !mask.isUnion));
  }

  static TypeMask unionOf(Iterable<TypeMask> masks, ClosedWorld closedWorld) {
    assert(
        masks.every((mask) => TypeMask.assertIsNormalized(mask, closedWorld)));
    List<FlatTypeMask> disjoint = <FlatTypeMask>[];
    unionOfHelper(masks, disjoint, closedWorld);
    if (disjoint.isEmpty) return new TypeMask.nonNullEmpty();
    if (disjoint.length > MAX_UNION_LENGTH) {
      return flatten(disjoint, closedWorld);
    }
    if (disjoint.length == 1) return disjoint[0];
    UnionTypeMask union = new UnionTypeMask._internal(disjoint);
    assert(TypeMask.assertIsNormalized(union, closedWorld));
    return union;
  }

  static void unionOfHelper(Iterable<TypeMask> masks,
      List<FlatTypeMask> disjoint, ClosedWorld closedWorld) {
    // TODO(johnniwinther): Impose an order on the mask to ensure subclass masks
    // are preferred to subtype masks.
    for (TypeMask mask in masks) {
      mask = TypeMask.nonForwardingMask(mask);
      if (mask.isUnion) {
        UnionTypeMask union = mask;
        unionOfHelper(union.disjointMasks, disjoint, closedWorld);
      } else if (mask.isEmpty) {
        continue;
      } else {
        FlatTypeMask flatMask = mask;
        int inListIndex = -1;
        bool covered = false;

        // Iterate over [disjoint] to find out if one of the mask
        // already covers [mask].
        for (int i = 0; i < disjoint.length; i++) {
          FlatTypeMask current = disjoint[i];
          if (current == null) continue;
          TypeMask newMask = flatMask.union(current, closedWorld);
          // If we have found a disjoint union, continue iterating.
          if (newMask.isUnion) continue;
          covered = true;
          // We found a mask that is either equal to [mask] or is a
          // supertype of [mask].
          if (current == newMask) break;

          // [mask] is a supertype of [current], replace the [disjoint]
          // list with [newMask] instead of [current]. Note that
          // [newMask] may contain different information than [mask],
          // like nullability.
          disjoint[i] = newMask;
          flatMask = newMask;

          if (inListIndex != -1) {
            // If the mask was already covered, we remove the previous
            // place where it was inserted. This new mask subsumes the
            // previously covered one.
            disjoint.removeAt(inListIndex);
            i--;
          }
          // Record where the mask was inserted.
          inListIndex = i;
        }
        // If none of the masks in [disjoint] covers [mask], we just
        // add [mask] to the list.
        if (!covered) disjoint.add(flatMask);
      }
    }
  }

  static TypeMask flatten(List<FlatTypeMask> masks, ClosedWorld closedWorld) {
    // TODO(johnniwinther): Move this computation to [ClosedWorld] and use the
    // class set structures.
    assert(masks.length > 1);
    // If either type mask is a subtype type mask, we cannot use a
    // subclass type mask to represent their union.
    bool useSubclass = masks.every((e) => !e.isSubtype);
    bool isNullable = masks.any((e) => e.isNullable);

    List<ClassEntity> masksBases = masks.map((mask) => mask.base).toList();
    Iterable<ClassEntity> candidates =
        closedWorld.commonSupertypesOf(masksBases);

    // Compute the best candidate and its kind.
    ClassEntity bestElement;
    int bestKind;
    int bestSize;
    for (ClassEntity candidate in candidates) {
      bool isInstantiatedStrictSubclass(cls) =>
          cls != candidate &&
          closedWorld.isExplicitlyInstantiated(cls) &&
          closedWorld.isSubclassOf(cls, candidate);

      int size;
      int kind;
      if (useSubclass && masksBases.every(isInstantiatedStrictSubclass)) {
        // If both [this] and [other] are subclasses of the supertype,
        // then we prefer to construct a subclass type mask because it
        // will always be at least as small as the corresponding
        // subtype type mask.
        kind = FlatTypeMask.SUBCLASS;
        // TODO(sigmund, johnniwinther): computing length here (and below) is
        // expensive. If we can't prevent `flatten` from being called a lot, it
        // might be worth caching results.
        size = closedWorld.strictSubclassCount(candidate);
        assert(size <= closedWorld.strictSubtypeCount(candidate));
      } else {
        kind = FlatTypeMask.SUBTYPE;
        size = closedWorld.strictSubtypeCount(candidate);
      }
      // Update the best candidate if the new one is better.
      if (bestElement == null || size < bestSize) {
        bestElement = candidate;
        bestSize = size;
        bestKind = kind;
      }
    }
    return new TypeMask(bestElement, bestKind, isNullable, closedWorld);
  }

  TypeMask union(dynamic other, ClosedWorld closedWorld) {
    other = TypeMask.nonForwardingMask(other);
    if (!other.isUnion && disjointMasks.contains(other)) return this;

    List<FlatTypeMask> newList = new List<FlatTypeMask>.from(disjointMasks);
    if (!other.isUnion) {
      newList.add(other);
    } else {
      assert(other is UnionTypeMask);
      newList.addAll(other.disjointMasks);
    }
    return new TypeMask.unionOf(newList, closedWorld);
  }

  TypeMask intersection(dynamic other, ClosedWorld closedWorld) {
    other = TypeMask.nonForwardingMask(other);
    if (!other.isUnion && disjointMasks.contains(other)) return other;
    if (other.isUnion && this == other) return this;

    List<TypeMask> intersections = <TypeMask>[];
    for (TypeMask current in disjointMasks) {
      if (other.isUnion) {
        if (other.disjointMasks.contains(current)) {
          intersections.add(current);
        } else {
          for (FlatTypeMask flatOther in other.disjointMasks) {
            intersections.add(current.intersection(flatOther, closedWorld));
          }
        }
      } else {
        intersections.add(current.intersection(other, closedWorld));
      }
    }
    return new TypeMask.unionOf(intersections, closedWorld);
  }

  bool isDisjoint(TypeMask other, ClosedWorld closedWorld) {
    for (var current in disjointMasks) {
      if (!current.isDisjoint(other, closedWorld)) return false;
    }
    return true;
  }

  TypeMask nullable() {
    if (isNullable) return this;
    List<FlatTypeMask> newList = new List<FlatTypeMask>.from(disjointMasks);
    newList[0] = newList[0].nullable();
    return new UnionTypeMask._internal(newList);
  }

  TypeMask nonNullable() {
    if (!isNullable) return this;
    Iterable<FlatTypeMask> newIterable = disjointMasks.map((e) {
      FlatTypeMask r = e.nonNullable();
      return r;
    });
    return new UnionTypeMask._internal(newIterable);
  }

  bool get isEmptyOrNull => false;
  bool get isEmpty => false;
  bool get isNull => false;
  bool get isNullable => disjointMasks.any((e) => e.isNullable);
  bool get isExact => false;
  bool get isUnion => true;
  bool get isContainer => false;
  bool get isMap => false;
  bool get isDictionary => false;
  bool get isForwarding => false;
  bool get isValue => false;

  /**
   * Checks whether [other] is contained in this union.
   *
   * Invariants:
   * - [other] may not be a [UnionTypeMask] itself
   * - the cheap test matching against individual members of [disjointMasks]
   *   must have failed.
   */
  bool slowContainsCheck(TypeMask other, ClosedWorld closedWorld) {
    // Unions should never make it here.
    assert(!other.isUnion);
    // Ensure the cheap test fails.
    assert(!disjointMasks.any((mask) => mask.containsMask(other, closedWorld)));
    // If we cover object, we should never get here.
    assert(!contains(closedWorld.commonElements.objectClass, closedWorld));
    // Likewise, nullness should be covered.
    assert(isNullable || !other.isNullable);
    // The fast test is precise for exact types.
    if (other.isExact) return false;
    // We cannot contain object.
    if (other.contains(closedWorld.commonElements.objectClass, closedWorld)) {
      return false;
    }
    FlatTypeMask flat = TypeMask.nonForwardingMask(other);
    // Check we cover the base class.
    if (!contains(flat.base, closedWorld)) return false;
    // Check for other members.
    Iterable<ClassEntity> members;
    if (flat.isSubclass) {
      members = closedWorld.strictSubclassesOf(flat.base);
    } else {
      assert(flat.isSubtype);
      members = closedWorld.strictSubtypesOf(flat.base);
    }
    return members.every((ClassEntity cls) => this.contains(cls, closedWorld));
  }

  bool isInMask(TypeMask other, ClosedWorld closedWorld) {
    other = TypeMask.nonForwardingMask(other);
    if (isNullable && !other.isNullable) return false;
    if (other.isUnion) {
      UnionTypeMask union = other;
      bool containedInAnyOf(FlatTypeMask mask, Iterable<FlatTypeMask> masks) {
        // null is not canonicalized for the union but stored only on some
        // masks in [disjointMask]. It has been checked in the surrounding
        // context, so we can safely ignore it here.
        FlatTypeMask maskDisregardNull = mask.nonNullable();
        return masks.any((FlatTypeMask other) {
          return other.containsMask(maskDisregardNull, closedWorld);
        });
      }

      return disjointMasks.every((FlatTypeMask disjointMask) {
        bool contained = containedInAnyOf(disjointMask, union.disjointMasks);
        if (PERFORM_EXTRA_CONTAINS_CHECK &&
            !contained &&
            union.slowContainsCheck(disjointMask, closedWorld)) {
          throw "TypeMask based containment check failed for $this and $other.";
        }
        return contained;
      });
    }
    return disjointMasks.every((mask) => mask.isInMask(other, closedWorld));
  }

  bool containsMask(TypeMask other, ClosedWorld closedWorld) {
    other = TypeMask.nonForwardingMask(other);
    if (other.isNullable && !isNullable) return false;
    if (other.isUnion) return other.isInMask(this, closedWorld);
    other = other.nonNullable(); // nullable is not canonicalized, so drop it.
    bool contained =
        disjointMasks.any((mask) => mask.containsMask(other, closedWorld));
    if (PERFORM_EXTRA_CONTAINS_CHECK &&
        !contained &&
        slowContainsCheck(other, closedWorld)) {
      throw "TypeMask based containment check failed for $this and $other.";
    }
    return contained;
  }

  bool containsOnlyInt(ClosedWorld closedWorld) {
    return disjointMasks.every((mask) => mask.containsOnlyInt(closedWorld));
  }

  bool containsOnlyDouble(ClosedWorld closedWorld) {
    return disjointMasks.every((mask) => mask.containsOnlyDouble(closedWorld));
  }

  bool containsOnlyNum(ClosedWorld closedWorld) {
    return disjointMasks.every((mask) {
      return mask.containsOnlyNum(closedWorld);
    });
  }

  bool containsOnlyBool(ClosedWorld closedWorld) {
    return disjointMasks.every((mask) => mask.containsOnlyBool(closedWorld));
  }

  bool containsOnlyString(ClosedWorld closedWorld) {
    return disjointMasks.every((mask) => mask.containsOnlyString(closedWorld));
  }

  bool containsOnly(ClassEntity element) {
    return disjointMasks.every((mask) => mask.containsOnly(element));
  }

  bool satisfies(ClassEntity cls, ClosedWorld closedWorld) {
    return disjointMasks.every((mask) => mask.satisfies(cls, closedWorld));
  }

  bool contains(ClassEntity cls, ClosedWorld closedWorld) {
    return disjointMasks.any((e) => e.contains(cls, closedWorld));
  }

  bool containsAll(ClosedWorld closedWorld) {
    return disjointMasks.any((mask) => mask.containsAll(closedWorld));
  }

  ClassEntity singleClass(ClosedWorld closedWorld) => null;

  bool needsNoSuchMethodHandling(Selector selector, ClosedWorld closedWorld) {
    return disjointMasks
        .any((e) => e.needsNoSuchMethodHandling(selector, closedWorld));
  }

  bool canHit(
      MemberEntity element, Selector selector, ClosedWorld closedWorld) {
    return disjointMasks.any((e) => e.canHit(element, selector, closedWorld));
  }

  MemberEntity locateSingleElement(Selector selector, ClosedWorld closedWorld) {
    MemberEntity candidate;
    for (FlatTypeMask mask in disjointMasks) {
      MemberEntity current = mask.locateSingleElement(selector, closedWorld);
      if (current == null) {
        return null;
      } else if (candidate == null) {
        candidate = current;
      } else if (candidate != current) {
        return null;
      }
    }
    return candidate;
  }

  String toString() {
    String masksString =
        (disjointMasks.map((TypeMask mask) => mask.toString()).toList()..sort())
            .join(", ");
    return 'Union of [$masksString]';
  }

  bool operator ==(other) {
    if (identical(this, other)) return true;

    bool containsAll() {
      return other.disjointMasks.every((e) {
        var map = disjointMasks.map((e) => e.nonNullable());
        return map.contains(e.nonNullable());
      });
    }

    return other is UnionTypeMask &&
        other.isNullable == isNullable &&
        other.disjointMasks.length == disjointMasks.length &&
        containsAll();
  }

  int get hashCode {
    int hashCode = isNullable ? 86 : 43;
    // The order of the masks in [disjointMasks] must not affect the
    // hashCode.
    for (var mask in disjointMasks) {
      hashCode = (hashCode ^ mask.nonNullable().hashCode) & 0x3fffffff;
    }
    return hashCode;
  }
}
