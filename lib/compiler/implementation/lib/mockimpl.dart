// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Mocks of classes and interfaces that Leg cannot read directly.

// TODO(ahe): Remove this file.

class JSSyntaxRegExp implements RegExp {
  final String pattern;
  final bool multiLine;
  final bool ignoreCase;

  const JSSyntaxRegExp(String pattern,
                       [bool multiLine = false, bool ignoreCase = false])
    : this.pattern = pattern,
      this.multiLine = multiLine,
      this.ignoreCase = ignoreCase;

  JSSyntaxRegExp._globalVersionOf(JSSyntaxRegExp other)
      : this.pattern = other.pattern,
        this.multiLine = other.multiLine,
        this.ignoreCase = other.ignoreCase {
    regExpAttachGlobalNative(this);
  }

  Match firstMatch(String str) {
    List<String> m = regExpExec(this, checkString(str));
    if (m === null) return null;
    var matchStart = regExpMatchStart(m);
    // m.lastIndex only works with flag 'g'.
    var matchEnd = matchStart + m[0].length;
    return new MatchImplementation(pattern, str, matchStart, matchEnd, m);
  }

  bool hasMatch(String str) => regExpTest(this, checkString(str));

  String stringMatch(String str) {
    var match = firstMatch(str);
    return match === null ? null : match.group(0);
  }

  Iterable<Match> allMatches(String str) {
    checkString(str);
    return new _AllMatchesIterable(this, str);
  }

  _getNative() => regExpGetNative(this);
}

class MatchImplementation implements Match {
  const MatchImplementation(
      String this.pattern,
      String this.str,
      int this._start,
      int this._end,
      List<String> this._groups);

  final String pattern;
  final String str;
  final int _start;
  final int _end;
  final List<String> _groups;

  int start() => _start;
  int end() => _end;
  String group(int index) => _groups[index];
  String operator [](int index) => group(index);
  int groupCount() => _groups.length - 1;

  List<String> groups(List<int> groups) {
    List<String> out = [];
    for (int i in groups) {
      out.add(group(i));
    }
    return out;
  }
}

class _AllMatchesIterable implements Iterable<Match> {
  final JSSyntaxRegExp _re;
  final String _str;

  const _AllMatchesIterable(this._re, this._str);

  Iterator<Match> iterator() => new _AllMatchesIterator(_re, _str);
}

class _AllMatchesIterator implements Iterator<Match> {
  final RegExp _re;
  final String _str;
  Match _next;
  bool _done;

  _AllMatchesIterator(JSSyntaxRegExp re, String this._str)
    : _done = false, _re = new JSSyntaxRegExp._globalVersionOf(re);

  Match next() {
    if (!hasNext()) {
      throw const NoMoreElementsException();
    }

    // _next is set by #hasNext
    var next = _next;
    _next = null;
    return next;
  }

  bool hasNext() {
    if (_done) {
      return false;
    } else if (_next != null) {
      return true;
    }

    _next = _re.firstMatch(_str);
    if (_next == null) {
      _done = true;
      return false;
    } else {
      return true;
    }
  }
}

class ReceivePortFactory {
  factory ReceivePort() {
    throw 'factory ReceivePort is not implemented';
  }
}

class StringBase {
  static String createFromCharCodes(List<int> charCodes) {
    checkNull(charCodes);
    if (!isJsArray(charCodes)) {
      if (charCodes is !List) throw new IllegalArgumentException(charCodes);
      charCodes = new List.from(charCodes);
    }
    return Primitives.stringFromCharCodes(charCodes);
  }

  static String join(List<String> strings, String separator) {
    checkNull(strings);
    checkNull(separator);
    if (separator is !String) throw new IllegalArgumentException(separator);
    return stringJoinUnchecked(_toJsStringArray(strings), separator);
  }

  static String concatAll(List<String> strings) {
    return stringJoinUnchecked(_toJsStringArray(strings), "");
  }

  static List _toJsStringArray(List<String> strings) {
    checkNull(strings);
    var array;
    final length = strings.length;
    if (isJsArray(strings)) {
      array = strings;
      for (int i = 0; i < length; i++) {
        final string = strings[i];
        checkNull(string);
        if (string is !String) throw new IllegalArgumentException(string);
      }
    } else {
      array = new List(length);
      for (int i = 0; i < length; i++) {
        final string = strings[i];
        checkNull(string);
        if (string is !String) throw new IllegalArgumentException(string);
        array[i] = string;
      }
    }
    return array;
  }
}

class ListFactory<E> {
  factory List([int length]) => Primitives.newList(length);
  factory List.from(Iterable<E> other) {
    List<E> result = new List<E>();
    // TODO(ahe): Use for-in when it is implemented correctly.
    Iterator<E> iterator = other.iterator();
    while (iterator.hasNext()) {
      result.add(iterator.next());
    }
    return result;
  }
}
