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
abstract class Date implements Comparable {
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
   * in the local time zone.
   *
   * [month] and [day] are one-based. For example
   * [:new Date(1938, 1, 10):] represents the 10th of January 1938.
   */
  factory Date(int year,
               [int month = 1,
                int day = 1,
                int hour = 0,
                int minute = 0,
                int second = 0,
                int millisecond = 0]) {
    return new _DateImpl(
        year, month, day, hour, minute, second, millisecond, false);
  }

  /**
   * Constructs a [Date] instance based on the individual parts. The date is
   * in the UTC time zone.
   *
   * [month] and [day] are one-based. For example
   * [:new Date.utc(1938, 1, 10):] represents the 10th of January 1938 in
   * Coordinated Universal Time.
   */
  factory Date.utc(int year,
                   [int month = 1,
                    int day = 1,
                    int hour = 0,
                    int minute = 0,
                    int second = 0,
                    int millisecond = 0]) {
    return new _DateImpl(
        year, month, day, hour, minute, second, millisecond, true);
  }

  /**
   * Constructs a new [Date] instance with current date time value in the
   * local time zone.
   */
  factory Date.now() => new _DateImpl.now();

  /**
   * Constructs a new [Date] instance based on [formattedString].
   */
  factory Date.fromString(String formattedString)
      => new _DateImpl.fromString(formattedString);

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
  // TODO(lrn): Have two constructors instead of taking an optional bool.
  factory Date.fromMillisecondsSinceEpoch(int millisecondsSinceEpoch,
                                          {bool isUtc: false}) {
    return new _DateImpl.fromMillisecondsSinceEpoch(millisecondsSinceEpoch,
                                                    isUtc);
  }

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
   * [:new Date.fromMillisecondsSinceEpoch(millisecondsSinceEpoch,
   *                                       isUtc: false):].
   */
  Date toLocal();

