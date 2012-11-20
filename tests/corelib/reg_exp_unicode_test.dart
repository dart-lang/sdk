// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test for testing regular expressions in Dart.

main() {
  String str = "\u{10000}";

  // Dot will match surrogates too (ideally it should match a pair).
  Expect.isTrue(new RegExp(r'^..?$').hasMatch(str));

  // Surrogate pair in a RegExp.
  Expect.isTrue(new RegExp('^\u{10000}\$').hasMatch(str));

  // Mormon characters should work too.
  String mitt = "My name is 𐐣𐐮𐐻";
  Expect.isTrue(new RegExp(r'𐐣𐐮𐐻$').hasMatch(mitt));

  // Character classes sort of work, but the surrogates are treated as separate
  // characters.
  Expect.isTrue(new RegExp(r'[𐐣𐐮𐐻]+$').hasMatch(mitt));
}
