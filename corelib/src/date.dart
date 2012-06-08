// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart core library.

/**
 * Date is the public interface to a point in time.
 */
interface Date extends Comparable, Hashable default DateImplementation {
  // Weekday constants that are returned by [weekday] method:
  static final int MON = 0;
  static final int TUE = 1;
  static final int WED = 2;
  static final int THU = 3;
  static final int FRI = 4;
  static final int SAT = 5;
  static final int SUN = 6;
  static final int DAYS_IN_WEEK = 7;

  // Month constants that are returned by the [month] getter.
  static final int JAN = 1;
  static final int FEB = 2;
  static final int MAR = 3;
  static final int APR = 4;
  static final int MAY = 5;
  static final int JUN = 6;
  static final int JUL = 7;
  static final int AUG = 8;
  static final int SEP = 9;
  static final int OCT = 10;
  static final int NOV = 11;
  static final int DEC = 12;

  /**
   * Constructs a [Date] instance based on the individual parts. The date is
   * in the local time-zone if [isUtc] is false.
   */
  // TODO(floitsch): the spec allows default values in interfaces, but our
  // tools don't yet. Eventually we want to have default values here.
  Date(int year,
       [int month,
        int day,
        int hours,
        int minutes,
        int seconds,
        int milliseconds,
        bool isUtc]);

  /**
   * Constructs a [Date] instance based on the individual parts.
   * [timeZone] may not be [:null:].
   *
   * *DEPRECATED*
   */
  Date.withTimeZone(int year,
                    int month,
                    int day,
                    int hours,
                    int minutes,
                    int seconds,
                    int milliseconds,
                    TimeZone timeZone);

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
   * Constructs a new [Date] instance with the given [value]. If [isUtc] is
   * false then the date is in the local time-zone.
   *
   * The constructed [Date] represents 1970-01-01T00:00:00Z + [value]ms in
   * the given time-zone (local or UTC).
   */
  // TODO(floitsch): the spec allows default values in interfaces, but our
  // tools don't yet. Eventually we want to have default values here.
  Date.fromEpoch(int value, [bool isUtc]);

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
   * Returns [this] in the local time-zone. Returns itself if it is already in
   * the local time zone. Otherwise, this method is equivalent to
   * [:new Date.fromEpoch(this.value, isUtc: false):].
   */
  Date toLocal();

  /**
   * Returns [this] in UTC. Returns itself if it is already in UTC. Otherwise,
   * this method is equivalent to
   * [:new Date.fromEpoch(this.value, isUtc: true):].
   */
  Date toUtc();

  /**
   * Returns a new [Date] in the given [targetTimeZone] time zone. The
   * [value] of the new instance is equal to [:this.value:].
   *
   * This call is equivalent to
   *  [:new Date.fromEpoch(this.value, targetTimeZone):].
   *
   * *DEPRECATED*
   */
  Date changeTimeZone(TimeZone targetTimeZone);

  /**
   * Returns the abbreviated time-zone name.
   *
   * Examples: [:"CET":] or [:"CEST":].
   */
  String get timeZoneName();

  /**
   * The time-zone offset is the difference between local time and UTC. That is,
   * the offset is positive for time zones west of UTC.
   *
   * Note, that JavaScript, Python and C return the difference between UTC and
   * local time. Java, C# and Ruby return the difference between local time and
   * UTC.
   */
  Duration get timeZoneOffset();

  /**
   * Returns the year.
   */
  int get year();

  /**
   * Returns the month in the year [1..12].
   */
  int get month();

  /**
   * Returns the day in the month [1..31].
   */
  int get day();

  /**
   * Returns the number of hours [0..23].
   */
  int get hours();

  /**
   * Returns the number of minutes [0...59].
   */
  int get minutes();

  /**
   * Returns the number of seconds [0...59].
   */
  int get seconds();

  /**
   * Returns the number of milliseconds [0...999].
   */
  int get milliseconds();

  /**
   * Returns the week day [MON..SUN]
   */
  int get weekday();

  /**
   * Returns milliseconds from 1970-01-01T00:00:00Z (UTC).
   *
   * Note that this value is independent of the time zone.
   */
  final int value;

  /**
   * Returns true if this [Date] is set to UTC time.
   */
  bool isUtc();

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
