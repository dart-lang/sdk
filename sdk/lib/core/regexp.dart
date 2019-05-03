// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.core;

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
 * ```dart
 * RegExp exp = new RegExp(r"(\w+)");
 * String str = "Parse my string";
 * Iterable<Match> matches = exp.allMatches(str);
 * ```
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
   *
   * If `multiLine` is enabled, then `^` and `$` will match the beginning and
   * end of a _line_, in addition to matching beginning and end of input,
   * respectively.
   *
   * If `caseSensitive` is disabled, then case is ignored.
   *
   * Example:
   *
   * ```dart
   * var wordPattern = RegExp(r"(\w+)");
   * var bracketedNumberValue = RegExp("$key: \\[\\d+\\]");
   * ```
   *
   * Notice the use of a _raw string_ in the first example, and a regular
   * string in the second. Because of the many character classes used in
   * regular expressions, it is common to use a raw string here, unless string
   * interpolation is required.
   */
  external factory RegExp(String source,
      {bool multiLine = false, bool caseSensitive = true});

  /**
   * Returns a regular expression that matches [text].
   *
   * If [text] contains characters that are meaningful in regular expressions,
   * the resulting regular expression will match those characters literally.
   * If [text] contains no characters that have special meaning in a regular
   * expression, it is returned unmodified.
   *
   * The characters that have special meaning in regular expressions are:
   * `(`, `)`, `[`, `]`, `{`, `}`, `*`, `+`, `?`, `.`, `^`, `$`, `|` and `\`.
   */
  external static String escape(String text);

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

/**
 * A regular expression match.
 *
 * Regular expression matches are [Match]es, but also include the ability
 * to retrieve the names for any named capture groups and to retrieve
 * matches for named capture groups by name instead of their index.
 */
abstract class RegExpMatch implements Match {
  /**
   * The string matched by the group named [name].
   *
   * Returns the string matched by the capture group named [name], or
   * `null` if no string was matched by that capture group as part of
   * this match.
   *
   * The [name] must be the name of a named capture group in the regular
   * expression creating this match (that is, the name must be in
   * [groupNames]).
   */
  String namedGroup(String name);

  /**
   * The names of the captured groups in the match.
   */
  Iterable<String> get groupNames;
}
