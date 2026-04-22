// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of "dart:_http";

/// Utility functions for working with dates with HTTP specific date
/// formats.
class HttpDate {
  // From RFC-2616 section "3.3.1 Full Date",
  // http://tools.ietf.org/html/rfc2616#section-3.3.1
  //
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

  /// Format a date according to
  /// [RFC-1123](http://tools.ietf.org/html/rfc1123 "RFC-1123"),
  /// e.g. `Thu, 1 Jan 1970 00:00:00 GMT`.
  static String format(DateTime date) {
    StringBuffer sb = StringBuffer();
    _formatTo(date, sb);
    return sb.toString();
  }

  static const List<String> _weekdayAbbreviations = <String>[
    "Mon",
    "Tue",
    "Wed",
    "Thu",
    "Fri",
    "Sat",
    "Sun",
  ];

  static const List<String> _weekdays = <String>[
    "Monday",
    "Tuesday",
    "Wednesday",
    "Thursday",
    "Friday",
    "Saturday",
    "Sunday",
  ];

  static const List<String> _monthAbbreviations = <String>[
    "Jan",
    "Feb",
    "Mar",
    "Apr",
    "May",
    "Jun",
    "Jul",
    "Aug",
    "Sep",
    "Oct",
    "Nov",
    "Dec",
  ];

  static String _formatTo(DateTime date, StringSink sb) {
    DateTime d = date.toUtc();
    sb
      ..write(_weekdayAbbreviations[d.weekday - 1])
      ..write(", ")
      ..write(d.day <= 9 ? "0" : "")
      ..write(d.day.toString())
      ..write(" ")
      ..write(_monthAbbreviations[d.month - 1])
      ..write(" ")
      ..write(d.year.toString())
      ..write(d.hour <= 9 ? " 0" : " ")
      ..write(d.hour.toString())
      ..write(d.minute <= 9 ? ":0" : ":")
      ..write(d.minute.toString())
      ..write(d.second <= 9 ? ":0" : ":")
      ..write(d.second.toString())
      ..write(" GMT");
    return sb.toString();
  }

  /// Parse a date string in either of the formats
  /// [RFC-1123](http://tools.ietf.org/html/rfc1123 "RFC-1123"),
  /// [RFC-850](http://tools.ietf.org/html/rfc850 "RFC-850") or
  /// ANSI C's asctime() format. These formats are listed here.
  ///
  /// * Thu, 1 Jan 1970 00:00:00 GMT
  /// * Thursday, 1-Jan-1970 00:00:00 GMT
  /// * Thu Jan  1 00:00:00 1970
  ///
  /// For more information see [RFC-2616 section
  /// 3.1.1](http://tools.ietf.org/html/rfc2616#section-3.3.1
  /// "RFC-2616 section 3.1.1").
  static DateTime parse(String date) =>
      _parse(date, 0, date.length, _invalidHttpDate);

  static Never _invalidHttpDate(String source, int start, int end) =>
      throw HttpException("Invalid HTTP date ${source.substring(start, end)}");

  /// Try parsing like [parse], but return `null` if parsing fails.
  static DateTime? _tryParse(String date) {
    try {
      return _parse(date, 0, date.length, _failedTryParse);
    } on HttpException {
      return null;
    }
  }

  // Cheaper throw for [_tryParse]
  static Never _failedTryParse(String source, int start, int end) =>
      throw const HttpException("");

