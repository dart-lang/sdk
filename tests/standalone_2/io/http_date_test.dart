// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:async";
import "dart:math";
import "dart:io";
import "package:expect/expect.dart";

void testParseHttpDate() {
  DateTime date;
  date = new DateTime.utc(1999, DateTime.june, 11, 18, 46, 53, 0);
  Expect.equals(date, HttpDate.parse("Fri, 11 Jun 1999 18:46:53 GMT"));
  Expect.equals(date, HttpDate.parse("Friday, 11-Jun-1999 18:46:53 GMT"));
  Expect.equals(date, HttpDate.parse("Fri Jun 11 18:46:53 1999"));

  date = new DateTime.utc(1970, DateTime.january, 1, 0, 0, 0, 0);
  Expect.equals(date, HttpDate.parse("Thu, 1 Jan 1970 00:00:00 GMT"));
  Expect.equals(date, HttpDate.parse("Thursday, 1-Jan-1970 00:00:00 GMT"));
  Expect.equals(date, HttpDate.parse("Thu Jan  1 00:00:00 1970"));

  date = new DateTime.utc(2012, DateTime.march, 5, 23, 59, 59, 0);
  Expect.equals(date, HttpDate.parse("Mon, 5 Mar 2012 23:59:59 GMT"));
  Expect.equals(date, HttpDate.parse("Monday, 5-Mar-2012 23:59:59 GMT"));
  Expect.equals(date, HttpDate.parse("Mon Mar  5 23:59:59 2012"));
}

void testFormatParseHttpDate() {
  test(int year, int month, int day, int hours, int minutes, int seconds,
      String expectedFormatted) {
    DateTime date;
    String formatted;
    date = new DateTime.utc(year, month, day, hours, minutes, seconds, 0);
    formatted = HttpDate.format(date);
    Expect.equals(expectedFormatted, formatted);
    Expect.equals(date, HttpDate.parse(formatted));
  }

  test(1999, DateTime.june, 11, 18, 46, 53, "Fri, 11 Jun 1999 18:46:53 GMT");
  test(1970, DateTime.january, 1, 0, 0, 0, "Thu, 01 Jan 1970 00:00:00 GMT");
  test(1970, DateTime.january, 1, 9, 9, 9, "Thu, 01 Jan 1970 09:09:09 GMT");
  test(2012, DateTime.march, 5, 23, 59, 59, "Mon, 05 Mar 2012 23:59:59 GMT");
}

void testParseHttpDateFailures() {
  Expect.throws(() {
    HttpDate.parse("");
  });
  String valid = "Mon, 5 Mar 2012 23:59:59 GMT";
  for (int i = 1; i < valid.length - 1; i++) {
    String tmp = valid.substring(0, i);
    Expect.throws(() {
      HttpDate.parse(tmp);
    });
    Expect.throws(() {
      HttpDate.parse(" $tmp");
    });
    Expect.throws(() {
      HttpDate.parse(" $tmp ");
    });
    Expect.throws(() {
      HttpDate.parse("$tmp ");
    });
  }
  Expect.throws(() {
    HttpDate.parse(" $valid");
  });
  Expect.throws(() {
    HttpDate.parse(" $valid ");
  });
  Expect.throws(() {
    HttpDate.parse("$valid ");
  });
}

void main() {
  testParseHttpDate();
  testFormatParseHttpDate();
  testParseHttpDateFailures();
}
