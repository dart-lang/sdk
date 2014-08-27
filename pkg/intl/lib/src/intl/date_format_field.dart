// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of intl;

/**
 * This is a private class internal to DateFormat which is used for formatting
 * particular fields in a template. e.g. if the format is hh:mm:ss then the
 * fields would be "hh", ":", "mm", ":", and "ss". Each type of field knows
 * how to format that portion of a date.
 */
abstract class _DateFormatField {
  /** The format string that defines us, e.g. "hh" */
  String pattern;

  /** The DateFormat that we are part of.*/
  DateFormat parent;

  _DateFormatField(this.pattern, this.parent);

  /**
   * Return the width of [pattern]. Different widths represent different
   * formatting options. See the comment for DateFormat for details.
   */
  int get width => pattern.length;

  String fullPattern() => pattern;

  String toString() => pattern;

  /** Format date according to our specification and return the result. */
  String format(DateTime date) {
    // Default implementation in the superclass, works for both types of
    // literal patterns, and is overridden by _DateFormatPatternField.
    return pattern;
  }

  /** Abstract method for subclasses to implementing parsing for their format.*/
  void parse(_Stream input, _DateBuilder dateFields);

  /** Parse a literal field. We just look for the exact input. */
  void parseLiteral(_Stream input) {
    var found = input.read(width);
    if (found != pattern) {
      throwFormatException(input);
    }
  }

  /** Throw a format exception with an error message indicating the position.*/
  void throwFormatException(_Stream stream) {
    throw new FormatException("Trying to read $this from ${stream.contents} "
        "at position ${stream.index}");
  }
}

/**
 * Represents a literal field - a sequence of characters that doesn't
 * change according to the date's data. As such, the implementation
 * is extremely simple.
 */
class _DateFormatLiteralField extends _DateFormatField {

  _DateFormatLiteralField(pattern, parent): super(pattern, parent);

  parse(_Stream input, _DateBuilder dateFields) {
    return parseLiteral(input);
  }
}

/**
 * Represents a literal field with quoted characters in it. This is
 * only slightly more complex than a _DateFormatLiteralField.
 */
class _DateFormatQuotedField extends _DateFormatField {

  String _fullPattern;

  String fullPattern() => _fullPattern;

  _DateFormatQuotedField(pattern, parent): super(pattern, parent) {
    _fullPattern = pattern;
    patchQuotes();
  }

  parse(_Stream input, _DateBuilder dateFields) {
    return parseLiteral(input);
  }

  void patchQuotes() {
    if (pattern == "''") {
      pattern = "'";
    } else {
      pattern = pattern.substring(1, pattern.length - 1);
      var twoEscapedQuotes = new RegExp(r"''");
      pattern = pattern.replaceAll(twoEscapedQuotes, "'");
    }
  }
}

/*
 * Represents a field in the pattern that formats some aspect of the
 * date. Consists primarily of a switch on the particular pattern characters
 * to determine what to do.
 */
class _DateFormatPatternField extends _DateFormatField {

  _DateFormatPatternField(pattern, parent): super(pattern,  parent);

  /** Format date according to our specification and return the result. */
  String format(DateTime date) {
    return formatField(date);
  }

  /**
   * Parse the date according to our specification and put the result
   * into the correct place in dateFields.
   */
  void parse(_Stream input, _DateBuilder dateFields) {
    parseField(input, dateFields);
  }

  /**
   * Parse a field representing part of a date pattern. Note that we do not
   * return a value, but rather build up the result in [builder].
   */
  void parseField(_Stream input, _DateBuilder builder) {
   try {
     switch(pattern[0]) {
       case 'a': parseAmPm(input, builder); break;
       case 'c': parseStandaloneDay(input); break;
       case 'd': handleNumericField(input, builder.setDay); break; // day
       // Day of year. Setting month=January with any day of the year works
       case 'D': handleNumericField(input, builder.setDay); break; // dayofyear
       case 'E': parseDayOfWeek(input); break;
       case 'G': break; // era
       case 'h': parse1To12Hours(input, builder); break;
       case 'H': handleNumericField(input, builder.setHour); break; // hour 0-23
       case 'K': handleNumericField(input, builder.setHour); break; //hour 0-11
       case 'k': handleNumericField(input, builder.setHour,-1); break; //hr 1-24
       case 'L': parseStandaloneMonth(input, builder); break;
       case 'M': parseMonth(input, builder); break;
       case 'm': handleNumericField(input, builder.setMinute); break; // minutes
       case 'Q': break; // quarter
       case 'S': handleNumericField(input, builder.setFractionalSecond); break;
       case 's': handleNumericField(input, builder.setSecond); break;
       case 'v': break; // time zone id
       case 'y': handleNumericField(input, builder.setYear); break;
       case 'z': break; // time zone
       case 'Z': break; // time zone RFC
       default: return;
     }
   } catch (e) { throwFormatException(input); }
 }

