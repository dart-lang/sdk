part of dart.core;
 class Duration implements Comparable<Duration> {static const int MICROSECONDS_PER_MILLISECOND = 1000;
 static const int MILLISECONDS_PER_SECOND = 1000;
 static const int SECONDS_PER_MINUTE = 60;
 static const int MINUTES_PER_HOUR = 60;
 static const int HOURS_PER_DAY = 24;
 static const int MICROSECONDS_PER_SECOND = MICROSECONDS_PER_MILLISECOND * MILLISECONDS_PER_SECOND;
 static const int MICROSECONDS_PER_MINUTE = MICROSECONDS_PER_SECOND * SECONDS_PER_MINUTE;
 static const int MICROSECONDS_PER_HOUR = MICROSECONDS_PER_MINUTE * MINUTES_PER_HOUR;
 static const int MICROSECONDS_PER_DAY = MICROSECONDS_PER_HOUR * HOURS_PER_DAY;
 static const int MILLISECONDS_PER_MINUTE = MILLISECONDS_PER_SECOND * SECONDS_PER_MINUTE;
 static const int MILLISECONDS_PER_HOUR = MILLISECONDS_PER_MINUTE * MINUTES_PER_HOUR;
 static const int MILLISECONDS_PER_DAY = MILLISECONDS_PER_HOUR * HOURS_PER_DAY;
 static const int SECONDS_PER_HOUR = SECONDS_PER_MINUTE * MINUTES_PER_HOUR;
 static const int SECONDS_PER_DAY = SECONDS_PER_HOUR * HOURS_PER_DAY;
 static const int MINUTES_PER_DAY = MINUTES_PER_HOUR * HOURS_PER_DAY;
 static const Duration ZERO = const Duration(seconds: 0);
 final int _duration;
 const Duration({
  int days : 0, int hours : 0, int minutes : 0, int seconds : 0, int milliseconds : 0, int microseconds : 0}
) : this._microseconds(days * MICROSECONDS_PER_DAY + hours * MICROSECONDS_PER_HOUR + minutes * MICROSECONDS_PER_MINUTE + seconds * MICROSECONDS_PER_SECOND + milliseconds * MICROSECONDS_PER_MILLISECOND + microseconds);
 const Duration._microseconds(this._duration);
 Duration operator +(Duration other) {
  return new Duration._microseconds(_duration + other._duration);
  }
 Duration operator -(Duration other) {
  return new Duration._microseconds(_duration - other._duration);
  }
 Duration operator *(num factor) {
  return new Duration._microseconds((_duration * factor).round());
  }
 Duration operator ~/(int quotient) {
  if (quotient == 0) throw new IntegerDivisionByZeroException();
   return new Duration._microseconds(_duration ~/ quotient);
  }
 bool operator <(Duration other) => this._duration < other._duration;
 bool operator >(Duration other) => this._duration > other._duration;
 bool operator <=(Duration other) => this._duration <= other._duration;
 bool operator >=(Duration other) => this._duration >= other._duration;
 int get inDays => _duration ~/ Duration.MICROSECONDS_PER_DAY;
 int get inHours => _duration ~/ Duration.MICROSECONDS_PER_HOUR;
 int get inMinutes => _duration ~/ Duration.MICROSECONDS_PER_MINUTE;
 int get inSeconds => _duration ~/ Duration.MICROSECONDS_PER_SECOND;
 int get inMilliseconds => _duration ~/ Duration.MICROSECONDS_PER_MILLISECOND;
 int get inMicroseconds => _duration;
 bool operator ==(other) {
  if (other is! Duration) return false;
   return _duration == other._duration;
  }
 int get hashCode => _duration.hashCode;
 int compareTo(Duration other) => _duration.compareTo(other._duration);
 String toString() {
  String sixDigits(int n) {
    if (n >= 100000) return "$n";
     if (n >= 10000) return "0$n";
     if (n >= 1000) return "00$n";
     if (n >= 100) return "000$n";
     if (n >= 10) return "0000$n";
     return "00000$n";
    }
   String twoDigits(int n) {
    if (n >= 10) return "$n";
     return "0$n";
    }
   if (inMicroseconds < 0) {
    return "-${-this}
  ";
  }
 String twoDigitMinutes = twoDigits(((__x0) => DDC$RT.cast(__x0, num, int, "CastGeneral", """line 258, column 40 of dart:core/duration.dart: """, __x0 is int, true))(inMinutes.remainder(MINUTES_PER_HOUR)));
 String twoDigitSeconds = twoDigits(((__x1) => DDC$RT.cast(__x1, num, int, "CastGeneral", """line 259, column 40 of dart:core/duration.dart: """, __x1 is int, true))(inSeconds.remainder(SECONDS_PER_MINUTE)));
 String sixDigitUs = sixDigits(((__x2) => DDC$RT.cast(__x2, num, int, "CastGeneral", """line 261, column 19 of dart:core/duration.dart: """, __x2 is int, true))(inMicroseconds.remainder(MICROSECONDS_PER_SECOND)));
 return "$inHours:$twoDigitMinutes:$twoDigitSeconds.$sixDigitUs";
}
 bool get isNegative => _duration < 0;
 Duration abs() => new Duration._microseconds(_duration.abs());
 Duration operator -() => new Duration._microseconds(-_duration);
}
