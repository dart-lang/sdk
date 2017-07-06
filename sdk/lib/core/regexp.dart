// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of "core.dart";

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
 * 
 * Note the use of a _raw string_ (a string prefixed with `r`)
 * in the example above. Use a raw string to treat each character in a string
 * as a literal character.
 */
abstract class RegExp implements Pattern {
  /**
   * Constructs a regular expression.
   *
   * Throws a [FormatException] if [source] is not valid regular
   * expression syntax.
   */
  external factory RegExp(String source,
      {bool multiLine: false, bool caseSensitive: true});

  /**
   * Searches for the first match of the regular expression
   * in the string [input]. Returns `null` if there is no match.
   */
  Match firstMatch(String input);

  /**
   * Returns an iterable of the matches of the regular expression on [input].
   *
   * If [start] is provided, only start looking for matches at `start`.
   */
  Iterable<Match> allMatches(String input, [int start = 0]);

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
