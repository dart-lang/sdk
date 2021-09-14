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

  const MapTypeMask(this.forwardTo, this.allocationNode, this.allocationElement,
      this.keyType, this.valueType);

  /// Deserializes a [MapTypeMask] object from [source].
  factory MapTypeMask.readFromDataSource(
      DataSource source, CommonMasks domain) {
    source.begin(tag);
    TypeMask forwardTo = TypeMask.readFromDataSource(source, domain);
    ir.TreeNode allocationNode = source.readTreeNodeOrNull();
    MemberEntity allocationElement = source.readMemberOrNull();
    TypeMask keyType = TypeMask.readFromDataSource(source, domain);
    TypeMask valueType = TypeMask.readFromDataSource(source, domain);
    source.end(tag);
    return MapTypeMask(
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
  MapTypeMask withFlags({bool isNullable, bool hasLateSentinel}) {
    isNullable ??= this.isNullable;
    hasLateSentinel ??= this.hasLateSentinel;
    if (isNullable == this.isNullable &&
        hasLateSentinel == this.hasLateSentinel) {
      return this;
    }
    return MapTypeMask(
        forwardTo.withFlags(
            isNullable: isNullable, hasLateSentinel: hasLateSentinel),
        allocationNode,
        allocationElement,
        keyType,
        valueType);
  }

  @override
  bool get isContainer => false;
  @override
  bool get isMap => true;
  @override
  bool get isExact => true;

  @override
  TypeMask _unionSpecialCases(TypeMask other, CommonMasks domain,
      {bool isNullable, bool hasLateSentinel}) {
    assert(isNullable != null);
    assert(hasLateSentinel != null);
    if (other is MapTypeMask &&
        keyType != null &&
        other.keyType != null &&
        valueType != null &&
        other.valueType != null) {
      TypeMask newKeyType = keyType.union(other.keyType, domain);
      TypeMask newValueType = valueType.union(other.valueType, domain);
      TypeMask newForwardTo = forwardTo.union(other.forwardTo, domain);
      return MapTypeMask(newForwardTo, null, null, newKeyType, newValueType);
    }
    if (other is DictionaryTypeMask) {
      // TODO(johnniwinther): Find another way to check this invariant that
      // doesn't need the compiler.
      assert(other.keyType ==
          TypeMask.nonNullExact(
              domain.commonElements.jsStringClass, domain._closedWorld));
      TypeMask newKeyType = keyType.union(other.keyType, domain);
      TypeMask newValueType =
          other._typeMap.values.fold(keyType, (p, n) => p.union(n, domain));
      TypeMask newForwardTo = forwardTo.union(other.forwardTo, domain);
      MapTypeMask newMapTypeMask = MapTypeMask(
          newForwardTo,
          allocationNode == other.allocationNode ? allocationNode : null,
          allocationElement == other.allocationElement
              ? allocationElement
              : null,
          newKeyType,
          newValueType);
      return newMapTypeMask;
    }
    return null;
  }

  @override
  bool operator ==(other) {
    if (identical(this, other)) return true;
    if (other is! MapTypeMask) return false;
    return super == other &&
        keyType == other.keyType &&
        valueType == other.valueType;
  }

  @override
  int get hashCode => Hashing.objectHash(
      valueType, Hashing.objectHash(keyType, super.hashCode));

  @override
  String toString() {
    return 'Map($forwardTo, key: $keyType, value: $valueType)';
  }
}
