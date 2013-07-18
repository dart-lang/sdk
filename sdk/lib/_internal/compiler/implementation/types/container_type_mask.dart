// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of types;

/// A holder for an element type. We define a special class for it so
/// that nullable ContainerTypeMask and non-nullable ContainerTypeMask
/// share the same [ElementTypeHolder].
class ElementTypeHolder {
  // These fields will be set after global analysis.
  TypeMask elementType;
  int length;

  int get hashCode => elementType.hashCode;
}

/// A [ContainerTypeMask] is a [TypeMask] for a specific allocation
/// site of a container (currently only List) that will get specialized
/// once the [ListTracer] phase finds an element type for it.
class ContainerTypeMask extends ForwardingTypeMask {
  // The flat version of a [ContainerTypeMask] is the container type
  // (for example List).
  final FlatTypeMask forwardTo;

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
  int get length => holder.length;
  void set length(int length) {
    holder.length = length;
  }

  ContainerTypeMask(this.forwardTo,
                    this.allocationNode,
                    this.allocationElement,
                    [holder])
      : this.holder = (holder == null) ? new ElementTypeHolder() : holder;

  TypeMask nullable() {
    return isNullable
        ? this
        : new ContainerTypeMask(forwardTo.nullable(),
                                allocationNode,
                                allocationElement,
                                holder);
  }

  TypeMask nonNullable() {
    return isNullable
        ? new ContainerTypeMask(forwardTo.nonNullable(),
                                allocationNode,
                                allocationElement,
                                holder)
        : this;
  }

  bool get isContainer => true;
  bool get isExact => true;

  bool equalsDisregardNull(other) {
    if (other is! ContainerTypeMask) return false;
    return allocationNode == other.allocationNode;
  }

  TypeMask intersection(TypeMask other, Compiler compiler) {
    TypeMask forwardIntersection = forwardTo.intersection(other, compiler);
    if (forwardIntersection.isEmpty) return forwardIntersection;
    return forwardIntersection.isNullable
        ? nullable()
        : nonNullable();
  }

  bool operator==(other) {
    if (other is! ContainerTypeMask) return false;
    return allocationNode == other.allocationNode
        && isNullable == other.isNullable;
  }

  int get hashCode => computeHashCode(allocationNode, isNullable);

  String toString() {
    return 'Container mask: $elementType';
  }
}
