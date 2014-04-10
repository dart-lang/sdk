// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// or details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Test date formatting and parsing using locale data read via an http request
 * to a server.
 */

library date_time_format_http_request_test;

import 'dart:html';
import 'package:unittest/html_config.dart';
import 'package:unittest/unittest.dart';
import 'package:intl/date_symbol_data_http_request.dart';
import 'date_time_format_test_stub.dart';

main() {
  useHtmlConfiguration();
  var url = "http://localhost:${window.location.port}"
    "/root_dart/pkg/intl/lib/src/data/dates/";

   test("Initializing a locale that needs fallback", () {
     initializeDateFormatting("de_DE", url).then(expectAsync((_) => true));
   });

  runWith(smallSetOfLocales, url, initializeDateFormatting);
}
