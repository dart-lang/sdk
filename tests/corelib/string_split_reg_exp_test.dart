// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

main() {
  var list = "a b c".split(new RegExp(" "));
  Expect.equals(3, list.length);
  Expect.equals("a", list[0]);
  Expect.equals("b", list[1]);
  Expect.equals("c", list[2]);

  list = "adbdc".split(new RegExp("[dz]"));
  Expect.equals(3, list.length);
  Expect.equals("a", list[0]);
  Expect.equals("b", list[1]);
  Expect.equals("c", list[2]);

  list = "addbddc".split(new RegExp("dd"));
  Expect.equals(3, list.length);
  Expect.equals("a", list[0]);
  Expect.equals("b", list[1]);
  Expect.equals("c", list[2]);

  list = "abc".split(new RegExp(r"b$"));
  Expect.equals(1, list.length);
  Expect.equals("abc", list[0]);

  list = "abc".split(new RegExp(""));
  Expect.equals(3, list.length);
  Expect.equals("a", list[0]);
  Expect.equals("b", list[1]);
  Expect.equals("c", list[2]);

  list = "   ".split(new RegExp("[ ]"));
  Expect.equals(4, list.length);
  Expect.equals("", list[0]);
  Expect.equals("", list[1]);
  Expect.equals("", list[2]);
  Expect.equals("", list[3]);

  list = "aaa".split(new RegExp(r"a$"));
  Expect.equals(2, list.length);
  Expect.equals("aa", list[0]);
  Expect.equals("", list[1]);
}
