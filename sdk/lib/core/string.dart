// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.core;

/**
 * A sequence of characters.
 *
 * A string can be either single or multiline. Single line strings are
 * written using matching single or double quotes, and multiline strings are
 * written using triple quotes. The following are all valid Dart strings:
 *
 *     'Single quotes';
 *     "Double quotes";
 *     'Double quotes in "single" quotes';
 *     "Single quotes in 'double' quotes";
 *
 *     '''A
 *     multiline
 *     string''';
 *
 *     """
 *     Another
 *     multiline
 *     string""";
 *
 * Strings are immutable. Although you cannot change a string, you can perform
 * an operation on a string and assign the result to a new string:
 *
 *     var string = 'Dart is fun';
 *     var newString = string.substring(0, 5);
 *
 * You can use the plus (`+`) operator to concatenate strings:
 *
 *     'Dart ' + 'is ' + 'fun!'; // 'Dart is fun!'
 *
 * You can also use adjacent string literals for concatenation:
 *
 *     'Dart ' 'is ' 'fun!';    // 'Dart is fun!'
 *
 * You can use `${}` to interpolate the value of Dart expressions
 * within strings. The curly braces can be omitted when evaluating identifiers:
 *
 *     string = 'dartlang';
 *     '$string has ${string.length} letters'; // 'dartlang has 8 letters'
 *
 * A string is represented by a sequence of Unicode UTF-16 code units
 * accessible through the [codeUnitAt] or the [codeUnits] members:
 *
 *     string = 'Dart';
 *     string.codeUnitAt(0); // 68
 *     string.codeUnits;     // [68, 97, 114, 116]
 *
 * The string representation of code units is accessible through the index
 * operator:
 *
 *     string[0];            // 'D'
 *
 * The characters of a string are encoded in UTF-16. Decoding UTF-16, which
 * combines surrogate pairs, yields Unicode code points. Following a similar
 * terminology to Go, we use the name 'rune' for an integer representing a
 * Unicode code point. Use the [runes] property to get the runes of a string:
 *
 *     string.runes.toList(); // [68, 97, 114, 116]
 *
 * For a character outside the Basic Multilingual Plane (plane 0) that is
 * composed of a surrogate pair, [runes] combines the pair and returns a
 * single integer.  For example, the Unicode character for a
 * musical G-clef ('𝄞') with rune value 0x1D11E consists of a UTF-16 surrogate
 * pair: `0xD834` and `0xDD1E`. Using [codeUnits] returns the surrogate pair,
 * and using `runes` returns their combined value:
 *
 *     var clef = '\u{1D11E}';
 *     clef.codeUnits;         // [0xD834, 0xDD1E]
 *     clef.runes.toList();    // [0x1D11E]
 *
 * The String class can not be extended or implemented. Attempting to do so
 * yields a compile-time error.
 *
 * ## Other resources
 *
 * See [StringBuffer] to efficiently build a string incrementally. See
 * [RegExp] to work with regular expressions.
 *
 * Also see:

 * * [Dart Cookbook](https://www.dartlang.org/docs/cookbook/#strings)
 *   for String examples and recipes.
 * * [Dart Up and Running](https://www.dartlang.org/docs/dart-up-and-running/ch03.html#strings-and-regular-expressions)
 */
abstract class String implements Comparable<String>, Pattern {
  /**
   * Allocates a new String for the specified [charCodes].
   *
   * The [charCodes] can be UTF-16 code units or runes. If a char-code value is
   * 16-bit, it is copied verbatim:
   *
   *     new String.fromCharCodes([68]); // 'D'
   *
   * If a char-code value is greater than 16-bits, it is decomposed into a
   * surrogate pair:
   *
   *     var clef = new String.fromCharCodes([0x1D11E]);
   *     clef.codeUnitAt(0); // 0xD834
   *     clef.codeUnitAt(1); // 0xDD1E
   *
   * If [start] and [end] is provided, only the values of [charCodes]
   * at positions from `start` to, but not including, `end`, are used.
   * The `start` and `end` values must satisfy
   * `0 <= start <= end <= charCodes.length`.
   */
  external factory String.fromCharCodes(Iterable<int> charCodes,
      [int start = 0, int end]);

