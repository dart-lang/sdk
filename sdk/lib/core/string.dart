// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * The String class represents character strings. Strings are
 * immutable. A string is represented by a list of 16-bit UTF-16
 * code units accessible through the [codeUnitAt] or the [codeUnits]
 * methods.  The corresponding Unicode code points are available with
 * [charCodeAt] or the [charCodes] method.
 */
abstract class String implements Comparable, Pattern, Sequence<String> {
  // Unicode does not allow for code points above this limit.
  static const int MAX_CODE_POINT = 0x10ffff;
  // A Dart string is represented by UTF-16 code units which must be <= 0xffff.
  static const int MAX_CODE_UNIT = 0xffff;
  // Unicode does not allow for code points in this range.
  static const int UNICODE_RESERVED_AREA_START = 0xd800;
  static const int UNICODE_RESERVED_AREA_END = 0xdfff;
  // Unicode code points above this limit are coded as two code units in Dart's
  // UTF-16 string.
  static const int SUPPLEMENTARY_CODE_POINT_BASE = 0x10000;

  /**
   * Allocates a new String for the specified 21 bit Unicode [codePoints].
   * Throws an ArgumentError if any of the codePoints are not ints between 0 and
   * MAX_CODE_POINT.  Also throws an ArgumentError if any of the code points
   * are in the area reserved for UTF-16 surrogate pairs.
   */
  factory String.fromCharCodes(List<int> charCodes) {
    int pairs = 0;
    // There is some duplication of constants here relative to the ones in
    // lib/utf/utf16.dart because we don't want core to depend on the utf
    // library.
    const int MASK = 0x3ff;
    const int LEAD_SURROGATE_BASE = UNICODE_RESERVED_AREA_START;
    const int TRAIL_SURROGATE_BASE = 0xdc00;
    for (var code in charCodes) {
      if (code is !int || code < 0) throw new ArgumentError(charCodes);
      if (code >= UNICODE_RESERVED_AREA_START) {
        if (code > MAX_CODE_UNIT) {
          pairs++;
        }
        if (code <= UNICODE_RESERVED_AREA_END || code > MAX_CODE_POINT) {
          // No surrogates or out-of-range code points allowed in the input.
          throw new ArgumentError(charCodes);
        }
      }
    }
    // Fast case - there are no surrogate pairs.
    if (pairs == 0) return new String.fromCodeUnits(charCodes);
    var codeUnits = new List<int>(pairs + charCodes.length);
    int j = 0;
    for (int code in charCodes) {
      if (code >= SUPPLEMENTARY_CODE_POINT_BASE) {
        codeUnits[j++] = LEAD_SURROGATE_BASE +
            (((code - SUPPLEMENTARY_CODE_POINT_BASE) >> 10) & MASK);
        codeUnits[j++] = TRAIL_SURROGATE_BASE + (code & MASK);
      } else {
        codeUnits[j++] = code;
      }
    }
    return new String.fromCodeUnits(codeUnits);
  }

  /**
   * Allocates a new String for the specified 16 bit UTF-16 [codeUnits].
   */
  external factory String.fromCodeUnits(List<int> codeUnits);

  /**
   * Gets the Unicode character (as [String]) at the given [index].  This
   * routine can return a single combining character (accent) that would
   * normally be displayed together with the character it is modifying.
   * If the index corresponds to a surrogate code unit then a one-code-unit
   * string is returned containing that unpaired surrogate code unit.
   */
  String operator [](int index);

  /**
   * Gets the 21 bit Unicode code point at the given [index].  If the code units
   * at index and index + 1 form a valid surrogate pair then this function
   * returns the non-basic plane code point that they represent.  If the code
   * unit at index is a trailing surrogate or a leading surrogate that is not
   * followed by a trailing surrogate then the raw code unit is returned.
   */
  int charCodeAt(int index);

  /**
   * Gets the 16 bit UTF-16 code unit at the given index.
   */
  int codeUnitAt(int index);


  /**
   * The length of the string, measured in UTF-16 code units.
   */
  int get length;

  /**
   * Returns whether the two strings are equal. This method compares
   * each individual UTF-16 code unit.  No Unicode normalization is
   * performed (accent composition/decomposition).
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
   * Returns a list of the characters of this string.  No string normalization
   * is performed so unprecomposed combining characters (accents) may be found
   * in the list.  Valid surrogate pairs are returned as one string.
   */
  List<String> splitChars();

  /**
   * Returns a list of the 21 bit Unicode code points of this string.
   */
  List<int> get charCodes;

  /**
   * Returns a list of the 16 bit UTF-16 code units of this string.
   */
  List<int> get codeUnits;

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
