// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of types;

class UnionTypeMask implements TypeMask {
  final Iterable<FlatTypeMask> disjointMasks;

  static const int MAX_UNION_LENGTH = 4;

  UnionTypeMask._(this.disjointMasks);

  static TypeMask unionOf(Iterable<TypeMask> masks, Compiler compiler) {
    List<FlatTypeMask> disjoint = <FlatTypeMask>[];
    unionOfHelper(masks, disjoint, compiler);
    if (disjoint.isEmpty) return new TypeMask.nonNullEmpty();
    if (disjoint.length > MAX_UNION_LENGTH) return flatten(disjoint, compiler);
    if (disjoint.length == 1) return disjoint[0];
    return new UnionTypeMask._(disjoint);
  }

  static TypeMask nonForwardingMask(mask) {
    while (mask.isForwarding) mask = mask.forwardTo;
    return mask;
  }

  static void unionOfHelper(Iterable<TypeMask> masks,
                            List<FlatTypeMask> disjoint,
                            Compiler compiler) {
    for (TypeMask mask in masks) {
      mask = nonForwardingMask(mask);
      if (mask.isUnion) {
        UnionTypeMask union = mask;
        unionOfHelper(union.disjointMasks, disjoint, compiler);
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
          TypeMask newMask = mask.union(current, compiler);
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
          mask = newMask;

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
        if (!covered) disjoint.add(mask);
      }
    }
  }

  static TypeMask flatten(List<FlatTypeMask> masks, Compiler compiler) {
    assert(masks.length > 1);
    // If either type mask is a subtype type mask, we cannot use a
    // subclass type mask to represent their union.
    bool useSubclass = masks.every((e) => !e.isSubtype);
    bool isNullable = masks.any((e) => e.isNullable);

    // Compute the common supertypes of the two types.
    ClassElement firstElement = masks[0].base;
    ClassElement secondElement = masks[1].base;
    Iterable<ClassElement> candidates =
        compiler.world.commonSupertypesOf(firstElement, secondElement);
    bool unseenType = false;
    for (int i = 2; i < masks.length; i++) {
      ClassElement element = masks[i].base;
      Set<ClassElement> supertypes = compiler.world.supertypesOf(element);
      if (supertypes == null) {
        unseenType = true;
        break;
      }
      candidates = candidates.where((e) => supertypes.contains(e));
    }

    if (candidates.isEmpty || unseenType) {
      // TODO(kasperl): Get rid of this check. It can only happen when
      // at least one of the two base types is 'unseen'.
      return new TypeMask(compiler.objectClass,
                          FlatTypeMask.SUBCLASS,
                          isNullable);
    }
    // Compute the best candidate and its kind.
    ClassElement bestElement;
    int bestKind;
    int bestSize;
    for (ClassElement candidate in candidates) {
      Set<ClassElement> subclasses = useSubclass
          ? compiler.world.subclassesOf(candidate)
          : null;
      int size;
      int kind;
      if (subclasses != null
          && masks.every((t) => subclasses.contains(t.base))) {
        // If both [this] and [other] are subclasses of the supertype,
        // then we prefer to construct a subclass type mask because it
        // will always be at least as small as the corresponding
        // subtype type mask.
        kind = FlatTypeMask.SUBCLASS;
        size = subclasses.length;
        assert(size <= compiler.world.subtypesOf(candidate).length);
      } else {
        kind = FlatTypeMask.SUBTYPE;
        size = compiler.world.subtypesOf(candidate).length;
      }
      // Update the best candidate if the new one is better.
      if (bestElement == null || size < bestSize) {
        bestElement = candidate;
        bestSize = size;
        bestKind = kind;
      }
    }
    if (bestElement == compiler.objectClass) bestKind = FlatTypeMask.SUBCLASS;
    return new TypeMask(bestElement, bestKind, isNullable);
  }

  TypeMask union(var other, Compiler compiler) {
    other = nonForwardingMask(other);
    if (!other.isUnion && disjointMasks.contains(other)) return this;

    List<FlatTypeMask> newList =
        new List<FlatTypeMask>.from(disjointMasks);
    if (!other.isUnion) {
      newList.add(other);
    } else {
      assert(other is UnionTypeMask);
      newList.addAll(other.disjointMasks);
    }
    return new TypeMask.unionOf(newList, compiler);
  }

  TypeMask intersection(var other, Compiler compiler) {
    other = nonForwardingMask(other);
    if (!other.isUnion && disjointMasks.contains(other)) return other;

    List<TypeMask> intersections = <TypeMask>[];
    for (TypeMask current in disjointMasks) {
      if (other.isUnion) {
        for (FlatTypeMask flatOther in other.disjointMasks) {
          intersections.add(current.intersection(flatOther, compiler));
        }
      } else {
        intersections.add(current.intersection(other, compiler));
      }
    }
    return new TypeMask.unionOf(intersections, compiler);
  }

  TypeMask nullable() {
    if (isNullable) return this;
    List<FlatTypeMask> newList = new List<FlatTypeMask>.from(disjointMasks);
    newList[0] = newList[0].nullable();
    return new UnionTypeMask._(newList);
  }

  TypeMask nonNullable() {
    if (!isNullable) return this;
    Iterable<FlatTypeMask> newIterable =
        disjointMasks.map((e) => e.nonNullable());
    return new UnionTypeMask._(newIterable);
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

  bool isInMask(TypeMask other, Compiler compiler) {
    return disjointMasks.every((mask) => mask.isInMask(other, compiler));
  }

  bool containsMask(TypeMask other, Compiler compiler) {
    return disjointMasks.any((mask) => mask.containsMask(other, compiler));
  }

  bool containsOnlyInt(Compiler compiler) {
    return disjointMasks.every((mask) => mask.containsOnlyInt(compiler));
  }

  bool containsOnlyDouble(Compiler compiler) {
    return disjointMasks.every((mask) => mask.containsOnlyDouble(compiler));
  }

  bool containsOnlyNum(Compiler compiler) {
    return disjointMasks.every((mask) {
      return mask.containsOnlyNum(compiler);
    });
  }

  bool containsOnlyBool(Compiler compiler) {
    return disjointMasks.every((mask) => mask.containsOnlyBool(compiler));
  }

  bool containsOnlyString(Compiler compiler) {
    return disjointMasks.every((mask) => mask.containsOnlyString(compiler));
  }

  bool containsOnly(ClassElement element) {
    return disjointMasks.every((mask) => mask.containsOnly(element));
  }

  bool satisfies(ClassElement cls, Compiler compiler) {
    return disjointMasks.every((mask) => mask.satisfies(cls, compiler));
  }

  bool contains(ClassElement type, Compiler compiler) {
    return disjointMasks.any((e) => e.contains(type, compiler));
  }

  bool containsAll(Compiler compiler) {
    return disjointMasks.any((mask) => mask.containsAll(compiler));
  }

  ClassElement singleClass(Compiler compiler) => null;

  bool needsNoSuchMethodHandling(Selector selector, Compiler compiler) {
    return disjointMasks.any(
        (e) => e.needsNoSuchMethodHandling(selector, compiler));
  }

  bool canHit(Element element, Selector selector, Compiler compiler) {
    return disjointMasks.any((e) => e.canHit(element, selector, compiler));
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

  String toString() => 'Union of $disjointMasks';

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
