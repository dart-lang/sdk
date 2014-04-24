// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.core;

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
 * Some patterns, regular expressions in particular, may record subtrings
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


/**
 * A regular expression pattern.
 *
 * Regular expressions are [Pattern]s, and can as such be used to match strings
 * or parts of strings.
 *
 * Dart regular expressions have the same syntax and semantics as
 * JavaScript regular expressions. See
 * <http://ecma-international.org/ecma-262/5.1/#sec-15.10>
 * for the specification of JavaScript regular expressions.
 *
 * [firstMatch] is the main implementation method that applies a regular
 * expression to a string and returns the first [Match]. All
 * other methods in [RegExp] can build on it.
 *
 * Use [allMatches] to look for all matches of a regular expression in
 * a string.
 *
 * The following example finds all matches of a regular expression in
 * a string.
 *
 *     RegExp exp = new RegExp(r"(\w+)");
 *     String str = "Parse my string";
 *     Iterable<Match> matches = exp.allMatches(str);
 */
abstract class RegExp implements Pattern {
  /**
   * Constructs a regular expression.
   *
   * Throws a [FormatException] if [source] is not valid regular
   * expression syntax.
   */
  external factory RegExp(String source, {bool multiLine: false,
                                          bool caseSensitive: true});

  /**
   * Searches for the first match of the regular expression
   * in the string [input]. Returns `null` if there is no match.
   */
  Match firstMatch(String input);

  /**
   * Returns an iterable of the matches of the regular expression on [input].
   */
  Iterable<Match> allMatches(String input);

  /**
   * Returns whether the regular expression has a match in the string [input].
   */
  bool hasMatch(String input);

  /**
   * Returns the first substring match of this regular expression in [input].
   */
  String stringMatch(String input);

  /**
   * The source regular expression string used to create this `RegExp`.
   */
  String get pattern;

  /**
   * Whether this regular expression matches multiple lines.
   *
   * If the regexp does match multiple lines, the "^" and "$" characters
   * match the beginning and end of lines. If not, the character match the
   * beginning and end of the input.
   */
  bool get isMultiLine;

  /**
   * Whether this regular expression is case sensitive.
   *
   * If the regular expression is not case sensitive, it will match an input
   * letter with a pattern letter even if the two letters are different case
   * versions of the same letter.
   */
  bool get isCaseSensitive;
}