  /**
   * Allocates a new String for the specified [charCode].
   *
   * If the [charCode] can be represented by a single UTF-16 code unit, the new
   * string contains a single code unit. Otherwise, the [length] is 2 and
   * the code units form a surrogate pair. See documentation for
   * [fromCharCodes].
   *
   * Creating a String with half of a surrogate pair is allowed.
   */
  external factory String.fromCharCode(int charCode);

  /**
   * Returns the string value of the environment declaration [name].
   *
   * Environment declarations are provided by the surrounding system compiling
   * or running the Dart program. Declarations map a string key to a string
   * value.
   *
   * If [name] is not declared in the environment, the result is instead
   * [defaultValue].
   *
   * Example of getting a value:
   *
   *     const String.fromEnvironment("defaultFloo", defaultValue: "no floo")
   *
   * Example of checking whether a declaration is there at all:
   *
   *     var isDeclared = const String.fromEnvironment("maybeDeclared") != null;
   */
  // The .fromEnvironment() constructors are special in that we do not want
  // users to call them using "new". We prohibit that by giving them bodies
  // that throw, even though const constructors are not allowed to have bodies.
  // Disable those static errors.
  //ignore: const_constructor_with_body
  //ignore: const_factory
  external const factory String.fromEnvironment(String name,
      {String defaultValue});

  /**
   * Gets the character (as a single-code-unit [String]) at the given [index].
   *
   * The returned string represents exactly one UTF-16 code unit, which may be
   * half of a surrogate pair. A single member of a surrogate pair is an
   * invalid UTF-16 string:
   *
   *     var clef = '\u{1D11E}';
   *     // These represent invalid UTF-16 strings.
   *     clef[0].codeUnits;      // [0xD834]
   *     clef[1].codeUnits;      // [0xDD1E]
   *
   * This method is equivalent to
   * `new String.fromCharCode(this.codeUnitAt(index))`.
   */
  String operator [](int index);

  /**
   * Returns the 16-bit UTF-16 code unit at the given [index].
   */
  int codeUnitAt(int index);

  /**
   * The length of the string.
   *
   * Returns the number of UTF-16 code units in this string. The number
   * of [runes] might be fewer, if the string contains characters outside
   * the Basic Multilingual Plane (plane 0):
   *
   *     'Dart'.length;          // 4
   *     'Dart'.runes.length;    // 4
   *
   *     var clef = '\u{1D11E}';
   *     clef.length;            // 2
   *     clef.runes.length;      // 1
   */
  int get length;

  /**
   * Returns a hash code derived from the code units of the string.
   *
   * This is compatible with [==]. Strings with the same sequence
   * of code units have the same hash code.
   */
  int get hashCode;

  /**
   * Returns true if other is a `String` with the same sequence of code units.
   *
   * This method compares each individual code unit of the strings.
   * It does not check for Unicode equivalence.
   * For example, both the following strings represent the string 'Amélie',
   * but due to their different encoding, are not equal:
   *
   *     'Am\xe9lie' == 'Ame\u{301}lie'; // false
   *
   * The first string encodes 'é' as a single unicode code unit (also
   * a single rune), whereas the second string encodes it as 'e' with the
   * combining accent character '◌́'.
   */
  bool operator ==(Object other);

  /**
   * Returns true if this string ends with [other]. For example:
   *
   *     'Dart'.endsWith('t'); // true
   */
  bool endsWith(String other);

