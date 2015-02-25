part of dart.collection;

bool _defaultEquals(a, b) => a == b;
int _defaultHashCode(a) => DDC$RT.cast(a.hashCode, dynamic, int, "CastGeneral",
    """line 10, column 28 of dart:collection/hash_map.dart: """,
    a.hashCode is int, true);
typedef bool _Equality<K>(K a, K b);
typedef int _Hasher<K>(K object);
abstract class HashMap<K, V> implements Map<K, V> {
  factory HashMap({bool equals(K key1, K key2), int hashCode(K key),
      bool isValidKey(potentialKey)}) {
    if (isValidKey == null) {
      if (hashCode == null) {
        if (equals == null) {
          return new _HashMap<K, V>();
        }
        hashCode = _defaultHashCode;
      } else {
        if (identical(identityHashCode, hashCode) &&
            identical(identical, equals)) {
          return new _IdentityHashMap<K, V>();
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
    return new _CustomHashMap<K, V>(equals, hashCode, isValidKey);
  }
  factory HashMap.identity() = _IdentityHashMap<K, V>;
  factory HashMap.from(Map other) {
    HashMap<K, V> result = new HashMap<K, V>();
    other.forEach((k, v) {
      result[k] = DDC$RT.cast(v, dynamic, V, "CastGeneral",
          """line 112, column 40 of dart:collection/hash_map.dart: """, v is V,
          false);
    });
    return result;
  }
  factory HashMap.fromIterable(Iterable iterable,
      {K key(element), V value(element)}) {
    HashMap<K, V> map = new HashMap<K, V>();
    Maps._fillMapWithMappedIterable(map, iterable, key, value);
    return map;
  }
  factory HashMap.fromIterables(Iterable<K> keys, Iterable<V> values) {
    HashMap<K, V> map = new HashMap<K, V>();
    Maps._fillMapWithIterables(map, keys, values);
    return map;
  }
}
