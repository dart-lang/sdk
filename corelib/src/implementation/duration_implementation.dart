// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart core library.

class DurationImplementation implements Duration {
  final int _durationInMilliseconds;

  const DurationImplementation([int days = 0,
                                int hours = 0,
                                int minutes = 0,
                                int seconds = 0,
                                int milliseconds = 0])
    : _durationInMilliseconds = days * Duration.MILLISECONDS_PER_DAY +
                                hours * Duration.MILLISECONDS_PER_HOUR +
                                minutes * Duration.MILLISECONDS_PER_MINUTE +
                                seconds * Duration.MILLISECONDS_PER_SECOND +
                                milliseconds;

  int get inDays() {
    return _durationInMilliseconds ~/ Duration.MILLISECONDS_PER_DAY;
  }

  int get inHours() {
    return _durationInMilliseconds ~/ Duration.MILLISECONDS_PER_HOUR;
  }

  int get inMinutes() {
    return _durationInMilliseconds ~/ Duration.MILLISECONDS_PER_MINUTE;
  }

  int get inSeconds() {
    return _durationInMilliseconds ~/ Duration.MILLISECONDS_PER_SECOND;
  }

  int get inMilliseconds() {
    return _durationInMilliseconds;
  }

  bool operator ==(other) {
    if (!(other is DurationImplementation)) return false;
    return _durationInMilliseconds == other.inMilliseconds;
  }

  int hashCode() {
    return _durationInMilliseconds.hashCode();
  }

  int compareTo(Duration other) {
    return inMilliseconds.compareTo(other.inMilliseconds);
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

    if (_durationInMilliseconds < 0) {
      Duration duration =
          new DurationImplementation(milliseconds: -_durationInMilliseconds);
      return "-${duration}";
    }
    String twoDigitMinutes =
        twoDigits(inMinutes.remainder(Duration.MINUTES_PER_HOUR));
    String twoDigitSeconds =
        twoDigits(inSeconds.remainder(Duration.SECONDS_PER_MINUTE));
    String threeDigitMs =
        threeDigits(inMilliseconds.remainder(Duration.MILLISECONDS_PER_SECOND));
    return "${inHours}:${twoDigitMinutes}:${twoDigitSeconds}.${threeDigitMs}";
  }
}
