// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of types;

/// A [ContainerTypeMask] is a [TypeMask] for a specific allocation
/// site of a container (currently only List) that will get specialized
/// once the [TypeGraphInferrer] phase finds an element type for it.
class ContainerTypeMask extends ForwardingTypeMask {
  final TypeMask forwardTo;

  // The [Node] where this type mask was created.
  final Node allocationNode;

  // The [Element] where this type mask was created.
  final Element allocationElement;

  // The element type of this container.
  final TypeMask elementType;

  // The length of the container.
  final int length;

  ContainerTypeMask(this.forwardTo,
                    this.allocationNode,
                    this.allocationElement,
                    this.elementType,
                    this.length);

  TypeMask nullable() {
    return isNullable
        ? this
        : new ContainerTypeMask(forwardTo.nullable(),
                                allocationNode,
                                allocationElement,
                                elementType,
                                length);
  }

  TypeMask nonNullable() {
    return isNullable
        ? new ContainerTypeMask(forwardTo.nonNullable(),
                                allocationNode,
                                allocationElement,
                                elementType,
                                length)
        : this;
  }

  bool get isContainer => true;
  bool get isExact => true;

  bool equalsDisregardNull(other) {
    if (other is! ContainerTypeMask) return false;
    return super.equalsDisregardNull(other) &&
        allocationNode == other.allocationNode &&
        elementType == other.elementType &&
        length == other.length;
  }

  TypeMask intersection(TypeMask other, Compiler compiler) {
    TypeMask forwardIntersection = forwardTo.intersection(other, compiler);
    if (forwardIntersection.isEmpty) return forwardIntersection;
    return forwardIntersection.isNullable
        ? nullable()
        : nonNullable();
  }

  TypeMask union(other, Compiler compiler) {
    if (this == other) {
      return this;
    } else if (equalsDisregardNull(other)) {
      return other.isNullable ? other : this;
    } else if (other.isEmpty) {
      return other.isNullable ? this.nullable() : this;
    } else if (other.isContainer
               && elementType != null
               && other.elementType != null) {
      TypeMask newElementType =
          elementType.union(other.elementType, compiler);
      int newLength = (length == other.length) ? length : null;
      TypeMask newForwardTo = forwardTo.union(other.forwardTo, compiler);
      return new ContainerTypeMask(
          newForwardTo,
          allocationNode == other.allocationNode ? allocationNode : null,
          allocationElement == other.allocationElement ? allocationElement
                                                       : null,
          newElementType, newLength);
    } else {
      return forwardTo.union(other, compiler);
    }
  }

  bool operator==(other) => super == other;

  int get hashCode {
    return computeHashCode(
        allocationNode, isNullable, elementType, length, forwardTo);
  }

  String toString() {
    return 'Container mask: $elementType length: $length type: $forwardTo';
  }
}
