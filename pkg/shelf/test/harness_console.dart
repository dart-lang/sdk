// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*
 * This file imports all individual tests files and allows them to be run
 * all at once.
 *
 * It also exposes `testCore` which is used by `hop_runner` to rust tests via
 * Hop.
 */
library harness_console;

import 'package:unittest/unittest.dart';

import 'create_middleware_test.dart' as create_middleware;
import 'http_date_test.dart' as http_date;
import 'log_middleware_test.dart' as log_middleware;
import 'media_type_test.dart' as media_type;
import 'request_test.dart' as request;
import 'response_test.dart' as response;
import 'shelf_io_test.dart' as shelf_io;
import 'stack_test.dart' as stack;

void main() {
  groupSep = ' - ';

  group('createMiddleware', create_middleware.main);
  group('http_date', http_date.main);
  group('logRequests', log_middleware.main);
  group('MediaType', media_type.main);
  group('Request', request.main);
  group('Response', response.main);
  group('shelf_io', shelf_io.main);
  group('Stack', stack.main);
}
