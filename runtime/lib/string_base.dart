// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * [_StringBase] contains common methods used by concrete String
 * implementations, e.g., _OneByteString.
 */
class _StringBase {

  factory _StringBase._uninstantiable() {
    throw new UnsupportedError(
        "_StringBase can't be instaniated");
  }

  int get hashCode native "String_getHashCode";

  /**
   *  Create the most efficient string representation for specified
   *  [codePoints].
   */
  static String createFromCharCodes(List<int> charCodes) {
    _ObjectArray objectArray;
    if (charCodes is _ObjectArray) {
      objectArray = charCodes;
    } else {
      int len = charCodes.length;
      objectArray = new _ObjectArray(len);
      for (int i = 0; i < len; i++) {
        objectArray[i] = charCodes[i];
      }
    }
    return _createFromCodePoints(objectArray);
  }

  static String _createFromCodePoints(_ObjectArray<int> codePoints)
      native "StringBase_createFromCodePoints";

  String operator [](int index) native "String_charAt";

  int charCodeAt(int index) native "String_charCodeAt";

  int get length native "String_getLength";

  bool get isEmpty {
    return this.length === 0;
  }

  String concat(String other) native "String_concat";

  String toString() {
    return this;
  }

  bool operator ==(Object other) {
    if (this === other) {
      return true;
    }
    if ((other is !String) ||
        (this.length != other.length)) {
      // TODO(5413632): Compare hash codes when both are present.
      return false;
    }
    return this.compareTo(other) === 0;
  }

  int compareTo(String other) {
    int thisLength = this.length;
    int otherLength = other.length;
    int len = (thisLength < otherLength) ? thisLength : otherLength;
    for (int i = 0; i < len; i++) {
      int thisCodePoint = this.charCodeAt(i);
      int otherCodePoint = other.charCodeAt(i);
      if (thisCodePoint < otherCodePoint) {
        return -1;
      }
      if (thisCodePoint > otherCodePoint) {
        return 1;
      }
    }
    if (thisLength < otherLength) return -1;
    if (thisLength > otherLength) return 1;
    return 0;
  }

  bool _substringMatches(int start, String other) {
    if (other.isEmpty) return true;
    if ((start < 0) || (start >= this.length)) {
      return false;
    }
    final int len = other.length;
    if ((start + len) > this.length) {
      return false;
    }
    for (int i = 0; i < len; i++) {
      if (this.charCodeAt(i + start) != other.charCodeAt(i)) {
        return false;
      }
    }
    return true;
  }

  bool endsWith(String other) {
    return _substringMatches(this.length - other.length, other);
  }

  bool startsWith(String other) {
    return _substringMatches(0, other);
  }

  int indexOf(String other, [int start = 0]) {
    if (other.isEmpty) {
      return start < this.length ? start : this.length;
    }
    if ((start < 0) || (start >= this.length)) {
      return -1;
    }
    int len = this.length - other.length + 1;
    for (int index = start; index < len; index++) {
      if (_substringMatches(index, other)) {
        return index;
      }
    }
    return -1;
  }

  int lastIndexOf(String other, [int start = null]) {
    if (start == null) start = length - 1;
    if (other.isEmpty) {
      return min(this.length, start);
    }
    if (start >= this.length) {
      start = this.length - 1;
    }
    for (int index = start; index >= 0; index--) {
      if (_substringMatches(index, other)) {
        return index;
      }
    }
    return -1;
  }

  String substring(int startIndex, [int endIndex]) {
    if (endIndex === null) endIndex = this.length;

    if ((startIndex < 0) || (startIndex > this.length)) {
      throw new IndexOutOfRangeException(startIndex);
    }
    if ((endIndex < 0) || (endIndex > this.length)) {
      throw new IndexOutOfRangeException(endIndex);
    }
    if (startIndex > endIndex) {
      throw new IndexOutOfRangeException(startIndex);
    }
    return _substringUnchecked(startIndex, endIndex);
  }

  String _substringUnchecked(int startIndex, int endIndex)
      native "StringBase_substringUnchecked";

  String trim() {
    final int len = this.length;
    int first = 0;
    for (; first < len; first++) {
      if (!_isWhitespace(this.charCodeAt(first))) {
        break;
      }
    }
    if (len == first) {
      // String contains only whitespaces.
      return "";
    }
    int last = len - 1;
    for (; last >= first; last--) {
      if (!_isWhitespace(this.charCodeAt(last))) {
        break;
      }
    }
    if ((first == 0) && (last == (len - 1))) {
      // Returns this string if it does not have leading or trailing
      // whitespaces.
      return this;
    } else {
      return _substringUnchecked(first, last + 1);
    }
  }

