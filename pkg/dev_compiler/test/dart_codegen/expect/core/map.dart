part of dart.core;
 abstract class Map<K, V> {factory Map() = LinkedHashMap<K, V>;
 factory Map.from(Map other) = LinkedHashMap<K, V>.from;
 factory Map.identity() = LinkedHashMap<K, V>.identity;
 factory Map.fromIterable(Iterable iterable, {
  K key(element), V value(element)}
) = LinkedHashMap<K, V>.fromIterable;
 factory Map.fromIterables(Iterable<K> keys, Iterable<V> values) = LinkedHashMap<K, V>.fromIterables;
 bool containsValue(Object value);
 bool containsKey(Object key);
 V operator [](Object key);
 void operator []=(K key, V value);
 V putIfAbsent(K key, V ifAbsent());
 void addAll(Map<K, V> other);
 V remove(Object key);
 void clear();
 void forEach(void f(K key, V value));
 Iterable<K> get keys;
 Iterable<V> get values;
 int get length;
 bool get isEmpty;
 bool get isNotEmpty;
}
