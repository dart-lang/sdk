// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart core library.

class TimeImplementation implements Time {
  final int _duration;

  const TimeImplementation(int days,
                           int hours,
                           int minutes,
                           int seconds,
                           int milliseconds)
    : _duration = days * Time.MS_PER_DAY +
                  hours * Time.MS_PER_HOUR +
                  minutes * Time.MS_PER_MINUTE +
                  seconds * Time.MS_PER_SECOND +
                  milliseconds;

  const TimeImplementation.duration(int duration) : _duration = duration;

  int get days() {
    return _duration ~/ Time.MS_PER_DAY;
  }

  int get hours() {
    int hours = _duration ~/ Time.MS_PER_HOUR;
    return hours.remainder(Time.HOURS_PER_DAY);
  }

  int get minutes() {
    int minutes = _duration ~/ Time.MS_PER_MINUTE;
    return minutes.remainder(Time.MINUTES_PER_HOUR);
  }

  int get seconds() {
    int seconds = _duration ~/ Time.MS_PER_SECOND;
    return seconds.remainder(Time.SECONDS_PER_MINUTE);
  }

  int get milliseconds() {
    return _duration.remainder(Time.MS_PER_SECOND);
  }

  int get duration() {
    return _duration;
  }

  bool operator ==(other) {
    if (!(other is TimeImplementation)) return false;
    return other.duration == _duration;
  }

  int hashCode() {
    return duration.hashCode();
  }

  int compareTo(Time other) {
    return duration.compareTo(other.duration);
  }

  String toString() {
    String threeDigits(int n) {
      if (n >= 100) return "${n}";
      if (n > 10) return "0${n}";
      return "00${n}";
    }
    String twoDigits(int n) {
      if (n >= 10) return "${n}";
      return "0${n}";
    }

    if (_duration < 0) {
      Time time = new TimeImplementation.duration(-duration);
      return "-${time}";
    }
    int allHours = 24 * days + hours;
    String twoDigitMinutes = twoDigits(minutes);
    String twoDigitSeconds = twoDigits(seconds);
    String threeDigitMs = threeDigits(milliseconds);
    return "${allHours}:${twoDigitMinutes}:${twoDigitSeconds}.${threeDigitMs}";
  }
}
