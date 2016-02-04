// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Meta-test that runs all tests we have written.
library dev_compiler.test.all_tests;

import 'package:test/test.dart';

import 'closure/closure_annotation_test.dart' as closure_annotation_test;
import 'closure/closure_type_test.dart' as closure_type_test;
import 'codegen_test.dart' as codegen_test;
import 'js/builder_test.dart' as builder_test;
import 'end_to_end_test.dart' as e2e;
import 'report_test.dart' as report_test;
import 'dependency_graph_test.dart' as dependency_graph_test;
import 'transformer_test.dart' as transformer_test;
import 'utils_test.dart' as utils_test;

void main() {
  group('end-to-end', e2e.main);
  group('report', report_test.main);
  group('dependency_graph', dependency_graph_test.main);
  group('codegen', () => codegen_test.main([]));
  group('transformer', transformer_test.main);
  group('closure', () {
    closure_annotation_test.main();
    closure_type_test.main();
  });
  group('js', builder_test.main);
  group('utils', utils_test.main);
}
