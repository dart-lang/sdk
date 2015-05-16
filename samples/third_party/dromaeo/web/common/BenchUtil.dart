// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of common;

// Misc benchmark-related utility functions.

class BenchUtil {
  static int get now {
    return new DateTime.now().millisecondsSinceEpoch;
  }

  static Map<String, Object> deserialize(String data) {
    return JSON.decode(data);
  }

  static String serialize(Object obj) {
    return JSON.encode(obj);
  }

  // Shuffle a list randomly.
  static void shuffle(List<Object> list) {
    int len = list.length - 1;
    for (int i = 0; i < len; i++) {
      int index = (Math.random() * (len - i)).toInt() + i;
      Object tmp = list[i];
      list[i] = list[index];
      list[index] = tmp;
    }
  }

  static String formatGolemData(String prefix, Map<String, num> results) {
    List<String> elements = new List<String>();
    results.forEach((String name, num score) {
      elements.add('"${prefix}/${name}":${score}');
    });
    return serialize(elements);
  }

  static bool _inRange(int charCode, String start, String end) {
    return start.codeUnitAt(0) <= charCode && charCode <= end.codeUnitAt(0);
  }

  static const String DIGITS = '0123456789ABCDEF';
  static String _asDigit(int value) {
    return DIGITS[value];
  }

  static String encodeUri(final String s) {
    StringBuffer sb = new StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final int charCode = s.codeUnitAt(i);
      final bool noEscape =
          _inRange(charCode, '0', '9') ||
          _inRange(charCode, 'a', 'z') ||
          _inRange(charCode, 'A', 'Z');
      if (noEscape) {
        sb.write(s[i]);
      } else {
       sb.write('%');
       sb.write(_asDigit((charCode >> 4) & 0xF));
       sb.write(_asDigit(charCode & 0xF));
      }
    }
    return sb.toString();
  }

  // TODO: use corelib implementation.
  static String replaceAll(String s, String pattern,
                           String replacement(Match match)) {
    StringBuffer sb = new StringBuffer();

    int pos = 0;
    for (Match match in new RegExp(pattern).allMatches(s)) {
      sb.write(s.substring(pos, match.start));
      sb.write(replacement(match));
      pos = match.end;
    }
    sb.write(s.substring(pos));

    return sb.toString();
  }
}
