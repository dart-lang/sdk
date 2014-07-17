// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Tests the DateFormat library in dart. This file contains core tests that
 * are run regardless of where the locale data is found, so it doesn't expect to
 * be run on its own, but rather to be imported and run from another test file.
 */

library date_time_format_tests;

import 'package:unittest/unittest.dart';
import 'date_time_format_test_data.dart';
import 'package:intl/intl.dart';
import 'package:intl/src/date_format_internal.dart';

var formatsToTest = const [
  DateFormat.DAY,
  DateFormat.ABBR_WEEKDAY,
  DateFormat.WEEKDAY,
  DateFormat.ABBR_STANDALONE_MONTH,
  DateFormat.STANDALONE_MONTH,
  DateFormat.NUM_MONTH,
  DateFormat.NUM_MONTH_DAY,
  DateFormat.NUM_MONTH_WEEKDAY_DAY,
  DateFormat.ABBR_MONTH,
  DateFormat.ABBR_MONTH_DAY,
  DateFormat.ABBR_MONTH_WEEKDAY_DAY,
  DateFormat.MONTH,
  DateFormat.MONTH_DAY,
  DateFormat.MONTH_WEEKDAY_DAY,
  DateFormat.ABBR_QUARTER,
  DateFormat.QUARTER,
  DateFormat.YEAR,
  DateFormat.YEAR_NUM_MONTH,
  DateFormat.YEAR_NUM_MONTH_DAY,
  DateFormat.YEAR_NUM_MONTH_WEEKDAY_DAY,
  DateFormat.YEAR_ABBR_MONTH,
  DateFormat.YEAR_ABBR_MONTH_DAY,
  DateFormat.YEAR_ABBR_MONTH_WEEKDAY_DAY,
  DateFormat.YEAR_MONTH,
  DateFormat.YEAR_MONTH_DAY,
  DateFormat.YEAR_MONTH_WEEKDAY_DAY,
  // TODO(alanknight): CLDR and ICU appear to disagree on these for Japanese
  //    DateFormat.YEAR_ABBR_QUARTER,
  //    DateFormat.YEAR_QUARTER,
  DateFormat.HOUR24,
  DateFormat.HOUR24_MINUTE,
  DateFormat.HOUR24_MINUTE_SECOND,
  DateFormat.HOUR,
  DateFormat.HOUR_MINUTE,
  DateFormat.HOUR_MINUTE_SECOND,
  // TODO(alanknight): Time zone support
  //    DateFormat.HOUR_MINUTE_GENERIC_TZ,
  //    DateFormat.HOUR_MINUTE_TZ,
  //    DateFormat.HOUR_GENERIC_TZ,
  //    DateFormat.HOUR_TZ,
  DateFormat.MINUTE,
  DateFormat.MINUTE_SECOND,
  DateFormat.SECOND
  // ABBR_GENERIC_TZ,
  // GENERIC_TZ,
  // ABBR_SPECIFIC_TZ,
  // SPECIFIC_TZ,
  // ABBR_UTC_TZ
  ];

var icuFormatNamesToTest = const [
  // It would be really nice to not have to duplicate this and just be able
  // to use the names to get reflective access.
  "DAY",
  "ABBR_WEEKDAY",
  "WEEKDAY",
  "ABBR_STANDALONE_MONTH",
  "STANDALONE_MONTH",
  "NUM_MONTH",
  "NUM_MONTH_DAY",
  "NUM_MONTH_WEEKDAY_DAY",
  "ABBR_MONTH",
  "ABBR_MONTH_DAY",
  "ABBR_MONTH_WEEKDAY_DAY",
  "MONTH",
  "MONTH_DAY",
  "MONTH_WEEKDAY_DAY",
  "ABBR_QUARTER",
  "QUARTER",
  "YEAR",
  "YEAR_NUM_MONTH",
  "YEAR_NUM_MONTH_DAY",
  "YEAR_NUM_MONTH_WEEKDAY_DAY",
  "YEAR_ABBR_MONTH",
  "YEAR_ABBR_MONTH_DAY",
  "YEAR_ABBR_MONTH_WEEKDAY_DAY",
  "YEAR_MONTH",
  "YEAR_MONTH_DAY",
  "YEAR_MONTH_WEEKDAY_DAY",
  // TODO(alanknight): CLDR and ICU appear to disagree on these for Japanese.
  // omit for the time being
  //    "YEAR_ABBR_QUARTER",
  //    "YEAR_QUARTER",
  "HOUR24",
  "HOUR24_MINUTE",
  "HOUR24_MINUTE_SECOND",
  "HOUR",
  "HOUR_MINUTE",
  "HOUR_MINUTE_SECOND",
  // TODO(alanknight): Time zone support
  //    "HOUR_MINUTE_GENERIC_TZ",
  //    "HOUR_MINUTE_TZ",
  //    "HOUR_GENERIC_TZ",
  //    "HOUR_TZ",
  "MINUTE",
  "MINUTE_SECOND",
  "SECOND"
  // ABBR_GENERIC_TZ,
  // GENERIC_TZ,
  // ABBR_SPECIFIC_TZ,
  // SPECIFIC_TZ,
  // ABBR_UTC_TZ
];

