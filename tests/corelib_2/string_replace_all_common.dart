// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import "package:expect/expect.dart";

testAll(Pattern Function(Pattern) wrap) {
  testReplaceAll(wrap);
  testReplaceAllMapped(wrap);
  testSplitMapJoin(wrap);
}

testReplaceAll(Pattern Function(Pattern) wrap) {
  Expect.equals("aXXcaXXdae", "abcabdae".replaceAll(wrap("b"), "XX"));

  // Test with the replaced string at the beginning.
  Expect.equals("XXbcXXbdXXe", "abcabdae".replaceAll(wrap("a"), "XX"));

  // Test with the replaced string at the end.
  Expect.equals("abcabdaXX", "abcabdae".replaceAll(wrap("e"), "XX"));

  // Test when there are no occurence of the string to replace.
  Expect.equals("abcabdae", "abcabdae".replaceAll(wrap("f"), "XX"));

  // Test when the string to change is the empty string.
  Expect.equals("", "".replaceAll(wrap("from"), "to"));

  // Test when the string to change is a substring of the string to
  // replace.
  Expect.equals("fro", "fro".replaceAll(wrap("from"), "to"));

  // Test when the string to change is the replaced string.
  Expect.equals("to", "from".replaceAll(wrap("from"), "to"));

  // Test when matches are adjacent
  Expect.equals("toto", "fromfrom".replaceAll(wrap("from"), "to"));

  // Test when the string to change is the replacement string.
  Expect.equals("to", "to".replaceAll(wrap("from"), "to"));

  // Test replacing by the empty string.
  Expect.equals("bcbde", "abcabdae".replaceAll(wrap("a"), ""));
  Expect.equals("AB", "AfromB".replaceAll(wrap("from"), ""));

  // Test changing the empty string.
  Expect.equals("to", "".replaceAll(wrap(""), "to"));

  // Test replacing the empty string.
  Expect.equals("toAtoBtoCto", "ABC".replaceAll(wrap(""), "to"));

  // Pattern strings containing RegExp metacharacters - these are not
  // interpreted as RegExps.
  Expect.equals(r"$$", "||".replaceAll(wrap("|"), r"$"));
  Expect.equals(r"$$$$", "||".replaceAll(wrap("|"), r"$$"));
  Expect.equals(r"x$|x", "x|.|x".replaceAll(wrap("|."), r"$"));
  Expect.equals(r"$$", "..".replaceAll(wrap("."), r"$"));
  Expect.equals(r"[$$$$]", "[..]".replaceAll(wrap("."), r"$$"));
  Expect.equals(r"[$]", "[..]".replaceAll(wrap(".."), r"$"));
  Expect.equals(r"$$", r"\\".replaceAll(wrap(r"\"), r"$"));
}

testReplaceAllMapped(Pattern Function(Pattern) wrap) {
  String mark(Match m) => "[${m[0]}]";
  Expect.equals("a[b]ca[b]dae", "abcabdae".replaceAllMapped(wrap("b"), mark));

  // Test with the replaced string at the beginning.
  Expect.equals("[a]bc[a]bd[a]e", "abcabdae".replaceAllMapped(wrap("a"), mark));

  // Test with the replaced string at the end.
  Expect.equals("abcabda[e]", "abcabdae".replaceAllMapped(wrap("e"), mark));

  // Test when there are no occurence of the string to replace.
  Expect.equals("abcabdae", "abcabdae".replaceAllMapped(wrap("f"), mark));

  // Test when the string to change is the empty string.
  Expect.equals("", "".replaceAllMapped(wrap("from"), mark));

  // Test when the string to change is a substring of the string to
  // replace.
  Expect.equals("fro", "fro".replaceAllMapped(wrap("from"), mark));

  // Test when matches are adjacent
  Expect.equals(
      "[from][from]", "fromfrom".replaceAllMapped(wrap("from"), mark));

  // Test replacing by the empty string.
  Expect.equals("bcbde", "abcabdae".replaceAllMapped(wrap("a"), (m) => ""));
  Expect.equals("AB", "AfromB".replaceAllMapped(wrap("from"), (m) => ""));

  // Test changing the empty string.
  Expect.equals("[]", "".replaceAllMapped(wrap(""), mark));

  // Test replacing the empty string.
  Expect.equals("[]A[]B[]C[]", "ABC".replaceAllMapped(wrap(""), mark));
}

testSplitMapJoin(Pattern Function(Pattern) wrap) {
  String mark(Match m) => "[${m[0]}]";
  String rest(String s) => "<${s}>";

  Expect.equals("<a>[b]<ca>[b]<dae>",
      "abcabdae".splitMapJoin(wrap("b"), onMatch: mark, onNonMatch: rest));

  // Test with the replaced string at the beginning.
  Expect.equals("<>[a]<bc>[a]<bd>[a]<e>",
      "abcabdae".splitMapJoin(wrap("a"), onMatch: mark, onNonMatch: rest));

  // Test with the replaced string at the end.
  Expect.equals("<abcabda>[e]<>",
      "abcabdae".splitMapJoin(wrap("e"), onMatch: mark, onNonMatch: rest));

  // Test when there are no occurence of the string to replace.
  Expect.equals("<abcabdae>",
      "abcabdae".splitMapJoin(wrap("f"), onMatch: mark, onNonMatch: rest));

  // Test when the string to change is the empty string.
  Expect.equals(
      "<>", "".splitMapJoin(wrap("from"), onMatch: mark, onNonMatch: rest));

  // Test when the string to change is a substring of the string to
  // replace.
  Expect.equals("<fro>",
      "fro".splitMapJoin(wrap("from"), onMatch: mark, onNonMatch: rest));

  // Test when matches are adjacent
  Expect.equals("<>[from]<>[from]<>",
      "fromfrom".splitMapJoin(wrap("from"), onMatch: mark, onNonMatch: rest));

  // Test changing the empty string.
  Expect.equals(
      "<>[]<>", "".splitMapJoin(wrap(""), onMatch: mark, onNonMatch: rest));

  // Test replacing the empty string.
  Expect.equals("<>[]<A>[]<B>[]<C>[]<>",
      "ABC".splitMapJoin(wrap(""), onMatch: mark, onNonMatch: rest));

  // Test with only onMatch.
  Expect.equals(
      "[a]bc[a]bd[a]e", "abcabdae".splitMapJoin(wrap("a"), onMatch: mark));

  // Test with only onNonMatch
  Expect.equals(
      "<>a<bc>a<bd>a<e>", "abcabdae".splitMapJoin(wrap("a"), onNonMatch: rest));
}
