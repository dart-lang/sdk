// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore: IMPORT_INTERNAL_LIBRARY
import "dart:_http" show Testing$HttpDate;

import "package:expect/expect.dart";

var _parseCookieDate = Testing$HttpDate.test$_parseCookieDate;

void testParseHttpCookieDate() {
  Expect.throws(() => _parseCookieDate(""));

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
    Expect.equals(date, _parseCookieDate(formatted));
  }

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
}

void main() {
  testParseHttpCookieDate();
}
