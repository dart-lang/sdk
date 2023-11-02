// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../tool/spec/check_all_test.dart' as check_spec;
import 'analysis/test_all.dart' as analysis;
import 'analysis_server_test.dart' as analysis_server;
import 'benchmarks_test.dart' as benchmarks;
import 'channel/test_all.dart' as channel;
import 'client/test_all.dart' as client;
import 'domain_analysis_test.dart' as domain_analysis;
import 'domain_completion_test.dart' as domain_completion;
import 'domain_diagnostic_test.dart' as domain_experimental;
import 'domain_execution_test.dart' as domain_execution;
import 'domain_server_test.dart' as domain_server;
import 'edit/test_all.dart' as edit;
import 'lsp/test_all.dart' as lsp;
import 'lsp_over_legacy/test_all.dart' as lsp_over_legacy;
import 'plugin/test_all.dart' as plugin;
import 'protocol_server_test.dart' as protocol_server;
import 'protocol_test.dart' as protocol;
import 'search/test_all.dart' as search;
import 'services/test_all.dart' as services;
import 'socket_server_test.dart' as socket_server;
import 'src/test_all.dart' as src;
import 'tool/test_all.dart' as tool;
import 'utilities/test_all.dart' as utilities;
import 'verify_error_fix_status_test.dart' as verify_error_fix_status;
import 'verify_no_solo_test.dart' as verify_no_solo;
import 'verify_no_utf8_encode_test.dart' as verify_no_utf8_encode;
import 'verify_sorted_test.dart' as verify_sorted;
import 'verify_tests_test.dart' as verify_tests;

void main() {
  defineReflectiveSuite(() {
    analysis.main();
    analysis_server.main();
    benchmarks.main();
    channel.main();
    client.main();
    domain_analysis.main();
    domain_completion.main();
    domain_execution.main();
    domain_experimental.main();
    domain_server.main();
    edit.main();
    lsp.main();
    lsp_over_legacy.main();
    plugin.main();
    protocol_server.main();
    protocol.main();
    search.main();
    services.main();
    socket_server.main();
    src.main();
    tool.main();
    utilities.main();
    verify_error_fix_status.main();
    verify_no_solo.main();
    verify_no_utf8_encode.main();
    verify_sorted.main();
    verify_tests.main();
    defineReflectiveSuite(() {
      defineReflectiveTests(SpecTest);
    }, name: 'spec');
  }, name: 'analysis_server');
}

@reflectiveTest
class SpecTest {
  void test_specHasBeenGenerated() async {
    await check_spec.main();
  }
}
