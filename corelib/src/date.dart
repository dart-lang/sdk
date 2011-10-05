// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart core library.

interface Date extends Comparable factory DateImplementation {
  /**
   * Creates a [Date] object for the given [year], [month] and [day].
   * No checks are performed on the input values.
   */
  const Date(int year, int month, int day);

  /**
   * Returns the year of the date.
   */
  int get year();
  /**
   * Returns the month of the date [JAN..DEC].
   */
  int get month();
  /**
   * Returns the day of the date [1..31].
   */
  int get day();

  /**
   * Returns the week day [MON..SUN].
   *
   * If the date is invalid throws an exception.
   * TODO(floitsch): what exception?
   */
  int get weekday();

  // Constants.

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
}
