// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Exercises compile-time string constants

main() {
  // Constant comparisons are independent of the quotes used.
  Expect.isTrue("abcd" === 'abcd');
  Expect.isTrue('abcd' === "abcd");
  Expect.isTrue("ab\"cd" === 'ab"cd');
  Expect.isTrue('ab\'cd' === "ab'cd");

  // String concatenation works even when quotes are different.
  Expect.isTrue("abcd" === "ab" "cd");
  Expect.isTrue("abcd" === "ab" 'cd');
  Expect.isTrue("abcd" === 'ab' 'cd');
  Expect.isTrue("abcd" === 'ab' "cd");

  // Or when there are more than 2 contatenations.
  Expect.isTrue("abcd" === "a" "b" "cd");
  Expect.isTrue("abcd" === "a" "b" "c" "d");
  Expect.isTrue('abcd' === 'a' 'b' 'c' 'd');
  Expect.isTrue("abcd" === "a" "b" 'c' "d");
  Expect.isTrue("abcd" === 'a' 'b' 'c' 'd');
  Expect.isTrue("abcd" === 'a' "b" 'c' "d");

  Expect.isTrue("a'b'cd" === "a" "'b'" 'c' "d");
  Expect.isTrue("a\"b\"cd" === "a" '"b"' 'c' "d");
  Expect.isTrue("a\"b\"cd" === "a" '"b"' 'c' "d");
  Expect.isTrue("a'b'cd" === 'a' "'b'" 'c' "d");
  Expect.isTrue('a\'b\'cd' === "a" "'b'" 'c' "d");
  Expect.isTrue('a"b"cd' === 'a' '"b"' 'c' "d");
  Expect.isTrue("a\"b\"cd" === 'a' '"b"' 'c' "d");
}
