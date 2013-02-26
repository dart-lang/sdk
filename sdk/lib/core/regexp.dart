// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.core;

/**
 * [Match] contains methods to manipulate a regular expression match.
 *
 * Iterables of [Match] objects are returned from [RegExp] matching methods.
 *
 * The following example finds all matches of a [RegExp] in a [String]
 * and iterates through the returned iterable of [Match] objects.
 *
 *     RegExp exp = new RegExp(r"(\w+)");
 *     String str = "Parse my string";
 *     Iterable<Match> matches = exp.allMatches(str);
 *     for (Match m in matches) {
 *       String match = m.group(0);
 *       print(match);
 *     };
 *
 * The output of the example is:
 *
 *     Parse
 *     my
 *     string
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
   * Returns the string matched by the given [group]. If [group] is 0,
   * returns the match of the regular expression.
   */
  String group(int group);
  String operator [](int group);

  /**
   * Returns the strings matched by [groups]. The order in the
   * returned string follows the order in [groups].
   */
  List<String> groups(List<int> groups);

  /**
   * Returns the number of groups in the regular expression.
   */
  int get groupCount;

  /**
   * The string on which this matcher was computed.
   */
  String get str;

  /**
   * The pattern used to search in [str].
   */
  Pattern get pattern;
}


/**
 * [RegExp] represents regular expressions.
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
   * Constructs a regular expression. The default implementation of a
   * [RegExp] sets [multiLine] to false and [caseSensitive] to true.
   * Throws a [FormatException] if [pattern] is not a valid regular
   * exression pattern.
   */
  external factory RegExp(String pattern, {bool multiLine: false,
                                           bool caseSensitive: true});

  /**
   * Searches for the first match of the regular expression
   * in the string [str]. Returns `null` if there is no match.
   */
  Match firstMatch(String str);

  /**
   * Returns an iterable on the  matches of the regular
   * expression in [str].
   */
  Iterable<Match> allMatches(String str);

  /**
   * Returns whether the regular expression has a match in the string [str].
   */
  bool hasMatch(String str);

  /**
   * Searches for the first match of the regular expression
   * in the string [str] and returns the matched string.
   */
  String stringMatch(String str);

  /**
   * The pattern of this regular expression.
   */
  String get pattern;

  /**
   * Whether this regular expression matches multiple lines.
   */
  bool get isMultiLine;

  /**
   * Whether this regular expression is case insensitive.
   */
  bool get isCaseSensitive;
}
