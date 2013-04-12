// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// TODO(srdjan): Move StringBuffer to visible names.

void testConstructor() {
  StringBuffer bf = new StringBuffer("");
  Expect.equals(true, bf.isEmpty);

  bf = new StringBuffer("abc");
  Expect.equals(3, bf.length);
  Expect.equals("abc", bf.toString());

  bf = new StringBuffer("\x00");
}

void testWrite() {
  StringBuffer bf = new StringBuffer("");
  Expect.equals(true, bf.isEmpty);

  bf.write("a");
  Expect.equals(1, bf.length);
  Expect.equals("a", bf.toString());

  bf = new StringBuffer("");
  bf.write("a");
  bf.write("b");
  Expect.equals("ab", bf.toString());

  bf = new StringBuffer("abc");
  bf.write("d");
  bf.write("e");
  bf.write("f");
  bf.write("g");
  bf.write("h");
  bf.write("i");
  bf.write("j");
  bf.write("k");
  bf.write("l");
  bf.write("m");
  bf.write("n");
  bf.write("o");
  bf.write("p");
  bf.write("q");
  bf.write("r");
  bf.write("s");
  bf.write("t");
  bf.write("u");
  bf.write("v");
  bf.write("w");
  bf.write("x");
  bf.write("y");
  bf.write("z");
  bf.write("\n");
  bf.write("thequickbrownfoxjumpsoverthelazydog");
  Expect.equals("abcdefghijklmnopqrstuvwxyz\n"
                "thequickbrownfoxjumpsoverthelazydog",
                bf.toString());

  bf = new StringBuffer("");
  for (int i = 0; i < 100000; i++) {
    bf.write('');
    bf.write("");
  }
  Expect.equals("", bf.toString());
}

void testLength() {
  StringBuffer bf = new StringBuffer("");
  Expect.equals(0, bf.length);
  bf.write("foo");
  Expect.equals(3, bf.length);
  bf.write("bar");
  Expect.equals(6, bf.length);
  bf.write("");
  Expect.equals(6, bf.length);
}

void testIsEmpty() {
  StringBuffer bf = new StringBuffer("");
  Expect.equals(true, bf.isEmpty);
  bf.write("foo");
  Expect.equals(false, bf.isEmpty);
}

void testWriteAll() {
  StringBuffer bf = new StringBuffer("");
  bf.writeAll(["foo", "bar", "a", "b", "c"]);
  Expect.equals("foobarabc", bf.toString());

  bf.writeAll([]);
  Expect.equals("foobarabc", bf.toString());

  bf.writeAll(["", "", ""]);
  Expect.equals("foobarabc", bf.toString());
}

void testClear() {
  StringBuffer bf = new StringBuffer("");
  bf.write("foo");
  bf.clear();
  Expect.equals("", bf.toString());
  Expect.equals(0, bf.length);

  bf.write("bar");
  Expect.equals("bar", bf.toString());
  Expect.equals(3, bf.length);
  bf.clear();
  Expect.equals("", bf.toString());
  Expect.equals(0, bf.length);
}

void testToString() {
  StringBuffer bf = new StringBuffer("");
  Expect.equals("", bf.toString());

  bf = new StringBuffer("foo");
  Expect.equals("foo", bf.toString());

  bf = new StringBuffer("foo");
  bf.write("bar");
  Expect.equals("foobar", bf.toString());
}

void testChaining() {
  StringBuffer bf = new StringBuffer("");
  StringBuffer bf2 = new StringBuffer("");
  bf2.write("bf2");
  bf..write("foo")
    ..write("bar")
    ..write(bf2)
    ..write(bf2)
    ..write("toto");
  Expect.equals("foobarbf2bf2toto", bf.toString());
}

void testWriteCharCode() {
  StringBuffer bf1 = new StringBuffer();
  StringBuffer bf2 = new StringBuffer();
  bf1.write("a");
  bf2.writeCharCode(0x61);  // a
  bf1.write("b");
  bf2.writeCharCode(0x62);  // b
  bf1.write("c");
  bf2.writeCharCode(0x63);  // c
  bf1.write(new String.fromCharCode(0xD823));
  bf2.writeCharCode(0xD823);
  bf1.write(new String.fromCharCode(0xDC23));
  bf2.writeCharCode(0xDC23);
  bf1.write("\u{1d49e}");
  bf2.writeCharCode(0x1d49e);
  bf1.write("\x00");
  bf2.writeCharCode(0);
  Expect.equals(bf1.toString(), bf2.toString());
  Expect.equals("abc\u{18c23}\u{1d49e}\x00", bf2.toString());

  // Mixing strings and char-codes.
  bf1.clear();
  bf1.write("abcde");
  bf1.writeCharCode(0x61);
  bf1.writeCharCode(0x62);
  bf1.writeCharCode(0x63);
  bf1.write("d");
  bf1.writeCharCode(0x65);
  Expect.equals("abcdeabcde", bf1.toString());

  // Out-of-range character codes are not allowed.
  Expect.throws(() { bf2.writeCharCode(-1); });
  Expect.throws(() { bf2.writeCharCode(0x110000); });
}

void main() {
  testToString();
  testConstructor();
  testLength();
  testIsEmpty();
  testWrite();
  testWriteCharCode();
  testWriteAll();
  testClear();
  testChaining();
}
