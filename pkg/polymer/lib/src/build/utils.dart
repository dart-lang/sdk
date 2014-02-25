// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library polymer.src.utils;

/// Converts a string name with hyphens into an identifier, by removing hyphens
/// and capitalizing the following letter. Optionally [startUppercase] to
/// captialize the first letter.
String toCamelCase(String hyphenedName, {bool startUppercase: false}) {
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

/// Reverse of [toCamelCase].
String toHyphenedName(String word) {
  var sb = new StringBuffer();
  for (int i = 0; i < word.length; i++) {
    var lower = word[i].toLowerCase();
    if (word[i] != lower && i > 0) sb.write('-');
    sb.write(lower);
  }
  return sb.toString();
}
