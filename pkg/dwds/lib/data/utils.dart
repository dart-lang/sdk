// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Converts a list of key-value pairs into a map.
///
/// The list is expected to be in the format:
/// ['key1', value1, 'key2', value2, ...]
///
/// Or, if [type] is provided:
/// ['Type', 'key1', value1, 'key2', value2, ...]
///
/// If [type] is provided, the first element of the list must match [type],
/// and the key-value pairs start from the second element.
Map<String, dynamic> listToMap(List<dynamic> list, {String? type}) {
  var startIndex = 0;
  if (type != null) {
    if (list.isEmpty || list.first != type) {
      throw FormatException('Expected "$type" as first element', list);
    }
    startIndex = 1;
  }

  if ((list.length - startIndex).isOdd) {
    throw FormatException(
      'Expected an even number of elements${type != null ? " after $type" : ""}',
      list,
    );
  }
  final map = <String, dynamic>{};
  var i = startIndex;
  while (i < list.length - 1) {
    final key = list[i] as String;
    final value = list[i + 1];
    map[key] = value;
    i += 2;
  }
  return map;
}
