// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist_internal.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../shared/shared_apply_code_action_tests.dart';
import '../code_actions_mixin.dart';
import '../server_abstract.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ApplyCodeActionTest);
  });
}

@reflectiveTest
class ApplyCodeActionTest extends AbstractLspAnalysisServerTest
    with
        LspSharedTestMixin,
        CodeActionsTestMixin,
        // Tests are defined in SharedApplyCodeActionTests.
        SharedApplyCodeActionTests {
  @override
  void setUp() {
    super.setUp();

    setApplyEditSupport();
    setDocumentChangesSupport();

    registerBuiltInAssistGenerators();
  }
}