  bool contains(Pattern pattern, [int startIndex = 0]) {
    if (pattern is String) {
      return indexOf(pattern, startIndex) >= 0;
    }
    return pattern.allMatches(this.substring(startIndex)).iterator().hasNext;
  }

  String replaceFirst(Pattern pattern, String replacement) {
    if (pattern is! Pattern) {
      throw new ArgumentError("${pattern} is not a Pattern");
    }
    if (replacement is! String) {
      throw new ArgumentError("${replacement} is not a String");
    }
    StringBuffer buffer = new StringBuffer();
    int startIndex = 0;
    Iterator iterator = pattern.allMatches(this).iterator();
    if (iterator.hasNext) {
      Match match = iterator.next();
      buffer.add(this.substring(startIndex, match.start)).add(replacement);
      startIndex = match.end;
    }
    return buffer.add(this.substring(startIndex)).toString();
  }

  String replaceAll(Pattern pattern, String replacement) {
    if (pattern is! Pattern) {
      throw new ArgumentError("${pattern} is not a Pattern");
    }
    if (replacement is! String) {
      throw new ArgumentError("${replacement} is not a String");
    }
    StringBuffer buffer = new StringBuffer();
    int startIndex = 0;
    for (Match match in pattern.allMatches(this)) {
      buffer.add(this.substring(startIndex, match.start)).add(replacement);
      startIndex = match.end;
    }
    return buffer.add(this.substring(startIndex)).toString();
  }

  /**
   * Convert all objects in [values] to strings and concat them
   * into a result string.
   */
  static String _interpolate(List values) {
    int numValues = values.length;
    var stringList = new _ObjectArray(numValues);
    for (int i = 0; i < numValues; i++) {
      stringList[i] = values[i].toString();
    }
    return _concatAll(stringList);
  }

  Iterable<Match> allMatches(String str) {
    List<Match> result = new List<Match>();
    int length = str.length;
    int patternLength = this.length;
    int startIndex = 0;
    while (true) {
      int position = str.indexOf(this, startIndex);
      if (position == -1) {
        break;
      }
      result.add(new _StringMatch(position, str, this));
      int endIndex = position + patternLength;
      if (endIndex == length) {
        break;
      } else if (position == endIndex) {
        ++startIndex;  // empty match, advance and restart
      } else {
        startIndex = endIndex;
      }
    }
    return result;
  }

  List<String> split(Pattern pattern) {
    int length = this.length;
    Iterator iterator = pattern.allMatches(this).iterator();
    if (length == 0 && iterator.hasNext) {
      // A matched empty string input returns the empty list.
      return <String>[];
    }
    List<String> result = new List<String>();
    int startIndex = 0;
    int previousIndex = 0;
    while (true) {
      if (startIndex == length || !iterator.hasNext) {
        result.add(this.substring(previousIndex, length));
        break;
      }
      Match match = iterator.next();
      if (match.start == length) {
        result.add(this.substring(previousIndex, length));
        break;
      }
      int endIndex = match.end;
      if (startIndex == endIndex && endIndex == previousIndex) {
        ++startIndex;  // empty match, advance and restart
        continue;
      }
      result.add(this.substring(previousIndex, match.start));
      startIndex = previousIndex = endIndex;
    }
    return result;
  }

  List<String> splitChars() {
    int len = this.length;
    final result = new List<String>(len);
    for (int i = 0; i < len; i++) {
      result[i] = this[i];
    }
    return result;
  }

  List<int> get charCodes {
    int len = this.length;
    final result = new List<int>(len);
    for (int i = 0; i < len; i++) {
      result[i] = this.charCodeAt(i);
    }
    return result;
  }

  String toUpperCase() native "String_toUpperCase";

  String toLowerCase() native "String_toLowerCase";

  // Implementations of Strings methods follow below.
  static String join(List<String> strings, String separator) {
    final int length = strings.length;
    if (length === 0) {
      return "";
    }

    List stringsList = strings;
    if (separator.length != 0) {
      stringsList = new List(2 * length - 1);
      stringsList[0] = strings[0];
      int j = 1;
      for (int i = 1; i < length; i++) {
        stringsList[j++] = separator;
        stringsList[j++] = strings[i];
      }
    }
    return concatAll(stringsList);
  }

  static String concatAll(List<String> strings) {
    _ObjectArray stringsArray;
    if (strings is _ObjectArray) {
      stringsArray = strings;
    } else {
      int len = strings.length;
      stringsArray = new _ObjectArray(len);
      for (int i = 0; i < len; i++) {
        stringsArray[i] = strings[i];
      }
    }
    return _concatAll(stringsArray);
  }

