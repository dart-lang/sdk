// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of custom_element;

/**
 * Represents an attribute map of model values. If any items are added,
 * removed, or replaced, then observers that are listening to [changes]
 * will be notified.
 */
class _AttributeMap implements Map<String, String> {
  final CustomElement _element;
  final Map<String, String> _map;

  /** Creates an attribute map wrapping the host attributes. */
  _AttributeMap(CustomElement element)
      : _element = element, _map = element.host.attributes;

  // Forward all read methods:
  Iterable<String> get keys => _map.keys;
  Iterable<String> get values => _map.values;
  int get length =>_map.length;
  bool get isEmpty => _map.isEmpty;
  bool get isNotEmpty => _map.isNotEmpty;
  bool containsValue(Object value) => _map.containsValue(value);
  bool containsKey(Object key) => _map.containsKey(key);
  String operator [](Object key) => _map[key];
  void forEach(void f(String key, String value)) => _map.forEach(f);
  String toString() => _map.toString();

  // Override the write methods and ensure attributeChanged is called:
  void operator []=(String key, String value) {
    int len = _map.length;
    String oldValue = _map[key];
    _map[key] = value;
    if (len != _map.length || !identical(oldValue, value)) {
      _element.attributeChanged(key, oldValue);
    }
  }

  void addAll(Map<String, String> other) {
    other.forEach((String key, String value) { this[key] = value; });
  }

  String putIfAbsent(String key, String ifAbsent()) {
    int len = _map.length;
    String result = _map.putIfAbsent(key, ifAbsent);
    if (len != _map.length) {
      _element.attributeChanged(key, null);
    }
    return result;
  }

  String remove(Object key) {
    int len = _map.length;
    String result =  _map.remove(key);
    if (len != _map.length) {
      _element.attributeChanged(key, result);
    }
    return result;
  }

  void clear() {
    int len = _map.length;
    if (len > 0) {
      _map.forEach((key, value) {
        _element.attributeChanged(key, value);
      });
    }
    _map.clear();
  }

  /**
   * This is not a [Map] method. We use it to implement "set attributes", which
   * is a global replace operation. Rather than [clear] followed by [addAll],
   * we try to be a bit smarter.
   */
  void _replaceAll(Map<String, String> other) {
    for (var key in keys) {
      if (!other.containsKey(key)) remove(key);
    }
    addAll(other);
  }
}
