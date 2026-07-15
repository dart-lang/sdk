// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Recursively converts [object] to a strictly JSON-compatible representation.
///
/// This will avoid allocations if [object] is already a JSON-compatible
/// primitive or a collection containing only JSON-compatible types.
///
/// This will always ensure [Map]s are [Map<String, Object?>] and [List]s are
/// [List<Object?>].
///
/// This is used to "purify" complex objects (like those from the LSP protocol)
/// before they are sent over a JSON-RPC 2.0 peer that is not using string
/// encoding.
Object? jsonify(Object? object) {
  if (object is String || object is num || object is bool || object == null) {
    return object;
  }

  if (object is List) {
    List<Object?>? newList;
    for (var i = 0; i < object.length; i++) {
      final item = object[i];
      final jsonified = jsonify(item);
      if (newList != null) {
        newList.add(jsonified);
      } else if (!identical(item, jsonified)) {
        newList = <Object?>[];
        for (var j = 0; j < i; j++) {
          newList.add(object[j]);
        }
        newList.add(jsonified);
      }
    }
    return newList ?? object;
  }

  if (object is Map) {
    Map<String, Object?>? newMap;
    // We check if the map is already Map<String, Object?> to decide if we can
    // return it as-is.
    final isCorrectType = object is Map<String, Object?>;

    var index = 0;
    for (final entry in object.entries) {
      final key = entry.key;
      final value = entry.value;

      final jsonifiedKey = key is String ? key : key.toString();
      final jsonifiedValue = jsonify(value);

      if (newMap != null) {
        newMap[jsonifiedKey] = jsonifiedValue;
      } else if (!isCorrectType ||
          !identical(key, jsonifiedKey) ||
          !identical(value, jsonifiedValue)) {
        newMap = <String, Object?>{};
        var j = 0;
        for (final prevEntry in object.entries) {
          if (j >= index) break;
          newMap[prevEntry.key.toString()] = prevEntry.value;
          j++;
        }
        newMap[jsonifiedKey] = jsonifiedValue;
      }
      index++;
    }

    if (newMap != null) return newMap;
    if (isCorrectType) return object;
    return object.cast<String, Object?>();
  }

  // If it has a toJson method, call it recursively.
  try {
    // ignore: avoid_dynamic_calls
    return jsonify((object as dynamic).toJson());
    // ignore: avoid_catching_errors
  } on NoSuchMethodError {
    // Fallback for objects without toJson()
    return object.toString();
  }
}
