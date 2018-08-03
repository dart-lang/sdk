// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Make sure that date-times close to daylight savings work correctly.
// See http://dartbug.com/30550

/// A list of (decomposed) date-times where daylight saving changes
/// happen.
///
/// This list covers multiple timezones to increase test coverage on
/// different machines.
final daylightSavingChanges = [
  // TZ environment, y, m, d, h, change.
  ["Europe/Paris", 2017, 03, 26, 02, 60],
  ["Europe/Paris", 2017, 10, 29, 03, -60],
  ["Antarctica/Troll", 2017, 03, 19, 01, 120],
  ["Antarctica/Troll", 2017, 10, 29, 03, -120],
  ["Australia/Canberra", 2017, 04, 02, 03, -60],
  ["Australia/Canberra", 2017, 10, 01, 02, 60],
  ["Australia/Lord_Howe", 2017, 04, 02, 02, -30],
  ["Australia/Lord_Howe", 2017, 10, 01, 02, 30],
  ["Atlantic/Bermuda", 2017, 03, 12, 02, 60], // US and Canada.
  ["Atlantic/Bermuda", 2017, 11, 05, 02, -60],
  ["America/Campo_Grande", 2017, 02, 19, 00, -60], // Brazil
  ["America/Campo_Grande", 2017, 10, 15, 00, 60],
  ["America/Santiago", 2017, 05, 14, 00, -60],
  ["America/Santiago", 2017, 08, 13, 00, 60],
  ["Chile/EasterIsland", 2017, 05, 13, 22, -60],
  ["Chile/EasterIsland", 2017, 08, 12, 22, 60],
  ["Pacific/Fiji", 2017, 01, 15, 03, -60],
  ["Pacific/Fiji", 2017, 11, 05, 02, 60],
  ["America/Scoresbysund", 2017, 03, 26, 00, 60], // Ittoqqortoormiit.
  ["America/Scoresbysund", 2017, 10, 29, 01, -60],
  ["Asia/Tehran", 2017, 03, 22, 00, 60],
  ["Asia/Tehran", 2017, 09, 22, 00, -60],
  ["Israel", 2017, 03, 24, 02, 60],
  ["Israel", 2017, 10, 29, 02, -60],
  ["Asia/Amman", 2017, 03, 31, 00, 60],
  ["Asia/Amman", 2017, 10, 27, 01, -60],
  ["Mexico/General", 2017, 04, 02, 02, 60],
  ["Mexico/General", 2017, 10, 29, 02, -60],
];

void runTests() {
  // Makes sure we don't go into the wrong direction during a
  // daylight-savings change (as happened in #30550).
  for (var test in daylightSavingChanges) {
    for (int i = 0; i < 2; i++) {
      int year = test[1];
      int month = test[2];
      int day = test[3];
      int hour = test[4];

      int minute = i == 0 ? 0 : test[5];
      // Rather adjust the hours than keeping the minutes.
      hour += minute ~/ 60;
      minute = minute.remainder(60);
      if (hour < 0) {
        hour += 24;
        day--;
      }

      {
        // Check that microseconds are taken into account.
        var dtMillisecond = new DateTime(year, month, day, hour, minute, 0, 1);
        var dtSecond = new DateTime(year, month, day, hour, minute, 1);
        Expect.equals(const Duration(milliseconds: 999),
            dtSecond.difference(dtMillisecond));

        dtMillisecond = new DateTime(year, month, day, hour, minute, 0, -1);
        dtSecond = new DateTime(year, month, day, hour, minute, -1);
        Expect.equals(const Duration(milliseconds: 999),
            dtMillisecond.difference(dtSecond));
      }

      var dt1 = new DateTime(year, month, day, hour);
      var dt2 = new DateTime(year, month, day, hour, 1);

      // Earlier:
      int earlierDay = day;
      int earlierHour = hour - 1;
      if (earlierHour < 0) {
        earlierHour = 23;
        earlierDay--;
      }
      var dt3 = new DateTime(year, month, earlierDay, earlierHour, 59);

      var diff1 = dt2.difference(dt1).inMinutes;
      var diff2 = dt1.difference(dt3).inMinutes;

      if (diff1 == 1 && diff2 == 1 && dt1.hour == hour && dt1.minute == 0) {
        // Regular date-time.
        continue;
      }

      // At most one is at a distance of more than a minute.
      Expect.isTrue(diff1 == 1 || diff2 == 1);

      if (diff2 < 0) {
        // This happens, when we ask for invalid times.
        // Suppose daylight-saving is at 2:00 and switches to 3:00. If we
        // ask for 2:59, we get 3:59 (59 minutes after 2:00).
        Expect.isFalse(dt3.day == earlierDay && dt3.hour == earlierHour);
        // If that's the case, then removing one minute from dt1 should
        // not yield a date-time with the earlier values, and it should
        // be far away from dt3.
        var dt4 = dt1.add(const Duration(minutes: -1));
        Expect.isFalse(dt4.day == earlierDay && dt4.hour == earlierHour);
        Expect.isTrue(dt4.isBefore(dt1));
        Expect.isTrue(dt4.day < earlierDay ||
            (dt4.day == earlierDay && dt4.hour < earlierHour));
        continue;
      }

      // They must be in the right order.
      Expect.isTrue(dt1.isBefore(dt2));
      Expect.isTrue(dt3.isBefore(dt1));
    }
  }
}

void main(List<String> args) {
  // The following code constructs a String with all timezones that are
  // relevant for this test.
  // This can be helpful for running tests in multiple timezones.
  // Typically, one would write something like:
  //    for tz in <contents_of_string>; do TZ=$tz tools/test.py ...; done
  var result = new StringBuffer();
  for (int i = 0; i < daylightSavingChanges.length; i += 2) {
    if (i != 0) result.write(" ");
    result.write(daylightSavingChanges[i][0]);
  }

  runTests();
}
