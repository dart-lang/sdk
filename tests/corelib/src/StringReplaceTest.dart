// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
  }
}

main() {
  StringReplaceTest.testMain();
}
