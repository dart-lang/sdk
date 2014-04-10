// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library observe.src.observable_map;

import 'dart:collection';
import 'package:observe/observe.dart';


// TODO(jmesserly): this needs to be faster. We currently require multiple
// lookups per key to get the old value.
// TODO(jmesserly): this doesn't implement the precise interfaces like
// LinkedHashMap, SplayTreeMap or HashMap. However it can use them for the
// backing store.

// TODO(jmesserly): should we summarize map changes like we do for list changes?
class MapChangeRecord<K, V> extends ChangeRecord {
  // TODO(jmesserly): we could store this more compactly if it matters, with
  // subtypes for inserted and removed.

  /// The map key that changed.
  final K key;

  /// The previous value associated with this key.
  final V oldValue;

  /// The new value associated with this key.
  final V newValue;

  /// True if this key was inserted.
  final bool isInsert;

  /// True if this key was removed.
  final bool isRemove;

  MapChangeRecord(this.key, this.oldValue, this.newValue)
      : isInsert = false, isRemove = false;

  MapChangeRecord.insert(this.key, this.newValue)
      : isInsert = true, isRemove = false, oldValue = null;

  MapChangeRecord.remove(this.key, this.oldValue)
      : isInsert = false, isRemove = true, newValue = null;

  String toString() {
    var kind = isInsert ? 'insert' : isRemove ? 'remove' : 'set';
    return '#<MapChangeRecord $kind $key from: $oldValue to: $newValue>';
  }
}

/// Represents an observable map of model values. If any items are added,
/// removed, or replaced, then observers that are listening to [changes]
/// will be notified.
class ObservableMap<K, V> extends ChangeNotifier implements Map<K, V> {
  final Map<K, V> _map;

  /// Creates an observable map.
  ObservableMap() : _map = new HashMap<K, V>();

  /// Creates a new observable map using a [LinkedHashMap].
  ObservableMap.linked() : _map = new LinkedHashMap<K, V>();

  /// Creates a new observable map using a [SplayTreeMap].
  ObservableMap.sorted() : _map = new SplayTreeMap<K, V>();

  /// Creates an observable map that contains all key value pairs of [other].
  /// It will attempt to use the same backing map type if the other map is a
  /// [LinkedHashMap], [SplayTreeMap], or [HashMap]. Otherwise it defaults to
  /// [HashMap].
  ///
  /// Note this will perform a shallow conversion. If you want a deep conversion
  /// you should use [toObservable].
  factory ObservableMap.from(Map<K, V> other) {
    return new ObservableMap<K, V>.createFromType(other)..addAll(other);
  }

  /// Like [ObservableMap.from], but creates an empty map.
  factory ObservableMap.createFromType(Map<K, V> other) {
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

  @reflectable Iterable<K> get keys => _map.keys;

  @reflectable Iterable<V> get values => _map.values;

  @reflectable int get length =>_map.length;

  @reflectable bool get isEmpty => length == 0;

  @reflectable bool get isNotEmpty => !isEmpty;

  @reflectable bool containsValue(Object value) => _map.containsValue(value);

  @reflectable bool containsKey(Object key) => _map.containsKey(key);

  @reflectable V operator [](Object key) => _map[key];

  @reflectable void operator []=(K key, V value) {
    if (!hasObservers) {
      _map[key] = value;
      return;
    }

    int len = _map.length;
    V oldValue = _map[key];

    _map[key] = value;

    if (len != _map.length) {
      notifyPropertyChange(#length, len, _map.length);
      notifyChange(new MapChangeRecord.insert(key, value));
      _notifyKeysValuesChanged();
    } else if (oldValue != value) {
      notifyChange(new MapChangeRecord(key, oldValue, value));
      _notifyValuesChanged();
    }
  }

  void addAll(Map<K, V> other) {
    other.forEach((K key, V value) { this[key] = value; });
  }

  V putIfAbsent(K key, V ifAbsent()) {
    int len = _map.length;
    V result = _map.putIfAbsent(key, ifAbsent);
    if (hasObservers && len != _map.length) {
      notifyPropertyChange(#length, len, _map.length);
      notifyChange(new MapChangeRecord.insert(key, result));
      _notifyKeysValuesChanged();
    }
    return result;
  }

  V remove(Object key) {
    int len = _map.length;
    V result =  _map.remove(key);
    if (hasObservers && len != _map.length) {
      notifyChange(new MapChangeRecord.remove(key, result));
      notifyPropertyChange(#length, len, _map.length);
      _notifyKeysValuesChanged();
    }
    return result;
  }

  void clear() {
    int len = _map.length;
    if (hasObservers && len > 0) {
      _map.forEach((key, value) {
        notifyChange(new MapChangeRecord.remove(key, value));
      });
      notifyPropertyChange(#length, len, 0);
      _notifyKeysValuesChanged();
    }
    _map.clear();
  }

  void forEach(void f(K key, V value)) => _map.forEach(f);

  String toString() => Maps.mapToString(this);

  // Note: we don't really have a reasonable old/new value to use here.
  // But this should fix "keys" and "values" in templates with minimal overhead.
  void _notifyKeysValuesChanged() {
    notifyChange(new PropertyChangeRecord(this, #keys, null, null));
    _notifyValuesChanged();
  }

  void _notifyValuesChanged() {
    notifyChange(new PropertyChangeRecord(this, #values, null, null));
  }
}