/**
 * Exercise all of the formats we have explicitly defined on a particular
 * locale. [expectedResults] is a map from ICU format names to the
 * expected result of formatting [date] according to that format in
 * [localeName].
 */
testLocale(String localeName, Map expectedResults, DateTime date) {
  var intl = new Intl(localeName);
  for(int i=0; i<formatsToTest.length; i++) {
    var skeleton = formatsToTest[i];
    var format = intl.date(skeleton);
    var icuName = icuFormatNamesToTest[i];
    var actualResult = format.format(date);
    expect(expectedResults[icuName], equals(actualResult));
  }
}

testRoundTripParsing(String localeName, DateTime date) {
  // In order to test parsing, we can't just read back the date, because
  // printing in most formats loses information. But we can test that
  // what we parsed back prints the same as what we originally printed.
  // At least in most cases. In some cases, we can't even do that. e.g.
  // the skeleton WEEKDAY can't be reconstructed at all, and YEAR_MONTH
  // formats don't give us enough information to construct a valid date.
  var badSkeletons = const [
      DateFormat.ABBR_WEEKDAY,
      DateFormat.WEEKDAY,
      DateFormat.QUARTER,
      DateFormat.ABBR_QUARTER,
      DateFormat.YEAR,
      DateFormat.YEAR_NUM_MONTH,
      DateFormat.YEAR_ABBR_MONTH,
      DateFormat.YEAR_MONTH,
      DateFormat.MONTH_WEEKDAY_DAY,
      DateFormat.NUM_MONTH_WEEKDAY_DAY,
      DateFormat.ABBR_MONTH_WEEKDAY_DAY];
  var originalTime = new DateTime.now();
  var originalTimeZoneOffset = date.timeZoneOffset;
  var originalTimeZoneName = date.timeZoneName;
  for(int i = 0; i < formatsToTest.length; i++) {
    var skeleton = formatsToTest[i];
    if (!badSkeletons.any((x) => x == skeleton)) {
      var format = new DateFormat(skeleton, localeName);
      var actualResult = format.format(date);
      var parsed = format.parse(actualResult);
      var thenPrintAgain = format.format(parsed);
      expect(thenPrintAgain, equals(actualResult));
    }
  }
}

/** A shortcut for returning all the locales we have available.*/
List<String> allLocales() => DateFormat.allLocalesWithSymbols();

Function _subsetFunc;

List<String> _subsetValue;

List<String> get subset {
  if(_subsetValue == null) {
    _subsetValue = _subsetFunc();
  }
  return _subsetValue;
}

