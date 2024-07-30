// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analyzer/src/lint/registry.dart';
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

typedef _VoidCallback = Future<void> Function();

@reflectiveTest
class DiagnosticTest extends AbstractLspAnalysisServerTest {
  Future<void> checkPluginErrorsForFile(String pluginAnalyzedFilePath) async {
    var pluginAnalyzedUri = pathContext.toUri(pluginAnalyzedFilePath);

    newFile(pluginAnalyzedFilePath, '''String a = "Test";
String b = "Test";
''');
    await initialize();

    var diagnosticsUpdate = waitForDiagnostics(pluginAnalyzedUri);
    var pluginError = plugin.AnalysisError(
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
    var pluginResult =
        plugin.AnalysisErrorsParams(pluginAnalyzedFilePath, [pluginError]);
    configureTestPlugin(notification: pluginResult.toNotification());

    var diagnostics = await diagnosticsUpdate;
    expect(diagnostics, hasLength(1));

    var err = diagnostics!.first;
    expect(err.severity, DiagnosticSeverity.Error);
    expect(err.message, equals('Test error from plugin'));
    expect(err.code, equals('ERR1'));
    expect(err.range.start.line, equals(0));
    expect(err.range.start.character, equals(0));
    expect(err.range.end.line, equals(0));
    expect(err.range.end.character, equals(6));
    expect(err.relatedInformation, hasLength(1));

    var related = err.relatedInformation![0];
    expect(related.message, equals('Related error'));
    expect(related.location.range.start.line, equals(1));
    expect(related.location.range.start.character, equals(12));
    expect(related.location.range.end.line, equals(1));
    expect(related.location.range.end.character, equals(16));
  }

  @override
  void setUp() {
    super.setUp();

    if (Registry.ruleRegistry.isEmpty) {
      registerLintRules();
    }

    // These tests deliberately generate diagnostics.
    failTestOnErrorDiagnostic = false;
  }

  Future<void> test_afterDocumentEdits() async {
    const initialContents = 'int a = 1;';
    newFile(mainFilePath, initialContents);

    await initialize();
    await openFile(mainFileUri, initialContents);
    await pumpEventQueue(times: 5000);
    expect(diagnostics[mainFileUri], isNull);

    await replaceFile(222, mainFileUri, 'String a = 1;');
    await pumpEventQueue(times: 5000);
    expect(diagnostics[mainFileUri], isNotEmpty);
  }

  Future<void> test_analysisOptionsFile() async {
    newFile(analysisOptionsPath, '''
linter:
  rules:
    - invalid_lint_rule_name
''');

    var firstDiagnosticsUpdate = waitForDiagnostics(analysisOptionsUri);
    await initialize();
    var initialDiagnostics = await firstDiagnosticsUpdate;
    expect(initialDiagnostics, hasLength(1));
    expect(initialDiagnostics!.first.severity, DiagnosticSeverity.Warning);
    expect(initialDiagnostics.first.code, 'undefined_lint');
  }

  @FailingTest(issue: 'https://github.com/dart-lang/sdk/issues/43926')
  Future<void> test_analysisOptionsFile_packageInclude() async {
    newFile(analysisOptionsPath, '''
include: package:pedantic/analysis_options.yaml
''');

    // Verify there's an error for the import.
    var firstDiagnosticsUpdate = waitForDiagnostics(analysisOptionsUri);
    await initialize();
    var initialDiagnostics = await firstDiagnosticsUpdate;
    expect(initialDiagnostics, hasLength(1));
    expect(initialDiagnostics!.first.severity, DiagnosticSeverity.Warning);
    expect(initialDiagnostics.first.code, 'include_file_not_found');

    // TODO(scheglov): The server does not handle the file change.
    throw 'Times out';

    // // Write a package file that allows resolving the include.
    // final secondDiagnosticsUpdate = waitForDiagnostics(analysisOptionsUri);
    // writeTestPackageConfig(pedantic: true);
    //
    // // Ensure the error disappeared.
    // final updatedDiagnostics = await secondDiagnosticsUpdate;
    // expect(updatedDiagnostics, hasLength(0));
  }

  /// Ensure the server can initialize correctly and send diagnostics when the
  /// analysis_options file throws errors during parsing.
  ///
  /// https://github.com/dart-lang/sdk/issues/55987
  Future<void> test_analysisOptionsFile_parseError() async {
    newFile(analysisOptionsPath, '''
include: package:lints/recommended.yaml
f

''');

    var firstDiagnosticsUpdate = waitForDiagnostics(analysisOptionsUri);
    await initialize();
    var initialDiagnostics = await firstDiagnosticsUpdate;
    var diagnostic = initialDiagnostics!.first;
    expect(diagnostic.severity, DiagnosticSeverity.Error);
    expect(diagnostic.code, 'parse_error');
    expect(diagnostic.message, "Expected ':'.");
  }

  Future<void> test_contextMessage() async {
    newFile(mainFilePath, '''
void f() {
  x = 0;
  int? x;
  print(x);
}
''');

    var diagnosticsUpdate = waitForDiagnostics(mainFileUri);
    await initialize();
    var diagnostics = await diagnosticsUpdate;
    expect(diagnostics, hasLength(1));
    var diagnostic = diagnostics!.first;
    expect(diagnostic.relatedInformation, hasLength(1));
  }

  Future<void> test_correction() async {
    newFile(mainFilePath, '''
void f() {
  x = 0;
}
''');

    var diagnosticsUpdate = waitForDiagnostics(mainFileUri);
    await initialize();
    var diagnostics = await diagnosticsUpdate;
    expect(diagnostics, hasLength(1));
    var diagnostic = diagnostics!.first;
    expect(diagnostic.message, contains('\nTry'));
  }

  Future<void> test_deletedFile() async {
    newFile(mainFilePath, 'String a = 1;');

    var firstDiagnosticsUpdate = waitForDiagnostics(mainFileUri);
    await initialize();
    var originalDiagnostics = await firstDiagnosticsUpdate;
    expect(originalDiagnostics, hasLength(1));

    // Deleting the file should result in an update to remove the diagnostics.
    var secondDiagnosticsUpdate = waitForDiagnostics(mainFileUri);
    deleteFile(mainFilePath);
    var updatedDiagnostics = await secondDiagnosticsUpdate;
    expect(updatedDiagnostics, hasLength(0));
  }

  Future<void> test_diagnosticTag_deprecated() async {
    setDiagnosticTagSupport([DiagnosticTag.Deprecated]);

    var onePackagePath = convertPath('/home/one');
    writeTestPackageConfig(
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

    var diagnosticsUpdate = waitForDiagnostics(mainFileUri);
    await initialize();
    var diagnostics = await diagnosticsUpdate;
    expect(diagnostics, hasLength(1));
    var diagnostic = diagnostics!.first;
    expect(diagnostic.code, equals('deprecated_member_use'));
    expect(diagnostic.tags, contains(DiagnosticTag.Deprecated));
  }

  Future<void> test_diagnosticTag_notSupported() async {
    var onePackagePath = convertPath('/home/one');
    writeTestPackageConfig(
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

    var diagnosticsUpdate = waitForDiagnostics(mainFileUri);
    await initialize();
    var diagnostics = await diagnosticsUpdate;
    expect(diagnostics, hasLength(1));
    var diagnostic = diagnostics!.first;
    expect(diagnostic.code, equals('deprecated_member_use'));
    expect(diagnostic.tags, isNull);
  }

  Future<void> test_diagnosticTag_unnecessary() async {
    setDiagnosticTagSupport([DiagnosticTag.Unnecessary]);

    newFile(mainFilePath, '''
    void f() {
      return;
      print('unreachable');
    }
    ''');

    var diagnosticsUpdate = waitForDiagnostics(mainFileUri);
    await initialize();
    var diagnostics = await diagnosticsUpdate;
    expect(diagnostics, hasLength(1));
    var diagnostic = diagnostics!.first;
    expect(diagnostic.code, equals('dead_code'));
    expect(diagnostic.tags, contains(DiagnosticTag.Unnecessary));
  }

  Future<void> test_documentationUrl() async {
    setDiagnosticCodeDescriptionSupport();

    newFile(mainFilePath, '''
    // ignore: unused_import
    import 'dart:async' as import; // produces BUILT_IN_IDENTIFIER_IN_DECLARATION
    ''');

    var diagnosticsUpdate = waitForDiagnostics(mainFileUri);
    await initialize();
    var diagnostics = await diagnosticsUpdate;
    expect(diagnostics, hasLength(1));
    var diagnostic = diagnostics!.first;
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

    var diagnosticsUpdate = waitForDiagnostics(mainFileUri);
    await initialize();
    var diagnostics = await diagnosticsUpdate;
    expect(diagnostics, hasLength(1));
    var diagnostic = diagnostics!.first;
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

  /// Verify we don't send a redundant set of empty diagnostics during startup.
  Future<void> test_emptyDiagnostics_notInitial() async {
    newFile(mainFilePath, 'void f() {}');

    var notifications = <PublishDiagnosticsParams>[];
    publishedDiagnostics.listen(notifications.add);

    await initialize();
    await pumpEventQueue(times: 5000);

    expect(notifications.length, isZero);
  }

  /// Verify we only send diagnostic updates when a) they're not empty or
  /// b) they're empty, but the previous set was not empty.
  Future<void> test_emptyDiagnostics_onlyOnce() async {
    var notifications = <PublishDiagnosticsParams>[];
    publishedDiagnostics.listen(notifications.add);

    await initialize();
    await pumpEventQueue(times: 5000);

    /// Helper that executes [f] and checks whether it produces a diagnostic
    /// update.
    Future<void> verifyAction(_VoidCallback f, bool expectUpdate) async {
      notifications.clear();
      await f();
      await pumpEventQueue(times: 5000);
      expect(notifications, hasLength(expectUpdate ? 1 : 0));
    }

    Future<void> expectUpdate(_VoidCallback f) => verifyAction(f, true);
    Future<void> expectNoUpdate(_VoidCallback f) => verifyAction(f, false);

    // New file, 0 diagnostics, sends no notification
    await expectNoUpdate(() => openFile(mainFileUri, 'void f() {}'));
    // Update, non-empty diagnostic always sends notification
    await expectUpdate(() => replaceFile(1, mainFileUri, 'v'));
    // Update, non-empty diagnostic always sends notification
    await expectUpdate(() => replaceFile(1, mainFileUri, 'g'));
    // Update, 1->0 diagnostics, sends notification
    await expectUpdate(() => replaceFile(2, mainFileUri, 'void g() {}'));
    // Update, 0->0 diagnostics, sends no notification
    await expectNoUpdate(() => replaceFile(3, mainFileUri, 'void h() {}'));
  }

  Future<void> test_fixDataFile() async {
    var fixDataPath = join(projectFolderPath, 'lib', 'fix_data.yaml');
    var fixDataUri = pathContext.toUri(fixDataPath);
    newFile(fixDataPath, '''
version: latest
''').path;

    var firstDiagnosticsUpdate = waitForDiagnostics(fixDataUri);
    await initialize();
    var initialDiagnostics = await firstDiagnosticsUpdate;
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
    var serverErrorMessage =
        "A value of type 'int' can't be assigned to a variable of type 'String'";
    var pluginErrorMessage = 'Test error from plugin';

    newFile(mainFilePath, 'String a = 1;');
    var initialDiagnosticsFuture = waitForDiagnostics(mainFileUri);
    await initialize();
    var initialDiagnostics = await initialDiagnosticsFuture;
    expect(initialDiagnostics, hasLength(1));
    expect(initialDiagnostics!.first.message, contains(serverErrorMessage));

    var pluginTriggeredDiagnosticFuture = waitForDiagnostics(mainFileUri);
    var pluginError = plugin.AnalysisError(
      plugin.AnalysisErrorSeverity.ERROR,
      plugin.AnalysisErrorType.STATIC_TYPE_WARNING,
      plugin.Location(mainFilePath, 0, 1, 0, 0, endLine: 0, endColumn: 1),
      pluginErrorMessage,
      'ERR1',
    );
    var pluginResult = plugin.AnalysisErrorsParams(mainFilePath, [pluginError]);
    configureTestPlugin(notification: pluginResult.toNotification());

    var pluginTriggeredDiagnostics = await pluginTriggeredDiagnosticFuture;
    expect(
        pluginTriggeredDiagnostics!.map((error) => error.message),
        containsAll([
          pluginErrorMessage,
          contains(serverErrorMessage),
        ]));
  }

  /// Test that when server has produced diagnostics for a file and it is
  /// subsequently removed, that an update from the plugin does not cause
  /// the last diagnostics from the server to re-appear (which happens if the
  /// deletion does not clear the servers errors from the ErrorCollector).
  ///
  /// https://github.com/Dart-Code/Dart-Code/issues/5113
  Future<void> test_fromPlugins_dartFile_producedAfterFileRemoved() async {
    var serverErrorMessage =
        "A value of type 'int' can't be assigned to a variable of type 'String'";
    var pluginErrorMessage = 'Test error from plugin';

    // First, trigger a diagnostic from the server.
    newFile(mainFilePath, 'String a = 1;');
    var diagnosticsFuture = waitForDiagnostics(mainFileUri);
    await initialize();

    // Expect only the server diagnostic.
    expect((await diagnosticsFuture)!.single.message,
        contains(serverErrorMessage));

    // Delete the file, and expect diagnostics to be cleared.
    diagnosticsFuture = waitForDiagnostics(mainFileUri);
    deleteFile(mainFilePath);
    expect((await diagnosticsFuture)!, hasLength(0));

    // Trigger a plugin diagnostic. In reality, the plugin would probalby
    // produce 0 diagnostics after the file is removed, but since the LSP server
    // has an optimization to not send empty diagnostics if the last update was
    // empty, we wouldn't be able wait for that so we just use a real diagnostic
    // (which is still realistic since plugins might have not processed the
    // remove yet).
    diagnosticsFuture = waitForDiagnostics(mainFileUri);
    var pluginError = plugin.AnalysisError(
      plugin.AnalysisErrorSeverity.ERROR,
      plugin.AnalysisErrorType.STATIC_TYPE_WARNING,
      plugin.Location(mainFilePath, 0, 1, 0, 0, endLine: 0, endColumn: 1),
      pluginErrorMessage,
      'ERR1',
    );
    var pluginResult = plugin.AnalysisErrorsParams(mainFilePath, [pluginError]);
    configureTestPlugin(notification: pluginResult.toNotification());

    // Wait for the diagnostic updated and ensure it's still empty and no stale
    // error has come back.
    expect((await diagnosticsFuture)!.single.message, pluginErrorMessage);
  }

  Future<void> test_fromPlugins_nonDartFile() async {
    await checkPluginErrorsForFile(join(projectFolderPath, 'lib', 'foo.sql'));
  }

  Future<void> test_initialAnalysis() async {
    newFile(mainFilePath, 'String a = 1;');

    var diagnosticsUpdate = waitForDiagnostics(mainFileUri);
    await initialize();
    var diagnostics = await diagnosticsUpdate;
    expect(diagnostics, hasLength(1));
    var diagnostic = diagnostics!.first;
    expect(diagnostic.code, equals('invalid_assignment'));
    expect(diagnostic.range.start.line, equals(0));
    expect(diagnostic.range.start.character, equals(11));
    expect(diagnostic.range.end.line, equals(0));
    expect(diagnostic.range.end.character, equals(12));
  }

  /// Ensure lints included from another package work when there are multiple
  /// workspace folders.
  ///
  /// https://github.com/dart-lang/sdk/issues/56047
  @skippedTest
  Future<void> test_lints_includedFromPackage() async {
    // FailingTest() doesn't handle timeouts so this is marked as skipped.
    // Needs to be manually updated when
    // https://github.com/dart-lang/sdk/issues/56047 is fixed.

    var rootWorkspacePath = '$packagesRootPath/root';

    // Set up a project with an analysis_options that enables a lint.
    var lintsPackagePath = '$rootWorkspacePath/my_lints';
    newFile('$lintsPackagePath/lib/pubspec.yaml', '''
name: my_lints
''');
    newFile('$lintsPackagePath/lib/analysis_options.yaml', '''
linter:
  rules:
    - avoid_dynamic_calls
''');
    writePackageConfig(convertPath(lintsPackagePath));

    // Set up a project that imports the analysis_options and violates the lint.
    var projectPackagePath = '$rootWorkspacePath/my_project';
    writePackageConfig(
      projectPackagePath,
      config: (PackageConfigFileBuilder()
        ..add(name: 'my_lints', rootPath: lintsPackagePath)),
    );
    newFile('$projectPackagePath/analysis_options.yaml', '''
include: package:my_lints/analysis_options.yaml

linter:
  rules:
    - prefer_single_quotes
''');
    newFile('$projectPackagePath/main.dart', '''
void f(dynamic a) => a.foo();
''');

    // Verify there's an error for the import.
    var diagnosticsUpdate =
        waitForDiagnostics(toUri('$projectPackagePath/main.dart'));
    await initialize(workspaceFolders: [toUri(rootWorkspacePath)]);
    var diagnostics = await diagnosticsUpdate;
    expect(diagnostics!.single.code, contains('avoid_dynamic_calls'));
  }

  Future<void> test_looseFile_withoutPubpsec() async {
    await initialize(allowEmptyRootUri: true);

    // Opening the file should trigger diagnostics.
    {
      var diagnosticsUpdate = waitForDiagnostics(mainFileUri);
      await openFile(mainFileUri, 'final a = Bad();');
      var diagnostics = await diagnosticsUpdate;
      expect(diagnostics, hasLength(1));
      var diagnostic = diagnostics!.first;
      expect(diagnostic.message, contains("The function 'Bad' isn't defined"));
    }

    // Closing the file should remove the diagnostics.
    {
      var diagnosticsUpdate = waitForDiagnostics(mainFileUri);
      await closeFile(mainFileUri);
      var diagnostics = await diagnosticsUpdate;
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
    var originalDiagnosticsUpdate = waitForDiagnostics(mainFileUri);
    await replaceFile(docVersion++, mainFileUri, wrappedContent('final bar;'));
    var originalDiagnostics = await originalDiagnosticsUpdate;

    // Helper to update the content and verify the same diagnostics are returned
    // in the same order, despite the changes to offset/message altering
    // hashcodes.
    Future<void> verifyDiagnostics(String content) async {
      var diagnosticsUpdate = waitForDiagnostics(mainFileUri);
      await replaceFile(docVersion++, mainFileUri, wrappedContent(content));
      var diagnostics = await diagnosticsUpdate;
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

    var firstDiagnosticsUpdate = waitForDiagnostics(mainFileUri);
    // Don't set showTodos in config, because they should show even without this
    // setting if they are upgraded to warnings/errors.
    await initialize();
    var initialDiagnostics = await firstDiagnosticsUpdate;
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

    await provideConfig(
      initialize,
      {'showTodos': true},
    );
    expect(diagnostics[mainFileUri], hasLength(2));
  }

  Future<void> test_todos_disabled() async {
    const contents = '''
    // TODO: This
    String a = "";
    ''';
    newFile(mainFilePath, contents);

    // TODOs are disabled by default so we don't need to send any config.
    await initialize();
    await pumpEventQueue(times: 5000);
    expect(diagnostics[mainFileUri], isNull);
  }

  Future<void> test_todos_enabledAfterAnalysis() async {
    const contents = '''
    // TODO: This
    String a = "";
    ''';

    await provideConfig(initialize, {});
    await openFile(mainFileUri, contents);
    await initialAnalysis;
    expect(diagnostics[mainFileUri], isNull);

    await updateConfig({'showTodos': true});
    await waitForAnalysisComplete();
    expect(diagnostics[mainFileUri], hasLength(1));
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

    await provideConfig(
      initialize,
      {
        // Include both casings, since this comes from the user we should handle
        // either.
        'showTodos': ['TODO', 'fixme']
      },
    );
    await initialAnalysis;

    var initialDiagnostics = diagnostics[mainFileUri]!;
    expect(initialDiagnostics, hasLength(2));
    expect(
      initialDiagnostics.map((e) => e.code!),
      containsAll(['todo', 'fixme']),
    );
  }
}