  /**
   * Returns true if this string starts with a match of [pattern].
   *
   *     var string = 'Dart';
   *     string.startsWith('D');                       // true
   *     string.startsWith(new RegExp(r'[A-Z][a-z]')); // true
   *
   * If [index] is provided, this method checks if the substring starting
   * at that index starts with a match of [pattern]:
   *
   *     string.startsWith('art', 1);                  // true
   *     string.startsWith(new RegExp(r'\w{3}'));      // true
   *
   * [index] must not be negative or greater than [length].
   *
   * A [RegExp] containing '^' does not match if the [index] is greater than
   * zero. The pattern works on the string as a whole, and does not extract
   * a substring starting at [index] first:
   *
   *     string.startsWith(new RegExp(r'^art'), 1);    // false
   *     string.startsWith(new RegExp(r'art'), 1);     // true
   */
  bool startsWith(Pattern pattern, [int index = 0]);

  /**
   * Returns the position of the first match of [pattern] in this string,
   * starting at [start], inclusive:
   *
   *     var string = 'Dartisans';
   *     string.indexOf('art');                     // 1
   *     string.indexOf(new RegExp(r'[A-Z][a-z]')); // 0
   *
   * Returns -1 if no match is found:
   *
   *     string.indexOf(new RegExp(r'dart'));       // -1
   *
   * [start] must be non-negative and not greater than [length].
   */
  int indexOf(Pattern pattern, [int start]);

  /**
   * Returns the position of the last match [pattern] in this string, searching
   * backward starting at [start], inclusive:
   *
   *     var string = 'Dartisans';
   *     string.lastIndexOf('a');                    // 6
   *     string.lastIndexOf(new RegExp(r'a(r|n)'));  // 6
   *
   * Returns -1 if [pattern] could not be found in this string.
   *
   *     string.lastIndexOf(new RegExp(r'DART'));    // -1
   *
   * The [start] must be non-negative and not greater than [length].
   */
  int lastIndexOf(Pattern pattern, [int start]);

  /**
   * Returns true if this string is empty.
   */
  bool get isEmpty;

  /**
   * Returns true if this string is not empty.
   */
  bool get isNotEmpty;

  /**
   * Creates a new string by concatenating this string with [other].
   *
   *     'dart' + 'lang'; // 'dartlang'
   */
  String operator +(String other);

  /**
   * Returns the substring of this string that extends from [startIndex],
   * inclusive, to [endIndex], exclusive.
   *
   *     var string = 'dartlang';
   *     string.substring(1);    // 'artlang'
   *     string.substring(1, 4); // 'art'
   */
  String substring(int startIndex, [int endIndex]);

  /**
   * Returns the string without any leading and trailing whitespace.
   *
   * If the string contains leading or trailing whitespace, a new string with no
   * leading and no trailing whitespace is returned:
   *
   *     '\tDart is fun\n'.trim(); // 'Dart is fun'
   *
   * Otherwise, the original string itself is returned:
   *
   *     var str1 = 'Dart';
   *     var str2 = str1.trim();
   *     identical(str1, str2);    // true
   *
   * Whitespace is defined by the Unicode White_Space property (as defined in
   * version 6.2 or later) and the BOM character, 0xFEFF.
   *
   * Here is the list of trimmed characters (following version 6.2):
   *
   *     0009..000D    ; White_Space # Cc   <control-0009>..<control-000D>
   *     0020          ; White_Space # Zs   SPACE
   *     0085          ; White_Space # Cc   <control-0085>
   *     00A0          ; White_Space # Zs   NO-BREAK SPACE
   *     1680          ; White_Space # Zs   OGHAM SPACE MARK
   *     180E          ; White_Space # Zs   MONGOLIAN VOWEL SEPARATOR
   *     2000..200A    ; White_Space # Zs   EN QUAD..HAIR SPACE
   *     2028          ; White_Space # Zl   LINE SEPARATOR
   *     2029          ; White_Space # Zp   PARAGRAPH SEPARATOR
   *     202F          ; White_Space # Zs   NARROW NO-BREAK SPACE
   *     205F          ; White_Space # Zs   MEDIUM MATHEMATICAL SPACE
   *     3000          ; White_Space # Zs   IDEOGRAPHIC SPACE
   *
   *     FEFF          ; BOM                ZERO WIDTH NO_BREAK SPACE
   */
  String trim();

