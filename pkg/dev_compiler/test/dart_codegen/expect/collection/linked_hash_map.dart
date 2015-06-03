part of dart.collection;
 abstract class LinkedHashMap<K, V> implements HashMap<K, V> {external factory LinkedHashMap({
  bool equals(K key1, K key2), int hashCode(K key), bool isValidKey(potentialKey)}
);
 external factory LinkedHashMap.identity();
 factory LinkedHashMap.from(Map other) {
  LinkedHashMap<K, V> result = new LinkedHashMap<K, V>();
   other.forEach((k, v) {
    result[DEVC$RT.cast(k, dynamic, K, "CompositeCast", """line 74, column 35 of dart:collection/linked_hash_map.dart: """, k is K, false)] = DEVC$RT.cast(v, dynamic, V, "CompositeCast", """line 74, column 40 of dart:collection/linked_hash_map.dart: """, v is V, false);
    }
  );
   return result;
  }
 factory LinkedHashMap.fromIterable(Iterable iterable, {
  K key(element), V value(element)}
) {
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
