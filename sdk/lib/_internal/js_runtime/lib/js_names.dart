// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart._js_names;

import 'dart:_js_embedded_names'
    show JsGetName, MANGLED_GLOBAL_NAMES, MANGLED_NAMES;

import 'dart:_foreign_helper' show JS, JS_EMBEDDED_GLOBAL, JS_GET_NAME;

import 'dart:_js_helper' show JsCache, NoInline;

import 'dart:_interceptors' show JSArray;

/// No-op method that is called to inform the compiler that unmangled named
/// must be preserved.
preserveNames() {}

/// A map from mangled names to "reflective" names, that is, unmangled names
/// with some additional information, such as, number of required arguments.
/// This map is for mangled names used as instance members.
final _LazyMangledNamesMap mangledNames = new _LazyMangledInstanceNamesMap(
    JS_EMBEDDED_GLOBAL('=Object', MANGLED_NAMES));

/// A map from "reflective" names to mangled names (the reverse of
/// [mangledNames]).
final _LazyReflectiveNamesMap reflectiveNames = new _LazyReflectiveNamesMap(
    JS_EMBEDDED_GLOBAL('=Object', MANGLED_NAMES), true);

/// A map from mangled names to "reflective" names (see [mangledNames]).  This
/// map is for globals, that is, static and top-level members.
final _LazyMangledNamesMap mangledGlobalNames = new _LazyMangledNamesMap(
    JS_EMBEDDED_GLOBAL('=Object', MANGLED_GLOBAL_NAMES));

/// A map from "reflective" names to mangled names (the reverse of
/// [mangledGlobalNames]).
final _LazyReflectiveNamesMap reflectiveGlobalNames =
    new _LazyReflectiveNamesMap(
        JS_EMBEDDED_GLOBAL('=Object', MANGLED_GLOBAL_NAMES), false);

/// Implements a mapping from mangled names to their reflective counterparts.
/// The propertiy names of [_jsMangledNames] are the mangled names, and the
/// values are the "reflective" names.
class _LazyMangledNamesMap {
  /// [_jsMangledNames] is a JavaScript object literal.
  var _jsMangledNames;

  _LazyMangledNamesMap(this._jsMangledNames);

  String operator [](String key) {
    var result = JS('var', '#[#]', _jsMangledNames, key);
    // Filter out all non-string values to protect against polution from
    // anciliary fields in [_jsMangledNames].
    bool filter = JS('bool', 'typeof # !== "string"', result);
    // To ensure that the inferrer sees that result is a String, we explicitly
    // give it a better type here.
    return filter ? null : JS('String', '#', result);
  }
}

/// Extends [_LazyMangledNamesMap] with additional support for adding mappings
/// from mangled setter names to their reflective counterpart by rewriting a
/// corresponding entry for a getter name, if it exists.
class _LazyMangledInstanceNamesMap extends _LazyMangledNamesMap {
  _LazyMangledInstanceNamesMap(_jsMangledNames) : super(_jsMangledNames);

  String operator [](String key) {
    String result = super[key];
    String setterPrefix = JS_GET_NAME(JsGetName.SETTER_PREFIX);
    if (result == null && key.startsWith(setterPrefix)) {
      String getterPrefix = JS_GET_NAME(JsGetName.GETTER_PREFIX);
      int setterPrefixLength = setterPrefix.length;

      // Generate the setter name from the getter name.
      key = '$getterPrefix${key.substring(setterPrefixLength)}';
      result = super[key];
      return (result != null) ? "${result}=" : null;
    }
    return result;
  }
}

/// Implements the inverse of [_LazyMangledNamesMap]. As it would be too
/// expensive to seach the mangled names map for a value that corresponds to
/// the lookup key on each invocation, we compute the full mapping in demand
/// and cache it. The cache is invalidated when the underlying [_jsMangledNames]
/// object changes its length. This condition is sufficient as the name mapping
/// can only grow over time.
/// When [_isInstance] is true, we also apply the inverse of the setter/getter
/// name conversion implemented by [_LazyMangledInstanceNamesMap].
class _LazyReflectiveNamesMap {
  /// [_jsMangledNames] is a JavaScript object literal.
  final _jsMangledNames;
  final bool _isInstance;
  int _cacheLength = 0;
  Map<String, String> _cache;

  _LazyReflectiveNamesMap(this._jsMangledNames, this._isInstance);

  Map<String, String> _updateReflectiveNames() {
    preserveNames();
    Map<String, String> result = <String, String>{};
    List keys = JS('List', 'Object.keys(#)', _jsMangledNames);
    for (String key in keys) {
      var reflectiveName = JS('var', '#[#]', _jsMangledNames, key);
      // Filter out all non-string values to protect against polution from
      // anciliary fields in [_jsMangledNames].
      bool filter = JS('bool', 'typeof # !== "string"', reflectiveName);
      if (filter) continue;
      result[reflectiveName] = JS('String', '#', key);

      String getterPrefix = JS_GET_NAME(JsGetName.GETTER_PREFIX);
      if (_isInstance && key.startsWith(getterPrefix)) {
        int getterPrefixLength = getterPrefix.length;
        String setterPrefix = JS_GET_NAME(JsGetName.SETTER_PREFIX);
        result['$reflectiveName='] =
            '$setterPrefix${key.substring(getterPrefixLength)}';
      }
    }
    return result;
  }

  int get _jsMangledNamesLength =>
      JS('int', 'Object.keys(#).length', _jsMangledNames);

  String operator [](String key) {
    if (_cache == null || _jsMangledNamesLength != _cacheLength) {
      _cache = _updateReflectiveNames();
      _cacheLength = _jsMangledNamesLength;
    }
    return _cache[key];
  }
}

@NoInline()
List extractKeys(victim) {
  var result = JS('', '# ? Object.keys(#) : []', victim, victim);
  return new JSArray.markFixed(result);
}

/**
 * Returns the (global) unmangled version of [name].
 *
 * Normally, you should use [mangledGlobalNames] directly, but this method
 * doesn't tell the compiler to preserve names. So this method only returns a
 * non-null value if some other component has made the compiler preserve names.
 *
 * This is used, for example, to return unmangled names from TypeImpl.toString
 * *if* names are being preserved for other reasons (use of dart:mirrors, for
 * example).
 */
String unmangleGlobalNameIfPreservedAnyways(String name) {
  var names = JS_EMBEDDED_GLOBAL('=Object', MANGLED_GLOBAL_NAMES);
  return JsCache.fetch(names, name);
}

String unmangleAllIdentifiersIfPreservedAnyways(String str) {
  return JS(
      'String',
      r'''
        (function(str, names) {
          return str.replace(
              /[^<,> ]+/g,
              function(m) { return names[m] || m; });
        })(#, #)''',
      str,
      JS_EMBEDDED_GLOBAL('', MANGLED_GLOBAL_NAMES));
}
