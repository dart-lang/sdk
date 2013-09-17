// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.core;

/**
 * An interface for basic searches within strings.
 */
abstract class Pattern {
  /**
   * Match this pattern against the string repeatedly.
   *
   * The iterable will contain all the non-overlapping matches of the
   * pattern on the string, ordered by start index.
   *
   * The matches are found by repeatedly finding the first match
   * of the pattern on the string, starting from the end of the previous
   * match, and initially starting from index zero.
   *
   * If the pattern matches the empty string at some point, the next
   * match is found by starting at the previous match's end plus one.
   */
  Iterable<Match> allMatches(String str);

  /**
   * Match this pattern against the start of string.
   *
   * If [start] is provided, it must be an integer in the range `0` ..
   * `string.length`. In that case, this patten is tested against the
   * string at the [start] position. That is, a match is returned if the
   * pattern can match a part of the string starting from position [start].
   */
  Match matchAsPrefix(String string, [int start = 0]);
}
