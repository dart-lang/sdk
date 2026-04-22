// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:io";
// ignore: IMPORT_INTERNAL_LIBRARY
import "dart:_http" show Testing$HttpDate;

import "package:expect/expect.dart";

var _parseCookieDate = Testing$HttpDate.test$_parseCookieDate;

void testParseHttpCookieDate() {
  testThrows(String source) {
    Expect.throws<HttpException>(() => _parseCookieDate(source));
  }

  test(
    int year,
    int month,
    int day,
    int hours,
    int minutes,
    int seconds,
    String formatted,
  ) {
    DateTime date = new DateTime.utc(
      year,
      month,
      day,
      hours,
      minutes,
      seconds,
      0,
    );
    Expect.equals(date, _parseCookieDate(formatted), formatted);
  }

  testThrows("");

  const jan = DateTime.january;
  const jun = DateTime.june;
  // Correct RFC 1123 Format.
  test(2021, jun, 09, 10, 18, 14, "Wed, 09 Jun 2021 10:18:14 GMT");
  test(2021, jan, 13, 22, 23, 01, "Wed, 13 Jan 2021 22:23:01 GMT");
  test(2013, jan, 15, 21, 47, 38, "Tue, 15 Jan 2013 21:47:38 GMT");
  test(1970, jan, 01, 00, 00, 01, "Thu, 01 Jan 1970 00:00:01 GMT");
  // Allows RFC 850 Date.
  test(2013, jan, 15, 21, 47, 38, "Tuesday, 15-Jan-2013 21:47:38 GMT");
  // Allows AscTime Date.
  test(2013, jan, 15, 21, 47, 38, "Tue Jan 15 21:47:38 2013");
  // Years < 100 are normalized to 1970-2069.
  test(2000, jan, 01, 00, 00, 01, "Thu, 01 Jan 00 00:00:01 GMT");
  test(1970, jan, 01, 00, 00, 01, "Thu, 01 Jan 70 00:00:01 GMT");
  test(2069, jan, 01, 00, 00, 01, "Thu, 01 Jan 69 00:00:01 GMT");
  test(1999, jan, 01, 00, 00, 01, "Thu, 01 Jan 99 00:00:01 GMT");

  // Ignores case of letters.
  test(2012, jun, 19, 14, 15, 01, "tue, 19 jun 12 14:15:01 gmt");
  // Allows `-` between day-month-year of (otherwise) RFC 1123 date.
  test(2012, jun, 19, 14, 15, 01, "tue, 19-jun-12 14:15:01 gmt");

  // The parsing algorithm allows:
  // * year, month, time, and dayOfMonth in any order.
  //   * year is 2-4 digits
  //   * month is letters
  //   * time is three times 1-2 digits separated by `:`.
  //   * dayOfMonth is 1-2 digits.
  //   These can be non-overlapping, so any order is possible.
  // * Arbitrary characters after the digits/three first lower-case months.
  //

  test(2012, jun, 3, 14, 15, 01, "2012 jun 3 14:15:01");
  test(2012, jun, 3, 14, 15, 01, "2012 jun 14:15:01 3");
  test(2012, jun, 3, 14, 15, 01, "2012 3 jun 14:15:01");
  test(2012, jun, 3, 14, 15, 01, "2012 14:15:01 jun 3");
  test(2012, jun, 3, 14, 15, 01, "2012 3 14:15:01 jun");
  test(2012, jun, 3, 14, 15, 01, "2012 14:15:01 3 jun");

  test(2012, jun, 3, 14, 15, 01, "jun 2012 3 14:15:01");
  test(2012, jun, 3, 14, 15, 01, "jun 2012 14:15:01 3");
  test(2012, jun, 3, 14, 15, 01, "3 2012 jun 14:15:01");
  test(2012, jun, 3, 14, 15, 01, "14:15:01 2012 jun 3");
  test(2012, jun, 3, 14, 15, 01, "3 2012 14:15:01 jun");
  test(2012, jun, 3, 14, 15, 01, "14:15:01 2012 3 jun");

  test(2012, jun, 3, 14, 15, 01, "jun 3 2012 14:15:01");
  test(2012, jun, 3, 14, 15, 01, "jun 14:15:01 2012 3");
  test(2012, jun, 3, 14, 15, 01, "3 jun 2012 14:15:01");
  test(2012, jun, 3, 14, 15, 01, "14:15:01 jun 2012 3");
  test(2012, jun, 3, 14, 15, 01, "3 14:15:01 2012 jun");
  test(2012, jun, 3, 14, 15, 01, "14:15:01 3 2012 jun");

  test(2012, jun, 3, 14, 15, 01, "jun 3 14:15:01 2012");
  test(2012, jun, 3, 14, 15, 01, "jun 14:15:01 3 2012");
  test(2012, jun, 3, 14, 15, 01, "3 jun 14:15:01 2012");
  test(2012, jun, 3, 14, 15, 01, "14:15:01 jun 3 2012");
  test(2012, jun, 3, 14, 15, 01, "3 14:15:01 jun 2012");
  test(2012, jun, 3, 14, 15, 01, "14:15:01 3 jun 2012");

  // Day-of-month is matched before year for a 2-digit number.
  test(2003, jun, 12, 14, 15, 01, "12 03 14:15:01 jun");
  test(2012, jun, 3, 14, 15, 01, "03 12 14:15:01 jun");
  // After day-of-month is set, "1" isn't matched.
  test(2012, jun, 3, 14, 15, 01, "3 1 14:15:01 jun 12");
  // Five digits is not a year.
  test(2012, jun, 3, 14, 15, 01, "03 02001 14:15:01 jun 12");

  // Time-parts can be one or two digits.
  test(2012, jun, 3, 9, 8, 7, "03 12 9:8:7 jun");

  // Year can be two, three or four digits,
  test(2001, jun, 3, 14, 15, 01, "03 01 14:15:01 jun 12");
  test(2010, jun, 3, 14, 15, 01, "03 010 14:15:01 jun 12");
  test(2069, jun, 3, 14, 15, 01, "03 0069 14:15:01 jun 12");
  // But not one digit.
  test(2003, jun, 2, 14, 15, 01, "02 1 03 14:15:01 jun");

  // Day before year, if valid as both.
  test(2001, jun, 2, 14, 15, 01, "02 01 14:15:01 jun");
  test(2002, jun, 1, 14, 15, 01, "002 01 14:15:01 jun");

  // Other parts can contain `:`.
  test(2001, jun, 3, 2, 59, 59, "jun 03:99:999 02:59:59 01:99:99");
  test(2003, jun, 1, 2, 59, 59, "jun 003:99:999 02:59:59 01:99:99");

  // Only first match counts
  test(2001, jun, 20, 9, 8, 7, "jun 20 2001 09:08:07 aug 10 2012 10:11:12");

  // Incomplete dates fail.

  // No year.
  testThrows('01 14:15:01 jun');
  testThrows('01 1 14:15:01 jun');

  // No month.
  testThrows('01 2012 14:15:01');
  testThrows('01 2012 14:15:01 gmt');

  // No day.
  testThrows('2012 14:15:01 jun');
  testThrows('2012 14:15:01 jun 012'); // Three digits, not a day.

  // No time.
  testThrows('2012 12 jun');
  testThrows('2012 12 14 jun');
  testThrows('2012 12 14: jun');
  testThrows('2012 12 14:15 jun');
  testThrows('2012 12 14:15: jun');
  testThrows('2012 12 14:15:Z0 jun');
  testThrows('2012 12 14:15:+0 jun');

  // Invalid hour.
  testThrows('2012 12 24:15:01 jun');
  testThrows('2012 12 99:15:01 jun');
  // Invalid minute.
  testThrows('2012 12 00:60:01 jun');
  testThrows('2012 12 00:99:01 jun');
  // Invalid second.
  testThrows('2012 12 00:01:60 jun');
  testThrows('2012 12 00:01:99 jun');
  // Invalid day-of-month
  testThrows('2012 00 00:01:02 jun'); // Zero not allowed.
  testThrows('2012 32 00:01:02 jul'); // July had 31 days.
  testThrows('2012 31 00:01:02 apr'); // April had 30 days.
  testThrows('2012 30 00:01:02 feb'); // February had 29 days.
  testThrows('2011 30 00:01:02 feb'); // That February had 28 days.
  // Invalid year (< 1601)
  test(1601, jun, 1, 0, 1, 2, '1601 01 00:01:02 jun');
  testThrows('1600 01 00:01:02 jun');
  testThrows('999 01 00:01:02 jun');
  testThrows('100 01 00:01:02 jun'); // If below 100, adds 1900/2000.

  // Every entry can have trailing non-delimiters.
  const delimiters =
      "\x09"
      "\x20\x21\x22\x23\x24\x25\x26\x27"
      "\x28\x29\x2a\x2b\x2c\x2d\x2e\x2f"
      "\x3b\x3c\x3d\x3e\x3f\x40"
      "\x5b\x5c\x5d\x5e\x5f\x60"
      "\x7b\x7c\x7d\x7e";

  // Does not start with digit.
  const nonDelimiters =
      "\x00\x01\x02\x03\x04\x05\x06\x07"
      "\x08\x0a\x0b\x0c\x0d\x0e\x0f"
      "\x10\x11\x12\x13\x14\x15\x16\x17"
      "\x18\x19\x1a\x1b\x1c\x1d\x1e\x1f"
      "0123456789:"
      "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
      "abcdefghijklmnopqrstuvwxyz"
      "\x7F\x80\xFF";

  const delimited =
      "${delimiters}2012$nonDelimiters${delimiters}"
      "jun$nonDelimiters${delimiters}3$nonDelimiters${delimiters}"
      "14:15:01$delimiters";
  test(2012, jun, 3, 14, 15, 01, delimited);
}

void main() {
  testParseHttpCookieDate();
}
