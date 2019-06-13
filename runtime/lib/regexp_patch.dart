// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// part of "core_patch.dart";

@patch
class RegExp {
  @patch
  factory RegExp(String source,
      {bool multiLine: false,
      bool caseSensitive: true,
      bool unicode: false,
      bool dotAll: false}) {
    _RegExpHashKey key =
        new _RegExpHashKey(source, multiLine, caseSensitive, unicode, dotAll);
    _RegExpHashValue value = _cache[key];

    if (value == null) {
      if (_cache.length > _MAX_CACHE_SIZE) {
        _RegExpHashKey lastKey = _recentlyUsed.last;
        _recentlyUsed.remove(lastKey);
        _cache.remove(lastKey);
      }

      value = new _RegExpHashValue(
          new _RegExp(source,
              multiLine: multiLine,
              caseSensitive: caseSensitive,
              unicode: unicode,
              dotAll: dotAll),
          key);
      _cache[key] = value;
    } else {
      value.key.unlink();
    }

    assert(value != null);

    _recentlyUsed.addFirst(value.key);
    assert(_recentlyUsed.length == _cache.length);

    // TODO(zerny): We might not want to canonicalize regexp objects.
    return value.regexp;
  }

  /**
   * Finds the index of the first RegExp-significant char in [text].
   *
   * Starts looking from [start]. Returns `text.length` if no character
   * is found that has special meaning in RegExp syntax.
   */
  static int _findEscapeChar(String text, int start) {
    // Table where each character in the range U+0000 to U+007f is represented
    // by whether it needs to be escaped in a regexp.
    // The \x00 characters means escacped, and \x01 means non-escaped.
    const escapes =
        "\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01"
        "\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01"
        //                 $               (   )   *   +           .
        "\x01\x01\x01\x01\x00\x01\x01\x01\x00\x00\x00\x00\x01\x01\x00\x01"
        //                                                             ?
        "\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x00"
        "\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01"
        //                                             [   \   ]   ^
        "\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x00\x00\x00\x00\x01"
        "\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01"
        //                                             {   |   }
        "\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x00\x00\x00\x01\x01";
    for (int i = start; i < text.length; i++) {
      int char = text.codeUnitAt(i);
      if (char <= 0x7f && escapes.codeUnitAt(char) == 0) return i;
    }
    return text.length;
  }

  @patch
  static String escape(String text) {
    int escapeCharIndex = _findEscapeChar(text, 0);
    // If the text contains no characters needing escape, return it directly.
    if (escapeCharIndex == text.length) return text;

    var buffer = new StringBuffer();
    int previousSliceEndIndex = 0;
    do {
      // Copy characters from previous escape to current escape into result.
      // This includes the previously escaped character.
      buffer.write(text.substring(previousSliceEndIndex, escapeCharIndex));
      // Prepare the current character to be escaped by prefixing it with a '\'.
      buffer.write(r"\");
      previousSliceEndIndex = escapeCharIndex;
      escapeCharIndex = _findEscapeChar(text, escapeCharIndex + 1);
    } while (escapeCharIndex < text.length);
    // Copy tail of string into result.
    buffer.write(text.substring(previousSliceEndIndex, escapeCharIndex));
    return buffer.toString();
  }

  // Regular expression objects are stored in a cache of up to _MAX_CACHE_SIZE
  // elements using an LRU eviction strategy.
  // TODO(zerny): Do not impose a fixed limit on the number of cached objects.
  // Other possibilities could be limiting by the size of the regexp objects,
  // or imposing a lower time bound for the most recent use under which a regexp
  // may not be removed from the cache.
  // TODO(zerny): Use self-sizing cache similar to _AccessorCache in
  // mirrors_impl.dart.
  static const int _MAX_CACHE_SIZE = 256;
  static final Map<_RegExpHashKey, _RegExpHashValue> _cache =
      new HashMap<_RegExpHashKey, _RegExpHashValue>();
  static final LinkedList<_RegExpHashKey> _recentlyUsed =
      new LinkedList<_RegExpHashKey>();

  int get _groupCount;
  Iterable<String> get _groupNames;
  int _groupNameIndex(String name);
}

// Represents both a key in the regular expression cache as well as its
// corresponding entry in the LRU list.
class _RegExpHashKey extends LinkedListEntry<_RegExpHashKey> {
  final String pattern;
  final bool multiLine;
  final bool caseSensitive;
  final bool unicode;
  final bool dotAll;

