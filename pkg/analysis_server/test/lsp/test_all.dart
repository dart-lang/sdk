// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../src/lsp/lsp_packet_transformer_test.dart' as lsp_packet_transformer;
import 'analyzer_status_test.dart' as analyzer_status;
import 'cancel_request_test.dart' as cancel_request;
import 'change_workspace_folders_test.dart' as change_workspace_folders;
import 'closing_labels_test.dart' as closing_labels;
import 'code_actions_assists_test.dart' as code_actions_assists;
import 'code_actions_fixes_test.dart' as code_actions_fixes;
import 'code_actions_refactor_test.dart' as code_actions_refactor;
import 'code_actions_source_test.dart' as code_actions_source;
import 'completion_dart_test.dart' as completion_dart;
import 'completion_yaml_test.dart' as completion_yaml;
import 'configuration_test.dart' as configuration;
import 'definition_test.dart' as definition;
import 'diagnostic_test.dart' as diagnostic;
import 'document_changes_test.dart' as document_changes;
import 'document_highlights_test.dart' as document_highlights;
import 'document_symbols_test.dart' as document_symbols;
import 'file_modification_test.dart' as file_modification;
import 'flutter_outline_test.dart' as flutter_outline;
import 'folding_test.dart' as folding;
import 'format_test.dart' as format;
import 'hover_test.dart' as hover;
import 'implementation_test.dart' as implementation;
import 'initialization_test.dart' as initialization;
import 'mapping_test.dart' as mapping;
import 'outline_test.dart' as outline;
import 'priority_files_test.dart' as priority_files;
import 'reanalyze_test.dart' as reanalyze;
import 'references_test.dart' as references;
import 'rename_test.dart' as rename;
import 'semantic_tokens_test.dart' as semantic_tokens;
import 'server_test.dart' as server;
import 'signature_help_test.dart' as signature_help;
import 'super_test.dart' as get_super;
import 'will_rename_files_test.dart' as will_rename_files;
import 'workspace_symbols_test.dart' as workspace_symbols;

void main() {
  defineReflectiveSuite(() {
    analyzer_status.main();
    cancel_request.main();
    change_workspace_folders.main();
    closing_labels.main();
    code_actions_assists.main();
    code_actions_fixes.main();
    code_actions_source.main();
    code_actions_refactor.main();
    completion_dart.main();
    completion_yaml.main();
    configuration.main();
    definition.main();
    diagnostic.main();
    document_changes.main();
    document_highlights.main();
    document_symbols.main();
    file_modification.main();
    flutter_outline.main();
    folding.main();
    format.main();
    get_super.main();
    hover.main();
    implementation.main();
    initialization.main();
    lsp_packet_transformer.main();
    mapping.main();
    outline.main();
    priority_files.main();
    reanalyze.main();
    references.main();
    rename.main();
    semantic_tokens.main();
    server.main();
    signature_help.main();
    will_rename_files.main();
    workspace_symbols.main();
  }, name: 'lsp');
}
