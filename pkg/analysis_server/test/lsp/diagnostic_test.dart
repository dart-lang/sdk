// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart' as plugin;
import 'package:analyzer_plugin/protocol/protocol_generated.dart' as plugin;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'server_abstract.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DiagnosticTest);
  });
}

@reflectiveTest
class DiagnosticTest extends AbstractLspAnalysisServerTest {
  Folder pedanticLibFolder;

  Future<void> checkPluginErrorsForFile(String pluginAnalyzedFilePath) async {
    final pluginAnalyzedUri = Uri.file(pluginAnalyzedFilePath);

    newFile(pluginAnalyzedFilePath, content: '''String a = "Test";
String b = "Test";
''');
    await initialize();

    final diagnosticsUpdate = waitForDiagnostics(pluginAnalyzedUri);
    final pluginError = plugin.AnalysisError(
      plugin.AnalysisErrorSeverity.ERROR,
      plugin.AnalysisErrorType.STATIC_TYPE_WARNING,
      plugin.Location(pluginAnalyzedFilePath, 0, 6, 0, 0),
      'Test error from plugin',
      'ERR1',
      contextMessages: [
        plugin.DiagnosticMessage('Related error',
            plugin.Location(pluginAnalyzedFilePath, 31, 4, 1, 12))
      ],
    );
    final pluginResult =
        plugin.AnalysisErrorsParams(pluginAnalyzedFilePath, [pluginError]);
    configureTestPlugin(notification: pluginResult.toNotification());

    final diagnostics = await diagnosticsUpdate;
    expect(diagnostics, hasLength(1));

    final err = diagnostics.first;
    expect(err.severity, DiagnosticSeverity.Error);
    expect(err.message, equals('Test error from plugin'));
    expect(err.code, equals('ERR1'));
    expect(err.range.start.line, equals(0));
    expect(err.range.start.character, equals(0));
    expect(err.range.end.line, equals(0));
    expect(err.range.end.character, equals(6));
    expect(err.relatedInformation, hasLength(1));

    final related = err.relatedInformation[0];
    expect(related.message, equals('Related error'));
    expect(related.location.range.start.line, equals(1));
    expect(related.location.range.start.character, equals(12));
    expect(related.location.range.end.line, equals(1));
    expect(related.location.range.end.character, equals(16));
  }

  Future<void> test_afterDocumentEdits() async {
    const initialContents = 'int a = 1;';
    newFile(mainFilePath, content: initialContents);

    final firstDiagnosticsUpdate = waitForDiagnostics(mainFileUri);
    await initialize();
    final initialDiagnostics = await firstDiagnosticsUpdate;
    expect(initialDiagnostics, hasLength(0));

    await openFile(mainFileUri, initialContents);

    final secondDiagnosticsUpdate = waitForDiagnostics(mainFileUri);
    await replaceFile(222, mainFileUri, 'String a = 1;');
    final updatedDiagnostics = await secondDiagnosticsUpdate;
    expect(updatedDiagnostics, hasLength(1));
  }

  Future<void> test_analysisOptionsFile() async {
    newFile(analysisOptionsPath, content: '''
linter:
  rules:
    - invalid_lint_rule_name
''').path;

    final firstDiagnosticsUpdate = waitForDiagnostics(analysisOptionsUri);
    await initialize();
    final initialDiagnostics = await firstDiagnosticsUpdate;
    expect(initialDiagnostics, hasLength(1));
    expect(initialDiagnostics.first.severity, DiagnosticSeverity.Warning);
    expect(initialDiagnostics.first.code, 'undefined_lint_warning');
  }

  @FailingTest(issue: 'https://github.com/dart-lang/sdk/issues/43926')
  Future<void> test_analysisOptionsFile_packageInclude() async {
    newFile(analysisOptionsPath, content: '''
include: package:pedantic/analysis_options.yaml
''').path;

    // Verify there's an error for the import.
    final firstDiagnosticsUpdate = waitForDiagnostics(analysisOptionsUri);
    await initialize();
    final initialDiagnostics = await firstDiagnosticsUpdate;
    expect(initialDiagnostics, hasLength(1));
    expect(initialDiagnostics.first.severity, DiagnosticSeverity.Warning);
    expect(initialDiagnostics.first.code, 'include_file_not_found');

    // TODO(scheglov) The server does not handle the file change.
    throw 'Times out';

    // // Write a package file that allows resolving the include.
    // final secondDiagnosticsUpdate = waitForDiagnostics(analysisOptionsUri);
    // writePackageConfig(projectFolderPath, pedantic: true);
    //
    // // Ensure the error disappeared.
    // final updatedDiagnostics = await secondDiagnosticsUpdate;
    // expect(updatedDiagnostics, hasLength(0));
  }

