part of dart.collection;

abstract class LinkedHashMap<K, V> implements HashMap<K, V> {
  @patch factory LinkedHashMap({bool equals(K key1, K key2),
      int hashCode(K key), bool isValidKey(potentialKey)}) {
    if (isValidKey == null) {
      if (hashCode == null) {
        if (equals == null) {
          return new _LinkedHashMap<K, V>();
        }
        hashCode = _defaultHashCode;
      } else {
        if (identical(identityHashCode, hashCode) &&
            identical(identical, equals)) {
          return new _LinkedIdentityHashMap<K, V>();
        }
        if (equals == null) {
          equals = _defaultEquals;
        }
      }
    } else {
      if (hashCode == null) {
        hashCode = _defaultHashCode;
      }
      if (equals == null) {
        equals = _defaultEquals;
      }
    }
    return new _LinkedCustomHashMap<K, V>(equals, hashCode, isValidKey);
  }
  @patch factory LinkedHashMap.identity() = _LinkedIdentityHashMap<K, V>;
  factory LinkedHashMap.from(Map other) {
    LinkedHashMap<K, V> result = new LinkedHashMap<K, V>();
    other.forEach((k, v) {
      result[k] = DDC$RT.cast(v, dynamic, V, "CastGeneral",
          """line 65, column 40 of dart:collection/linked_hash_map.dart: """,
          v is V, false);
    });
    return result;
  }
  factory LinkedHashMap.fromIterable(Iterable iterable,
      {K key(element), V value(element)}) {
    LinkedHashMap<K, V> map = new LinkedHashMap<K, V>();
    Maps._fillMapWithMappedIterable(map, iterable, key, value);
    return map;
  }
  factory LinkedHashMap.fromIterables(Iterable<K> keys, Iterable<V> values) {
    LinkedHashMap<K, V> map = new LinkedHashMap<K, V>();
    Maps._fillMapWithIterables(map, keys, values);
    return map;
  }
}
