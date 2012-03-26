// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Misc benchmark-related utility functions.

class BenchUtil {
  static int get now() {
    return new Date.now().value;
  }

  static Map<String, Object> deserialize(String data) {
    return JSON.parse(data);
  }

  static String serialize(Object obj) {
    return JSON.stringify(obj);
  }

  // Shuffle an array randomly.
  static void shuffle(Array<Object> array) {
    int len = array.length - 1;
    for (int i = 0; i < len; i++) {
      int index = (Math.random() * (len - i)).toInt() + i;
      Object tmp = array[i];
      array[i] = array[index];
      array[index] = tmp;
    }
  }

  static String formatGolemData(String prefix, Map<String, num> results) {
    Array<String> elements = new Array<String>();
    results.forEach((String name, num score) {
      elements.add('"${prefix}/${name}":${score}');
    });
    return serialize(elements);
  }

  static bool _inRange(int charCode, String start, String end) {
    return start.charCodeAt(0) <= charCode && charCode <= end.charCodeAt(0);
  }

  static final String DIGITS = '0123456789ABCDEF';
  static String _asDigit(int value) {
    return DIGITS[value];
  }

  static String encodeUri(final String s) {
    StringBuffer sb = new StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final int charCode = s.charCodeAt(i);
      final bool noEscape =
          _inRange(charCode, '0', '9') ||
          _inRange(charCode, 'a', 'z') ||
          _inRange(charCode, 'A', 'Z');
      if (noEscape) {
        sb.add(s[i]);
      } else {
       sb.add('%');
       sb.add(_asDigit((charCode >> 4) & 0xF));
       sb.add(_asDigit(charCode & 0xF));
      }
    }
    return sb.toString();
  }

  // TODO: use corelib implementation.
  static String replaceAll(String s, String pattern,
                           String replacement(Match match)) {
    StringBuffer sb = new StringBuffer();

    int pos = 0;
    for (Match match in new RegExp(pattern, '').allMatches(s)) {
      sb.add(s.substring(pos, match.start()));
      sb.add(replacement(match));
      pos = match.end();
    }
    sb.add(s.substringToEnd(pos));

    return sb.toString();
  }
}
