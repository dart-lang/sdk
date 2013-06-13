// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import "dart:async";
import "dart:math";
import 'dart:collection';

part '../../../sdk/lib/io/common.dart';
part "../../../sdk/lib/io/io_sink.dart";
part "../../../sdk/lib/io/http.dart";
part "../../../sdk/lib/io/http_impl.dart";
part "../../../sdk/lib/io/http_parser.dart";
part "../../../sdk/lib/io/http_utils.dart";
part "../../../sdk/lib/io/socket.dart";

void testParseHttpCookieDate() {
  Expect.throws(() => _HttpUtils.parseCookieDate(""));

  test(int year,
       int month,
       int day,
       int hours,
       int minutes,
       int seconds,
       String formatted) {
    DateTime date = new DateTime.utc(year, month, day, hours, minutes, seconds, 0);
    Expect.equals(date, _HttpUtils.parseCookieDate(formatted));
  }

  test(2012, DateTime.JUNE, 19, 14, 15, 01, "tue, 19-jun-12 14:15:01 gmt");
  test(2021, DateTime.JUNE, 09, 10, 18, 14, "Wed, 09-Jun-2021 10:18:14 GMT");
  test(2021, DateTime.JANUARY, 13, 22, 23, 01, "Wed, 13-Jan-2021 22:23:01 GMT");
  test(2013, DateTime.JANUARY, 15, 21, 47, 38, "Tue, 15-Jan-2013 21:47:38 GMT");
  test(1970, DateTime.JANUARY, 01, 00, 00, 01, "Thu, 01-Jan-1970 00:00:01 GMT");
}

void main() {
  testParseHttpCookieDate();
}
