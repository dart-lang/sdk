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

  factory DateTimeImplementation.fromDateAndTime(
      Date date,
      Time time,
      TimeZoneImplementation timeZone) {
    if (timeZone === null) {
      timeZone = new TimeZoneImplementation.local();
    }
    return new DateTimeImplementation.withTimeZone(date.year,
                                                   date.month,
                                                   date.day + time.days,
                                                   time.hours,
                                                   time.minutes,
                                                   time.seconds,
                                                   time.milliseconds,
                                                   timeZone);
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

  Date get date() {
    return new DateImplementation(year, month, day);
  }

  Time get time() {
    return new TimeImplementation(0, hours, minutes, seconds, milliseconds);
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
    String dateString = date.toString();
    String timeString = time.toString();
    if (timeZone.isUtc) {
      return "${dateString} ${timeString}Z";
    } else {
      return "${dateString} ${timeString}";
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