  /** Formatting logic if we are of type FIELD */
  String formatField(DateTime date) {
     switch (pattern[0]) {
      case 'a': return formatAmPm(date);
      case 'c': return formatStandaloneDay(date);
      case 'd': return formatDayOfMonth(date);
      case 'D': return formatDayOfYear(date);
      case 'E': return formatDayOfWeek(date);
      case 'G': return formatEra(date);
      case 'h': return format1To12Hours(date);
      case 'H': return format0To23Hours(date);
      case 'K': return format0To11Hours(date);
      case 'k': return format24Hours(date);
      case 'L': return formatStandaloneMonth(date);
      case 'M': return formatMonth(date);
      case 'm': return formatMinutes(date);
      case 'Q': return formatQuarter(date);
      case 'S': return formatFractionalSeconds(date);
      case 's': return formatSeconds(date);
      case 'v': return formatTimeZoneId(date);
      case 'y': return formatYear(date);
      case 'z': return formatTimeZone(date);
      case 'Z': return formatTimeZoneRFC(date);
      default: return '';
    }
  }

  /** Return the symbols for our current locale. */
  DateSymbols get symbols => dateTimeSymbols[parent.locale];

  formatEra(DateTime date) {
    var era = date.year > 0 ? 1 : 0;
    return width >= 4 ? symbols.ERANAMES[era] :
                        symbols.ERAS[era];
  }

  formatYear(DateTime date) {
    // TODO(alanknight): Proper handling of years <= 0
    var year = date.year;
    if (year < 0) {
      year = -year;
    }
    return width == 2 ? padTo(2, year % 100) : padTo(width, year);
  }

  /**
   * We are given [input] as a stream from which we want to read a date. We
   * can't dynamically build up a date, so we are given a list [dateFields] of
   * the constructor arguments and an [position] at which to set it
   * (year,month,day,hour,minute,second,fractionalSecond)
   * then after all parsing is done we construct a date from the arguments.
   * This method handles reading any of the numeric fields. The [offset]
   * argument allows us to compensate for zero-based versus one-based values.
   */
  void handleNumericField(_Stream input, Function setter, [int offset = 0]) {
    var result = input.nextInteger();
    if (result == null) throwFormatException(input);
    setter(result + offset);
  }

  /**
   * We are given [input] as a stream from which we want to read a date. We
   * can't dynamically build up a date, so we are given a list [dateFields] of
   * the constructor arguments and an [position] at which to set it
   * (year,month,day,hour,minute,second,fractionalSecond)
   * then after all parsing is done we construct a date from the arguments.
   * This method handles reading any of string fields from an enumerated set.
   */
   int parseEnumeratedString(_Stream input, List possibilities) {
     var results = new _Stream(possibilities).findIndexes(
       (each) => input.peek(each.length) == each);
     if (results.isEmpty) throwFormatException(input);
     results.sort(
       (a, b) => possibilities[a].length.compareTo(possibilities[b].length));
     var longestResult = results.last;
     input.read(possibilities[longestResult].length);
     return longestResult;
     }

  String formatMonth(DateTime date) {
    switch (width) {
      case 5: return symbols.NARROWMONTHS[date.month-1];
      case 4: return symbols.MONTHS[date.month-1];
      case 3: return symbols.SHORTMONTHS[date.month-1];
      default:
        return padTo(width, date.month);
    }
  }

  void parseMonth(input, dateFields) {
    var possibilities;
    switch(width) {
      case 5: possibilities = symbols.NARROWMONTHS; break;
      case 4: possibilities = symbols.MONTHS; break;
      case 3: possibilities = symbols.SHORTMONTHS; break;
      default: return handleNumericField(input, dateFields.setMonth);
    }
    dateFields.month = parseEnumeratedString(input, possibilities) + 1;
  }

  String format24Hours(DateTime date) {
    return padTo(width, date.hour);
  }

  String formatFractionalSeconds(DateTime date) {
    // Always print at least 3 digits. If the width is greater, append 0s
    var basic = padTo(3, date.millisecond);
    if (width - 3 > 0) {
      var extra = padTo(width - 3, 0);
      return basic + extra;
    } else {
      return basic;
    }
  }

  String formatAmPm(DateTime date) {
    var hours = date.hour;
    var index = (date.hour >= 12) && (date.hour < 24) ? 1 : 0;
    var ampm = symbols.AMPMS;
    return ampm[index];
  }

  void parseAmPm(input, dateFields) {
    // If we see a "PM" note it in an extra field.
    var ampm = parseEnumeratedString(input, symbols.AMPMS);
    if (ampm == 1) dateFields.pm = true;
  }

  String format1To12Hours(DateTime date) {
    var hours = date.hour;
    if (date.hour > 12) hours = hours - 12;
    if (hours == 0) hours = 12;
    return padTo(width, hours);
  }

  void parse1To12Hours(_Stream input, _DateBuilder dateFields) {
    handleNumericField(input, dateFields.setHour);
    if (dateFields.hour == 12) dateFields.hour = 0;
  }

