// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'apply_code_action_test.dart' as apply_code_action;
import 'call_hierarchy_test.dart' as call_hierarchy;
import 'code_action_assists_test.dart' as code_action_assists;
import 'code_action_fixes_test.dart' as code_action_fixes;
import 'code_action_refactors_test.dart' as code_action_refactors;
import 'code_action_source_test.dart' as code_action_source;
import 'document_color_test.dart' as document_color;
import 'document_highlights_test.dart' as document_highlights;
import 'document_symbols_test.dart' as document_symbols;
import 'edit_argument_test.dart' as edit_argument;
import 'editable_arguments_test.dart' as editable_arguments;
import 'execute_command_test.dart' as execute_command;
import 'format_test.dart' as format;
import 'hover_test.dart' as hover;
import 'implementation_test.dart' as implementation;
import 'signature_help_test.dart' as signature_help;
import 'type_definition_test.dart' as type_definition;
import 'type_hierarchy_test.dart' as type_hierarchy;
import 'will_rename_files_test.dart' as will_rename_files;
import 'workspace_apply_edit_test.dart' as workspace_apply_edit;
import 'workspace_symbols_test.dart' as workspace_symbols;

void main() {
  defineReflectiveSuite(() {
    apply_code_action.main();
    call_hierarchy.main();
    code_action_assists.main();
    code_action_fixes.main();
    code_action_refactors.main();
    code_action_source.main();
    document_color.main;
    document_highlights.main();
    document_symbols.main();
    edit_argument.main();
    editable_arguments.main();
    execute_command.main();
    format.main();
    hover.main();
    implementation.main();
    signature_help.main();
    type_definition.main();
    type_hierarchy.main();
    will_rename_files.main();
    workspace_apply_edit.main();
    workspace_symbols.main();
  }, name: 'lsp_over_legacy');
}
