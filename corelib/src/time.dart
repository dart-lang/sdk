// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart core library.

// TODO(floitsch): This class might change its name (e.g. TimeDuration).
interface Time extends Comparable factory TimeImplementation {
  /**
   * The time is the sum of all individual parts. This means that individual
   * parts don't need to be less than the next-bigger unit. For example [hours]
   * is allowed to have a value greater than 23.
   *
   * All individual parts are allowed to be negative.
   */
  const Time(int days, int hours, int minutes, int seconds, int milliseconds);
  /**
   * Constructs a time out of a duration. [duration] is in milliseconds.
   */
  const Time.duration(int duration);

  /**
   * Returns the number of days.
   */
  final int days;
  /**
   * Returns the number of hours [0..23].
   */
  final int hours;
  /**
   * Returns the number of minutes [0...59].
   */
  final int minutes;
  /**
   * Returns the number of seconds [0...59].
   */
  final int seconds;
  /**
   * Returns the number of milliseconds [0...999].
   */
  final int milliseconds;

  /**
   * Returns, in milliseconds, the sum of days, hours, minutes, seconds and
   * milliseconds.
   */
  int get duration();

  static final int MS_PER_SECOND = 1000;
  static final int SECONDS_PER_MINUTE = 60;
  static final int MINUTES_PER_HOUR = 60;
  static final int HOURS_PER_DAY = 24;

  static final int MS_PER_MINUTE = MS_PER_SECOND * SECONDS_PER_MINUTE;
  static final int MS_PER_HOUR = MS_PER_MINUTE * MINUTES_PER_HOUR;
  static final int MS_PER_DAY = MS_PER_HOUR * HOURS_PER_DAY;

  static final int SECONDS_PER_HOUR = SECONDS_PER_MINUTE * MINUTES_PER_HOUR;
  static final int SECONDS_PER_DAY = SECONDS_PER_HOUR * HOURS_PER_DAY;

  static final int MINUTES_PER_DAY = MINUTES_PER_HOUR * HOURS_PER_DAY;
}