  /**
   * Returns [this] in UTC. Returns itself if it is already in UTC. Otherwise,
   * this method is equivalent to
   * [:new Date.fromMillisecondsSinceEpoch(millisecondsSinceEpoch,
   *                                       isUtc: true):].
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

class _DateImpl implements Date {
  final int millisecondsSinceEpoch;
  final bool isUtc;

  factory _DateImpl.fromString(String formattedString) {
    // Read in (a subset of) ISO 8601.
    // Examples:
    //    - "2012-02-27 13:27:00"
    //    - "2012-02-27 13:27:00.423z"
    //    - "20120227 13:27:00"
    //    - "20120227T132700"
    //    - "20120227"
    //    - "2012-02-27T14Z"
    //    - "-123450101 00:00:00 Z"  // In the year -12345.
    final RegExp re = const RegExp(
        r'^([+-]?\d?\d\d\d\d)-?(\d\d)-?(\d\d)'  // The day part.
        r'(?:[ T](\d\d)(?::?(\d\d)(?::?(\d\d)(.\d{1,6})?)?)? ?([zZ])?)?$');
    Match match = re.firstMatch(formattedString);
    if (match !== null) {
      int parseIntOrZero(String matched) {
        // TODO(floitsch): we should not need to test against the empty string.
        if (matched === null || matched == "") return 0;
        return int.parse(matched);
      }

      double parseDoubleOrZero(String matched) {
        // TODO(floitsch): we should not need to test against the empty string.
        if (matched === null || matched == "") return 0.0;
        return double.parse(matched);
      }

      int years = int.parse(match[1]);
      int month = int.parse(match[2]);
      int day = int.parse(match[3]);
      int hour = parseIntOrZero(match[4]);
      int minute = parseIntOrZero(match[5]);
      int second = parseIntOrZero(match[6]);
      bool addOneMillisecond = false;
      int millisecond = (parseDoubleOrZero(match[7]) * 1000).round().toInt();
      if (millisecond == 1000) {
        addOneMillisecond = true;
        millisecond = 999;
      }
      // TODO(floitsch): we should not need to test against the empty string.
      bool isUtc = (match[8] !== null) && (match[8] != "");
      int millisecondsSinceEpoch = _brokenDownDateToMillisecondsSinceEpoch(
          years, month, day, hour, minute, second, millisecond, isUtc);
      if (millisecondsSinceEpoch === null) {
        throw new ArgumentError(formattedString);
      }
      if (addOneMillisecond) millisecondsSinceEpoch++;
      return new Date.fromMillisecondsSinceEpoch(millisecondsSinceEpoch,
                                                 isUtc: isUtc);
    } else {
      throw new ArgumentError(formattedString);
    }
  }

  static const int _MAX_MILLISECONDS_SINCE_EPOCH = 8640000000000000;

  _DateImpl.fromMillisecondsSinceEpoch(this.millisecondsSinceEpoch,
                                       this.isUtc) {
    if (millisecondsSinceEpoch.abs() > _MAX_MILLISECONDS_SINCE_EPOCH) {
      throw new ArgumentError(millisecondsSinceEpoch);
    }
    if (isUtc === null) throw new ArgumentError(isUtc);
  }

  bool operator ==(other) {
    if (!(other is Date)) return false;
    return (millisecondsSinceEpoch == other.millisecondsSinceEpoch);
  }

  bool operator <(Date other)
      => millisecondsSinceEpoch < other.millisecondsSinceEpoch;

  bool operator <=(Date other)
      => millisecondsSinceEpoch <= other.millisecondsSinceEpoch;

  bool operator >(Date other)
      => millisecondsSinceEpoch > other.millisecondsSinceEpoch;

  bool operator >=(Date other)
      => millisecondsSinceEpoch >= other.millisecondsSinceEpoch;

  int compareTo(Date other)
      => millisecondsSinceEpoch.compareTo(other.millisecondsSinceEpoch);

  int get hashCode => millisecondsSinceEpoch;

  Date toLocal() {
    if (isUtc) {
      return new Date.fromMillisecondsSinceEpoch(millisecondsSinceEpoch,
                                                 isUtc: false);
    }
    return this;
  }

  Date toUtc() {
    if (isUtc) return this;
    return new Date.fromMillisecondsSinceEpoch(millisecondsSinceEpoch,
                                               isUtc: true);
  }

  String toString() {
    String fourDigits(int n) {
      int absN = n.abs();
      String sign = n < 0 ? "-" : "";
      if (absN >= 1000) return "$n";
      if (absN >= 100) return "${sign}0$absN";
      if (absN >= 10) return "${sign}00$absN";
      return "${sign}000$absN";
    }

    String threeDigits(int n) {
      if (n >= 100) return "${n}";
      if (n >= 10) return "0${n}";
      return "00${n}";
    }

    String twoDigits(int n) {
      if (n >= 10) return "${n}";
      return "0${n}";
    }

    String y = fourDigits(year);
    String m = twoDigits(month);
    String d = twoDigits(day);
    String h = twoDigits(hour);
    String min = twoDigits(minute);
    String sec = twoDigits(second);
    String ms = threeDigits(millisecond);
    if (isUtc) {
      return "$y-$m-$d $h:$min:$sec.${ms}Z";
    } else {
      return "$y-$m-$d $h:$min:$sec.$ms";
    }
  }

  /** Returns a new [Date] with the [duration] added to [this]. */
  Date add(Duration duration) {
    int ms = millisecondsSinceEpoch;
    return new Date.fromMillisecondsSinceEpoch(
        ms + duration.inMilliseconds, isUtc: isUtc);
  }

  /** Returns a new [Date] with the [duration] subtracted from [this]. */
  Date subtract(Duration duration) {
    int ms = millisecondsSinceEpoch;
    return new Date.fromMillisecondsSinceEpoch(
        ms - duration.inMilliseconds, isUtc: isUtc);
  }

  /** Returns a [Duration] with the difference of [this] and [other]. */
  Duration difference(Date other) {
    int ms = millisecondsSinceEpoch;
    int otherMs = other.millisecondsSinceEpoch;
    return new Duration(milliseconds: ms - otherMs);
  }

  external _DateImpl(int year,
                     int month,
                     int day,
                     int hour,
                     int minute,
                     int second,
                     int millisecond,
                     bool isUtc);
  external _DateImpl.now();
  external static int _brokenDownDateToMillisecondsSinceEpoch(
      int year, int month, int day, int hour, int minute, int second,
      int millisecond, bool isUtc);
  external String get timeZoneName;
  external Duration get timeZoneOffset;
  external int get year;
  external int get month;
  external int get day;
  external int get hour;
  external int get minute;
  external int get second;
  external int get millisecond;
  external int get weekday;
}
