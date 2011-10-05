// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart core library.

class DateImplementation implements Date {
  final int year;
  final int month;
  final int day;

  const DateImplementation(int year, int month, int day)
  : this.year = year,
    this.month = month,
    this.day = day;

  bool operator ==(other) {
    if (this === other) return true;
    if (!(other is DateImplementation)) return false;
    return year == other.year && month == other.month && day == other.day;
  }

  int hashCode() {
    return approximateDays_(this);
  }

  static int approximateDays_(Date date) {
    // Compute the approximate number of days of the given date.
    // The number is constructed in such a way that year has precedence over
    // month over day. That is, for two given dates, the returned number is
    // higher for the date with the higher year, month, day.
    //
    // Since a month has at most 31 days, month * 32 ensures that months take
    // precedence over days. Similarly year * 512 ensures that years take
    // precedence over months: there are at most 12 months, and 12 * 32 < 512.
    return date.year * 512 + date.month * 32 + date.day;
  }

  int compareTo(Date other) {
    return approximateDays_(this).compareTo(approximateDays_(other));
  }

  String toString() {
    String twoDigits(int n) {
      if (n >= 10) return "${n}";
      return "0${n}";
    }
    String twoDigitMonth = twoDigits(month);
    String twoDigitDay = twoDigits(day);
    return "${year}-${twoDigitMonth}-${twoDigitDay}";
  }

  // TODO(floitsch): Implement missing Date interface.
  int get weekday() {
    throw "DateImplementation 'get weekday' unimplemented";
  }
}
