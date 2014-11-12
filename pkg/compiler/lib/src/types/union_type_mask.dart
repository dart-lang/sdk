// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of types;

class UnionTypeMask implements TypeMask {
  final Iterable<FlatTypeMask> disjointMasks;

  static const int MAX_UNION_LENGTH = 4;

  UnionTypeMask._internal(this.disjointMasks) {
    assert(disjointMasks.length > 1);
    assert(disjointMasks.every((TypeMask mask) => !mask.isUnion));
  }

  static TypeMask unionOf(Iterable<TypeMask> masks, ClassWorld classWorld) {
    assert(masks.every((mask) => TypeMask.assertIsNormalized(mask, classWorld)));
    List<FlatTypeMask> disjoint = <FlatTypeMask>[];
    unionOfHelper(masks, disjoint, classWorld);
    if (disjoint.isEmpty) return new TypeMask.nonNullEmpty();
    if (disjoint.length > MAX_UNION_LENGTH) {
      return flatten(disjoint, classWorld);
    }
    if (disjoint.length == 1) return disjoint[0];
    UnionTypeMask union = new UnionTypeMask._internal(disjoint);
    assert(TypeMask.assertIsNormalized(union, classWorld));
    return union;
  }

  static void unionOfHelper(Iterable<TypeMask> masks,
                            List<FlatTypeMask> disjoint,
                            ClassWorld classWorld) {
    // TODO(johnniwinther): Impose an order on the mask to ensure subclass masks
    // are preferred to subtype masks.
    for (TypeMask mask in masks) {
      mask = TypeMask.nonForwardingMask(mask);
      if (mask.isUnion) {
        UnionTypeMask union = mask;
        unionOfHelper(union.disjointMasks, disjoint, classWorld);
      } else if (mask.isEmpty && !mask.isNullable) {
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
          TypeMask newMask = flatMask.union(current, classWorld);
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

  static TypeMask flatten(List<FlatTypeMask> masks, ClassWorld classWorld) {
    assert(masks.length > 1);
    // If either type mask is a subtype type mask, we cannot use a
    // subclass type mask to represent their union.
    bool useSubclass = masks.every((e) => !e.isSubtype);
    bool isNullable = masks.any((e) => e.isNullable);

    Iterable<ClassElement> candidates =
        classWorld.commonSupertypesOf(masks.map((mask) => mask.base));

    // Compute the best candidate and its kind.
    ClassElement bestElement;
    int bestKind;
    int bestSize;
    for (ClassElement candidate in candidates) {
      Iterable<ClassElement> subclasses = useSubclass
          ? classWorld.subclassesOf(candidate)
          : const <ClassElement>[];
      int size;
      int kind;
      if (masks.every((t) => subclasses.contains(t.base))) {
        // If both [this] and [other] are subclasses of the supertype,
        // then we prefer to construct a subclass type mask because it
        // will always be at least as small as the corresponding
        // subtype type mask.
        kind = FlatTypeMask.SUBCLASS;
        size = subclasses.length;
        assert(size <= classWorld.subtypesOf(candidate).length);
      } else {
        kind = FlatTypeMask.SUBTYPE;
        size = classWorld.subtypesOf(candidate).length;
      }
      // Update the best candidate if the new one is better.
      if (bestElement == null || size < bestSize) {
        bestElement = candidate;
        bestSize = size;
        bestKind = kind;
      }
    }
    return new TypeMask(bestElement, bestKind, isNullable, classWorld);
  }

  TypeMask union(var other, ClassWorld classWorld) {
    other = TypeMask.nonForwardingMask(other);
    if (!other.isUnion && disjointMasks.contains(other)) return this;

    List<FlatTypeMask> newList =
        new List<FlatTypeMask>.from(disjointMasks);
    if (!other.isUnion) {
      newList.add(other);
    } else {
      assert(other is UnionTypeMask);
      newList.addAll(other.disjointMasks);
    }
    return new TypeMask.unionOf(newList, classWorld);
  }

  TypeMask intersection(var other, ClassWorld classWorld) {
    other = TypeMask.nonForwardingMask(other);
    if (!other.isUnion && disjointMasks.contains(other)) return other;

    List<TypeMask> intersections = <TypeMask>[];
    for (TypeMask current in disjointMasks) {
      if (other.isUnion) {
        for (FlatTypeMask flatOther in other.disjointMasks) {
          intersections.add(current.intersection(flatOther, classWorld));
        }
      } else {
        intersections.add(current.intersection(other, classWorld));
      }
    }
    return new TypeMask.unionOf(intersections, classWorld);
  }

  TypeMask nullable() {
    if (isNullable) return this;
    List<FlatTypeMask> newList = new List<FlatTypeMask>.from(disjointMasks);
    newList[0] = newList[0].nullable();
    return new UnionTypeMask._internal(newList);
  }

  TypeMask nonNullable() {
    if (!isNullable) return this;
    Iterable<FlatTypeMask> newIterable =
        disjointMasks.map((e) => e.nonNullable());
    return new UnionTypeMask._internal(newIterable);
  }

  bool get isEmpty => false;
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
  bool slowContainsCheck(TypeMask other, ClassWorld classWorld) {
    // Unions should never make it here.
    assert(!other.isUnion);
    // Ensure the cheap test fails.
    assert(!disjointMasks.any((mask) => mask.containsMask(other, classWorld)));
    // If we cover object, we should never get here.
    assert(!contains(classWorld.objectClass, classWorld));
    // Likewise, nullness should be covered.
    assert(isNullable || !other.isNullable);
    // The fast test is precise for exact types.
    if (other.isExact) return false;
    // We cannot contain object.
    if (other.contains(classWorld.objectClass, classWorld)) return false;
    FlatTypeMask flat = TypeMask.nonForwardingMask(other);
    // Check we cover the base class.
    if (!contains(flat.base, classWorld)) return false;
    // Check for other members.
    Iterable<ClassElement> members;
    if (flat.isSubclass) {
      members = classWorld.subclassesOf(flat.base);
    } else {
      assert(flat.isSubtype);
      members = classWorld.subtypesOf(flat.base);
    }
    return members.every((ClassElement cls) => this.contains(cls, classWorld));
  }

  bool isInMask(TypeMask other, ClassWorld classWorld) {
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
          return other.containsMask(maskDisregardNull, classWorld);
        });
      }
      return disjointMasks.every((FlatTypeMask disjointMask) {
        bool contained = containedInAnyOf(disjointMask, union.disjointMasks);
        assert(contained || !union.slowContainsCheck(disjointMask, classWorld));
        return contained;
      });
    }
    return disjointMasks.every((mask) => mask.isInMask(other, classWorld));
  }

  bool containsMask(TypeMask other, ClassWorld classWorld) {
    other = TypeMask.nonForwardingMask(other);
    if (other.isNullable && !isNullable) return false;
    if (other.isUnion) return other.isInMask(this, classWorld);
    other = other.nonNullable(); // nullable is not canonicalized, so drop it.
    bool contained =
        disjointMasks.any((mask) => mask.containsMask(other, classWorld));
    assert(contained || !slowContainsCheck(other, classWorld));
    return contained;
  }

  bool containsOnlyInt(ClassWorld classWorld) {
    return disjointMasks.every((mask) => mask.containsOnlyInt(classWorld));
  }

  bool containsOnlyDouble(ClassWorld classWorld) {
    return disjointMasks.every((mask) => mask.containsOnlyDouble(classWorld));
  }

  bool containsOnlyNum(ClassWorld classWorld) {
    return disjointMasks.every((mask) {
      return mask.containsOnlyNum(classWorld);
    });
  }

  bool containsOnlyBool(ClassWorld classWorld) {
    return disjointMasks.every((mask) => mask.containsOnlyBool(classWorld));
  }

  bool containsOnlyString(ClassWorld classWorld) {
    return disjointMasks.every((mask) => mask.containsOnlyString(classWorld));
  }

  bool containsOnly(ClassElement element) {
    return disjointMasks.every((mask) => mask.containsOnly(element));
  }

  bool satisfies(ClassElement cls, ClassWorld classWorld) {
    return disjointMasks.every((mask) => mask.satisfies(cls, classWorld));
  }

  bool contains(ClassElement type, ClassWorld classWorld) {
    return disjointMasks.any((e) => e.contains(type, classWorld));
  }

  bool containsAll(ClassWorld classWorld) {
    return disjointMasks.any((mask) => mask.containsAll(classWorld));
  }

  ClassElement singleClass(ClassWorld classWorld) => null;

  bool needsNoSuchMethodHandling(Selector selector, ClassWorld classWorld) {
    return disjointMasks.any(
        (e) => e.needsNoSuchMethodHandling(selector, classWorld));
  }

  bool canHit(Element element, Selector selector, ClassWorld classWorld) {
    return disjointMasks.any((e) => e.canHit(element, selector, classWorld));
  }

  Element locateSingleElement(Selector selector, Compiler compiler) {
    Element candidate;
    for (FlatTypeMask mask in disjointMasks) {
      Element current = mask.locateSingleElement(selector, compiler);
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
    String masksString = (disjointMasks.map((TypeMask mask) => mask.toString())
        .toList()..sort()).join(", ");
    return 'Union of [$masksString]';
  }

  bool operator==(other) {
    if (identical(this, other)) return true;

    bool containsAll() {
      return other.disjointMasks.every((e) {
        var map = disjointMasks.map((e) => e.nonNullable());
        return map.contains(e.nonNullable());
      });
    }

    return other is UnionTypeMask
        && other.isNullable == isNullable
        && other.disjointMasks.length == disjointMasks.length
        && containsAll();
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
