// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.core;

/**
 * The String class represents character strings. Strings are
 * immutable. A string is represented by a list of 32-bit Unicode
 * scalar character codes accessible through the [charCodeAt] or the
 * [charCodes] method.
 */
abstract class String implements Comparable, Pattern {
  /**
   * Allocates a new String for the specified [charCodes].
   */
  external factory String.fromCharCodes(List<int> charCodes);

  /**
   * Allocates a new String for the specified [charCode].
   *
   * The built string is of [length] one, if the [charCode] lies inside the
   * basic multilingual plane (plane 0). Otherwise the [length] is 2 and
   * the code units form a surrogate pair.
   */
  factory String.character(int charCode) {
    List<int> charCodes = new List<int>.fixedLength(1, fill: charCode);
    return new String.fromCharCodes(charCodes);
  }

  /**
   * Gets the character (as [String]) at the given [index].
   */
  String operator [](int index);

  /**
   * Gets the scalar character code at the given [index].
   */
  int charCodeAt(int index);

  /**
   * The length of the string.
   */
  int get length;

  /**
   * Returns whether the two strings are equal. This method compares
   * each individual scalar character codes of the strings.
   */
  bool operator ==(String other);

  /**
   * Returns whether this string ends with [other].
   */
  bool endsWith(String other);

  /**
   * Returns whether this string starts with [other].
   */
  bool startsWith(String other);

  /**
   * Returns the first location of [other] in this string starting at
   * [start] (inclusive).
   * Returns -1 if [other] could not be found.
   */
  int indexOf(String other, [int start]);

  /**
   * Returns the last location of [other] in this string, searching
   * backward starting at [start] (inclusive).
   * Returns -1 if [other] could not be found.
   */
  int lastIndexOf(String other, [int start]);

  /**
   * Returns whether this string is empty.
   */
  bool get isEmpty;

  /**
   * Creates a new string by concatenating this string with [other].
   */
  String concat(String other);

  /**
   * Returns a slice of this string from [startIndex] to [endIndex].
   *
   * If [startIndex] is omitted, it defaults to the start of the string.
   *
   * If [endIndex] is omitted, it defaults to the end of the string.
   *
   * If either index is negative, it's taken as a negative index from the
   * end of the string. Their effective value is computed by adding the
   * negative value to the [length] of the string.
   *
   * The effective indices, after  must be non-negative, no greater than the
   * length of the string, and [endIndex] must not be less than [startIndex].
   */
  String slice([int startIndex, int endIndex]);

  /**
   * Returns a substring of this string in the given range.
   * [startIndex] is inclusive and [endIndex] is exclusive.
   */
  String substring(int startIndex, [int endIndex]);

  /**
   * Removes leading and trailing whitespace from a string. If the string
   * contains leading or trailing whitespace a new string with no leading and
   * no trailing whitespace is returned. Otherwise, the string itself is
   * returned.  Whitespace is defined as every Unicode character in the Zs, Zl
   * and Zp categories (this includes no-break space), the spacing control
   * characters from 9 to 13 (tab, lf, vtab, ff and cr), and 0xfeff the BOM
   * character.
   */
  String trim();

  /**
   * Returns whether this string contains [other] starting
   * at [startIndex] (inclusive).
   */
  bool contains(Pattern other, [int startIndex]);

  /**
   * Returns a new string where the first occurence of [from] in this string
   * is replaced with [to].
   */
  String replaceFirst(Pattern from, String to);

  /**
   * Returns a new string where all occurences of [from] in this string
   * are replaced with [replace].
   */
  String replaceAll(Pattern from, var replace);

  /**
   * Returns a new string where all occurences of [from] in this string
   * are replaced with a [String] depending on [replace].
   *
   *
   * The [replace] function is called with the [Match] generated
   * by the pattern, and its result is used as replacement.
   */
  String replaceAllMapped(Pattern from, String replace(Match match));

  /**
   * Splits the string around matches of [pattern]. Returns
   * a list of substrings.
   */
  List<String> split(Pattern pattern);

  /**
   * Returns a list of the characters of this string.
   */
  List<String> splitChars();

  /**
   * Splits the string on the [pattern], then converts each part and each match.
   *
   * The pattern is used to split the string into parts and separating matches.
   *
   * Each match is converted to a string by calling [onMatch]. If [onMatch]
   * is omitted, the matched string is used.
   *
   * Each non-matched part is converted by a call to [onNonMatch]. If
   * [onNonMatch] is omitted, the non-matching part is used.
   *
   * Then all the converted parts are combined into the resulting string.
   */
  String splitMapJoin(Pattern pattern,
                      {String onMatch(Match match),
                       String onNonMatch(String nonMatch)});

  /**
   * Returns a list of the scalar character codes of this string.
   */
  List<int> get charCodes;

  /**
   * If this string is not already all lower case, returns a new string
   * where all characters  are made lower case. Returns [:this:] otherwise.
   */
  String toLowerCase();

  /**
   * If this string is not already all uper case, returns a new string
   * where all characters are made upper case. Returns [:this:] otherwise.
   */
  String toUpperCase();
}
