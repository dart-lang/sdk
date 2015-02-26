part of dart.collection;
 abstract class MapBase<K, V> = Object with MapMixin<K, V>;
 abstract class MapMixin<K, V> implements Map<K, V> {Iterable<K> get keys;
 V operator [](Object key);
 operator []=(K key, V value);
 V remove(Object key);
 void clear();
 void forEach(void action(K key, V value)) {
  for (K key in keys) {
    action(key, this[key]);
    }
  }
 void addAll(Map<K, V> other) {
  for (K key in other.keys) {
    this[key] = other[key];
    }
  }
 bool containsValue(V value) {
  for (K key in keys) {
    if (this[key] == value) return true;
    }
   return false;
  }
 V putIfAbsent(K key, V ifAbsent()) {
  if (keys.contains(key)) {
    return this[key];
    }
   return this[key] = ifAbsent();
  }
 bool containsKey(Object key) => keys.contains(key);
 int get length => keys.length;
 bool get isEmpty => keys.isEmpty;
 bool get isNotEmpty => keys.isNotEmpty;
 Iterable<V> get values => new _MapBaseValueIterable<V>(this);
 String toString() => Maps.mapToString(this);
}
 abstract class UnmodifiableMapBase<K, V> = MapBase<K, V> with _UnmodifiableMapMixin<K, V>;
 class _MapBaseValueIterable<V> extends IterableBase<V> implements EfficientLength {final Map _map;
 _MapBaseValueIterable(this._map);
 int get length => _map.length;
 bool get isEmpty => _map.isEmpty;
 bool get isNotEmpty => _map.isNotEmpty;
 V get first => ((__x26) => DDC$RT.cast(__x26, dynamic, V, "CastGeneral", """line 122, column 18 of dart:collection/maps.dart: """, __x26 is V, false))(_map[_map.keys.first]);
 V get single => ((__x27) => DDC$RT.cast(__x27, dynamic, V, "CastGeneral", """line 123, column 19 of dart:collection/maps.dart: """, __x27 is V, false))(_map[_map.keys.single]);
 V get last => ((__x28) => DDC$RT.cast(__x28, dynamic, V, "CastGeneral", """line 124, column 17 of dart:collection/maps.dart: """, __x28 is V, false))(_map[_map.keys.last]);
 Iterator<V> get iterator => new _MapBaseValueIterator<V>(_map);
}
 class _MapBaseValueIterator<V> implements Iterator<V> {final Iterator _keys;
 final Map _map;
 V _current = ((__x29) => DDC$RT.cast(__x29, Null, V, "CastLiteral", """line 138, column 16 of dart:collection/maps.dart: """, __x29 is V, false))(null);
 _MapBaseValueIterator(Map map) : _map = map, _keys = map.keys.iterator;
 bool moveNext() {
if (_keys.moveNext()) {
_current = ((__x30) => DDC$RT.cast(__x30, dynamic, V, "CastGeneral", """line 144, column 18 of dart:collection/maps.dart: """, __x30 is V, false))(_map[_keys.current]);
 return true;
}
 _current = ((__x31) => DDC$RT.cast(__x31, Null, V, "CastLiteral", """line 147, column 16 of dart:collection/maps.dart: """, __x31 is V, false))(null);
 return false;
}
 V get current => _current;
}
 abstract class _UnmodifiableMapMixin<K, V> implements Map<K, V> {void operator []=(K key, V value) {
throw new UnsupportedError("Cannot modify unmodifiable map");
}
 void addAll(Map<K, V> other) {
throw new UnsupportedError("Cannot modify unmodifiable map");
}
 void clear() {
throw new UnsupportedError("Cannot modify unmodifiable map");
}
 V remove(Object key) {
throw new UnsupportedError("Cannot modify unmodifiable map");
}
 V putIfAbsent(K key, V ifAbsent()) {
throw new UnsupportedError("Cannot modify unmodifiable map");
}
}
 class MapView<K, V> implements Map<K, V> {final Map<K, V> _map;
 const MapView(Map<K, V> map) : _map = map;
 V operator [](Object key) => _map[key];
 void operator []=(K key, V value) {
_map[key] = value;
}
 void addAll(Map<K, V> other) {
_map.addAll(other);
}
 void clear() {
_map.clear();
}
 V putIfAbsent(K key, V ifAbsent()) => _map.putIfAbsent(key, ifAbsent);
 bool containsKey(Object key) => _map.containsKey(key);
 bool containsValue(Object value) => _map.containsValue(value);
 void forEach(void action(K key, V value)) {
_map.forEach(action);
}
 bool get isEmpty => _map.isEmpty;
 bool get isNotEmpty => _map.isNotEmpty;
 int get length => _map.length;
 Iterable<K> get keys => _map.keys;
 V remove(Object key) => _map.remove(key);
 String toString() => _map.toString();
 Iterable<V> get values => _map.values;
}
 class UnmodifiableMapView<K, V> = MapView<K, V> with _UnmodifiableMapMixin<K, V>;
 class Maps {static bool containsValue(Map map, value) {
for (final v in map.values) {
if (value == v) {
return true;
}
}
 return false;
}
 static bool containsKey(Map map, key) {
for (final k in map.keys) {
if (key == k) {
return true;
}
}
 return false;
}
 static putIfAbsent(Map map, key, ifAbsent()) {
if (map.containsKey(key)) {
return map[key];
}
 final v = ifAbsent();
 map[key] = v;
 return v;
}
 static clear(Map map) {
for (final k in map.keys.toList()) {
map.remove(k);
}
}
 static forEach(Map map, void f(key, value)) {
for (final k in map.keys) {
f(k, map[k]);
}
}
 static Iterable getValues(Map map) {
return map.keys.map((key) => map[key]);
}
 static int length(Map map) => map.keys.length;
 static bool isEmpty(Map map) => map.keys.isEmpty;
 static bool isNotEmpty(Map map) => map.keys.isNotEmpty;
 static String mapToString(Map m) {
if (IterableBase._isToStringVisiting(m)) {
return '{...}';
}
 var result = new StringBuffer();
 try {
IterableBase._toStringVisiting.add(m);
 result.write('{');
 bool first = true;
 m.forEach((k, v) {
if (!first) {
result.write(', ');
}
 first = false;
 result.write(k);
 result.write(': ');
 result.write(v);
}
);
 result.write('}');
}
 finally {
assert (identical(IterableBase._toStringVisiting.last, m)); IterableBase._toStringVisiting.removeLast();
}
 return result.toString();
}
 static _id(x) => x;
 static void _fillMapWithMappedIterable(Map map, Iterable iterable, key(element), value(element)) {
if (key == null) key = _id;
 if (value == null) value = _id;
 for (var element in iterable) {
map[key(element)] = value(element);
}
}
 static void _fillMapWithIterables(Map map, Iterable keys, Iterable values) {
Iterator keyIterator = keys.iterator;
 Iterator valueIterator = values.iterator;
 bool hasNextKey = keyIterator.moveNext();
 bool hasNextValue = valueIterator.moveNext();
 while (hasNextKey && hasNextValue) {
map[keyIterator.current] = valueIterator.current;
 hasNextKey = keyIterator.moveNext();
 hasNextValue = valueIterator.moveNext();
}
 if (hasNextKey || hasNextValue) {
throw new ArgumentError("Iterables do not have same length.");
}
}
}
