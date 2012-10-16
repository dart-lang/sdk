// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class DateImplementation implements Date {
  final int millisecondsSinceEpoch;
  final bool isUtc;

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
        r'^([+-]?\d?\d\d\d\d)-?(\d\d)-?(\d\d)'  // The day part.
        r'(?:[ T](\d\d)(?::?(\d\d)(?::?(\d\d)(.\d{1,6})?)?)? ?([zZ])?)?$');
    Match match = re.firstMatch(formattedString);
    if (match !== null) {
      int parseIntOrZero(String matched) {
        // TODO(floitsch): we should not need to test against the empty string.
        if (matched === null || matched == "") return 0;
        return int.parse(matched);
      }

      double parseDoubleOrZero(String matched) {
        // TODO(floitsch): we should not need to test against the empty string.
        if (matched === null || matched == "") return 0.0;
        return double.parse(matched);
      }

      int years = int.parse(match[1]);
      int month = int.parse(match[2]);
      int day = int.parse(match[3]);
      int hour = parseIntOrZero(match[4]);
      int minute = parseIntOrZero(match[5]);
      int second = parseIntOrZero(match[6]);
      bool addOneMillisecond = false;
      int millisecond = (parseDoubleOrZero(match[7]) * 1000).round().toInt();
      if (millisecond == 1000) {
        addOneMillisecond = true;
        millisecond = 999;
      }
      // TODO(floitsch): we should not need to test against the empty string.
      bool isUtc = (match[8] !== null) && (match[8] != "");
      int millisecondsSinceEpoch = _brokenDownDateToMillisecondsSinceEpoch(
          years, month, day, hour, minute, second, millisecond, isUtc);
      if (millisecondsSinceEpoch === null) {
        throw new ArgumentError(formattedString);
      }
      if (addOneMillisecond) millisecondsSinceEpoch++;
      return new Date.fromMillisecondsSinceEpoch(millisecondsSinceEpoch,
                                                 isUtc: isUtc);
    } else {
      throw new ArgumentError(formattedString);
    }
  }

  static const int _MAX_MILLISECONDS_SINCE_EPOCH = 8640000000000000;

  DateImplementation.fromMillisecondsSinceEpoch(this.millisecondsSinceEpoch,
                                                this.isUtc) {
    if (millisecondsSinceEpoch.abs() > _MAX_MILLISECONDS_SINCE_EPOCH) {
      throw new ArgumentError(millisecondsSinceEpoch);
    }
    if (isUtc === null) throw new ArgumentError(isUtc);
  }

  bool operator ==(other) {
    if (!(other is Date)) return false;
    return (millisecondsSinceEpoch == other.millisecondsSinceEpoch);
  }

  bool operator <(Date other)
      => millisecondsSinceEpoch < other.millisecondsSinceEpoch;

  bool operator <=(Date other)
      => millisecondsSinceEpoch <= other.millisecondsSinceEpoch;

  bool operator >(Date other)
      => millisecondsSinceEpoch > other.millisecondsSinceEpoch;

  bool operator >=(Date other)
      => millisecondsSinceEpoch >= other.millisecondsSinceEpoch;

  int compareTo(Date other)
      => millisecondsSinceEpoch.compareTo(other.millisecondsSinceEpoch);

  int hashCode() => millisecondsSinceEpoch;

  Date toLocal() {
    if (isUtc) {
      return new Date.fromMillisecondsSinceEpoch(millisecondsSinceEpoch,
                                                 isUtc: false);
    }
    return this;
  }

  Date toUtc() {
    if (isUtc) return this;
    return new Date.fromMillisecondsSinceEpoch(millisecondsSinceEpoch,
                                               isUtc: true);
  }

  String toString() {
    String fourDigits(int n) {
      int absN = n.abs();
      String sign = n < 0 ? "-" : "";
      if (absN >= 1000) return "$n";
      if (absN >= 100) return "${sign}0$absN";
      if (absN >= 10) return "${sign}00$absN";
      return "${sign}000$absN";
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
    String h = twoDigits(hour);
    String min = twoDigits(minute);
    String sec = twoDigits(second);
    String ms = threeDigits(millisecond);
    if (isUtc) {
      return "$y-$m-$d $h:$min:$sec.${ms}Z";
    } else {
      return "$y-$m-$d $h:$min:$sec.$ms";
    }
  }

  /** Returns a new [Date] with the [duration] added to [this]. */
  Date add(Duration duration) {
    int ms = millisecondsSinceEpoch;
    return new Date.fromMillisecondsSinceEpoch(
        ms + duration.inMilliseconds, isUtc: isUtc);
  }

  /** Returns a new [Date] with the [duration] subtracted from [this]. */
  Date subtract(Duration duration) {
    int ms = millisecondsSinceEpoch;
    return new Date.fromMillisecondsSinceEpoch(
        ms - duration.inMilliseconds, isUtc: isUtc);
  }

  /** Returns a [Duration] with the difference of [this] and [other]. */
  Duration difference(Date other) {
    int ms = millisecondsSinceEpoch;
    int otherMs = other.millisecondsSinceEpoch;
    return new Duration(milliseconds: ms - otherMs);
  }

  external DateImplementation(int year,
                              int month,
                              int day,
                              int hour,
                              int minute,
                              int second,
                              int millisecond,
                              bool isUtc);
  external DateImplementation.now();
  external static int _brokenDownDateToMillisecondsSinceEpoch(
      int year, int month, int day, int hour, int minute, int second,
      int millisecond, bool isUtc);
  external String get timeZoneName;
  external Duration get timeZoneOffset;
  external int get year;
  external int get month;
  external int get day;
  external int get hour;
  external int get minute;
  external int get second;
  external int get millisecond;
  external int get weekday;
}
