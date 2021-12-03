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

  const ContainerTypeMask(this.forwardTo, this.allocationNode,
      this.allocationElement, this.elementType, this.length);

  /// Deserializes a [ContainerTypeMask] object from [source].
  factory ContainerTypeMask.readFromDataSource(
      DataSource source, CommonMasks domain) {
    source.begin(tag);
    TypeMask forwardTo = TypeMask.readFromDataSource(source, domain);
    ir.TreeNode allocationNode = source.readTreeNodeOrNull();
    MemberEntity allocationElement = source.readMemberOrNull();
    TypeMask elementType = TypeMask.readFromDataSource(source, domain);
    int length = source.readIntOrNull();
    source.end(tag);
    return ContainerTypeMask(
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
  ContainerTypeMask withFlags({bool isNullable, bool hasLateSentinel}) {
    isNullable ??= this.isNullable;
    hasLateSentinel ??= this.hasLateSentinel;
    if (isNullable == this.isNullable &&
        hasLateSentinel == this.hasLateSentinel) {
      return this;
    }
    return ContainerTypeMask(
        forwardTo.withFlags(
            isNullable: isNullable, hasLateSentinel: hasLateSentinel),
        allocationNode,
        allocationElement,
        elementType,
        length);
  }

  @override
  bool get isContainer => true;
  @override
  bool get isExact => true;

  @override
  TypeMask _unionSpecialCases(TypeMask other, CommonMasks domain,
      {bool isNullable, bool hasLateSentinel}) {
    assert(isNullable != null);
    assert(hasLateSentinel != null);
    if (other is ContainerTypeMask &&
        elementType != null &&
        other.elementType != null) {
      TypeMask newElementType = elementType.union(other.elementType, domain);
      int newLength = (length == other.length) ? length : null;
      TypeMask newForwardTo = forwardTo.union(other.forwardTo, domain);
      return ContainerTypeMask(
          newForwardTo,
          allocationNode == other.allocationNode ? allocationNode : null,
          allocationElement == other.allocationElement
              ? allocationElement
              : null,
          newElementType,
          newLength);
    }
    return null;
  }

  @override
  bool operator ==(other) {
    if (identical(this, other)) return true;
    if (other is! ContainerTypeMask) return false;
    return super == other &&
        elementType == other.elementType &&
        length == other.length;
  }

  @override
  int get hashCode => Hashing.objectHash(
      length, Hashing.objectHash(elementType, super.hashCode));

  @override
  String toString() {
    return 'Container($forwardTo, element: $elementType, length: $length)';
  }
}
