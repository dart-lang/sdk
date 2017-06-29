// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of _js_helper;

stringIndexOfStringUnchecked(receiver, other, startIndex) {
  return JS('int', '#.indexOf(#, #)', receiver, other, startIndex);
}

substring1Unchecked(receiver, startIndex) {
  return JS('String', '#.substring(#)', receiver, startIndex);
}

substring2Unchecked(receiver, startIndex, endIndex) {
  return JS('String', '#.substring(#, #)', receiver, startIndex, endIndex);
}

stringContainsStringUnchecked(receiver, other, startIndex) {
  return stringIndexOfStringUnchecked(receiver, other, startIndex) >= 0;
}

class StringMatch implements Match {
  const StringMatch(int this.start, String this.input, String this.pattern);

  int get end => start + pattern.length;
  String operator [](int g) => group(g);
  int get groupCount => 0;

  String group(int group_) {
    if (group_ != 0) {
      throw new RangeError.value(group_);
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

  final int start;
  final String input;
  final String pattern;
}

Iterable<Match> allMatchesInStringUnchecked(
    String pattern, String string, int startIndex) {
  return new _StringAllMatchesIterable(string, pattern, startIndex);
}

class _StringAllMatchesIterable extends Iterable<Match> {
  final String _input;
  final String _pattern;
  final int _index;

  _StringAllMatchesIterable(this._input, this._pattern, this._index);

  Iterator<Match> get iterator =>
      new _StringAllMatchesIterator(_input, _pattern, _index);

  Match get first {
    int index = stringIndexOfStringUnchecked(_input, _pattern, _index);
    if (index >= 0) {
      return new StringMatch(index, _input, _pattern);
    }
    throw IterableElementError.noElement();
  }
}

class _StringAllMatchesIterator implements Iterator<Match> {
  final String _input;
  final String _pattern;
  int _index;
  Match _current;

  _StringAllMatchesIterator(this._input, this._pattern, this._index);

  bool moveNext() {
    if (_index + _pattern.length > _input.length) {
      _current = null;
      return false;
    }
    var index = stringIndexOfStringUnchecked(_input, _pattern, _index);
    if (index < 0) {
      _index = _input.length + 1;
      _current = null;
      return false;
    }
    int end = index + _pattern.length;
    _current = new StringMatch(index, _input, _pattern);
    // Empty match, don't start at same location again.
    if (end == _index) end++;
    _index = end;
    return true;
  }

  Match get current => _current;
}

stringContainsUnchecked(receiver, other, startIndex) {
  if (other is String) {
    return stringContainsStringUnchecked(receiver, other, startIndex);
  } else if (other is JSSyntaxRegExp) {
    return other.hasMatch(receiver.substring(startIndex));
  } else {
    var substr = receiver.substring(startIndex);
    return other.allMatches(substr).isNotEmpty;
  }
}

stringReplaceJS(receiver, replacer, replacement) {
  // The JavaScript String.replace method recognizes replacement
  // patterns in the replacement string. Dart does not have that
  // behavior.
  replacement = JS('String', r'#.replace(/\$/g, "$$$$")', replacement);
  return JS('String', r'#.replace(#, #)', receiver, replacer, replacement);
}

stringReplaceFirstRE(receiver, regexp, replacement, startIndex) {
  var match = regexp._execGlobal(receiver, startIndex);
  if (match == null) return receiver;
  var start = match.start;
  var end = match.end;
  return stringReplaceRangeUnchecked(receiver, start, end, replacement);
}

/// Returns a string for a RegExp pattern that matches [string]. This is done by
/// escaping all RegExp metacharacters.
quoteStringForRegExp(string) {
  return JS('String', r'#.replace(/[[\]{}()*+?.\\^$|]/g, "\\$&")', string);
}

stringReplaceAllUnchecked(receiver, pattern, replacement) {
  checkString(replacement);
  if (pattern is String) {
    if (pattern == "") {
      if (receiver == "") {
        return JS('String', '#', replacement); // help type inference.
      } else {
        StringBuffer result = new StringBuffer('');
        int length = receiver.length;
        result.write(replacement);
        for (int i = 0; i < length; i++) {
          result.write(receiver[i]);
          result.write(replacement);
        }
        return result.toString();
      }
    } else {
      var quoted = quoteStringForRegExp(pattern);
      var replacer = JS('', "new RegExp(#, 'g')", quoted);
      return stringReplaceJS(receiver, replacer, replacement);
    }
  } else if (pattern is JSSyntaxRegExp) {
    var re = regExpGetGlobalNative(pattern);
    return stringReplaceJS(receiver, re, replacement);
  } else {
    checkNull(pattern);
    // TODO(floitsch): implement generic String.replace (with patterns).
    throw "String.replaceAll(Pattern) UNIMPLEMENTED";
  }
}

String _matchString(Match match) => match[0];
String _stringIdentity(String string) => string;

stringReplaceAllFuncUnchecked(receiver, pattern, onMatch, onNonMatch) {
  if (onMatch == null) onMatch = _matchString;
  if (onNonMatch == null) onNonMatch = _stringIdentity;
  if (pattern is String) {
    return stringReplaceAllStringFuncUnchecked(
        receiver, pattern, onMatch, onNonMatch);
  }
  // Placing the Pattern test here is indistinguishable from placing it at the
  // top of the method but it saves an extra check on the `pattern is String`
  // path.
  if (pattern is! Pattern) {
    throw new ArgumentError.value(pattern, 'pattern', 'is not a Pattern');
  }
  StringBuffer buffer = new StringBuffer('');
  int startIndex = 0;
  for (Match match in pattern.allMatches(receiver)) {
    buffer.write(onNonMatch(receiver.substring(startIndex, match.start)));
    buffer.write(onMatch(match));
    startIndex = match.end;
  }
  buffer.write(onNonMatch(receiver.substring(startIndex)));
  return buffer.toString();
}

stringReplaceAllEmptyFuncUnchecked(receiver, onMatch, onNonMatch) {
  // Pattern is the empty string.
  StringBuffer buffer = new StringBuffer('');
  int length = receiver.length;
  int i = 0;
  buffer.write(onNonMatch(""));
  while (i < length) {
    buffer.write(onMatch(new StringMatch(i, receiver, "")));
    // Special case to avoid splitting a surrogate pair.
    int code = receiver.codeUnitAt(i);
    if ((code & ~0x3FF) == 0xD800 && length > i + 1) {
      // Leading surrogate;
      code = receiver.codeUnitAt(i + 1);
      if ((code & ~0x3FF) == 0xDC00) {
        // Matching trailing surrogate.
        buffer.write(onNonMatch(receiver.substring(i, i + 2)));
        i += 2;
        continue;
      }
    }
    buffer.write(onNonMatch(receiver[i]));
    i++;
  }
  buffer.write(onMatch(new StringMatch(i, receiver, "")));
  buffer.write(onNonMatch(""));
  return buffer.toString();
}

stringReplaceAllStringFuncUnchecked(receiver, pattern, onMatch, onNonMatch) {
  int patternLength = pattern.length;
  if (patternLength == 0) {
    return stringReplaceAllEmptyFuncUnchecked(receiver, onMatch, onNonMatch);
  }
  int length = receiver.length;
  StringBuffer buffer = new StringBuffer('');
  int startIndex = 0;
  while (startIndex < length) {
    int position = stringIndexOfStringUnchecked(receiver, pattern, startIndex);
    if (position == -1) {
      break;
    }
    buffer.write(onNonMatch(receiver.substring(startIndex, position)));
    buffer.write(onMatch(new StringMatch(position, receiver, pattern)));
    startIndex = position + patternLength;
  }
  buffer.write(onNonMatch(receiver.substring(startIndex)));
  return buffer.toString();
}

stringReplaceFirstUnchecked(receiver, pattern, replacement, int startIndex) {
  if (pattern is String) {
    int index = stringIndexOfStringUnchecked(receiver, pattern, startIndex);
    if (index < 0) return receiver;
    int end = index + pattern.length;
    return stringReplaceRangeUnchecked(receiver, index, end, replacement);
  }
  if (pattern is JSSyntaxRegExp) {
    return startIndex == 0
        ? stringReplaceJS(receiver, regExpGetNative(pattern), replacement)
        : stringReplaceFirstRE(receiver, pattern, replacement, startIndex);
  }
  checkNull(pattern);
  Iterator<Match> matches = pattern.allMatches(receiver, startIndex).iterator;
  if (!matches.moveNext()) return receiver;
  Match match = matches.current;
  return receiver.replaceRange(match.start, match.end, replacement);
}

stringReplaceFirstMappedUnchecked(receiver, pattern, replace, int startIndex) {
  Iterator<Match> matches = pattern.allMatches(receiver, startIndex).iterator;
  if (!matches.moveNext()) return receiver;
  Match match = matches.current;
  String replacement = "${replace(match)}";
  return receiver.replaceRange(match.start, match.end, replacement);
}

stringJoinUnchecked(array, separator) {
  return JS('String', r'#.join(#)', array, separator);
}

String stringReplaceRangeUnchecked(
    String receiver, int start, int end, String replacement) {
  var prefix = JS('String', '#.substring(0, #)', receiver, start);
  var suffix = JS('String', '#.substring(#)', receiver, end);
  return "$prefix$replacement$suffix";
}
