// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:unittest/unittest.dart';

import 'analysis/test_all.dart' as analysis_all;
import 'analysis_server_test.dart' as analysis_server_test;
import 'channel/test_all.dart' as channel_test;
import 'completion_test.dart' as completion_test;
import 'context_manager_test.dart' as context_manager_test;
import 'domain_analysis_test.dart' as domain_analysis_test;
import 'domain_completion_test.dart' as domain_completion_test;
import 'domain_diagnostic_test.dart' as domain_experimental_test;
import 'domain_execution_test.dart' as domain_execution_test;
import 'domain_server_test.dart' as domain_server_test;
import 'edit/test_all.dart' as edit_all;
import 'operation/test_all.dart' as operation_test_all;
import 'plugin/test_all.dart' as plugin_all;
import 'protocol_server_test.dart' as protocol_server_test;
import 'protocol_test.dart' as protocol_test;
import 'search/test_all.dart' as search_all;
import 'server_options_test.dart' as server_options;
import 'services/test_all.dart' as services_all;
import 'single_context_manager_test.dart' as single_context_manager_test;
import 'socket_server_test.dart' as socket_server_test;
import 'source/test_all.dart' as source_all;
import 'src/test_all.dart' as src_all;
import 'utils.dart';

/**
 * Utility for manually running all tests.
 */
main() {
  initializeTestEnvironment();
  group('analysis_server', () {
    analysis_all.main();
    analysis_server_test.main();
    channel_test.main();
    completion_test.main();
    context_manager_test.main();
    domain_analysis_test.main();
    domain_completion_test.main();
    domain_execution_test.main();
    domain_experimental_test.main();
    domain_server_test.main();
    edit_all.main();
    operation_test_all.main();
    plugin_all.main();
    protocol_server_test.main();
    protocol_test.main();
    search_all.main();
    server_options.main();
    services_all.main();
    single_context_manager_test.main();
    socket_server_test.main();
    source_all.main();
    src_all.main();
  });
}
