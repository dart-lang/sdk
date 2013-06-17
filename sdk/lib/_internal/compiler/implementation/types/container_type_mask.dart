// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of types;

/// A holder for an element type. We define a special class for it so
/// that nullable ContainerTypeMask and non-nullable ContainerTypeMask
/// share the same [ElementTypeHolder].
class ElementTypeHolder {
  // This field will be set after global analysis.
  TypeMask elementType;
}

/// A [ContainerTypeMask] is a [TypeMask] for a specific allocation
/// site of a container (currently only List) that will get specialized
/// once the [ListTracer] phase finds an element type for it.
class ContainerTypeMask implements TypeMask {

  // The flat version of a [ContainerTypeMask] is the container type
  // (for example List).
  final FlatTypeMask asFlat;

  // The [Node] where this type mask was created.
  final Node allocationNode;

  // The [Element] where this type mask was created.
  final Element allocationElement;

  // A holder for the element type. Shared between all
  // [ContainerTypeMask] for the same node.
  final ElementTypeHolder holder;

  TypeMask get elementType => holder.elementType;
  void set elementType(TypeMask mask) {
    holder.elementType = mask;
  }

  ContainerTypeMask(this.asFlat,
                    this.allocationNode,
                    this.allocationElement,
                    [holder])
      : this.holder = (holder == null) ? new ElementTypeHolder() : holder;

  TypeMask nullable() {
    return isNullable
        ? this
        : new ContainerTypeMask(asFlat.nullable(),
                                allocationNode,
                                allocationElement,
                                holder);
  }

  TypeMask nonNullable() {
    return isNullable
        ? new ContainerTypeMask(asFlat.nonNullable(),
                                allocationNode,
                                allocationElement,
                                holder)
        : this;
  }

  TypeMask simplify(Compiler compiler) => this;

  bool get isEmpty => false;
  bool get isNullable => asFlat.isNullable;
  bool get isExact => true;
  bool get isUnion => false;
  bool get isContainer => true;

  bool containsOnlyInt(Compiler compiler) => false;
  bool containsOnlyDouble(Compiler compiler) => false;
  bool containsOnlyNum(Compiler compiler) => false;
  bool containsOnlyNull(Compiler compiler) => false;
  bool containsOnlyBool(Compiler compiler) => false;
  bool containsOnlyString(Compiler compiler) => false;
  bool containsOnly(ClassElement element) {
    return asFlat.containsOnly(element);
  }

  bool satisfies(ClassElement cls, Compiler compiler) {
    return asFlat.satisfies(cls, compiler);
  }

  bool contains(DartType type, Compiler compiler) {
    return asFlat.contains(type, compiler);
  }

  bool containsAll(Compiler compiler) => false;

  ClassElement singleClass(Compiler compiler) {
    return asFlat.singleClass(compiler);
  }

  Iterable<ClassElement> containedClasses(Compiler compiler) {
    return asFlat.containedClasses(compiler);
  }

  TypeMask union(other, Compiler compiler) {
    if (other.isContainer
        && other.allocationNode == this.allocationNode) {
      return other.isNullable ? other : this;
    } else if (other.isEmpty) {
      return other.isNullable ? this.nullable() : this;
    }
    return asFlat.union(other, compiler);
  }

  TypeMask intersection(TypeMask other, Compiler compiler) {
    TypeMask flatIntersection = asFlat.intersection(other, compiler);
    if (flatIntersection.isEmpty) return flatIntersection;
    return flatIntersection.isNullable
        ? nullable()
        : nonNullable();
  }

  bool willHit(Selector selector, Compiler compiler) {
    return asFlat.willHit(selector, compiler);
  }

  bool canHit(Element element, Selector selector, Compiler compiler) {
    return asFlat.canHit(element, selector, compiler);
  }

  Element locateSingleElement(Selector selector, Compiler compiler) {
    return asFlat.locateSingleElement(selector, compiler);
  }

  bool operator==(other) {
    if (other is! ContainerTypeMask) return false;
    return allocationNode == other.allocationNode
        && isNullable == other.isNullable;
  }

  String toString() {
    return 'Container mask: $elementType';
  }
}
