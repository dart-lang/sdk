// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of masks;

/// A [MapTypeMask] is a [TypeMask] for a specific allocation
/// site of a map (currently only internal Map class) that will get specialized
/// once the [TypeGraphInferrer] phase finds a key and/or value type for it.
class MapTypeMask extends AllocationTypeMask {
  /// Tag used for identifying serialized [MapTypeMask] objects in a
  /// debugging data stream.
  static const String tag = 'map-type-mask';

  @override
  final TypeMask forwardTo;

  @override
  final ir.Node allocationNode;

  @override
  final MemberEntity allocationElement;

  // The value type of this map.
  final TypeMask valueType;

  // The key type of this map.
  final TypeMask keyType;

  MapTypeMask(this.forwardTo, this.allocationNode, this.allocationElement,
      this.keyType, this.valueType);

  /// Deserializes a [MapTypeMask] object from [source].
  factory MapTypeMask.readFromDataSource(
      DataSource source, JClosedWorld closedWorld) {
    source.begin(tag);
    TypeMask forwardTo = new TypeMask.readFromDataSource(source, closedWorld);
    ir.TreeNode allocationNode = source.readTreeNodeOrNull();
    MemberEntity allocationElement = source.readMemberOrNull();
    TypeMask keyType = new TypeMask.readFromDataSource(source, closedWorld);
    TypeMask valueType = new TypeMask.readFromDataSource(source, closedWorld);
    source.end(tag);
    return new MapTypeMask(
        forwardTo, allocationNode, allocationElement, keyType, valueType);
  }

  /// Serializes this [MapTypeMask] to [sink].
  @override
  void writeToDataSink(DataSink sink) {
    sink.writeEnum(TypeMaskKind.map);
    sink.begin(tag);
    forwardTo.writeToDataSink(sink);
    sink.writeTreeNodeOrNull(allocationNode);
    sink.writeMemberOrNull(allocationElement);
    keyType.writeToDataSink(sink);
    valueType.writeToDataSink(sink);
    sink.end(tag);
  }

  @override
  TypeMask nullable() {
    return isNullable
        ? this
        : new MapTypeMask(forwardTo.nullable(), allocationNode,
            allocationElement, keyType, valueType);
  }

  @override
  TypeMask nonNullable() {
    return isNullable
        ? new MapTypeMask(forwardTo.nonNullable(), allocationNode,
            allocationElement, keyType, valueType)
        : this;
  }

  @override
  bool get isContainer => false;
  @override
  bool get isMap => true;
  @override
  bool get isExact => true;

  @override
  bool equalsDisregardNull(other) {
    if (other is! MapTypeMask) return false;
    return super.equalsDisregardNull(other) &&
        allocationNode == other.allocationNode &&
        keyType == other.keyType &&
        valueType == other.valueType;
  }

  @override
  TypeMask intersection(TypeMask other, JClosedWorld closedWorld) {
    TypeMask forwardIntersection = forwardTo.intersection(other, closedWorld);
    if (forwardIntersection.isEmptyOrNull) return forwardIntersection;
    return forwardIntersection.isNullable ? nullable() : nonNullable();
  }

  @override
  TypeMask union(dynamic other, JClosedWorld closedWorld) {
    if (this == other) {
      return this;
    } else if (equalsDisregardNull(other)) {
      return other.isNullable ? other : this;
    } else if (other.isEmptyOrNull) {
      return other.isNullable ? this.nullable() : this;
    } else if (other.isMap &&
        keyType != null &&
        other.keyType != null &&
        valueType != null &&
        other.valueType != null) {
      TypeMask newKeyType = keyType.union(other.keyType, closedWorld);
      TypeMask newValueType = valueType.union(other.valueType, closedWorld);
      TypeMask newForwardTo = forwardTo.union(other.forwardTo, closedWorld);
      return new MapTypeMask(
          newForwardTo, null, null, newKeyType, newValueType);
    } else if (other.isDictionary) {
      // TODO(johnniwinther): Find another way to check this invariant that
      // doesn't need the compiler.
      assert(other.keyType ==
          new TypeMask.nonNullExact(
              closedWorld.commonElements.jsStringClass, closedWorld));
      TypeMask newKeyType = keyType.union(other.keyType, closedWorld);
      TypeMask newValueType =
          other.typeMap.values.fold(keyType, (p, n) => p.union(n, closedWorld));
      TypeMask newForwardTo = forwardTo.union(other.forwardTo, closedWorld);
      MapTypeMask newMapTypeMask = new MapTypeMask(
          newForwardTo,
          allocationNode == other.allocationNode ? allocationNode : null,
          allocationElement == other.allocationElement
              ? allocationElement
              : null,
          newKeyType,
          newValueType);
      return newMapTypeMask;
    } else {
      return forwardTo.union(other, closedWorld);
    }
  }

  @override
  bool operator ==(other) => super == other;

  @override
  int get hashCode {
    return computeHashCode(
        allocationNode, isNullable, keyType, valueType, forwardTo);
  }

  @override
  String toString() {
    return 'Map($forwardTo, key: $keyType, value: $valueType)';
  }
}
