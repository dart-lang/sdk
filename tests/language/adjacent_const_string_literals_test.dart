// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


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
  Expect.equals("", (const Conster("" "" @"")).toString());

  Expect.equals("a", (const Conster("a" "")).toString());
  Expect.equals("a", (const Conster("a" '')).toString());
  Expect.equals("a", (const Conster("a" @'')).toString());

  Expect.equals("b", (const Conster('b' "")).toString());
  Expect.equals("b", (const Conster('b' '')).toString());
  Expect.equals("b", (const Conster('b' @'')).toString());

  Expect.equals("c", (const Conster(@'c' "")).toString());
  Expect.equals("c", (const Conster(@'c' '')).toString());
  Expect.equals("c", (const Conster(@'c' @'')).toString());

  Expect.equals("a", (const Conster("" "a")).toString());
  Expect.equals("a", (const Conster("" 'a')).toString());
  Expect.equals("a", (const Conster("" @'a')).toString());

  Expect.equals("b", (const Conster('' "b")).toString());
  Expect.equals("b", (const Conster('' 'b')).toString());
  Expect.equals("b", (const Conster('' @'b')).toString());

  Expect.equals("c", (const Conster(@'' "c")).toString());
  Expect.equals("c", (const Conster(@'' 'c')).toString());
  Expect.equals("c", (const Conster(@'' @'c')).toString());
}

const s = "a";

testInterpolation() {
  Expect.equals(@"ab", (const Conster("$s" "b")).toString());
  Expect.equals(@"ab", (const Conster('$s' "b")).toString());
  Expect.equals(@"$sb", (const Conster(@'$s' "b")).toString());

  Expect.equals(@"-a-b", (const Conster("-$s-" "b")).toString());
  Expect.equals(@"-a-b", (const Conster('-$s-' "b")).toString());
  Expect.equals(@"-$s-b", (const Conster(@'-$s-' "b")).toString());

  Expect.equals(@"ba", (const Conster('b' "$s")).toString());
  Expect.equals(@"ba", (const Conster('b' '$s')).toString());
  Expect.equals(@"b$s", (const Conster('b' @'$s')).toString());

  Expect.equals(@"b-a-", (const Conster('b' "-$s-")).toString());
  Expect.equals(@"b-a-", (const Conster('b' '-$s-')).toString());
  Expect.equals(@"b-$s-", (const Conster('b' @'-$s-')).toString());
}

testMultiline() {
  Expect.equals("abe",
                (const Conster("a"
                "b"
                "e")).toString());
  Expect.equals("a b e",
                (const Conster("a "
                "b "
                "e")).toString());
  Expect.equals("a b e",
                (const Conster("a"
                " b"
                " e")).toString());

  Expect.equals("abe", (const Conster("""
a""" "b" "e")).toString());
  Expect.equals("a b e", (const Conster("""
a""" " b" " e")).toString());

  Expect.equals("abe", (const Conster("""
a""" """
b""" """
e""")).toString());
}

