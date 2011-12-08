// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart core library.

// JavaScript implementation of DateImplementation.
class DateImplementation implements Date {
  factory DateImplementation(int years,
                             int month,
                             int day,
                             int hours,
                             int minutes,
                             int seconds,
                             int milliseconds) {
    return new DateImplementation.withTimeZone(
        years, month, day,
        hours, minutes, seconds, milliseconds,
        new TimeZoneImplementation.local());
  }

  DateImplementation.withTimeZone(int years,
                                  int month,
                                  int day,
                                  int hours,
                                  int minutes,
                                  int seconds,
                                  int milliseconds,
                                  TimeZone timeZone)
      : this.timeZone = timeZone,
        value = _valueFromDecomposed(years, month, day,
                                     hours, minutes, seconds, milliseconds,
                                     timeZone.isUtc) {
  }

  DateImplementation.now()
      : timeZone = new TimeZone.local(),
        value = _now() {
  }

  DateImplementation.fromString(String formattedString)
      : timeZone = new TimeZone.local(),
        value = _valueFromString(formattedString) {
  }

  const DateImplementation.fromEpoch(int this.value, TimeZone this.timeZone);

  bool operator ==(other) {
    if (!(other is DateImplementation)) return false;
    return (value == other.value) && (timeZone == other.timeZone);
  }

  int compareTo(Date other) {
    return value.compareTo(other.value);
  }

  Date changeTimeZone(TimeZone targetTimeZone) {
    if (targetTimeZone == null) {
      targetTimeZone = new TimeZoneImplementation.local();
    }
    return new Date.fromEpoch(value, targetTimeZone);
  }

  int get year() {
    return _getYear(value, isUtc());
  }

  int get month() {
    return _getMonth(value, isUtc());
  }

  int get day() {
    return _getDay(value, isUtc());
  }

  int get hours() {
    return _getHours(value, isUtc());
  }

  int get minutes() {
    return _getMinutes(value, isUtc());
  }

  int get seconds() {
    return _getSeconds(value, isUtc());
  }

  int get milliseconds() {
    return _getMilliseconds(value, isUtc());
  }

  int get weekday() {
    final Date unixTimeStart =
        new Date.withTimeZone(1970, 1, 1, 0, 0, 0, 0, timeZone);
    int msSince1970 = this.difference(unixTimeStart).inMilliseconds;
    // Adjust the milliseconds to avoid problems with summer-time.
    if (hours < 2) {
      msSince1970 += 2 * Duration.MILLISECONDS_PER_HOUR;
    }
    int daysSince1970 =
        (msSince1970 / Duration.MILLISECONDS_PER_DAY).floor().toInt();
    // 1970-1-1 was a Thursday.
    return ((daysSince1970 + Date.THU) % Date.DAYS_IN_WEEK);
  }

  bool isLocalTime() {
    return !timeZone.isUtc;
  }

  bool isUtc() {
    return timeZone.isUtc;
  }

  String toString() {
    String threeDigits(int n) {
      if (n >= 100) return "${n}";
      if (n > 10) return "0${n}";
      return "00${n}";
    }
    String twoDigits(int n) {
      if (n >= 10) return "${n}";
      return "0${n}";
    }

    String m = twoDigits(month);
    String d = twoDigits(day);
    String h = twoDigits(hours);
    String min = twoDigits(minutes);
    String sec = twoDigits(seconds);
    String ms = threeDigits(milliseconds);
    if (timeZone.isUtc) {
      return "$year-$m-$d $h:$min:$sec.${ms}Z";
    } else {
      return "$year-$m-$d $h:$min:$sec.$ms";
    }
  }

    // Adds the [duration] to this Date instance.
  Date add(Duration duration) {
    return new DateImplementation.fromEpoch(value + duration.inMilliseconds,
                                            timeZone);
  }

  // Subtracts the [duration] from this Date instance.
  Date subtract(Duration duration) {
    return new DateImplementation.fromEpoch(value - duration.inMilliseconds,
                                            timeZone);
  }

  // Returns a [Duration] with the difference of [this] and [other].
  Duration difference(Date other) {
    return new Duration(milliseconds: value - other.value);
  }

  final int value;
  final TimeZoneImplementation timeZone;

  static int _valueFromDecomposed(int years, int month, int day,
                                  int hours, int minutes, int seconds,
                                  int milliseconds, bool isUtc) native;
  static int _valueFromString(String str) native;
  static int _now() native;
  int _getYear(int value, bool isUtc) native;
  int _getMonth(int value, bool isUtc) native;
  int _getDay(int value, bool isUtc) native;
  int _getHours(int value, bool isUtc) native;
  int _getMinutes(int value, bool isUtc) native;
  int _getSeconds(int value, bool isUtc) native;
  int _getMilliseconds(int value, bool isUtc) native;
}