  /**
   * Returns the string without any leading whitespace.
   *
   * As [trim], but only removes leading whitespace.
   */
  String trimLeft();

  /**
   * Returns the string without any trailing whitespace.
   *
   * As [trim], but only removes trailing whitespace.
   */
  String trimRight();

  /**
   * Creates a new string by concatenating this string with itself a number
   * of times.
   *
   * The result of `str * n` is equivalent to
   * `str + str + ...`(n times)`... + str`.
   *
   * Returns an empty string if [times] is zero or negative.
   */
  String operator *(int times);

  /**
   * Pads this string on the left if it is shorter than [width].
   *
   * Return a new string that prepends [padding] onto this string
   * one time for each position the length is less than [width].
   *
   * If [width] is already smaller than or equal to `this.length`,
   * no padding is added. A negative `width` is treated as zero.
   *
   * If [padding] has length different from 1, the result will not
   * have length `width`. This may be useful for cases where the
   * padding is a longer string representing a single character, like
   * `"&nbsp;"` or `"\u{10002}`".
   * In that case, the user should make sure that `this.length` is
   * the correct measure of the strings length.
   */
  String padLeft(int width, [String padding = ' ']);

  /**
   * Pads this string on the right if it is shorter than [width].
   *
   * Return a new string that appends [padding] after this string
   * one time for each position the length is less than [width].
   *
   * If [width] is already smaller than or equal to `this.length`,
   * no padding is added. A negative `width` is treated as zero.
   *
   * If [padding] has length different from 1, the result will not
   * have length `width`. This may be useful for cases where the
   * padding is a longer string representing a single character, like
   * `"&nbsp;"` or `"\u{10002}`".
   * In that case, the user should make sure that `this.length` is
   * the correct measure of the strings length.
   */
  String padRight(int width, [String padding = ' ']);

  /**
   * Returns true if this string contains a match of [other]:
   *
   *     var string = 'Dart strings';
   *     string.contains('D');                     // true
   *     string.contains(new RegExp(r'[A-Z]'));    // true
   *
   * If [startIndex] is provided, this method matches only at or after that
   * index:
   *
   *     string.contains('X', 1);                  // false
   *     string.contains(new RegExp(r'[A-Z]'), 1); // false
   *
   * [startIndex] must not be negative or greater than [length].
   */
  bool contains(Pattern other, [int startIndex = 0]);

  /**
   * Returns a new string in which the first occurrence of [from] in this string
   * is replaced with [to], starting from [startIndex]:
   *
   *     '0.0001'.replaceFirst(new RegExp(r'0'), ''); // '.0001'
   *     '0.0001'.replaceFirst(new RegExp(r'0'), '7', 1); // '0.7001'
   */
  String replaceFirst(Pattern from, String to, [int startIndex = 0]);

  /**
   * Replace the first occurrence of [from] in this string.
   *
   * Returns a new string, which is this string
   * except that the first match of [from], starting from [startIndex],
   * is replaced by the result of calling [replace] with the match object.
   *
   * The optional [startIndex] is by default set to 0. If provided, it must be
   * an integer in the range `[0 .. len]`, where `len` is this string's length.
   *
   * If the value returned by calling `replace` is not a [String], it
   * is converted to a `String` using its `toString` method, which must
   * then return a string.
   */
  String replaceFirstMapped(Pattern from, String replace(Match match),
      [int startIndex = 0]);

