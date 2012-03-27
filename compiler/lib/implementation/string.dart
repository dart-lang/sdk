// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class StringImplementation implements String native "String" {
  factory StringImplementation.fromValues(List<int> values) {
    return _newFromValues(values);
  }

  String operator[](int index) {
    if (0 <= index && index < length) {
      return _indexOperator(index);
    }
    throw new IndexOutOfRangeException(index);
  }

  int charCodeAt(int index) {
    if (0 <= index && index < length) {
      return _charCodeAt(index);
    }
    throw new IndexOutOfRangeException(index);
  }

  int get length() native;

  bool operator ==(var other) native;

  bool substringMatches(int start, String other) {
    int len = length;
    int otherLen = other.length;
    if (otherLen == 0) return true;
    if ((start < 0) || (start >= len)) return false;
    if (start + otherLen > len) return false;
    StringImplementation otherImpl = other;
    for (int i = 0; i < otherLen; i++) {
      // We can use the unsafe _charCodeAt.
      if (_charCodeAt(start + i) != otherImpl._charCodeAt(i)) return false;
    }
    return true;
  }

  bool endsWith(String other) {
    return substringMatches(length - other.length, other);
  }

  bool startsWith(String other) {
    return substringMatches(0, other);
  }

  int indexOf(String other, [int start = 0]) {
    return _nativeIndexOf(other, start);
  }

  int lastIndexOf(String other, [int start = null]) {
    if (start === null) start = length - 1;
    return _nativeLastIndexOf(other, start);
  }

  int _nativeIndexOf(String other, int start) native;
  int _nativeLastIndexOf(String other, int start) native;

  bool isEmpty() {
    return length == 0;
  }

  String concat(String other) native;

  String operator +(Object obj) {
    return this.concat(obj.toString());
  }

  String substring(int startIndex, [int endIndex = null]) {
    if (endIndex == null) endIndex = this.length;

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

  String trim() native;

  bool contains(Pattern pattern, [int startIndex = 0]) {
    if (startIndex < 0 || startIndex > length) {
      throw new IndexOutOfRangeException(startIndex);
    }
    if (pattern is String) {
      return this.indexOf(pattern, startIndex) != -1;
    } else if (pattern is JSSyntaxRegExp) {
      JSSyntaxRegExp regExp = pattern;
      return regExp.hasMatch(_substringUnchecked(startIndex, length));
    } else {
      String substr = _substringUnchecked(startIndex, length);
      return !pattern.allMatches(substr).iterator().hasNext();
    }
  }

  String replaceFirst(Pattern from, String to) {
    if (from is String || from is JSSyntaxRegExp) {
      return _replace(from, to);
    } else {
      // TODO(floitsch): implement generic String.replace (with patterns).
      throw "StringImplementation.replace(Pattern) UNIMPLEMENTED";
    }
  }

  String replaceAll(Pattern from, String to) {
    if (from is String) {
      if (from == "") {
        if (this == "") {
          return to;
        } else {
          StringBuffer result = new StringBuffer();
          int len = length;
          result.add(to);
          for (int i = 0; i < len; i++) {
            result.add(this[i]);
            result.add(to);
          }
          return result.toString();
        }
      } else {
        return _replaceAll(from, to);
      }
    } else if (from is JSSyntaxRegExp) {
      return _replaceAll(from, to);
    } else {
      // TODO(floitsch): implement generic String.replace (with patterns).
      throw "StringImplementation.replaceAll(Pattern) UNIMPLEMENTED";
    }
  }

  List<String> split(Pattern pattern) {
    if (pattern is String || pattern is JSSyntaxRegExp) {
      return _split(pattern);
    } else {
      throw "StringImplementation.split(Pattern) UNIMPLEMENTED";
    }
  }

  Iterable<Match> allMatches(String str) {
    List<Match> result = [];
    if (this.isEmpty()) return result;
    int length = this.length;

    int ix = 0;
    while (ix < str.length) {
      int foundIx = str.indexOf(this, ix);
      if (foundIx < 0) break;
      // Call "toString" to coerce the "this" back to a primitive string.
      result.add(new _StringMatch(foundIx, str, this.toString()));
      ix = foundIx + length;
    }
    return result;
  }

  List<String> splitChars() {
    return _split("");
  }

  List<int> charCodes() {
    int len = length;
    List<int> result = new List<int>(len);
    for (int i = 0; i < len; i++) {
      // It is safe to call the private function (which doesn't do
      // range-checks).
      result[i] = _charCodeAt(i);
    }
    return result;
  }

  String toLowerCase() native;
  String toUpperCase() native;

  int hashCode() native;

  // Note: we can't just return 'this', because we want the primitive string
  // and not the wrapped String object.
  String toString() native;

  int compareTo(String other) native;

  static String _newFromValues(List<int> values) native;
  String _indexOperator(int index) native;
  int _charCodeAt(int index) native;
  String _substringUnchecked(int startIndex, int endIndex) native;
  String _replace(Pattern from, String to) native;
  String _replaceAll(Pattern from, String to) native;
  List<String> _split(Pattern pattern) native;

  get dynamic() { return toString(); }
}

class _StringJsUtil {
  static String toDartString(o) native {
    if (o === null) return "null";
    return o.toString();
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

  String group(int group_) {
    if (group_ != 0) {
      throw new IndexOutOfRangeException(group_);
    }
    return pattern;
  }

  List<String> groups(List<int> groups_) {
    List<String> result = new List<String>();
    for (int g in groups_) {
      result.add(group(g));
    }
    return result;
  }

  final int _start;
  final String str;
  final String pattern;
}
