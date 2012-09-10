// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart core library.

/**
 * Date is the public interface to a point in time.
 *
 * It can represent time values that are at a distance of at most
 * 8,640,000,000,000,000ms (100,000,000 days) from epoch (1970-01-01 UTC). In
 * other words: [:millisecondsSinceEpoch.abs() <= 8640000000000000:].
 *
 * Also see [Stopwatch] for means to measure time-spans.
 */
interface Date extends Comparable, Hashable default DateImplementation {
  // Weekday constants that are returned by [weekday] method:
  static const int MON = 1;
  static const int TUE = 2;
  static const int WED = 3;
  static const int THU = 4;
  static const int FRI = 5;
  static const int SAT = 6;
  static const int SUN = 7;
  static const int DAYS_IN_WEEK = 7;

  // Month constants that are returned by the [month] getter.
  static const int JAN = 1;
  static const int FEB = 2;
  static const int MAR = 3;
  static const int APR = 4;
  static const int MAY = 5;
  static const int JUN = 6;
  static const int JUL = 7;
  static const int AUG = 8;
  static const int SEP = 9;
  static const int OCT = 10;
  static const int NOV = 11;
  static const int DEC = 12;

  /**
   * Constructs a [Date] instance based on the individual parts. The date is
   * in the local time zone if [isUtc] is false.
   *
   * [month] and [day] are one-based. For example
   * [:new Date(1938, 1, 10)] represents the 10th of January 1938.
   */
  // TODO(floitsch): the spec allows default values in interfaces, but our
  // tools don't yet. Eventually we want to have default values here.
  Date(int year,
       [int month,
        int day,
        int hour,
        int minute,
        int second,
        int millisecond,
        bool isUtc]);

  /**
   * Constructs a new [Date] instance with current date time value in the
   * local time zone.
   */
  Date.now();

  /**
   * Constructs a new [Date] instance based on [formattedString].
   */
  Date.fromString(String formattedString);

  /**
   * Constructs a new [Date] instance with the given [millisecondsSinceEpoch].
   * If [isUtc] is false then the date is in the local time zone.
   *
   * The constructed [Date] represents
   * 1970-01-01T00:00:00Z + [millisecondsSinceEpoch]ms in the given
   * time zone (local or UTC).
   */
  // TODO(floitsch): the spec allows default values in interfaces, but our
  // tools don't yet. Eventually we want to have default values here.
  Date.fromMillisecondsSinceEpoch(int millisecondsSinceEpoch, [bool isUtc]);

  /**
   * Returns true if [this] occurs at the same time as [other]. The
   * comparison is independent of whether the time is utc or in the local
   * time zone.
   */
  bool operator ==(Date other);
  /**
   * Returns true if [this] occurs before [other]. The comparison is independent
   * of whether the time is utc or in the local time zone.
   */
  bool operator <(Date other);
  /**
   * Returns true if [this] occurs at the same time or before [other]. The
   * comparison is independent of whether the time is utc or in the local
   * time zone.
   */
  bool operator <=(Date other);
  /**
   * Returns true if [this] occurs after [other]. The comparison is independent
   * of whether the time is utc or in the local time zone.
   */
  bool operator >(Date other);
  /**
   * Returns true if [this] occurs at the same time or after [other]. The
   * comparison is independent of whether the time is utc or in the local
   * time zone.
   */
  bool operator >=(Date other);


  /**
   * Returns [this] in the local time zone. Returns itself if it is already in
   * the local time zone. Otherwise, this method is equivalent to
   * [:new Date.fromMillisecondsSinceEpoch(millisecondsSinceEpoch, false):].
   */
  Date toLocal();

  /**
   * Returns [this] in UTC. Returns itself if it is already in UTC. Otherwise,
   * this method is equivalent to
   * [:new Date.fromMillisecondsSinceEpoch(millisecondsSinceEpoch, true):].
   */
  Date toUtc();

  /**
   * Returns the abbreviated time-zone name.
   *
   * Examples: [:"CET":] or [:"CEST":].
   */
  String get timeZoneName;

  /**
   * The time-zone offset is the difference between local time and UTC. That is,
   * the offset is positive for time zones west of UTC.
   *
   * Note, that JavaScript, Python and C return the difference between UTC and
   * local time. Java, C# and Ruby return the difference between local time and
   * UTC.
   */
  Duration get timeZoneOffset;

  /**
   * Returns the year.
   */
  int get year;

  /**
   * Returns the month into the year [1..12].
   */
  int get month;

  /**
   * Returns the day into the month [1..31].
   */
  int get day;

  /**
   * Returns the hour into the day [0..23].
   */
  int get hour;

  /**
   * Returns the minute into the hour [0...59].
   */
  int get minute;

  /**
   * Returns the second into the minute [0...59].
   */
  int get second;

  /**
   * Returns the millisecond into the second [0...999].
   */
  int get millisecond;

  /**
   * Returns the week day [MON..SUN]. In accordance with ISO 8601
   * a week starts with Monday which has the value 1.
   */
  int get weekday;

  /**
   * The milliseconds since 1970-01-01T00:00:00Z (UTC). This value is
   * independent of the time zone.
   *
   * See [Stopwatch] for means to measure time-spans.
   */
  int get millisecondsSinceEpoch;

  /**
   * True if this [Date] is set to UTC time.
   */
  bool get isUtc;

  /**
   * Returns a human readable string for this instance.
   * The returned string is constructed for the time zone of this instance.
   */
  String toString();

  /**
   * Returns a new [Date] with the [duration] added to this instance.
   */
  Date add(Duration duration);

  /**
   * Returns a new [Date] with the [duration] subtracted from this instance.
   */
  Date subtract(Duration duration);

  /**
   * Returns a [Duration] with the difference of [:this:] and [other].
   */
  Duration difference(Date other);
}
