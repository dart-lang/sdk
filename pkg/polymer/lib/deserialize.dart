// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library polymer.deserialize;

import 'dart:convert' show JSON;

final _typeHandlers = {
  String: (x, _) => x,
  Null: (x, _) => x,
  DateTime: (x, def) {
    // TODO(jmesserly): shouldn't need to try-catch here
    // See: https://code.google.com/p/dart/issues/detail?id=1878
    try {
      return DateTime.parse(x);
    } catch (e) {
      return def;
    }
  },
  bool: (x, _) => x != 'false',
  int: (x, def) => int.parse(x, onError: (_) => def),
  double: (x, def) => double.parse(x, (_) => def),
};

/// Convert representation of [value] based on [type] and [currentValue].
Object deserializeValue(String value, Object currentValue, Type type) {
  var handler = _typeHandlers[type];
  if (handler != null) return handler(value, currentValue);

  try {
    // If the string is an object, we can parse is with the JSON library.
    // include convenience replace for single-quotes. If the author omits
    // quotes altogether, parse will fail.
    return JSON.decode(value.replaceAll("'", '"'));

    // TODO(jmesserly): deserialized JSON is not assignable to most objects in
    // Dart. We should attempt to convert it appropriately.
  } catch(e) {
    // The object isn't valid JSON, return the raw value
    return value;
  }
}
