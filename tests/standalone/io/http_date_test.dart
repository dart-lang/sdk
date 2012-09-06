// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#import("dart:math");

#source("../../../runtime/bin/input_stream.dart");
#source("../../../runtime/bin/output_stream.dart");
#source("../../../runtime/bin/chunked_stream.dart");
#source("../../../runtime/bin/string_stream.dart");
#source("../../../runtime/bin/stream_util.dart");
#source("../../../runtime/bin/http.dart");
#source("../../../runtime/bin/http_impl.dart");
#source("../../../runtime/bin/http_parser.dart");
#source("../../../runtime/bin/http_utils.dart");

void testParseHttpDate() {
  Date date;
  date = new Date(1999, Date.JUN, 11, 18, 46, 53, 0, isUtc: true);
  Expect.equals(date, _HttpUtils.parseDate("Fri, 11 Jun 1999 18:46:53 GMT"));
  Expect.equals(date, _HttpUtils.parseDate("Friday, 11-Jun-1999 18:46:53 GMT"));
  Expect.equals(date, _HttpUtils.parseDate("Fri Jun 11 18:46:53 1999"));

  date = new Date(1970, Date.JAN, 1, 0, 0, 0, 0, isUtc: true);
  Expect.equals(date, _HttpUtils.parseDate("Thu, 1 Jan 1970 00:00:00 GMT"));
  Expect.equals(date,
                _HttpUtils.parseDate("Thursday, 1-Jan-1970 00:00:00 GMT"));
  Expect.equals(date, _HttpUtils.parseDate("Thu Jan  1 00:00:00 1970"));

  date = new Date(2012, Date.MAR, 5, 23, 59, 59, 0, isUtc: true);
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
    Date date;
    String formatted;
    date = new Date(year, month, day, hours, minutes, seconds, 0, isUtc: true);
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

void testParseHttpCookieDate() {
  Expect.throws(() => _HttpUtils.parseCookieDate(""));

  test(int year,
       int month,
       int day,
       int hours,
       int minutes,
       int seconds,
       String formatted) {
    Date date = new Date(
        year, month, day, hours, minutes, seconds, 0, isUtc: true);
    Expect.equals(date, _HttpUtils.parseCookieDate(formatted));
  }

  test(2012, Date.JUN, 19, 14, 15, 01, "tue, 19-jun-12 14:15:01 gmt");
  test(2021, Date.JUN, 09, 10, 18, 14, "Wed, 09-Jun-2021 10:18:14 GMT");
  test(2021, Date.JAN, 13, 22, 23, 01, "Wed, 13-Jan-2021 22:23:01 GMT");
  test(2013, Date.JAN, 15, 21, 47, 38, "Tue, 15-Jan-2013 21:47:38 GMT");
  test(1970, Date.JAN, 01, 00, 00, 01, "Thu, 01-Jan-1970 00:00:01 GMT");
}

void main() {
  testParseHttpDate();
  testFormatParseHttpDate();
  testParseHttpDateFailures();
  testParseHttpCookieDate();
}
