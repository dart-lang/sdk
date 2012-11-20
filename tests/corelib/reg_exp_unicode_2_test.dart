// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test for testing regular expressions in Dart.

// These tests currently fail due to bug 6592.
main() {
  String str = "\u{10000}";

  // Dot should match a surrogate pair.
  Expect.isTrue(new RegExp(r'^.$').hasMatch(str));

  // Non-BMP characters in character classes should be treated as one character,
  // not two separate surrogates.
  String alias = "\u{10402}";  // 0xd801 0xdc02.
  String char_class = "\u{10401}\u{10802}";  // 0xd801 0xdc01 0xd802 0xdc02.
  Expect.isFalse(new RegExp('^[$char_class]+\$').hasMatch(alias));
}
