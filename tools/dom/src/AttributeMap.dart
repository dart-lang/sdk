// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of html;

abstract class _AttributeMap implements Map<String, String> {
  final Element _element;

  _AttributeMap(this._element);

  void addAll(Map<String, String> other) {
    other.forEach((k, v) {
      this[k] = v;
    });
  }

  bool containsValue(Object value) {
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
    var keys = <String>[];
    for (int i = 0, len = attributes.length; i < len; i++) {
      _Attr attr = attributes[i];
      if (_matches(attr)) {
        keys.add(attr.name);
      }
    }
    return keys;
  }

  Iterable<String> get values {
    // TODO: generate a lazy collection instead.
    var attributes = _element._attributes;
    var values = <String>[];
    for (int i = 0, len = attributes.length; i < len; i++) {
      _Attr attr = attributes[i];
      if (_matches(attr)) {
        values.add(attr.value);
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
  bool _matches(_Attr node);
}

/**
 * Wrapper to expose [Element.attributes] as a typed map.
 */
class _ElementAttributeMap extends _AttributeMap {
  _ElementAttributeMap(Element element) : super(element);

  bool containsKey(Object key) {
    return _element._hasAttribute(key);
  }

  String operator [](Object key) {
    return _element.getAttribute(key);
  }

  void operator []=(String key, String value) {
    _element.setAttribute(key, value);
  }

  String remove(Object key) {
    String value = _element.getAttribute(key);
    _element._removeAttribute(key);
    return value;
  }

  /**
   * The number of {key, value} pairs in the map.
   */
  int get length {
    return keys.length;
  }

  bool _matches(_Attr node) => node._namespaceUri == null;
}

/**
 * Wrapper to expose namespaced attributes as a typed map.
 */
class _NamespacedAttributeMap extends _AttributeMap {
  final String _namespace;

  _NamespacedAttributeMap(Element element, this._namespace) : super(element);

  bool containsKey(Object key) {
    return _element._hasAttributeNS(_namespace, key);
  }

  String operator [](Object key) {
    return _element.getAttributeNS(_namespace, key);
  }

  void operator []=(String key, String value) {
    _element.setAttributeNS(_namespace, key, value);
  }

  String remove(Object key) {
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

  bool _matches(_Attr node) => node._namespaceUri == _namespace;
}

/**
 * Provides a Map abstraction on top of data-* attributes, similar to the
 * dataSet in the old DOM.
 */
class _DataAttributeMap implements Map<String, String> {
  final Map<String, String> _attributes;

  _DataAttributeMap(this._attributes);

  // interface Map

  void addAll(Map<String, String> other) {
    other.forEach((k, v) {
      this[k] = v;
    });
  }

  // TODO: Use lazy iterator when it is available on Map.
  bool containsValue(Object value) => values.any((v) => v == value);

  bool containsKey(Object key) => _attributes.containsKey(_attr(key));

  String operator [](Object key) => _attributes[_attr(key)];

  void operator []=(String key, String value) {
    _attributes[_attr(key)] = value;
  }

  String putIfAbsent(String key, String ifAbsent()) =>
      _attributes.putIfAbsent(_attr(key), ifAbsent);

  String remove(Object key) => _attributes.remove(_attr(key));

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
    final keys = <String>[];
    _attributes.forEach((String key, String value) {
      if (_matches(key)) {
        keys.add(_strip(key));
      }
    });
    return keys;
  }

  Iterable<String> get values {
    final values = <String>[];
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
  String _attr(String key) => 'data-${_toHyphenedName(key)}';
  bool _matches(String key) => key.startsWith('data-');
  String _strip(String key) => _toCamelCase(key.substring(5));

  /**
   * Converts a string name with hyphens into an identifier, by removing hyphens
   * and capitalizing the following letter. Optionally [startUppercase] to
   * captialize the first letter.
   */
  String _toCamelCase(String hyphenedName, {bool startUppercase: false}) {
    var segments = hyphenedName.split('-');
    int start = startUppercase ? 0 : 1;
    for (int i = start; i < segments.length; i++) {
      var segment = segments[i];
      if (segment.length > 0) {
        // Character between 'a'..'z' mapped to 'A'..'Z'
        segments[i] = '${segment[0].toUpperCase()}${segment.substring(1)}';
      }
    }
    return segments.join('');
  }

  /** Reverse of [toCamelCase]. */
  String _toHyphenedName(String word) {
    var sb = new StringBuffer();
    for (int i = 0; i < word.length; i++) {
      var lower = word[i].toLowerCase();
      if (word[i] != lower && i > 0) sb.write('-');
      sb.write(lower);
    }
    return sb.toString();
  }
}
