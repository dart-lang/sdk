// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class _HttpUtils {
  static String decodeUrlEncodedString(String urlEncoded) {
    // First check the string for any encoding.
    int index = 0;
    bool encoded = false;
    while (!encoded && index < urlEncoded.length) {
      encoded = urlEncoded[index] == "+" || urlEncoded[index] == "%";
      index++;
    }
    if (!encoded) return urlEncoded;
    index--;

    // Start decoding from the first encoded character.
    List<int> bytes = new List<int>();
    for (int i = 0; i < index; i++) bytes.add(urlEncoded.charCodeAt(i));
    for (int i = index; i < urlEncoded.length; i++) {
      if (urlEncoded[i] == "+") {
        bytes.add(32);
      } else if (urlEncoded[i] == "%") {
        if (urlEncoded.length - i < 2) {
          throw new HttpException("Invalid URL encoding");
        }
        int byte = 0;
        for (int j = 0; j < 2; j++) {
          var charCode = urlEncoded.charCodeAt(i + j + 1);
          if (0x30 <= charCode && charCode <= 0x39) {
            byte = byte * 16 + charCode - 0x30;
          } else if (0x41 <= charCode && charCode <= 0x46) {
            byte = byte * 16 + charCode - 0x37;
          } else if (0x61 <= charCode && charCode <= 0x66) {
            byte = byte * 16 + charCode - 0x57;
          } else {
            throw new HttpException("Invalid URL encoding");
          }
        }
        bytes.add(byte);
        i += 2;
      } else {
        bytes.add(urlEncoded.charCodeAt(i));
      }
    }
    return decodeUtf8(bytes);
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

    Date d = date.toUtc();
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

  static Date parseDate(String date, [bool strict = true]) {
    final int SP = 32;
    List wkdays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
    List weekdays = ["Monday", "Tuesday", "Wednesday", "Thursday",
                     "Friday", "Saturday", "Sunday"];
    List months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun",
                   "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    List wkdaysLowerCase = ["mon", "tue", "wed", "thu", "fri", "sat", "sun"];
    List weekdaysLowerCase = ["monday", "tuesday", "wednesday", "thursday",
                              "friday", "saturday", "sunday"];
    List monthsLowerCase = ["jan", "feb", "mar", "apr", "may", "jun",
                            "jul", "aug", "sep", "oct", "nov", "dec"];

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
      if (strict) {
        if (tmp != s) {
          throw new HttpException("Invalid HTTP date $date");
        }
      } else {
        if (tmp.toLowerCase() != s.toLowerCase()) {
          throw new HttpException("Invalid HTTP date $date");
        }
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
        weekday = strict ? wkdays.indexOf(tmp)
                         : wkdaysLowerCase.indexOf(tmp.toLowerCase());
        if (weekday != -1) {
          format = formatAsctime;
          return weekday;
        }
      } else {
        tmp = date.substring(index, pos);
        index = pos + 1;
        weekday = strict ? wkdays.indexOf(tmp)
                         : wkdaysLowerCase.indexOf(tmp.toLowerCase());
        if (weekday != -1) {
          format = formatRfc1123;
          return weekday;
        }
        weekday = strict ? weekdays.indexOf(tmp)
                         : weekdaysLowerCase.indexOf(tmp.toLowerCase());
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
      int month = strict ? months.indexOf(tmp)
                         : monthsLowerCase.indexOf(tmp.toLowerCase());
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
    return new Date(
        year, month + 1, day, hours, minutes, seconds, 0, isUtc: true);
  }
}
