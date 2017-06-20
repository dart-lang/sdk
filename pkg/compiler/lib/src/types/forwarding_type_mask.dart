// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of masks;

/**
 * A type mask that wraps an other one, and delegate all its
 * implementation methods to it.
 */
abstract class ForwardingTypeMask implements TypeMask {
  TypeMask get forwardTo;

  ForwardingTypeMask();

  bool get isEmptyOrNull => forwardTo.isEmptyOrNull;
  bool get isEmpty => forwardTo.isEmpty;
  bool get isNullable => forwardTo.isNullable;
  bool get isNull => forwardTo.isNull;
  bool get isExact => forwardTo.isExact;

  bool get isUnion => false;
  bool get isContainer => false;
  bool get isMap => false;
  bool get isDictionary => false;
  bool get isValue => false;
  bool get isForwarding => true;

  bool isInMask(TypeMask other, ClosedWorld closedWorld) {
    return forwardTo.isInMask(other, closedWorld);
  }

  bool containsMask(TypeMask other, ClosedWorld closedWorld) {
    return forwardTo.containsMask(other, closedWorld);
  }

  bool containsOnlyInt(ClosedWorld closedWorld) {
    return forwardTo.containsOnlyInt(closedWorld);
  }

  bool containsOnlyDouble(ClosedWorld closedWorld) {
    return forwardTo.containsOnlyDouble(closedWorld);
  }

  bool containsOnlyNum(ClosedWorld closedWorld) {
    return forwardTo.containsOnlyNum(closedWorld);
  }

  bool containsOnlyBool(ClosedWorld closedWorld) {
    return forwardTo.containsOnlyBool(closedWorld);
  }

  bool containsOnlyString(ClosedWorld closedWorld) {
    return forwardTo.containsOnlyString(closedWorld);
  }

  bool containsOnly(ClassEntity cls) {
    return forwardTo.containsOnly(cls);
  }

  bool satisfies(ClassEntity cls, ClosedWorld closedWorld) {
    return forwardTo.satisfies(cls, closedWorld);
  }

  bool contains(ClassEntity cls, ClosedWorld closedWorld) {
    return forwardTo.contains(cls, closedWorld);
  }

  bool containsAll(ClosedWorld closedWorld) {
    return forwardTo.containsAll(closedWorld);
  }

  ClassEntity singleClass(ClosedWorld closedWorld) {
    return forwardTo.singleClass(closedWorld);
  }

  TypeMask union(other, ClosedWorld closedWorld) {
    if (this == other) {
      return this;
    } else if (equalsDisregardNull(other)) {
      return other.isNullable ? other : this;
    } else if (other.isEmptyOrNull) {
      return other.isNullable ? this.nullable() : this;
    }
    return forwardTo.union(other, closedWorld);
  }

  bool isDisjoint(TypeMask other, ClosedWorld closedWorld) {
    return forwardTo.isDisjoint(other, closedWorld);
  }

  TypeMask intersection(TypeMask other, ClosedWorld closedWorld) {
    return forwardTo.intersection(other, closedWorld);
  }

  bool needsNoSuchMethodHandling(
      Selector selector, covariant ClosedWorld closedWorld) {
    return forwardTo.needsNoSuchMethodHandling(selector, closedWorld);
  }

  bool canHit(
      MemberEntity element, Selector selector, ClosedWorld closedWorld) {
    return forwardTo.canHit(element, selector, closedWorld);
  }

  MemberEntity locateSingleElement(Selector selector, ClosedWorld closedWorld) {
    return forwardTo.locateSingleElement(selector, closedWorld);
  }

  bool equalsDisregardNull(other) {
    if (other is! ForwardingTypeMask) return false;
    if (forwardTo.isNullable) {
      return forwardTo == other.forwardTo.nullable();
    } else {
      return forwardTo == other.forwardTo.nonNullable();
    }
  }

  bool operator ==(other) {
    return equalsDisregardNull(other) && isNullable == other.isNullable;
  }

  int get hashCode => throw "Subclass should implement hashCode getter";
}
