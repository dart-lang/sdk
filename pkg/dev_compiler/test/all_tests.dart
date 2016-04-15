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
import 'worker/worker_test.dart' as worker_test;

void main() {
  group('codegen', () => codegen_test.main([]));
  group('closure', () {
    closure_annotation_test.main();
    closure_type_test.main();
  });
  group('js', builder_test.main);
  group('worker', worker_test.main);
}
