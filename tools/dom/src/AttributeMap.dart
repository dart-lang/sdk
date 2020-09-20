// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of html;

abstract class _AttributeMap extends MapBase<String, String> {
  final Element _element;

  _AttributeMap(this._element);

  void addAll(Map<String, String> other) {
    other.forEach((k, v) {
      this[k] = v;
    });
  }

  Map<K, V> cast<K, V>() => Map.castFrom<String, String, K, V>(this);
  bool containsValue(Object? value) {
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
    return this[key] as String;
  }

  void clear() {
    for (var key in keys) {
      remove(key);
    }
  }

  void forEach(void f(String key, String value)) {
    for (var key in keys) {
      var value = this[key];
      f(key, value as String);
    }
  }

  Iterable<String> get keys {
    // TODO: generate a lazy collection instead.
    var attributes = _element._attributes!;
    var keys = <String>[];
    for (int i = 0, len = attributes.length; i < len; i++) {
      _Attr attr = attributes[i] as _Attr;
      if (_matches(attr)) {
        keys.add(attr.name!);
      }
    }
    return keys;
  }

  Iterable<String> get values {
    // TODO: generate a lazy collection instead.
    var attributes = _element._attributes!;
    var values = <String>[];
    for (int i = 0, len = attributes.length; i < len; i++) {
      _Attr attr = attributes[i] as _Attr;
      if (_matches(attr)) {
        values.add(attr.value!);
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

  bool containsKey(Object? key) {
    return key is String && _element._hasAttribute(key);
  }

  String? operator [](Object? key) {
    return _element.getAttribute(key as String);
  }

  void operator []=(String key, String value) {
    _element.setAttribute(key, value);
  }

  @pragma('dart2js:tryInline')
  String? remove(Object? key) => key is String ? _remove(_element, key) : null;

  /**
   * The number of {key, value} pairs in the map.
   */
  int get length {
    return keys.length;
  }

  bool _matches(_Attr node) => node._namespaceUri == null;

  // Inline this because almost all call sites of [remove] do not use [value],
  // and the annotations on the `getAttribute` call allow it to be removed.
  @pragma('dart2js:tryInline')
  static String? _remove(Element element, String key) {
    String? value = JS(
        // throws:null(1) is not accurate since [key] could be malformed, but
        // [key] is checked again by `removeAttributeNS`.
        'returns:String|Null;depends:all;effects:none;throws:null(1)',
        '#.getAttribute(#)',
        element,
        key);
    JS('', '#.removeAttribute(#)', element, key);
    return value;
  }
}

/**
 * Wrapper to expose namespaced attributes as a typed map.
 */
class _NamespacedAttributeMap extends _AttributeMap {
  final String? _namespace;

  _NamespacedAttributeMap(Element element, this._namespace) : super(element);

  bool containsKey(Object? key) {
    return key is String && _element._hasAttributeNS(_namespace, key);
  }

  String? operator [](Object? key) {
    return _element.getAttributeNS(_namespace, key as String);
  }

  void operator []=(String key, String value) {
    _element.setAttributeNS(_namespace, key, value);
  }

  @pragma('dart2js:tryInline')
  String? remove(Object? key) =>
      key is String ? _remove(_namespace, _element, key) : null;

  /**
   * The number of {key, value} pairs in the map.
   */
  int get length {
    return keys.length;
  }

  bool _matches(_Attr node) => node._namespaceUri == _namespace;

  // Inline this because almost all call sites of [remove] do not use the
  // returned [value], and the annotations on the `getAttributeNS` call allow it
  // to be removed.
  @pragma('dart2js:tryInline')
  static String? _remove(String? namespace, Element element, String key) {
    String? value = JS(
        // throws:null(1) is not accurate since [key] could be malformed, but
        // [key] is checked again by `removeAttributeNS`.
        'returns:String|Null;depends:all;effects:none;throws:null(1)',
        '#.getAttributeNS(#, #)',
        element,
        namespace,
        key);
    JS('', '#.removeAttributeNS(#, #)', element, namespace, key);
    return value;
  }
}

/**
 * Provides a Map abstraction on top of data-* attributes, similar to the
 * dataSet in the old DOM.
 */
class _DataAttributeMap extends MapBase<String, String> {
  final Map<String, String> _attributes;

  _DataAttributeMap(this._attributes);

  // interface Map

  void addAll(Map<String, String> other) {
    other.forEach((k, v) {
      this[k] = v;
    });
  }

  Map<K, V> cast<K, V>() => Map.castFrom<String, String, K, V>(this);
  // TODO: Use lazy iterator when it is available on Map.
  bool containsValue(Object? value) => values.any((v) => v == value);

  bool containsKey(Object? key) =>
      _attributes.containsKey(_attr(key as String));

  String? operator [](Object? key) => _attributes[_attr(key as String)];

  void operator []=(String key, String value) {
    _attributes[_attr(key)] = value;
  }

  String putIfAbsent(String key, String ifAbsent()) =>
      _attributes.putIfAbsent(_attr(key), ifAbsent);

  String? remove(Object? key) => _attributes.remove(_attr(key as String));

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
   * capitalize the first letter.
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
