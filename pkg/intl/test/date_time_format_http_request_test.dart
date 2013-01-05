// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// or details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Test date formatting and parsing using locale data read via an http request
 * to a server.
 */

library date_time_format_http_request_test;

import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_http_request.dart';
import 'date_time_format_test_core.dart';
import 'dart:html';
import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';

var url = '';

main() {
  useHtmlConfiguration();
  url = "http://localhost:${window.location.port}/pkg/intl/lib/src/data/dates/";
  // Initialize one locale just so we know what the list is.
  test('Run everything', () {
    initializeDateFormatting("en_US", url).then(expectAsync1(runEverything));});
}

void runEverything(_) {
  // Initialize all locales and wait for them to finish before running tests.
  var futures = DateFormat.allLocalesWithSymbols().map(
      (locale) => initializeDateFormatting(locale, url));
  Futures.wait(futures).then(expectAsync1((_) {
      runDateTests(smallSetOfLocales());
    }));
}
