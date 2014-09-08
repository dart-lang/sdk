// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Tests for the strict option when parsing dates and times, which are
/// relatively locale-independent, depending only on the being a valid date
/// and consuming all the input data.
library date_time_strict_test;

import 'package:intl/intl.dart';
import 'package:unittest/unittest.dart';

main() {
  test("All input consumed", () {
    var format = new DateFormat.yMMMd();
    var date = new DateTime(2014, 9, 3);
    var formatted = 'Sep 3, 2014';
    expect(format.format(date), formatted);
    var parsed = format.parseStrict(formatted);
    expect(parsed, date);

    check(String s) {
        expect(() => format.parseStrict(s), throwsFormatException);
        expect(format.parse(s), date);
    }

    check(formatted + ",");
    check(formatted + "abc");
    check(formatted + "   ");
  });

  test("Invalid dates", () {
    var format = new DateFormat.yMd();
    check(s) => expect(() => format.parseStrict(s), throwsFormatException);
    check("0/3/2014");
    check("13/3/2014");
    check("9/0/2014");
    check("9/31/2014");
    check("09/31/2014");
    check("10/32/2014");
    check("2/29/2014");
    expect(format.parseStrict("2/29/2016"), new DateTime(2016, 2, 29));
  });

  test("Invalid times am/pm", () {
     var format = new DateFormat.jms();
     check(s) => expect(() => format.parseStrict(s), throwsFormatException);
     check("-1:15:00 AM");
     expect(format.parseStrict("0:15:00 AM"), new DateTime(1970, 1, 1, 0, 15));
     check("24:00:00 PM");
     check("24:00:00 AM");
     check("25:00:00 PM");
     check("0:-1:00 AM");
     check("0:60:00 AM");
     expect(format.parseStrict("0:59:00 AM"), new DateTime(1970, 1, 1, 0, 59));
     check("0:0:-1 AM");
     check("0:0:60 AM");
     check("2:0:60 PM");
     expect(format.parseStrict("2:0:59 PM"),
         new DateTime(1970, 1, 1, 14, 0, 59));
   });

  test("Invalid times 24 hour", () {
     var format = new DateFormat.Hms();
     check(s) => expect(() => format.parseStrict(s), throwsFormatException);
     check("-1:15:00");
     expect(format.parseStrict("0:15:00"), new DateTime(1970, 1, 1, 0, 15));
     check("24:00:00");
     check("24:00:00");
     check("25:00:00");
     check("0:-1:00");
     check("0:60:00");
     expect(format.parseStrict("0:59:00"), new DateTime(1970, 1, 1, 0, 59));
     check("0:0:-1");
     check("0:0:60");
     check("14:0:60");
     expect(format.parseStrict("14:0:59"),
         new DateTime(1970, 1, 1, 14, 0, 59));
   });
}