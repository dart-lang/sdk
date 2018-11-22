// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'completion_test.dart' as completion_test;
import 'definition_test.dart' as definition_test;
import 'diagnostic_test.dart' as diagnostic_test;
import 'file_modification_test.dart' as file_modification_test;
import 'format_test.dart' as format_test;
import 'hover_test.dart' as hover_test;
import 'initialization_test.dart' as initialization_test;
import 'references_test.dart' as references_test;
import 'server_test.dart' as server_test;
import 'signature_help_test.dart' as signature_help_test;

main() {
  defineReflectiveSuite(() {
    completion_test.main();
    definition_test.main();
    diagnostic_test.main();
    file_modification_test.main();
    format_test.main();
    hover_test.main();
    initialization_test.main();
    references_test.main();
    server_test.main();
    signature_help_test.main();
  }, name: 'lsp');
}