  /// Implements [parse] on a substring.
  ///
  /// If [isCookieDate] is `true`, also accepts `Thu, 1-Jan-1970 00:00:00 GMT`,
  /// with `-`s between day-month-year.
  /// This format was accepted by the special Cookie-date parser,
  /// which now uses this function too.
  static DateTime _parse(
    String source,
    int start,
    int end,
    Never Function(String, int, int) onError,
  ) {
    // Almost same format after the week-day, only differ by one character.
    const int formatRfc1123 = _CharCode.SP;
    const int formatRfc850 = _CharCode.MINUS;
    // Separate format.
    const int formatAsctime = 0;

    int index = start;

    Never throwError() {
      onError(source, start, end);
    }

    void expectChar(int charCode) {
      if (index < end && source.codeUnitAt(index) == charCode) {
        index++;
      } else {
        throwError();
      }
    }

    // Detects one of three recognized formats.
    //
    // All three formats start with the week-day in different ways:
    // * `Mon `: [formatAsctime]
    // * `Mon,`: [formatRfc1123]
    // * `Monday,`: [formatRfc850]
    int expectWeekday() {
      for (var i = 0; i < _weekdayAbbreviations.length; i++) {
        var wkday = _weekdayAbbreviations[i]; // Three-letter day abbreviation.
        assert(wkday.length == 3);
        if (index + 3 <= end && _isTextNoCase(source, index, 3, wkday)) {
          var weekday = _weekdays[i]; // Unabbreviated day.
          // Check if following characters are the rest of the day name.
          if (index + weekday.length <= end &&
              _isTextNoCase(
                source,
                index + 3,
                weekday.length - 3,
                weekday,
                3,
              )) {
            index += weekday.length;
            expectChar(_CharCode.COMMA);
            return formatRfc850;
          }
          index += 3;
          if (index < end) {
            var nextChar = source.codeUnitAt(index);
            if (nextChar == _CharCode.COMMA) {
              index++;
              return formatRfc1123;
            }
            if (nextChar == _CharCode.SP) {
              index++;
              return formatAsctime;
            }
          }
          break;
        }
      }
      throwError();
    }

    int expectMonth() {
      for (var i = 0; i < _monthAbbreviations.length; i++) {
        String monthAbbreviation = _monthAbbreviations[i];
        assert(monthAbbreviation.length == 3);
        if (index + 3 <= end &&
            _isTextNoCase(source, index, 3, monthAbbreviation)) {
          index += 3;
          return i;
        }
      }
      throwError();
    }

    int expectNum(int maxLength) {
      int value = 0;
      int start = index;
      while (index < end) {
        int digit = source.codeUnitAt(index) ^ 0x30;
        if (digit <= 9) {
          value = value * 10 + digit;
          index++;
          continue;
        }
        break;
      }
      int length = index - start;
      if (length > 0 && length <= maxLength) {
        return value;
      }
      throwError();
    }

    int format = expectWeekday();
    int year;
    int month;
    int day;
    int hours;
    int minutes;
    int seconds;
    if (format == formatAsctime) {
      month = expectMonth();
      expectChar(_CharCode.SP);
      if (source.codeUnitAt(index) == _CharCode.SP) index++;
      day = expectNum(2);
      expectChar(_CharCode.SP);
      hours = expectNum(2);
      expectChar(_CharCode.COLON);
      minutes = expectNum(2);
      expectChar(_CharCode.COLON);
      seconds = expectNum(2);
      expectChar(_CharCode.SP);
      year = expectNum(4);
    } else {
      var dateSeparator = format;
      expectChar(_CharCode.SP);
      day = expectNum(2);
      expectChar(dateSeparator);
      month = expectMonth();
      expectChar(dateSeparator);
      year = expectNum(4);
      expectChar(_CharCode.SP);
      hours = expectNum(2);
      expectChar(_CharCode.COLON);
      minutes = expectNum(2);
      expectChar(_CharCode.COLON);
      seconds = expectNum(2);
      if (index + 4 <= end && _isTextNoCase(source, index, 4, ' GMT')) {
        index += 4;
      } else {
        throwError();
      }
    }
    if (index != end) throwError();
    return DateTime.utc(year, month + 1, day, hours, minutes, seconds);
  }

