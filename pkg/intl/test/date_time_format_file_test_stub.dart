// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Tests date formatting and parsing using locale data read from the
 * local file system.
 */

#library('date_time_format_file_test');

#import('../lib/date_format.dart');
#import('../lib/date_symbol_data_file.dart');
#import('dart:io');
#import('date_time_format_test_core.dart');
#import('data_directory.dart');
#import('../../../pkg/unittest/unittest.dart');

runWith([Function getSubset]) {
  // Initialize one locale just so we know what the list is.
  test('Run all date formatting tests with locales from files', () {
    initializeDateFormatting("en_US", dataDirectory).then(
        expectAsync1((_) => runEverything(getSubset)));
  });
}

void runEverything(Function getSubset) {
  // Initialize all locales and wait for them to finish before running tests.
  var futures = DateFormat.allLocalesWithSymbols().map(
      (locale) => initializeDateFormatting(locale, dataDirectory));
  test('Run all date formatting tests nested test', () {
    Futures.wait(futures).then(
        expectAsync1((results) => runDateTests(getSubset())));
  });
}