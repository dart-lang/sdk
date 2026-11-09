// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that `String.contains` with a non-zero start index searches the
// original string from that index, so that a `Pattern` can still see the text
// before the index.
//
// Regression test for https://dartbug.com/64730.

import 'package:expect/expect.dart';

class WrappedPattern implements Pattern {
  final Pattern pattern;

  WrappedPattern(this.pattern);

  @override
  Iterable<Match> allMatches(String string, [int start = 0]) =>
      pattern.allMatches(string, start);

  @override
  Match? matchAsPrefix(String string, [int start = 0]) =>
      pattern.matchAsPrefix(string, start);
}

void main() {
  const text = 'id:42';
  const start = 3;

  // The start index limits where matching begins; it does not change where
  // the beginning of the original string is.
  Expect.isFalse(text.contains(RegExp(r'^42'), start));

  // A match starting at `start` must still be able to inspect earlier text.
  Expect.isTrue(text.contains(RegExp(r'(?<=:)42'), start));

  // Custom patterns also receive the original string and the start index.
  Expect.isFalse(text.contains(WrappedPattern(RegExp(r'^42')), start));
  Expect.isTrue(text.contains(WrappedPattern(RegExp(r'(?<=:)42')), start));

  // `String.indexOf` retains the original string and handles both cases.
  Expect.equals(-1, text.indexOf(RegExp(r'^42'), start));
  Expect.equals(start, text.indexOf(RegExp(r'(?<=:)42'), start));

  // A zero-width match at the end remains possible when searching from there.
  Expect.isTrue(text.contains(RegExp(r'$'), text.length));
  Expect.isTrue(text.contains(RegExp(r'(?:)'), text.length));
  Expect.isFalse(text.contains(RegExp(r'^'), text.length));
}
