// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart.pkg.collection.canonicalized_map;

import 'dart:collection';

import 'utils.dart';

/**
 * A map whose keys are converted to canonical values of type `C`.
 *
 * This is useful for using case-insensitive String keys, for example. It's more
 * efficient than a [LinkedHashMap] with a custom equality operator because it
 * only canonicalizes each key once, rather than doing so for each comparison.
 *
 * By default, `null` is allowed as a key. It can be forbidden via the
 * `isValidKey` parameter.
 */
class CanonicalizedMap<C, K, V> implements Map<K, V> {
  final Function _canonicalize;

  final Function _isValidKeyFn;

  final _base = new Map<C, Pair<K, V>>();

  /**
   * Creates an empty canonicalized map.
   *
   * The [canonicalize] function should return the canonical value for the given
   * key. Keys with the same canonical value are considered equivalent.
   *
   * The [isValidKey] function is called before calling [canonicalize] for
   * methods that take arbitrary objects. It can be used to filter out keys that
   * can't be canonicalized.
   */
  CanonicalizedMap(C canonicalize(K key), {bool isValidKey(K key)})
      : _canonicalize = canonicalize,
        _isValidKeyFn = isValidKey;

  /**
   * Creates a canonicalized map that is initialized with the key/value pairs of
   * [other].
   *
   * The [canonicalize] function should return the canonical value for the given
   * key. Keys with the same canonical value are considered equivalent.
   *
   * The [isValidKey] function is called before calling [canonicalize] for
   * methods that take arbitrary objects. It can be used to filter out keys that
   * can't be canonicalized.
   */
  CanonicalizedMap.from(Map<K, V> other, C canonicalize(K key),
          {bool isValidKey(K key)})
      : _canonicalize = canonicalize,
        _isValidKeyFn = isValidKey {
    addAll(other);
  }

  V operator [](Object key) {
    if (!_isValidKey(key)) return null;
    var pair = _base[_canonicalize(key)];
    return pair == null ? null : pair.last;
  }

  void operator []=(K key, V value) {
    _base[_canonicalize(key)] = new Pair(key, value);
  }

  void addAll(Map<K, V> other) {
    other.forEach((key, value) => this[key] = value);
  }

  void clear() {
    _base.clear();
  }

  bool containsKey(Object key) {
    if (!_isValidKey(key)) return false;
    return _base.containsKey(_canonicalize(key));
  }

  bool containsValue(Object value) =>
      _base.values.any((pair) => pair.last == value);

  void forEach(void f(K key, V value)) {
    _base.forEach((key, pair) => f(pair.first, pair.last));
  }

  bool get isEmpty => _base.isEmpty;

  bool get isNotEmpty => _base.isNotEmpty;

  Iterable<K> get keys => _base.values.map((pair) => pair.first);

  int get length => _base.length;

  V putIfAbsent(K key, V ifAbsent()) {
    return _base.putIfAbsent(_canonicalize(key),
        () => new Pair(key, ifAbsent())).last;
  }

  V remove(Object key) {
    if (!_isValidKey(key)) return null;
    var pair = _base.remove(_canonicalize(key));
    return pair == null ? null : pair.last;
  }

  Iterable<V> get values => _base.values.map((pair) => pair.last);

  String toString() => Maps.mapToString(this);

  bool _isValidKey(Object key) => (key == null || key is K) &&
      (_isValidKeyFn == null || _isValidKeyFn(key));
}
