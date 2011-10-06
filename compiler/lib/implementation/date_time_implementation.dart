// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart core library.

// JavaScript implementation of DateTimeImplementation.
class DateTimeImplementation implements DateTime {
  factory DateTimeImplementation(int years,
                                 int month,
                                 int day,
                                 int hours,
                                 int minutes,
                                 int seconds,
                                 int milliseconds) {
    return new DateTimeImplementation.withTimeZone(
        years, month, day,
        hours, minutes, seconds, milliseconds,
        new TimeZoneImplementation.local());
  }

  DateTimeImplementation.withTimeZone(int years,
                                      int month,
                                      int day,
                                      int hours,
                                      int minutes,
                                      int seconds,
                                      int milliseconds,
                                      TimeZoneImplementation timeZone)
      : this.timeZone = timeZone,
        value = _valueFromDecomposed(years, month, day,
                                     hours, minutes, seconds, milliseconds,
                                     timeZone.isUtc) {
  }

  DateTimeImplementation.now()
      : timeZone = new TimeZone.local(),
        value = _now() {
  }

  DateTimeImplementation.fromString(String formattedString)
      : timeZone = new TimeZone.local(),
        value = _valueFromString(formattedString) {
  }

  const DateTimeImplementation.fromEpoch(this.value, this.timeZone);

  bool operator ==(other) {
    if (!(other is DateTimeImplementation)) return false;
    return (value == other.value) && (timeZone == other.timeZone);
  }

  int compareTo(DateTime other) {
    return value.compareTo(other.value);
  }

  DateTime changeTimeZone(TimeZone targetTimeZone) {
    if (targetTimeZone == null) {
      targetTimeZone = new TimeZoneImplementation.local();
    }
    return new DateTime.fromEpoch(value, targetTimeZone);
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
    throw "Unimplemented";
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

    // Adds the duration [time] to this DateTime instance.
  DateTime add(Time time) {
    return new DateTimeImplementation.fromEpoch(value + time.duration,
                                                timeZone);
  }

  // Subtracts the duration [time] from this DateTime instance.
  DateTime subtract(Time time) {
    return new DateTimeImplementation.fromEpoch(value - time.duration,
                                                timeZone);
  }

  // Returns a [Time] with the difference of [this] and [other].
  Time difference(DateTime other) {
    return new TimeImplementation.duration(value - other.value);
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
