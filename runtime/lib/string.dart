// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * [StringBase] contains common methods used by concrete String implementations,
 * e.g., OneByteString.
 */
class StringBase {

  int hashCode() native "String_hashCode";

  /**
   *  Create the most efficient string representation for specified
   *  [codePoints].
   */
  static String createFromCharCodes(List<int> charCodes) {
    ObjectArray objectArray;
    if (charCodes is ObjectArray) {
      objectArray = charCodes;
    } else {
      int len = charCodes.length;
      objectArray = new Array(len);
      for (int i = 0; i < len; i++) {
        objectArray[i] = charCodes[i];
      }
    }
    return _createFromCodePoints(objectArray);
  }

  static String _createFromCodePoints(ObjectArray<int> codePoints)
      native "StringBase_createFromCodePoints";

  String operator [](int index) native "String_charAt";

  int charCodeAt(int index) native "String_charCodeAt";

  int get length() native "String_getLength";

  bool isEmpty() {
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
    if (!(other is String) ||
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

  bool substringMatches(int start, String other) {
    if (other.isEmpty()) return true;
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
    return this.substringMatches(this.length - other.length, other);
  }

  bool startsWith(String other) {
    return this.substringMatches(0, other);
  }

  int indexOf(String other, int startIndex) {
    if (other.isEmpty()) {
      return startIndex < this.length ? startIndex : this.length;
    }
    if ((startIndex < 0) || (startIndex >= this.length)) {
      return -1;
    }
    int len = this.length - other.length + 1;
    for (int index = startIndex; index < len; index++) {
      if (this.substringMatches(index, other)) {
        return index;
      }
    }
    return -1;
  }

  int lastIndexOf(String other, int fromIndex) {
    if (other.isEmpty()) {
      return Math.min(this.length, fromIndex);
    }
    if (fromIndex >= this.length) {
      fromIndex = this.length - 1;
    }
    for (int index = fromIndex; index >= 0; index--) {
      if (this.substringMatches(index, other)) {
        return index;
      }
    }
    return -1;
  }

  String substring(int startIndex, int endIndex) {
    if ((startIndex < 0) || (startIndex > this.length)) {
      throw new IndexOutOfRangeException(startIndex);
    }
    if ((endIndex < 0) || (endIndex > this.length)) {
      throw new IndexOutOfRangeException(endIndex);
    }
    if (startIndex > endIndex) {
      throw new IndexOutOfRangeException(startIndex);
    }
    return substringUnchecked_(startIndex, endIndex);
  }

  // TODO(terry): Temporary workaround until substring can support a default
  //              argument for endIndex (when the VM supports default args).
  //              This method is a place holder to flag breakage for apps
  //              that depend on this behavior of substring.
  String substringToEnd(int startIndex) {
    return this.substring(startIndex, this.length);
  }

  String substringUnchecked_(int startIndex, int endIndex) {
    int len = endIndex - startIndex;
    Array<int> charCodes = new Array<int>(len);
    for (int i = 0; i < len; i++) {
      charCodes[i] = this.charCodeAt(startIndex + i);
    }
    return StringBase.createFromCharCodes(charCodes);
  }

  String trim() {
    int len = this.length;
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
    for (int i = last; last >= first; last--) {
      if (!_isWhitespace(this.charCodeAt(last))) {
        break;
      }
    }
    return substringUnchecked_(first, last + 1);
  }

  bool contains(Pattern other, int startIndex) {
    if (other is RegExp) {
      throw "Unimplemented String.contains with RegExp";
    }
    return indexOf(other, startIndex) >= 0;
  }

  String replaceFirst(Pattern from, String to) {
    if (from is RegExp) {
      throw "Unimplemented String.replace with RegExp";
    }
    int pos = this.indexOf(from, 0);
    if (pos < 0) {
      return this;
    }
    String s1 = this.substring(0, pos);
    String s2 = this.substring(pos + from.length, this.length);
    return s1.concat(to.concat(s2));
  }

  String replaceAll(Pattern from_, String to) {
    if (from_ is RegExp) {
      throw "Unimplemented String.replaceAll with RegExp";
    }
    String from = from_;
    int fromLength = from.length;
    int toLength = to.length;
    int thisLength = this.length;

    StringBuffer result = new StringBuffer("");
    // Special case the empty string replacement where [to] is
    // inserted in between each character.
    if (fromLength === 0) {
      result.add(to);
      for (int i = 0; i < thisLength; i++) {
        result.add(this.substring(i, i + 1));
        result.add(to);
      }
      return result.toString();
    }

    int index = indexOf(from, 0);
    if (index < 0) {
      return this;
    }
    int startIndex = 0;
    do {
      result.add(this.substring(startIndex, index));
      result.add(to);
      startIndex = index + fromLength;
    } while ((index = indexOf(from, startIndex)) >= 0);

    // If there are remaining code points, add them to the string
    // buffer.
    if (startIndex < thisLength) {
      result.add(this.substring(startIndex, thisLength));
    }

    return result.toString();
  }

  /**
   * Convert argument obj to string and concat it with this string.
   * Returns concatenated string.
   */
  String operator +(Object obj) {
    return this.concat(obj.toString());
  }

  /**
   * Convert all objects in [values] to strings and concat them
   * into a result string.
   */
  static String _interpolate(Array values) {
    int numValues = values.length;
    Array<String> stringArray = new Array<String>(numValues);
    int resultLength = 0;
    for (int i = 0; i < numValues; i++) {
      String str = values[i].toString();
      resultLength += str.length;
      stringArray[i] = str;
    }
    Array<int> codepoints = new Array<int>(resultLength);
    int intArrayIx = 0;
    for (int i = 0; i < numValues; i++) {
      String str = stringArray[i];
      int strLength = str.length;
      for (int k = 0; k < strLength; k++) {
        codepoints[intArrayIx++] = str.charCodeAt(k);
      }
    }
    return StringBase.createFromCharCodes(codepoints);
  }

  Iterable<Match> allMatches(String str) {
    GrowableObjectArray<Match> result = new GrowableObjectArray<Match>();
    if (this.isEmpty()) return result;
    int length = this.length;

    int ix = 0;
    while (ix < str.length) {
      int foundIx = str.indexOf(this, ix);
      if (foundIx < 0) break;
      result.add(new _StringMatch(foundIx, str, this));
      ix = foundIx + length;
    }
    return result;
  }

  Array<String> split(Pattern pattern) {
    if (pattern is RegExp) {
      throw "Unimplemented split with RegExp";
    }
    GrowableObjectArray<String> result = new GrowableObjectArray<String>();
    if (pattern.isEmpty()) {
      for (int i = 0; i < this.length; i++) {
        result.add(this.substring(i, i+1));
      }
      return result;
    }
    int ix = 0;
    while (ix < this.length) {
      int foundIx = this.indexOf(pattern, ix);
      if (foundIx < 0) {
        // Not found, add remaining.
        result.add(this.substring(ix, this.length));
        break;
      }
      result.add(this.substring(ix, foundIx));
      ix = foundIx + pattern.length;
    }
    if (ix == this.length) {
      result.add("");
    }
    return result;
  }

  Array<String> splitChars() {
    int len = this.length;
    final result = new Array<String>(len);
    for (int i = 0; i < len; i++) {
      result[i] = this[i];
    }
    return result;
  }

  Array<int> charCodes() {
    int len = this.length;
    final result = new Array<int>(len);
    for (int i = 0; i < len; i++) {
      result[i] = this.charCodeAt(i);
    }
    return result;
  }

  String toLowerCase() {
    final int aCode = "A".charCodeAt(0);
    final int zCode = "Z".charCodeAt(0);
    final int delta = aCode - "a".charCodeAt(0);
    return _convert(this, aCode, zCode, delta);
  }

  String toUpperCase() {
    final int aCode = "a".charCodeAt(0);
    final int zCode = "z".charCodeAt(0);
    final int delta = aCode - "A".charCodeAt(0);
    return _convert(this, aCode, zCode, delta);
  }

  static String _convert(String str, int startCode, int endCode, int delta) {
    final int len = str.length;
    int i = 0;
    // Check if we can just return the string.
    for (; i < len; i++) {
      int code = str.charCodeAt(i);
      if ((startCode <= code) && (code <= endCode)) break;
    }
    if (i == len) return str;

    Array<int> charCodes = new Array<int>(len);
    for (i = 0; i < len; i++) {
      int code = str.charCodeAt(i);
      if ((startCode <= code) && (code <= endCode)) {
        code = code - delta;
      }
      charCodes[i] = code;
    }
    return StringBase.createFromCharCodes(charCodes);
  }



  // Implementations of Strings methods follow below.
  static String join(Array<String> strings, String separator) {
    final int length = strings.length;
    if (length === 0) {
      return "";
    }

    Array strings_array = strings;
    if (separator.length != 0) {
      strings_array = new Array(2 * length - 1);
      strings_array[0] = strings[0];
      int j = 1;
      for (int i = 1; i < length; i++) {
        strings_array[j++] = separator;
        strings_array[j++] = strings[i];
      }
    }
    return concatAll(strings_array);
  }

  static String concatAll(Array<String> strings) {
    ObjectArray strings_array;
    if (strings is ObjectArray) {
      strings_array = strings;
    } else {
      int len = strings.length;
      strings_array = new Array(len);
      for (int i = 0; i < len; i++) {
        strings_array[i] = strings[i];
      }
    }
    return _concatAll(strings_array);
  }

  static String _concatAll(ObjectArray<String> strings)
      native "Strings_concatAll";
}


class OneByteString extends StringBase implements String {
  // Checks for one-byte whitespaces only.
  // TODO(srdjan): Investigate if 0x85 (NEL) and 0xA0 (NBSP) are valid
  // whitespaces for one byte strings.
  bool _isWhitespace(int codePoint) {
    return
      (codePoint === 32) || // Space.
      ((9 <= codePoint) && (codePoint <= 13)); // CR, LF, TAB, etc.
  }

}


class TwoByteString extends StringBase implements String {
  // Checks for one-byte whitespaces only.
  // TODO(srdjan): Investigate if 0x85 (NEL) and 0xA0 (NBSP) are valid
  // whitespaces. Add checking for multi-byte whitespace codepoints.
  bool _isWhitespace(int codePoint) {
    return
      (codePoint === 32) || // Space.
      ((9 <= codePoint) && (codePoint <= 13)); // CR, LF, TAB, etc.
  }
}


class FourByteString extends StringBase implements String {
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
  const _StringMatch(int this._start,
                     String this.str,
                     String this.pattern);

  int start() => _start;
  int end() => _start + pattern.length;
  String operator[](int g) => group(g);
  int groupCount() => 0;

  String group(int group) {
    if (group != 0) {
      throw new IndexOutOfRangeException(group);
    }
    return pattern;
  }

  Array<String> groups(Array<int> groups) {
    Array<String> result = new Array<String>();
    for (int g in groups) {
      result.add(group(g));
    }
    return result;
  }

  final int _start;
  final String str;
  final String pattern;
}
