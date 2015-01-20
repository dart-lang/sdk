// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analysis_server.src.status.utilities;

/**
 * Encode the characters in the given [string] so that they are safe for
 * inclusion in HTML.
 */
String encodeHtml(String string) {
  StringBuffer buffer = new StringBuffer();
  for (int i = 0; i < string.length; i++) {
    int char = string.codeUnitAt(i);
    if ((char >= 'a'.codeUnitAt(0) && char <= 'z'.codeUnitAt(0)) ||
        (char >= 'A'.codeUnitAt(0) && char <= 'Z'.codeUnitAt(0)) ||
        (char >= '0'.codeUnitAt(0) && char <= '9'.codeUnitAt(0)) ||
        char == '_'.codeUnitAt(0) ||
        char == '#'.codeUnitAt(0) ||
        char == ','.codeUnitAt(0) ||
        char == '.'.codeUnitAt(0) ||
        char == ';'.codeUnitAt(0) ||
        char == ':'.codeUnitAt(0) ||
        char == '('.codeUnitAt(0) ||
        char == ')'.codeUnitAt(0) ||
        char == '['.codeUnitAt(0) ||
        char == ']'.codeUnitAt(0) ||
        char == '{'.codeUnitAt(0) ||
        char == '}'.codeUnitAt(0) ||
        char == ' '.codeUnitAt(0) ||
        char == '='.codeUnitAt(0) ||
        char == '+'.codeUnitAt(0) ||
        char == '-'.codeUnitAt(0) ||
        char == '*'.codeUnitAt(0) ||
        char == '%'.codeUnitAt(0)) {
      buffer.writeCharCode(char);
    } else if (char == '<'.codeUnitAt(0)) {
      buffer.write('&lt;');
    } else if (char == '>'.codeUnitAt(0)) {
      buffer.write('&gt;');
    } else if (char == '&'.codeUnitAt(0)) {
      buffer.write('&amp;');
    } else if (char == '"'.codeUnitAt(0)) {
      buffer.write('&quot;');
    } else if (char == "'".codeUnitAt(0)) {
      buffer.write('&#x27;');
    } else if (char == '/'.codeUnitAt(0)) {
      buffer.write('&#x2F;');
    } else if (char == 0x2192) {
      buffer.write('&rarr;');
    } else if (char == 0x00A0) {
      buffer.write('&nbsp;');
    } else {
      buffer.write('<b>x${char.toRadixString(16)};</b>');
    }
  }
  return buffer.toString();
}