  /**
   * Replaces all substrings that match [from] with [replace].
   *
   * Returns a new string in which the non-overlapping substrings matching
   * [from] (the ones iterated by `from.allMatches(thisString)`) are replaced
   * by the literal string [replace].
   *
   *     'resume'.replaceAll(new RegExp(r'e'), 'é'); // 'résumé'
   *
   * Notice that the [replace] string is not interpreted. If the replacement
   * depends on the match (for example on a [RegExp]'s capture groups), use
   * the [replaceAllMapped] method instead.
   */
  String replaceAll(Pattern from, String replace);

  /**
   * Replace all substrings that match [from] by a string computed from the
   * match.
   *
   * Returns a new string in which the non-overlapping substrings that match
   * [from] (the ones iterated by `from.allMatches(thisString)`) are replaced
   * by the result of calling [replace] on the corresponding [Match] object.
   *
   * This can be used to replace matches with new content that depends on the
   * match, unlike [replaceAll] where the replacement string is always the same.
   *
   * The [replace] function is called with the [Match] generated
   * by the pattern, and its result is used as replacement.
   *
   * The function defined below converts each word in a string to simplified
   * 'pig latin' using [replaceAllMapped]:
   *
   *     pigLatin(String words) => words.replaceAllMapped(
   *         new RegExp(r'\b(\w*?)([aeiou]\w*)', caseSensitive: false),
   *         (Match m) => "${m[2]}${m[1]}${m[1].isEmpty ? 'way' : 'ay'}");
   *
   *     pigLatin('I have a secret now!'); // 'Iway avehay away ecretsay ownay!'
   */
  String replaceAllMapped(Pattern from, String replace(Match match));

  /**
   * Replaces the substring from [start] to [end] with [replacement].
   *
   * Returns a new string equivalent to:
   *
   *     this.substring(0, start) + replacement + this.substring(end)
   *
   * The [start] and [end] indices must specify a valid range of this string.
   * That is `0 <= start <= end <= this.length`.
   * If [end] is `null`, it defaults to [length].
   */
  String replaceRange(int start, int end, String replacement);

  /**
   * Splits the string at matches of [pattern] and returns a list of substrings.
   *
   * Finds all the matches of `pattern` in this string,
   * and returns the list of the substrings between the matches.
   *
   *     var string = "Hello world!";
   *     string.split(" ");                      // ['Hello', 'world!'];
   *
   * Empty matches at the beginning and end of the strings are ignored,
   * and so are empty matches right after another match.
   *
   *     var string = "abba";
   *     string.split(new RegExp(r"b*"));        // ['a', 'a']
   *                                             // not ['', 'a', 'a', '']
   *
   * If this string is empty, the result is an empty list if `pattern` matches
   * the empty string, and it is `[""]` if the pattern doesn't match.
   *
   *     var string = '';
   *     string.split('');                       // []
   *     string.split("a");                      // ['']
   *
   * Splitting with an empty pattern splits the string into single-code unit
   * strings.
   *
   *     var string = 'Pub';
   *     string.split('');                       // ['P', 'u', 'b']
   *
   *     string.codeUnits.map((unit) {
   *       return new String.fromCharCode(unit);
   *     }).toList();                            // ['P', 'u', 'b']
   *
   * Splitting happens at UTF-16 code unit boundaries,
   * and not at rune boundaries:
   *
   *     // String made up of two code units, but one rune.
   *     string = '\u{1D11E}';
   *     string.split('').length;                 // 2 surrogate values
   *
   * To get a list of strings containing the individual runes of a string,
   * you should not use split. You can instead map each rune to a string
   * as follows:
   *
   *     string.runes.map((rune) => new String.fromCharCode(rune)).toList();
   */
  List<String> split(Pattern pattern);

