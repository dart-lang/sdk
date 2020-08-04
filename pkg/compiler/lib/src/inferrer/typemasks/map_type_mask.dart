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
      DataSource source, CommonMasks domain) {
    source.begin(tag);
    TypeMask forwardTo = new TypeMask.readFromDataSource(source, domain);
    ir.TreeNode allocationNode = source.readTreeNodeOrNull();
    MemberEntity allocationElement = source.readMemberOrNull();
    TypeMask keyType = new TypeMask.readFromDataSource(source, domain);
    TypeMask valueType = new TypeMask.readFromDataSource(source, domain);
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
    } else if (other.isMap &&
        keyType != null &&
        other.keyType != null &&
        valueType != null &&
        other.valueType != null) {
      TypeMask newKeyType = keyType.union(other.keyType, domain);
      TypeMask newValueType = valueType.union(other.valueType, domain);
      TypeMask newForwardTo = forwardTo.union(other.forwardTo, domain);
      return new MapTypeMask(
          newForwardTo, null, null, newKeyType, newValueType);
    } else if (other.isDictionary) {
      // TODO(johnniwinther): Find another way to check this invariant that
      // doesn't need the compiler.
      assert(other.keyType ==
          new TypeMask.nonNullExact(
              domain.commonElements.jsStringClass, domain._closedWorld));
      TypeMask newKeyType = keyType.union(other.keyType, domain);
      TypeMask newValueType =
          other.typeMap.values.fold(keyType, (p, n) => p.union(n, domain));
      TypeMask newForwardTo = forwardTo.union(other.forwardTo, domain);
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
      return forwardTo.union(other, domain);
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
