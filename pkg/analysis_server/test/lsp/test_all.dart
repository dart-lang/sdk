// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../src/lsp/lsp_packet_transformer_test.dart'
    as packet_transformer_tests;
import 'code_actions_assists_test.dart' as assists_code_action_tests;
import 'code_actions_fixes_test.dart' as fixes_code_action_tests;
import 'code_actions_source_test.dart' as source_code_action_tests;
import 'completion_test.dart' as completion_test;
import 'definition_test.dart' as definition_test;
import 'diagnostic_test.dart' as diagnostic_test;
import 'document_highlights_test.dart' as document_highlights_test;
import 'document_symbols_test.dart' as document_symbols_test;
import 'file_modification_test.dart' as file_modification_test;
import 'format_test.dart' as format_test;
import 'hover_test.dart' as hover_test;
import 'initialization_test.dart' as initialization_test;
import 'priority_files_test.dart' as priority_files_test;
import 'references_test.dart' as references_test;
import 'rename_test.dart' as rename_test;
import 'server_test.dart' as server_test;
import 'signature_help_test.dart' as signature_help_test;

main() {
  defineReflectiveSuite(() {
    completion_test.main();
    definition_test.main();
    diagnostic_test.main();
    document_symbols_test.main();
    document_highlights_test.main();
    file_modification_test.main();
    priority_files_test.main();
    format_test.main();
    hover_test.main();
    initialization_test.main();
    references_test.main();
    server_test.main();
    signature_help_test.main();
    source_code_action_tests.main();
    fixes_code_action_tests.main();
    assists_code_action_tests.main();
    packet_transformer_tests.main();
    rename_test.main();
  }, name: 'lsp');
}