// TODO(alanknight): Run specific tests for the en_ISO locale which isn't
// included in CLDR, and check that our patterns for it are correct (they
// very likely aren't).
void runDateTests(Function subsetFunc) {
  assert(subsetFunc != null);
  _subsetFunc = subsetFunc;

  test('Multiple patterns', () {
    var date = new DateTime.now();
    var multiple1 = new DateFormat.yMd().add_jms();
    var multiple2 = new DateFormat("yMd").add_jms();
    var separate1 = new DateFormat.yMd();
    var separate2 = new DateFormat.jms();
    var separateFormat = "${separate1.format(date)} ${separate2.format(date)}";
    expect(multiple1.format(date), equals(multiple2.format(date)));
    expect(multiple1.format(date), equals(separateFormat));
    var customPunctuation = new DateFormat("yMd").addPattern("jms",":::");
    var custom = "${separate1.format(date)}:::${separate2.format(date)}";
    expect(customPunctuation.format(date), equals(custom));
  });

  test('Basic date format parsing', () {
    var date_format = new DateFormat("d");
    expect(
        date_format.parsePattern("hh:mm:ss")
            .map((x) => x.pattern)
            .toList(),
        orderedEquals(["hh",":", "mm",":","ss"]));
    expect(
        date_format.parsePattern("hh:mm:ss")
            .map((x) => x.pattern)
            .toList(),
        orderedEquals(["hh",":", "mm",":","ss"]));
  });

  test('Test ALL the supported formats on representative locales', () {
    var aDate = new DateTime(2012, 1, 27, 20, 58, 59, 0);
    testLocale("en_US", English, aDate);
    if (subset.length > 1) {
      // Don't run if we have just one locale, so some of these won't be there.
      testLocale("de_DE", German, aDate);
      testLocale("fr_FR", French, aDate);
      testLocale("ja_JP", Japanese, aDate);
      testLocale("el_GR", Greek, aDate);
      testLocale("de_AT", Austrian, aDate);
    }
  });

  test('Test round-trip parsing of dates', () {
    var hours = [0, 1, 11, 12, 13, 23];
    var months = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12];
    for (var locale in subset) {
      for (var month in months) {
        var aDate = new DateTime(2012, month, 27, 13, 58, 59, 012);
        testRoundTripParsing(locale, aDate);
      }
      for (var hour in hours) {
        var aDate = new DateTime(2012, 1, 27, hour, 58, 59, 123);
        testRoundTripParsing(locale, aDate);
      }
    }
  });

  // TODO(alanknight): The coverage for patterns and symbols differs
  // at the source, in CLDR 25, so we can't guarantee that all patterns
  // have symbols or vice versa. Wish we could.

  test('Test malformed locales', () {
    // Don't run if we have just one locale, which may not include these.
    if (subset.length <= 1) return;
    var aDate = new DateTime(2012, 1, 27, 20, 58, 59, 0);
    // Austrian is a useful test locale here because it differs slightly
    // from the generic "de" locale so we can tell the difference between
    // correcting to "de_AT" and falling back to just "de".
    testLocale('de-AT', Austrian, aDate);
    testLocale('de_at', Austrian, aDate);
    testLocale('de-at', Austrian, aDate);
  });

  test('Test format creation via Intl', () {
    // Don't run if we have just one locale, which may not include these.
    if (subset.length <= 1) return;
    var intl = new Intl('ja_JP');
    var instanceJP = intl.date('jms');
    var instanceUS = intl.date('jms', 'en_US');
    var blank = intl.date('jms');
    var date = new DateTime(2012, 1, 27, 20, 58, 59, 0);
    expect(instanceJP.format(date), equals("20:58:59"));
    expect(instanceUS.format(date), equals("8:58:59 PM"));
    expect(blank.format(date), equals("20:58:59"));
  });

  test('Test explicit format string', () {
    // Don't run if we have just one locale, which may not include these.
    if (subset.length <= 1) return;
    var aDate = new DateTime(2012, 1, 27, 20, 58, 59, 0);
    // An explicit format that doesn't conform to any skeleton
    var us = new DateFormat(r'yy //// :W \\\\ dd:ss ^&@ M');
    expect(us.format(aDate), equals(r"12 //// :W \\\\ 27:59 ^&@ 1"));
    // The result won't change with locale unless we use fields that are words.
    var greek = new DateFormat(r'yy //// :W \\\\ dd:ss ^&@ M', 'el_GR');
    expect(greek.format(aDate), equals(r"12 //// :W \\\\ 27:59 ^&@ 1"));
    var usWithWords = new DateFormat('yy / :W \\ dd:ss ^&@ MMM', 'en_US');
    var greekWithWords = new DateFormat('yy / :W \\ dd:ss ^&@ MMM', 'el_GR');
    expect(
        usWithWords.format(aDate),
        equals(r"12 / :W \ 27:59 ^&@ Jan"));
    expect(
        greekWithWords.format(aDate),
        equals(r"12 / :W \ 27:59 ^&@ Ιαν"));
    var escaped = new DateFormat(r"hh 'o''clock'");
    expect(escaped.format(aDate), equals(r"08 o'clock"));
    var reParsed = escaped.parse(escaped.format(aDate));
    expect(escaped.format(reParsed), equals(escaped.format(aDate)));
    var noSeparators = new DateFormat('HHmmss');
    expect(noSeparators.format(aDate), equals("205859"));
    });

  test('Test fractional seconds padding', () {
    var one = new DateTime(2012, 1, 27, 20, 58, 59, 1);
    var oneHundred = new DateTime(2012, 1, 27, 20, 58, 59, 100);
    var fractional = new DateFormat('hh:mm:ss.SSS', 'en_US');
    expect(fractional.format(one), equals('08:58:59.001'));
    expect(fractional.format(oneHundred), equals('08:58:59.100'));
    var long = new DateFormat('ss.SSSSSSSS', 'en_US');
    expect(long.format(oneHundred), equals('59.10000000'));
    expect(long.format(one), equals('59.00100000'));
  });

  test('Test parseUTC', () {
    var local = new DateTime(2012, 1, 27, 20, 58, 59, 1);
    var utc = new DateTime.utc(2012, 1, 27, 20, 58, 59, 1);
    // Getting the offset as a duration via difference() would be simpler,
    // but doesn't work on dart2js in checked mode. See issue 4437.
    var offset = utc.millisecondsSinceEpoch - local.millisecondsSinceEpoch;
    var format = new DateFormat('yyyy-MM-dd HH:mm:ss');
    var localPrinted = format.format(local);
    var parsed = format.parse(localPrinted);
    var parsedUTC = format.parseUTC(format.format(utc));
    var parsedOffset = parsedUTC.millisecondsSinceEpoch
        - parsed.millisecondsSinceEpoch;
    expect(parsedOffset, equals(offset));
    expect(utc.hour, equals(parsedUTC.hour));
    expect(local.hour, equals(parsed.hour));
    });

  test('Test 0-padding', () {
    var someDate = new DateTime(123, 1, 2, 3, 4, 5);
    var format = new DateFormat('yyyy-MM-dd HH:mm:ss');
    expect(format.format(someDate), '0123-01-02 03:04:05');
  });

  test('Test default format', () {
    var someDate = new DateTime(2012, 1, 27, 20, 58, 59, 1);
    var emptyFormat = new DateFormat(null, "en_US");
    var knownDefault = new DateFormat.yMMMMd("en_US").add_jms();
    var result = emptyFormat.format(someDate);
    var knownResult = knownDefault.format(someDate);
    expect(result, knownResult);
  });

  test('Get symbols', () {
    var emptyFormat = new DateFormat(null, "en_US");
    var symbols = emptyFormat.dateSymbols;
    expect(symbols.NARROWWEEKDAYS, ['S', 'M', 'T', 'W', 'T', 'F', 'S']);
  });

  test('Quarter calculation', () {
    var quarters = ['Q1', 'Q1', 'Q1',
                    'Q2', 'Q2', 'Q2',
                    'Q3', 'Q3', 'Q3',
                    'Q4', 'Q4', 'Q4'];
    var quarterFormat = new DateFormat.QQQ();
    for (int i = 0; i < 12; i++) {
        var month = i + 1;
        var aDate = new DateTime(2012, month, 27, 13, 58, 59, 012);
        var formatted = quarterFormat.format(aDate);
        expect(formatted, quarters[i]);
    }
  });

  /**
   * Generate a map from day numbers in the given [year] (where Jan 1 == 1)
   * to a Date object. If [year] is a leap year, then pass 1 for
   * [leapDay], otherwise pass 0.
   */
  Map<int, DateTime> generateDates(int year, int leapDay) =>
      new Iterable.generate(365 + leapDay, (n) => n + 1)
        .map((day) {
          var result = new DateTime(year, 1, day);
          // TODO(alanknight): This is a workaround for dartbug.com/15560.
          if (result.toUtc() == result) result = new DateTime(year, 1, day);
          return result;
        }).toList().asMap();

  void verifyOrdinals(Map dates) {
    var f = new DateFormat("D");
    var withYear = new DateFormat("yyyy D");
    dates.forEach((number, date) {
      var formatted = f.format(date);
      expect(formatted, (number + 1).toString());
      var formattedWithYear = withYear.format(date);
      var parsed = withYear.parse(formattedWithYear);
      expect(parsed, date);
    });
  }

  test('Ordinal Date', () {
    var f = new DateFormat("D");
    var dates = generateDates(2012, 1);
    var nonLeapDates = generateDates(2013, 0);
    verifyOrdinals(dates);
    verifyOrdinals(nonLeapDates);
    // Check one hard-coded just to be on the safe side.
    var aDate = new DateTime(2012, 4, 27, 13, 58, 59, 012);
    expect(f.format(aDate), "118");
  });

  // There are some very odd off-by-one bugs when parsing dates. Put in
  // some very basic tests to try and get more information.
  test('Simple Date Creation', () {
    var format = new DateFormat(DateFormat.NUM_MONTH);
    var first = format.parse("7");
    var second = format.parse("7");
    var basic = new DateTime(1970, 7);
    var basicAgain = new DateTime(1970, 7);
    expect(first, second);
    expect(first, basic);
    expect(basic, basicAgain);
    expect(first.month, 7);
  });
}
