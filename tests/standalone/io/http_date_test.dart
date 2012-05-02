// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#source("../../../runtime/bin/http_utils.dart");

class HttpException implements Exception {
  const HttpException([String this.message = ""]);
  String toString() => "HttpException: $message";
  final String message;
}

void testParseHttpDate() {
  TimeZone utc = new TimeZone.utc();
  Date date;
  date = new Date.withTimeZone(1999, Date.JUN, 11, 18, 46, 53, 0, utc);
  Expect.equals(date, _HttpUtils.parseDate("Fri, 11 Jun 1999 18:46:53 GMT"));
  Expect.equals(date, _HttpUtils.parseDate("Friday, 11-Jun-1999 18:46:53 GMT"));
  Expect.equals(date, _HttpUtils.parseDate("Fri Jun 11 18:46:53 1999"));

  date = new Date.withTimeZone(1970, Date.JAN, 1, 0, 0, 0, 0, utc);
  Expect.equals(date, _HttpUtils.parseDate("Thu, 1 Jan 1970 00:00:00 GMT"));
  Expect.equals(date,
                _HttpUtils.parseDate("Thursday, 1-Jan-1970 00:00:00 GMT"));
  Expect.equals(date, _HttpUtils.parseDate("Thu Jan  1 00:00:00 1970"));

  date = new Date.withTimeZone(2012, Date.MAR, 5, 23, 59, 59, 0, utc);
  Expect.equals(date, _HttpUtils.parseDate("Mon, 5 Mar 2012 23:59:59 GMT"));
  Expect.equals(date, _HttpUtils.parseDate("Monday, 5-Mar-2012 23:59:59 GMT"));
  Expect.equals(date, _HttpUtils.parseDate("Mon Mar  5 23:59:59 2012"));
}

void testFormatParseHttpDate() {
  test(int year,
       int month,
       int day,
       int hours,
       int minutes,
       int seconds,
       String expectedFormatted) {
    TimeZone utc = new TimeZone.utc();
    Date date;
    String formatted;
    date = new Date.withTimeZone(
        year, month, day, hours, minutes, seconds, 0, utc);
    formatted = _HttpUtils.formatDate(date);
    Expect.equals(expectedFormatted, formatted);
    Expect.equals(date, _HttpUtils.parseDate(formatted));
  }

  test(1999, Date.JUN, 11, 18, 46, 53, "Fri, 11 Jun 1999 18:46:53 GMT");
  test(1970, Date.JAN, 1, 0, 0, 0, "Thu, 1 Jan 1970 00:00:00 GMT");
  test(2012, Date.MAR, 5, 23, 59, 59, "Mon, 5 Mar 2012 23:59:59 GMT");
}

void testParseHttpDateFailures() {
  Expect.throws(() {
    _HttpUtils.parseDate("");
  });
  String valid = "Mon, 5 Mar 2012 23:59:59 GMT";
  for (int i = 1; i < valid.length - 1; i++) {
    String tmp = valid.substring(0, i);
    Expect.throws(() {
      _HttpUtils.parseDate(tmp);
    });
    Expect.throws(() {
      _HttpUtils.parseDate(" $tmp");
    });
    Expect.throws(() {
      _HttpUtils.parseDate(" $tmp ");
    });
    Expect.throws(() {
      _HttpUtils.parseDate("$tmp ");
    });
  }
  Expect.throws(() {
    _HttpUtils.parseDate(" $valid");
  });
  Expect.throws(() {
    _HttpUtils.parseDate(" $valid ");
  });
  Expect.throws(() {
    _HttpUtils.parseDate("$valid ");
  });
}

void main() {
  testParseHttpDate();
  testFormatParseHttpDate();
  testParseHttpDateFailures();
}
