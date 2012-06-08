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
    var result = "";
    var first = true;
    for (var string in strings) {
      checkNull(string);
      if (string is !String) throw new IllegalArgumentException(string);
      if (!first) result += separator; // TODO(ahe): Use string buffer.
      result += string; // TODO(ahe): Use string buffer.
      first = false;
    }
    return result;
  }

  static String concatAll(List<String> strings) {
    checkNull(strings);
    var result = "";
    for (var string in strings) {
      checkNull(string);
      if (string is !String) throw new IllegalArgumentException(string);
      result = '$result$string'; // TODO(ahe): Use string buffer.
    }
    return result;
  }
}

class TimeZoneImplementation implements TimeZone {
  const TimeZoneImplementation.utc() : isUtc = true;
  TimeZoneImplementation.local() : isUtc = false;

  bool operator ==(Object other) {
    if (!(other is TimeZoneImplementation)) return false;
    return isUtc == other.isUtc;
  }

  final bool isUtc;
}

class DateImplementation implements Date {
  final int value;
  final bool _isUtc;

  DateImplementation(int years,
                     [int month = 1,
                      int day = 1,
                      int hours = 0,
                      int minutes = 0,
                      int seconds = 0,
                      int milliseconds = 0,
                      bool isUtc = false])
      : this._isUtc = checkNull(isUtc),
        value = Primitives.valueFromDecomposedDate(
            years, month, day, hours, minutes, seconds, milliseconds, isUtc) {
    _asJs();
  }

  DateImplementation.withTimeZone(int years,
                                  int month,
                                  int day,
                                  int hours,
                                  int minutes,
                                  int seconds,
                                  int milliseconds,
                                  TimeZoneImplementation timeZone)
      : this(years, month, day, hours, minutes, seconds, milliseconds,
             timeZone.isUtc);

  DateImplementation.now()
      : _isUtc = false,
        value = Primitives.dateNow() {
    _asJs();
  }

  factory DateImplementation.fromString(String formattedString) {
    // Read in (a subset of) ISO 8601.
    // Examples:
    //    - "2012-02-27 13:27:00"
    //    - "2012-02-27 13:27:00.423z"
    //    - "20120227 13:27:00"
    //    - "20120227T132700"
    //    - "20120227"
    //    - "2012-02-27T14Z"
    //    - "-123450101 00:00:00 Z"  // In the year -12345.
    final RegExp re = const RegExp(
        @'^([+-]?\d?\d\d\d\d)-?(\d\d)-?(\d\d)' // The day part.
        @'(?:[ T](\d\d)(?::?(\d\d)(?::?(\d\d)(.\d{1,6})?)?)? ?([zZ])?)?$');
    Match match = re.firstMatch(formattedString);
    if (match !== null) {
      int parseIntOrZero(String matched) {
        // TODO(floitsch): we should not need to test against the empty string.
        if (matched === null || matched == "") return 0;
        return Math.parseInt(matched);
      }

      double parseDoubleOrZero(String matched) {
        // TODO(floitsch): we should not need to test against the empty string.
        if (matched === null || matched == "") return 0.0;
        return Math.parseDouble(matched);
      }

      int years = Math.parseInt(match[1]);
      int month = Math.parseInt(match[2]);
      int day = Math.parseInt(match[3]);
      int hours = parseIntOrZero(match[4]);
      int minutes = parseIntOrZero(match[5]);
      int seconds = parseIntOrZero(match[6]);
      bool addOneMillisecond = false;
      int milliseconds = (parseDoubleOrZero(match[7]) * 1000).round().toInt();
      if (milliseconds == 1000) {
        addOneMillisecond = true;
        milliseconds = 999;
      }
      // TODO(floitsch): we should not need to test against the empty string.
      bool isUtc = (match[8] !== null) && (match[8] != "");
      int epochValue = Primitives.valueFromDecomposedDate(
          years, month, day, hours, minutes, seconds, milliseconds, isUtc);
      if (epochValue === null) {
        throw new IllegalArgumentException(formattedString);
      }
      if (addOneMillisecond) epochValue++;
      return new DateImplementation.fromEpoch(epochValue, isUtc);
    } else {
      throw new IllegalArgumentException(formattedString);
    }
  }