  /// Parse a cookie date (sub-)string.
  ///
  /// Allows all HTTP legacy formats, not just the recommended RFC-1123 format.
  ///
  /// See https://www.rfc-editor.org/rfc/rfc6265#section-5.1.1
  static DateTime _parseCookieDate(String source, int start, int end) {
    // The algorithm separates bytes into delimiters and non-delimiters.
    // The source here is a Dart string, which may contain characters
    // above 0xFF. Those are treated as opaque non-delimiters.
    // If the header was UTF-8 encoded, those code units may have been
    // represented by bytes in the 0x80-0xFF range,
    // which are all non-delimiters.

    // Whether each character in the 0x00..0x7f is a delimiter or not.
    // If it's not a delimiter, we may add more information if it can
    // start a valid date-token.
    // We add extra information to month-start-letter entries,
    // 0xH4 means month starting letter, with H being an index
    // into the `monthMatches` table below.
    const charKindTable =
        // 0x00 .. 0x08: Generic non-delimiters
        "\x01\x01\x01\x01\x01\x01\x01\x01"
        "\x01"
        // 0x09 (TAB): Delimiter.
        "\x00"
        // 0x0A-0x1F: Generic non-delimiters
        "\x01\x01\x01\x01\x01\x01"
        "\x01\x01\x01\x01\x01\x01\x01\x01"
        "\x01\x01\x01\x01\x01\x01\x01\x01"
        // 0x20-0x2F: delimiters
        "\x00\x00\x00\x00\x00\x00\x00\x00"
        "\x00\x00\x00\x00\x00\x00\x00\x00"
        // 0x30-0x39: Digits
        "\x02\x02\x02\x02\x02\x02\x02\x02"
        "\x02\x02"
        // 0x3A (:), non-delimiter, required time field separator.
        "\x01"
        // 0x3B-0x40, delimiters
        "\x00\x00\x00\x00\x00"
        "\x00"
        // 0x41-0x5A, upper-case letters. Non-delimiters and some month starters.
        // (APR, AUG), DEC, FEB, (JAN, JUL, JUN), (MAR, MAY), NOV, OCT, SEP
        // (0x04 + index for first occurrence of start letter in above list)
        "\x04\x01\x01\x24\x01\x34\x01"
        "\x01\x01\x44\x01\x01\x74\x94\xA4"
        "\x01\x01\x01\xB4\x01\x01\x01\x01"
        "\x01\x01\x01"
        // 0x5b-0x60, delimiters
        "\x00\x00\x00\x00\x00"
        "\x00"
        // 0x61-0x7A, lower-case letters, same as upper case.
        "\x04\x01\x01\x24\x01\x34\x01"
        "\x01\x01\x44\x01\x01\x74\x94\xA4"
        "\x01\x01\x01\xB4\x01\x01\x01\x01"
        "\x01\x01\x01"
        // 0x7B-0x7E delimiters
        "\x00\x00\x00\x00"
        // 0x7F-0xFF (and beyond), non-delimiters
        "\x01"; // TODO: make into literal when it works.

    const delimiterValue = 0x00;
    const nonDelimiterValue = 0x01; // General non-delimiter value.
    // Non-delimiter digit.
    const digitFlag = 0x02;
    // Non delimiter lower-case letter that starts a month name.
    const monthStartFlag = 0x04;

    // Month name to month number table.
    // Each entry contains the two last letters of the three-letter month
    // grouped by first letter.
    const monthMatches = [
      // 'a' at index 0 (Char kind table above contains `0x04` for `a` and `A`)
      _MonthTableEntry(
        DateTime.april,
        _CharCode.a,
        _CharCode.p,
        _CharCode.r,
        hasMore: true,
      ),
      _MonthTableEntry(DateTime.august, _CharCode.a, _CharCode.u, _CharCode.g),
      // 'd' at index 2
      _MonthTableEntry(
        DateTime.december,
        _CharCode.d,
        _CharCode.e,
        _CharCode.c,
      ),
      // 'f' at index 3
      _MonthTableEntry(
        DateTime.february,
        _CharCode.f,
        _CharCode.e,
        _CharCode.b,
      ),
      // 'j' at index 4
      _MonthTableEntry(
        DateTime.january,
        _CharCode.j,
        _CharCode.a,
        _CharCode.n,
        hasMore: true,
      ),
      _MonthTableEntry(
        DateTime.july,
        _CharCode.j,
        _CharCode.u,
        _CharCode.l,
        hasMore: true,
      ),
      _MonthTableEntry(DateTime.june, _CharCode.j, _CharCode.u, _CharCode.n),
      // 'm' at index 7
      _MonthTableEntry(
        DateTime.march,
        _CharCode.m,
        _CharCode.a,
        _CharCode.r,
        hasMore: true,
      ),
      _MonthTableEntry(DateTime.may, _CharCode.m, _CharCode.a, _CharCode.y),
      // 'n' at index 9
      _MonthTableEntry(
        DateTime.november,
        _CharCode.n,
        _CharCode.o,
        _CharCode.v,
      ),
      // 'n' at index 10
      _MonthTableEntry(DateTime.october, _CharCode.o, _CharCode.c, _CharCode.t),
      // 's' at index 11
      _MonthTableEntry(
        DateTime.september,
        _CharCode.s,
        _CharCode.e,
        _CharCode.p,
      ),
    ];

    var index = start;

    // Scans a number (sequence of ASCII digits).
    // Returns the value, or negative if no digits or more than `maxDigits`.
    // Count digits from `digitsStart` and start with `value`, which
    // allows not scanning a first known digit again.
    // No recognized token accepts more than 4 digits.
    int tryScanNumber(int maxDigits, int digitsStart, int value) {
      var cursor = index;
      int digit;
      while (cursor < end &&
          (digit = source.codeUnitAt(cursor) ^ _CharCode.ZERO) <= 9) {
        value = value * 10 + digit;
        cursor++;
      }
      var length = cursor - digitsStart;
      if (length > 0 && length <= maxDigits) {
        index = cursor;
        return value;
      }
      return -1; // Zero or more than `maxDigits` digits
    }

    bool tryChar(int expectedChar) {
      if (index < end && source.codeUnitAt(index) == expectedChar) {
        index++;
        return true;
      }
      return false;
    }

    // Parts of date that must be found.
    int year = -1; // Found if non-negative.
    int month = 0; // Found if positive (valid values are 1..12).
    int dayOfMonth = -1; // Found if non-negative (potentially valid if 1..31).
    int hours = -1; // Time found if non-negative.
    int minutes = 0; // Minutes and seconds only matter if hours are found.
    int seconds = 0;

    while (index < end) {
      var char = source.codeUnitAt(index);
      //  1.  Using the grammar below, divide the cookie-date into date-tokens.
      //
      // (Split at delimiters, sequences of non-delimiters are date-tokens.)
      var kind = char <= 0x7F ? charKindTable.codeUnitAt(char) : 0x01;

      if (kind == delimiterValue) {
        index++;
      } else {
        // Found first non-delimiter character of a date-token.
        // Parse and process token.
        if (kind & digitFlag != delimiterValue) {
          // Starts with digit.
          // 2. Process each date-token sequentially in the order
          //    the date-tokens appear in the cookie-date:

          var beforeDigitsIndex = index;
          var value = tryScanNumber(4, index++, char ^ _CharCode.ZERO);
          if (value >= 0) {
            var length = index - beforeDigitsIndex;
            assert(length > 0 && length <= 4);
            if (hours < 0 &&
                length <= 2 &&
                tryChar(_CharCode.COLON) &&
                (minutes = tryScanNumber(2, index, 0)) >= 0 &&
                tryChar(_CharCode.COLON) &&
                (seconds = tryScanNumber(2, index, 0)) >= 0) {
              // 2.
              //  1. If the found-time flag is not set and the token matches the
              //   time production, set the found-time flag and set the hour-
              //   value, minute-value, and second-value to the numbers denoted
              //   by the digits in the date-token, respectively.  Skip the
              //   remaining sub-steps and continue to the next date-token.
              //
              // The time production is (including errata):
              //     1*2DIGIT ":" 1*2DIGIT ":" 1*2DIGIT [ non-digit *OCTET ]
              hours = value;
              // Fall through to skipping until next delimiters.
            } else if (dayOfMonth < 0 && length <= 2) {
              // 2.
              //  2. If the found-day-of-month flag is not set and the date-token
              //   matches the day-of-month production, set the found-day-of-
              //   month flag and set the day-of-month-value to the number
              //   denoted by the date-token.  Skip the remaining sub-steps and
              //   continue to the next date-token.
              //
              // The `day-of-month` production (including errata):
              //    1*2DIGIT [ non-digit *OCTET ]
              // (Where OCTET is non-delimiters only, since date-tokens are
              // split on delimiters first.)
              dayOfMonth = value;
              // Fall through to skipping until next delimiter.
            } else if (year < 0 && length >= 2) {
              // 2.
              //  4. If the found-year flag is not set and the date-token matches
              //   the year production, set the found-year flag and set the
              //   year-value to the number denoted by the date-token.  Skip the
              //   remaining sub-steps and continue to the next date-token.
              //
              // The year production (including errata):
              //     2*4DIGIT [ non-digit *OCTET ]
              //
              // Then:
              // 3.  If the year-value is greater than or equal to 70 and
              //   less than or equal to 99, increment the year-value by 1900.
              //
              // 4.  If the year-value is greater than or equal to 0 and
              //   less than or equal to 69, increment the year-value by 2000.
              //   1.  NOTE: Some existing user agents interpret two-digit years
              //       differently.
              if (value <= 99) {
                if (value <= 69) value += 100;
                value += 1900;
              }
              year = value;
            }
          }
        } else if (month <= 0 && kind & monthStartFlag != 0) {
          // Found letter that starts a month.

          // 2.
          //  3. If the found-month flag is not set and the date-token matches
          //   the month production, set the found-month flag and set the
          //   month-value to the month denoted by the date-token.  Skip the
          //   remaining sub-steps and continue to the next date-token.
          //
          // The month production is: ("jan"/.../"dec") *OCTET
          //
          // EBNF RFC states that quoted strings match case-insensitively,
          // so anything that starts with case-insensitive three-letter months.

          if (++index + 2 <= end) {
            // Read next two characters, make them lower-case if letters.
            var peek1 = source.codeUnitAt(index) | 0x20;
            var peek2 = source.codeUnitAt(index + 1) | 0x20;
            // Only continue if both are ASCII.
            if ((peek1 | peek2) <= 0x7F) {
              var twoChars = peek1 << 8 | peek2;
              // Months starting with that letter.
              var monthTableIndex = kind >> 4;
              _MonthTableEntry
              monthTableEntry; // Declare outside to allow use in condition.
              do {
                monthTableEntry = monthMatches[monthTableIndex];
                if (monthTableEntry.chars == twoChars) {
                  month = monthTableEntry.month;
                  index += 2;
                  break;
                }
                monthTableIndex++;
              } while (monthTableEntry.hasMore);
            }
          }
        } else {
          // Non-digit non-month-starting non-delimiter.
          // Doesn't start any date-token, so just skip to next
          // delimiter.
          index++;
        }
        // Skip any following non-delimiters (trailing `*OCTAL`), and the first
        // following delimiter.
        while (index < end) {
          char = source.codeUnitAt(index);
          index++;
          if (char <= 0x7F &&
              charKindTable.codeUnitAt(char) == delimiterValue) {
            break;
          }
        }
      }
    }

    // 5. Abort these steps and fail to parse the cookie-date if:
    //    * at least one of the found-day-of-month, found-month, found-
    //      year, or found-time flags is not set,
    //    * the day-of-month-value is less than 1 or greater than 31,
    //    * the year-value is less than 1601,
    //    * the hour-value is greater than 23,
    //    * the minute-value is greater than 59, or
    //    * the second-value is greater than 59.
    if (hours >= 0 &&
        hours <= 23 &&
        minutes <= 59 &&
        seconds <= 59 &&
        dayOfMonth >= 0 &&
        dayOfMonth <= 31 &&
        month > 0 &&
        year >= 1601) {
      var date = DateTime.utc(year, month, dayOfMonth, hours, minutes, seconds);
      // 6. Let the parsed-cookie-date be the date whose day-of-month, month,
      //    year, hour, minute, and second (in UTC) are the day-of-month-
      //    value, the month-value, the year-value, the hour-value, the
      //    minute-value, and the second-value, respectively.  If no such
      //    date exists, abort these steps and fail to parse the cookie-date.
      if (date.day == dayOfMonth) {
        // In UTC time, the ony input that can be invalid is `dayOfMonth`
        // with a value above 28. If it is, the `DateTime` class corrects
        // by overflowing into the next month. If the `DateTime.day` matches,
        // no overflow happened.

        // 7. Return the parsed-cookie-date as the result of this algorithm.
        return date;
      }
      _invalidCookieDate(source, start, end, "invalid day of month");
    }
    _invalidCookieDate(
      source,
      start,
      end,
      [
        if (hours < 0)
          "no time part"
        else ...[
          if (hours > 23) "invalid hours part ($hours)",
          if (minutes > 59) "invalid minutes part ($minutes)",
          if (seconds > 59) "invalid seconds part ($seconds)",
        ],
        if (month <= 0) "no month part",
        if (year < 0)
          "no year part"
        else if (year < 1601)
          "invalid year ($year)",
        if (dayOfMonth < 0)
          "no day of month part"
        else if (dayOfMonth < 1 || dayOfMonth > 31)
          "invalid day of month",
      ].join(', '),
    );
  }

