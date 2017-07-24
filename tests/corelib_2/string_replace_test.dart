// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

main() {
  // Test replaceFirst.
  Expect.equals("AtoBtoCDtoE", "AfromBtoCDtoE".replaceFirst("from", "to"));

  // Test with the replaced string at the beginning.
  Expect.equals("toABtoCDtoE", "fromABtoCDtoE".replaceFirst("from", "to"));

  // Test with the replaced string at the end.
  Expect.equals("toABtoCDtoEto", "fromABtoCDtoEto".replaceFirst("from", "to"));

  // Test when there are no occurence of the string to replace.
  Expect.equals("ABC", "ABC".replaceFirst("from", "to"));

  // Test when the string to change is the empty string.
  Expect.equals("", "".replaceFirst("from", "to"));

  // Test when the string to change is a substring of the string to
  // replace.
  Expect.equals("fro", "fro".replaceFirst("from", "to"));

  // Test when the string to change is the replaced string.
  Expect.equals("to", "from".replaceFirst("from", "to"));

  // Test when the string to change is the replacement string.
  Expect.equals("to", "to".replaceFirst("from", "to"));

  // Test replacing by the empty string.
  Expect.equals("", "from".replaceFirst("from", ""));
  Expect.equals("AB", "AfromB".replaceFirst("from", ""));

  // Test changing the empty string.
  Expect.equals("to", "".replaceFirst("", "to"));

  // Test replacing the empty string.
  Expect.equals("toAtoBtoCto", "AtoBtoCto".replaceFirst("", "to"));

  // Test startIndex.
  Expect.equals(
      "foo-AAA-foo-bar", "foo-bar-foo-bar".replaceFirst("bar", "AAA", 4));

  // Test startIndex skipping one case at the beginning.
  Expect.equals(
      "foo-bar-AAA-bar", "foo-bar-foo-bar".replaceFirst("foo", "AAA", 1));

  // Test startIndex skipping one case at the beginning.
  Expect.equals(
      "foo-bar-foo-AAA", "foo-bar-foo-bar".replaceFirst("bar", "AAA", 5));

  // Test startIndex replacing with the empty string.
  Expect.equals("foo-bar--bar", "foo-bar-foo-bar".replaceFirst("foo", "", 1));

  // Test startIndex with a RegExp with carat
  Expect.equals("foo-bar-foo-bar",
      "foo-bar-foo-bar".replaceFirst(new RegExp(r"^foo"), "", 8));

  // Test startIndex with a RegExp
  Expect.equals(
      "aaa{3}X{3}", "aaa{3}aaa{3}".replaceFirst(new RegExp(r"a{3}"), "X", 1));

  // Test startIndex with regexp-looking String
  Expect.equals("aaa{3}aaX", "aaa{3}aaa{3}".replaceFirst("a{3}", "X", 3));

  // Test negative startIndex
  Expect.throws(
      () => "hello".replaceFirst("h", "X", -1), (e) => e is RangeError);

  // Test startIndex too large
  Expect.throws(
      () => "hello".replaceFirst("h", "X", 6), (e) => e is RangeError);

  // Test null startIndex
  Expect.throws(
      () => "hello".replaceFirst("h", "X", null), (e) => e is ArgumentError);

  // Test replaceFirstMapped.
  Expect.equals(
      "AtoBtoCDtoE", "AfromBtoCDtoE".replaceFirstMapped("from", (_) => "to"));

  // Test with the replaced string at the beginning.
  Expect.equals(
      "toABtoCDtoE", "fromABtoCDtoE".replaceFirstMapped("from", (_) => "to"));

  // Test with the replaced string at the end.
  Expect.equals("toABtoCDtoEto",
      "fromABtoCDtoEto".replaceFirstMapped("from", (_) => "to"));

  // Test when there are no occurence of the string to replace.
  Expect.equals("ABC", "ABC".replaceFirstMapped("from", (_) => "to"));

  // Test when the string to change is the empty string.
  Expect.equals("", "".replaceFirstMapped("from", (_) => "to"));

  // Test when the string to change is a substring of the string to
  // replace.
  Expect.equals("fro", "fro".replaceFirstMapped("from", (_) => "to"));

  // Test when the string to change is the replaced string.
  Expect.equals("to", "from".replaceFirstMapped("from", (_) => "to"));

  // Test when the string to change is the replacement string.
  Expect.equals("to", "to".replaceFirstMapped("from", (_) => "to"));

  // Test replacing by the empty string.
  Expect.equals("", "from".replaceFirstMapped("from", (_) => ""));
  Expect.equals("AB", "AfromB".replaceFirstMapped("from", (_) => ""));

  // Test changing the empty string.
  Expect.equals("to", "".replaceFirstMapped("", (_) => "to"));

  // Test replacing the empty string.
  Expect.equals("toAtoBtoCto", "AtoBtoCto".replaceFirstMapped("", (_) => "to"));

  // Test startIndex.
  Expect.equals("foo-AAA-foo-bar",
      "foo-bar-foo-bar".replaceFirstMapped("bar", (_) => "AAA", 4));

  // Test startIndex skipping one case at the beginning.
  Expect.equals("foo-bar-AAA-bar",
      "foo-bar-foo-bar".replaceFirstMapped("foo", (_) => "AAA", 1));

  // Test startIndex skipping one case at the beginning.
  Expect.equals("foo-bar-foo-AAA",
      "foo-bar-foo-bar".replaceFirstMapped("bar", (_) => "AAA", 5));

  // Test startIndex replacing with the empty string.
  Expect.equals("foo-bar--bar",
      "foo-bar-foo-bar".replaceFirstMapped("foo", (_) => "", 1));

  // Test startIndex with a RegExp with carat
  Expect.equals("foo-bar-foo-bar",
      "foo-bar-foo-bar".replaceFirstMapped(new RegExp(r"^foo"), (_) => "", 8));

  // Test startIndex with a RegExp
  Expect.equals("aaa{3}X{3}",
      "aaa{3}aaa{3}".replaceFirstMapped(new RegExp(r"a{3}"), (_) => "X", 1));

  // Test startIndex with regexp-looking String
  Expect.equals(
      "aaa{3}aaX", "aaa{3}aaa{3}".replaceFirstMapped("a{3}", (_) => "X", 3));

  // Test negative startIndex
  Expect.throws(() => "hello".replaceFirstMapped("h", (_) => "X", -1),
      (e) => e is RangeError);

  // Test startIndex too large
  Expect.throws(() => "hello".replaceFirstMapped("h", (_) => "X", 6),
      (e) => e is RangeError);

  // Test null startIndex
  Expect.throws(() => "hello".replaceFirstMapped("h", (_) => "X", null),
      (e) => e is ArgumentError);

  // Test replacement depending on argument.
  Expect.equals("foo-BAR-foo-bar",
      "foo-bar-foo-bar".replaceFirstMapped("bar", (v) => v[0].toUpperCase()));

  Expect.equals("foo-[bar]-foo-bar",
      "foo-bar-foo-bar".replaceFirstMapped("bar", (v) => "[${v[0]}]"));

  Expect.equals("foo-foo-bar-foo-bar-foo-bar",
      "foo-bar-foo-bar".replaceFirstMapped("bar", (v) => v.input));

  // Test replacement throwing.
  Expect.throws(() => "foo-bar".replaceFirstMapped("bar", (v) => throw 42),
      (e) => e == 42);

  // Test replacement returning non-String.
  var o = new Object();
  Expect.equals(
      "foo-$o",
      "foo-bar".replaceFirstMapped("bar", (v) {
        return o;
      }));

  for (var string in ["", "x", "foo", "x\u2000z"]) {
    for (var replacement in ["", "foo", string]) {
      for (int start = 0; start <= string.length; start++) {
        var expect;
        for (int end = start; end <= string.length; end++) {
          expect =
              string.substring(0, start) + replacement + string.substring(end);
          Expect.equals(expect, string.replaceRange(start, end, replacement),
              '"$string"[$start:$end]="$replacement"');
        }
        // Reuse expect from "end == string.length" case when omitting end.
        Expect.equals(expect, string.replaceRange(start, null, replacement),
            '"$string"[$start:]="$replacement"');
      }
    }
    Expect.throws(() => string.replaceRange(0, 0, null));
    Expect.throws(() => string.replaceRange(-1, 0, "x"));
    Expect.throws(() => string.replaceRange(0, string.length + 1, "x"));
  }
}
