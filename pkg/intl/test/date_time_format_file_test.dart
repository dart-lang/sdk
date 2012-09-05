// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Tests date formatting and parsing using locale data read from the
 * local file system.
 */

#library('date_time_format_test');

#import('../date_format.dart');
#import('../date_symbol_data_file.dart');
#import('dart:io');
#import('date_time_format_test_core.dart');
#import('data_directory.dart');

main() {
  // Initialize one locale just so we know what the list is.
  initializeDateFormatting("en_US", dataDirectory).then(runEverything);
}

void runEverything(_) {
  // Initialize all locales and wait for them to finish before running tests.
  var futures = DateFormat.allLocalesWithSymbols().map(
      (locale) => initializeDateFormatting(locale, dataDirectory));
  Futures.wait(futures).then((results) => runDateTests());
}