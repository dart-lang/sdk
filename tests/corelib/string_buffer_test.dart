// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(srdjan): Move StringBuffer to visible names.

class StringBufferTest {
  static testConstructor() {
    StringBuffer bf = new StringBuffer("");
    Expect.equals(true, bf.isEmpty());

    bf = new StringBuffer("abc");
    Expect.equals(3, bf.length);
    Expect.equals("abc", bf.toString());
  }

  static testAdd() {
    StringBuffer bf = new StringBuffer("");
    Expect.equals(true, bf.isEmpty());

    bf.add("a");
    Expect.equals(1, bf.length);
    Expect.equals("a", bf.toString());

    bf = new StringBuffer("");
    bf.add("a");
    bf.add("b");
    Expect.equals("ab", bf.toString());

    bf = new StringBuffer("abc");
    bf.add("d");
    bf.add("e");
    bf.add("f");
    bf.add("g");
    bf.add("h");
    bf.add("i");
    bf.add("j");
    bf.add("k");
    bf.add("l");
    bf.add("m");
    bf.add("n");
    bf.add("o");
    bf.add("p");
    bf.add("q");
    bf.add("r");
    bf.add("s");
    bf.add("t");
    bf.add("u");
    bf.add("v");
    bf.add("w");
    bf.add("x");
    bf.add("y");
    bf.add("z");
    bf.add("\n");
    bf.add("thequickbrownfoxjumpsoverthelazydog");
    Expect.equals("abcdefghijklmnopqrstuvwxyz\n"
                  "thequickbrownfoxjumpsoverthelazydog",
                  bf.toString());

    bf = new StringBuffer("");
    for (int i = 0; i < 100000; i++) {
      bf.add('');
      bf.add("");
    }
    Expect.equals("", bf.toString());

    Expect.equals(bf, bf.add("foo"));
  }

  static testLength() {
    StringBuffer bf = new StringBuffer("");
    Expect.equals(0, bf.length);
    bf.add("foo");
    Expect.equals(3, bf.length);
    bf.add("bar");
    Expect.equals(6, bf.length);
    bf.add("");
    Expect.equals(6, bf.length);
  }

  static testIsEmpty() {
    StringBuffer bf = new StringBuffer("");
    Expect.equals(true, bf.isEmpty());
    bf.add("foo");
    Expect.equals(false, bf.isEmpty());
  }

  static testAddAll() {
    StringBuffer bf = new StringBuffer("");
    bf.addAll(["foo", "bar", "a", "b", "c"]);
    Expect.equals("foobarabc", bf.toString());

    bf.addAll([]);
    Expect.equals("foobarabc", bf.toString());

    bf.addAll(["", "", ""]);
    Expect.equals("foobarabc", bf.toString());

    Expect.equals(bf, bf.addAll(["foo"]));
  }

  static testClear() {
    StringBuffer bf = new StringBuffer("");
    bf.add("foo");
    bf.clear();
    Expect.equals("", bf.toString());
    Expect.equals(0, bf.length);

    bf.add("bar");
    Expect.equals("bar", bf.toString());
    Expect.equals(3, bf.length);
    bf.clear();
    Expect.equals("", bf.toString());
    Expect.equals(0, bf.length);

    Expect.equals(bf, bf.clear());
  }

  static testToString() {
    StringBuffer bf = new StringBuffer("");
    Expect.equals("", bf.toString());

    bf = new StringBuffer("foo");
    Expect.equals("foo", bf.toString());

    bf = new StringBuffer("foo");
    bf.add("bar");
    Expect.equals("foobar", bf.toString());
  }

  static testChaining() {
    StringBuffer bf = new StringBuffer("");
    StringBuffer bf2 = new StringBuffer("");
    bf2.add("bf2");
    bf.add("foo")
      .add("bar")
      .add(bf2)
      .add(bf2)
      .add("toto");
    Expect.equals("foobarbf2bf2toto", bf.toString());
  }

  static testMain() {
    testToString();
    testConstructor();
    testLength();
    testIsEmpty();
    testAdd();
    testAddAll();
    testClear();
    testChaining();
  }
}

main() {
  StringBufferTest.testMain();
}
