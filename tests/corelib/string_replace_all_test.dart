// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

testReplaceAll() {
  Expect.equals("aXXcaXXdae", "abcabdae".replaceAll("b", "XX"));

  // Test with the replaced string at the beginning.
  Expect.equals("XXbcXXbdXXe", "abcabdae".replaceAll("a", "XX"));

  // Test with the replaced string at the end.
  Expect.equals("abcabdaXX", "abcabdae".replaceAll("e", "XX"));

  // Test when there are no occurence of the string to replace.
  Expect.equals("abcabdae", "abcabdae".replaceAll("f", "XX"));

  // Test when the string to change is the empty string.
  Expect.equals("", "".replaceAll("from", "to"));

  // Test when the string to change is a substring of the string to
  // replace.
  Expect.equals("fro", "fro".replaceAll("from", "to"));

  // Test when the string to change is the replaced string.
  Expect.equals("to", "from".replaceAll("from", "to"));

  // Test when matches are adjacent
  Expect.equals("toto", "fromfrom".replaceAll("from", "to"));

  // Test when the string to change is the replacement string.
  Expect.equals("to", "to".replaceAll("from", "to"));

  // Test replacing by the empty string.
  Expect.equals("bcbde", "abcabdae".replaceAll("a", ""));
  Expect.equals("AB", "AfromB".replaceAll("from", ""));

  // Test changing the empty string.
  Expect.equals("to", "".replaceAll("", "to"));

  // Test replacing the empty string.
  Expect.equals("toAtoBtoCto", "ABC".replaceAll("", "to"));

  // Pattern strings containing RegExp metacharacters - these are not
  // interpreted as RegExps.
  Expect.equals(r"$$", "||".replaceAll("|", r"$"));
  Expect.equals(r"$$$$", "||".replaceAll("|", r"$$"));
  Expect.equals(r"x$|x", "x|.|x".replaceAll("|.", r"$"));
  Expect.equals(r"$$", "..".replaceAll(".", r"$"));
  Expect.equals(r"[$$$$]", "[..]".replaceAll(".", r"$$"));
  Expect.equals(r"[$]", "[..]".replaceAll("..", r"$"));
  Expect.equals(r"$$", r"\\".replaceAll(r"\", r"$"));
}

testReplaceAllMapped() {
  String mark(Match m) => "[${m[0]}]";
  Expect.equals("a[b]ca[b]dae", "abcabdae".replaceAllMapped("b", mark));

  // Test with the replaced string at the beginning.
  Expect.equals("[a]bc[a]bd[a]e", "abcabdae".replaceAllMapped("a", mark));

  // Test with the replaced string at the end.
  Expect.equals("abcabda[e]", "abcabdae".replaceAllMapped("e", mark));

  // Test when there are no occurence of the string to replace.
  Expect.equals("abcabdae", "abcabdae".replaceAllMapped("f", mark));

  // Test when the string to change is the empty string.
  Expect.equals("", "".replaceAllMapped("from", mark));

  // Test when the string to change is a substring of the string to
  // replace.
  Expect.equals("fro", "fro".replaceAllMapped("from", mark));

  // Test when matches are adjacent
  Expect.equals("[from][from]", "fromfrom".replaceAllMapped("from", mark));

  // Test replacing by the empty string.
  Expect.equals("bcbde", "abcabdae".replaceAllMapped("a", (m) => ""));
  Expect.equals("AB", "AfromB".replaceAllMapped("from", (m) => ""));

  // Test changing the empty string.
  Expect.equals("[]", "".replaceAllMapped("", mark));

  // Test replacing the empty string.
  Expect.equals("[]A[]B[]C[]", "ABC".replaceAllMapped("", mark));
}

testSplitMapJoin() {
  String mark(Match m) => "[${m[0]}]";
  String wrap(String s) => "<${s}>";

  Expect.equals("<a>[b]<ca>[b]<dae>",
      "abcabdae".splitMapJoin("b", onMatch: mark, onNonMatch: wrap));

  // Test with the replaced string at the beginning.
  Expect.equals("<>[a]<bc>[a]<bd>[a]<e>",
      "abcabdae".splitMapJoin("a", onMatch: mark, onNonMatch: wrap));

  // Test with the replaced string at the end.
  Expect.equals("<abcabda>[e]<>",
      "abcabdae".splitMapJoin("e", onMatch: mark, onNonMatch: wrap));

  // Test when there are no occurence of the string to replace.
  Expect.equals("<abcabdae>",
      "abcabdae".splitMapJoin("f", onMatch: mark, onNonMatch: wrap));

  // Test when the string to change is the empty string.
  Expect.equals("<>", "".splitMapJoin("from", onMatch: mark, onNonMatch: wrap));

  // Test when the string to change is a substring of the string to
  // replace.
  Expect.equals(
      "<fro>", "fro".splitMapJoin("from", onMatch: mark, onNonMatch: wrap));

  // Test when matches are adjacent
  Expect.equals("<>[from]<>[from]<>",
      "fromfrom".splitMapJoin("from", onMatch: mark, onNonMatch: wrap));

  // Test changing the empty string.
  Expect.equals("<>[]<>", "".splitMapJoin("", onMatch: mark, onNonMatch: wrap));

  // Test replacing the empty string.
  Expect.equals("<>[]<A>[]<B>[]<C>[]<>",
      "ABC".splitMapJoin("", onMatch: mark, onNonMatch: wrap));

  // Test with only onMatch.
  Expect.equals("[a]bc[a]bd[a]e", "abcabdae".splitMapJoin("a", onMatch: mark));

  // Test with only onNonMatch
  Expect.equals(
      "<>a<bc>a<bd>a<e>", "abcabdae".splitMapJoin("a", onNonMatch: wrap));
}

main() {
  testReplaceAll();
  testReplaceAllMapped();
  testSplitMapJoin();
}
