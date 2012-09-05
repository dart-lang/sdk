// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Test date formatting and parsing using locale data which is available
 * directly in the program as a constant.*/

#library('date_time_format_test');

#import('../date_format.dart');
#import('../date_time_patterns.dart');
#import('../date_symbol_data_local.dart');
#import('date_time_format_test_core.dart');

main() {
  // Initialize one locale just so we know what the list is.
  initializeDateFormatting("en_US",null).then(runEverything);
}

void runEverything(_) {
  // Initialize all locales and wait for them to finish before running tests.
  var futures = DateFormat.allLocalesWithSymbols().map(
      (locale) => initializeDateFormatting(locale, null));
  Futures.wait(futures).then((results) => runDateTests());
}