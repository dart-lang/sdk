// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/src/services/correction/assist_internal.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../shared/shared_apply_code_action_tests.dart';
import 'abstract_lsp_over_legacy.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ApplyCodeActionTest);
  });
}

@reflectiveTest
class ApplyCodeActionTest extends SharedLspOverLegacyTest
    with
        // Tests are defined in SharedApplyCodeActionTests.
        SharedApplyCodeActionTests {
  @override
  Future<void> initializeServer() async {
    await super.initializeServer();
    await sendClientCapabilities();
  }

  @override
  Future<void> setUp() async {
    await super.setUp();

    setApplyEditSupport();
    setDocumentChangesSupport();

    registerBuiltInAssistGenerators();
  }
}
