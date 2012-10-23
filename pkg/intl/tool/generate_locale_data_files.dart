// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * A utility program to take locale data represented as a Dart map whose keys
 * are locale names and write it into individual JSON files named by locale.
 * This should be run any time the locale data changes.
 *
 * The files are written under "data/dates", in two subdirectories, "symbols"
 * and "patterns". In "data/dates" it will also generate "localeList.dart",
 * which is sourced by the date_symbol_data... files.
 */

import '../lib/date_symbols.dart';
import '../lib/date_symbol_data_local.dart';
import '../lib/date_time_patterns.dart';
import '../lib/intl.dart';
import 'dart:io';
import 'dart:json';
import '../test/data_directory.dart';

main() {
  initializeDateFormatting("en_IGNORED", null);
  writeSymbolData();
  writePatternData();
  writeLocaleList();
}

void writeLocaleList() {
  var file = new File('${dataDirectory}localeList.dart');
  var outputStream = file.openOutputStream();
  outputStream.writeString(
      '// Copyright (c) 2012, the Dart project authors.  Please see the '
      'AUTHORS file\n// for details. All rights reserved. Use of this source'
      'code is governed by a\n// BSD-style license that can be found in the'
      ' LICENSE file.\n\n'
      '/// Hard-coded list of all available locales for dates.\n');
  outputStream.writeString('final availableLocalesForDateFormatting = const [');
  List<String> allLocales = DateFormat.allLocalesWithSymbols();
  allLocales.forEach((locale) {
    outputStream.writeString('"$locale"');
    if (locale == allLocales.last()) {
      outputStream.writeString('];');
    } else {
      outputStream.writeString(',\n    ');
    }
  });
}

void writeSymbolData() {
  dateTimeSymbolMap().forEach(
      (locale, symbols) => writeSymbols(locale, symbols));
}

void writePatternData() {
  dateTimePatternMap().forEach(
      (locale, patterns) => writePatterns(locale, patterns));
}

void writeSymbols(locale, symbols) {
  var file = new File('${dataDirectory}symbols/${locale}.json');
  var outputStream = file.openOutputStream();
  writeToJSON(symbols, outputStream);
  outputStream.close();
}

void writePatterns(locale, patterns) {
  var file = new File('${dataDirectory}patterns/${locale}.json');
  var outputStream = file.openOutputStream();
  outputStream.writeString(JSON.stringify(patterns));
  outputStream.close();
}

void writeToJSON(Dynamic data, OutputStream out) {
  out.writeString(JSON.stringify(data.serializeToMap()));
}