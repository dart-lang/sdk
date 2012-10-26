// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#source("../../../runtime/bin/base64.dart");

void main() {
  String line;
  String expected;

  line =
      "Man is distinguished, not only by his reason, but by this singular "
      "passion from other animals, which is a lust of the mind, that by a "
      "perseverance of delight in the continued and indefatigable generation "
      "of knowledge, exceeds the short vehemence of any carnal pleasure.";
  expected =
      "TWFuIGlzIGRpc3Rpbmd1aXNoZWQsIG5vdCBvbm"
      "x5IGJ5IGhpcyByZWFzb24sIGJ1dCBieSB0aGlz\r\n"
      "IHNpbmd1bGFyIHBhc3Npb24gZnJvbSBvdGhlci"
      "BhbmltYWxzLCB3aGljaCBpcyBhIGx1c3Qgb2Yg\r\n"
      "dGhlIG1pbmQsIHRoYXQgYnkgYSBwZXJzZXZlcm"
      "FuY2Ugb2YgZGVsaWdodCBpbiB0aGUgY29udGlu\r\n"
      "dWVkIGFuZCBpbmRlZmF0aWdhYmxlIGdlbmVyYX"
      "Rpb24gb2Yga25vd2xlZGdlLCBleGNlZWRzIHRo\r\n"
      "ZSBzaG9ydCB2ZWhlbWVuY2Ugb2YgYW55IGNhcm"
      "5hbCBwbGVhc3VyZS4=";
  Expect.equals(expected, _Base64._encode(line.charCodes));
  Expect.listEquals(line.charCodes, _Base64._decode(expected));

  line = "Simple string";
  expected = "U2ltcGxlIHN0cmluZw==";
  Expect.equals(expected, _Base64._encode(line.charCodes));
  Expect.listEquals(line.charCodes, _Base64._decode(expected));

  for (int i = 0; i < 256; i++) {
    List<int> x = [i];
    Expect.listEquals(x, _Base64._decode(_Base64._encode(x)));
  }

  for (int i = 0; i < 255; i++) {
    List<int> x = [i, i + 1];
    Expect.listEquals(x, _Base64._decode(_Base64._encode(x)));
  }

  for (int i = 0; i < 254; i++) {
    List<int> x = [i, i + 1, i + 2];
    Expect.listEquals(x, _Base64._decode(_Base64._encode(x)));
  }

  for (int i = 0; i < 253; i++) {
    List<int> x = [i, i + 1, i + 2, i + 3];
    Expect.listEquals(x, _Base64._decode(_Base64._encode(x)));
  }

  for (int i = 0; i < 252; i++) {
    List<int> x = [i, i + 1, i + 2, i + 3, i + 4];
    Expect.listEquals(x, _Base64._decode(_Base64._encode(x)));
  }

  for (int i = 0; i < 251; i++) {
    List<int> x = [i, i + 1, i + 2, i + 3, i + 4, i + 5];
    Expect.listEquals(x, _Base64._decode(_Base64._encode(x)));
  }

  for (int i = 0; i < 250; i++) {
    List<int> x = [i, i + 1, i + 2, i + 3, i + 4, i + 5, i + 6];
    Expect.listEquals(x, _Base64._decode(_Base64._encode(x)));
  }
}
