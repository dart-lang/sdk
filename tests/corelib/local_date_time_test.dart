// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Tests that local DateTime constructor works correctly around
// time zone changes.

void main() {
  // Find two points in time with different time zones.
  // Search linearly back from 2020-01-01 in steps of 60 days.
  // Stop if reaching 1970-01-01 (epoch) without finding anything.
  var time = DateTime.utc(2020, 1, 1).millisecondsSinceEpoch;
  var offset =
      DateTime.fromMillisecondsSinceEpoch(time).timeZoneOffset.inMilliseconds;
  var time2 = time;
  var offset2 = offset;
  // Whether the first change found moved the clock forward.
  bool changeForward = false;
  // 60 days.
  const delta = 60 * Duration.millisecondsPerDay;
  while (time2 > 0) {
    time2 -= delta;
    offset2 = DateTime.fromMillisecondsSinceEpoch(time2)
        .timeZoneOffset
        .inMilliseconds;
    if (verbose) {
      print("Search: ${tz(time2, offset2)} - ${tz(time, offset)}");
    }
    if (offset2 != offset) {
      // Two different time zones found. Now find the precise (to the minute)
      // time where a change happened, and test that.
      test(findChange(time2, time));
      // Remeber if the change moved the clock forward or backward.
      changeForward = offset2 < offset;
      break;
    }
  }
  time = time2;
  // Find a change in the other direction.
  // Keep iterating backwards to find another time zone
  // where the change was in the other direction.
  while (time > 0) {
    time -= delta;
    offset =
        DateTime.fromMillisecondsSinceEpoch(time).timeZoneOffset.inMilliseconds;
    if (verbose) {
      print("Search: ${tz(time2, offset2)} - ${tz(time, offset)}");
    }
    if (offset != offset2) {
      if ((offset < offset2) != changeForward) {
        test(findChange(time, time2));
        break;
      } else {
        // Another change in the same direction.
        // Probably rare, but move use this time
        // as end-point instead, so the binary search will be shorter.
        time2 = time;
        offset2 = offset;
      }
    }
  }
}

/// Tests that a local time zone change is correctly represented
/// by local time [DateTime] objects created from date-time values.
void test(TimeZoneChange change) {
  if (verbose) print("Test of $change");
  // Sanity check. The time zones match the [change] one second
  // before and after the change.
  var before = DateTime.fromMillisecondsSinceEpoch(
      change.msSinceEpoch - Duration.millisecondsPerSecond);
  Expect.equals(change.msOffsetBefore, before.timeZoneOffset.inMilliseconds);
  var after = DateTime.fromMillisecondsSinceEpoch(
      change.msSinceEpoch + Duration.millisecondsPerSecond);
  Expect.equals(change.msOffsetAfter, after.timeZoneOffset.inMilliseconds);

  if (verbose) print("From MS    : ${dtz(before)} --- ${dtz(after)}");

  // Create local DateTime objects for the same YMDHMS as the
  // values above. See that we pick the correct local time for them.

  // One second before the change, even if clock moves backwards,
  // we pick a value that is in the earlier time zone.
  var localBefore = DateTime(before.year, before.month, before.day, before.hour,
      before.minute, before.second);
  Expect.equals(before, localBefore);

  // Asking for a calendar date one second after the change.
  var localAfter = DateTime(after.year, after.month, after.day, after.hour,
      after.minute, after.second);
  if (verbose) print("From YMDHMS: ${dtz(localBefore)} --- ${dtz(localAfter)}");
  if (before.timeZoneOffset < after.timeZoneOffset) {
    // Clock moved forwards.
    // We're asking for a clock time which doesn't exist.
    if (verbose) {
      print("Forward: ${dtz(after)} vs ${dtz(localAfter)}");
    }
    Expect.equals(after, localAfter);
  } else {
    // Clock moved backwards.
    // We're asking for a clock time which exists more than once.
    // Should be in the former time zone.
    Expect.equals(before.timeZoneOffset, localAfter.timeZoneOffset);
  }
}

/// Finds a time zone change between [before] and [after].
///
/// The [before] time must be before [after],
/// and the local time zone at the two points must be different.
///
/// Finds the point in time, with one minute precision,
/// where the time zone changed, and returns this point,
/// as well as the time zone offset before and after the change.
TimeZoneChange findChange(int before, int after) {
  var min = Duration.millisecondsPerMinute;
  assert(before % min == 0);
  assert(after % min == 0);
  var offsetBefore =
      DateTime.fromMillisecondsSinceEpoch(before).timeZoneOffset.inMilliseconds;
  var offsetAfter =
      DateTime.fromMillisecondsSinceEpoch(after).timeZoneOffset.inMilliseconds;
  // Binary search for the precise (to 1 minute increments)
  // time where the change happened.
  while (after - before > min) {
    var mid = before + (after - before) ~/ 2;
    mid -= mid % min;
    var offsetMid =
        DateTime.fromMillisecondsSinceEpoch(mid).timeZoneOffset.inMilliseconds;
    if (verbose) {
      print(
          "Bsearch: ${tz(before, offsetBefore)} - ${tz(mid, offsetMid)} - ${tz(after, offsetAfter)}");
    }
    if (offsetMid == offsetBefore) {
      before = mid;
    } else if (offsetMid == offsetAfter) {
      after = mid;
    } else {
      // Third timezone in the middle. Probably rare.
      // Use that as either before or after.
      // Keep the direction of the time zone change.
      var forwardChange = offsetAfter > offsetBefore;
      if ((offsetMid > offsetBefore) == forwardChange) {
        after = mid;
        offsetAfter = offsetMid;
      } else {
        before = mid;
        offsetBefore = offsetMid;
      }
    }
  }
  return TimeZoneChange(after, offsetBefore, offsetAfter);
}

/// A local time zone change.
class TimeZoneChange {
  /// The point in time where the clocks were adjusted.
  final int msSinceEpoch;

  /// The time zone offset before the change.
  final int msOffsetBefore;

  /// The time zone offset since the change.
  final int msOffsetAfter;
  TimeZoneChange(this.msSinceEpoch, this.msOffsetBefore, this.msOffsetAfter);
  String toString() {
    var local = DateTime.fromMillisecondsSinceEpoch(msSinceEpoch);
    var offsetBefore = Duration(milliseconds: msOffsetBefore);
    var offsetAfter = Duration(milliseconds: msOffsetAfter);
    return "$local (${ltz(offsetBefore)} -> ${ltz(offsetAfter)})";
  }
}

// Helpers when printing timezones.

/// Point in time in ms since epoch, and known offset in ms.
String tz(int ms, int offset) => "${DateTime.fromMillisecondsSinceEpoch(ms)}"
    "${ltz(Duration(milliseconds: offset))}";

/// Time plus Zone from DateTime
String dtz(DateTime dt) => "$dt${dt.isUtc ? "" : ltz(dt.timeZoneOffset)}";

/// Time zone from duration ("+h:ss" format).
String ltz(Duration d) => "${d.isNegative ? "-" : "+"}${d.inHours}"
    ":${(d.inMinutes % 60).toString().padLeft(2, "0")}";

/// Set to true if debugging.
const bool verbose = false;
