// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of _interceptors;

/**
 * The interceptor class for [String]. The compiler recognizes this
 * class as an interceptor, and changes references to [:this:] to
 * actually use the receiver of the method, which is generated as an extra
 * argument added to each member.
 */
class JSString extends Interceptor implements String, JSIndexable {
  const JSString();

  int codeUnitAt(int index) {
    if (index is !int) throw diagnoseIndexError(this, index);
    if (index < 0) throw diagnoseIndexError(this, index);
    if (index >= length) throw diagnoseIndexError(this, index);
    return JS('JSUInt31', r'#.charCodeAt(#)', this, index);
  }

  Iterable<Match> allMatches(String string, [int start = 0]) {
    checkString(string);
    checkInt(start);
    if (0 > start || start > string.length) {
      throw new RangeError.range(start, 0, string.length);
    }
    return allMatchesInStringUnchecked(this, string, start);
  }

  Match matchAsPrefix(String string, [int start = 0]) {
    if (start < 0 || start > string.length) {
      throw new RangeError.range(start, 0, string.length);
    }
    if (start + this.length > string.length) return null;
    // TODO(lrn): See if this can be optimized.
    for (int i = 0; i < this.length; i++) {
      if (string.codeUnitAt(start + i) != this.codeUnitAt(i)) {
        return null;
      }
    }
    return new StringMatch(start, string, this);
  }

  String operator +(String other) {
    if (other is !String) throw new ArgumentError.value(other);
    return JS('String', r'# + #', this, other);
  }

  bool endsWith(String other) {
    checkString(other);
    int otherLength = other.length;
    if (otherLength > length) return false;
    return other == substring(length - otherLength);
  }

  String replaceAll(Pattern from, String to) {
    checkString(to);
    return stringReplaceAllUnchecked(this, from, to);
  }

  String replaceAllMapped(Pattern from, String convert(Match match)) {
    return this.splitMapJoin(from, onMatch: convert);
  }

  String splitMapJoin(Pattern from,
                      {String onMatch(Match match),
                       String onNonMatch(String nonMatch)}) {
    return stringReplaceAllFuncUnchecked(this, from, onMatch, onNonMatch);
  }

  String replaceFirst(Pattern from, String to, [int startIndex = 0]) {
    checkString(to);
    checkInt(startIndex);
    RangeError.checkValueInInterval(startIndex, 0, this.length, "startIndex");
    return stringReplaceFirstUnchecked(this, from, to, startIndex);
  }

  String replaceFirstMapped(Pattern from, String replace(Match match),
                            [int startIndex = 0]) {
    checkNull(replace);
    checkInt(startIndex);
    RangeError.checkValueInInterval(startIndex, 0, this.length, "startIndex");
    return stringReplaceFirstMappedUnchecked(this, from, replace, startIndex);
  }

  List<String> split(Pattern pattern) {
    checkNull(pattern);
    if (pattern is String) {
      return JS('JSExtendableArray', r'#.split(#)', this, pattern);
    } else if (pattern is JSSyntaxRegExp && regExpCaptureCount(pattern) == 0) {
      var re = regExpGetNative(pattern);
      return JS('JSExtendableArray', r'#.split(#)', this, re);
    } else {
      return _defaultSplit(pattern);
    }
  }

  String replaceRange(int start, int end, String replacement) {
    checkString(replacement);
    checkInt(start);
    end = RangeError.checkValidRange(start, end, this.length);
    checkInt(end);
    return stringReplaceRangeUnchecked(this, start, end, replacement);
  }

