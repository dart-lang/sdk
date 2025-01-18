// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../shared/shared_edit_argument_tests.dart';
import 'abstract_lsp_over_legacy.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(EditArgumentTest);
  });
}

@reflectiveTest
class EditArgumentTest extends SharedLspOverLegacyTest
    with
        // Tests are defined in SharedEditArgumentTests because they
        // are shared and run for both LSP and Legacy servers.
        SharedEditArgumentTests {
  @override
  Future<void> setUp() async {
    await super.setUp();

    writeTestPackageConfig(flutter: true);
  }
}
