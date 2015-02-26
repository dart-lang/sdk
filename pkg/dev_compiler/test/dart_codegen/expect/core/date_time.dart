part of dart.core;
 class DateTime implements Comparable {static const int MONDAY = 1;
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
 DateTime(int year, [int month = 1, int day = 1, int hour = 0, int minute = 0, int second = 0, int millisecond = 0]) : this._internal(year, month, day, hour, minute, second, millisecond, false);
 DateTime.utc(int year, [int month = 1, int day = 1, int hour = 0, int minute = 0, int second = 0, int millisecond = 0]) : this._internal(year, month, day, hour, minute, second, millisecond, true);
 DateTime.now() : this._now();
 static DateTime parse(String formattedString) {
  final RegExp re = new RegExp(r'^([+-]?\d{4,6})-?(\d\d)-?(\d\d)' r'(?:[ T](\d\d)(?::?(\d\d)(?::?(\d\d)(.\d{1,6})?)?)?' r'( ?[zZ]| ?([-+])(\d\d)(?::?(\d\d))?)?)?$');
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
     int millisecondsSinceEpoch = _brokenDownDateToMillisecondsSinceEpoch(years, month, day, hour, minute, second, millisecond, isUtc);
     if (millisecondsSinceEpoch == null) {
      throw new FormatException("Time out of range", formattedString);
      }
     if (addOneMillisecond) millisecondsSinceEpoch++;
     return new DateTime.fromMillisecondsSinceEpoch(millisecondsSinceEpoch, isUtc: isUtc);
    }
   else {
    throw new FormatException("Invalid date format", formattedString);
    }
  }
 static const int _MAX_MILLISECONDS_SINCE_EPOCH = 8640000000000000;
 DateTime.fromMillisecondsSinceEpoch(int millisecondsSinceEpoch, {
  bool isUtc : false}
) : this.millisecondsSinceEpoch = millisecondsSinceEpoch, this.isUtc = isUtc {
  if (millisecondsSinceEpoch.abs() > _MAX_MILLISECONDS_SINCE_EPOCH) {
    throw new ArgumentError(millisecondsSinceEpoch);
    }
   if (isUtc == null) throw new ArgumentError(isUtc);
  }
 bool operator ==(other) {
  if (!(other is DateTime)) return false;
   return (millisecondsSinceEpoch == other.millisecondsSinceEpoch && isUtc == other.isUtc);
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
 int compareTo(DateTime other) => millisecondsSinceEpoch.compareTo(other.millisecondsSinceEpoch);
 int get hashCode => millisecondsSinceEpoch;
 DateTime toLocal() {
  if (isUtc) {
    return new DateTime.fromMillisecondsSinceEpoch(millisecondsSinceEpoch, isUtc: false);
    }
   return this;
  }
 DateTime toUtc() {
  if (isUtc) return this;
   return new DateTime.fromMillisecondsSinceEpoch(millisecondsSinceEpoch, isUtc: true);
  }
 static String _fourDigits(int n) {
  int absN = n.abs();
   String sign = n < 0 ? "-" : "";
   if (absN >= 1000) return "$n";
   if (absN >= 100) return "${sign}
0$absN";
 if (absN >= 10) return "${sign}
00$absN";
 return "${sign}
000$absN";
}
 static String _sixDigits(int n) {
assert (n < -9999 || n > 9999); int absN = n.abs();
 String sign = n < 0 ? "-" : "+";
 if (absN >= 100000) return "$sign$absN";
 return "${sign}
0$absN";
}
 static String _threeDigits(int n) {
if (n >= 100) return "${n}
";
 if (n >= 10) return "0${n}
";
 return "00${n}
";
}
 static String _twoDigits(int n) {
if (n >= 10) return "${n}
";
 return "0${n}
";
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
return "$y-$m-$d $h:$min:$sec.${ms}
Z";
}
 else {
return "$y-$m-$d $h:$min:$sec.$ms";
}
}
 String toIso8601String() {
String y = (year >= -9999 && year <= 9999) ? _fourDigits(year) : _sixDigits(year);
 String m = _twoDigits(month);
 String d = _twoDigits(day);
 String h = _twoDigits(hour);
 String min = _twoDigits(minute);
 String sec = _twoDigits(second);
 String ms = _threeDigits(millisecond);
 if (isUtc) {
return "$y-$m-${d}
T$h:$min:$sec.${ms}
Z";
}
 else {
return "$y-$m-${d}
T$h:$min:$sec.$ms";
}
}
 DateTime add(Duration duration) {
int ms = millisecondsSinceEpoch;
 return new DateTime.fromMillisecondsSinceEpoch(ms + duration.inMilliseconds, isUtc: isUtc);
}
 DateTime subtract(Duration duration) {
int ms = millisecondsSinceEpoch;
 return new DateTime.fromMillisecondsSinceEpoch(ms - duration.inMilliseconds, isUtc: isUtc);
}
 Duration difference(DateTime other) {
int ms = millisecondsSinceEpoch;
 int otherMs = other.millisecondsSinceEpoch;
 return new Duration(milliseconds: ms - otherMs);
}
 external DateTime._internal(int year, int month, int day, int hour, int minute, int second, int millisecond, bool isUtc);
 external DateTime._now();
 external static int _brokenDownDateToMillisecondsSinceEpoch(int year, int month, int day, int hour, int minute, int second, int millisecond, bool isUtc);
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
