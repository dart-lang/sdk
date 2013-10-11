// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Tests date formatting and parsing using locale data read from the
 * local file system. This tests one half the locales, since testing all
 * of them takes long enough that it may cause timeouts in the test bots.
 */

library date_time_format_file_test_1;
import 'date_time_format_test_stub.dart';
import 'data_directory.dart';
import 'package:intl/date_symbol_data_file.dart';
import 'package:unittest/unittest.dart';

main() {
  unittestConfiguration.timeout = new Duration(seconds: 60);
  runWith(oddLocales, dataDirectory, initializeDateFormatting);
}
