// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class StringReplaceTest {
  static testMain() {
    Expect.equals(
        "AtoBtoCDtoE", "AfromBtoCDtoE".replaceFirst("from", "to"));

    // Test with the replaced string at the begining.
    Expect.equals(
        "toABtoCDtoE", "fromABtoCDtoE".replaceFirst("from", "to"));

    // Test with the replaced string at the end.
    Expect.equals(
        "toABtoCDtoEto", "fromABtoCDtoEto".replaceFirst("from", "to"));

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

    // Test startIndex skipping one case at the begining.
    Expect.equals(
        "foo-bar-AAA-bar", "foo-bar-foo-bar".replaceFirst("foo", "AAA", 1));

    // Test startIndex skipping one case at the begining.
    Expect.equals(
        "foo-bar-foo-AAA", "foo-bar-foo-bar".replaceFirst("bar", "AAA", 5));

    // Test startIndex replacing with the empty string.
    Expect.equals(
        "foo-bar--bar", "foo-bar-foo-bar".replaceFirst("foo", "", 1));

    // Test startIndex with a RegExp with carat
    Expect.equals(
        "foo-bar-foo-bar",
        "foo-bar-foo-bar".replaceFirst(new RegExp(r"^foo"), "", 8));

    // Test startIndex with a RegExp
    Expect.equals(
        "aaa{3}X{3}", "aaa{3}aaa{3}".replaceFirst(new RegExp(r"a{3}"), "X", 1));

    // Test startIndex with regexp-looking String
    Expect.equals(
        "aaa{3}aaX", "aaa{3}aaa{3}".replaceFirst("a{3}", "X", 3));

    // Test negative startIndex
    Expect.throws(
        () => "hello".replaceFirst("h", "X", -1), (e) => e is RangeError);

    // Test startIndex too large
    Expect.throws(
        () => "hello".replaceFirst("h", "X", 6), (e) => e is RangeError);

    // Test null startIndex
    Expect.throws(
        () => "hello".replaceFirst("h", "X", null), (e) => e is ArgumentError);

    // Test object startIndex
    Expect.throws(
        () => "hello".replaceFirst("h", "X", new Object()));
  }
}

main() {
  StringReplaceTest.testMain();
}
