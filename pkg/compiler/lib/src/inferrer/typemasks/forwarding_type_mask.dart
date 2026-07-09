// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'masks.dart';

/// A type mask that wraps another one, and delegates all its
/// implementation methods to it.
abstract class ForwardingTypeMask extends TypeMask {
  TypeMask get forwardTo;

  const ForwardingTypeMask();

  @override
  Bitset get powerset => forwardTo.powerset;
  @override
  bool get isEmptyOrSpecial => forwardTo.isEmptyOrSpecial;
  @override
  bool get isEmpty => forwardTo.isEmpty;
  @override
  bool get isNull => forwardTo.isNull;
  @override
  AbstractBool get isLateSentinel => forwardTo.isLateSentinel;
  @override
  bool get isExact => forwardTo.isExact;

  @override
  bool isInMask(TypeMask other, CommonMasks domain) {
    return forwardTo.isInMask(other, domain);
  }

  @override
  bool containsMask(TypeMask other, CommonMasks domain) {
    return forwardTo.containsMask(other, domain);
  }

  @override
  bool containsOnlyInt(JClosedWorld closedWorld) {
    return forwardTo.containsOnlyInt(closedWorld);
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
  ClassEntity? singleClass(JClosedWorld closedWorld) {
    return forwardTo.singleClass(closedWorld);
  }

  @override
  TypeMask union(TypeMask other, CommonMasks domain) {
    if (this == other) {
      return this;
    }
    final powerset = this.powerset.union(other.powerset);
    if (isEmptyOrSpecial) {
      return other.withPowerset(powerset, domain);
    }
    if (other.isEmptyOrSpecial) {
      return withPowerset(powerset, domain);
    }
    return _unionSpecialCases(other, domain, powerset) ??
        forwardTo.union(other, domain);
  }

  TypeMask? _unionSpecialCases(
    TypeMask other,
    CommonMasks domain,
    Bitset powerset,
  ) => null;

  @override
  bool _isNonTriviallyDisjoint(TypeMask other, JClosedWorld closedWorld) {
    return forwardTo._isNonTriviallyDisjoint(other, closedWorld);
  }

  @override
  TypeMask _nonEmptyIntersection(TypeMask other, CommonMasks domain) {
    TypeMask forwardIntersection = forwardTo._nonEmptyIntersection(
      other,
      domain,
    );
    if (forwardIntersection.isEmptyOrSpecial) return forwardIntersection;
    return withPowerset(forwardIntersection.powerset, domain);
  }

  @override
  bool needsNoSuchMethodHandling(
    Selector selector,
    covariant JClosedWorld closedWorld,
  ) {
    return forwardTo.needsNoSuchMethodHandling(selector, closedWorld);
  }

  @override
  bool canHit(MemberEntity element, Name name, CommonMasks domain) {
    return forwardTo.canHit(element, name, domain);
  }

  @override
  MemberEntity? locateSingleMember(Selector selector, CommonMasks domain) {
    return forwardTo.locateSingleMember(selector, domain);
  }

  @override
  Iterable<DynamicCallTarget> findRootsOfTargets(
    Selector selector,
    MemberHierarchyBuilder memberHierarchyBuilder,
    JClosedWorld closedWorld,
  ) {
    return forwardTo.findRootsOfTargets(
      selector,
      memberHierarchyBuilder,
      closedWorld,
    );
  }

  @override
  bool operator ==(other) {
    if (identical(this, other)) return true;
    if (other is! ForwardingTypeMask) return false;
    return forwardTo == other.forwardTo;
  }

  @override
  int get hashCode => forwardTo.hashCode;
}

abstract class AllocationTypeMask extends ForwardingTypeMask {
  const AllocationTypeMask();

  // The [ir.Node] where this type mask was created. This value is not used
  // after type inference and therefore does not need to be serialized by
  // subclasses.  It will always be null outside of the global inference phase.
  ir.Node? get allocationNode;

  // The [Entity] where this type mask was created.
  MemberEntity? get allocationElement;

  @override
  bool operator ==(other) {
    if (identical(this, other)) return true;
    if (other is! AllocationTypeMask) return false;
    return super == other && allocationNode == other.allocationNode;
  }

  @override
  int get hashCode => Hashing.objectHash(allocationNode, super.hashCode);
}