  _RegExpHashKey(this.pattern, this.multiLine, this.caseSensitive, this.unicode,
      this.dotAll);

  int get hashCode => pattern.hashCode;
  bool operator ==(that) {
    return (that is _RegExpHashKey) &&
        (this.pattern == that.pattern) &&
        (this.multiLine == that.multiLine) &&
        (this.caseSensitive == that.caseSensitive) &&
        (this.unicode == that.unicode) &&
        (this.dotAll == that.dotAll);
  }
}

// Represents a value in the regular expression cache. Contains a pointer
// back to the key in order to access the corresponding LRU entry.
class _RegExpHashValue {
  final _RegExp regexp;
  final _RegExpHashKey key;

  _RegExpHashValue(this.regexp, this.key);
}

class _RegExpMatch implements RegExpMatch {
  _RegExpMatch._(this._regexp, this.input, this._match);

  int get start => _start(0);
  int get end => _end(0);

  int _start(int groupIdx) {
    return _match[(groupIdx * _MATCH_PAIR)];
  }

  int _end(int groupIdx) {
    return _match[(groupIdx * _MATCH_PAIR) + 1];
  }

  String group(int groupIdx) {
    if (groupIdx < 0 || groupIdx > _regexp._groupCount) {
      throw new RangeError.value(groupIdx);
    }
    int startIndex = _start(groupIdx);
    int endIndex = _end(groupIdx);
    if (startIndex == -1) {
      assert(endIndex == -1);
      return null;
    }
    return input._substringUnchecked(startIndex, endIndex);
  }

  String operator [](int groupIdx) {
    return this.group(groupIdx);
  }

  List<String> groups(List<int> groupsSpec) {
    var groupsList = new List<String>(groupsSpec.length);
    for (int i = 0; i < groupsSpec.length; i++) {
      groupsList[i] = group(groupsSpec[i]);
    }
    return groupsList;
  }

  int get groupCount => _regexp._groupCount;

  Pattern get pattern => _regexp;

  String namedGroup(String name) {
    var idx = _regexp._groupNameIndex(name);
    if (idx < 0) {
      throw ArgumentError("Not a capture group name: ${name}");
    }
    return group(idx);
  }

  Iterable<String> get groupNames {
    return _regexp._groupNames;
  }

  final RegExp _regexp;
  final String input;
  final List<int> _match;
  static const int _MATCH_PAIR = 2;
}

@pragma("vm:entry-point")
class _RegExp implements RegExp {
  factory _RegExp(String pattern,
      {bool multiLine: false,
      bool caseSensitive: true,
      bool unicode: false,
      bool dotAll: false}) native "RegExp_factory";

  RegExpMatch firstMatch(String str) {
    if (str is! String) throw new ArgumentError(str);
    List match = _ExecuteMatch(str, 0);
    if (match == null) {
      return null;
    }
    return new _RegExpMatch._(this, str, match);
  }

  Iterable<RegExpMatch> allMatches(String string, [int start = 0]) {
    if (string is! String) throw new ArgumentError(string);
    if (start is! int) throw new ArgumentError(start);
    if (0 > start || start > string.length) {
      throw new RangeError.range(start, 0, string.length);
    }
    return new _AllMatchesIterable(this, string, start);
  }

  RegExpMatch matchAsPrefix(String string, [int start = 0]) {
    if (string is! String) throw new ArgumentError(string);
    if (start is! int) throw new ArgumentError(start);
    if (start < 0 || start > string.length) {
      throw new RangeError.range(start, 0, string.length);
    }
    List<int> list = _ExecuteMatchSticky(string, start);
    if (list == null) return null;
    return new _RegExpMatch._(this, string, list);
  }

  bool hasMatch(String str) {
    if (str is! String) throw new ArgumentError(str);
    List match = _ExecuteMatch(str, 0);
    return (match == null) ? false : true;
  }

