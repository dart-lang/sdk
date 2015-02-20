part of dart.core;

class DateTime implements Comparable {
  static const int MONDAY = 1;
  static const int TUESDAY = 2;
  static const int WEDNESDAY = 3;
  static const int THURSDAY = 4;
  static const int FRIDAY = 5;
  static const int SATURDAY = 6;
  static const int SUNDAY = 7;
  static const int DAYS_PER_WEEK = 7;
  static const int JANUARY = 1;
  static const int FEBRUARY = 2;
  static const int MARCH = 3;
  static const int APRIL = 4;
  static const int MAY = 5;
  static const int JUNE = 6;
  static const int JULY = 7;
  static const int AUGUST = 8;
  static const int SEPTEMBER = 9;
  static const int OCTOBER = 10;
  static const int NOVEMBER = 11;
  static const int DECEMBER = 12;
  static const int MONTHS_PER_YEAR = 12;
  final int millisecondsSinceEpoch;
  final bool isUtc;
  DateTime(int year, [int month = 1, int day = 1, int hour = 0, int minute = 0,
      int second = 0, int millisecond = 0])
      : this._internal(
          year, month, day, hour, minute, second, millisecond, false);
  DateTime.utc(int year, [int month = 1, int day = 1, int hour = 0,
      int minute = 0, int second = 0, int millisecond = 0])
      : this._internal(
          year, month, day, hour, minute, second, millisecond, true);
  DateTime.now() : this._now();
  static DateTime parse(String formattedString) {
    final RegExp re = new RegExp(
        r'^([+-]?\d{4,6})-?(\d\d)-?(\d\d)' r'(?:[ T](\d\d)(?::?(\d\d)(?::?(\d\d)(.\d{1,6})?)?)?' r'( ?[zZ]| ?([-+])(\d\d)(?::?(\d\d))?)?)?$');
    Match match = re.firstMatch(formattedString);
    if (match != null) {
      int parseIntOrZero(String matched) {
        if (matched == null) return 0;
        return int.parse(matched);
      }
      double parseDoubleOrZero(String matched) {
        if (matched == null) return 0.0;
        return double.parse(matched);
      }
      int years = int.parse(match[1]);
      int month = int.parse(match[2]);
      int day = int.parse(match[3]);
      int hour = parseIntOrZero(match[4]);
      int minute = parseIntOrZero(match[5]);
      int second = parseIntOrZero(match[6]);
      bool addOneMillisecond = false;
      int millisecond = (parseDoubleOrZero(match[7]) * 1000).round();
      if (millisecond == 1000) {
        addOneMillisecond = true;
        millisecond = 999;
      }
      bool isUtc = false;
      if (match[8] != null) {
        isUtc = true;
        if (match[9] != null) {
          int sign = (match[9] == '-') ? -1 : 1;
          int hourDifference = int.parse(match[10]);
          int minuteDifference = parseIntOrZero(match[11]);
          minuteDifference += 60 * hourDifference;
          minute -= sign * minuteDifference;
        }
      }
      int millisecondsSinceEpoch = _brokenDownDateToMillisecondsSinceEpoch(
          years, month, day, hour, minute, second, millisecond, isUtc);
      if (millisecondsSinceEpoch == null) {
        throw new FormatException("Time out of range", formattedString);
      }
      if (addOneMillisecond) millisecondsSinceEpoch++;
      return new DateTime.fromMillisecondsSinceEpoch(millisecondsSinceEpoch,
          isUtc: isUtc);
    } else {
      throw new FormatException("Invalid date format", formattedString);
    }
  }
  static const int _MAX_MILLISECONDS_SINCE_EPOCH = 8640000000000000;
  DateTime.fromMillisecondsSinceEpoch(int millisecondsSinceEpoch,
      {bool isUtc: false})
      : this.millisecondsSinceEpoch = millisecondsSinceEpoch,
        this.isUtc = isUtc {
    if (millisecondsSinceEpoch.abs() > _MAX_MILLISECONDS_SINCE_EPOCH) {
      throw new ArgumentError(millisecondsSinceEpoch);
    }
    if (isUtc == null) throw new ArgumentError(isUtc);
  }
  bool operator ==(other) {
    if (!(other is DateTime)) return false;
    return (millisecondsSinceEpoch == other.millisecondsSinceEpoch &&
        isUtc == other.isUtc);
  }
  bool isBefore(DateTime other) {
    return millisecondsSinceEpoch < other.millisecondsSinceEpoch;
  }
  bool isAfter(DateTime other) {
    return millisecondsSinceEpoch > other.millisecondsSinceEpoch;
  }
  bool isAtSameMomentAs(DateTime other) {
    return millisecondsSinceEpoch == other.millisecondsSinceEpoch;
  }
  int compareTo(DateTime other) =>
      millisecondsSinceEpoch.compareTo(other.millisecondsSinceEpoch);
  int get hashCode => millisecondsSinceEpoch;
  DateTime toLocal() {
    if (isUtc) {
      return new DateTime.fromMillisecondsSinceEpoch(millisecondsSinceEpoch,
          isUtc: false);
    }
    return this;
  }
  DateTime toUtc() {
    if (isUtc) return this;
    return new DateTime.fromMillisecondsSinceEpoch(millisecondsSinceEpoch,
        isUtc: true);
  }
  static String _fourDigits(int n) {
    int absN = n.abs();
    String sign = n < 0 ? "-" : "";
    if (absN >= 1000) return "$n";
    if (absN >= 100) return "${sign}0$absN";
    if (absN >= 10) return "${sign}00$absN";
    return "${sign}000$absN";
  }
  static String _sixDigits(int n) {
    assert(n < -9999 || n > 9999);
    int absN = n.abs();
    String sign = n < 0 ? "-" : "+";
    if (absN >= 100000) return "$sign$absN";
    return "${sign}0$absN";
  }
  static String _threeDigits(int n) {
    if (n >= 100) return "${n}";
    if (n >= 10) return "0${n}";
    return "00${n}";
  }
  static String _twoDigits(int n) {
    if (n >= 10) return "${n}";
    return "0${n}";
  }
  String toString() {
    String y = _fourDigits(year);
    String m = _twoDigits(month);
    String d = _twoDigits(day);
    String h = _twoDigits(hour);
    String min = _twoDigits(minute);
    String sec = _twoDigits(second);
    String ms = _threeDigits(millisecond);
    if (isUtc) {
      return "$y-$m-$d $h:$min:$sec.${ms}Z";
    } else {
      return "$y-$m-$d $h:$min:$sec.$ms";
    }
  }
  String toIso8601String() {
    String y =
        (year >= -9999 && year <= 9999) ? _fourDigits(year) : _sixDigits(year);
    String m = _twoDigits(month);
    String d = _twoDigits(day);
    String h = _twoDigits(hour);
    String min = _twoDigits(minute);
    String sec = _twoDigits(second);
    String ms = _threeDigits(millisecond);
    if (isUtc) {
      return "$y-$m-${d}T$h:$min:$sec.${ms}Z";
    } else {
      return "$y-$m-${d}T$h:$min:$sec.$ms";
    }
  }
  DateTime add(Duration duration) {
    int ms = millisecondsSinceEpoch;
    return new DateTime.fromMillisecondsSinceEpoch(ms + duration.inMilliseconds,
        isUtc: isUtc);
  }
  DateTime subtract(Duration duration) {
    int ms = millisecondsSinceEpoch;
    return new DateTime.fromMillisecondsSinceEpoch(ms - duration.inMilliseconds,
        isUtc: isUtc);
  }
  Duration difference(DateTime other) {
    int ms = millisecondsSinceEpoch;
    int otherMs = other.millisecondsSinceEpoch;
    return new Duration(milliseconds: ms - otherMs);
  }
  @patch DateTime._internal(int year, int month, int day, int hour, int minute,
      int second, int millisecond, bool isUtc)
      : this.isUtc = isUtc is bool ? isUtc : throw new ArgumentError(isUtc),
        millisecondsSinceEpoch = checkInt(Primitives.valueFromDecomposedDate(
            year, month, day, hour, minute, second, millisecond, isUtc));
  @patch DateTime._now()
      : isUtc = false,
        millisecondsSinceEpoch = Primitives.dateNow();
  @patch static int _brokenDownDateToMillisecondsSinceEpoch(int year, int month,
      int day, int hour, int minute, int second, int millisecond, bool isUtc) {
    return ((__x0) => DDC$RT.cast(__x0, dynamic, int, "CastGeneral",
            """line 600, column 12 of dart:core/date_time.dart: """,
            __x0 is int, true))(Primitives.valueFromDecomposedDate(
        year, month, day, hour, minute, second, millisecond, isUtc));
  }
  @patch String get timeZoneName {
    if (isUtc) return "UTC";
    return ((__x1) => DDC$RT.cast(__x1, dynamic, String, "CastGeneral",
        """line 607, column 12 of dart:core/date_time.dart: """, __x1 is String,
        true))(Primitives.getTimeZoneName(this));
  }
  @patch Duration get timeZoneOffset {
    if (isUtc) return new Duration();
    return new Duration(minutes: Primitives.getTimeZoneOffsetInMinutes(this));
  }
  @patch int get year => ((__x2) => DDC$RT.cast(__x2, dynamic, int,
      "CastGeneral", """line 617, column 19 of dart:core/date_time.dart: """,
      __x2 is int, true))(Primitives.getYear(this));
  @patch int get month => ((__x3) => DDC$RT.cast(__x3, dynamic, int,
      "CastGeneral", """line 620, column 20 of dart:core/date_time.dart: """,
      __x3 is int, true))(Primitives.getMonth(this));
  @patch int get day => ((__x4) => DDC$RT.cast(__x4, dynamic, int,
      "CastGeneral", """line 623, column 18 of dart:core/date_time.dart: """,
      __x4 is int, true))(Primitives.getDay(this));
  @patch int get hour => ((__x5) => DDC$RT.cast(__x5, dynamic, int,
      "CastGeneral", """line 626, column 19 of dart:core/date_time.dart: """,
      __x5 is int, true))(Primitives.getHours(this));
  @patch int get minute => ((__x6) => DDC$RT.cast(__x6, dynamic, int,
      "CastGeneral", """line 629, column 21 of dart:core/date_time.dart: """,
      __x6 is int, true))(Primitives.getMinutes(this));
  @patch int get second => ((__x7) => DDC$RT.cast(__x7, dynamic, int,
      "CastGeneral", """line 632, column 21 of dart:core/date_time.dart: """,
      __x7 is int, true))(Primitives.getSeconds(this));
  @patch int get millisecond => ((__x8) => DDC$RT.cast(__x8, dynamic, int,
      "CastGeneral", """line 635, column 26 of dart:core/date_time.dart: """,
      __x8 is int, true))(Primitives.getMilliseconds(this));
  @patch int get weekday => ((__x9) => DDC$RT.cast(__x9, dynamic, int,
      "CastGeneral", """line 638, column 22 of dart:core/date_time.dart: """,
      __x9 is int, true))(Primitives.getWeekday(this));
}
