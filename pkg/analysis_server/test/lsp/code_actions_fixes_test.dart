// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analyzer/src/lint/linter.dart';
import 'package:analyzer/src/lint/registry.dart';
import 'package:analyzer/src/test_utilities/test_code_format.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart' as plugin;
import 'package:analyzer_plugin/protocol/protocol_generated.dart' as plugin;
import 'package:linter/src/rules.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../utils/test_code_extensions.dart';
import 'code_actions_abstract.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FixesCodeActionsTest);
  });
}

/// A version of `camel_case_types` that is deprecated.
class DeprecatedCamelCaseTypes extends LintRule {
  DeprecatedCamelCaseTypes()
      : super(
          name: 'camel_case_types',
          group: Group.style,
          state: State.deprecated(),
          description: '',
          details: '',
        );
}

@reflectiveTest
class FixesCodeActionsTest extends AbstractCodeActionsTest {
  /// Helper to check plugin fixes for [filePath].
  ///
  /// Used to ensure that both Dart and non-Dart files fixes are returned.
  Future<void> checkPluginResults(String filePath) async {
    final fileUri = Uri.file(filePath);

    // This code should get a fix to replace 'foo' with 'bar'.'
    const content = '[[foo]]';
    const expectedContent = 'bar';

    final pluginResult = plugin.EditGetFixesResult([
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
                plugin.SourceFileEdit(filePath, 0,
                    edits: [plugin.SourceEdit(0, 3, 'bar')])
              ],
              id: 'fooToBar',
            ),
          )
        ],
      )
    ]);
    configureTestPlugin(
      handler: (request) =>
          request is plugin.EditGetFixesParams ? pluginResult : null,
    );

    newFile(filePath, withoutMarkers(content));
    await initialize(
      textDocumentCapabilities: withCodeActionKinds(
          emptyTextDocumentClientCapabilities, [CodeActionKind.QuickFix]),
    );

    final codeActions =
        await getCodeActions(fileUri, range: rangeFromMarkers(content));
    final assist = findEditAction(codeActions,
        CodeActionKind('quickfix.fooToBar'), "Change 'foo' to 'bar'")!;

    final edit = assist.edit!;
    expect(edit.changes, isNotNull);

    // Ensure applying the changes will give us the expected content.
    final contents = {
      filePath: withoutMarkers(content),
    };
    applyChanges(contents, edit.changes!);
    expect(contents[filePath], equals(expectedContent));
  }

  Future<void> test_addImport_noPreference() async {
    newFile(
      join(projectFolderPath, 'lib', 'class.dart'),
      'class MyClass {}',
    );

    final code = TestCode.parse('''
MyCla^ss? a;
''');

    newFile(mainFilePath, code.code);
    await initialize(
      textDocumentCapabilities: withCodeActionKinds(
          emptyTextDocumentClientCapabilities, [CodeActionKind.QuickFix]),
    );

    final codeActions =
        await getCodeActions(mainFileUri, position: code.position.position);
    final codeActionTitles = codeActions.map((action) =>
        action.map((command) => command.title, (action) => action.title));

    expect(
      codeActionTitles,
      // With no preference, server defaults to absolute.
      containsAllInOrder([
        "Import library 'package:test/class.dart'",
        "Import library 'class.dart'",
      ]),
    );
  }

  Future<void> test_addImport_preferAbsolute() async {
    _enableLints(['always_use_package_imports']);

    newFile(
      join(projectFolderPath, 'lib', 'class.dart'),
      'class MyClass {}',
    );

    final code = TestCode.parse('''
MyCla^ss? a;
''');

    newFile(mainFilePath, code.code);
    await initialize(
      textDocumentCapabilities: withCodeActionKinds(
          emptyTextDocumentClientCapabilities, [CodeActionKind.QuickFix]),
    );

    final codeActions =
        await getCodeActions(mainFileUri, position: code.position.position);
    final codeActionTitles = codeActions.map((action) =>
        action.map((command) => command.title, (action) => action.title));

    expect(
      codeActionTitles,
      containsAllInOrder([
        "Import library 'package:test/class.dart'",
        "Import library 'class.dart'",
      ]),
    );
  }

  Future<void> test_addImport_preferRelative() async {
    _enableLints(['prefer_relative_imports']);

    newFile(
      join(projectFolderPath, 'lib', 'class.dart'),
      'class MyClass {}',
    );

    final code = TestCode.parse('''
MyCla^ss? a;
''');

    newFile(mainFilePath, code.code);
    await initialize(
      textDocumentCapabilities: withCodeActionKinds(
          emptyTextDocumentClientCapabilities, [CodeActionKind.QuickFix]),
    );

    final codeActions =
        await getCodeActions(mainFileUri, position: code.position.position);
    final codeActionTitles = codeActions.map((action) =>
        action.map((command) => command.title, (action) => action.title));

    expect(
      codeActionTitles,
      containsAllInOrder([
        "Import library 'class.dart'",
        "Import library 'package:test/class.dart'",
      ]),
    );
  }

  Future<void> test_analysisOptions() async {
    registerLintRules();

    // To ensure there's an associated code action, we manually deprecate an
    // existing lint (`camel_case_types`) for the duration of this test.

    // Fetch the "actual" lint so we can restore it after the test.
    var camelCaseTypes = Registry.ruleRegistry.getRule('camel_case_types')!;

    // Overwrite it.
    Registry.ruleRegistry.register(DeprecatedCamelCaseTypes());

    // Now we can assume it will have an action associated...

    try {
      const content = r'''
linter:
  rules:
    - prefer_is_empty
    - [[camel_case_types]]
    - lines_longer_than_80_chars
''';

      const expectedContent = r'''
linter:
  rules:
    - prefer_is_empty
    - lines_longer_than_80_chars
''';

      newFile(analysisOptionsPath, withoutMarkers(content));
      await initialize(
        textDocumentCapabilities: withCodeActionKinds(
            emptyTextDocumentClientCapabilities, [CodeActionKind.QuickFix]),
      );

      // Expect a fix.
      final codeActions = await getCodeActions(analysisOptionsUri,
          range: rangeFromMarkers(content));
      final fix = findEditAction(codeActions,
          CodeActionKind('quickfix.removeLint'), "Remove 'camel_case_types'")!;

      // Ensure it makes the correct edits.
      final edit = fix.edit!;
      final contents = {
        analysisOptionsPath: withoutMarkers(content),
      };
      applyChanges(contents, edit.changes!);
      expect(contents[analysisOptionsPath], equals(expectedContent));
    } finally {
      // Restore the "real" `camel_case_types`.
      Registry.ruleRegistry.register(camelCaseTypes);
    }
  }

  Future<void> test_appliesCorrectEdits_withDocumentChangesSupport() async {
    // This code should get a fix to remove the unused import.
    const content = '''
    import 'dart:async';
    [[import]] 'dart:convert';

    Future foo;
    ''';

    const expectedContent = '''
    import 'dart:async';

    Future foo;
    ''';
    newFile(mainFilePath, withoutMarkers(content));
    await initialize(
      textDocumentCapabilities: withCodeActionKinds(
          emptyTextDocumentClientCapabilities, [CodeActionKind.QuickFix]),
      workspaceCapabilities:
          withDocumentChangesSupport(emptyWorkspaceClientCapabilities),
    );

    final codeActions =
        await getCodeActions(mainFileUri, range: rangeFromMarkers(content));
    final fixAction = findEditAction(
        codeActions,
        CodeActionKind('quickfix.remove.unusedImport'),
        'Remove unused import')!;

    // Ensure the edit came back, and using documentChanges.
    final edit = fixAction.edit!;
    expect(edit.documentChanges, isNotNull);
    expect(edit.changes, isNull);

    // Ensure applying the changes will give us the expected content.
    final contents = {
      mainFilePath: withoutMarkers(content),
    };
    applyDocumentChanges(contents, edit.documentChanges!);
    expect(contents[mainFilePath], equals(expectedContent));
  }

  Future<void> test_appliesCorrectEdits_withoutDocumentChangesSupport() async {
    // This code should get a fix to remove the unused import.
    const content = '''
    import 'dart:async';
    [[import]] 'dart:convert';

    Future foo;
    ''';

    const expectedContent = '''
    import 'dart:async';

    Future foo;
    ''';
    newFile(mainFilePath, withoutMarkers(content));
    await initialize(
      textDocumentCapabilities: withCodeActionKinds(
          emptyTextDocumentClientCapabilities, [CodeActionKind.QuickFix]),
    );

    final codeActions =
        await getCodeActions(mainFileUri, range: rangeFromMarkers(content));
    final fixAction = findEditAction(
        codeActions,
        CodeActionKind('quickfix.remove.unusedImport'),
        'Remove unused import')!;

    // Ensure the edit came back, and using changes.
    final edit = fixAction.edit!;
    expect(edit.changes, isNotNull);
    expect(edit.documentChanges, isNull);

    // Ensure applying the changes will give us the expected content.
    final contents = {
      mainFilePath: withoutMarkers(content),
    };
    applyChanges(contents, edit.changes!);
    expect(contents[mainFilePath], equals(expectedContent));
  }

  Future<void> test_createFile() async {
    const content = '''
    import '[[newfile.dart]]';
    ''';

    final expectedCreatedFile =
        path.join(path.dirname(mainFilePath), 'newfile.dart');

    newFile(mainFilePath, withoutMarkers(content));
    await initialize(
      textDocumentCapabilities: withCodeActionKinds(
          emptyTextDocumentClientCapabilities, [CodeActionKind.QuickFix]),
      workspaceCapabilities: withResourceOperationKinds(
          emptyWorkspaceClientCapabilities, [ResourceOperationKind.Create]),
    );

    final codeActions =
        await getCodeActions(mainFileUri, range: rangeFromMarkers(content));
    final fixAction = findEditAction(codeActions,
        CodeActionKind('quickfix.create.file'), "Create file 'newfile.dart'")!;

    final edit = fixAction.edit!;
    expect(edit.documentChanges, isNotNull);

    // Ensure applying the changes creates the file and with the expected content.
    final contents = {
      mainFilePath: withoutMarkers(content),
    };
    applyDocumentChanges(contents, edit.documentChanges!);
    expect(contents[expectedCreatedFile], isNotEmpty);
  }

  Future<void> test_filtersCorrectly() async {
    const content = '''
    import 'dart:async';
    [[import]] 'dart:convert';

    Future foo;
    ''';
    newFile(mainFilePath, withoutMarkers(content));
    await initialize(
      textDocumentCapabilities: withCodeActionKinds(
        emptyTextDocumentClientCapabilities,
        [CodeActionKind.QuickFix, CodeActionKind.Refactor],
      ),
    );

    ofKind(CodeActionKind kind) => getCodeActions(
          mainFileUri,
          range: rangeFromMarkers(content),
          kinds: [kind],
        );

    // The code above will return a quickfix.remove.unusedImport
    expect(await ofKind(CodeActionKind.QuickFix), isNotEmpty);
    expect(await ofKind(CodeActionKind('quickfix.remove')), isNotEmpty);
    expect(await ofKind(CodeActionKind('quickfix.other')), isEmpty);
    expect(await ofKind(CodeActionKind.Refactor), isEmpty);
  }

  Future<void> test_fixAll_logsExecution() async {
    const content = '''
void f(String a) {
  [[print(a!!)]];
  print(a!!);
}
    ''';
    newFile(mainFilePath, withoutMarkers(content));
    await initialize(
      textDocumentCapabilities: withCodeActionKinds(
          emptyTextDocumentClientCapabilities, [CodeActionKind.QuickFix]),
    );

    final codeActions =
        await getCodeActions(mainFileUri, range: rangeFromMarkers(content));
    final fixAction = findEditAction(
      codeActions,
      CodeActionKind('quickfix.remove.nonNullAssertion.multi'),
      "Remove '!'s in file",
    )!;

    await executeCommand(fixAction.command!);
    expectCommandLogged('dart.fix.remove.nonNullAssertion.multi');
  }

  Future<void> test_fixAll_notWhenNoBatchFix() async {
    // Some fixes (for example 'create function foo') are not available in the
    // batch processor, so should not generate fix-all-in-file fixes even if there
    // are multiple instances.
    const content = '''
var a = [[foo]]();
var b = bar();
    ''';

    newFile(mainFilePath, withoutMarkers(content));
    await initialize(
      textDocumentCapabilities: withCodeActionKinds(
          emptyTextDocumentClientCapabilities, [CodeActionKind.QuickFix]),
    );

    final allFixes =
        await getCodeActions(mainFileUri, range: rangeFromMarkers(content));

    // Expect only the single-fix, there should be no apply-all.
    expect(allFixes, hasLength(1));
    final fixTitle = allFixes.first.map((f) => f.title, (f) => f.title);
    expect(fixTitle, equals("Create function 'foo'"));
  }

  Future<void> test_fixAll_notWhenSingle() async {
    const content = '''
void f(String a) {
  [[print(a!)]];
}
    ''';

    newFile(mainFilePath, withoutMarkers(content));
    await initialize(
      textDocumentCapabilities: withCodeActionKinds(
          emptyTextDocumentClientCapabilities, [CodeActionKind.QuickFix]),
    );

    final codeActions =
        await getCodeActions(mainFileUri, range: rangeFromMarkers(content));
    final fixAction = findEditAction(
        codeActions, CodeActionKind('quickfix'), "Remove '!'s in file");

    // Should not appear if there was only a single error.
    expect(fixAction, isNull);
  }

  Future<void> test_fixAll_whenMultiple() async {
    const content = '''
void f(String a) {
  [[print(a!!)]];
  print(a!!);
}
    ''';

    const expectedContent = '''
void f(String a) {
  print(a);
  print(a);
}
    ''';
    newFile(mainFilePath, withoutMarkers(content));
    await initialize(
      textDocumentCapabilities: withCodeActionKinds(
          emptyTextDocumentClientCapabilities, [CodeActionKind.QuickFix]),
    );

    final codeActions =
        await getCodeActions(mainFileUri, range: rangeFromMarkers(content));
    final fixAction = findEditAction(
      codeActions,
      CodeActionKind('quickfix.remove.nonNullAssertion.multi'),
      "Remove '!'s in file",
    )!;

    // Ensure applying the changes will give us the expected content.
    final contents = {
      mainFilePath: withoutMarkers(content),
    };
    applyChanges(contents, fixAction.edit!.changes!);
    expect(contents[mainFilePath], equals(expectedContent));
  }

  Future<void> test_ignoreDiagnostic_afterOtherFixes() async {
    const content = '''
void main() {
  Uint8List inputBytes = Uin^t8List.fromList(List.filled(100000000, 0));
}
''';

    newFile(mainFilePath, withoutMarkers(content));
    await initialize(
      textDocumentCapabilities: withCodeActionKinds(
          emptyTextDocumentClientCapabilities, [CodeActionKind.QuickFix]),
    );

    final position = positionFromMarker(content);
    final range = Range(start: position, end: position);
    final codeActions = await getCodeActions(mainFileUri, range: range);
    final codeActionKinds = codeActions.map(
      (item) => item.map(
        (command) => null,
        (action) => action.kind?.toString(),
      ),
    );

    expect(
      codeActionKinds,
      containsAllInOrder([
        // Non-ignore fixes (order doesn't matter here, but this is what
        // server produces).
        'quickfix.create.class',
        'quickfix.create.mixin',
        'quickfix.create.localVariable',
        'quickfix.remove.unusedLocalVariable',
        // Ignore fixes last, with line sorted above file.
        'quickfix.ignore.line',
        'quickfix.ignore.file',
      ]),
    );
  }

  Future<void> test_ignoreDiagnosticForFile() async {
    const content = '''
// Header comment
// Header comment
// Header comment

// This comment is attached to the below import
import 'dart:async';
[[import]] 'dart:convert';

Future foo;''';

    const expectedContent = '''
// Header comment
// Header comment
// Header comment

// ignore_for_file: unused_import

// This comment is attached to the below import
import 'dart:async';
import 'dart:convert';

Future foo;''';
    newFile(mainFilePath, withoutMarkers(content));
    await initialize(
      textDocumentCapabilities: withCodeActionKinds(
          emptyTextDocumentClientCapabilities, [CodeActionKind.QuickFix]),
    );

    // Find the ignore action.
    final codeActions =
        await getCodeActions(mainFileUri, range: rangeFromMarkers(content));
    final fixAction = findEditAction(
        codeActions,
        CodeActionKind('quickfix.ignore.file'),
        "Ignore 'unused_import' for this file")!;

    // Ensure applying the changes will give us the expected content.
    final contents = {
      mainFilePath: withoutMarkers(content),
    };
    applyChanges(contents, fixAction.edit!.changes!);
    expect(contents[mainFilePath], equals(expectedContent));
  }

  Future<void> test_ignoreDiagnosticForLine() async {
    const content = '''
import 'dart:async';
[[import]] 'dart:convert';

Future foo;''';

    const expectedContent = '''
import 'dart:async';
// ignore: unused_import
import 'dart:convert';

Future foo;''';
    newFile(mainFilePath, withoutMarkers(content));
    await initialize(
      textDocumentCapabilities: withCodeActionKinds(
          emptyTextDocumentClientCapabilities, [CodeActionKind.QuickFix]),
    );

    // Find the ignore action.
    final codeActions =
        await getCodeActions(mainFileUri, range: rangeFromMarkers(content));
    final fixAction = findEditAction(
        codeActions,
        CodeActionKind('quickfix.ignore.line'),
        "Ignore 'unused_import' for this line")!;

    // Ensure applying the changes will give us the expected content.
    final contents = {
      mainFilePath: withoutMarkers(content),
    };
    applyChanges(contents, fixAction.edit!.changes!);
    expect(contents[mainFilePath], equals(expectedContent));
  }

  Future<void> test_logsExecution() async {
    const content = '''
[[import]] 'dart:convert';
''';
    newFile(mainFilePath, withoutMarkers(content));
    await initialize(
      textDocumentCapabilities: withCodeActionKinds(
          emptyTextDocumentClientCapabilities, [CodeActionKind.QuickFix]),
    );

    final codeActions =
        await getCodeActions(mainFileUri, range: rangeFromMarkers(content));
    final fixAction = findEditAction(
        codeActions,
        CodeActionKind('quickfix.remove.unusedImport'),
        'Remove unused import')!;

    await executeCommand(fixAction.command!);
    expectCommandLogged('dart.fix.remove.unusedImport');
  }

  /// Repro for https://github.com/Dart-Code/Dart-Code/issues/4462.
  ///
  /// Original code only included a fix on its first error (which in this sample
  /// is the opening brace) and not the whole range of the error.
  Future<void> test_multilineError() async {
    registerLintRules();
    newFile(analysisOptionsPath, '''
linter:
  rules:
    - prefer_expression_function_bodies
    ''');

    final code = TestCode.parse('''
int foo() {
  [!return!] 1;
}
    ''');

    newFile(mainFilePath, code.code);
    await initialize(
      textDocumentCapabilities: withCodeActionKinds(
          emptyTextDocumentClientCapabilities, [CodeActionKind.QuickFix]),
    );

    final codeActions =
        await getCodeActions(mainFileUri, range: code.range.range);
    final fixAction = findEditAction(
        codeActions,
        CodeActionKind('quickfix.convert.toExpressionBody'),
        'Convert to expression body');
    expect(fixAction, isNotNull);
  }

  Future<void> test_noDuplicates_differentFix() async {
    // For convenience, quick-fixes are usually returned for the entire line,
    // though this can lead to duplicate entries (by title) when multiple
    // diagnostics have their own fixes of the same type.
    //
    // Expect only the only one nearest to the start of the range to be returned.
    const content = '''
void f() {
  var a = [];
  print(a!!);^
}
''';

    newFile(mainFilePath, withoutMarkers(content));
    await initialize(
      textDocumentCapabilities: withCodeActionKinds(
          emptyTextDocumentClientCapabilities, [CodeActionKind.QuickFix]),
    );

    final codeActions = await getCodeActions(mainFileUri,
        position: positionFromMarker(content));
    final removeNnaAction = findEditActions(codeActions,
        CodeActionKind('quickfix.remove.nonNullAssertion'), "Remove the '!'");

    // Expect only one of the fixes.
    expect(removeNnaAction, hasLength(1));

    // Ensure the action is for the diagnostic on the second bang which was
    // closest to the range requested.
    final secondBangPos =
        positionFromOffset(withoutMarkers(content).indexOf('!);'), content);
    expect(removeNnaAction.first.diagnostics, hasLength(1));
    final diagStart = removeNnaAction.first.diagnostics!.first.range.start;
    expect(diagStart, equals(secondBangPos));
  }

  Future<void> test_noDuplicates_sameFix() async {
    const content = '''
    var a = [Test, Test, Te[[]]st];
    ''';

    newFile(mainFilePath, withoutMarkers(content));
    await initialize(
      textDocumentCapabilities: withCodeActionKinds(
          emptyTextDocumentClientCapabilities, [CodeActionKind.QuickFix]),
    );

    final codeActions =
        await getCodeActions(mainFileUri, range: rangeFromMarkers(content));
    final createClassActions = findEditActions(codeActions,
        CodeActionKind('quickfix.create.class'), "Create class 'Test'");

    expect(createClassActions, hasLength(1));
    expect(createClassActions.first.diagnostics, hasLength(3));
  }

  Future<void> test_noDuplicates_withDocumentChangesSupport() async {
    const content = '''
    var a = [Test, Test, Te[[]]st];
    ''';

    newFile(mainFilePath, withoutMarkers(content));
    await initialize(
        textDocumentCapabilities: withCodeActionKinds(
            emptyTextDocumentClientCapabilities, [CodeActionKind.QuickFix]),
        workspaceCapabilities: withApplyEditSupport(
            withDocumentChangesSupport(emptyWorkspaceClientCapabilities)));

    final codeActions =
        await getCodeActions(mainFileUri, range: rangeFromMarkers(content));
    final createClassActions = findEditActions(codeActions,
        CodeActionKind('quickfix.create.class'), "Create class 'Test'");

    expect(createClassActions, hasLength(1));
    expect(createClassActions.first.diagnostics, hasLength(3));
  }

  Future<void> test_organizeImportsFix_namedOrganizeImports() async {
    registerLintRules();
    newFile(analysisOptionsPath, '''
linter:
  rules:
    - directives_ordering
    ''');

    // This code should get a fix to sort the imports.
    const content = '''
import 'dart:io';
[[import 'dart:async']];

Completer a;
ProcessInfo b;
    ''';

    const expectedContent = '''
import 'dart:async';
import 'dart:io';

Completer a;
ProcessInfo b;
    ''';
    newFile(mainFilePath, withoutMarkers(content));
    await initialize(
      textDocumentCapabilities: withCodeActionKinds(
          emptyTextDocumentClientCapabilities, [CodeActionKind.QuickFix]),
    );

    final codeActions =
        await getCodeActions(mainFileUri, range: rangeFromMarkers(content));
    final fixAction = findEditAction(codeActions,
        CodeActionKind('quickfix.organize.imports'), 'Organize Imports')!;

    // Ensure the edit came back, and using changes.
    final edit = fixAction.edit!;
    expect(edit.changes, isNotNull);
    expect(edit.documentChanges, isNull);

    // Ensure applying the changes will give us the expected content.
    final contents = {
      mainFilePath: withoutMarkers(content),
    };
    applyChanges(contents, edit.changes!);
    expect(contents[mainFilePath], equals(expectedContent));
  }

  Future<void> test_outsideRoot() async {
    final otherFilePath = convertPath('/home/otherProject/foo.dart');
    final otherFileUri = Uri.file(otherFilePath);
    newFile(otherFilePath, 'bad code to create error');
    await initialize(
      textDocumentCapabilities: withCodeActionKinds(
          emptyTextDocumentClientCapabilities, [CodeActionKind.QuickFix]),
    );

    final codeActions = await getCodeActions(
      otherFileUri,
      position: startOfDocPos,
    );
    expect(codeActions, isEmpty);
  }

  Future<void> test_plugin_dart() async {
    if (!AnalysisServer.supportsPlugins) return;
    return await checkPluginResults(mainFilePath);
  }

  Future<void> test_plugin_nonDart() async {
    if (!AnalysisServer.supportsPlugins) return;
    return await checkPluginResults(join(projectFolderPath, 'lib', 'foo.foo'));
  }

  Future<void> test_plugin_sortsWithServer() async {
    if (!AnalysisServer.supportsPlugins) return;
    // Produces a server fix for removing unused import with a default
    // priority of 50.
    const content = '''
[[import]] 'dart:convert';
''';

    // Provide two plugin results that should sort either side of the server fix.
    final pluginResult = plugin.EditGetFixesResult([
      plugin.AnalysisErrorFixes(
        plugin.AnalysisError(
          plugin.AnalysisErrorSeverity.ERROR,
          plugin.AnalysisErrorType.HINT,
          plugin.Location(mainFilePath, 0, 3, 0, 0),
          'Dummy error',
          'dummy',
        ),
        fixes: [
          plugin.PrioritizedSourceChange(10, plugin.SourceChange('Low')),
          plugin.PrioritizedSourceChange(100, plugin.SourceChange('High')),
        ],
      )
    ]);
    configureTestPlugin(
      handler: (request) =>
          request is plugin.EditGetFixesParams ? pluginResult : null,
    );

    newFile(mainFilePath, withoutMarkers(content));
    await initialize(
      textDocumentCapabilities: withCodeActionKinds(
          emptyTextDocumentClientCapabilities, [CodeActionKind.QuickFix]),
    );

    final codeActions =
        await getCodeActions(mainFileUri, range: rangeFromMarkers(content));
    final codeActionTitles = codeActions.map((action) =>
        action.map((command) => command.title, (action) => action.title));

    expect(
      codeActionTitles,
      containsAllInOrder([
        'High',
        'Remove unused import',
        'Low',
      ]),
    );
  }

  Future<void> test_pubspec() async {
    const content = '';

    const expectedContent = r'''
name: my_project
''';

    newFile(pubspecFilePath, content);
    await initialize(
      textDocumentCapabilities: withCodeActionKinds(
          emptyTextDocumentClientCapabilities, [CodeActionKind.QuickFix]),
    );

    // Expect a fix.
    final codeActions =
        await getCodeActions(pubspecFileUri, range: startOfDocRange);
    final fix = findEditAction(
        codeActions, CodeActionKind('quickfix.add.name'), "Add 'name' key")!;

    // Ensure it makes the correct edits.
    final edit = fix.edit!;
    final contents = {
      pubspecFilePath: withoutMarkers(content),
    };
    applyChanges(contents, edit.changes!);
    expect(contents[pubspecFilePath], equals(expectedContent));
  }

  Future<void> test_snippets_createMethod_functionTypeNestedParameters() async {
    const content = '''
class A {
  void a() => c^((cell) => cell.south);
  void b() => c((cell) => cell.west);
}
''';

    const expectedContent = r'''
class A {
  void a() => c((cell) => cell.south);
  void b() => c((cell) => cell.west);

  ${1:c}(${2:Function(dynamic cell)} ${3:param0}) {}
}
''';

    newFile(mainFilePath, withoutMarkers(content));
    await initialize(
      textDocumentCapabilities: withCodeActionKinds(
          emptyTextDocumentClientCapabilities, [CodeActionKind.QuickFix]),
      workspaceCapabilities:
          withDocumentChangesSupport(emptyWorkspaceClientCapabilities),
      experimentalCapabilities: {
        'snippetTextEdit': true,
      },
    );

    final codeActions = await getCodeActions(mainFileUri,
        position: positionFromMarker(content));
    final fixAction = findEditAction(codeActions,
        CodeActionKind('quickfix.create.method'), "Create method 'c'")!;

    // Ensure the edit came back, and using documentChanges.
    final edit = fixAction.edit!;
    expect(edit.documentChanges, isNotNull);
    expect(edit.changes, isNull);

    // Ensure applying the changes will give us the expected content.
    final contents = {
      mainFilePath: withoutMarkers(content),
    };
    applyDocumentChanges(contents, edit.documentChanges!);
    expect(contents[mainFilePath], equals(expectedContent));
  }

  Future<void>
      test_snippets_extractVariable_functionTypeNestedParameters() async {
    const content = '''
void f() {
  useFunction(te^st);
}

useFunction(int g(a, b)) {}
''';

    const expectedContent = r'''
void f() {
  ${1:int Function(dynamic a, dynamic b)} ${2:test};
  useFunction(test);
}

useFunction(int g(a, b)) {}
''';

    newFile(mainFilePath, withoutMarkers(content));
    await initialize(
      textDocumentCapabilities: withCodeActionKinds(
          emptyTextDocumentClientCapabilities, [CodeActionKind.QuickFix]),
      workspaceCapabilities:
          withDocumentChangesSupport(emptyWorkspaceClientCapabilities),
      experimentalCapabilities: {
        'snippetTextEdit': true,
      },
    );

    final codeActions = await getCodeActions(mainFileUri,
        position: positionFromMarker(content));
    final fixAction = findEditAction(
        codeActions,
        CodeActionKind('quickfix.create.localVariable'),
        "Create local variable 'test'")!;

    // Ensure the edit came back, and using documentChanges.
    final edit = fixAction.edit!;
    expect(edit.documentChanges, isNotNull);
    expect(edit.changes, isNull);

    // Ensure applying the changes will give us the expected content.
    final contents = {
      mainFilePath: withoutMarkers(content),
    };
    applyDocumentChanges(contents, edit.documentChanges!);
    expect(contents[mainFilePath], equals(expectedContent));
  }

  void _enableLints(List<String> lintNames) {
    registerLintRules();
    final lintsYaml = lintNames.map((name) => '    - $name\n').join();
    newFile(analysisOptionsPath, '''
linter:
  rules:
$lintsYaml
''');
  }
}
