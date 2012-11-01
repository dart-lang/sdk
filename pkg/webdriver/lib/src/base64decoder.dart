// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of webdriver;

/**
 * A simple base64 decoder class, used to decode web browser screenshots
 * returned by WebDriver.
 */
class Base64Decoder {

  static int getVal(String s, pos) {
    int code = s.charCodeAt(pos);
    if (code >= 65 && code < (65+26)) { // 'A'..'Z'
      return code - 65;
    } else if (code >= 97 && code < (97+26)) { // 'a'..'z'
      return code - 97 + 26;
    } else if (code >= 48 && code < (48+10)) { // '0'..'9'
      return code - 48 + 52;
    } else if (code == 43) { // '+'
      return 62;
    } else if (code == 47) { // '/'
      return 63;
    } else {
      throw 'Invalid character $s';
    }
  }

  static List<int> decode(String s) {
    var rtn = new List<int>();
    var pos = 0;
    while (pos < s.length) {
      if (s[pos+2] =='=') { // Single byte as two chars.
        int v = (getVal(s, pos) << 18 ) | (getVal(s, pos+1) << 12 );
        rtn.add((v >> 16) & 0xff);
        break;
      } else if (s[pos+3] == '=') { // Two bytes as 3 chars.
        int v = (getVal(s, pos) << 18 ) | (getVal(s, pos+1) << 12 ) |
            (getVal(s, pos + 2) << 6);
        rtn.add((v >> 16) & 0xff);
        rtn.add((v >> 8) & 0xff);
        break;
      } else { // Three bytes as 4 chars.
        int v = (getVal(s, pos) << 18 ) | (getVal(s, pos+1) << 12 ) |
            (getVal(s, pos + 2) << 6) | getVal(s, pos+3);
        pos += 4;
        rtn.add((v >> 16 ) & 0xff);
        rtn.add((v >> 8) & 0xff);
        rtn.add(v & 0xff);
      }
    }
    return rtn;
  }
}
