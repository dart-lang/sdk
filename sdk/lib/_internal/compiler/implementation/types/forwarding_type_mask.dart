// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of types;

/**
 * A type mask that wraps an other one, and delegate all its
 * implementation methods to it.
 */
abstract class ForwardingTypeMask implements TypeMask {

  TypeMask get forwardTo;

  ForwardingTypeMask();

  bool get isEmpty => forwardTo.isEmpty;
  bool get isNullable => forwardTo.isNullable;
  bool get isExact => forwardTo.isExact;

  bool get isUnion => false;
  bool get isContainer => false;
  bool get isMap => false;
  bool get isDictionary => false;
  bool get isValue => false;
  bool get isForwarding => true;

  bool isInMask(TypeMask other, ClassWorld classWorld) {
    return forwardTo.isInMask(other, classWorld);
  }

  bool containsMask(TypeMask other, ClassWorld classWorld) {
    return forwardTo.containsMask(other, classWorld);
  }

  bool containsOnlyInt(ClassWorld classWorld) {
    return forwardTo.containsOnlyInt(classWorld);
  }

  bool containsOnlyDouble(ClassWorld classWorld) {
    return forwardTo.containsOnlyDouble(classWorld);
  }

  bool containsOnlyNum(ClassWorld classWorld) {
    return forwardTo.containsOnlyNum(classWorld);
  }

  bool containsOnlyBool(ClassWorld classWorld) {
    return forwardTo.containsOnlyBool(classWorld);
  }

  bool containsOnlyString(ClassWorld classWorld) {
    return forwardTo.containsOnlyString(classWorld);
  }

  bool containsOnly(ClassElement element) {
    return forwardTo.containsOnly(element);
  }

  bool satisfies(ClassElement cls, ClassWorld classWorld) {
    return forwardTo.satisfies(cls, classWorld);
  }

  bool contains(ClassElement type, ClassWorld classWorld) {
    return forwardTo.contains(type, classWorld);
  }

  bool containsAll(ClassWorld classWorld) {
    return forwardTo.containsAll(classWorld);
  }

  ClassElement singleClass(ClassWorld classWorld) {
    return forwardTo.singleClass(classWorld);
  }

  TypeMask union(other, ClassWorld classWorld) {
    if (this == other) {
      return this;
    } else if (equalsDisregardNull(other)) {
      return other.isNullable ? other : this;
    } else if (other.isEmpty) {
      return other.isNullable ? this.nullable() : this;
    }
    return forwardTo.union(other, classWorld);
  }

  TypeMask intersection(TypeMask other, ClassWorld classWorld) {
    return forwardTo.intersection(other, classWorld);
  }

  bool needsNoSuchMethodHandling(Selector selector, ClassWorld classWorld) {
    return forwardTo.needsNoSuchMethodHandling(selector, classWorld);
  }

  bool canHit(Element element, Selector selector, ClassWorld classWorld) {
    return forwardTo.canHit(element, selector, classWorld);
  }

  Element locateSingleElement(Selector selector, Compiler compiler) {
    return forwardTo.locateSingleElement(selector, compiler);
  }

  bool equalsDisregardNull(other) {
    if (other is! ForwardingTypeMask) return false;
    if (forwardTo.isNullable) {
      return forwardTo == other.forwardTo.nullable();
    } else {
      return forwardTo == other.forwardTo.nonNullable();
    }
  }

  bool operator==(other) {
    return equalsDisregardNull(other) && isNullable == other.isNullable;
  }

  int get hashCode => throw "Subclass should implement hashCode getter";
}
