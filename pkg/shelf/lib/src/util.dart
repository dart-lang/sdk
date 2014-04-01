// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library shelf.util;

import 'dart:async';

import 'package:stack_trace/stack_trace.dart';

import 'string_scanner.dart';

/// Like [Future.sync], but wraps the Future in [Chain.track] as well.
Future syncFuture(callback()) => Chain.track(new Future.sync(callback));

const _WEEKDAYS = const ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
const _MONTHS = const ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug",
    "Sep", "Oct", "Nov", "Dec"];

final _shortWeekdayRegExp = new RegExp(r"Mon|Tue|Wed|Thu|Fri|Sat|Sun");
final _longWeekdayRegExp =
    new RegExp(r"Monday|Tuesday|Wednesday|Thursday|Friday|Saturday|Sunday");
final _monthRegExp =
    new RegExp(r"Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec");
final _digitRegExp = new RegExp(r"\d+");

// TODO(nweiz): Move this into an http_parser package.
/// Return a HTTP-formatted string representation of [date].
///
/// This follows [RFC 822](http://tools.ietf.org/html/rfc822) as updated by [RFC
/// 1123](http://tools.ietf.org/html/rfc1123).
String formatHttpDate(DateTime date) {
  date = date.toUtc();
  var buffer = new StringBuffer()
      ..write(_WEEKDAYS[date.weekday - 1])
      ..write(", ")
      ..write(date.day.toString())
      ..write(" ")
      ..write(_MONTHS[date.month - 1])
      ..write(" ")
      ..write(date.year.toString())
      ..write(date.hour < 9 ? " 0" : " ")
      ..write(date.hour.toString())
      ..write(date.minute < 9 ? ":0" : ":")
      ..write(date.minute.toString())
      ..write(date.second < 9 ? ":0" : ":")
      ..write(date.second.toString())
      ..write(" GMT");
  return buffer.toString();
}

// TODO(nweiz): Move this into an http_parser package.
/// Parses an HTTP-formatted date into a UTC [DateTime].
///
/// This follows [RFC
/// 2616](http://www.w3.org/Protocols/rfc2616/rfc2616-sec3.html#sec3.3). It will
/// throw a [FormatException] if [date] is invalid.
DateTime parseHttpDate(String date) {
  var errorMessage = 'Invalid HTTP date "$date".';
  var scanner = new StringScanner(date);

  if (scanner.scan(_longWeekdayRegExp)) {
    // RFC 850 starts with a long weekday.
    scanner.expect(", ", errorMessage);
    var day = _parseInt(scanner, errorMessage, 2);
    scanner.expect("-", errorMessage);
    var month = _parseMonth(scanner, errorMessage);
    scanner.expect("-", errorMessage);
    var year = 1900 + _parseInt(scanner, errorMessage, 2);
    scanner.expect(" ", errorMessage);
    var time = _parseTime(scanner, errorMessage);
    scanner.expect(" GMT", errorMessage);
    if (!scanner.isDone) throw new FormatException(errorMessage);

    return _makeDateTime(year, month, day, time, errorMessage);
  }

  // RFC 1123 and asctime both start with a short weekday.
  scanner.expect(_shortWeekdayRegExp, errorMessage);
  if (scanner.scan(", ")) {
    // RFC 1123 follows the weekday with a comma.
    var day = _parseInt(scanner, errorMessage, 2);
    scanner.expect(" ", errorMessage);
    var month = _parseMonth(scanner, errorMessage);
    scanner.expect(" ", errorMessage);
    var year = _parseInt(scanner, errorMessage, 4);
    scanner.expect(" ", errorMessage);
    var time = _parseTime(scanner, errorMessage);
    scanner.expect(" GMT", errorMessage);
    if (!scanner.isDone) throw new FormatException(errorMessage);

    return _makeDateTime(year, month, day, time, errorMessage);
  }

  // asctime follows the weekday with a space.
  scanner.expect(" ", errorMessage);
  var month = _parseMonth(scanner, errorMessage);
  scanner.expect(" ", errorMessage);
  var day = scanner.scan(" ") ?
      _parseInt(scanner, errorMessage, 1) :
      _parseInt(scanner, errorMessage, 2);
  scanner.expect(" ", errorMessage);
  var time = _parseTime(scanner, errorMessage);
  scanner.expect(" ", errorMessage);
  var year = _parseInt(scanner, errorMessage, 4);
  if (!scanner.isDone) throw new FormatException(errorMessage);

  return _makeDateTime(year, month, day, time, errorMessage);
}

/// Parses a short-form month name to a form accepted by [DateTime].
int _parseMonth(StringScanner scanner, String errorMessage) {
  scanner.expect(_monthRegExp, errorMessage);
  // DateTime uses 1-indexed months.
  return _MONTHS.indexOf(scanner.lastMatch[0]) + 1;
}

/// Parses an int an enforces that it has exactly [digits] digits.
int _parseInt(StringScanner scanner, String errorMessage, int digits) {
  scanner.expect(_digitRegExp, errorMessage);
  if (scanner.lastMatch[0].length != digits) {
    throw new FormatException(errorMessage);
  } else {
    return int.parse(scanner.lastMatch[0]);
  }
}

/// Parses an timestamp of the form "HH:MM:SS" on a 24-hour clock.
DateTime _parseTime(StringScanner scanner, String errorMessage) {
  var hours = _parseInt(scanner, errorMessage, 2);
  scanner.expect(':', errorMessage);

  var minutes = _parseInt(scanner, errorMessage, 2);
  scanner.expect(':', errorMessage);

  var seconds = _parseInt(scanner, errorMessage, 2);

  if (hours >= 24 || minutes >= 60 || seconds >= 60) {
    throw new FormatException(errorMessage);
  }

  return new DateTime(1, 1, 1, hours, minutes, seconds);
}

/// Returns a UTC [DateTime] from the given components.
///
/// Validates that [day] is a valid day for [month]. If it's not, throws a
/// [FormatException] with [errorMessage].
DateTime _makeDateTime(int year, int month, int day, DateTime time,
    String errorMessage) {
  if (day < 1) throw new FormatException(errorMessage);
  var dateTime = new DateTime.utc(
      year, month, day, time.hour, time.minute, time.second);

  // If [day] was too large, it will cause [month] to overflow.
  if (dateTime.month != month) throw new FormatException(errorMessage);
  return dateTime;
}
