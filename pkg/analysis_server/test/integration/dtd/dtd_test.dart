// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../shared/shared_dtd_tests.dart';
import '../lsp/abstract_lsp_over_legacy.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DtdTest);
  });
}

@reflectiveTest
class DtdTest
    // This test uses the LspOverLegacy base as it uses an LSP request to tell
    // the server to connect DTD, however these tests themselves are verifying
    // the servers integration with DTD.
    extends AbstractLspOverLegacyTest
    // Test implementations come from this mixin because they
    // are shared with the legacy server integration tests.
    with
        SharedDtdTests {
  @override
  void createFile(String path, String content) {
    newFile(path, content);
  }

  @override
  Future<void> initializeServer() async {
    await standardAnalysisSetup();
    await analysisFinished;
  }

  @override
  Future<void> setUp() async {
    await super.setUp();
    await setUpDtd();
  }

  @override
  Future<void> shutdownServer() async {
    await shutdownIfNeeded();
    // If tests call shutdownServer, we should skip it during teardown.
    skipShutdown = true;
  }

  @override
  Future<void> tearDown() async {
    await tearDownDtd();
    await super.tearDown();
  }
}
