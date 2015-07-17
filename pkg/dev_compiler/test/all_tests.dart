// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Meta-test that runs all tests we have written.
library dev_compiler.test.all_tests;

import 'package:test/test.dart';

import 'checker/checker_test.dart' as checker_test;
import 'checker/inferred_type_test.dart' as inferred_type_test;
import 'checker/self_host_test.dart' as self_host;
import 'codegen_test.dart' as codegen_test;
import 'end_to_end_test.dart' as e2e;
import 'report_test.dart' as report_test;
import 'dependency_graph_test.dart' as dependency_graph_test;

void main() {
  group('end-to-end', e2e.main);
  group('inferred types', inferred_type_test.main);
  group('checker', checker_test.main);
  group('report', report_test.main);
  group('dependency_graph', dependency_graph_test.main);
  group('codegen', () => codegen_test.main([]));
  group('self_host', self_host.main);
}