  Future<void> test_contextMessage() async {
    newFile(mainFilePath, content: '''
void f() {
  x = 0;
  int x;
  print(x);
}
''');

    final diagnosticsUpdate = waitForDiagnostics(mainFileUri);
    await initialize();
    final diagnostics = await diagnosticsUpdate;
    expect(diagnostics, hasLength(1));
    final diagnostic = diagnostics.first;
    expect(diagnostic.relatedInformation, hasLength(1));
  }

  Future<void> test_correction() async {
    newFile(mainFilePath, content: '''
void f() {
  x = 0;
}
''');

    final diagnosticsUpdate = waitForDiagnostics(mainFileUri);
    await initialize();
    final diagnostics = await diagnosticsUpdate;
    expect(diagnostics, hasLength(1));
    final diagnostic = diagnostics.first;
    expect(diagnostic.message, contains('\nTry'));
  }

  Future<void> test_deletedFile() async {
    newFile(mainFilePath, content: 'String a = 1;');

    final firstDiagnosticsUpdate = waitForDiagnostics(mainFileUri);
    await initialize();
    final originalDiagnostics = await firstDiagnosticsUpdate;
    expect(originalDiagnostics, hasLength(1));

    // Deleting the file should result in an update to remove the diagnostics.
    final secondDiagnosticsUpdate = waitForDiagnostics(mainFileUri);
    deleteFile(mainFilePath);
    final updatedDiagnostics = await secondDiagnosticsUpdate;
    expect(updatedDiagnostics, hasLength(0));
  }

  Future<void> test_diagnosticTag_deprecated() async {
    newFile(mainFilePath, content: '''
    @deprecated
    int dep;

    void main() => print(dep);
    ''');

    final diagnosticsUpdate = waitForDiagnostics(mainFileUri);
    await initialize(
        textDocumentCapabilities: withDiagnosticTagSupport(
            emptyTextDocumentClientCapabilities, [DiagnosticTag.Deprecated]));
    final diagnostics = await diagnosticsUpdate;
    expect(diagnostics, hasLength(1));
    final diagnostic = diagnostics.first;
    expect(diagnostic.code, equals('deprecated_member_use_from_same_package'));
    expect(diagnostic.tags, contains(DiagnosticTag.Deprecated));
  }

  Future<void> test_diagnosticTag_notSupported() async {
    newFile(mainFilePath, content: '''
    @deprecated
    int dep;

    void main() => print(dep);
    ''');

    final diagnosticsUpdate = waitForDiagnostics(mainFileUri);
    await initialize();
    final diagnostics = await diagnosticsUpdate;
    expect(diagnostics, hasLength(1));
    final diagnostic = diagnostics.first;
    expect(diagnostic.code, equals('deprecated_member_use_from_same_package'));
    expect(diagnostic.tags, isNull);
  }

  Future<void> test_diagnosticTag_unnecessary() async {
    newFile(mainFilePath, content: '''
    void main() {
      return;
      print('unreachable');
    }
    ''');

    final diagnosticsUpdate = waitForDiagnostics(mainFileUri);
    await initialize(
        textDocumentCapabilities: withDiagnosticTagSupport(
            emptyTextDocumentClientCapabilities, [DiagnosticTag.Unnecessary]));
    final diagnostics = await diagnosticsUpdate;
    expect(diagnostics, hasLength(1));
    final diagnostic = diagnostics.first;
    expect(diagnostic.code, equals('dead_code'));
    expect(diagnostic.tags, contains(DiagnosticTag.Unnecessary));
  }

