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
  final Map<String, TypeMask> _typeMap;

  const DictionaryTypeMask(super.forwardTo, super._allocationNode,
      super.allocationElement, super.keyType, super.valueType, this._typeMap);

  /// Deserializes a [DictionaryTypeMask] object from [source].
  factory DictionaryTypeMask.readFromDataSource(
      DataSourceReader source, CommonMasks domain) {
    source.begin(tag);
    final forwardTo = TypeMask.readFromDataSource(source, domain);
    final allocationElement = source.readMemberOrNull();
    final keyType = TypeMask.readFromDataSource(source, domain);
    final valueType = TypeMask.readFromDataSource(source, domain);
    final typeMap =
        source.readStringMap(() => TypeMask.readFromDataSource(source, domain));
    source.end(tag);
    return DictionaryTypeMask(
        forwardTo, null, allocationElement, keyType, valueType, typeMap);
  }

  /// Serializes this [DictionaryTypeMask] to [sink].
  @override
  void writeToDataSink(DataSinkWriter sink) {
    sink.writeEnum(TypeMaskKind.dictionary);
    sink.begin(tag);
    forwardTo.writeToDataSink(sink);
    sink.writeMemberOrNull(allocationElement);
    keyType.writeToDataSink(sink);
    valueType.writeToDataSink(sink);
    sink.writeStringMap(_typeMap, (TypeMask typeMask) {
      typeMask.writeToDataSink(sink);
    });
    sink.end(tag);
  }

  @override
  DictionaryTypeMask withFlags({bool? isNullable, bool? hasLateSentinel}) {
    isNullable ??= this.isNullable;
    hasLateSentinel ??= this.hasLateSentinel;
    if (isNullable == this.isNullable &&
        hasLateSentinel == this.hasLateSentinel) {
      return this;
    }
    return DictionaryTypeMask(
        forwardTo.withFlags(
            isNullable: isNullable, hasLateSentinel: hasLateSentinel),
        allocationNode,
        allocationElement,
        keyType,
        valueType,
        _typeMap);
  }

  @override
  bool get isExact => true;

  bool containsKey(String key) => _typeMap.containsKey(key);

  TypeMask? getValueForKey(String key) => _typeMap[key];

  @override
  TypeMask? _unionSpecialCases(TypeMask other, CommonMasks domain,
      {required bool isNullable, required bool hasLateSentinel}) {
    if (other is DictionaryTypeMask) {
      TypeMask newForwardTo = forwardTo.union(other.forwardTo, domain);
      TypeMask newKeyType = keyType.union(other.keyType, domain);
      TypeMask newValueType = valueType.union(other.valueType, domain);
      Map<String, TypeMask> mappings = {};
      _typeMap.forEach((k, v) {
        if (!other._typeMap.containsKey(k)) {
          mappings[k] = v.nullable();
        }
      });
      other._typeMap.forEach((k, v) {
        if (_typeMap.containsKey(k)) {
          mappings[k] = v.union(_typeMap[k]!, domain);
        } else {
          mappings[k] = v.nullable();
        }
      });
      return DictionaryTypeMask(
          newForwardTo, null, null, newKeyType, newValueType, mappings);
    }
    if (other is MapTypeMask) {
      TypeMask newForwardTo = forwardTo.union(other.forwardTo, domain);
      TypeMask newKeyType = keyType.union(other.keyType, domain);
      TypeMask newValueType = valueType.union(other.valueType, domain);
      return MapTypeMask(newForwardTo, null, null, newKeyType, newValueType);
    }
    return null;
  }

  @override
  bool operator ==(other) {
    if (identical(this, other)) return true;
    if (other is! DictionaryTypeMask) return false;
    return super == other &&
        _typeMap.keys.every((k) => other._typeMap.containsKey(k)) &&
        other._typeMap.keys.every(
            (k) => _typeMap.containsKey(k) && _typeMap[k] == other._typeMap[k]);
  }

  @override
  int get hashCode => Hashing.objectHash(_typeMap, super.hashCode);

  @override
  String toString() {
    return 'Dictionary($forwardTo, key: $keyType, '
        'value: $valueType, map: $_typeMap)';
  }
}
