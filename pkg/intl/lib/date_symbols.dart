// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library date_symbols;

/**
 * This holds onto information about how a particular locale formats dates. It
 * contains mostly strings, e.g. what the names of months or weekdays are,
 * but also indicates things like the first day of the week. We expect the data
 * for instances of these to be generated out of ICU or a similar reference
 * source. This is used in conjunction with the date_time_patterns, which
 * defines for a particular locale the different named formats that will
 * make use of this data.
 */
class DateSymbols {
  String NAME;
  List<String> ERAS, ERANAMES, NARROWMONTHS, STANDALONENARROWMONTHS,
      MONTHS, STANDALONEMONTHS, SHORTMONTHS, STANDALONESHORTMONTHS, WEEKDAYS,
      STANDALONEWEEKDAYS, SHORTWEEKDAYS, STANDALONESHORTWEEKDAYS,
      NARROWWEEKDAYS, STANDALONENARROWWEEKDAYS, SHORTQUARTERS,
      QUARTERS, AMPMS, DATEFORMATS, TIMEFORMATS;
  Map<String, String> AVAILABLEFORMATS;
  int FIRSTDAYOFWEEK;
  List<int> WEEKENDRANGE;
  int FIRSTWEEKCUTOFFDAY;

  DateSymbols({this.NAME,
               this.ERAS,
               this.ERANAMES,
               this.NARROWMONTHS,
               this.STANDALONENARROWMONTHS,
               this.MONTHS,
               this.STANDALONEMONTHS,
               this.SHORTMONTHS,
               this.STANDALONESHORTMONTHS,
               this.WEEKDAYS,
               this.STANDALONEWEEKDAYS,
               this.SHORTWEEKDAYS,
               this.STANDALONESHORTWEEKDAYS,
               this.NARROWWEEKDAYS,
               this.STANDALONENARROWWEEKDAYS,
               this.SHORTQUARTERS,
               this.QUARTERS,
               this.AMPMS,
               // TODO(alanknight): These formats are taken from Closure,
               // where there's only a fixed set of available formats.
               // Here we have the patterns separately. These should
               // either be used, or removed.
               this.DATEFORMATS,
               this.TIMEFORMATS,
               this.AVAILABLEFORMATS,
               this.FIRSTDAYOFWEEK,
               this.WEEKENDRANGE,
               this.FIRSTWEEKCUTOFFDAY});

  // TODO(alanknight): Replace this with use of a more general serialization
  // facility once one is available. Issue 4926.
  DateSymbols.deserializeFromMap(Map map) {
    NAME = map["NAME"];
    ERAS = map["ERAS"];
    ERANAMES = map["ERANAMES"];
    NARROWMONTHS = map["NARROWMONTHS"];
    STANDALONENARROWMONTHS = map["STANDALONENARROWMONTHS"];
    MONTHS = map["MONTHS"];
    STANDALONEMONTHS = map["STANDALONEMONTHS"];
    SHORTMONTHS = map["SHORTMONTHS"];
    STANDALONESHORTMONTHS = map["STANDALONESHORTMONTHS"];
    WEEKDAYS = map["WEEKDAYS"];
    STANDALONEWEEKDAYS = map["STANDALONEWEEKDAYS"];
    SHORTWEEKDAYS = map["SHORTWEEKDAYS"];
    STANDALONESHORTWEEKDAYS = map["STANDALONESHORTWEEKDAYS"];
    NARROWWEEKDAYS = map["NARROWWEEKDAYS"];
    STANDALONENARROWWEEKDAYS = map["STANDALONENARROWWEEKDAYS"];
    SHORTQUARTERS = map["SHORTQUARTERS"];
    QUARTERS = map["QUARTERS"];
    AMPMS = map["AMPMS"];
    DATEFORMATS = map["DATEFORMATS"];
    TIMEFORMATS = map["TIMEFORMATS"];
    AVAILABLEFORMATS = map["AVAILABLEFORMATS"];
    FIRSTDAYOFWEEK = map["FIRSTDAYOFWEEK"];
    WEEKENDRANGE = map["WEEKENDRANGE"];
    FIRSTWEEKCUTOFFDAY = map["FIRSTWEEKCUTOFFDAY"];
  }

  Map serializeToMap() => {
    "NAME": NAME,
    "ERAS": ERAS,
    "ERANAMES": ERANAMES,
    "NARROWMONTHS": NARROWMONTHS,
    "STANDALONENARROWMONTHS": STANDALONENARROWMONTHS,
    "MONTHS": MONTHS,
    "STANDALONEMONTHS": STANDALONEMONTHS,
    "SHORTMONTHS": SHORTMONTHS,
    "STANDALONESHORTMONTHS": STANDALONESHORTMONTHS,
    "WEEKDAYS": WEEKDAYS,
    "STANDALONEWEEKDAYS": STANDALONEWEEKDAYS,
    "SHORTWEEKDAYS": SHORTWEEKDAYS,
    "STANDALONESHORTWEEKDAYS": STANDALONESHORTWEEKDAYS,
    "NARROWWEEKDAYS": NARROWWEEKDAYS,
    "STANDALONENARROWWEEKDAYS": STANDALONENARROWWEEKDAYS,
    "SHORTQUARTERS": SHORTQUARTERS,
    "QUARTERS": QUARTERS,
    "AMPMS": AMPMS,
    "DATEFORMATS": DATEFORMATS,
    "TIMEFORMATS": TIMEFORMATS,
    "AVAILABLEFORMATS": AVAILABLEFORMATS,
    "FIRSTDAYOFWEEK": FIRSTDAYOFWEEK,
    "WEEKENDRANGE": WEEKENDRANGE,
    "FIRSTWEEKCUTOFFDAY": FIRSTWEEKCUTOFFDAY
  };

