// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class _HttpUtils {
  static String decodeUrlEncodedString(String urlEncoded) {
    void invalidEscape() {
      // TODO(sgjesse): Handle the error.
    }

    StringBuffer result = new StringBuffer();
    for (int ii = 0; urlEncoded.length > ii; ++ii) {
      if ('+' == urlEncoded[ii]) {
        result.add(' ');
      } else if ('%' == urlEncoded[ii] &&
                 urlEncoded.length - 2 > ii) {
        try {
          int charCode =
            Math.parseInt('0x' + urlEncoded.substring(ii + 1, ii + 3));
          if (charCode <= 0x7f) {
            result.add(new String.fromCharCodes([charCode]));
            ii += 2;
          } else {
            invalidEscape();
            return '';
          }
        } catch (BadNumberFormatException ignored) {
          invalidEscape();
          return '';
        }
      } else {
        result.add(urlEncoded[ii]);
      }
    }
    return result.toString();
  }

  static Map<String, String> splitQueryString(String queryString) {
    Map<String, String> result = new Map<String, String>();
    int currentPosition = 0;
    while (currentPosition < queryString.length) {
      int position = queryString.indexOf("=", currentPosition);
      if (position == -1) {
        break;
      }
      String name = queryString.substring(currentPosition, position);
      currentPosition = position + 1;
      position = queryString.indexOf("&", currentPosition);
      String value;
      if (position == -1) {
        value = queryString.substring(currentPosition);
        currentPosition = queryString.length;
      } else {
        value = queryString.substring(currentPosition, position);
        currentPosition = position + 1;
      }
      result[_HttpUtils.decodeUrlEncodedString(name)] =
        _HttpUtils.decodeUrlEncodedString(value);
    }
    return result;
  }

  // From RFC 2616 section "3.3.1 Full Date"
  // HTTP-date    = rfc1123-date | rfc850-date | asctime-date
  // rfc1123-date = wkday "," SP date1 SP time SP "GMT"
  // rfc850-date  = weekday "," SP date2 SP time SP "GMT"
  // asctime-date = wkday SP date3 SP time SP 4DIGIT
  // date1        = 2DIGIT SP month SP 4DIGIT
  //                ; day month year (e.g., 02 Jun 1982)
  // date2        = 2DIGIT "-" month "-" 2DIGIT
  //                ; day-month-year (e.g., 02-Jun-82)
  // date3        = month SP ( 2DIGIT | ( SP 1DIGIT ))
  //                ; month day (e.g., Jun  2)
  // time         = 2DIGIT ":" 2DIGIT ":" 2DIGIT
  //                ; 00:00:00 - 23:59:59
  // wkday        = "Mon" | "Tue" | "Wed"
  //              | "Thu" | "Fri" | "Sat" | "Sun"
  // weekday      = "Monday" | "Tuesday" | "Wednesday"
  //              | "Thursday" | "Friday" | "Saturday" | "Sunday"
  // month        = "Jan" | "Feb" | "Mar" | "Apr"
  //              | "May" | "Jun" | "Jul" | "Aug"
  //              | "Sep" | "Oct" | "Nov" | "Dec"

  // Format as RFC 1123 date.
  static String formatDate(Date date) {
    List wkday = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
    List month = ["Jan", "Feb", "Mar", "Apr", "May", "Jun",
                  "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];

    Date d = date.changeTimeZone(new TimeZone.utc());
    StringBuffer sb = new StringBuffer();
    sb.add(wkday[d.weekday]);
    sb.add(", ");
    sb.add(d.day.toString());
    sb.add(" ");
    sb.add(month[d.month - 1]);
    sb.add(" ");
    sb.add(d.year.toString());
    d.hours < 9 ? sb.add(" 0") : sb.add(" ");
    sb.add(d.hours.toString());
    d.minutes < 9 ? sb.add(":0") : sb.add(":");
    sb.add(d.minutes.toString());
    d.seconds < 9 ? sb.add(":0") : sb.add(":");
    sb.add(d.seconds.toString());
    sb.add(" GMT");
    return sb.toString();
  }

  static Date parseDate(String date) {
    final int SP = 32;
    List wkdays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
    List weekdays = ["Monday", "Tuesday", "Wednesday", "Thursday",
                     "Friday", "Saturday", "Sunday"];
    List months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun",
                   "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];

    final int formatRfc1123 = 0;
    final int formatRfc850 = 1;
    final int formatAsctime = 2;

    int index = 0;
    String tmp;
    int format;

    void expect(String s) {
      if (date.length - index < s.length) {
        throw new HttpException("Invalid HTTP date $date");
      }
      String tmp = date.substring(index, index + s.length);
      if (tmp != s) {
        throw new HttpException("Invalid HTTP date $date");
      }
      index += s.length;
    }

    int expectWeekday() {
      int weekday;
      // The formatting of the weekday signals the format of the date string.
      int pos = date.indexOf(",", index);
      if (pos == -1) {
        int pos = date.indexOf(" ", index);
        if (pos == -1) throw new HttpException("Invalid HTTP date $date");
        tmp = date.substring(index, pos);
        index = pos + 1;
        weekday = wkdays.indexOf(tmp);
        if (weekday != -1) {
          format = formatAsctime;
          return weekday;
        }
      } else {
        tmp = date.substring(index, pos);
        index = pos + 1;
        weekday = wkdays.indexOf(tmp);
        if (weekday != -1) {
          format = formatRfc1123;
          return weekday;
        }
        weekday = weekdays.indexOf(tmp);
        if (weekday != -1) {
          format = formatRfc850;
          return weekday;
        }
      }
      throw new HttpException("Invalid HTTP date $date");
    }

    int expectMonth(String separator) {
      int pos = date.indexOf(separator, index);
      if (pos - index != 3) throw new HttpException("Invalid HTTP date $date");
      tmp = date.substring(index, pos);
      index = pos + 1;
      int month = months.indexOf(tmp);
      if (month != -1) return month;
      throw new HttpException("Invalid HTTP date $date");
    }

    int expectNum(String separator) {
      int pos;
      if (separator.length > 0) {
        pos = date.indexOf(separator, index);
      } else {
        pos = date.length;
      }
      String tmp = date.substring(index, pos);
      index = pos + separator.length;
      try {
        int value = Math.parseInt(tmp);
        return value;
      } catch (BadNumberFormatException e) {
        throw new HttpException("Invalid HTTP date $date");
      }
    }

    void expectEnd() {
      if (index != date.length) {
        throw new HttpException("Invalid HTTP date $date");
      }
    }

    int weekday = expectWeekday();
    int day;
    int month;
    int year;
    int hours;
    int minutes;
    int seconds;
    if (format == formatAsctime) {
      month = expectMonth(" ");
      if (date.charCodeAt(index) == SP) index++;
      day = expectNum(" ");
      hours = expectNum(":");
      minutes = expectNum(":");
      seconds = expectNum(" ");
      year = expectNum("");
    } else {
      expect(" ");
      day = expectNum(format == formatRfc1123 ? " " : "-");
      month = expectMonth(format == formatRfc1123 ? " " : "-");
      year = expectNum(" ");
      hours = expectNum(":");
      minutes = expectNum(":");
      seconds = expectNum(" ");
      expect("GMT");
    }
    expectEnd();
    TimeZone utc = new TimeZone.utc();
    return new Date.withTimeZone(
        year, month + 1, day, hours, minutes, seconds, 0, utc);
  }
}
