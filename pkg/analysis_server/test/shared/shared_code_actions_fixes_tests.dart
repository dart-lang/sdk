// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/extensions/code_action.dart';
import 'package:analysis_server/src/services/correction/fix_internal.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/lint/linter.dart';
import 'package:analyzer/src/lint/registry.dart';
import 'package:analyzer/src/test_utilities/test_code_format.dart';
import 'package:linter/src/rules.dart';
import 'package:test/test.dart';

import '../lsp/code_actions_mixin.dart';
import '../lsp/request_helpers_mixin.dart';
import '../lsp/server_abstract.dart';
import '../utils/test_code_extensions.dart';
import 'shared_test_interface.dart';

/// Shared tests used by both LSP + Legacy server tests and/or integration.
mixin SharedFixesCodeActionsTests
    on
        SharedTestInterface,
        CodeActionsTestMixin,
        LspRequestHelpersMixin,
        LspEditHelpersMixin,
        LspVerifyEditHelpersMixin,
        ClientCapabilitiesHelperMixin {
  String get analysisOptionsPath =>
      pathContext.join(projectFolderPath, 'analysis_options.yaml');

  @override
  Future<void> setUp() async {
    await super.setUp();

    // Fix tests are likely to have diagnostics that need fixing.
    failTestOnErrorDiagnostic = false;

    setApplyEditSupport();
    setDocumentChangesSupport();
    setSupportedCodeActionKinds([CodeActionKind.QuickFix]);

    registerBuiltInFixGenerators();
  }

  Future<void> test_addImport_noPreference() async {
    createFile(
      pathContext.join(projectFolderPath, 'lib', 'class.dart'),
      'class MyClass {}',
    );

    var code = TestCode.parse('''
MyCla^ss? a;
''');

    createFile(testFilePath, code.code);
    await initializeServer();

    var codeActions = await getCodeActions(
      testFileUri,
      position: code.position.position,
    );
    var codeActionTitles = codeActions.map((action) => action.title);

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

    createFile(
      pathContext.join(projectFolderPath, 'lib', 'class.dart'),
      'class MyClass {}',
    );

    var code = TestCode.parse('''
MyCla^ss? a;
''');

    createFile(testFilePath, code.code);
    await initializeServer();

    var codeActions = await getCodeActions(
      testFileUri,
      position: code.position.position,
    );
    var codeActionTitles = codeActions.map((action) => action.title);

    expect(
      codeActionTitles,
      containsAllInOrder(["Import library 'package:test/class.dart'"]),
    );
  }

  Future<void> test_addImport_preferRelative() async {
    _enableLints(['prefer_relative_imports']);

    createFile(
      pathContext.join(projectFolderPath, 'lib', 'class.dart'),
      'class MyClass {}',
    );

    var code = TestCode.parse('''
MyCla^ss? a;
''');

    createFile(testFilePath, code.code);
    await initializeServer();

    var codeActions = await getCodeActions(
      testFileUri,
      position: code.position.position,
    );
    var codeActionTitles = codeActions.map((action) => action.title);

    expect(
      codeActionTitles,
      containsAllInOrder(["Import library 'class.dart'"]),
    );
  }

  Future<void> test_analysisOptions() async {
    registerLintRules();

    // To ensure there's an associated code action, we manually deprecate an
    // existing lint (`camel_case_types`) for the duration of this test.

    // Fetch the "actual" lint so we can restore it after the test.
    var camelCaseTypes = Registry.ruleRegistry.getRule('camel_case_types')!;

    // Overwrite it.
    Registry.ruleRegistry.registerLintRule(_DeprecatedCamelCaseTypes());

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

      await verifyCodeActionLiteralEdits(
        filePath: analysisOptionsPath,
        content,
        expectedContent,
        kind: CodeActionKind('quickfix.removeLint'),
        title: "Remove 'camel_case_types'",
      );
    } finally {
      // Restore the "real" `camel_case_types`.
      Registry.ruleRegistry.registerLintRule(camelCaseTypes);
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

    await verifyCodeActionLiteralEdits(
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
    await verifyCodeActionLiteralEdits(
      content,
      expectedContent,
      kind: CodeActionKind('quickfix.remove.unusedImport'),
      title: 'Remove unused import',
    );
  }

  Future<void> test_codeActionLiterals_supported() async {
    const content = '''
void f(String a) => [!print(a!)!];
''';

    const expectedContent = '''
void f(String a) => print(a);
''';

    await verifyCodeActionLiteralEdits(
      content,
      expectedContent,
      kind: CodeActionKind('quickfix.remove.nonNullAssertion'),
      title: "Remove the '!'",
    );
  }

  Future<void> test_codeActionLiterals_unsupported() async {
    setSupportedCodeActionKinds(null); // no codeActionLiteralSupport

    const content = '''
void f(String a) => [!print(a!)!];
''';

    const expectedContent = '''
void f(String a) => print(a);
''';

    await verifyCommandCodeActionEdits(
      content,
      expectedContent,
      command: Commands.applyCodeAction,
      title: "Remove the '!'",
    );
  }

  Future<void> test_createFile() async {
    const content = '''
import '[!createFile.dart!]';
''';

    const expectedContent = '''
>>>>>>>>>> lib/createFile.dart created
// TODO Implement this library.<<<<<<<<<<
''';

    setFileCreateSupport();
    await verifyCodeActionLiteralEdits(
      content,
      expectedContent,
      kind: CodeActionKind('quickfix.create.file'),
      title: "Create file 'createFile.dart'",
    );
  }

  Future<void> test_filtersCorrectly() async {
    setSupportedCodeActionKinds([
      CodeActionKind.QuickFix,
      CodeActionKind.Refactor,
    ]);

    var code = TestCode.parse('''
import 'dart:async';
[!import!] 'dart:convert';

Future foo;
''');
    createFile(testFilePath, code.code);
    await initializeServer();

    ofKind(CodeActionKind kind) =>
        getCodeActions(testFileUri, range: code.range.range, kinds: [kind]);

    // The code above will return a 'quickfix.remove.unusedImport'.
    expect(await ofKind(CodeActionKind.QuickFix), isNotEmpty);
    expect(await ofKind(CodeActionKind('quickfix.remove')), isNotEmpty);
    expect(await ofKind(CodeActionKind('quickfix.remove.foo')), isEmpty);
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

    var action = await expectCodeActionLiteral(
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
    var code = TestCode.parse('''
var a = [!foo!]();
var b = bar();
''');

    createFile(testFilePath, code.code);
    await initializeServer();

    var allFixes = await getCodeActions(testFileUri, range: code.range.range);

    // Expect only the single-fix, there should be no apply-all.
    expect(allFixes, hasLength(2));
    var fixTitle = allFixes.first.map((f) => f.title, (f) => f.title);
    expect(fixTitle, equals("Create function 'foo'"));
    var fixTitle2 = allFixes.last.map((f) => f.title, (f) => f.title);
    expect(fixTitle2, equals("Create class 'foo'"));
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
    createFile(analysisOptionsPath, '''
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

    await verifyCodeActionLiteralEdits(
      content,
      expectedContent,
      kind: CodeActionKind('quickfix.remove.nonNullAssertion.multi'),
      title: "Remove '!'s in file",
    );
  }

  Future<void> test_ignoreDiagnostic_afterOtherFixes() async {
    var code = TestCode.parse('''
void main() {
  Uint8List inputBytes = Uin^t8List.fromList(List.filled(100000000, 0));
}
''');

    createFile(testFilePath, code.code);
    await initializeServer();

    var position = code.position.position;
    var range = Range(start: position, end: position);
    var codeActions = await getCodeActions(testFileUri, range: range);
    var codeActionKinds = codeActions.map(
      (item) =>
          item.map((literal) => literal.kind?.toString(), (command) => null),
    );

    expect(
      codeActionKinds,
      containsAllInOrder([
        // Non-ignore fixes (order doesn't matter here, but this is what
        // server produces).
        'quickfix.create.class.uppercase',
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

    await verifyCodeActionLiteralEdits(
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

    await verifyCodeActionLiteralEdits(
      content,
      expectedContent,
      kind: CodeActionKind('quickfix.ignore.line'),
      title: "Ignore 'unused_import' for this line",
    );
  }

  Future<void> test_logsExecution() async {
    var code = TestCode.parse('''
[!import!] 'dart:convert';
''');
    createFile(testFilePath, code.code);
    await initializeServer();

    var codeActions = await getCodeActions(
      testFileUri,
      range: code.range.range,
    );
    var fixAction =
        findCodeActionLiteral(
          codeActions,
          title: 'Remove unused import',
          kind: CodeActionKind('quickfix.remove.unusedImport'),
        )!;

    await executeCommand(fixAction.command!);
    expectCommandLogged('dart.fix.remove.unusedImport');
  }

  /// Repro for https://github.com/Dart-Code/Dart-Code/issues/4462.
  ///
  /// Original code only included a fix on its first error (which in this sample
  /// is the opening brace) and not the whole range of the error.
  Future<void> test_multilineError() async {
    registerLintRules();
    createFile(analysisOptionsPath, '''
linter:
  rules:
    - prefer_expression_function_bodies
    ''');

    var code = TestCode.parse('''
int foo() {
  [!return!] 1;
}
    ''');

    createFile(testFilePath, code.code);
    await initializeServer();

    var codeActions = await getCodeActions(
      testFileUri,
      range: code.range.range,
    );
    var fixAction = findCodeActionLiteral(
      codeActions,
      title: 'Convert to expression body',
      kind: CodeActionKind('quickfix.convert.toExpressionBody'),
    );
    expect(fixAction, isNotNull);
  }

  Future<void> test_noDuplicates_differentFix() async {
    // For convenience, quick-fixes are usually returned for the entire line,
    // though this can lead to duplicate entries (by title) when multiple
    // diagnostics have their own fixes of the same type.
    //
    // Expect only the only one nearest to the start of the range to be returned.
    var code = TestCode.parse('''
void f() {
  var a = [];
  print(a!!);^
}
''');

    createFile(testFilePath, code.code);
    await initializeServer();

    var codeActions = await getCodeActions(
      testFileUri,
      position: code.position.position,
    );
    var removeNnaAction =
        findCodeActionLiteral(
          codeActions,
          title: "Remove the '!'",
          kind: CodeActionKind('quickfix.remove.nonNullAssertion'),
        )!;

    // Ensure the action is for the diagnostic on the second bang which was
    // closest to the range requested.
    var diagnostics = removeNnaAction.diagnostics;
    var secondBangPos = positionFromOffset(code.code.indexOf('!);'), code.code);
    expect(diagnostics, hasLength(1));
    var diagStart = diagnostics!.first.range.start;
    expect(diagStart, equals(secondBangPos));
  }

  Future<void> test_noDuplicates_sameFix() async {
    var code = TestCode.parse('''
var a = [Test, Test, Te[!!]st];
''');

    createFile(testFilePath, code.code);
    await initializeServer();

    var codeActions = await getCodeActions(
      testFileUri,
      range: code.range.range,
    );
    var createClassAction =
        findCodeActionLiteral(
          codeActions,
          title: "Create class 'Test'",
          kind: CodeActionKind('quickfix.create.class.uppercase'),
        )!;

    expect(createClassAction.diagnostics, hasLength(3));
  }

  Future<void> test_noDuplicates_withDocumentChangesSupport() async {
    var code = TestCode.parse('''
var a = [Test, Test, Te[!!]st];
''');

    createFile(testFilePath, code.code);
    await initializeServer();

    var codeActions = await getCodeActions(
      testFileUri,
      range: code.range.range,
    );
    var createClassActions =
        findCodeActionLiteral(
          codeActions,
          title: "Create class 'Test'",
          kind: CodeActionKind('quickfix.create.class.uppercase'),
        )!;

    expect(createClassActions.diagnostics, hasLength(3));
  }

  Future<void> test_organizeImportsFix_namedOrganizeImports() async {
    registerLintRules();
    createFile(analysisOptionsPath, '''
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

    await verifyCodeActionLiteralEdits(
      content,
      expectedContent,
      kind: CodeActionKind('quickfix.organize.imports'),
      title: 'Organize Imports',
    );
  }

  Future<void> test_outsideRoot() async {
    var otherFilePath = pathContext.normalize(
      pathContext.join(projectFolderPath, '..', 'otherProject', 'foo.dart'),
    );
    var otherFileUri = pathContext.toUri(otherFilePath);
    createFile(otherFilePath, 'bad code to create error');
    await initializeServer();

    var codeActions = await getCodeActions(
      otherFileUri,
      position: startOfDocPos,
    );
    expect(codeActions, isEmpty);
  }

  Future<void> test_pubspec() async {
    const content = '^';

    var expectedContent = '''
name: $testPackageName
''';

    await verifyCodeActionLiteralEdits(
      filePath: pubspecFilePath,
      content,
      expectedContent,
      kind: CodeActionKind('quickfix.add.name'),
      title: "Add 'name' key",
    );
  }

  Future<void> test_snippets() async {
    setSnippetTextEditSupport();

    const content = '''
abstract class A {
  void m();
}

class ^B extends A {}
''';

    const expectedContent = r'''
abstract class A {
  void m();
}

class B extends A {
  @override
  void m() {
    // TODO: implement m$0
  }
}
''';

    await verifyCodeActionLiteralEdits(
      content,
      expectedContent,
      kind: CodeActionKind('quickfix.create.missingOverrides'),
      title: 'Create 1 missing override',
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

  ${1:void} ${2:c}(${3:Function(dynamic cell)} ${4:param0}) {}
}
''';

    setSnippetTextEditSupport();
    await verifyCodeActionLiteralEdits(
      content,
      expectedContent,
      kind: CodeActionKind('quickfix.create.method'),
      title: "Create method 'c'",
    );
  }

  /// Ensure braces aren't over-escaped in snippet choices.
  /// https://github.com/dart-lang/sdk/issues/54403
  Future<void> test_snippets_createMissingOverrides_recordBraces() async {
    const content = '''
abstract class A {
  void m(Iterable<({int a, int b})> r);
}

class ^B extends A {}
''';

    const expectedContent = r'''
abstract class A {
  void m(Iterable<({int a, int b})> r);
}

class B extends A {
  @override
  void m(${1|Iterable<({int a\, int b})>,Object|} ${2:r}) {
    // TODO: implement m$0
  }
}
''';

    setSnippetTextEditSupport();
    await verifyCodeActionLiteralEdits(
      content,
      expectedContent,
      kind: CodeActionKind('quickfix.create.missingOverrides'),
      title: 'Create 1 missing override',
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
    await verifyCodeActionLiteralEdits(
      content,
      expectedContent,
      kind: CodeActionKind('quickfix.create.localVariable'),
      title: "Create local variable 'test'",
    );
  }

  /// The non-standard snippets we supported are only supported for
  /// [CodeActionLiteral]s and not for [Command]s (which go via
  /// workspace/applyEdit) so even if enabled, they should not be returned.
  Future<void> test_snippets_unsupportedForCommands() async {
    setSupportedCodeActionKinds(null); // no codeActionLiteralSupport
    setSnippetTextEditSupport(); // will be ignored

    const content = '''
abstract class A {
  void m();
}

class ^B extends A {}
''';

    // No $0 placeholder in this content (unlike in `test_snippets`).
    const expectedContent = r'''
abstract class A {
  void m();
}

class B extends A {
  @override
  void m() {
    // TODO: implement m
  }
}
''';

    await verifyCommandCodeActionEdits(
      content,
      expectedContent,
      command: Commands.applyCodeAction,
      title: 'Create 1 missing override',
    );
  }

  void _enableLints(List<String> lintNames) {
    registerLintRules();
    var lintsYaml = lintNames.map((name) => '    - $name\n').join();
    createFile(analysisOptionsPath, '''
linter:
  rules:
$lintsYaml
''');
  }
}

/// A version of `camel_case_types` that is deprecated.
class _DeprecatedCamelCaseTypes extends LintRule {
  static const LintCode code = LintCode(
    'camel_case_types',
    "The type name '{0}' isn't an UpperCamelCase identifier.",
    correctionMessage:
        'Try changing the name to follow the UpperCamelCase style.',
    hasPublishedDocs: true,
  );

  _DeprecatedCamelCaseTypes()
    : super(
        name: 'camel_case_types',
        state: RuleState.deprecated(),
        description: '',
      );

  @override
  DiagnosticCode get diagnosticCode => code;
}
