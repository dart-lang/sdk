// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of masks;

/// A [DictionaryTypeMask] is a [TypeMask] for a specific allocation
/// site of a map (currently only internal Map class) that is used as
/// a dictionary, i.e. a mapping from a set of statically known strings
/// to values. These typemasks only come into existence after the
/// [TypeGraphInferrer] has successfully identified such a usage. Otherwise,
/// the more general [MapTypeMask] is used.
class DictionaryTypeMask extends MapTypeMask {
  /// Tag used for identifying serialized [DictionaryTypeMask] objects in a
  /// debugging data stream.
  static const String tag = 'dictionary-type-mask';

  // The underlying key/value map of this dictionary.
  final Map<String, AbstractValue> _typeMap;

  DictionaryTypeMask(
      TypeMask forwardTo,
      ir.Node allocationNode,
      MemberEntity allocationElement,
      TypeMask keyType,
      TypeMask valueType,
      this._typeMap)
      : super(forwardTo, allocationNode, allocationElement, keyType, valueType);

  /// Deserializes a [DictionaryTypeMask] object from [source].
  factory DictionaryTypeMask.readFromDataSource(
      DataSource source, CommonMasks domain) {
    source.begin(tag);
    TypeMask forwardTo = new TypeMask.readFromDataSource(source, domain);
    ir.TreeNode allocationNode = source.readTreeNodeOrNull();
    MemberEntity allocationElement = source.readMemberOrNull();
    TypeMask keyType = new TypeMask.readFromDataSource(source, domain);
    TypeMask valueType = new TypeMask.readFromDataSource(source, domain);
    Map<String, AbstractValue> typeMap = source
        .readStringMap(() => new TypeMask.readFromDataSource(source, domain));
    source.end(tag);
    return new DictionaryTypeMask(forwardTo, allocationNode, allocationElement,
        keyType, valueType, typeMap);
  }

  /// Serializes this [DictionaryTypeMask] to [sink].
  @override
  void writeToDataSink(DataSink sink) {
    sink.writeEnum(TypeMaskKind.dictionary);
    sink.begin(tag);
    forwardTo.writeToDataSink(sink);
    sink.writeTreeNodeOrNull(allocationNode);
    sink.writeMemberOrNull(allocationElement);
    keyType.writeToDataSink(sink);
    valueType.writeToDataSink(sink);
    sink.writeStringMap(_typeMap, (AbstractValue value) {
      TypeMask typeMask = value;
      typeMask.writeToDataSink(sink);
    });
    sink.end(tag);
  }

  @override
  TypeMask nullable() {
    return isNullable
        ? this
        : new DictionaryTypeMask(forwardTo.nullable(), allocationNode,
            allocationElement, keyType, valueType, _typeMap);
  }

  @override
  TypeMask nonNullable() {
    return isNullable
        ? new DictionaryTypeMask(forwardTo.nonNullable(), allocationNode,
            allocationElement, keyType, valueType, _typeMap)
        : this;
  }

  @override
  bool get isDictionary => true;
  @override
  bool get isExact => true;

  bool containsKey(String key) => _typeMap.containsKey(key);

  TypeMask getValueForKey(String key) => _typeMap[key];

  @override
  bool equalsDisregardNull(other) {
    if (other is! DictionaryTypeMask) return false;
    return allocationNode == other.allocationNode &&
        keyType == other.keyType &&
        valueType == other.valueType &&
        _typeMap.keys.every((k) => other._typeMap.containsKey(k)) &&
        other._typeMap.keys.every(
            (k) => _typeMap.containsKey(k) && _typeMap[k] == other._typeMap[k]);
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
    } else if (other.isDictionary) {
      TypeMask newForwardTo = forwardTo.union(other.forwardTo, domain);
      TypeMask newKeyType = keyType.union(other.keyType, domain);
      TypeMask newValueType = valueType.union(other.valueType, domain);
      Map<String, TypeMask> mappings = <String, TypeMask>{};
      _typeMap.forEach((k, dynamic v) {
        if (!other._typeMap.containsKey(k)) {
          mappings[k] = v.nullable();
        }
      });
      other._typeMap.forEach((k, v) {
        if (_typeMap.containsKey(k)) {
          mappings[k] = v.union(_typeMap[k], domain);
        } else {
          mappings[k] = v.nullable();
        }
      });
      return new DictionaryTypeMask(
          newForwardTo, null, null, newKeyType, newValueType, mappings);
    } else if (other.isMap &&
        (other.keyType != null) &&
        (other.valueType != null)) {
      TypeMask newForwardTo = forwardTo.union(other.forwardTo, domain);
      TypeMask newKeyType = keyType.union(other.keyType, domain);
      TypeMask newValueType = valueType.union(other.valueType, domain);
      return new MapTypeMask(
          newForwardTo, null, null, newKeyType, newValueType);
    } else {
      return forwardTo.union(other, domain);
    }
  }

  @override
  bool operator ==(other) => super == other;

  @override
  int get hashCode {
    return computeHashCode(allocationNode, isNullable, _typeMap, forwardTo);
  }

  @override
  String toString() {
    return 'Dictionary($forwardTo, key: $keyType, '
        'value: $valueType, map: $_typeMap)';
  }
}
