// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of masks;

/// A [TypeMask] for a specific allocation site of a container (currently only
/// List) that will get specialized once the [TypeGraphInferrer] phase finds an
/// element type for it.
class ContainerTypeMask extends AllocationTypeMask {
  /// Tag used for identifying serialized [ContainerTypeMask] objects in a
  /// debugging data stream.
  static const String tag = 'container-type-mask';

  @override
  final TypeMask forwardTo;

  @override
  final ir.Node allocationNode;

  @override
  final MemberEntity allocationElement;

  // The element type of this container.
  final TypeMask elementType;

  // The length of the container.
  final int length;

  ContainerTypeMask(this.forwardTo, this.allocationNode, this.allocationElement,
      this.elementType, this.length);

  /// Deserializes a [ContainerTypeMask] object from [source].
  factory ContainerTypeMask.readFromDataSource(
      DataSource source, CommonMasks domain) {
    source.begin(tag);
    TypeMask forwardTo = new TypeMask.readFromDataSource(source, domain);
    ir.TreeNode allocationNode = source.readTreeNodeOrNull();
    MemberEntity allocationElement = source.readMemberOrNull();
    TypeMask elementType = new TypeMask.readFromDataSource(source, domain);
    int length = source.readIntOrNull();
    source.end(tag);
    return new ContainerTypeMask(
        forwardTo, allocationNode, allocationElement, elementType, length);
  }

  /// Serializes this [ContainerTypeMask] to [sink].
  @override
  void writeToDataSink(DataSink sink) {
    sink.writeEnum(TypeMaskKind.container);
    sink.begin(tag);
    forwardTo.writeToDataSink(sink);
    sink.writeTreeNodeOrNull(allocationNode);
    sink.writeMemberOrNull(allocationElement);
    elementType.writeToDataSink(sink);
    sink.writeIntOrNull(length);
    sink.end(tag);
  }

  @override
  TypeMask nullable() {
    return isNullable
        ? this
        : new ContainerTypeMask(forwardTo.nullable(), allocationNode,
            allocationElement, elementType, length);
  }

  @override
  TypeMask nonNullable() {
    return isNullable
        ? new ContainerTypeMask(forwardTo.nonNullable(), allocationNode,
            allocationElement, elementType, length)
        : this;
  }

  @override
  bool get isContainer => true;
  @override
  bool get isExact => true;

  @override
  bool equalsDisregardNull(other) {
    if (other is! ContainerTypeMask) return false;
    return super.equalsDisregardNull(other) &&
        allocationNode == other.allocationNode &&
        elementType == other.elementType &&
        length == other.length;
  }

  @override
  TypeMask intersection(TypeMask other, CommonMasks domain) {
    TypeMask forwardIntersection = forwardTo.intersection(other, domain);
    if (forwardIntersection.isEmptyOrNull) return forwardIntersection;
    return forwardIntersection.isNullable ? nullable() : nonNullable();
  }

  @override
  TypeMask union(dynamic other, CommonMasks domain) {
    if (this == other) {
      return this;
    } else if (equalsDisregardNull(other)) {
      return other.isNullable ? other : this;
    } else if (other.isEmptyOrNull) {
      return other.isNullable ? this.nullable() : this;
    } else if (other.isContainer &&
        elementType != null &&
        other.elementType != null) {
      TypeMask newElementType = elementType.union(other.elementType, domain);
      int newLength = (length == other.length) ? length : null;
      TypeMask newForwardTo = forwardTo.union(other.forwardTo, domain);
      return new ContainerTypeMask(
          newForwardTo,
          allocationNode == other.allocationNode ? allocationNode : null,
          allocationElement == other.allocationElement
              ? allocationElement
              : null,
          newElementType,
          newLength);
    } else {
      return forwardTo.union(other, domain);
    }
  }

  @override
  bool operator ==(other) => super == other;

  @override
  int get hashCode {
    return computeHashCode(
        allocationNode, isNullable, elementType, length, forwardTo);
  }

  @override
  String toString() {
    return 'Container($forwardTo, element: $elementType, length: $length)';
  }
}
