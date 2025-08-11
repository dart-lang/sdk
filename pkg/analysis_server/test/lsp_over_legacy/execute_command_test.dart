// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'abstract_lsp_over_legacy.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExecuteCommandTest);
  });
}

@reflectiveTest
class ExecuteCommandTest extends LspOverLegacyTest {
  Future<void> test_logAction() async {
    var testActionName = 'test.action';

    await waitForTasksFinished();
    await executeCommand(
      Command(
        title: 'Log Action',
        command: Commands.logAction,
        arguments: [
          {'action': testActionName},
        ],
      ),
    );

    expect(
      server.analyticsManager
          .getRequestData(Method.workspace_executeCommand.toString())
          .additionalEnumCounts['command']!
          .keys,
      contains(testActionName),
    );
  }
}
