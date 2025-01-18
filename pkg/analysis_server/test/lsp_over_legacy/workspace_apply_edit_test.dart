// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../shared/shared_workspace_apply_edit_tests.dart';
import 'abstract_lsp_over_legacy.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(WorkspaceApplyEditTest);
  });
}

@reflectiveTest
class WorkspaceApplyEditTest extends SharedLspOverLegacyTest
    with
        // Tests are defined in SharedWorkspaceApplyEditTests because they
        // are shared and run for both LSP and Legacy servers.
        SharedWorkspaceApplyEditTests {
  @override
  Future<void> initializeServer() async {
    await super.initializeServer();
    await sendClientCapabilities();
  }

  @override
  Future<void> setUp() async {
    await super.setUp();
    setApplyEditSupport();
    setFileCreateSupport();
    setDocumentChangesSupport();
  }
}
