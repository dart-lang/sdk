// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:unittest/unittest.dart';

import 'analysis_notification_navigation_test.dart' as analysis_notification_navigation_test;
import 'analysis_notification_outline_test.dart' as analysis_notification_outline_test;
import 'analysis_server_test.dart' as analysis_server_test;
import 'channel_test.dart' as channel_test;
import 'domain_analysis_test.dart' as domain_analysis_test;
import 'domain_server_test.dart' as domain_server_test;
import 'operation/test_all.dart' as operation_test;
import 'protocol_test.dart' as protocol_test;
import 'resource_test.dart' as resource_test;
import 'socket_server_test.dart' as socket_server_test;

/**
 * Utility for manually running all tests.
 */
main() {
  groupSep = ' | ';
  group('analysis_server', () {
    analysis_notification_navigation_test.main();
    analysis_notification_outline_test.main();
    analysis_server_test.main();
    channel_test.main();
    domain_analysis_test.main();
    domain_server_test.main();
    operation_test.main();
    protocol_test.main();
    resource_test.main();
    socket_server_test.main();
  });
}