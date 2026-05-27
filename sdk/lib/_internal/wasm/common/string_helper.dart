// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart._string_helper;

import "dart:_error_utils";
import "dart:_internal" show IterableElementError, unsafeCast;
import 'dart:_string' show StringUncheckedOperations;

class StringMatch implements Match {
  const StringMatch(this.start, this.input, this.pattern);

  int get end => start + pattern.length;
  String operator [](int g) {
    IndexErrorUtils.checkIndex(g, 1);
    return pattern;
  }

  int get groupCount => 0;

  String group(int group) => this[group];

  List<String> groups(List<int> groups) {
    List<String> result = <String>[];
    for (int g in groups) {
      result.add(this[g]);
    }
    return result;
  }

  final int start;
  final String input;
  final String pattern;
}

class StringAllMatchesIterable extends Iterable<Match> {
  final String _input;
  final String _pattern;
  final int _index;

  StringAllMatchesIterable(this._input, this._pattern, this._index);

  Iterator<Match> get iterator =>
      StringAllMatchesIterator(_input, _pattern, _index);

  Match get first {
    int index = _input.indexOf(_pattern, _index);
    if (index >= 0) {
      return StringMatch(index, _input, _pattern);
    }
    throw IterableElementError.noElement();
  }
}

class StringAllMatchesIterator implements Iterator<Match> {
  final String _input;
  final String _pattern;
  int _index;
  Match? _current;

  StringAllMatchesIterator(this._input, this._pattern, this._index);

  bool moveNext() {
    if (_index + _pattern.length > _input.length) {
      _current = null;
      return false;
    }
    var index = _input.indexOf(_pattern, _index);
    if (index < 0) {
      _index = _input.length + 1;
      _current = null;
      return false;
    }
    int end = index + _pattern.length;
    _current = StringMatch(index, _input, _pattern);
    // Empty match, don't start at same location again.
    if (end == _index) end++;
    _index = end;
    return true;
  }

  Match get current => _current as Match;
}

int stringCombineHashes(int hash, int other_hash) {
  hash += other_hash;
  hash += hash << 10;
  hash ^= (hash & 0xFFFFFFFF) >>> 6;
  return hash;
}

int stringFinalizeHash(int hash) {
  hash += hash << 3;
  hash ^= (hash & 0xFFFFFFFF) >>> 11;
  hash += hash << 15;
  hash &= 0x3FFFFFFF;
  return hash == 0 ? 1 : hash;
}

String splitMapJoinImpl(
  String source,
  Pattern from,
  String Function(Match)? onMatch,
  String Function(String)? onNonMatch,
) {
  if (onMatch == null) onMatch = _matchString;
  if (onNonMatch == null) onNonMatch = _stringIdentity;
  if (from is String) {
    final patternLength = from.length;
    if (patternLength == 0) {
      // Pattern is the empty string.
      StringBuffer buffer = StringBuffer();
      int i = 0;
      buffer.write(onNonMatch(""));
      final length = source.length;
      while (i < length) {
        buffer.write(onMatch(StringMatch(i, source, "")));
        // Special case to avoid splitting a surrogate pair.
        int code = source.codeUnitAt(i);
        if ((code & ~0x3FF) == 0xD800 && length > i + 1) {
          // Leading surrogate;
          code = source.codeUnitAt(i + 1);
          if ((code & ~0x3FF) == 0xDC00) {
            // Matching trailing surrogate.
            buffer.write(onNonMatch(source.substring(i, i + 2)));
            i += 2;
            continue;
          }
        }
        buffer.write(onNonMatch(source[i]));
        i++;
      }
      buffer.write(onMatch(StringMatch(i, source, "")));
      buffer.write(onNonMatch(""));
      return buffer.toString();
    }
    StringBuffer buffer = StringBuffer();
    int startIndex = 0;
    final length = source.length;
    while (startIndex < length) {
      int position = source.indexOf(from, startIndex);
      if (position == -1) {
        break;
      }
      buffer.write(onNonMatch(source.substring(startIndex, position)));
      buffer.write(onMatch(StringMatch(position, source, from)));
      startIndex = position + patternLength;
    }
    buffer.write(onNonMatch(source.substring(startIndex)));
    return buffer.toString();
  }
  StringBuffer buffer = StringBuffer();
  int startIndex = 0;
  for (Match match in from.allMatches(source)) {
    buffer.write(onNonMatch(source.substring(startIndex, match.start)));
    buffer.write(onMatch(match));
    startIndex = match.end;
  }
  buffer.write(onNonMatch(source.substring(startIndex)));
  return buffer.toString();
}

