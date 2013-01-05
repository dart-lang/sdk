// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Tests date formatting and parsing using locale data read from the
 * local file system.
 */
library date_time_format_file_test;

import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'date_time_format_test_core.dart';
import 'package:unittest/unittest.dart';

main() {
  runDateTests(['en_US']);
}
