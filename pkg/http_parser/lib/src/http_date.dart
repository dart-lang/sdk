// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library http_parser.http_date;

import 'package:string_scanner/string_scanner.dart';

const _WEEKDAYS = const ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
const _MONTHS = const ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug",
    "Sep", "Oct", "Nov", "Dec"];

final _shortWeekdayRegExp = new RegExp(r"Mon|Tue|Wed|Thu|Fri|Sat|Sun");
final _longWeekdayRegExp =
    new RegExp(r"Monday|Tuesday|Wednesday|Thursday|Friday|Saturday|Sunday");
final _monthRegExp =
    new RegExp(r"Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec");
final _digitRegExp = new RegExp(r"\d+");

/// Return a HTTP-formatted string representation of [date].
///
/// This follows [RFC 822](http://tools.ietf.org/html/rfc822) as updated by [RFC
/// 1123](http://tools.ietf.org/html/rfc1123).
String formatHttpDate(DateTime date) {
  date = date.toUtc();
  var buffer = new StringBuffer()
      ..write(_WEEKDAYS[date.weekday - 1])
      ..write(", ")
      ..write(date.day <= 9 ? "0" : "")
      ..write(date.day.toString())
      ..write(" ")
      ..write(_MONTHS[date.month - 1])
      ..write(" ")
      ..write(date.year.toString())
      ..write(date.hour <= 9 ? " 0" : " ")
      ..write(date.hour.toString())
      ..write(date.minute <= 9 ? ":0" : ":")
      ..write(date.minute.toString())
      ..write(date.second <= 9 ? ":0" : ":")
      ..write(date.second.toString())
      ..write(" GMT");
  return buffer.toString();
}

/// Parses an HTTP-formatted date into a UTC [DateTime].
///
/// This follows [RFC
/// 2616](http://www.w3.org/Protocols/rfc2616/rfc2616-sec3.html#sec3.3). It will
/// throw a [FormatException] if [date] is invalid.
DateTime parseHttpDate(String date) {
  try {
    var scanner = new StringScanner(date);

    if (scanner.scan(_longWeekdayRegExp)) {
      // RFC 850 starts with a long weekday.
      scanner.expect(", ");
      var day = _parseInt(scanner, 2);
      scanner.expect("-");
      var month = _parseMonth(scanner);
      scanner.expect("-");
      var year = 1900 + _parseInt(scanner, 2);
      scanner.expect(" ");
      var time = _parseTime(scanner);
      scanner.expect(" GMT");
      scanner.expectDone();

      return _makeDateTime(year, month, day, time);
    }

    // RFC 1123 and asctime both start with a short weekday.
    scanner.expect(_shortWeekdayRegExp);
    if (scanner.scan(", ")) {
      // RFC 1123 follows the weekday with a comma.
      var day = _parseInt(scanner, 2);
      scanner.expect(" ");
      var month = _parseMonth(scanner);
      scanner.expect(" ");
      var year = _parseInt(scanner, 4);
      scanner.expect(" ");
      var time = _parseTime(scanner);
      scanner.expect(" GMT");
      scanner.expectDone();

      return _makeDateTime(year, month, day, time);
    }

    // asctime follows the weekday with a space.
    scanner.expect(" ");
    var month = _parseMonth(scanner);
    scanner.expect(" ");
    var day = scanner.scan(" ") ?
        _parseInt(scanner, 1) :
        _parseInt(scanner, 2);
    scanner.expect(" ");
    var time = _parseTime(scanner);
    scanner.expect(" ");
    var year = _parseInt(scanner, 4);
    scanner.expectDone();

    return _makeDateTime(year, month, day, time);
  } on FormatException catch (error) {
    throw new FormatException('Invalid HTTP date "$date": ${error.message}');
  }
}

/// Parses a short-form month name to a form accepted by [DateTime].
int _parseMonth(StringScanner scanner) {
  scanner.expect(_monthRegExp);
  // DateTime uses 1-indexed months.
  return _MONTHS.indexOf(scanner.lastMatch[0]) + 1;
}

/// Parses an int an enforces that it has exactly [digits] digits.
int _parseInt(StringScanner scanner, int digits) {
  scanner.expect(_digitRegExp);
  if (scanner.lastMatch[0].length != digits) {
    scanner.error("expected a $digits-digit number.");
  }

  return int.parse(scanner.lastMatch[0]);
}

/// Parses an timestamp of the form "HH:MM:SS" on a 24-hour clock.
DateTime _parseTime(StringScanner scanner) {
  var hours = _parseInt(scanner, 2);
  if (hours >= 24) scanner.error("hours may not be greater than 24.");
  scanner.expect(':');

  var minutes = _parseInt(scanner, 2);
  if (minutes >= 60) scanner.error("minutes may not be greater than 60.");
  scanner.expect(':');

  var seconds = _parseInt(scanner, 2);
  if (seconds >= 60) scanner.error("seconds may not be greater than 60.");

  return new DateTime(1, 1, 1, hours, minutes, seconds);
}

/// Returns a UTC [DateTime] from the given components.
///
/// Validates that [day] is a valid day for [month]. If it's not, throws a
/// [FormatException].
DateTime _makeDateTime(int year, int month, int day, DateTime time) {
  var dateTime = new DateTime.utc(
      year, month, day, time.hour, time.minute, time.second);

  // If [day] was too large, it will cause [month] to overflow.
  if (dateTime.month != month) {
    throw new FormatException("invalid day '$day' for month '$month'.");
  }
  return dateTime;
}