  static Never _invalidCookieDate(
    String source,
    int start,
    int end, [
    String message = "",
  ]) => throw HttpException(
    "Invalid cookie date ${source.substring(start, end)}"
    "${message.isEmpty ? "" : ": $message"}",
  );
}

// Helper to make the integers of the month parsing table more readable.
extension type _MonthTableEntry._(int _) implements int {
  // TODO: Could be stored in 16 bits string if we pre-check that the characters
  // are letters (5 bits per letter, 4 bits month, 1 bit "has more").
  // Check if worth it.

  // TODO: Could store "has more" in bit 7, making `& 0x80` an 8-bit literal,
  // but then requires `& 0x7F7F` for the letters.

  // Information stored in bits:
  //   0..6: last ASCII char
  //   7: 0
  //   8..14: second ASCII char
  //   15: more with same first start letter?
  //   16-19: month number
  const _MonthTableEntry(
    int month,
    int firstLetter,
    int secondLetter,
    int thirdLetter, {
    bool hasMore = false,
  }) : _ =
           (month << 16) |
           (secondLetter << 8) |
           thirdLetter |
           (hasMore ? 0x8000 : 0);

  // TODO: Check that compilers inline these operations.

  /// Whether table has more (following) entries for the same first letter.
  bool get hasMore => _ & 0x8000 != 0;

  /// The two ASCII characters ending this three-letter month name.
  int get chars => _ & 0x7FFF;

  /// The month for this entry.
  int get month => _ >> 16;
}
