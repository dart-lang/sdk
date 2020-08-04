// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of masks;

/// A [SetTypeMask] is a [TypeMask] for a specific allocation site of a set
/// (currently only the internal Set class) that will get specialized once the
/// [TypeGraphInferrer] phase finds an element type for it.
class SetTypeMask extends AllocationTypeMask {
  /// Tag used for identifying serialized [SetTypeMask] objects in a debugging
  /// data stream.
  static const String tag = 'set-type-mask';

  @override
  final TypeMask forwardTo;

  @override
  final ir.Node allocationNode;

  @override
  final MemberEntity allocationElement;

  // The element type of this set.
  final TypeMask elementType;

  SetTypeMask(this.forwardTo, this.allocationNode, this.allocationElement,
      this.elementType);

  /// Deserializes a [SetTypeMask] object from [source].
  factory SetTypeMask.readFromDataSource(
      DataSource source, CommonMasks domain) {
    source.begin(tag);
    TypeMask forwardTo = new TypeMask.readFromDataSource(source, domain);
    ir.TreeNode allocationNode = source.readTreeNodeOrNull();
    MemberEntity allocationElement = source.readMemberOrNull();
    TypeMask elementType = new TypeMask.readFromDataSource(source, domain);
    source.end(tag);
    return new SetTypeMask(
        forwardTo, allocationNode, allocationElement, elementType);
  }

  /// Serializes this [SetTypeMask] to [sink].
  @override
  void writeToDataSink(DataSink sink) {
    sink.writeEnum(TypeMaskKind.set);
    sink.begin(tag);
    forwardTo.writeToDataSink(sink);
    sink.writeTreeNodeOrNull(allocationNode);
    sink.writeMemberOrNull(allocationElement);
    elementType.writeToDataSink(sink);
    sink.end(tag);
  }

  @override
  TypeMask nullable() => isNullable
      ? this
      : new SetTypeMask(
          forwardTo.nullable(), allocationNode, allocationElement, elementType);

  @override
  TypeMask nonNullable() => isNullable
      ? new SetTypeMask(forwardTo.nonNullable(), allocationNode,
          allocationElement, elementType)
      : this;

  @override
  bool get isSet => true;

  @override
  bool get isExact => true;

  @override
  bool equalsDisregardNull(other) {
    if (other is! SetTypeMask) return false;
    return super.equalsDisregardNull(other) &&
        allocationNode == other.allocationNode &&
        elementType == other.elementType;
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
    } else if (other.isSet &&
        elementType != null &&
        other.elementType != null) {
      TypeMask newElementType = elementType.union(other.elementType, domain);
      TypeMask newForwardTo = forwardTo.union(other.forwardTo, domain);
      return new SetTypeMask(newForwardTo, null, null, newElementType);
    } else {
      return forwardTo.union(other, domain);
    }
  }

  @override
  bool operator ==(other) => super == other;

  @override
  int get hashCode =>
      computeHashCode(allocationNode, isNullable, elementType, forwardTo);

  @override
  String toString() => 'Set($forwardTo, element: $elementType)';
}