  String format0To11Hours(DateTime date) {
    return padTo(width, date.hour % 12);
  }

  String format0To23Hours(DateTime date) {
    return padTo(width, date.hour);
  }

  String formatStandaloneDay(DateTime date) {
    switch (width) {
      case 5: return symbols.STANDALONENARROWWEEKDAYS[date.weekday % 7];
      case 4: return symbols.STANDALONEWEEKDAYS[date.weekday % 7];
      case 3: return symbols.STANDALONESHORTWEEKDAYS[date.weekday % 7];
      default:
        return padTo(1, date.day);
    }
  }

  void parseStandaloneDay(_Stream input) {
    // This is ignored, but we still have to skip over it the correct amount.
    var possibilities;
    switch(width) {
      case 5: possibilities = symbols.STANDALONENARROWWEEKDAYS; break;
      case 4: possibilities = symbols.STANDALONEWEEKDAYS; break;
      case 3: possibilities = symbols.STANDALONESHORTWEEKDAYS; break;
      default: return handleNumericField(input, (x)=>x);
    }
    parseEnumeratedString(input, possibilities);
  }

  String formatStandaloneMonth(DateTime date) {
  switch (width) {
    case 5:
      return symbols.STANDALONENARROWMONTHS[date.month-1];
    case 4:
      return symbols.STANDALONEMONTHS[date.month-1];
    case 3:
      return symbols.STANDALONESHORTMONTHS[date.month-1];
    default:
      return padTo(width, date.month);
    }
  }

  void parseStandaloneMonth(input, dateFields) {
    var possibilities;
    switch(width) {
      case 5: possibilities = symbols.STANDALONENARROWMONTHS; break;
      case 4: possibilities = symbols.STANDALONEMONTHS; break;
      case 3: possibilities = symbols.STANDALONESHORTMONTHS; break;
      default: return handleNumericField(input, dateFields.setMonth);
    }
    dateFields.month = parseEnumeratedString(input, possibilities) + 1;
  }

  String formatQuarter(DateTime date) {
    var quarter = ((date.month - 1) / 3).truncate();
    if (width < 4) {
      return symbols.SHORTQUARTERS[quarter];
    } else {
      return symbols.QUARTERS[quarter];
    }
  }
  String formatDayOfMonth(DateTime date) {
    return padTo(width, date.day);
  }

  String formatDayOfYear(DateTime date) => padTo(width, dayNumberInYear(date));

  /** Return the ordinal day, i.e. the day number in the year. */
  int dayNumberInYear(DateTime date) {
    if (date.month == 1) return date.day;
    if (date.month == 2) return date.day + 31;
    return ordinalDayFromMarchFirst(date) + 59 + (isLeapYear(date) ? 1 : 0);
  }

  /**
   * Return the day of the year counting March 1st as 1, after which the
   * number of days per month is constant, so it's easier to calculate.
   * Formula from http://en.wikipedia.org/wiki/Ordinal_date
   */
  int ordinalDayFromMarchFirst(DateTime date) =>
      ((30.6 * date.month) - 91.4).floor() + date.day;

  /**
   * Return true if this is a leap year. Rely on [DateTime] to do the
   * underlying calculation, even though it doesn't expose the test to us.
   */
  bool isLeapYear(DateTime date) {
    var feb29 = new DateTime(date.year, 2, 29);
    return feb29.month == 2;
  }

  String formatDayOfWeek(DateTime date) {
    // Note that Dart's weekday returns 1 for Monday and 7 for Sunday.
    return (width >= 4 ? symbols.WEEKDAYS :
                        symbols.SHORTWEEKDAYS)[(date.weekday) % 7];
  }

  void parseDayOfWeek(_Stream input) {
    // This is IGNORED, but we still have to skip over it the correct amount.
    var possibilities = width >= 4 ? symbols.WEEKDAYS : symbols.SHORTWEEKDAYS;
    parseEnumeratedString(input, possibilities);
  }

  String formatMinutes(DateTime date) {
    return padTo(width, date.minute);
  }

  String formatSeconds(DateTime date) {
    return padTo(width, date.second);
  }

  String formatTimeZoneId(DateTime date) {
    // TODO(alanknight): implement time zone support
    throw new UnimplementedError();
  }

  String formatTimeZone(DateTime date) {
    throw new UnimplementedError();
  }

  String formatTimeZoneRFC(DateTime date) {
    throw new UnimplementedError();
  }

  /**
  * Return a string representation of the object padded to the left with
  * zeros. Primarily useful for numbers.
  */
  String padTo(int width, Object toBePrinted) {
    var basicString = toBePrinted.toString();
    if (basicString.length >= width) return basicString;
    var buffer = new StringBuffer();
    for (var i = 0; i < width - basicString.length; i++) {
      buffer.write('0');
    }
    buffer.write(basicString);
    return buffer.toString();
  }
}
