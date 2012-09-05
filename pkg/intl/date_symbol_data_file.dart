// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * This file should be imported, along with date_format.dart in order to read
 * locale data from files in the file system.
 */

#library('date_symbol_data_json');

#import("date_symbols.dart");
#import("lib/lazy_locale_data.dart");
#import('lib/date_format_internal.dart');
#import('lib/file_data_reader.dart');
#import('dart:io');

#source("data/dates/localeList.dart");

/**
 * This should be called for at least one [locale] before any date formatting
 * methods are called. It sets up the lookup for date symbols using [path].
 * The [path] parameter should end with a directory separator appropriate
 * for the platform.
 */
Future initializeDateFormatting(String locale, String path) {
  var reader = new FileDataReader('${path}symbols${Platform.pathSeparator}');
  initializeDateSymbols(() => new LazyLocaleData(
      reader, _createDateSymbol, availableLocalesForDateFormatting));
  var reader2 = new FileDataReader('${path}patterns${Platform.pathSeparator}');
  initializeDatePatterns(() => new LazyLocaleData(
      reader2, (x) => x, availableLocalesForDateFormatting));
  return initializeIndividualLocaleDateFormatting(
      (symbols, patterns) {
        return Futures.wait([
            symbols.initLocale(locale),
            patterns.initLocale(locale)]);
      });
}

/** Defines how new date symbol entries are created. */
DateSymbols _createDateSymbol(Map map) {
  return new DateSymbols.deserializeFromMap(map);
}