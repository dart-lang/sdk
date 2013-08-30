// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of html;

abstract class _AttributeMap implements Map<String, String> {
  final Element _element;

  _AttributeMap(this._element);

  bool containsValue(String value) {
    for (var v in this.values) {
      if (value == v) {
        return true;
      }
    }
    return false;
  }

  String putIfAbsent(String key, String ifAbsent()) {
    if (!containsKey(key)) {
      this[key] = ifAbsent();
    }
    return this[key];
  }

  void clear() {
    for (var key in keys) {
      remove(key);
    }
  }

  void forEach(void f(String key, String value)) {
    for (var key in keys) {
      var value = this[key];
      f(key, value);
    }
  }

  Iterable<String> get keys {
    // TODO: generate a lazy collection instead.
    var attributes = _element._attributes;
    var keys = new List<String>();
    for (int i = 0, len = attributes.length; i < len; i++) {
      if (_matches(attributes[i])) {
        keys.add(attributes[i].name);
      }
    }
    return keys;
  }

  Iterable<String> get values {
    // TODO: generate a lazy collection instead.
    var attributes = _element._attributes;
    var values = new List<String>();
    for (int i = 0, len = attributes.length; i < len; i++) {
      if (_matches(attributes[i])) {
        values.add(attributes[i].value);
      }
    }
    return values;
  }

  /**
   * Returns true if there is no {key, value} pair in the map.
   */
  bool get isEmpty {
    return length == 0;
  }

  /**
   * Returns true if there is at least one {key, value} pair in the map.
   */
  bool get isNotEmpty => !isEmpty;

  /**
   * Checks to see if the node should be included in this map.
   */
  bool _matches(Node node);
}

/**
 * Wrapper to expose [Element.attributes] as a typed map.
 */
class _ElementAttributeMap extends _AttributeMap {

  _ElementAttributeMap(Element element): super(element);

  bool containsKey(String key) {
    return _element._hasAttribute(key);
  }

  String operator [](String key) {
    return _element._getAttribute(key);
  }

  void operator []=(String key, String value) {
    _element._setAttribute(key, value);
  }

  String remove(String key) {
    String value = _element._getAttribute(key);
    _element._removeAttribute(key);
    return value;
  }

  /**
   * The number of {key, value} pairs in the map.
   */
  int get length {
    return keys.length;
  }

  bool _matches(Node node) => node._namespaceUri == null;
}

/**
 * Wrapper to expose namespaced attributes as a typed map.
 */
class _NamespacedAttributeMap extends _AttributeMap {

  final String _namespace;

  _NamespacedAttributeMap(Element element, this._namespace): super(element);

  bool containsKey(String key) {
    return _element._hasAttributeNS(_namespace, key);
  }

  String operator [](String key) {
    return _element._getAttributeNS(_namespace, key);
  }

  void operator []=(String key, String value) {
    _element._setAttributeNS(_namespace, key, value);
  }

  String remove(String key) {
    String value = this[key];
    _element._removeAttributeNS(_namespace, key);
    return value;
  }

  /**
   * The number of {key, value} pairs in the map.
   */
  int get length {
    return keys.length;
  }

  bool _matches(Node node) => node._namespaceUri == _namespace;
}


/**
 * Provides a Map abstraction on top of data-* attributes, similar to the
 * dataSet in the old DOM.
 */
class _DataAttributeMap implements Map<String, String> {

  final Map<String, String> _attributes;

  _DataAttributeMap(this._attributes);

  // interface Map

  // TODO: Use lazy iterator when it is available on Map.
  bool containsValue(String value) => values.any((v) => v == value);

  bool containsKey(String key) => _attributes.containsKey(_attr(key));

  String operator [](String key) => _attributes[_attr(key)];

  void operator []=(String key, String value) {
    _attributes[_attr(key)] = value;
  }

  String putIfAbsent(String key, String ifAbsent()) =>
    _attributes.putIfAbsent(_attr(key), ifAbsent);

  String remove(String key) => _attributes.remove(_attr(key));

  void clear() {
    // Needs to operate on a snapshot since we are mutating the collection.
    for (String key in keys) {
      remove(key);
    }
  }

  void forEach(void f(String key, String value)) {
    _attributes.forEach((String key, String value) {
      if (_matches(key)) {
        f(_strip(key), value);
      }
    });
  }

  Iterable<String> get keys {
    final keys = new List<String>();
    _attributes.forEach((String key, String value) {
      if (_matches(key)) {
        keys.add(_strip(key));
      }
    });
    return keys;
  }

  Iterable<String> get values {
    final values = new List<String>();
    _attributes.forEach((String key, String value) {
      if (_matches(key)) {
        values.add(value);
      }
    });
    return values;
  }

  int get length => keys.length;

  // TODO: Use lazy iterator when it is available on Map.
  bool get isEmpty => length == 0;

  bool get isNotEmpty => !isEmpty;

  // Helpers.
  String _attr(String key) => 'data-$key';
  bool _matches(String key) => key.startsWith('data-');
  String _strip(String key) => key.substring(5);
}