  /**
   * Splits the string, converts its parts, and combines them into a new
   * string.
   *
   * [pattern] is used to split the string into parts and separating matches.
   *
   * Each match is converted to a string by calling [onMatch]. If [onMatch]
   * is omitted, the matched string is used.
   *
   * Each non-matched part is converted by a call to [onNonMatch]. If
   * [onNonMatch] is omitted, the non-matching part is used.
   *
   * Then all the converted parts are combined into the resulting string.
   *
   *     'Eats shoots leaves'.splitMapJoin((new RegExp(r'shoots')),
   *         onMatch:    (m) => '${m.group(0)}',
   *         onNonMatch: (n) => '*'); // *shoots*
   */
  String splitMapJoin(Pattern pattern,
      {String onMatch(Match match), String onNonMatch(String nonMatch)});

  /**
   * Returns an unmodifiable list of the UTF-16 code units of this string.
   */
  List<int> get codeUnits;

  /**
   * Returns an [Iterable] of Unicode code-points of this string.
   *
   * If the string contains surrogate pairs, they are combined and returned
   * as one integer by this iterator. Unmatched surrogate halves are treated
   * like valid 16-bit code-units.
   */
  Runes get runes;

  /**
   * Converts all characters in this string to lower case.
   * If the string is already in all lower case, this method returns [:this:].
   *
   *     'ALPHABET'.toLowerCase(); // 'alphabet'
   *     'abc'.toLowerCase();      // 'abc'
   *
   * This function uses the language independent Unicode mapping and thus only
   * works in some languages.
   */
  // TODO(floitsch): document better. (See EcmaScript for description).
  String toLowerCase();

  /**
   * Converts all characters in this string to upper case.
   * If the string is already in all upper case, this method returns [:this:].
   *
   *     'alphabet'.toUpperCase(); // 'ALPHABET'
   *     'ABC'.toUpperCase();      // 'ABC'
   *
   * This function uses the language independent Unicode mapping and thus only
   * works in some languages.
   */
  // TODO(floitsch): document better. (See EcmaScript for description).
  String toUpperCase();
}

/**
 * The runes (integer Unicode code points) of a [String].
 */
class Runes extends Iterable<int> {
  final String string;
  Runes(this.string);

  RuneIterator get iterator => new RuneIterator(string);

  int get last {
    if (string.length == 0) {
      throw new StateError('No elements.');
    }
    int length = string.length;
    int code = string.codeUnitAt(length - 1);
    if (_isTrailSurrogate(code) && string.length > 1) {
      int previousCode = string.codeUnitAt(length - 2);
      if (_isLeadSurrogate(previousCode)) {
        return _combineSurrogatePair(previousCode, code);
      }
    }
    return code;
  }
}

// Is then code (a 16-bit unsigned integer) a UTF-16 lead surrogate.
bool _isLeadSurrogate(int code) => (code & 0xFC00) == 0xD800;

// Is then code (a 16-bit unsigned integer) a UTF-16 trail surrogate.
bool _isTrailSurrogate(int code) => (code & 0xFC00) == 0xDC00;

// Combine a lead and a trail surrogate value into a single code point.
int _combineSurrogatePair(int start, int end) {
  return 0x10000 + ((start & 0x3FF) << 10) + (end & 0x3FF);
}

/** [Iterator] for reading runes (integer Unicode code points) out of a Dart
  * string.
  */
class RuneIterator implements BidirectionalIterator<int> {
  /** String being iterated. */
  final String string;
  /** Position before the current code point. */
  int _position;
  /** Position after the current code point. */
  int _nextPosition;
  /**
   * Current code point.
   *
   * If the iterator has hit either end, the [_currentCodePoint] is null
   * and [: _position == _nextPosition :].
   */
  int _currentCodePoint;

  /** Create an iterator positioned at the beginning of the string. */
  RuneIterator(String string)
      : this.string = string,
        _position = 0,
        _nextPosition = 0;

  /**
   * Create an iterator positioned before the [index]th code unit of the string.
   *
   * When created, there is no [current] value.
   * A [moveNext] will use the rune starting at [index] the current value,
   * and a [movePrevious] will use the rune ending just before [index] as the
   * the current value.
   *
   * The [index] position must not be in the middle of a surrogate pair.
   */
  RuneIterator.at(String string, int index)
      : string = string,
        _position = index,
        _nextPosition = index {
    RangeError.checkValueInInterval(index, 0, string.length);
    _checkSplitSurrogate(index);
  }

