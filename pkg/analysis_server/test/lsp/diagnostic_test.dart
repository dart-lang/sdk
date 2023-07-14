// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analyzer/src/test_utilities/package_config_file_builder.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart' as plugin;
import 'package:analyzer_plugin/protocol/protocol_generated.dart' as plugin;
import 'package:linter/src/rules.dart';
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
  Future<void> checkPluginErrorsForFile(String pluginAnalyzedFilePath) async {
    final pluginAnalyzedUri = pathContext.toUri(pluginAnalyzedFilePath);

    newFile(pluginAnalyzedFilePath, '''String a = "Test";
String b = "Test";
''');
    await initialize();

    final diagnosticsUpdate = waitForDiagnostics(pluginAnalyzedUri);
    final pluginError = plugin.AnalysisError(
      plugin.AnalysisErrorSeverity.ERROR,
      plugin.AnalysisErrorType.STATIC_TYPE_WARNING,
      plugin.Location(pluginAnalyzedFilePath, 0, 6, 1, 1,
          endLine: 1, endColumn: 7),
      'Test error from plugin',
      'ERR1',
      contextMessages: [
        plugin.DiagnosticMessage(
            'Related error',
            plugin.Location(pluginAnalyzedFilePath, 31, 4, 2, 13,
                endLine: 2, endColumn: 17))
      ],
    );
    final pluginResult =
        plugin.AnalysisErrorsParams(pluginAnalyzedFilePath, [pluginError]);
    configureTestPlugin(notification: pluginResult.toNotification());

    final diagnostics = await diagnosticsUpdate;
    expect(diagnostics, hasLength(1));

    final err = diagnostics!.first;
    expect(err.severity, DiagnosticSeverity.Error);
    expect(err.message, equals('Test error from plugin'));
    expect(err.code, equals('ERR1'));
    expect(err.range.start.line, equals(0));
    expect(err.range.start.character, equals(0));
    expect(err.range.end.line, equals(0));
    expect(err.range.end.character, equals(6));
    expect(err.relatedInformation, hasLength(1));

    final related = err.relatedInformation![0];
    expect(related.message, equals('Related error'));
    expect(related.location.range.start.line, equals(1));
    expect(related.location.range.start.character, equals(12));
    expect(related.location.range.end.line, equals(1));
    expect(related.location.range.end.character, equals(16));
  }

  Future<void> test_afterDocumentEdits() async {
    const initialContents = 'int a = 1;';
    newFile(mainFilePath, initialContents);

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
    newFile(analysisOptionsPath, '''
linter:
  rules:
    - invalid_lint_rule_name
''');

    final firstDiagnosticsUpdate = waitForDiagnostics(analysisOptionsUri);
    await initialize();
    final initialDiagnostics = await firstDiagnosticsUpdate;
    expect(initialDiagnostics, hasLength(1));
    expect(initialDiagnostics!.first.severity, DiagnosticSeverity.Warning);
    expect(initialDiagnostics.first.code, 'undefined_lint_warning');
  }

  @FailingTest(issue: 'https://github.com/dart-lang/sdk/issues/43926')
  Future<void> test_analysisOptionsFile_packageInclude() async {
    newFile(analysisOptionsPath, '''
include: package:pedantic/analysis_options.yaml
''');

    // Verify there's an error for the import.
    final firstDiagnosticsUpdate = waitForDiagnostics(analysisOptionsUri);
    await initialize();
    final initialDiagnostics = await firstDiagnosticsUpdate;
    expect(initialDiagnostics, hasLength(1));
    expect(initialDiagnostics!.first.severity, DiagnosticSeverity.Warning);
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
    newFile(mainFilePath, '''
void f() {
  x = 0;
  int? x;
  print(x);
}
''');

    final diagnosticsUpdate = waitForDiagnostics(mainFileUri);
    await initialize();
    final diagnostics = await diagnosticsUpdate;
    expect(diagnostics, hasLength(1));
    final diagnostic = diagnostics!.first;
    expect(diagnostic.relatedInformation, hasLength(1));
  }

  Future<void> test_correction() async {
    newFile(mainFilePath, '''
void f() {
  x = 0;
}
''');

    final diagnosticsUpdate = waitForDiagnostics(mainFileUri);
    await initialize();
    final diagnostics = await diagnosticsUpdate;
    expect(diagnostics, hasLength(1));
    final diagnostic = diagnostics!.first;
    expect(diagnostic.message, contains('\nTry'));
  }

  Future<void> test_deletedFile() async {
    newFile(mainFilePath, 'String a = 1;');

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
    var onePackagePath = convertPath('/home/one');
    writePackageConfig(
      projectFolderPath,
      config: PackageConfigFileBuilder()
        ..add(name: 'one', rootPath: onePackagePath),
    );
    newFile(convertPath('$onePackagePath/lib/one.dart'), '''
    @deprecated
    int? dep;
    ''');
    newFile(mainFilePath, r'''
    import 'package:one/one.dart';
    void f() => print(dep);
    ''');

    final diagnosticsUpdate = waitForDiagnostics(mainFileUri);
    await initialize(
        textDocumentCapabilities: withDiagnosticTagSupport(
            emptyTextDocumentClientCapabilities, [DiagnosticTag.Deprecated]));
    final diagnostics = await diagnosticsUpdate;
    expect(diagnostics, hasLength(1));
    final diagnostic = diagnostics!.first;
    expect(diagnostic.code, equals('deprecated_member_use'));
    expect(diagnostic.tags, contains(DiagnosticTag.Deprecated));
  }

  Future<void> test_diagnosticTag_notSupported() async {
    var onePackagePath = convertPath('/home/one');
    writePackageConfig(
      projectFolderPath,
      config: PackageConfigFileBuilder()
        ..add(name: 'one', rootPath: onePackagePath),
    );
    newFile(convertPath('$onePackagePath/lib/one.dart'), '''
    @deprecated
    int? dep;
    ''');
    newFile(mainFilePath, r'''
    import 'package:one/one.dart';
    void f() => print(dep);
    ''');

    final diagnosticsUpdate = waitForDiagnostics(mainFileUri);
    await initialize();
    final diagnostics = await diagnosticsUpdate;
    expect(diagnostics, hasLength(1));
    final diagnostic = diagnostics!.first;
    expect(diagnostic.code, equals('deprecated_member_use'));
    expect(diagnostic.tags, isNull);
  }

  Future<void> test_diagnosticTag_unnecessary() async {
    newFile(mainFilePath, '''
    void f() {
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
    final diagnostic = diagnostics!.first;
    expect(diagnostic.code, equals('dead_code'));
    expect(diagnostic.tags, contains(DiagnosticTag.Unnecessary));
  }

  Future<void> test_documentationUrl() async {
    newFile(mainFilePath, '''
    // ignore: unused_import
    import 'dart:async' as import; // produces BUILT_IN_IDENTIFIER_IN_DECLARATION
    ''');

    final diagnosticsUpdate = waitForDiagnostics(mainFileUri);
    await initialize(
        textDocumentCapabilities: withDiagnosticCodeDescriptionSupport(
            emptyTextDocumentClientCapabilities));
    final diagnostics = await diagnosticsUpdate;
    expect(diagnostics, hasLength(1));
    final diagnostic = diagnostics!.first;
    expect(diagnostic.code, equals('built_in_identifier_in_declaration'));
    expect(
      diagnostic.codeDescription!.href,
      equals(Uri.parse(
          'https://dart.dev/diagnostics/built_in_identifier_in_declaration')),
    );
  }

  Future<void> test_documentationUrl_notSupported() async {
    newFile(mainFilePath, '''
    // ignore: unused_import
    import 'dart:async' as import; // produces BUILT_IN_IDENTIFIER_IN_DECLARATION
    ''');

    final diagnosticsUpdate = waitForDiagnostics(mainFileUri);
    await initialize();
    final diagnostics = await diagnosticsUpdate;
    expect(diagnostics, hasLength(1));
    final diagnostic = diagnostics!.first;
    expect(diagnostic.code, equals('built_in_identifier_in_declaration'));
    expect(diagnostic.codeDescription, isNull);
  }

  Future<void> test_dotFilesExcluded() async {
    var dotFolderFilePath =
        join(projectFolderPath, '.dart_tool', 'tool_file.dart');
    var dotFolderFileUri = pathContext.toUri(dotFolderFilePath);

    newFile(dotFolderFilePath, 'String a = 1;');

    List<Diagnostic>? diagnostics;
    // Record if diagnostics are received, but since we don't expect them
    // don't await them.
    unawaited(
        waitForDiagnostics(dotFolderFileUri).then((d) => diagnostics = d));

    // Send a request for a hover.
    await initialize();
    await getHover(dotFolderFileUri, Position(line: 0, character: 0));
    await pumpEventQueue(times: 5000);

    // Ensure that as part of responding to getHover, diagnostics were not
    // transmitted.
    expect(diagnostics, isNull);
  }

  Future<void> test_fixDataFile() async {
    var fixDataPath = join(projectFolderPath, 'lib', 'fix_data.yaml');
    var fixDataUri = pathContext.toUri(fixDataPath);
    newFile(fixDataPath, '''
version: latest
''').path;

    final firstDiagnosticsUpdate = waitForDiagnostics(fixDataUri);
    await initialize();
    final initialDiagnostics = await firstDiagnosticsUpdate;
    expect(initialDiagnostics, hasLength(1));
    expect(initialDiagnostics!.first.severity, DiagnosticSeverity.Error);
    expect(initialDiagnostics.first.code, 'invalid_value');
  }

  Future<void> test_fromPlugins_dartFile() async {
    await checkPluginErrorsForFile(mainFilePath);
  }

  Future<void> test_fromPlugins_dartFile_combined() async {
    // Check that if code has both a plugin and a server error, that when the
    // plugin produces an error, it comes through _with_ the server-produced
    // error.
    // https://github.com/dart-lang/sdk/issues/45678
    //
    final serverErrorMessage =
        "A value of type 'int' can't be assigned to a variable of type 'String'";
    final pluginErrorMessage = 'Test error from plugin';

    newFile(mainFilePath, 'String a = 1;');
    final initialDiagnosticsFuture = waitForDiagnostics(mainFileUri);
    await initialize();
    final initialDiagnostics = await initialDiagnosticsFuture;
    expect(initialDiagnostics, hasLength(1));
    expect(initialDiagnostics!.first.message, contains(serverErrorMessage));

    final pluginTriggeredDiagnosticFuture = waitForDiagnostics(mainFileUri);
    final pluginError = plugin.AnalysisError(
      plugin.AnalysisErrorSeverity.ERROR,
      plugin.AnalysisErrorType.STATIC_TYPE_WARNING,
      plugin.Location(mainFilePath, 0, 1, 0, 0, endLine: 0, endColumn: 1),
      pluginErrorMessage,
      'ERR1',
    );
    final pluginResult =
        plugin.AnalysisErrorsParams(mainFilePath, [pluginError]);
    configureTestPlugin(notification: pluginResult.toNotification());

    final pluginTriggeredDiagnostics = await pluginTriggeredDiagnosticFuture;
    expect(
        pluginTriggeredDiagnostics!.map((error) => error.message),
        containsAll([
          pluginErrorMessage,
          contains(serverErrorMessage),
        ]));
  }

  Future<void> test_fromPlugins_nonDartFile() async {
    await checkPluginErrorsForFile(join(projectFolderPath, 'lib', 'foo.sql'));
  }

  Future<void> test_initialAnalysis() async {
    newFile(mainFilePath, 'String a = 1;');

    final diagnosticsUpdate = waitForDiagnostics(mainFileUri);
    await initialize();
    final diagnostics = await diagnosticsUpdate;
    expect(diagnostics, hasLength(1));
    final diagnostic = diagnostics!.first;
    expect(diagnostic.code, equals('invalid_assignment'));
    expect(diagnostic.range.start.line, equals(0));
    expect(diagnostic.range.start.character, equals(11));
    expect(diagnostic.range.end.line, equals(0));
    expect(diagnostic.range.end.character, equals(12));
  }

  Future<void> test_looseFile_withoutPubpsec() async {
    await initialize(allowEmptyRootUri: true);

    // Opening the file should trigger diagnostics.
    {
      final diagnosticsUpdate = waitForDiagnostics(mainFileUri);
      await openFile(mainFileUri, 'final a = Bad();');
      final diagnostics = await diagnosticsUpdate;
      expect(diagnostics, hasLength(1));
      final diagnostic = diagnostics!.first;
      expect(diagnostic.message, contains("The function 'Bad' isn't defined"));
    }

    // Closing the file should remove the diagnostics.
    {
      final diagnosticsUpdate = waitForDiagnostics(mainFileUri);
      await closeFile(mainFileUri);
      final diagnostics = await diagnosticsUpdate;
      expect(diagnostics, hasLength(0));
    }
  }

  /// Tests that diagnostic ordering is stable when minor changes are made to
  /// the file that does not alter the diagnostics besides extending their
  /// range and adding to their messages.
  ///
  /// https://github.com/Dart-Code/Dart-Code/issues/3934
  Future<void> test_stableOrder() async {
    /// Helper to pad out the content in a way that has previously triggered
    /// this issue.
    String wrappedContent(String content) => '''
//
//
//
//

void f() {
  $content
}
''';

    registerLintRules();
    newFile(analysisOptionsPath, '''
linter:
  rules:
    - prefer_typing_uninitialized_variables

analyzer:
  language:
    strict-inference: true
    ''');

    newFile(mainFilePath, '');
    await initialize();
    await openFile(mainFileUri, '');

    // Collect the initial set of diagnostic to compare against.
    var docVersion = 1;
    final originalDiagnosticsUpdate = waitForDiagnostics(mainFileUri);
    await replaceFile(docVersion++, mainFileUri, wrappedContent('final bar;'));
    final originalDiagnostics = await originalDiagnosticsUpdate;

    // Helper to update the content and verify the same diagnostics are returned
    // in the same order, despite the changes to offset/message altering
    // hashcodes.
    Future<void> verifyDiagnostics(String content) async {
      final diagnosticsUpdate = waitForDiagnostics(mainFileUri);
      await replaceFile(docVersion++, mainFileUri, wrappedContent(content));
      final diagnostics = await diagnosticsUpdate;
      expect(
        diagnostics!.map((d) => d.code),
        originalDiagnostics!.map((d) => d.code),
      );
    }

    // These changes do not affect the errors being produced (besides offset/
    // message text) but will cause hashcode changes that previously altered the
    // returned order.
    await verifyDiagnostics('final dbar;');
    await verifyDiagnostics('final dybar;');
    await verifyDiagnostics('final dynbar;');
    await verifyDiagnostics('final dynabar;');
    await verifyDiagnostics('final dynambar;');
    await verifyDiagnostics('final dynamibar;');
    await verifyDiagnostics('final dynamicbar;');
  }

  Future<void> test_todos_asWarnings() async {
    newFile(analysisOptionsPath, '''
analyzer:
  errors:
    # Increase the severity of TODOs.
    todo: warning
    fixme: warning
''');

    const contents = '''
    // TODO: This
    // FIXME: This
    String a = "";
    ''';
    newFile(mainFilePath, contents);

    final firstDiagnosticsUpdate = waitForDiagnostics(mainFileUri);
    // Don't set showTodos in config, because they should show even without this
    // setting if they are upgraded to warnings/errors.
    await initialize();
    final initialDiagnostics = await firstDiagnosticsUpdate;
    expect(initialDiagnostics, hasLength(2));
    expect(initialDiagnostics!.map((d) => d.code).toSet(), {'todo', 'fixme'});
  }

  Future<void> test_todos_boolean() async {
    // TODOs only show up if there's also some code in the file.
    const contents = '''
    // TODO: This
    // FIXME: This
    String a = "";
    ''';
    newFile(mainFilePath, contents);

    final firstDiagnosticsUpdate = waitForDiagnostics(mainFileUri);
    await provideConfig(
      () => initialize(
          workspaceCapabilities:
              withConfigurationSupport(emptyWorkspaceClientCapabilities)),
      {'showTodos': true},
    );
    final initialDiagnostics = await firstDiagnosticsUpdate;
    expect(initialDiagnostics, hasLength(2));
  }

  Future<void> test_todos_disabled() async {
    const contents = '''
    // TODO: This
    String a = "";
    ''';
    newFile(mainFilePath, contents);

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

    // Capture any diagnostic updates. We might get multiple, because during
    // a reanalyze, all diagnostics are flushed (to empty) and then analysis
    // occurs.
    Map<String, List<Diagnostic>> latestDiagnostics = {};
    trackDiagnostics(latestDiagnostics);

    final nextAnalysis = waitForAnalysisComplete();
    await updateConfig({'showTodos': true});
    await nextAnalysis;
    expect(latestDiagnostics[mainFilePath], hasLength(1));
  }

  Future<void> test_todos_specific() async {
    // TODOs only show up if there's also some code in the file.
    const contents = '''
    // TODO: This
    // HACK: This
    // FIXME: This
    String a = "";
    ''';
    newFile(mainFilePath, contents);

    final firstDiagnosticsUpdate = waitForDiagnostics(mainFileUri);
    await provideConfig(
      () => initialize(
          workspaceCapabilities:
              withConfigurationSupport(emptyWorkspaceClientCapabilities)),
      {
        // Include both casings, since this comes from the user we should handle
        // either.
        'showTodos': ['TODO', 'fixme']
      },
    );
    final initialDiagnostics = (await firstDiagnosticsUpdate)!;
    expect(initialDiagnostics, hasLength(2));
    expect(
      initialDiagnostics.map((e) => e.code!),
      containsAll(['todo', 'fixme']),
    );
  }
}