  List<String> _defaultSplit(Pattern pattern) {
    List<String> result = <String>[];
    // End of most recent match. That is, start of next part to add to result.
    int start = 0;
    // Length of most recent match.
    // Set >0, so no match on the empty string causes the result to be [""].
    int length = 1;
    for (var match in pattern.allMatches(this)) {
      int matchStart = match.start;
      int matchEnd = match.end;
      length = matchEnd - matchStart;
      if (length == 0 && start == matchStart) {
        // An empty match right after another match is ignored.
        // This includes an empty match at the start of the string.
        continue;
      }
      int end = matchStart;
      result.add(this.substring(start, end));
      start = matchEnd;
    }
    if (start < this.length || length > 0) {
      // An empty match at the end of the string does not cause a "" at the end.
      // A non-empty match ending at the end of the string does add a "".
      result.add(this.substring(start));
    }
    return result;
  }

  bool startsWith(Pattern pattern, [int index = 0]) {
    checkInt(index);
    if (index < 0 || index > this.length) {
      throw new RangeError.range(index, 0, this.length);
    }
    if (pattern is String) {
      String other = pattern;
      int otherLength = other.length;
      int endIndex = index + otherLength;
      if (endIndex > length) return false;
      return other == JS('String', r'#.substring(#, #)', this, index, endIndex);
    }
    return pattern.matchAsPrefix(this, index) != null;
  }

  String substring(int startIndex, [int endIndex]) {
    checkInt(startIndex);
    if (endIndex == null) endIndex = length;
    checkInt(endIndex);
    if (startIndex < 0 ) throw new RangeError.value(startIndex);
    if (startIndex > endIndex) throw new RangeError.value(startIndex);
    if (endIndex > length) throw new RangeError.value(endIndex);
    return JS('String', r'#.substring(#, #)', this, startIndex, endIndex);
  }

  String toLowerCase() {
    return JS(
        'returns:String;effects:none;depends:none;throws:null(1)',
        r'#.toLowerCase()', this);
  }

  String toUpperCase() {
    return JS(
        'returns:String;effects:none;depends:none;throws:null(1)',
        r'#.toUpperCase()', this);
  }

  // Characters with Whitespace property (Unicode 6.2).
  // 0009..000D    ; White_Space # Cc       <control-0009>..<control-000D>
  // 0020          ; White_Space # Zs       SPACE
  // 0085          ; White_Space # Cc       <control-0085>
  // 00A0          ; White_Space # Zs       NO-BREAK SPACE
  // 1680          ; White_Space # Zs       OGHAM SPACE MARK
  // 180E          ; White_Space # Zs       MONGOLIAN VOWEL SEPARATOR
  // 2000..200A    ; White_Space # Zs       EN QUAD..HAIR SPACE
  // 2028          ; White_Space # Zl       LINE SEPARATOR
  // 2029          ; White_Space # Zp       PARAGRAPH SEPARATOR
  // 202F          ; White_Space # Zs       NARROW NO-BREAK SPACE
  // 205F          ; White_Space # Zs       MEDIUM MATHEMATICAL SPACE
  // 3000          ; White_Space # Zs       IDEOGRAPHIC SPACE
  //
  // BOM: 0xFEFF
  static bool _isWhitespace(int codeUnit) {
    // Most codeUnits should be less than 256. Special case with a smaller
    // switch.
    if (codeUnit < 256) {
      switch (codeUnit) {
        case 0x09:
        case 0x0A:
        case 0x0B:
        case 0x0C:
        case 0x0D:
        case 0x20:
        case 0x85:
        case 0xA0:
          return true;
        default:
          return false;
      }
    }
    switch (codeUnit) {
      case 0x1680:
      case 0x180E:
      case 0x2000:
      case 0x2001:
      case 0x2002:
      case 0x2003:
      case 0x2004:
      case 0x2005:
      case 0x2006:
      case 0x2007:
      case 0x2008:
      case 0x2009:
      case 0x200A:
      case 0x2028:
      case 0x2029:
      case 0x202F:
      case 0x205F:
      case 0x3000:
      case 0xFEFF:
        return true;
      default:
        return false;
    }
  }

