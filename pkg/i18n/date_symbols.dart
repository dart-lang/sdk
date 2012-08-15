// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
#library("date_symbols");

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
  final String NAME;
  final List<String> ERAS, ERANAMES, NARROWMONTHS, STANDALONENARROWMONTHS,
      MONTHS, STANDALONEMONTHS, SHORTMONTHS, STANDALONESHORTMONTHS, WEEKDAYS,
      STANDALONEWEEKDAYS, SHORTWEEKDAYS, STANDALONESHORTWEEKDAYS,
      NARROWWEEKDAYS, STANDALONENARROWWEEKDAYS, SHORTQUARTERS,
      QUARTERS, AMPMS, DATEFORMATS, TIMEFORMATS;
  final Map<String, String> AVAILABLEFORMATS;
  final int FIRSTDAYOFWEEK;
  final List<int> WEEKENDRANGE;
  final int FIRSTWEEKCUTOFFDAY;

  const DateSymbols([this.NAME,
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
                     this.DATEFORMATS,
                     this.TIMEFORMATS,
                     this.AVAILABLEFORMATS,
                     this.FIRSTDAYOFWEEK,
                     this.WEEKENDRANGE,
                     this.FIRSTWEEKCUTOFFDAY]);

  toString() => NAME;
}