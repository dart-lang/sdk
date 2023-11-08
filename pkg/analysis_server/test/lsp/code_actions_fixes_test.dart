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
    // This code should get a fix to replace 'foo' with 'bar'.'
    const content = '''
[!foo!]
''';
    const expectedContent = '''
bar
''';

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

    await verifyActionEdits(
      filePath: filePath,
      content,
      expectedContent,
      kind: CodeActionKind('quickfix.fooToBar'),
      title: "Change 'foo' to 'bar'",
    );
  }

  @override
  void setUp() {
    super.setUp();
    setSupportedCodeActionKinds([CodeActionKind.QuickFix]);
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
    await initialize();

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
    await initialize();

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
    await initialize();

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
    - [!camel_case_types!]
    - lines_longer_than_80_chars
''';

      const expectedContent = r'''
linter:
  rules:
    - prefer_is_empty
    - lines_longer_than_80_chars
''';

      await verifyActionEdits(
        filePath: analysisOptionsPath,
        content,
        expectedContent,
        kind: CodeActionKind('quickfix.removeLint'),
        title: "Remove 'camel_case_types'",
      );
    } finally {
      // Restore the "real" `camel_case_types`.
      Registry.ruleRegistry.register(camelCaseTypes);
    }
  }

  Future<void> test_appliesCorrectEdits_withDocumentChangesSupport() async {
    // This code should get a fix to remove the unused import.
    const content = '''
import 'dart:async';
[!import!] 'dart:convert';

Future foo;
''';

    const expectedContent = '''
import 'dart:async';

Future foo;
''';

    await verifyActionEdits(
      content,
      expectedContent,
      kind: CodeActionKind('quickfix.remove.unusedImport'),
      title: 'Remove unused import',
    );
  }

  Future<void> test_appliesCorrectEdits_withoutDocumentChangesSupport() async {
    // This code should get a fix to remove the unused import.
    const content = '''
import 'dart:async';
[!import!] 'dart:convert';

Future foo;
''';

    const expectedContent = '''
import 'dart:async';

Future foo;
''';

    setDocumentChangesSupport(false);
    await verifyActionEdits(
      content,
      expectedContent,
      kind: CodeActionKind('quickfix.remove.unusedImport'),
      title: 'Remove unused import',
    );
  }

  Future<void> test_createFile() async {
    const content = '''
import '[!newfile.dart!]';
''';

    const expectedContent = '''
>>>>>>>>>> lib/newfile.dart created
// TODO Implement this library.<<<<<<<<<<
''';

    setFileCreateSupport();
    await verifyActionEdits(
      content,
      expectedContent,
      kind: CodeActionKind('quickfix.create.file'),
      title: "Create file 'newfile.dart'",
    );
  }

  Future<void> test_filtersCorrectly() async {
    setSupportedCodeActionKinds(
        [CodeActionKind.QuickFix, CodeActionKind.Refactor]);

    final code = TestCode.parse('''
import 'dart:async';
[!import!] 'dart:convert';

Future foo;
''');
    newFile(mainFilePath, code.code);
    await initialize();

    ofKind(CodeActionKind kind) => getCodeActions(
          mainFileUri,
          range: code.range.range,
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
  [!print(a!!)!];
  print(a!!);
}
''';

    final action = await expectAction(
      content,
      kind: CodeActionKind('quickfix.remove.nonNullAssertion.multi'),
      title: "Remove '!'s in file",
    );

    await executeCommand(action.command!);
    expectCommandLogged('dart.fix.remove.nonNullAssertion.multi');
  }

  Future<void> test_fixAll_notWhenNoBatchFix() async {
    // Some fixes (for example 'create function foo') are not available in the
    // batch processor, so should not generate fix-all-in-file fixes even if there
    // are multiple instances.
    final code = TestCode.parse('''
var a = [!foo!]();
var b = bar();
''');

    newFile(mainFilePath, code.code);
    await initialize();

    final allFixes = await getCodeActions(mainFileUri, range: code.range.range);

    // Expect only the single-fix, there should be no apply-all.
    expect(allFixes, hasLength(1));
    final fixTitle = allFixes.first.map((f) => f.title, (f) => f.title);
    expect(fixTitle, equals("Create function 'foo'"));
  }

  Future<void> test_fixAll_notWhenSingle() async {
    const content = '''
void f(String a) {
  [!print(a!)!];
}
''';

    await expectNoAction(
      content,
      kind: CodeActionKind('quickfix'),
      title: "Remove '!'s in file",
    );
  }

  /// Ensure the "fix all in file" action doesn't appear against an unfixable
  /// item just because the diagnostic is also reported in a location that
  /// is fixable.
  ///
  /// https://github.com/dart-lang/sdk/issues/53021
  Future<void> test_fixAll_unfixable() async {
    registerLintRules();
    newFile(analysisOptionsPath, '''
linter:
  rules:
    - non_constant_identifier_names
    ''');

    const content = '''
/// This is unfixable because it's a top-level. It should not have a "fix all
/// in file" action.
var aaa_a^aa = '';

void f() {
  /// These are here to ensure there's > 1 instance of this diagnostic to
  /// allow "fix all in file" to appear.
  final bbb_bbb = 0;
  final ccc_ccc = 0;
}
''';

    await expectNoAction(
      content,
      kind: CodeActionKind('quickfix.rename.toCamelCase.multi'),
      title: 'Rename to camel case everywhere in file',
    );
  }

  Future<void> test_fixAll_whenMultiple() async {
    const content = '''
void f(String a) {
  [!print(a!!)!];
  print(a!!);
}
''';

    const expectedContent = '''
void f(String a) {
  print(a);
  print(a);
}
''';

    await verifyActionEdits(
      content,
      expectedContent,
      kind: CodeActionKind('quickfix.remove.nonNullAssertion.multi'),
      title: "Remove '!'s in file",
    );
  }

  Future<void> test_ignoreDiagnostic_afterOtherFixes() async {
    final code = TestCode.parse('''
void main() {
  Uint8List inputBytes = Uin^t8List.fromList(List.filled(100000000, 0));
}
''');

    newFile(mainFilePath, code.code);
    await initialize();

    final position = code.position.position;
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
[!import!] 'dart:convert';

Future foo;
''';

    const expectedContent = '''
// Header comment
// Header comment
// Header comment

// ignore_for_file: unused_import

// This comment is attached to the below import
import 'dart:async';
import 'dart:convert';

Future foo;
''';

    await verifyActionEdits(
      content,
      expectedContent,
      kind: CodeActionKind('quickfix.ignore.file'),
      title: "Ignore 'unused_import' for the whole file",
    );
  }

  Future<void> test_ignoreDiagnosticForLine() async {
    const content = '''
import 'dart:async';
[!import!] 'dart:convert';

Future foo;
''';

    const expectedContent = '''
import 'dart:async';
// ignore: unused_import
import 'dart:convert';

Future foo;
''';

    await verifyActionEdits(
      content,
      expectedContent,
      kind: CodeActionKind('quickfix.ignore.line'),
      title: "Ignore 'unused_import' for this line",
    );
  }

  Future<void> test_logsExecution() async {
    final code = TestCode.parse('''
[!import!] 'dart:convert';
''');
    newFile(mainFilePath, code.code);
    await initialize();

    final codeActions =
        await getCodeActions(mainFileUri, range: code.range.range);
    final fixAction = findAction(codeActions,
        title: 'Remove unused import',
        kind: CodeActionKind('quickfix.remove.unusedImport'))!;

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
    await initialize();

    final codeActions =
        await getCodeActions(mainFileUri, range: code.range.range);
    final fixAction = findAction(codeActions,
        title: 'Convert to expression body',
        kind: CodeActionKind('quickfix.convert.toExpressionBody'));
    expect(fixAction, isNotNull);
  }

  Future<void> test_noDuplicates_differentFix() async {
    // For convenience, quick-fixes are usually returned for the entire line,
    // though this can lead to duplicate entries (by title) when multiple
    // diagnostics have their own fixes of the same type.
    //
    // Expect only the only one nearest to the start of the range to be returned.
    final code = TestCode.parse('''
void f() {
  var a = [];
  print(a!!);^
}
''');

    newFile(mainFilePath, code.code);
    await initialize();

    final codeActions =
        await getCodeActions(mainFileUri, position: code.position.position);
    final removeNnaAction = findAction(codeActions,
        title: "Remove the '!'",
        kind: CodeActionKind('quickfix.remove.nonNullAssertion'));

    // Expect only one of the fixes.
    expect(removeNnaAction, isNotNull);

    // Ensure the action is for the diagnostic on the second bang which was
    // closest to the range requested.
    final secondBangPos =
        positionFromOffset(code.code.indexOf('!);'), code.code);
    expect(removeNnaAction!.diagnostics, hasLength(1));
    final diagStart = removeNnaAction.diagnostics!.first.range.start;
    expect(diagStart, equals(secondBangPos));
  }

  Future<void> test_noDuplicates_sameFix() async {
    final code = TestCode.parse('''
var a = [Test, Test, Te[!!]st];
''');

    newFile(mainFilePath, code.code);
    await initialize();

    final codeActions =
        await getCodeActions(mainFileUri, range: code.range.range);
    final createClassActions = findAction(codeActions,
        title: "Create class 'Test'",
        kind: CodeActionKind('quickfix.create.class'));

    expect(createClassActions, isNotNull);
    expect(createClassActions!.diagnostics, hasLength(3));
  }

  Future<void> test_noDuplicates_withDocumentChangesSupport() async {
    setApplyEditSupport();
    setDocumentChangesSupport();
    setSupportedCodeActionKinds([CodeActionKind.QuickFix]);

    final code = TestCode.parse('''
var a = [Test, Test, Te[!!]st];
''');

    newFile(mainFilePath, code.code);
    await initialize();

    final codeActions =
        await getCodeActions(mainFileUri, range: code.range.range);
    final createClassActions = findAction(codeActions,
        title: "Create class 'Test'",
        kind: CodeActionKind('quickfix.create.class'));

    expect(createClassActions, isNotNull);
    expect(createClassActions!.diagnostics, hasLength(3));
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
[!import 'dart:async'!];

Completer a;
ProcessInfo b;
''';

    const expectedContent = '''
import 'dart:async';
import 'dart:io';

Completer a;
ProcessInfo b;
''';

    await verifyActionEdits(
      content,
      expectedContent,
      kind: CodeActionKind('quickfix.organize.imports'),
      title: 'Organize Imports',
    );
  }

  Future<void> test_outsideRoot() async {
    final otherFilePath = convertPath('/home/otherProject/foo.dart');
    final otherFileUri = pathContext.toUri(otherFilePath);
    newFile(otherFilePath, 'bad code to create error');
    await initialize();

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
    final code = TestCode.parse('''
[!import!] 'dart:convert';
''');

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

    newFile(mainFilePath, code.code);
    await initialize();

    final codeActions =
        await getCodeActions(mainFileUri, range: code.range.range);
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
    const content = '^';

    const expectedContent = r'''
name: my_project
''';

    await verifyActionEdits(
      filePath: pubspecFilePath,
      content,
      expectedContent,
      kind: CodeActionKind('quickfix.add.name'),
      title: "Add 'name' key",
    );
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

    setSnippetTextEditSupport();
    await verifyActionEdits(
      content,
      expectedContent,
      kind: CodeActionKind('quickfix.create.method'),
      title: "Create method 'c'",
    );
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

    setSnippetTextEditSupport();
    await verifyActionEdits(
      content,
      expectedContent,
      kind: CodeActionKind('quickfix.create.localVariable'),
      title: "Create local variable 'test'",
    );
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
