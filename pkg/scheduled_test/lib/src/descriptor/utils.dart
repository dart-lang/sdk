// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library descriptor.utils;

import 'dart:io';

import 'package:pathos/path.dart' as path;

/// Returns a single filesystem entry within [parent] whose name matches
/// [pattern]. If [pattern] is a string, looks for an exact match; otherwise,
/// looks for an entry that contains [pattern].
///
/// If there are no entries in [parent] matching [pattern], or more than one,
/// this will throw an exception.
///
/// [type] is used for error reporting. It should be capitalized.
String entryMatchingPattern(String type, String parent, Pattern pattern) {
  if (pattern is String) {
    var fullPath = path.join(parent, pattern);
    if (new File(fullPath).existsSync() || new Directory(fullPath).existsSync()) {
      return fullPath;
    }
    throw "$type not found: '$fullPath'.";
  }

  var matchingEntries = new Directory(parent).listSync()
      .map((entry) => entry is File ? entry.fullPathSync() : entry.path)
      .where((entry) => path.basename(entry).contains(pattern))
      .toList();
  matchingEntries.sort();

  if (matchingEntries.length == 0) {
    throw "No entry found in '$parent' matching ${describePattern(pattern)}.";
  } else if (matchingEntries.length > 1) {
    throw "Multiple entries found in '$parent' matching "
          "${describePattern(pattern)}:\n"
      "${matchingEntries.map((entry) => '* $entry').join('\n')}";
  } else {
    return matchingEntries.first;
  }
}

/// Returns a human-readable description of [pattern].
String describePattern(Pattern pattern) {
  if (pattern is String) return "'$pattern'";
  if (pattern is! RegExp) return '$pattern';

  var flags = new StringBuffer();
  if (!pattern.isCaseSensitive) flags.add('i');
  if (pattern.isMultiLine) flags.add('m');
  return '/${pattern.pattern}/$flags';
}
