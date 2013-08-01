// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of observe;

// TODO(jmesserly): this needs to be faster. We currently require multiple
// lookups per key to get the old value.
// TODO(jmesserly): this doesn't implement the precise interfaces like
// LinkedHashMap, SplayTreeMap or HashMap. However it can use them for the
// backing store.

// TODO(jmesserly): should we summarize map changes like we do for list changes?
class MapChangeRecord extends ChangeRecord {
  /** The map key that changed. */
  final key;

  // TODO(jmesserly): we could store this more compactly if it matters.
  /** True if this key was inserted. */
  final bool isInsert;

  /** True if this key was removed. */
  final bool isRemove;

  MapChangeRecord(this.key, {this.isInsert: false, this.isRemove: false}) {
    if (isInsert && isRemove) {
      throw new ArgumentError(
          '$key cannot be inserted and removed in the same change');
    }
  }

  // Use == on the key, to match equality semantics of most Maps.
  bool changes(otherKey) => key == otherKey;

  String toString() {
    var kind = isInsert ? 'insert' : isRemove ? 'remove' : 'set';
    return '#<MapChangeRecord $kind $key>';
  }
}

/**
 * Represents an observable map of model values. If any items are added,
 * removed, or replaced, then observers that are listening to [changes]
 * will be notified.
 */
class ObservableMap<K, V> extends ChangeNotifierBase implements Map<K, V> {
  static const _LENGTH = const Symbol('length');

  final Map<K, V> _map;

  /** Creates an observable map. */
  ObservableMap() : _map = new HashMap<K, V>();

  /** Creates a new observable map using a [LinkedHashMap]. */
  ObservableMap.linked() : _map = new LinkedHashMap<K, V>();

  /** Creates a new observable map using a [SplayTreeMap]. */
  ObservableMap.sorted() : _map = new SplayTreeMap<K, V>();

  /**
   * Creates an observable map that contains all key value pairs of [other].
   * It will attempt to use the same backing map type if the other map is a
   * [LinkedHashMap], [SplayTreeMap], or [HashMap]. Otherwise it defaults to
   * [HashMap].
   *
   * Note this will perform a shallow conversion. If you want a deep conversion
   * you should use [toObservable].
   */
  factory ObservableMap.from(Map<K, V> other) {
    return new ObservableMap<K, V>._createFromType(other)..addAll(other);
  }

  factory ObservableMap._createFromType(Map<K, V> other) {
    ObservableMap result;
    if (other is SplayTreeMap) {
      result = new ObservableMap<K, V>.sorted();
    } else if (other is LinkedHashMap) {
      result = new ObservableMap<K, V>.linked();
    } else {
      result = new ObservableMap<K, V>();
    }
    return result;
  }

  Iterable<K> get keys => _map.keys;

  Iterable<V> get values => _map.values;

  int get length =>_map.length;

  bool get isEmpty => length == 0;

  bool get isNotEmpty => !isEmpty;

  bool containsValue(Object value) => _map.containsValue(value);

  bool containsKey(Object key) => _map.containsKey(key);

  V operator [](Object key) => _map[key];

  void operator []=(K key, V value) {
    int len = _map.length;
    V oldValue = _map[key];
    _map[key] = value;
    if (hasObservers) {
      if (len != _map.length) {
        notifyPropertyChange(_LENGTH, len, _map.length);
        notifyChange(new MapChangeRecord(key, isInsert: true));
      } else if (!identical(oldValue, value)) {
        notifyChange(new MapChangeRecord(key));
      }
    }
  }

  void addAll(Map<K, V> other) {
    other.forEach((K key, V value) { this[key] = value; });
  }

  V putIfAbsent(K key, V ifAbsent()) {
    int len = _map.length;
    V result = _map.putIfAbsent(key, ifAbsent);
    if (hasObservers && len != _map.length) {
      notifyPropertyChange(_LENGTH, len, _map.length);
      notifyChange(new MapChangeRecord(key, isInsert: true));
    }
    return result;
  }

  V remove(Object key) {
    int len = _map.length;
    V result =  _map.remove(key);
    if (hasObservers && len != _map.length) {
      notifyChange(new MapChangeRecord(key, isRemove: true));
      notifyPropertyChange(_LENGTH, len, _map.length);
    }
    return result;
  }

  void clear() {
    int len = _map.length;
    if (hasObservers && len > 0) {
      _map.forEach((key, value) {
        notifyChange(new MapChangeRecord(key, isRemove: true));
      });
      notifyPropertyChange(_LENGTH, len, 0);
    }
    _map.clear();
  }

  void forEach(void f(K key, V value)) => _map.forEach(f);

  String toString() => Maps.mapToString(this);
}
