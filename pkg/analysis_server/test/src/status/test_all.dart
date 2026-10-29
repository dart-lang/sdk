// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'ast_page_test.dart' as ast_page;
import 'contexts_page_test.dart' as contexts_page;
import 'element_model_page_test.dart' as element_model_page;
import 'file_io_timing_page_test.dart' as file_io_timing_page;
import 'performance_page_test.dart' as performance_page;
import 'plugins_page_test.dart' as plugins_page;
import 'session_log_page_test.dart' as session_log_page;

void main() {
  defineReflectiveSuite(() {
    ast_page.main();
    contexts_page.main();
    element_model_page.main();
    file_io_timing_page.main();
    performance_page.main();
    plugins_page.main();
    session_log_page.main();
  }, name: 'status');
}
