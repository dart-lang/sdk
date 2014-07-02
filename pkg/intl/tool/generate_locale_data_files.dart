// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * A utility program to take locale data represented as a Dart map whose keys
 * are locale names and write it into individual JSON files named by locale.
 * This should be run any time the locale data changes.
 *
 * The files are written under "data/dates", in two subdirectories, "symbols"
 * and "patterns". In "data/dates" it will also generate "locale_list.dart",
 * which is sourced by the date_symbol_data... files.
 */

import '../lib/date_symbol_data_local.dart';
import '../lib/date_time_patterns.dart';
import '../lib/intl.dart';
import 'dart:convert';
import 'dart:io';
import '../test/data_directory.dart';
import 'package:path/path.dart' as path;

main() {
  initializeDateFormatting("en_IGNORED", null);
  writeSymbolData();
  writePatternData();
  writeLocaleList();
}

void writeLocaleList() {
  var file = new File(path.join(dataDirectory, 'locale_list.dart'));
  var output = file.openWrite();
  output.write(
      '// Copyright (c) 2012, the Dart project authors.  Please see the '
      'AUTHORS file\n// for details. All rights reserved. Use of this source'
      'code is governed by a\n// BSD-style license that can be found in the'
      ' LICENSE file.\n\n'
      '/// Hard-coded list of all available locales for dates.\n');
  output.write('final availableLocalesForDateFormatting = const [');
  List<String> allLocales = DateFormat.allLocalesWithSymbols();
  allLocales.forEach((locale) {
    output.write('"$locale"');
    if (locale == allLocales.last) {
      output.write('];');
    } else {
      output.write(',\n    ');
    }
  });
  output.close();
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
  var file = new File(path.join(dataDirectory, 'symbols', '${locale}.json'));
  var output = file.openWrite();
  writeToJSON(symbols, output);
  output.close();
}

void writePatterns(locale, patterns) {
  var file = new File(path.join(dataDirectory, 'patterns', '${locale}.json'));
  file.openWrite()..write(JSON.encode(patterns))..close();
}

void writeToJSON(dynamic data, IOSink out) {
  out.write(JSON.encode(data.serializeToMap()));
}
