/**
 * Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
 * for details. All rights reserved. Use of this source code is governed by a
 * BSD-style license that can be found in the LICENSE file.
 */

library number_format_test;

import 'package:unittest/unittest.dart';
import 'package:intl/number_symbols_data.dart';
import 'package:intl/intl.dart';
import 'number_test_data.dart';
import 'dart:math';

/**
 * Tests the Numeric formatting library in dart.
 */
var testNumbers = {
  "0.001": 0.001,
  "0.01": 0.01,
  "0.1": 0.1,
  "1": 1,
  "2": 2.0,
  "10": 10,
  "100": 100,
  "1,000": 1000,
  "2,000,000,000,000": 2000000000000,
  "0.123": 0.123,
  "1,234": 1234.0,
  "1.234": 1.234,
  "1.23": 1.230,
  "NaN": double.NAN,
  "∞": double.INFINITY,
  "-∞": double.NEGATIVE_INFINITY,
  "3.142": PI};

var testExponential = const {
  "1E-3" : 0.001,
  "1E-2": 0.01,
  "1.23E0" : 1.23
  };

// TODO(alanknight): Test against currency, which requires generating data
// for the three different forms that this now supports.
// TODO(alanknight): Test against scientific, which requires significant
// digit support.
List<NumberFormat> standardFormats(String locale) {
  return [
          new NumberFormat.decimalPattern(locale),
          new NumberFormat.percentPattern(locale)
          ];
}

inJavaScript() => 1 is double;

main() {
  if (!inJavaScript()) {
    testNumbers["10,000,000,000,000,000,000,000,000,000,000"] =
        10000000000000000000000000000000;
  }

  // For data from a list of locales, run each locale's data as a separate
  // test so we can see exactly which ones pass or fail.
  var mainList = numberTestData;
  var sortedLocales = new List.from(numberFormatSymbols.keys);
  sortedLocales.sort((a, b) => a.compareTo(b));
  for (var locale in sortedLocales) {
    var testFormats = standardFormats(locale);
    var list = mainList.take(testFormats.length + 1).iterator;
    mainList = mainList.skip(testFormats.length + 1);
    var nextLocaleFromList = (list..moveNext()).current;
    test("Test against ICU data for $locale", () {
      expect(locale, nextLocaleFromList);
      for (var format in testFormats) {
        var formatted = format.format(123);
        var expected = (list..moveNext()).current;
        expect(formatted, expected);
      }
    });
  }

  test('Simple set of numbers', () {
    var number = new NumberFormat();
    for (var x in testNumbers.keys) {
      var formatted = number.format(testNumbers[x]);
      expect(formatted, x);
    }
  });

  test('Exponential form', () {
    var number = new NumberFormat("#.###E0");
    for (var x in testExponential.keys) {
      var formatted = number.format(testExponential[x]);
      expect(formatted, x);
    }
  });

  test('Explicit currency name', () {
    var amount = 1000000.32;
    var usConvention = new NumberFormat.currencyPattern('en_US', '€');
    var formatted = usConvention.format(amount);
    expect(formatted, '€1,000,000.32');
    var swissConvention = new NumberFormat.currencyPattern('de_CH', r'$');
    formatted = swissConvention.format(amount);
    var nbsp = new String.fromCharCode(0xa0);
    expect(formatted, r"$" + nbsp + "1'000'000.32");

    /// Verify we can leave off the currency and it gets filled in.
    var plainSwiss = new NumberFormat.currencyPattern('de_CH');
    formatted = plainSwiss.format(amount);
    expect(formatted, r"CHF" + nbsp + "1'000'000.32");

    // Verify that we can pass null in order to specify the currency symbol
    // but use the default locale.
    var defaultLocale = new NumberFormat.currencyPattern(null, 'Smurfs');
    formatted = defaultLocale.format(amount);
    // We don't know what the exact format will be, but it should have Smurfs.
    expect(formatted.contains('Smurfs'), isTrue);
  });
}