  /// Finds the index of the first non-whitespace character, or the
  /// end of the string. Start looking at position [index].
  static int _skipLeadingWhitespace(String string, int index) {
    const int SPACE = 0x20;
    const int CARRIAGE_RETURN = 0x0D;
    while (index < string.length) {
      int codeUnit = string.codeUnitAt(index);
      if (codeUnit != SPACE &&
          codeUnit != CARRIAGE_RETURN &&
          !_isWhitespace(codeUnit)) {
        break;
      }
      index++;
    }
    return index;
  }

  /// Finds the index after the last non-whitespace character, or 0.
  /// Start looking at position [index - 1].
  static int _skipTrailingWhitespace(String string, int index) {
    const int SPACE = 0x20;
    const int CARRIAGE_RETURN = 0x0D;
    while (index > 0) {
      int codeUnit = string.codeUnitAt(index - 1);
      if (codeUnit != SPACE &&
          codeUnit != CARRIAGE_RETURN &&
          !_isWhitespace(codeUnit)) {
        break;
      }
      index--;
    }
    return index;
  }

  // Dart2js can't use JavaScript trim directly,
  // because JavaScript does not trim
  // the NEXT LINE (NEL) character (0x85).
  String trim() {
    const int NEL = 0x85;

    // Start by doing JS trim. Then check if it leaves a NEL at
    // either end of the string.
    String result = JS('String', '#.trim()', this);
    if (result.length == 0) return result;
    int firstCode = result.codeUnitAt(0);
    int startIndex = 0;
    if (firstCode == NEL) {
      startIndex = _skipLeadingWhitespace(result, 1);
      if (startIndex == result.length) return "";
    }

    int endIndex = result.length;
    // We know that there is at least one character that is non-whitespace.
    // Therefore we don't need to verify that endIndex > startIndex.
    int lastCode = result.codeUnitAt(endIndex - 1);
    if (lastCode == NEL) {
      endIndex = _skipTrailingWhitespace(result, endIndex - 1);
    }
    if (startIndex == 0 && endIndex == result.length) return result;
    return JS('String', r'#.substring(#, #)', result, startIndex, endIndex);
  }

  // Dart2js can't use JavaScript trimLeft directly,
  // because it is not in ES5, so not every browser implements it,
  // and because those that do will not trim the NEXT LINE character (0x85).
  String trimLeft() {
    const int NEL = 0x85;

    // Start by doing JS trim. Then check if it leaves a NEL at
    // the beginning of the string.
    String result;
    int startIndex = 0;
    if (JS('bool', 'typeof #.trimLeft != "undefined"', this)) {
      result = JS('String', '#.trimLeft()', this);
      if (result.length == 0) return result;
      int firstCode = result.codeUnitAt(0);
      if (firstCode == NEL) {
        startIndex = _skipLeadingWhitespace(result, 1);
      }
    } else {
      result = this;
      startIndex = _skipLeadingWhitespace(this, 0);
    }
    if (startIndex == 0) return result;
    if (startIndex == result.length) return "";
    return JS('String', r'#.substring(#)', result, startIndex);
  }

  // Dart2js can't use JavaScript trimRight directly,
  // because it is not in ES5 and because JavaScript does not trim
  // the NEXT LINE character (0x85).
  String trimRight() {
    const int NEL = 0x85;

    // Start by doing JS trim. Then check if it leaves a NEL or BOM at
    // the end of the string.
    String result;
    int endIndex;
    // trimRight is implemented by Firefox and Chrome/Blink,
    // so use it if it is there.
    if (JS('bool', 'typeof #.trimRight != "undefined"', this)) {
      result = JS('String', '#.trimRight()', this);
      endIndex = result.length;
      if (endIndex == 0) return result;
      int lastCode = result.codeUnitAt(endIndex - 1);
      if (lastCode == NEL) {
        endIndex = _skipTrailingWhitespace(result, endIndex - 1);
      }
    } else {
      result = this;
      endIndex = _skipTrailingWhitespace(this, this.length);
    }

    if (endIndex == result.length) return result;
    if (endIndex == 0) return "";
    return JS('String', r'#.substring(#, #)', result, 0, endIndex);
  }

