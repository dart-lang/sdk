// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../shared/shared_editable_arguments_tests.dart';
import 'abstract_lsp_over_legacy.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(EditableArgumentsTest);
  });
}

@reflectiveTest
class EditableArgumentsTest extends SharedLspOverLegacyTest
    with
        // Tests are defined in SharedEditableArgumentsTests because they
        // are shared and run for both LSP and Legacy servers.
        SharedEditableArgumentsTests {
  @override
  Future<void> initializeServer() async {
    await waitForTasksFinished();
  }

  @override
  Future<void> setUp() async {
    await super.setUp();

    writeTestPackageConfig(flutter: true);
  }

  @override
  @FailingTest(reason: 'Document versions not currently supported for legacy')
  test_textDocument_closedFile() {
    // TODO(dantup): Implement support for version numbers in the legacy
    // protocol.
    return super.test_textDocument_closedFile();
  }

  @override
  @FailingTest(reason: 'Document versions not currently supported for legacy')
  test_textDocument_versions() {
    // TODO(dantup): Implement support for version numbers in the legacy
    // protocol.
    return super.test_textDocument_versions();
  }
}
