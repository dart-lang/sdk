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

  Map serializeToMap() {
    var map = new Map();
    map["NAME"] = NAME;
    map["ERAS"] = ERAS;
    map["ERANAMES"] = ERANAMES;
    map["NARROWMONTHS"] = NARROWMONTHS;
    map["STANDALONENARROWMONTHS"] = STANDALONENARROWMONTHS;
    map["MONTHS"] = MONTHS;
    map["STANDALONEMONTHS"] = STANDALONEMONTHS;
    map["SHORTMONTHS"] = SHORTMONTHS;
    map["STANDALONESHORTMONTHS"] = STANDALONESHORTMONTHS;
    map["WEEKDAYS"] = WEEKDAYS;
    map["STANDALONEWEEKDAYS"] = STANDALONEWEEKDAYS;
    map["SHORTWEEKDAYS"] = SHORTWEEKDAYS;
    map["STANDALONESHORTWEEKDAYS"] = STANDALONESHORTWEEKDAYS;
    map["NARROWWEEKDAYS"] = NARROWWEEKDAYS;
    map["STANDALONENARROWWEEKDAYS"] = STANDALONENARROWWEEKDAYS;
    map["SHORTQUARTERS"] = SHORTQUARTERS;
    map["QUARTERS"] = QUARTERS;
    map["AMPMS"] = AMPMS;
    map["DATEFORMATS"] = DATEFORMATS;
    map["TIMEFORMATS"] = TIMEFORMATS;
    map["AVAILABLEFORMATS"] = AVAILABLEFORMATS;
    map["FIRSTDAYOFWEEK"] = FIRSTDAYOFWEEK;
    map["WEEKENDRANGE"] = WEEKENDRANGE;
    map["FIRSTWEEKCUTOFFDAY"] = FIRSTWEEKCUTOFFDAY;
    return map;
  }

  toString() => NAME;
}