  String stringMatch(String str) {
    if (str is! String) throw new ArgumentError(str);
    List match = _ExecuteMatch(str, 0);
    if (match == null) {
      return null;
    }
    return str._substringUnchecked(match[0], match[1]);
  }

  String get pattern native "RegExp_getPattern";

  bool get isMultiLine native "RegExp_getIsMultiLine";

  bool get isCaseSensitive native "RegExp_getIsCaseSensitive";

  bool get isUnicode native "RegExp_getIsUnicode";

  bool get isDotAll native "RegExp_getIsDotAll";

  int get _groupCount native "RegExp_getGroupCount";

  // Returns a List [String, int, String, int, ...] where each
  // String is the name of a capture group and the following
  // int is that capture group's index.
  List get _groupNameList native "RegExp_getGroupNameMap";

  Iterable<String> get _groupNames sync* {
    final nameList = _groupNameList;
    for (var i = 0; i < nameList.length; i += 2) {
      yield nameList[i] as String;
    }
  }

  int _groupNameIndex(String name) {
    var nameList = _groupNameList;
    for (var i = 0; i < nameList.length; i += 2) {
      if (name == nameList[i]) {
        return nameList[i + 1];
      }
    }
    return -1;
  }

  // Byte map of one byte characters with a 0xff if the character is a word
  // character (digit, letter or underscore) and 0x00 otherwise.
  // Used by generated RegExp code.
  static const List<int> _wordCharacterMap = const <int>[
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,

    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, // '0' - '7'
    0xff, 0xff, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // '8' - '9'

    0x00, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, // 'A' - 'G'
    0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, // 'H' - 'O'
    0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, // 'P' - 'W'
    0xff, 0xff, 0xff, 0x00, 0x00, 0x00, 0x00, 0xff, // 'X' - 'Z', '_'

    0x00, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, // 'a' - 'g'
    0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, // 'h' - 'o'
    0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, // 'p' - 'w'
    0xff, 0xff, 0xff, 0x00, 0x00, 0x00, 0x00, 0x00, // 'x' - 'z'
    // Latin-1 range
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,

    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,

    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,

    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
  ];

  List _ExecuteMatch(String str, int start_index) native "RegExp_ExecuteMatch";

  List _ExecuteMatchSticky(String str, int start_index)
      native "RegExp_ExecuteMatchSticky";
}

class _AllMatchesIterable extends IterableBase<RegExpMatch> {
  final _RegExp _re;
  final String _str;
  final int _start;

  _AllMatchesIterable(this._re, this._str, this._start);

  Iterator<RegExpMatch> get iterator =>
      new _AllMatchesIterator(_re, _str, _start);
}

class _AllMatchesIterator implements Iterator<RegExpMatch> {
  final String _str;
  int _nextIndex;
  _RegExp _re;
  RegExpMatch _current;

  _AllMatchesIterator(this._re, this._str, this._nextIndex);

  RegExpMatch get current => _current;

  static bool _isLeadSurrogate(int c) {
    return c >= 0xd800 && c <= 0xdbff;
  }

  static bool _isTrailSurrogate(int c) {
    return c >= 0xdc00 && c <= 0xdfff;
  }

  bool moveNext() {
    if (_re == null) return false; // Cleared after a failed match.
    if (_nextIndex <= _str.length) {
      var match = _re._ExecuteMatch(_str, _nextIndex);
      if (match != null) {
        _current = new _RegExpMatch._(_re, _str, match);
        _nextIndex = _current.end;
        if (_nextIndex == _current.start) {
          // Zero-width match. Advance by one more, unless the regexp
          // is in unicode mode and it would put us within a surrogate
          // pair. In that case, advance past the code point as a whole.
          if (_re.isUnicode &&
              _nextIndex + 1 < _str.length &&
              _isLeadSurrogate(_str.codeUnitAt(_nextIndex)) &&
              _isTrailSurrogate(_str.codeUnitAt(_nextIndex + 1))) {
            _nextIndex++;
          }
          _nextIndex++;
        }
        return true;
      }
    }
    _current = null;
    _re = null;
    return false;
  }
}
