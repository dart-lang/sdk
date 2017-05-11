// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of "dart:core";

/**
 * An interface for basic searches within strings.
 */
abstract class Pattern {
  // NOTE: When using "start" index from the language library, call
  // without an argument if start is zero. This allows backwards compatibility
  // with implementations of the older interface that didn't have the start
  // index argument.
  /**
   * Match this pattern against the string repeatedly.
   *
   * If [start] is provided, matching will start at that index.
   *
   * The returned iterable lazily computes all the non-overlapping matches
   * of the pattern on the string, ordered by start index.
   * If a user only requests the first
   * match, this function should not compute all possible matches.
   *
   * The matches are found by repeatedly finding the first match
   * of the pattern on the string, starting from the end of the previous
   * match, and initially starting from index zero.
   *
   * If the pattern matches the empty string at some point, the next
   * match is found by starting at the previous match's end plus one.
   */
  Iterable<Match> allMatches(String string, [int start = 0]);

  /**
   * Match this pattern against the start of `string`.
   *
   * If [start] is provided, it must be an integer in the range `0` ..
   * `string.length`. In that case, this patten is tested against the
   * string at the [start] position. That is, a [Match] is returned if the
   * pattern can match a part of the string starting from position [start].
   * Returns `null` if the pattern doesn't match.
   */
  Match matchAsPrefix(String string, [int start = 0]);
}

/**
 * A result from searching within a string.
 *
 * A Match or an [Iterable] of Match objects is returned from [Pattern]
 * matching methods.
 *
 * The following example finds all matches of a [RegExp] in a [String]
 * and iterates through the returned iterable of Match objects.
 *
 *     RegExp exp = new RegExp(r"(\w+)");
 *     String str = "Parse my string";
 *     Iterable<Match> matches = exp.allMatches(str);
 *     for (Match m in matches) {
 *       String match = m.group(0);
 *       print(match);
 *     }
 *
 * The output of the example is:
 *
 *     Parse
 *     my
 *     string
 *
 * Some patterns, regular expressions in particular, may record substrings
 * that were part of the matching. These are called _groups_ in the Match
 * object. Some patterns may never have any groups, and their matches always
 * have zero [groupCount].
 */
abstract class Match {
  /**
   * Returns the index in the string where the match starts.
   */
  int get start;

  /**
   * Returns the index in the string after the last character of the
   * match.
   */
  int get end;

  /**
   * Returns the string matched by the given [group].
   *
   * If [group] is 0, returns the match of the pattern.
   *
   * The result may be `null` if the pattern didn't assign a value to it
   * as part of this match.
   */
  String group(int group);

  /**
   * Returns the string matched by the given [group].
   *
   * If [group] is 0, returns the match of the pattern.
   *
   * Short alias for [Match.group].
   */
  String operator [](int group);

  /**
   * Returns a list of the groups with the given indices.
   *
   * The list contains the strings returned by [group] for each index in
   * [groupIndices].
   */
  List<String> groups(List<int> groupIndices);

  /**
   * Returns the number of captured groups in the match.
   *
   * Some patterns may capture parts of the input that was used to
   * compute the full match. This is the number of captured groups,
   * which is also the maximal allowed argument to the [group] method.
   */
  int get groupCount;

  /**
   * The string on which this match was computed.
   */
  String get input;

  /**
   * The pattern used to search in [input].
   */
  Pattern get pattern;
}
