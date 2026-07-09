// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/lsp/extensions/code_action.dart';
import 'package:analyzer/src/test_utilities/test_code_format.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart' as plugin;
import 'package:analyzer_plugin/protocol/protocol_generated.dart' as plugin;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../shared/shared_code_actions_fixes_tests.dart';
import '../utils/test_code_extensions.dart';
import 'code_actions_mixin.dart';
import 'server_abstract.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FixesCodeActionsTest);
  });
}

@reflectiveTest
class FixesCodeActionsTest extends AbstractLspAnalysisServerTest
    with
        LspSharedTestMixin,
        CodeActionsTestMixin,
        // Most tests are defined in a shared mixin.
        SharedFixesCodeActionsTests {
  /// Helper to check plugin fixes for [filePath].
  ///
  /// Used to ensure that both Dart and non-Dart files fixes are returned.
  Future<void> checkPluginResults(String filePath) async {
    // TODO(dantup): Abstract plugin support to the shared test interface so
    //  that the plugin tests can also move to the shared mixins and run for
    //  both servers.

    // This code should get a fix to replace 'foo' with 'bar'.'
    const content = '''
[!foo!]
''';
    const expectedContent = '''
bar
''';

    var pluginResult = plugin.EditGetFixesResult([
      plugin.AnalysisErrorFixes(
        plugin.AnalysisError(
          plugin.AnalysisErrorSeverity.ERROR,
          plugin.AnalysisErrorType.HINT,
          plugin.Location(filePath, 0, 3, 0, 0),
          "Do not use 'foo'",
          'do_not_use_foo',
        ),
        fixes: [
          plugin.PrioritizedSourceChange(
            0,
            plugin.SourceChange(
              "Change 'foo' to 'bar'",
              edits: [
                plugin.SourceFileEdit(
                  filePath,
                  0,
                  edits: [plugin.SourceEdit(0, 3, 'bar')],
                ),
              ],
              id: 'fooToBar',
            ),
          ),
        ],
      ),
    ]);
    configureTestPlugin(
      handler: (request) =>
          request is plugin.EditGetFixesParams ? pluginResult : null,
    );

    await verifyCodeActionLiteralEdits(
      filePath: filePath,
      content,
      expectedContent,
      kind: CodeActionKind('quickfix.fooToBar'),
      title: "Change 'foo' to 'bar'",
      command: 'dart.logAction',
      commandArgs: [
        {'action': 'fix from plugin'},
      ],
    );
  }

  Future<void> test_plugin_dart() async {
    return await checkPluginResults(testFilePath);
  }

  Future<void> test_plugin_nonDart() async {
    return await checkPluginResults(join(projectFolderPath, 'lib', 'foo.foo'));
  }

  Future<void> test_plugin_sortsWithServer() async {
    // Produces a server fix for removing unused import with a default
    // priority of 50.
    var code = TestCode.parse('''
[!import!] 'dart:convert';
''');

    // Provide two plugin results that should sort either side of the server fix.
    var pluginResult = plugin.EditGetFixesResult([
      plugin.AnalysisErrorFixes(
        plugin.AnalysisError(
          plugin.AnalysisErrorSeverity.ERROR,
          plugin.AnalysisErrorType.HINT,
          plugin.Location(testFilePath, 0, 3, 0, 0),
          'Dummy error',
          'dummy',
        ),
        fixes: [
          plugin.PrioritizedSourceChange(10, plugin.SourceChange('Low')),
          plugin.PrioritizedSourceChange(100, plugin.SourceChange('High')),
        ],
      ),
    ]);
    configureTestPlugin(
      handler: (request) =>
          request is plugin.EditGetFixesParams ? pluginResult : null,
    );

    newFile(testFilePath, code.code);
    await initialize();

    var codeActions = await getCodeActions(
      testFileUri,
      range: code.range.range,
    );
    var codeActionTitles = codeActions.map((action) => action.title);

    expect(
      codeActionTitles,
      containsAllInOrder(['High', 'Remove unused import', 'Low']),
    );
  }
}
