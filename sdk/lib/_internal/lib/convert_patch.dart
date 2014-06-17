// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Patch file for dart:convert library.

import 'dart:_js_helper' show patch;
import 'dart:_foreign_helper' show JS;
import 'dart:_interceptors' show JSExtendableArray;

/**
 * Parses [json] and builds the corresponding parsed JSON value.
 *
 * Parsed JSON values Nare of the types [num], [String], [bool], [Null],
 * [List]s of parsed JSON values or [Map]s from [String] to parsed
 * JSON values.
 *
 * The optional [reviver] function, if provided, is called once for each object
 * or list property parsed. The arguments are the property name ([String]) or
 * list index ([int]), and the value is the parsed value.  The return value of
 * the reviver will be used as the value of that property instead of the parsed
 * value.  The top level value is passed to the reviver with the empty string as
 * a key.
 *
 * Throws [FormatException] if the input is not valid JSON text.
 */
@patch
_parseJson(String source, reviver(key, value)) {
  if (source is! String) throw new ArgumentError(source);

  var parsed;
  try {
    parsed = JS('=Object|JSExtendableArray|Null|bool|num|String',
                'JSON.parse(#)',
                source);
  } catch (e) {
    throw new FormatException(JS('String', 'String(#)', e));
  }

  return _convertJsonToDart(parsed, reviver);
}

/**
 * Walks the raw JavaScript value [json], replacing JavaScript Objects with
 * Maps. [json] is expected to be freshly allocated so elements can be replaced
 * in-place.
 */
_convertJsonToDart(json, reviver(key, value)) {

  var revive = reviver == null ? (key, value) => value : reviver;

  walk(e) {
    // JavaScript null, string, number, bool are in the correct representation.
    if (JS('bool', '# == null', e) || JS('bool', 'typeof # != "object"', e)) {
      return e;
    }

    // This test is needed to avoid identifing '{"__proto__":[]}' as an Array.
    // TODO(sra): Replace this test with cheaper '#.constructor === Array' when
    // bug 621 below is fixed.
    if (JS('bool', 'Object.getPrototypeOf(#) === Array.prototype', e)) {
      var list = JS('JSExtendableArray', '#', e);  // Teach compiler the type is known.
      // In-place update of the elements since JS Array is a Dart List.
      for (int i = 0; i < list.length; i++) {
        // Use JS indexing to avoid range checks.  We know this is the only
        // reference to the list, but the compiler will likely never be able to
        // tell that this instance of the list cannot have its length changed by
        // the reviver even though it later will be passed to the reviver at the
        // outer level.
        var item = JS('', '#[#]', list, i);
        JS('', '#[#]=#', list, i, revive(i, walk(item)));
      }
      return list;
    }

    // Otherwise it is a plain Object, so copy to a Map.
    var keys = JS('JSExtendableArray', 'Object.keys(#)', e);
    Map map = {};
    for (int i = 0; i < keys.length; i++) {
      String key = keys[i];
      map[key] = revive(key, walk(JS('', '#[#]', e, key)));
    }
    // V8 has a bug with properties named "__proto__"
    // https://code.google.com/p/v8/issues/detail?id=621
    var proto = JS('', '#.__proto__', e);
    // __proto__ can be undefined on IE9.
    if (JS('bool',
           'typeof # !== "undefined" && # !== Object.prototype',
           proto, proto)) {
      map['__proto__'] = revive('__proto__', walk(proto));
    }
    return map;
  }

  return revive(null, walk(json));
}

@patch
class _Utf8Encoder {
  // Use Uint8List when supported on all platforms.
  @patch
  static List<int> _createBuffer(int size) => new List<int>(size);
}