  DateImplementation.fromEpoch(this.value, [bool isUtc = false])
      : _isUtc = checkNull(isUtc);

  bool operator ==(other) {
    if (!(other is DateImplementation)) return false;
    return (value == other.value);
  }

  bool operator <(Date other) => value < other.value;

  bool operator <=(Date other) => value <= other.value;

  bool operator >(Date other) => value > other.value;

  bool operator >=(Date other) => value >= other.value;

  int compareTo(Date other) => value.compareTo(other.value);

  int hashCode() => value;

  Date toLocal() {
    if (isUtc()) return new DateImplementation.fromEpoch(value, false);
    return this;
  }

  Date toUtc() {
    if (isUtc()) return this;
    return new DateImplementation.fromEpoch(value, true);
  }

  Date changeTimeZone(TimeZone targetTimeZone) {
    if (targetTimeZone === null) {
      targetTimeZone = new TimeZoneImplementation.local();
    }
    return new Date.fromEpoch(value, targetTimeZone.isUtc);
  }

  String get timeZoneName() {
    if (isUtc()) return "UTC";
    return Primitives.getTimeZoneName(this);
  }

  Duration get timeZoneOffset() {
    if (isUtc()) return new Duration(0);
    return new Duration(minutes: Primitives.getTimeZoneOffsetInMinutes(this));
  }

  int get year() => Primitives.getYear(this);

  int get month() => Primitives.getMonth(this);

  int get day() => Primitives.getDay(this);

  int get hours() => Primitives.getHours(this);

  int get minutes() => Primitives.getMinutes(this);

  int get seconds() => Primitives.getSeconds(this);

  int get milliseconds() => Primitives.getMilliseconds(this);

  int get weekday() {
    // Adjust by one because JS weeks start on Sunday.
    var day = Primitives.getWeekday(this);
    return (day + 6) % 7;
  }

  bool isUtc() => _isUtc;

  String toString() {
    String fourDigits(int n) {
      int absN = n.abs();
      String sign = n < 0 ? "-" : "";
      if (absN >= 1000) return "$n";
      if (absN >= 100) return "${sign}0$absN";
      if (absN >= 10) return "${sign}00$absN";
      if (absN >= 1) return "${sign}000$absN";
      throw new IllegalArgumentException(n);
    }

    String threeDigits(int n) {
      if (n >= 100) return "${n}";
      if (n >= 10) return "0${n}";
      return "00${n}";
    }

    String twoDigits(int n) {
      if (n >= 10) return "${n}";
      return "0${n}";
    }

    String y = fourDigits(year);
    String m = twoDigits(month);
    String d = twoDigits(day);
    String h = twoDigits(hours);
    String min = twoDigits(minutes);
    String sec = twoDigits(seconds);
    String ms = threeDigits(milliseconds);
    if (isUtc()) {
      return "$y-$m-$d $h:$min:$sec.${ms}Z";
    } else {
      return "$y-$m-$d $h:$min:$sec.$ms";
    }
  }

  // Adds the [duration] to this Date instance.
  Date add(Duration duration) {
    checkNull(duration);
    return new DateImplementation.fromEpoch(value + duration.inMilliseconds,
                                            isUtc());
  }

  // Subtracts the [duration] from this Date instance.
  Date subtract(Duration duration) {
    checkNull(duration);
    return new DateImplementation.fromEpoch(value - duration.inMilliseconds,
                                            isUtc());
  }

  // Returns a [Duration] with the difference of [this] and [other].
  Duration difference(Date other) {
    checkNull(other);
    return new Duration(milliseconds: value - other.value);
  }

  // Lazily keep a JS Date stored in the dart object.
  var _asJs() => Primitives.lazyAsJsDate(this);
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
