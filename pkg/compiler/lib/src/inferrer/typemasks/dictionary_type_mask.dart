// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of masks;

/**
 * A [DictionaryTypeMask] is a [TypeMask] for a specific allocation
 * site of a map (currently only internal Map class) that is used as
 * a dictionary, i.e. a mapping from a set of statically known strings
 * to values. These typemasks only come into existence after the
 * [TypeGraphInferrer] has successfully identified such a usage. Otherwise,
 * the more general [MapTypeMask] is used.
 */
class DictionaryTypeMask<T> extends MapTypeMask<T> {
  // The underlying key/value map of this dictionary.
  final Map<String, AbstractValue> _typeMap;

  DictionaryTypeMask(
      TypeMask forwardTo,
      T allocationNode,
      MemberEntity allocationElement,
      TypeMask keyType,
      TypeMask valueType,
      this._typeMap)
      : super(forwardTo, allocationNode, allocationElement, keyType, valueType);

  TypeMask nullable() {
    return isNullable
        ? this
        : new DictionaryTypeMask<T>(forwardTo.nullable(), allocationNode,
            allocationElement, keyType, valueType, _typeMap);
  }

  TypeMask nonNullable() {
    return isNullable
        ? new DictionaryTypeMask<T>(forwardTo.nonNullable(), allocationNode,
            allocationElement, keyType, valueType, _typeMap)
        : this;
  }

  bool get isDictionary => true;
  bool get isExact => true;

  bool containsKey(String key) => _typeMap.containsKey(key);

  TypeMask getValueForKey(String key) => _typeMap[key];

  bool equalsDisregardNull(other) {
    if (other is! DictionaryTypeMask) return false;
    return allocationNode == other.allocationNode &&
        keyType == other.keyType &&
        valueType == other.valueType &&
        _typeMap.keys.every((k) => other._typeMap.containsKey(k)) &&
        other._typeMap.keys.every(
            (k) => _typeMap.containsKey(k) && _typeMap[k] == other._typeMap[k]);
  }

  TypeMask intersection(TypeMask other, ClosedWorld closedWorld) {
    TypeMask forwardIntersection = forwardTo.intersection(other, closedWorld);
    if (forwardIntersection.isEmptyOrNull) return forwardIntersection;
    return forwardIntersection.isNullable ? nullable() : nonNullable();
  }

  TypeMask union(dynamic other, ClosedWorld closedWorld) {
    if (this == other) {
      return this;
    } else if (equalsDisregardNull(other)) {
      return other.isNullable ? other : this;
    } else if (other.isEmptyOrNull) {
      return other.isNullable ? this.nullable() : this;
    } else if (other.isDictionary) {
      TypeMask newForwardTo = forwardTo.union(other.forwardTo, closedWorld);
      TypeMask newKeyType = keyType.union(other.keyType, closedWorld);
      TypeMask newValueType = valueType.union(other.valueType, closedWorld);
      Map<String, TypeMask> mappings = <String, TypeMask>{};
      _typeMap.forEach((k, dynamic v) {
        if (!other._typeMap.containsKey(k)) {
          mappings[k] = v.nullable();
        }
      });
      other._typeMap.forEach((k, v) {
        if (_typeMap.containsKey(k)) {
          mappings[k] = v.union(_typeMap[k], closedWorld);
        } else {
          mappings[k] = v.nullable();
        }
      });
      return new DictionaryTypeMask<T>(
          newForwardTo, null, null, newKeyType, newValueType, mappings);
    } else if (other.isMap &&
        (other.keyType != null) &&
        (other.valueType != null)) {
      TypeMask newForwardTo = forwardTo.union(other.forwardTo, closedWorld);
      TypeMask newKeyType = keyType.union(other.keyType, closedWorld);
      TypeMask newValueType = valueType.union(other.valueType, closedWorld);
      return new MapTypeMask(
          newForwardTo, null, null, newKeyType, newValueType);
    } else {
      return forwardTo.union(other, closedWorld);
    }
  }

  bool operator ==(other) => super == other;

  int get hashCode {
    return computeHashCode(allocationNode, isNullable, _typeMap, forwardTo);
  }

  String toString() {
    return 'Dictionary($forwardTo, key: $keyType, '
        'value: $valueType, map: $_typeMap)';
  }
}
