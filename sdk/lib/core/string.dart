// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.core;

/**
 * The String class represents sequences of characters. Strings are
 * immutable. A string is represented by a sequence of Unicode UTF-16
 * code units accessible through the [codeUnitAt] or the
 * [codeUnits] members. Their string representation is accessible through
 * the index-operator.
 *
 * The characters of a string are encoded in UTF-16. Decoding UTF-16, which
 * combines surrogate pairs, yields Unicode code points. Following a similar
 * terminology to Go we use the name "rune" for an integer representing a
 * Unicode code point. The runes of a string are accessible through the [runes]
 * getter.
 */
abstract class String implements Comparable, Pattern {
  /**
   * Allocates a new String for the specified [charCodes].
   *
   * The [charCodes] can be UTF-16 code units or runes. If a char-code value is
   * 16-bit it is copied verbatim. If it is greater than 16 bits it is
   * decomposed into a surrogate pair.
   */
  external factory String.fromCharCodes(Iterable<int> charCodes);

  /**
   * *Deprecated*. Use [String.fromCharCode] instead.
   */
  factory String.character(int charCode) => new String.fromCharCode(charCode);

  /**
   * Allocates a new String for the specified [charCode].
   *
   * The new string contains a single code unit if the [charCode] can be
   * represented by a single UTF-16 code unit. Otherwise the [length] is 2 and
   * the code units form a surrogate pair.
   *
   * It is allowed (though generally discouraged) to create a String with only
   * one half of a surrogate pair.
   */
  factory String.fromCharCode(int charCode) {
    List<int> charCodes = new List<int>.fixedLength(1, fill: charCode);
    return new String.fromCharCodes(charCodes);
  }

  /**
   * Gets the character (as [String]) at the given [index].
   *
   * The returned string represents exactly one UTF-16 code unit which may be
   * half of a surrogate pair. For example the Unicode character for a
   * musical G-clef ("𝄞") with rune value 0x1D11E consists of a UTF-16 surrogate
   * pair: `"\uDBFF\uDFFD"`. Using the index-operator on this string yields
   * a String with half of a surrogate pair:
   *
   *     var clef = "\uDBFF\uDFFD";
   *     clef.length;  // => 2
   *     clef.runes.first == 0x1D11E;  // => true
   *     clef.runes.length;  // => 1
   *     // The following strings are halves of a UTF-16 surrogate pair and
   *     // thus invalid UTF-16 strings:
   *     clef[0];  // => "\uDBFF"
   *     clef[1];  // => "\uDFFD"
   *
   * This method is equivalent to
   * `new String.fromCharCode(this.codeUnitAt(index))`.
   */
  String operator [](int index);

  /**
   * Gets the scalar character code at the given [index].
   *
   * *This method is deprecated. Please use [codeUnitAt] instead.*
   */
  int charCodeAt(int index);

  /**
   * Returns the 16-bit UTF-16 code unit at the given [index].
   */
  int codeUnitAt(int index);

  /**
   * The length of the string.
   *
   * Returns the number of UTF-16 code units in this string. The number
   * of [runes] might be less, if the string contains characters outside
   * the basic multilingual plane (plane 0).
   */
  int get length;

  /**
   * Returns whether the two strings are equal.
   *
   * This method compares each individual code unit of the strings. It does not
   * check for Unicode equivalence. For example the two following strings both
   * represent the string "Amélie" but, due to their different encoding will
   * not return equal.
   *
   *     "Am\xe9lie"
   *     "Ame\u{301}lie"
   *
   * In the first string the "é" is encoded as a single unicode code unit,
   * whereas the second string encodes it as "e" with the combining
   * accent character "◌́".
   */
  bool operator ==(var other);

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
   *
   * A sequence of strings can be concatenated by using [Iterable.join]:
   *
   *     var strings = ['foo', 'bar', 'geez'];
   *     var concatenated = strings.join();
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
   *
   * Splitting with an empty string pattern (`""`) splits at UTF-16 code unit
   * boundaries and not at rune boundaries. The following two expressions
   * are hence equivalent:
   *
   *     string.split("")
   *     string.codeUnits.map((unit) => new String.character(unit))
   *
   * Unless it guaranteed that the string is in the basic multilingual plane
   * (meaning that each code unit represents a rune) it is often better to
   * map the runes instead:
   *
   *     string.runes.map((rune) => new String.character(rune))
   */
  List<String> split(Pattern pattern);

  /**
   * Returns a list of the individual code-units converted to strings.
   *
   * *Deprecated*
   * If you want to split on code-unit boundaries, use [split]. If you
   * want to split on rune boundaries, use [runes] and map the result.
   *
   *     Iterable<String> characters =
   *         string.runes.map((c) => new String.fromCharCode(c));
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
   * Returns a list of UTF-16 code units of this string.
   *
   * *This getter is deprecated. Use [codeUnits] instead.*
   */
  List<int> get charCodes;

  /**
   * Returns an iterable of the UTF-16 code units of this string.
   */
  // TODO(floitsch): should it return a list?
  // TODO(floitsch): make it a bidirectional iterator.
  Iterable<int> get codeUnits;

  /**
   * Returns an iterable of Unicode code-points of this string.
   *
   * If the string contains surrogate pairs, they will be combined and returned
   * as one integer by this iterator. Unmatched surrogate halves are treated
   * like valid 16-bit code-units.
   */
  // TODO(floitsch): make it a Runes class.
  Iterable<int> get runes;

  /**
   * If this string is not already all lower case, returns a new string
   * where all characters are made lower case. Returns [:this:] otherwise.
   */
  // TODO(floitsch): document better. (See EcmaScript for description).
  String toLowerCase();

  /**
   * If this string is not already all upper case, returns a new string
   * where all characters are made upper case. Returns [:this:] otherwise.
   */
  // TODO(floitsch): document better. (See EcmaScript for description).
  String toUpperCase();
}
