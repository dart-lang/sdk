// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'call_hierarchy_test.dart' as call_hierarchy;
import 'document_color_test.dart' as document_color;
import 'document_highlights_test.dart' as document_highlights;
import 'document_symbols_test.dart' as document_symbols;
import 'format_test.dart' as format;
import 'hover_test.dart' as hover;
import 'implementation_test.dart' as implementation;
import 'signature_help_test.dart' as signature_help;
import 'type_definition_test.dart' as type_definition;
import 'type_hierarchy_test.dart' as type_hierarchy;
import 'will_rename_files_test.dart' as will_rename_files;
import 'workspace_symbols_test.dart' as workspace_symbols;

void main() {
  defineReflectiveSuite(() {
    call_hierarchy.main();
    document_color.main;
    document_highlights.main();
    document_symbols.main();
    format.main();
    hover.main();
    implementation.main();
    signature_help.main();
    type_definition.main();
    type_hierarchy.main();
    will_rename_files.main();
    workspace_symbols.main();
  }, name: 'lsp_over_legacy');
}
