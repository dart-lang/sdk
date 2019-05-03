// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../src/lsp/lsp_packet_transformer_test.dart' as lsp_packet_transformer;
import 'change_workspace_folders_test.dart' as change_workspace_folders;
import 'code_actions_assists_test.dart' as code_actions_assists;
import 'code_actions_fixes_test.dart' as code_actions_fixes;
import 'code_actions_source_test.dart' as code_actions_source;
import 'completion_test.dart' as completion;
import 'definition_test.dart' as definition;
import 'diagnostic_test.dart' as diagnostic;
import 'document_highlights_test.dart' as document_highlights;
import 'document_symbols_test.dart' as document_symbols;
import 'file_modification_test.dart' as file_modification;
import 'folding_test.dart' as folding;
import 'format_test.dart' as format;
import 'hover_test.dart' as hover;
import 'initialization_test.dart' as initialization;
import 'priority_files_test.dart' as priority_files;
import 'references_test.dart' as references;
import 'rename_test.dart' as rename;
import 'server_test.dart' as server;
import 'signature_help_test.dart' as signature_help;
import 'workspace_symbols_test.dart' as workspace_symbols;

main() {
  defineReflectiveSuite(() {
    change_workspace_folders.main();
    code_actions_assists.main();
    code_actions_fixes.main();
    code_actions_source.main();
    completion.main();
    definition.main();
    diagnostic.main();
    document_highlights.main();
    document_symbols.main();
    file_modification.main();
    folding.main();
    format.main();
    lsp_packet_transformer.main();
    hover.main();
    initialization.main();
    priority_files.main();
    references.main();
    rename.main();
    server.main();
    signature_help.main();
    workspace_symbols.main();
  }, name: 'lsp');
}
