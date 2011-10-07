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

  int _start(int group) {
    return _match[(group * _kMatchPair)];
  }

  int _end(int group) {
    return _match[(group * _kMatchPair) + 1];
  }

  String group(int group) {
    return str.substringUnchecked_(_start(group), _end(group));
  }

  String operator [](int group) {
    return str.substringUnchecked_(_start(group), _end(group));
  }

  List<String> groups(List<int> groups) {
    var groupsList = new List<String>(groups.length);
    for (int i = 0; i < groups.length; i++) {
      int grp_idx = groups[i];
      groupsList[i] = str.substringUnchecked_(_start(grp_idx), _end(grp_idx));
    }
    return groupsList;
  }

  int groupCount() {
    return regexp._groupCount;
  }

  final RegExp regexp;
  final String str;
  final List<int> _match;
  static final int _kMatchPair = 2;
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
    var jsregexMatches = new GrowableObjectArray<JSRegExpMatch>();
    List match = _ExecuteMatch(str, 0);
    if (match !== null) {
      jsregexMatches.add(new JSRegExpMatch(this, str, match));
      while (true) {
        match = _ExecuteMatch(str, match[1]);
        if (match === null) {
          break;
        }
        jsregexMatches.add(new JSRegExpMatch(this, str, match));
      }
    }
    return jsregexMatches;
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
