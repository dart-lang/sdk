// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Collection<T> supports most of the ES 5 Array methods, but it's missing
// map and reduce.

// TODO(jmesserly): we might want a version of this that return an iterable,
// however JS, Python and Ruby versions are all eager.
List map(Iterable source, mapper(source)) {
  List result = new List();
  if (source is List) {
    List list = source; // TODO: shouldn't need this
    result.length = list.length;
    for (int i = 0; i < list.length; i++) {
      result[i] = mapper(list[i]);
    }
  } else {
    for (final item in source) {
      result.add(mapper(item));
    }
  }
  return result;
}

reduce(Iterable source, callback, [initialValue]) {
  final i = source.iterator();

  var current = initialValue;
  if (current == null && i.hasNext()) {
    current = i.next();
  }
  while (i.hasNext()) {
    current = callback(current, i.next());
  }
  return current;
}

List zip(Iterable left, Iterable right, mapper(left, right)) {
  List result = new List();
  var x = left.iterator();
  var y = right.iterator();
  while (x.hasNext() && y.hasNext()) {
    result.add(mapper(x.next(), y.next()));
  }
  if (x.hasNext() || y.hasNext()) {
    throw new IllegalArgumentException();
  }
  return result;
}

/** Sorts the map by the key. */
List orderValuesByKeys(Map map) {
  // TODO(jmesserly): it'd be nice to have SortedMap in corelib.
  List keys = map.getKeys();
  keys.sort((x, y) => x.compareTo(y));
  final values = [];
  for (var k in keys) {
    values.add(map[k]);
  }
  return values;
}

/**
 * A [FixedCollection] is a collection of [length] items all of which have the
 * identical [value]
 */
class FixedCollection<E> implements Collection<E> {
  final E value;
  final int length;
  const FixedCollection(this.value, this.length);

  Iterator<E> iterator() => new FixedIterator<E>(value, length);
  void forEach(void f(E element)) { Collections.forEach(this, f); }
  Collection map(f(E element)) => Collections.map(this, new List(), f);
  Collection<E> filter(bool f(E element)) {
    return Collections.filter(this, new List<E>(), f);
  }
  bool every(bool f(E element)) => Collections.every(this, f);
  bool some(bool f(E element)) => Collections.some(this, f);
  bool isEmpty() => length == 0;
}

class FixedIterator<E> implements Iterator<E> {
  final E value;
  final int length;
  int _index = 0;
  FixedIterator(this.value, this.length);

  bool hasNext() => _index < length;
  E next() {
    _index++;
    return value;
  }
}

// Color constants used for generating messages.
String _GREEN_COLOR = '\u001b[32m';
String _RED_COLOR = '\u001b[31m';
String _MAGENTA_COLOR = '\u001b[35m';
String _NO_COLOR = '\u001b[0m';


/**
 * An implementation detail of [CopyOnWriteMap]. Essentially just
 * [HashMapImplementation] plus an additional [shared] field.
 */
class _SharedBackingMap<K, V> extends HashMapImplementation<K, V> {
  /**
   * The number of [CopyOnWriteMap] instances sharing this excluding the
   * original, i.e. it is safe to write iff `shared == 0`;
   */
  int shared = 0;
  _SharedBackingMap();
  factory _SharedBackingMap.from(Map<K, V> other) {
    final result = new _SharedBackingMap<K, V>();
    other.forEach((K k, V v) { result[k] = v; });
    return result;
  }
}

/** A copy-on-write [Map] implementation. */
// TODO(jmesserly): A persistent tree-based implementation of Map would be much
// nicer. This is just a quick hack to get things working.
class CopyOnWriteMap<K extends Hashable, V> implements HashMap<K, V> {
  _SharedBackingMap<K, V> _map;

  CopyOnWriteMap(): _map = new _SharedBackingMap<K, V>();
  CopyOnWriteMap._wrap(this._map);
  factory CopyOnWriteMap.from(Map<K, V> other) {
    if (other is CopyOnWriteMap<K, V>) {
      return other.dynamic.clone();
    }
    return new CopyOnWriteMap<K, V>._wrap(
        new _SharedBackingMap<K, V>.from(other));
  }

  CopyOnWriteMap<K, V> clone() {
    _map.shared++;
    return new CopyOnWriteMap<K, V>._wrap(_map);
  }

  void _ensureWritable() {
    if (_map.shared > 0) {
      _map.shared--;
      _map = new _SharedBackingMap<K, V>.from(_map);
    }
  }

  void operator []=(K key, V value) {
    _ensureWritable();
    _map[key] = value;
  }

  V putIfAbsent(K key, V ifAbsent()) {
    _ensureWritable();
    return _map.putIfAbsent(key, ifAbsent);
  }

  void clear() {
    _ensureWritable();
    _map.clear();
  }

  V remove(K key) {
    _ensureWritable();
    return _map.remove(key);
  }

  // Forwarding methods:
  V operator [](K key) => _map[key];
  bool isEmpty() => _map.isEmpty();
  int get length() => _map.length;
  void forEach(void f(K key, V value)) => _map.forEach(f);
  Collection<K> getKeys() => _map.getKeys();
  Collection<V> getValues() => _map.getValues();
  bool containsKey(K key) => _map.containsKey(key);
  bool containsValue(V value) => _map.containsValue(value);
}
