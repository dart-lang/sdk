// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('json');
#import('dart:coreimpl');

// TODO(jmesserly): this needs cleanup
// Ideally JS objects could be treated as Dart Maps directly, and then we can
// really use native JSON.parse and JSON.stringify.

typedef Object _NativeJsonConvert(Object key, Object value);

class _JSON native 'JSON' {
  static Object parse(String jsonString, _NativeJsonConvert fn) native;
  static String stringify(Object value, _NativeJsonConvert fn) native;
}


Object _getValue(obj, key) native 'return obj[key]';
void _setValue(obj, key, value) native 'obj[key] = value';

// This is a guard against general Dart objects getting through to
// JSON.stringify. We restrict to JS primitives and JS Array.
bool _directToJson(obj) native
  "return typeof obj != 'object' || obj == null || obj instanceof Array";

ListFactory<String> _jsKeys(Object obj) native '''
if (obj != null && typeof obj == 'object' && !(obj instanceof Array)) {
return Object.keys(obj);
}
return null;
''';

/**
 * Dart interface to JavaScript objects and JSON.
 */
class JSON {
  /**
   * Takes a string in JSON notation and returns the value it
   * represents.  The resulting value is one of the following:
   *  * null
   *  * a bool
   *  * a double
   *  * a String
   *  * an Array of values (recursively)
   *  * a Map from property names to values (recursively)
   */
  static Object parse(String str) {
    return _JSON.parse(str, (_, obj) {
      final keys = _jsKeys(obj);
      if (keys == null) return obj;

      // Note: only need to shallow convert here--JSON.parse handles the rest.
      final map = {};
      for (String key in keys) {
        map[key] = _getValue(obj, key);
      }
      return map;
    });
  }

  /**
   * Takes a value and returns a string in JSON notation
   * representing its value, or returns null if the value is not representable
   * in JSON.  A representable value is one of the following:
   *  * null
   *  * a bool
   *  * a double
   *  * a String
   *  * an Array of values (recursively)
   *  * a Map from property names to values (recursively)
   */
  // TODO(jmesserly): handle any List subtype? Right now it's converted as
  // something like:
  //     {"0":1,"1":2}
  static String stringify(Object value) {
    return _JSON.stringify(value, (_, obj) {
      if (_directToJson(obj)) return obj;
      if (obj is Map<String, Dynamic>) {
        Map<String, Dynamic> map = obj;
        obj = new Object();
        map.forEach((k, v) => _setValue(obj, k, v));
        return obj;
      }
      throw new IllegalArgumentException('cannot convert "$value" to JSON');
    });
  }
}
