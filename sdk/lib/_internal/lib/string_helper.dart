// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of _js_helper;

class StringMatch implements Match {
  const StringMatch(int this.start,
                    String this.input,
                    String this.pattern);

  int get end => start + pattern.length;
  String operator[](int g) => group(g);
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

List<Match> allMatchesInStringUnchecked(String needle, String haystack,
                                        int startIndex) {
  // Copied from StringBase.allMatches in
  // /runtime/lib/string_base.dart
  List<Match> result = new List<Match>();
  int length = haystack.length;
  int patternLength = needle.length;
  while (true) {
    int position = haystack.indexOf(needle, startIndex);
    if (position == -1) {
      break;
    }
    result.add(new StringMatch(position, haystack, needle));
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

stringContainsUnchecked(receiver, other, startIndex) {
  if (other is String) {
    return receiver.indexOf(other, startIndex) != -1;
  } else if (other is JSSyntaxRegExp) {
    return other.hasMatch(receiver.substring(startIndex));
  } else {
    var substr = receiver.substring(startIndex);
    return other.allMatches(substr).isNotEmpty;
  }
}

stringReplaceJS(receiver, replacer, to) {
  // The JavaScript String.replace method recognizes replacement
  // patterns in the replacement string. Dart does not have that
  // behavior.
  to = JS('String', r'#.replace(/\$/g, "$$$$")', to);
  return JS('String', r'#.replace(#, #)', receiver, replacer, to);
}

const String ESCAPE_REGEXP = r'[[\]{}()*+?.\\^$|]';

stringReplaceAllUnchecked(receiver, from, to) {
  checkString(to);
  if (from is String) {
    if (from == "") {
      if (receiver == "") {
        return to;
      } else {
        StringBuffer result = new StringBuffer();
        int length = receiver.length;
        result.write(to);
        for (int i = 0; i < length; i++) {
          result.write(receiver[i]);
          result.write(to);
        }
        return result.toString();
      }
    } else {
      var quoter = JS('', "new RegExp(#, 'g')", ESCAPE_REGEXP);
      var quoted = JS('String', r'#.replace(#, "\\$&")', from, quoter);
      var replacer = JS('', "new RegExp(#, 'g')", quoted);
      return stringReplaceJS(receiver, replacer, to);
    }
  } else if (from is JSSyntaxRegExp) {
    var re = regExpGetGlobalNative(from);
    return stringReplaceJS(receiver, re, to);
  } else {
    checkNull(from);
    // TODO(floitsch): implement generic String.replace (with patterns).
    throw "String.replaceAll(Pattern) UNIMPLEMENTED";
  }
}

String _matchString(Match match) => match[0];
String _stringIdentity(String string) => string;

stringReplaceAllFuncUnchecked(receiver, pattern, onMatch, onNonMatch) {
  if (pattern is! Pattern) {
    throw new ArgumentError("${pattern} is not a Pattern");
  }
  if (onMatch == null) onMatch = _matchString;
  if (onNonMatch == null) onNonMatch = _stringIdentity;
  if (pattern is String) {
    return stringReplaceAllStringFuncUnchecked(receiver, pattern,
                                               onMatch, onNonMatch);
  }
  StringBuffer buffer = new StringBuffer();
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
  StringBuffer buffer = new StringBuffer();
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
  StringBuffer buffer = new StringBuffer();
  int startIndex = 0;
  while (startIndex < length) {
    int position = receiver.indexOf(pattern, startIndex);
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


stringReplaceFirstUnchecked(receiver, from, to) {
  if (from is String) {
    return stringReplaceJS(receiver, from, to);
  } else if (from is JSSyntaxRegExp) {
    var re = regExpGetNative(from);
    return stringReplaceJS(receiver, re, to);
  } else {
    checkNull(from);
    // TODO(floitsch): implement generic String.replace (with patterns).
    throw "String.replace(Pattern) UNIMPLEMENTED";
  }
}

stringJoinUnchecked(array, separator) {
  return JS('String', r'#.join(#)', array, separator);
}
