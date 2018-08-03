// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class Conster {
  const Conster(this.value);

  final value;

  toString() {
    return value.toString();
  }
}

main() {
  testEmpty();
  testInterpolation();
  testMultiline();
}

testEmpty() {
  Expect.equals("", (const Conster("" "" "")).toString());
  Expect.equals("", (const Conster("" '' "")).toString());
  Expect.equals("", (const Conster("" "" r"")).toString());

  Expect.equals("a", (const Conster("a" "")).toString());
  Expect.equals("a", (const Conster("a" '')).toString());
  Expect.equals("a", (const Conster("a" r'')).toString());

  Expect.equals("b", (const Conster('b' "")).toString());
  Expect.equals("b", (const Conster('b' '')).toString());
  Expect.equals("b", (const Conster('b' r'')).toString());

  Expect.equals("c", (const Conster(r'c' "")).toString());
  Expect.equals("c", (const Conster(r'c' '')).toString());
  Expect.equals("c", (const Conster(r'c' r'')).toString());

  Expect.equals("a", (const Conster("" "a")).toString());
  Expect.equals("a", (const Conster("" 'a')).toString());
  Expect.equals("a", (const Conster("" r'a')).toString());

  Expect.equals("b", (const Conster('' "b")).toString());
  Expect.equals("b", (const Conster('' 'b')).toString());
  Expect.equals("b", (const Conster('' r'b')).toString());

  Expect.equals("c", (const Conster(r'' "c")).toString());
  Expect.equals("c", (const Conster(r'' 'c')).toString());
  Expect.equals("c", (const Conster(r'' r'c')).toString());
}

const s = "a";

testInterpolation() {
  Expect.equals(r"ab", (const Conster("$s" "b")).toString());
  Expect.equals(r"ab", (const Conster('$s' "b")).toString());
  Expect.equals(r"$sb", (const Conster(r'$s' "b")).toString());

  Expect.equals(r"-a-b", (const Conster("-$s-" "b")).toString());
  Expect.equals(r"-a-b", (const Conster('-$s-' "b")).toString());
  Expect.equals(r"-$s-b", (const Conster(r'-$s-' "b")).toString());

  Expect.equals(r"ba", (const Conster('b' "$s")).toString());
  Expect.equals(r"ba", (const Conster('b' '$s')).toString());
  Expect.equals(r"b$s", (const Conster('b' r'$s')).toString());

  Expect.equals(r"b-a-", (const Conster('b' "-$s-")).toString());
  Expect.equals(r"b-a-", (const Conster('b' '-$s-')).toString());
  Expect.equals(r"b-$s-", (const Conster('b' r'-$s-')).toString());
}

testMultiline() {
  Expect.equals(
      "abe",
      (const Conster("a"
              "b"
              "e"))
          .toString());
  Expect.equals(
      "a b e",
      (const Conster("a "
              "b "
              "e"))
          .toString());
  Expect.equals(
      "a b e",
      (const Conster("a"
              " b"
              " e"))
          .toString());

  Expect.equals(
      "abe",
      (const Conster("""
a"""
              "b"
              "e"))
          .toString());
  Expect.equals(
      "a b e",
      (const Conster("""
a"""
              " b"
              " e"))
          .toString());

  Expect.equals(
      "abe",
      (const Conster("""
a"""
              """
b"""
              """
e"""))
          .toString());
}
