// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

// Note: This test relies on LF line endings in the source file.

import "package:expect/expect.dart";

main() {
  {
    // Generates identical compile time constants.
    var s1 = "abcdefgh";
    var s2 = "abcd" "efgh";
    var s3 = "ab" "cd" "ef" "gh";
    var s4 = "a" "b" "c" "d" "e" "f" "g" "h";
    var s5 = "a" 'b' r"c" r'd' """e""" '''f''' r"""g""" r'''h''';
    Expect.isTrue(identical(s1, s2));
    Expect.isTrue(identical(s1, s3));
    Expect.isTrue(identical(s1, s4));
    Expect.isTrue(identical(s1, s5));
  }
  {
    // Separating whitespace isn't necessary for the tokenizer.
    var s1 = "abcdefgh";
    var s2 = "abcd" "efgh";
    var s3 = "ab" "cd" "ef" "gh";
    var s4 = "a" "b" "c" "d" "e" "f" "g" "h";
    var s5 = "a" 'b' r"c" r'd' """e""" '''f''' r"""g""" r'''h''';
    Expect.isTrue(identical(s1, s2));
    Expect.isTrue(identical(s1, s3));
    Expect.isTrue(identical(s1, s4));
    Expect.isTrue(identical(s1, s5));
    // "a""""""b""" should be tokenized as "a" """""b""", aka. "a" '""b'.
    Expect.isTrue(identical('a""b', "a" """""b"""));
    // """a""""""""b""" is 'a' '""b'.
    Expect.isTrue(identical('a""b', """a""" """""b"""));
    // Raw strings.
    Expect.isTrue(identical('ab', "a" r"b"));
    Expect.isTrue(identical('ab', r"a" "b"));
    Expect.isTrue(identical('ab', r"a" r"b"));
  }

  // Newlines are just whitespace.
  var ms1 = "abc"
      "def"
      "ghi"
      "jkl";
  Expect.isTrue(identical("abcdefghijkl", ms1));

  // Works with multiline strings too.
  var ms2 = """abc
  def"""
      """
  ghi
  jkl
  """;
  Expect.isTrue(
      identical("abc\n  def  ghi\n  jkl\n  ", ms2), "Multiline: $ms2");

  // Binds stronger than property access (it's considered one literal).
  Expect.equals(5, "ab" "cde".length, "Associativity");

  // Check that interpolations are handled correctly.
  {
    var x = "foo";
    var y = 42;
    var z = true;
    String e1 = "$x$y$z";
    Expect.equals(e1, "$x" "$y$z");
    Expect.equals(e1, "$x$y" "$z");
    Expect.equals(e1, "$x" "$y" "$z");
    String e2 = "-$x-$y-$z-";
    Expect.equals(e2, "-" "$x" "-" "$y" "-" "$z" "-", "a");
    Expect.equals(e2, "-$x" "-" "$y" "-" "$z" "-", "b");
    Expect.equals(e2, "-" "$x-" "$y" "-" "$z" "-", "c");
    Expect.equals(e2, "-" "$x" "-$y" "-" "$z" "-", "d");
    Expect.equals(e2, "-" "$x" "-" "$y-" "$z" "-", "e");
    Expect.equals(e2, "-" "$x" "-" "$y" "-$z" "-", "f");
    Expect.equals(e2, "-" "$x" "-" "$y" "-" "$z-", "g");
    Expect.equals(e2, "-" "$x-$y" "-" "$z" "-", "h");
    Expect.equals(e2, "-" "$x-$y-$z" "-", "i");

    Expect.equals("-$x-$y-", "-" "$x" "-" "$y" "-");
    Expect.equals("-$x-$y", "-" "$x" "-" "$y");
    Expect.equals("-$x$y-", "-" "$x" "$y" "-");
    Expect.equals("$x-$y-", "$x" "-" "$y" "-");

    Expect.equals("$x$y", "$x" "$y");
    Expect.equals("$x$y", "$x" "" "$y");
    Expect.equals("$x$y", "$x" "" "" "$y");
    Expect.equals("$x-$y", "$x" "-" "$y");
    Expect.equals("$x-$y", "$x" "-" "" "$y");
    Expect.equals("$x-$y", "$x" "" "-" "$y");
    Expect.equals("$x-$y", "$x" "" "-" "" "$y");

    Expect.equals("$x--$y", "$x" "-" "-" "$y");
    Expect.equals("$x--$y", "$x" "-" "-" "" "$y");
    Expect.equals("$x--$y", "$x" "-" "" "-" "$y");
    Expect.equals("$x--$y", "$x" "" "-" "-" "$y");

    Expect.equals("$x---$y", "$x" "-" "-" "-" "$y");
    Expect.equals("$x---", "$x" "-" "-" "-");
    Expect.equals("---$y", "-" "-" "-" "$y");

    Expect.equals("$x-$y-$z", "${'$x' '-' '$y'}" "-" "$z");

    Expect.equals(
        r"-foo-42-true-", r"-" "$x" r"""-""" """$y""" r'-' '$z' r'''-''', "j");
    Expect.equals(
        r"-$x-42-true-", r"-" r"$x" r"""-""" """$y""" r'-' '$z' r'''-''', "k");
    Expect.equals(
        r"-foo-$y-true-", r"-" "$x" r"""-""" r"""$y""" r'-' '$z' r'''-''', "l");
    Expect.equals(
        r"-foo-42-$z-", r"-" "$x" r"""-""" """$y""" r'-' r'$z' r'''-''', "m");
  }
}