/// Implementation of [String.split] for patterns where no specialized JS
/// implementation exists.
List<String> genericSplitImpl(String source, Pattern pattern) {
  final result = <String>[];
  // End of most recent match. That is, start of next part to add to result.
  int start = 0;
  // Length of most recent match.
  // Set >0, so no match on the empty string causes the result to be [""].
  int length = 1;
  for (var match in pattern.allMatches(source)) {
    int matchStart = match.start;
    int matchEnd = match.end;
    length = matchEnd - matchStart;
    if (length == 0 && start == matchStart) {
      // An empty match right after another match is ignored.
      // This includes an empty match at the start of the string.
      continue;
    }
    int end = matchStart;
    result.add(source.substring(start, end));
    start = matchEnd;
  }
  if (start < source.length || length > 0) {
    // An empty match at the end of the string does not cause a "" at the
    // end.  A non-empty match ending at the end of the string does add a
    // "".
    result.add(source.substring(start));
  }
  return result;
}

// Characters with Whitespace property (Unicode 6.3).
// 0009..000D    ; White_Space # Cc       <control-0009>..<control-000D>
// 0020          ; White_Space # Zs       SPACE
// 0085          ; White_Space # Cc       <control-0085>
// 00A0          ; White_Space # Zs       NO-BREAK SPACE
// 1680          ; White_Space # Zs       OGHAM SPACE MARK
// 2000..200A    ; White_Space # Zs       EN QUAD..HAIR SPACE
// 2028          ; White_Space # Zl       LINE SEPARATOR
// 2029          ; White_Space # Zp       PARAGRAPH SEPARATOR
// 202F          ; White_Space # Zs       NARROW NO-BREAK SPACE
// 205F          ; White_Space # Zs       MEDIUM MATHEMATICAL SPACE
// 3000          ; White_Space # Zs       IDEOGRAPHIC SPACE
//
// BOM: 0xFEFF
bool isWhitespace(int codeUnit) {
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

const int spaceCodeUnit = 0x20;
const int carriageReturnCodeUnit = 0x0D;
const int nelCodeUnit = 0x85;

/// Finds the index of the first non-whitespace character, or the
/// end of the string. Start looking at position [index].
int skipLeadingWhitespace(String string, int index) {
  final stringLength = string.length;
  while (index < stringLength) {
    int codeUnit = string.codeUnitAtUnchecked(index);
    if (codeUnit != spaceCodeUnit &&
        codeUnit != carriageReturnCodeUnit &&
        !isWhitespace(codeUnit)) {
      break;
    }
    index++;
  }
  return index;
}

/// Finds the index after the last non-whitespace character, or 0.
/// Start looking at position [index - 1] to [from].
int skipTrailingWhitespace(String string, int index, [int from = 0]) {
  while (index > from) {
    int codeUnit = string.codeUnitAtUnchecked(index - 1);
    if (codeUnit != spaceCodeUnit &&
        codeUnit != carriageReturnCodeUnit &&
        !isWhitespace(codeUnit)) {
      break;
    }
    index--;
  }
  return index;
}

String _matchString(Match match) => match[0]!;

String _stringIdentity(String string) => string;