  Future<void> test_dotFilesExcluded() async {
    var dotFolderFilePath =
        join(projectFolderPath, '.dart_tool', 'tool_file.dart');
    var dotFolderFileUri = Uri.file(dotFolderFilePath);

    newFile(dotFolderFilePath, content: 'String a = 1;');

    List<Diagnostic> diagnostics;
    waitForDiagnostics(dotFolderFileUri).then((d) => diagnostics = d);

    // Send a request for a hover.
    await initialize();
    await getHover(dotFolderFileUri, Position(line: 0, character: 0));

    // Ensure that as part of responding to getHover, diagnostics were not
    // transmitted.
    expect(diagnostics, isNull);
  }

  Future<void> test_fixDataFile() async {
    var fixDataPath = join(projectFolderPath, 'lib', 'fix_data.yaml');
    var fixDataUri = Uri.file(fixDataPath);
    newFile(fixDataPath, content: '''
version: latest
''').path;

    final firstDiagnosticsUpdate = waitForDiagnostics(fixDataUri);
    await initialize();
    final initialDiagnostics = await firstDiagnosticsUpdate;
    expect(initialDiagnostics, hasLength(1));
    expect(initialDiagnostics.first.severity, DiagnosticSeverity.Error);
    expect(initialDiagnostics.first.code, 'invalid_value');
  }

  Future<void> test_fromPlugins_dartFile() async {
    await checkPluginErrorsForFile(mainFilePath);
  }

  Future<void> test_fromPlugins_nonDartFile() async {
    await checkPluginErrorsForFile(join(projectFolderPath, 'lib', 'foo.sql'));
  }

  Future<void> test_initialAnalysis() async {
    newFile(mainFilePath, content: 'String a = 1;');

    final diagnosticsUpdate = waitForDiagnostics(mainFileUri);
    await initialize();
    final diagnostics = await diagnosticsUpdate;
    expect(diagnostics, hasLength(1));
    final diagnostic = diagnostics.first;
    expect(diagnostic.code, equals('invalid_assignment'));
    expect(diagnostic.range.start.line, equals(0));
    expect(diagnostic.range.start.character, equals(11));
    expect(diagnostic.range.end.line, equals(0));
    expect(diagnostic.range.end.character, equals(12));
  }

  Future<void> test_todos() async {
    // TODOs only show up if there's also some code in the file.
    const contents = '''
    // TODO: This
    String a = "";
    ''';
    newFile(mainFilePath, content: contents);

    final firstDiagnosticsUpdate = waitForDiagnostics(mainFileUri);
    await provideConfig(
      () => initialize(
          workspaceCapabilities:
              withConfigurationSupport(emptyWorkspaceClientCapabilities)),
      {'showTodos': true},
    );
    final initialDiagnostics = await firstDiagnosticsUpdate;
    expect(initialDiagnostics, hasLength(1));
  }

  Future<void> test_todos_disabled() async {
    const contents = '''
    // TODO: This
    String a = "";
    ''';
    newFile(mainFilePath, content: contents);

    final firstDiagnosticsUpdate = waitForDiagnostics(mainFileUri);
    // TODOs are disabled by default so we don't need to send any config.
    await initialize();
    final initialDiagnostics = await firstDiagnosticsUpdate;
    expect(initialDiagnostics, hasLength(0));
  }

  Future<void> test_todos_enabledAfterAnalysis() async {
    const contents = '''
    // TODO: This
    String a = "";
    ''';

    final initialAnalysis = waitForAnalysisComplete();
    final firstDiagnosticsUpdate = waitForDiagnostics(mainFileUri);
    await provideConfig(
      () => initialize(
          workspaceCapabilities:
              withConfigurationSupport(emptyWorkspaceClientCapabilities)),
      {},
    );
    await openFile(mainFileUri, contents);
    final initialDiagnostics = await firstDiagnosticsUpdate;
    expect(initialDiagnostics, hasLength(0));

    // Ensure initial analysis completely finished before we continue.
    await initialAnalysis;

    // Enable showTodos and update the file to ensure TODOs now come through.
    final secondDiagnosticsUpdate = waitForDiagnostics(mainFileUri);
    await updateConfig({'showTodos': true});
    await replaceFile(222, mainFileUri, contents);
    final updatedDiagnostics = await secondDiagnosticsUpdate;
    expect(updatedDiagnostics, hasLength(1));
  }
}