  toString() => NAME;
}

/**
 * We hard-code the locale data for en_US here so that there's at least one
 * locale always available.
 */
var en_USSymbols = new DateSymbols(
    NAME: "en_US",
    ERAS: const [ 'BC', 'AD'],
    ERANAMES: const [ 'Before Christ', 'Anno Domini'],
    NARROWMONTHS: const [ 'J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O',
         'N', 'D'],
    STANDALONENARROWMONTHS: const [ 'J', 'F', 'M', 'A', 'M', 'J', 'J', 'A',
         'S', 'O', 'N', 'D'],
    MONTHS: const [ 'January', 'February', 'March', 'April', 'May', 'June',
         'July', 'August', 'September', 'October', 'November', 'December'],
    STANDALONEMONTHS: const [ 'January', 'February', 'March', 'April', 'May',
         'June', 'July', 'August', 'September', 'October', 'November',
         'December'],
    SHORTMONTHS: const [ 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul',
         'Aug', 'Sep', 'Oct', 'Nov', 'Dec'],
    STANDALONESHORTMONTHS: const [ 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
         'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'],
    WEEKDAYS: const [ 'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday',
         'Friday', 'Saturday'],
    STANDALONEWEEKDAYS: const [ 'Sunday', 'Monday', 'Tuesday', 'Wednesday',
         'Thursday', 'Friday', 'Saturday'],
    SHORTWEEKDAYS: const [ 'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'],
    STANDALONESHORTWEEKDAYS: const [ 'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri',
         'Sat'],
    NARROWWEEKDAYS: const [ 'S', 'M', 'T', 'W', 'T', 'F', 'S'],
    STANDALONENARROWWEEKDAYS: const [ 'S', 'M', 'T', 'W', 'T', 'F', 'S'],
    SHORTQUARTERS: const [ 'Q1', 'Q2', 'Q3', 'Q4'],
    QUARTERS: const [ '1st quarter', '2nd quarter', '3rd quarter',
         '4th quarter'],
    AMPMS: const [ 'AM', 'PM'],
    DATEFORMATS: const [ 'EEEE, MMMM d, y', 'MMMM d, y', 'MMM d, y',
         'M/d/yy'],
    TIMEFORMATS: const [ 'h:mm:ss a zzzz', 'h:mm:ss a z', 'h:mm:ss a',
         'h:mm a'],
    FIRSTDAYOFWEEK: 6,
    WEEKENDRANGE: const [5, 6],
    FIRSTWEEKCUTOFFDAY: 5);

var en_USPatterns = const {
  'd': 'd', // DAY
  'E': 'EEE', // ABBR_WEEKDAY
  'EEEE': 'EEEE', // WEEKDAY
  'LLL': 'LLL', // ABBR_STANDALONE_MONTH
  'LLLL': 'LLLL', // STANDALONE_MONTH
  'M': 'L', // NUM_MONTH
  'Md': 'M/d', // NUM_MONTH_DAY
  'MEd': 'EEE, M/d', // NUM_MONTH_WEEKDAY_DAY
  'MMM': 'LLL', // ABBR_MONTH
  'MMMd': 'MMM d', // ABBR_MONTH_DAY
  'MMMEd': 'EEE, MMM d', // ABBR_MONTH_WEEKDAY_DAY
  'MMMM': 'LLLL', // MONTH
  'MMMMd': 'MMMM d', // MONTH_DAY
  'MMMMEEEEd': 'EEEE, MMMM d', // MONTH_WEEKDAY_DAY
  'QQQ': 'QQQ', // ABBR_QUARTER
  'QQQQ': 'QQQQ', // QUARTER
  'y': 'y', // YEAR
  'yM': 'M/y', // YEAR_NUM_MONTH
  'yMd': 'M/d/y', // YEAR_NUM_MONTH_DAY
  'yMEd': 'EEE, M/d/y', // YEAR_NUM_MONTH_WEEKDAY_DAY
  'yMMM': 'MMM y', // YEAR_ABBR_MONTH
  'yMMMd': 'MMM d, y', // YEAR_ABBR_MONTH_DAY
  'yMMMEd': 'EEE, MMM d, y', // YEAR_ABBR_MONTH_WEEKDAY_DAY
  'yMMMM': 'MMMM y', // YEAR_MONTH
  'yMMMMd': 'MMMM d, y', // YEAR_MONTH_DAY
  'yMMMMEEEEd': 'EEEE, MMMM d, y', // YEAR_MONTH_WEEKDAY_DAY
  'yQQQ': 'QQQ y', // YEAR_ABBR_QUARTER
  'yQQQQ': 'QQQQ y', // YEAR_QUARTER
  'H': 'HH', // HOUR24
  'Hm': 'HH:mm', // HOUR24_MINUTE
  'Hms': 'HH:mm:ss', // HOUR24_MINUTE_SECOND
  'j': 'h a', // HOUR
  'jm': 'h:mm a', // HOUR_MINUTE
  'jms': 'h:mm:ss a', // HOUR_MINUTE_SECOND
  'jmv': 'h:mm a v', // HOUR_MINUTE_GENERIC_TZ
  'jmz': 'h:mm a z', // HOUR_MINUTETZ
  'jz': 'h a z', // HOURGENERIC_TZ
  'm': 'm', // MINUTE
  'ms': 'mm:ss', // MINUTE_SECOND
  's': 's', // SECOND
  'v': 'v', // ABBR_GENERIC_TZ
  'z': 'z', // ABBR_SPECIFIC_TZ
  'zzzz': 'zzzz', // SPECIFIC_TZ
  'ZZZZ': 'ZZZZ'  // ABBR_UTC_TZ
};