  String operator*(int times) {
    if (0 >= times) return '';  // Unnecessary but hoists argument type check.
    if (times == 1 || this.length == 0) return this;
    if (times != JS('JSUInt32', '# >>> 0', times)) {
      // times >= 2^32. We can't create a string that big.
      throw const OutOfMemoryError();
    }
    var result = '';
    var s = this;
    while (true) {
      if (times & 1 == 1) result = s + result;
      times = JS('JSUInt31', '# >>> 1', times);
      if (times == 0) break;
      s += s;
    }
    return result;
  }

  String padLeft(int width, [String padding = ' ']) {
    int delta = width - this.length;
    if (delta <= 0) return this;
    return padding * delta + this;
  }

  String padRight(int width, [String padding = ' ']) {
    int delta = width - this.length;
    if (delta <= 0) return this;
    return this + padding * delta;
  }

  List<int> get codeUnits => new CodeUnits(this);

  Runes get runes => new Runes(this);

  int indexOf(Pattern pattern, [int start = 0]) {
    checkNull(pattern);
    if (start is! int) throw argumentErrorValue(start);
    if (start < 0 || start > this.length) {
      throw new RangeError.range(start, 0, this.length);
    }
    if (pattern is String) {
      return stringIndexOfStringUnchecked(this, pattern, start);
    }
    if (pattern is JSSyntaxRegExp) {
      JSSyntaxRegExp re = pattern;
      Match match = firstMatchAfter(re, this, start);
      return (match == null) ? -1 : match.start;
    }
    for (int i = start; i <= this.length; i++) {
      if (pattern.matchAsPrefix(this, i) != null) return i;
    }
    return -1;
  }

  int lastIndexOf(Pattern pattern, [int start]) {
    checkNull(pattern);
    if (start == null) {
      start = length;
    } else if (start is! int) {
      throw argumentErrorValue(start);
    } else if (start < 0 || start > this.length) {
      throw new RangeError.range(start, 0, this.length);
    }
    if (pattern is String) {
      String other = pattern;
      if (start + other.length > this.length) {
        start = this.length - other.length;
      }
      return stringLastIndexOfUnchecked(this, other, start);
    }
    for (int i = start; i >= 0; i--) {
      if (pattern.matchAsPrefix(this, i) != null) return i;
    }
    return -1;
  }

  bool contains(Pattern other, [int startIndex = 0]) {
    checkNull(other);
    if (startIndex < 0 || startIndex > this.length) {
      throw new RangeError.range(startIndex, 0, this.length);
    }
    return stringContainsUnchecked(this, other, startIndex);
  }

  bool get isEmpty => length == 0;

  bool get isNotEmpty => !isEmpty;

  int compareTo(String other) {
    if (other is !String) throw argumentErrorValue(other);
    return this == other ? 0
        : JS('bool', r'# < #', this, other) ? -1 : 1;
  }

  // Note: if you change this, also change the function [S].
  String toString() => this;

  /**
   * This is the [Jenkins hash function][1] but using masking to keep
   * values in SMI range.
   *
   * [1]: http://en.wikipedia.org/wiki/Jenkins_hash_function
   */
  int get hashCode {
    // TODO(ahe): This method shouldn't have to use JS. Update when our
    // optimizations are smarter.
    int hash = 0;
    for (int i = 0; i < length; i++) {
      hash = 0x1fffffff & (hash + JS('int', r'#.charCodeAt(#)', this, i));
      hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
      hash = JS('int', '# ^ (# >> 6)', hash, hash);
    }
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) <<  3));
    hash = JS('int', '# ^ (# >> 11)', hash, hash);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }

  Type get runtimeType => String;

  int get length => JS('int', r'#.length', this);

  String operator [](int index) {
    if (index is !int) throw diagnoseIndexError(this, index);
    if (index >= length || index < 0) throw diagnoseIndexError(this, index);
    return JS('String', '#[#]', this, index);
  }
}
