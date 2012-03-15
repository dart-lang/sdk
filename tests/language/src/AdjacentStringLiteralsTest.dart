// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

main() {
  testEmpty();
  testInterpolation();
  testMultiline();
}

testEmpty() {
  Expect.equals("", "" "" "");
  Expect.equals("", "" '' "");
  Expect.equals("", "" "" @"");
  
  Expect.equals("a", "a" "");
  Expect.equals("a", "a" '');
  Expect.equals("a", "a" @'');

  Expect.equals("b", 'b' "");
  Expect.equals("b", 'b' '');
  Expect.equals("b", 'b' @'');
  
  Expect.equals("c", @'c' "");
  Expect.equals("c", @'c' '');
  Expect.equals("c", @'c' @'');

  Expect.equals("a", "" "a");
  Expect.equals("a", "" 'a');
  Expect.equals("a", "" @'a');

  Expect.equals("b", '' "b");
  Expect.equals("b", '' 'b');
  Expect.equals("b", '' @'b');
  
  Expect.equals("c", @'' "c");
  Expect.equals("c", @'' 'c');
  Expect.equals("c", @'' @'c');
}

testInterpolation() {
  var s = "a";
  Expect.equals(@"ab", "$s" "b");
  Expect.equals(@"ab", '$s' "b");
  Expect.equals(@"$sb", @'$s' "b");

  Expect.equals(@"-a-b", "-$s-" "b");
  Expect.equals(@"-a-b", '-$s-' "b");
  Expect.equals(@"-$s-b", @'-$s-' "b");
  
  Expect.equals(@"ba", 'b' "$s");
  Expect.equals(@"ba", 'b' '$s');
  Expect.equals(@"b$s", 'b' @'$s');

  Expect.equals(@"b-a-", 'b' "-$s-");
  Expect.equals(@"b-a-", 'b' '-$s-');
  Expect.equals(@"b-$s-", 'b' @'-$s-');
}

testMultiline() {
  Expect.equals("abe",
                "a"
                "b"
                "e");
  Expect.equals("a b e",
                "a "
                "b "
                "e");
  Expect.equals("a b e",
                "a"
                " b"
                " e");

  Expect.equals("abe", """
a""" "b" "e");
  Expect.equals("a b e", """
a""" " b" " e");

  Expect.equals("abe", """
a""" """
b""" """
e""");
}

