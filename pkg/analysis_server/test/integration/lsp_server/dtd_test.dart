// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../shared/shared_dtd_tests.dart';
import 'integration_tests.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DtdTest);
  });
}

@reflectiveTest
class DtdTest
        // This is an integration test that runs with an out-of-process server.
        // Because each test spawns a DTD instance and running this suite can be
        // slow we don't have an in-memory copy of these tests, but the base class
        // can temporarily be changed to `AbstractLspAnalysisServerTest` to run
        // with an in-process (analysis) server for easier debugging. DTD always
        // runs out-of-process.
        extends AbstractLspAnalysisServerIntegrationTest
        // Test implementations come from this mixin because they
        // are shared with the legacy server integration tests.
        with SharedDtdTests {
  @override
  String get testFile => mainFilePath;

  @override
  Uri get testFileUri => mainFileUri;

  @override
  void createFile(String path, String content) {
    newFile(path, content);
  }

  @override
  Future<void> initializeServer() async {
    await initialize();
  }

  @override
  Future<void> setUp() async {
    await super.setUp();
    await setUpDtd();
  }

  @override
  Future<void> shutdownServer() async {
    await sendShutdown();
  }

  @override
  Future<void> tearDown() async {
    await tearDownDtd();
    super.tearDown();
  }
}
