// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../shared/shared_workspace_apply_edit_tests.dart';
import 'server_abstract.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(WorkspaceApplyEditTest);
  });
}

@reflectiveTest
class WorkspaceApplyEditTest extends AbstractLspAnalysisServerTest
    with
        LspSharedTestMixin,
        // Tests are defined in SharedWorkspaceApplyEditTests because they
        // are shared and run for both LSP and Legacy servers.
        SharedWorkspaceApplyEditTests {}
