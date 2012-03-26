// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class JSRegExpMatch implements Match {
  JSRegExpMatch(this.regexp, this.str, this._match);

  int start() {
    return _start(0);
  }

  int end() {
    return _end(0);
  }

  int _start(int groupIdx) {
    return _match[(groupIdx * MATCH_PAIR)];
  }

  int _end(int groupIdx) {
    return _match[(groupIdx * MATCH_PAIR) + 1];
  }

  String group(int groupIdx) {
    if (groupIdx < 0 || groupIdx > regexp._groupCount) {
      throw new IndexOutOfRangeException(groupIdx);
    }
    int startIndex = _start(groupIdx);
    int endIndex = _end(groupIdx);
    if (startIndex == -1) {
      assert(endIndex == -1);
      return null;
    }
    return str.substringUnchecked_(startIndex, endIndex);
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

  int groupCount() {
    return regexp._groupCount;
  }

  final RegExp regexp;
  final String str;
  final List<int> _match;
  static final int MATCH_PAIR = 2;
}


class JSSyntaxRegExp implements RegExp {
  const factory JSSyntaxRegExp(
      String pattern,
      [bool multiLine = false,
       bool ignoreCase = false]) native "JSSyntaxRegExp_factory";

  Match firstMatch(String str) {
    List match = _ExecuteMatch(str, 0);
    if (match === null) {
      return null;
    }
    return new JSRegExpMatch(this, str, match);
  }

  Iterable<Match> allMatches(String str) {
    List<Match> result = new List<Match>();
    int length = str.length;
    int startIndex = 0;
    while (true) {
      List match = _ExecuteMatch(str, startIndex);
      if (match == null) {
        break;
      }
      result.add(new JSRegExpMatch(this, str, match));
      int endIndex = match[1];
      if (endIndex == length) {
        break;
      } else if (match[0] == endIndex) {
        ++startIndex;  // empty match, advance and restart
      } else {
        startIndex = endIndex;
      }
    }
    return result;
  }

  bool hasMatch(String str) {
    List match = _ExecuteMatch(str, 0);
    return (match === null) ? false : true;
  }

  String stringMatch(String str) {
    List match = _ExecuteMatch(str, 0);
    if (match === null) {
      return null;
    }
    return str.substringUnchecked_(match[0], match[1]);
  }

  String get pattern() native "JSSyntaxRegExp_getPattern";

  bool get multiLine() native "JSSyntaxRegExp_multiLine";

  bool get ignoreCase() native "JSSyntaxRegExp_ignoreCase";

  int get _groupCount() native "JSSyntaxRegExp_getGroupCount";

  List _ExecuteMatch(String str, int start_index)
      native "JSSyntaxRegExp_ExecuteMatch";
}
