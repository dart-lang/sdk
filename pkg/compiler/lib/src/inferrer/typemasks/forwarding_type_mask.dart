// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of masks;

/// A type mask that wraps an other one, and delegate all its
/// implementation methods to it.
abstract class ForwardingTypeMask implements TypeMask {
  TypeMask get forwardTo;

  ForwardingTypeMask();

  @override
  bool get isEmptyOrNull => forwardTo.isEmptyOrNull;
  @override
  bool get isEmpty => forwardTo.isEmpty;
  @override
  bool get isNullable => forwardTo.isNullable;
  @override
  bool get isNull => forwardTo.isNull;
  @override
  bool get isExact => forwardTo.isExact;

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
  bool get isValue => false;
  @override
  bool get isForwarding => true;

  @override
  bool isInMask(TypeMask other, JClosedWorld closedWorld) {
    return forwardTo.isInMask(other, closedWorld);
  }

  @override
  bool containsMask(TypeMask other, JClosedWorld closedWorld) {
    return forwardTo.containsMask(other, closedWorld);
  }

  @override
  bool containsOnlyInt(JClosedWorld closedWorld) {
    return forwardTo.containsOnlyInt(closedWorld);
  }

  @override
  bool containsOnlyDouble(JClosedWorld closedWorld) {
    return forwardTo.containsOnlyDouble(closedWorld);
  }

  @override
  bool containsOnlyNum(JClosedWorld closedWorld) {
    return forwardTo.containsOnlyNum(closedWorld);
  }

  @override
  bool containsOnlyBool(JClosedWorld closedWorld) {
    return forwardTo.containsOnlyBool(closedWorld);
  }

  @override
  bool containsOnlyString(JClosedWorld closedWorld) {
    return forwardTo.containsOnlyString(closedWorld);
  }

  @override
  bool containsOnly(ClassEntity cls) {
    return forwardTo.containsOnly(cls);
  }

  @override
  bool satisfies(ClassEntity cls, JClosedWorld closedWorld) {
    return forwardTo.satisfies(cls, closedWorld);
  }

  @override
  bool contains(ClassEntity cls, JClosedWorld closedWorld) {
    return forwardTo.contains(cls, closedWorld);
  }

  @override
  bool containsAll(JClosedWorld closedWorld) {
    return forwardTo.containsAll(closedWorld);
  }

  @override
  ClassEntity singleClass(JClosedWorld closedWorld) {
    return forwardTo.singleClass(closedWorld);
  }

  @override
  TypeMask union(other, CommonMasks domain) {
    if (this == other) {
      return this;
    } else if (equalsDisregardNull(other)) {
      return other.isNullable ? other : this;
    } else if (other.isEmptyOrNull) {
      return other.isNullable ? this.nullable() : this;
    }
    return forwardTo.union(other, domain);
  }

  @override
  bool isDisjoint(TypeMask other, JClosedWorld closedWorld) {
    return forwardTo.isDisjoint(other, closedWorld);
  }

  @override
  TypeMask intersection(TypeMask other, CommonMasks domain) {
    return forwardTo.intersection(other, domain);
  }

  @override
  bool needsNoSuchMethodHandling(
      Selector selector, covariant JClosedWorld closedWorld) {
    return forwardTo.needsNoSuchMethodHandling(selector, closedWorld);
  }

  @override
  bool canHit(MemberEntity element, Name name, JClosedWorld closedWorld) {
    return forwardTo.canHit(element, name, closedWorld);
  }

  @override
  MemberEntity locateSingleMember(Selector selector, CommonMasks domain) {
    return forwardTo.locateSingleMember(selector, domain);
  }

  bool equalsDisregardNull(other) {
    if (other is! ForwardingTypeMask) return false;
    if (forwardTo.isNullable) {
      return forwardTo == other.forwardTo.nullable();
    } else {
      return forwardTo == other.forwardTo.nonNullable();
    }
  }

  @override
  bool operator ==(other) {
    return equalsDisregardNull(other) && isNullable == other.isNullable;
  }

  @override
  int get hashCode => throw "Subclass should implement hashCode getter";
}

abstract class AllocationTypeMask extends ForwardingTypeMask {
  // The [ir.Node] where this type mask was created.
  ir.Node get allocationNode;

  // The [Entity] where this type mask was created.
  MemberEntity get allocationElement;
}
