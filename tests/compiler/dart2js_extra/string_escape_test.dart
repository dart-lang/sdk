// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Test that string escapes work correctly.

testSingleCharacterEscapes() {
  List/*<String>*/ examples = [
    "\b\f\n\r\t\v",
    '\b\f\n\r\t\v',
    """\b\f\n\r\t\v""",
    '''\b\f\n\r\t\v''',
  ];
  List values = [8, 12, 10, 13, 9, 11];
  for (String s in examples) {
    Expect.equals(6, s.length);
    for (int i = 0; i < 6; i++) {
      Expect.equals(values[i], s.codeUnitAt(i));
    }
  }

  // An escaped quote isn't part of a multiline end quote.
  Expect.equals(r'"', """\"""");
  Expect.equals(r"'", '''\'''');
  Expect.equals(r'" "', """" \"""");
  Expect.equals(r"' '", '''' \'''');
  Expect.equals(r'"" ', """"" """);
  Expect.equals(r"'' ", ''''' ''');
}

testXEscapes() {
  var allBytes =
      "\x00\x01\x02\x03\x04\x05\x06\x07\x08\x09\x0a\x0b\x0c\x0d\x0e\x0f"
      "\x10\x11\x12\x13\x14\x15\x16\x17\x18\x19\x1a\x1b\x1c\x1d\x1e\x1f"
      "\x20\x21\x22\x23\x24\x25\x26\x27\x28\x29\x2a\x2b\x2c\x2d\x2e\x2f"
      "\x30\x31\x32\x33\x34\x35\x36\x37\x38\x39\x3a\x3b\x3c\x3d\x3e\x3f"
      "\x40\x41\x42\x43\x44\x45\x46\x47\x48\x49\x4a\x4b\x4c\x4d\x4e\x4f"
      "\x50\x51\x52\x53\x54\x55\x56\x57\x58\x59\x5a\x5b\x5c\x5d\x5e\x5f"
      "\x60\x61\x62\x63\x64\x65\x66\x67\x68\x69\x6a\x6b\x6c\x6d\x6e\x6f"
      "\x70\x71\x72\x73\x74\x75\x76\x77\x78\x79\x7a\x7b\x7c\x7d\x7e\x7f"
      "\x80\x81\x82\x83\x84\x85\x86\x87\x88\x89\x8a\x8b\x8c\x8d\x8e\x8f"
      "\x90\x91\x92\x93\x94\x95\x96\x97\x98\x99\x9a\x9b\x9c\x9d\x9e\x9f"
      "\xa0\xa1\xa2\xa3\xa4\xa5\xa6\xa7\xa8\xa9\xaa\xab\xac\xad\xae\xaf"
      "\xb0\xb1\xb2\xb3\xb4\xb5\xb6\xb7\xb8\xb9\xba\xbb\xbc\xbd\xbe\xbf"
      "\xc0\xc1\xc2\xc3\xc4\xc5\xc6\xc7\xc8\xc9\xca\xcb\xcc\xcd\xce\xcf"
      "\xd0\xd1\xd2\xd3\xd4\xd5\xd6\xd7\xd8\xd9\xda\xdb\xdc\xdd\xde\xdf"
      "\xe0\xe1\xe2\xe3\xe4\xe5\xe6\xe7\xe8\xe9\xea\xeb\xec\xed\xee\xef"
      "\xf0\xf1\xf2\xf3\xf4\xf5\xf6\xf7\xf8\xf9\xfa\xfb\xfc\xfd\xfe\xff";
  Expect.equals(256, allBytes.length);
  for (int i = 0; i < 256; i++) {
    Expect.equals(i, allBytes.codeUnitAt(i));
  }
}

testUEscapes() {
  List /*String*/ examples = [
    "\u0000\u0001\u0022\u0027\u005c\u007f\u0080\u00ff"
        "\u0100\u1000\ud7ff\ue000\uffff",
    '\u0000\u0001\u0022\u0027\u005c\u007f\u0080\u00ff'
        '\u0100\u1000\ud7ff\ue000\uffff',
    """\u0000\u0001\u0022\u0027\u005c\u007f\u0080\u00ff"""
        """\u0100\u1000\ud7ff\ue000\uffff""",
    '''\u0000\u0001\u0022\u0027\u005c\u007f\u0080\u00ff'''
        '''\u0100\u1000\ud7ff\ue000\uffff'''
  ];
  List/*<int>*/ values = [
    0,
    1,
    0x22,
    0x27,
    0x5c,
    0x7f,
    0x80,
    0xff,
    0x100,
    0x1000,
    0xd7ff,
    0xe000,
    0xffff
  ];
  for (String s in examples) {
    Expect.equals(values.length, s.length);
    for (int i = 0; i < values.length; i++) {
      Expect.equals(values[i], s.codeUnitAt(i));
    }
  }
  // No characters above 0xffff until Leg supports that.
  var long = "\u{0}\u{00}\u{000}\u{0000}\u{00000}\u{000000}"
      "\u{1}\u{01}\u{001}\u{00001}"
      "\u{ffff}\u{0ffff}\u{00ffff}";
  var longValues = [0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 0xffff, 0xffff, 0xffff];
  Expect.equals(longValues.length, long.length);
  for (int i = 0; i < longValues.length; i++) {
    Expect.equals(longValues[i], long.codeUnitAt(i));
  }
}

testIdentityEscapes() {
  // All non-control ASCII characters escaped, except those with special
  // meaning: b, f, n, r, t, u, v, and x (replaced by \x00).
  var asciiLiterals =
      "\ \!\"\#\$\%\&\'\(\)\*\+\,\-\.\/\0\1\2\3\4\5\6\7\8\9\:\;\<\=\>"
      "\?\@\A\B\C\D\E\F\G\H\I\J\K\L\M\N\O\P\Q\R\S\T\U\V\W\X\Y\Z\[\\\]"
      "\^\_\`\a\x00\c\d\e\x00\g\h\i\j\k\l\m\x00\o\p\q\x00\s\x00\x00\x00"
      "\w\x00\y\z\{\|\}\~\";

  Expect.equals(128 - 32, asciiLiterals.length);
  for (int i = 32; i < 128; i++) {
    int code = asciiLiterals.codeUnitAt(i - 32);
    if (code != 0) {
      Expect.equals(i, code);
    }
  }
}

testQuotes() {
  // The string [ "' ].
  String bothQuotes = ' "' "' ";
  Expect.equals(bothQuotes, " \"' ");
  Expect.equals(bothQuotes, ' "\' ');
  Expect.equals(bothQuotes, """ "' """);
  Expect.equals(bothQuotes, ''' "' ''');
  Expect.equals(bothQuotes, r""" "' """);
  Expect.equals(bothQuotes, r''' "' ''');
}

testRawStrings() {
  String raw1 = r'\x00';
  Expect.equals(4, raw1.length);
  Expect.equals(0x5c, raw1.codeUnitAt(0));
}

main() {
  // Test \x??.
  testXEscapes();
  // Test \u???? and \u{?+}.
  testUEscapes();
  // Test \b, \f, \n, \r, \t, \v.
  testSingleCharacterEscapes();
  // Test all other single character (identity) escaeps.
  testIdentityEscapes();
  // Test that quotes are handled correctly.
  testQuotes();
  // Test that raw strings are raw.
  testRawStrings();
}
