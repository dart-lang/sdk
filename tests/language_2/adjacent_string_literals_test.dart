// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

main() {
  testEmpty();
  testInterpolation();
  testMultiline();
}

testEmpty() {
  Expect.equals("", "" "" "");
  Expect.equals("", "" '' "");
  Expect.equals("", "" "" r"");

  Expect.equals("a", "a" "");
  Expect.equals("a", "a" '');
  Expect.equals("a", "a" r'');

  Expect.equals("b", 'b' "");
  Expect.equals("b", 'b' '');
  Expect.equals("b", 'b' r'');

  Expect.equals("c", r'c' "");
  Expect.equals("c", r'c' '');
  Expect.equals("c", r'c' r'');

  Expect.equals("a", "" "a");
  Expect.equals("a", "" 'a');
  Expect.equals("a", "" r'a');

  Expect.equals("b", '' "b");
  Expect.equals("b", '' 'b');
  Expect.equals("b", '' r'b');

  Expect.equals("c", r'' "c");
  Expect.equals("c", r'' 'c');
  Expect.equals("c", r'' r'c');
}

testInterpolation() {
  var s = "a";
  Expect.equals(r"ab", "$s" "b");
  Expect.equals(r"ab", '$s' "b");
  Expect.equals(r"$sb", r'$s' "b");

  Expect.equals(r"-a-b", "-$s-" "b");
  Expect.equals(r"-a-b", '-$s-' "b");
  Expect.equals(r"-$s-b", r'-$s-' "b");

  Expect.equals(r"ba", 'b' "$s");
  Expect.equals(r"ba", 'b' '$s');
  Expect.equals(r"b$s", 'b' r'$s');

  Expect.equals(r"b-a-", 'b' "-$s-");
  Expect.equals(r"b-a-", 'b' '-$s-');
  Expect.equals(r"b-$s-", 'b' r'-$s-');
}

testMultiline() {
  Expect.equals(
      "abe",
      "a"
      "b"
      "e");
  Expect.equals(
      "a b e",
      "a "
      "b "
      "e");
  Expect.equals(
      "a b e",
      "a"
      " b"
      " e");

  Expect.equals(
      "abe",
      """
a"""
      "b"
      "e");
  Expect.equals(
      "a b e",
      """
a"""
      " b"
      " e");

  Expect.equals(
      "abe",
      """
a"""
      """
b"""
      """
e""");
}