  static String _concatAll(_ObjectArray<String> strings)
      native "Strings_concatAll";
}


class _OneByteString extends _StringBase implements String {
  factory _OneByteString._uninstantiable() {
    throw new UnsupportedError(
        "_OneByteString can only be allocated by the VM");
  }

  // Checks for one-byte whitespaces only.
  // TODO(srdjan): Investigate if 0x85 (NEL) and 0xA0 (NBSP) are valid
  // whitespaces for one byte strings.
  bool _isWhitespace(int codePoint) {
    return
      (codePoint === 32) || // Space.
      ((9 <= codePoint) && (codePoint <= 13)); // CR, LF, TAB, etc.
  }

}


class _TwoByteString extends _StringBase implements String {
  factory _TwoByteString._uninstantiable() {
    throw new UnsupportedError(
        "_TwoByteString can only be allocated by the VM");
  }

  // Checks for one-byte whitespaces only.
  // TODO(srdjan): Investigate if 0x85 (NEL) and 0xA0 (NBSP) are valid
  // whitespaces. Add checking for multi-byte whitespace codepoints.
  bool _isWhitespace(int codePoint) {
    return
      (codePoint === 32) || // Space.
      ((9 <= codePoint) && (codePoint <= 13)); // CR, LF, TAB, etc.
  }
}


class _FourByteString extends _StringBase implements String {
  factory _FourByteString._uninstantiable() {
    throw new UnsupportedError(
        "_FourByteString can only be allocated by the VM");
  }

  // Checks for one-byte whitespaces only.
  // TODO(srdjan): Investigate if 0x85 (NEL) and 0xA0 (NBSP) are valid
  // whitespaces. Add checking for multi-byte whitespace codepoints.
  bool _isWhitespace(int codePoint) {
    return
      (codePoint === 32) || // Space.
      ((9 <= codePoint) && (codePoint <= 13)); // CR, LF, TAB, etc.
  }
}


class _ExternalOneByteString extends _StringBase implements String {
  factory _ExternalOneByteString._uninstantiable() {
    throw new UnsupportedError(
        "_ExternalOneByteString can only be allocated by the VM");
  }

  // Checks for one-byte whitespaces only.
  // TODO(srdjan): Investigate if 0x85 (NEL) and 0xA0 (NBSP) are valid
  // whitespaces for one byte strings.
  bool _isWhitespace(int codePoint) {
    return
      (codePoint === 32) || // Space.
      ((9 <= codePoint) && (codePoint <= 13)); // CR, LF, TAB, etc.
  }
}


class _ExternalTwoByteString extends _StringBase implements String {
  factory ExternalTwoByteString._uninstantiable() {
    throw new UnsupportedError(
        "_ExternalTwoByteString can only be allocated by the VM");
  }

  // Checks for one-byte whitespaces only.
  // TODO(srdjan): Investigate if 0x85 (NEL) and 0xA0 (NBSP) are valid
  // whitespaces. Add checking for multi-byte whitespace codepoints.
  bool _isWhitespace(int codePoint) {
    return
      (codePoint === 32) || // Space.
      ((9 <= codePoint) && (codePoint <= 13)); // CR, LF, TAB, etc.
  }
}


class _ExternalFourByteString extends _StringBase implements String {
  factory _ExternalFourByteString._uninstantiable() {
    throw new UnsupportedError(
        "ExternalFourByteString can only be allocated by the VM");
  }

  // Checks for one-byte whitespaces only.
  // TODO(srdjan): Investigate if 0x85 (NEL) and 0xA0 (NBSP) are valid
  // whitespaces. Add checking for multi-byte whitespace codepoints.
  bool _isWhitespace(int codePoint) {
    return
      (codePoint === 32) || // Space.
      ((9 <= codePoint) && (codePoint <= 13)); // CR, LF, TAB, etc.
  }
}


class _StringMatch implements Match {
  const _StringMatch(int this.start,
                     String this.str,
                     String this.pattern);

  int get end => start + pattern.length;
  String operator[](int g) => group(g);
  int get groupCount => 0;

  String group(int group) {
    if (group != 0) {
      throw new IndexOutOfRangeException(group);
    }
    return pattern;
  }

  List<String> groups(List<int> groups) {
    List<String> result = new List<String>();
    for (int g in groups) {
      result.add(group(g));
    }
    return result;
  }

  final int start;
  final String str;
  final String pattern;
}
