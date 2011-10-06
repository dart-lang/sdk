// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart core library.

/**
 * DateTime is the public interface to a point in time.
 */
interface DateTime extends Comparable factory DateTimeImplementation {
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
   * Constructs a [DateTime] instance based on the individual parts, in the
   * local time-zone.
   */
  DateTime(int year,
           int month,
           int day,
           int hours,
           int minutes,
           int seconds,
           int milliseconds);

  /**
   * Constructs a [DateTime] instance based on the individual parts.
   * [timeZone] may not be [:null:].
   */
  DateTime.withTimeZone(int year,
                        int month,
                        int day,
                        int hours,
                        int minutes,
                        int seconds,
                        int milliseconds,
                        TimeZone timeZone);

  /**
   * Constructs a new [DateTime] instance with current date time value.
   * The [timeZone] of this instance is set to the local time-zone.
   */
  DateTime.now();

  /**
   * Constructs a new [DateTime] instance based on [formattedString].
   */
  DateTime.fromString(String formattedString);

  /**
   * Constructs a new [DateTime] instance with the given time zone. The given
   * [timeZone] must not be [:null:].
   *
   * This constructor is the only one that doesn't need to be computations and
   * which can therefore be [:const:].
   *
   * The constructed [DateTime] represents 1970-01-01T00:00:00Z + [value]ms in
   * the given [timeZone].
   */
  const DateTime.fromEpoch(int value, TimeZone timeZone);

  /**
   * Returns a new [DateTime] in the given [targetTimeZone] time zone. The
   * [value] of the new instance is equal to [:this.value:].
   *
   * This call is equivalent to
   *  [:new DateTime.fromEpoch(this.value, targetTimeZone):].
   */
  DateTime changeTimeZone(TimeZone targetTimeZone);

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
   * Note that this value is independent of [timeZone].
   */
  final int value;

  /**
   * Returns the timeZone of this instance.
   */
  final TimeZone timeZone;

  /**
   * Returns true if this [DateTime] is set to local time.
   */
  bool isLocalTime();

  /**
   * Returns true if this [DateTime] is set to UTC time.
   * This is equivalent to [:this.timeZone.duration == 0:].
   */
  bool isUtc();

  /**
   * Returns a human readable string for this instance.
   * The returned string is constructed for the [timeZone] of this instance.
   */
  String toString();

  /**
   * Returns a new [DateTime] with the time [other] added to this instance.
   */
  DateTime add(Time other);

  /**
   * Returns a new [DateTime] with the time [other] subtracted from this
   * instance.
   */
  DateTime subtract(Time other);

  /**
   * Returns a [Time] with the difference of [:this:] and [other].
   */
  Time difference(DateTime other);
}
