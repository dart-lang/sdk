// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/lsp/extensions/code_action.dart';
import 'package:analyzer/src/test_utilities/test_code_format.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart' as plugin;
import 'package:analyzer_plugin/protocol/protocol_generated.dart' as plugin;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../lsp/code_actions_mixin.dart';
import '../lsp/server_abstract.dart';
import '../shared/shared_code_actions_assists_tests.dart';
import '../utils/test_code_extensions.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AssistsCodeActionsTest);
  });
}

@reflectiveTest
class AssistsCodeActionsTest extends AbstractLspAnalysisServerTest
    with
        LspSharedTestMixin,
        CodeActionsTestMixin,
        // Most tests are defined in a shared mixin.
        SharedAssistsCodeActionsTests {
  Future<void> test_plugin() async {
    failTestOnErrorDiagnostic = false;

    if (!AnalysisServer.supportsPlugins) return;
    // This code should get an assist to replace 'foo' with 'bar'.'
    const content = '''
[!foo!]
''';
    const expectedContent = '''
bar
''';

    var pluginResult = plugin.EditGetAssistsResult([
      plugin.PrioritizedSourceChange(
        0,
        plugin.SourceChange(
          "Change 'foo' to 'bar'",
          edits: [
            plugin.SourceFileEdit(
              testFilePath,
              0,
              edits: [plugin.SourceEdit(0, 3, 'bar')],
            ),
          ],
          id: 'fooToBar',
        ),
      ),
    ]);
    configureTestPlugin(
      handler:
          (request) =>
              request is plugin.EditGetAssistsParams ? pluginResult : null,
    );

    await verifyCodeActionLiteralEdits(
      content,
      expectedContent,
      kind: CodeActionKind('refactor.fooToBar'),
      title: "Change 'foo' to 'bar'",
      command: 'dart.logAction',
      commandArgs: [
        {'action': 'assist from plugin'},
      ],
    );
  }

  Future<void> test_plugin_sortsWithServer() async {
    setSupportedCodeActionKinds([CodeActionKind.Refactor]);

    if (!AnalysisServer.supportsPlugins) return;
    // Produces a server assist of "Convert to single quoted string" (with a
    // priority of 30).
    var code = TestCode.parse('import "[!dart:async!]";');

    // Provide two plugin results that should sort either side of the server assist.
    var pluginResult = plugin.EditGetAssistsResult([
      plugin.PrioritizedSourceChange(10, plugin.SourceChange('Low')),
      plugin.PrioritizedSourceChange(100, plugin.SourceChange('High')),
    ]);
    configureTestPlugin(
      handler:
          (request) =>
              request is plugin.EditGetAssistsParams ? pluginResult : null,
    );

    createFile(testFilePath, code.code);
    await initializeServer();

    var codeActions = await getCodeActions(
      testFileUri,
      range: code.range.range,
    );
    var codeActionTitles = codeActions.map((action) => action.title);

    expect(
      codeActionTitles,
      containsAllInOrder(['High', 'Convert to single quoted string', 'Low']),
    );
  }
}