  /** Throw an error if the index is in the middle of a surrogate pair. */
  void _checkSplitSurrogate(int index) {
    if (index > 0 &&
        index < string.length &&
        _isLeadSurrogate(string.codeUnitAt(index - 1)) &&
        _isTrailSurrogate(string.codeUnitAt(index))) {
      throw new ArgumentError('Index inside surrogate pair: $index');
    }
  }

  /**
   * Returns the starting position of the current rune in the string.
   *
   * Returns null if the [current] rune is null.
   */
  int get rawIndex => (_position != _nextPosition) ? _position : null;

  /**
   * Resets the iterator to the rune at the specified index of the string.
   *
   * Setting a negative [rawIndex], or one greater than or equal to
   * [:string.length:],
   * is an error. So is setting it in the middle of a surrogate pair.
   *
   * Setting the position to the end of then string will set [current] to null.
   */
  void set rawIndex(int rawIndex) {
    RangeError.checkValidIndex(rawIndex, string, "rawIndex");
    reset(rawIndex);
    moveNext();
  }

  /**
   * Resets the iterator to the given index into the string.
   *
   * After this the [current] value is unset.
   * You must call [moveNext] make the rune at the position current,
   * or [movePrevious] for the last rune before the position.
   *
   * Setting a negative [rawIndex], or one greater than [:string.length:],
   * is an error. So is setting it in the middle of a surrogate pair.
   */
  void reset([int rawIndex = 0]) {
    RangeError.checkValueInInterval(rawIndex, 0, string.length, "rawIndex");
    _checkSplitSurrogate(rawIndex);
    _position = _nextPosition = rawIndex;
    _currentCodePoint = null;
  }

  /** The rune (integer Unicode code point) starting at the current position in
   *  the string.
   */
  int get current => _currentCodePoint;

  /**
   * The number of code units comprising the current rune.
   *
   * Returns zero if there is no current rune ([current] is null).
   */
  int get currentSize => _nextPosition - _position;

  /**
   * A string containing the current rune.
   *
   * For runes outside the basic multilingual plane, this will be
   * a String of length 2, containing two code units.
   *
   * Returns null if [current] is null.
   */
  String get currentAsString {
    if (_position == _nextPosition) return null;
    if (_position + 1 == _nextPosition) return string[_position];
    return string.substring(_position, _nextPosition);
  }

  bool moveNext() {
    _position = _nextPosition;
    if (_position == string.length) {
      _currentCodePoint = null;
      return false;
    }
    int codeUnit = string.codeUnitAt(_position);
    int nextPosition = _position + 1;
    if (_isLeadSurrogate(codeUnit) && nextPosition < string.length) {
      int nextCodeUnit = string.codeUnitAt(nextPosition);
      if (_isTrailSurrogate(nextCodeUnit)) {
        _nextPosition = nextPosition + 1;
        _currentCodePoint = _combineSurrogatePair(codeUnit, nextCodeUnit);
        return true;
      }
    }
    _nextPosition = nextPosition;
    _currentCodePoint = codeUnit;
    return true;
  }

  bool movePrevious() {
    _nextPosition = _position;
    if (_position == 0) {
      _currentCodePoint = null;
      return false;
    }
    int position = _position - 1;
    int codeUnit = string.codeUnitAt(position);
    if (_isTrailSurrogate(codeUnit) && position > 0) {
      int prevCodeUnit = string.codeUnitAt(position - 1);
      if (_isLeadSurrogate(prevCodeUnit)) {
        _position = position - 1;
        _currentCodePoint = _combineSurrogatePair(prevCodeUnit, codeUnit);
        return true;
      }
    }
    _position = position;
    _currentCodePoint = codeUnit;
    return true;
  }
}
