// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart_core;

/**
 * The String class represents character strings. Strings are
 * immutable. A string is represented by a list of 32-bit Unicode
 * scalar character codes accessible through the [charCodeAt] or the
 * [charCodes] method.
 */
abstract class String implements Comparable, Pattern, Sequence<String> {
  /**
   * Allocates a new String for the specified [charCodes].
   */
  external factory String.fromCharCodes(List<int> charCodes);

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
   * are replaced with [to].
   */
  String replaceAll(Pattern from, String to);

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
