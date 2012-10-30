// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class _JSRegExpMatch implements Match {
  _JSRegExpMatch(this.regexp, this.str, this._match);

  int get start => _start(0);
  int get end => _end(0);

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
    // TODO(ajohnsen): Use _substringUnchecked when regexp is in core.
    return str.substring(startIndex, endIndex);
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

  int get groupCount => regexp._groupCount;

  String get pattern => regexp.pattern;

  final RegExp regexp;
  final String str;
  final List<int> _match;
  static const int MATCH_PAIR = 2;
}


patch class JSSyntaxRegExp {
  /* patch */ const factory JSSyntaxRegExp(
      String pattern,
      {bool multiLine: false,
       bool ignoreCase: false}) native "JSSyntaxRegExp_factory";

  /* patch */ Match firstMatch(String str) {
    List match = _ExecuteMatch(str, 0);
    if (match === null) {
      return null;
    }
    return new _JSRegExpMatch(this, str, match);
  }

  /* patch */ Iterable<Match> allMatches(String str) {
    List<Match> result = new List<Match>();
    int length = str.length;
    int startIndex = 0;
    while (true) {
      List match = _ExecuteMatch(str, startIndex);
      if (match == null) {
        break;
      }
      result.add(new _JSRegExpMatch(this, str, match));
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

  /* patch */ bool hasMatch(String str) {
    List match = _ExecuteMatch(str, 0);
    return (match === null) ? false : true;
  }

  /* patch */ String stringMatch(String str) {
    List match = _ExecuteMatch(str, 0);
    if (match === null) {
      return null;
    }
    // TODO(ajohnsen): Use _substringUnchecked when regexp is in core.
    return str.substring(match[0], match[1]);
  }

  /* patch */ String get pattern native "JSSyntaxRegExp_getPattern";

  /* patch */ bool get multiLine native "JSSyntaxRegExp_multiLine";

  /* patch */ bool get ignoreCase native "JSSyntaxRegExp_ignoreCase";

  int get _groupCount native "JSSyntaxRegExp_getGroupCount";

  List _ExecuteMatch(String str, int start_index)
      native "JSSyntaxRegExp_ExecuteMatch";
}
