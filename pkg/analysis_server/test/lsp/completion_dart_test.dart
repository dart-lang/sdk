// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/handlers/handler_completion.dart';
import 'package:analysis_server/src/services/snippets/dart/class_declaration.dart';
import 'package:analysis_server/src/services/snippets/dart/do_statement.dart';
import 'package:analysis_server/src/services/snippets/dart/flutter_stateful_widget.dart';
import 'package:analysis_server/src/services/snippets/dart/flutter_stateful_widget_with_animation.dart';
import 'package:analysis_server/src/services/snippets/dart/flutter_stateless_widget.dart';
import 'package:analysis_server/src/services/snippets/dart/for_in_statement.dart';
import 'package:analysis_server/src/services/snippets/dart/for_statement.dart';
import 'package:analysis_server/src/services/snippets/dart/function_declaration.dart';
import 'package:analysis_server/src/services/snippets/dart/if_else_statement.dart';
import 'package:analysis_server/src/services/snippets/dart/if_statement.dart';
import 'package:analysis_server/src/services/snippets/dart/main_function.dart';
import 'package:analysis_server/src/services/snippets/dart/switch_statement.dart';
import 'package:analysis_server/src/services/snippets/dart/test_definition.dart';
import 'package:analysis_server/src/services/snippets/dart/test_group_definition.dart';
import 'package:analysis_server/src/services/snippets/dart/try_catch_statement.dart';
import 'package:analysis_server/src/services/snippets/dart/while_statement.dart';
import 'package:analyzer/src/test_utilities/test_code_format.dart';
import 'package:collection/collection.dart';
import 'package:linter/src/lint_names.dart';
import 'package:linter/src/rules.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../tool/lsp_spec/matchers.dart';
import '../utils/test_code_extensions.dart';
import 'completion.dart';
import 'server_abstract.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CompletionDocumentationResolutionTest);
    defineReflectiveTests(CompletionLabelDetailsTest);
    defineReflectiveTests(CompletionTest);
    defineReflectiveTests(DartSnippetCompletionTest);
    defineReflectiveTests(FlutterSnippetCompletionTest);
  });
}

typedef ExpectedLabel =
    ({
      // Main label of the completion (eg 'myFunc')
      String? label,
      // The detail part of the label (shown after label, usually truncated signature)
      String? labelDetail,
      // Additional label description (usually the auto-import URI)
      String? labelDescription,
      // Filter text (usually same as label, never with `()` or other suffixes)
      String? filterText,
      // Main detail (shown in popout, usually full signature)
      String? detail,
      // Sometimes resolved detail has a prefix added (eg. "Auto-import from").
      String? resolvedDetailPrefix,
    });

abstract class AbstractCompletionTest extends AbstractLspAnalysisServerTest
    with CompletionTestMixin {
  AbstractCompletionTest() {
    defaultInitializationOptions = {
      // Default to a high budget for tests because everything is cold and
      // may take longer to return.
      'completionBudgetMilliseconds': 50000,
    };
  }

  void expectDocumentation(CompletionItem completion, Matcher matcher) {
    var docs = completion.documentation?.map(
      (markup) => markup.value,
      (string) => string,
    );
    expect(docs, matcher);
  }

  @override
  void setUp() {
    super.setUp();

    // Completion tests have incomplete code.
    failTestOnErrorDiagnostic = false;

    setApplyEditSupport();
  }

  void _enableLints(List<String> lintNames) {
    registerLintRules();
    var lintsYaml = lintNames.map((name) => '    - $name\n').join();
    newFile(analysisOptionsPath, '''
linter:
  rules:
$lintsYaml
''');
  }
}

@reflectiveTest
class CompletionDocumentationResolutionTest extends AbstractCompletionTest {
  late String content;
  late final code = TestCode.parse(content);

  Future<CompletionItem> getCompletionItem(String label) async {
    var completions = await getCompletion(mainFileUri, code.position.position);
    return completions.singleWhere((c) => c.label == label);
  }

  Future<void> initializeServer() async {
    await initialize();
    await openFile(mainFileUri, code.code);
    await initialAnalysis;
  }

  Future<void> test_class() async {
    newFile(join(projectFolderPath, 'my_class.dart'), '''
/// Class.
class MyClass {}
''');

    content = '''
void f() {
  MyClass^
}
''';

    await initializeServer();

    var completion = await getCompletionItem('MyClass');
    expectDocumentation(completion, isNull);

    var resolved = await resolveCompletion(completion);
    expectDocumentation(resolved, contains('Class.'));
  }

  Future<void> test_class_constructor() async {
    newFile(join(projectFolderPath, 'my_class.dart'), '''
class MyClass {
  /// Constructor.
  MyClass();
}
''');

    content = '''
void f() {
  MyClass^
}
''';

    await initializeServer();

    var completion = await getCompletionItem('MyClass()');
    expectDocumentation(completion, isNull);

    var resolved = await resolveCompletion(completion);
    expectDocumentation(resolved, contains('Constructor.'));
  }

  Future<void> test_class_constructor_not_duplicated() async {
    // https://github.com/dart-lang/sdk/issues/60188
    content = '''
class C {
  /// This is a constructor.
  C.c1();
}

void g(void Function() _) {}

void f() {
  g(C.^c1);
}
''';
    await initializeServer();

    var completion = await getCompletionItem('c1()');
    expectDocumentation(completion, equals('This is a constructor.'));
  }

  Future<void> test_class_constructorNamed() async {
    newFile(join(projectFolderPath, 'my_class.dart'), '''
class MyClass {
  /// Named Constructor.
  MyClass.named();
}
''');

    content = '''
void f() {
  MyClass^
}
''';

    await initializeServer();

    var completion = await getCompletionItem('MyClass.named()');
    expectDocumentation(completion, isNull);

    var resolved = await resolveCompletion(completion);
    expectDocumentation(resolved, contains('Named Constructor.'));
  }

  Future<void> test_enum() async {
    newFile(join(projectFolderPath, 'my_enum.dart'), '''
/// Enum.
enum MyEnum {}
''');

    content = '''
void f() {
  MyEnum^
}
''';

    await initializeServer();

    var completion = await getCompletionItem('MyEnum');
    expectDocumentation(completion, isNull);

    var resolved = await resolveCompletion(completion);
    expectDocumentation(resolved, contains('Enum.'));
  }

  Future<void> test_enum_member() async {
    // Function used to provide type context in main file without importing
    // the enum.
    newFile(join(projectFolderPath, 'lib', 'func.dart'), '''
import 'my_enum.dart';
void enumFunc(MyEnum e) {}
''');

    newFile(join(projectFolderPath, 'lib', 'my_enum.dart'), '''
enum MyEnum {
  /// Enum Member.
  one,
}
''');

    content = '''
import 'func.dart';
void f() {
  enumFunc(MyEnum^)
}
''';

    await initializeServer();

    var completion = await getCompletionItem('MyEnum.one');
    expectDocumentation(completion, isNull);

    var resolved = await resolveCompletion(completion);
    expectDocumentation(resolved, contains('Enum Member.'));
  }

  Future<void> test_innerPatternKeyword() async {
    content = '''
class A {
  A([this.value]);
  A? value;
}

void main() {
  final value = A(A(A()));
  if (value case A(value: A(:^))) {}
}
''';
    await initializeServer();

    var code = TestCode.parse(content);
    var completion = await getCompletionItem('value');
    expect(completion, isNotNull);

    // Resolve the completion item to get its edits.
    var resolved = await resolveCompletion(completion);

    // Apply all current-document edits.
    var newContent = applyTextEdits(code.code, [
      toTextEdit(resolved.textEdit!),
    ]);
    expect(
      newContent,
      equals('''
class A {
  A([this.value]);
  A? value;
}

void main() {
  final value = A(A(A()));
  if (value case A(value: A(:var value))) {}
}
'''),
    );
  }

  /// We should not show `var`, `final` or the member type on the display text.
  Future<void> test_pattern_member_name_only() async {
    content = '''
void f(({int name, int other}) r) {
  if (r case (:^)) {}
}
''';
    await initializeServer();

    var code = TestCode.parse(content);
    var completion = await getCompletionItem('name');
    expect(completion, isNotNull);

    // Resolve the completion item to get its edits.
    var resolved = await resolveCompletion(completion);

    // Apply all current-document edits.
    var newContent = applyTextEdits(code.code, [
      toTextEdit(resolved.textEdit!),
    ]);
    expect(
      newContent,
      equals('''
void f(({int name, int other}) r) {
  if (r case (:var name)) {}
}
'''),
    );
  }

  @FailingTest(issue: 'https://github.com/dart-lang/sdk/issues/60751')
  Future<void> test_pattern_member_type_with_hide_combinator_and_lint() async {
    newFile(join(projectFolderPath, 'lib', 'my_types.dart'), '''
class MyType {}
class MyType2 {}
typedef Other = ({MyType name,});
''');
    content = '''
import 'my_types.dart' hide MyType, MyType2;

void f(Other r) {
  if (r case (:^)) {}
}
''';
    _enableLints([LintNames.always_specify_types]);
    await initializeServer();
    var code = TestCode.parse(content);
    var completion = await getCompletionItem('name');
    expect(completion, isNotNull);
    var resolved = await resolveCompletion(completion);
    var newContent = applyTextEdits(code.code, [
      toTextEdit(resolved.textEdit!),
    ]);
    expect(
      newContent,
      equals('''
import 'my_types.dart' hide MyType2;

void f(Other r) {
  if (r case (:MyType name)) {}
}
'''),
    );
  }

  Future<void> test_pattern_member_type_with_new_import_and_lint() async {
    newFile(join(projectFolderPath, 'lib', 'my_types.dart'), '''
class MyType {}
''');
    newFile(join(projectFolderPath, 'lib', 'other.dart'), '''
import 'my_types.dart';
typedef Other = ({MyType name,});
''');
    content = '''
import 'other.dart';

void f(Other r) {
  if (r case (:^)) {}
}
''';
    _enableLints([LintNames.always_specify_types]);
    await initializeServer();
    var code = TestCode.parse(content);
    var completion = await getCompletionItem('name');
    var resolved = await resolveCompletion(completion);
    var newContent = applyTextEdits(
      code.code,
      [
        toTextEdit(resolved.textEdit!),
      ].followedBy(resolved.additionalTextEdits!).toList(),
    );
    expect(
      newContent,
      equals('''
import 'package:test/my_types.dart';

import 'other.dart';

void f(Other r) {
  if (r case (:MyType name)) {}
}
'''),
    );
  }

  @FailingTest(issue: 'https://github.com/dart-lang/sdk/issues/60751')
  Future<void> test_pattern_member_type_with_show_combinator_and_lint() async {
    newFile(join(projectFolderPath, 'lib', 'my_types.dart'), '''
class MyType {}
typedef Other = ({MyType name,});
''');
    content = '''
import 'my_types.dart' show Other;

void f(Other r) {
  if (r case (:^)) {}
}
''';
    _enableLints([LintNames.always_specify_types]);
    await initializeServer();
    var code = TestCode.parse(content);
    var completion = await getCompletionItem('name');
    expect(completion, isNotNull);
    var resolved = await resolveCompletion(completion);
    var newContent = applyTextEdits(code.code, [
      toTextEdit(resolved.textEdit!),
    ]);
    expect(
      newContent,
      equals('''
import 'my_types.dart' show Other, MyType;

void f(Other r) {
  if (r case (:MyType name)) {}
}
'''),
    );
  }

  Future<void> test_pattern_type_with_aliased_import_and_lint() async {
    newFile(join(projectFolderPath, 'lib', 'my_types.dart'), '''
class MyType {}
typedef Other = ({MyType name,});
''');
    content = '''
import 'my_types.dart' as t;

void f(t.Other r) {
  if (r case (:^)) {}
}
''';
    _enableLints([LintNames.always_specify_types]);
    await initializeServer();
    var code = TestCode.parse(content);
    var completion = await getCompletionItem('name');
    expect(completion, isNotNull);
    var resolved = await resolveCompletion(completion);
    var newContent = applyTextEdits(code.code, [
      toTextEdit(resolved.textEdit!),
    ]);
    expect(
      newContent,
      equals('''
import 'my_types.dart' as t;

void f(t.Other r) {
  if (r case (:t.MyType name)) {}
}
'''),
    );
  }
}

@reflectiveTest
class CompletionLabelDetailsTest extends AbstractCompletionTest {
  late String fileAPath;

  /// A helper for [expectLabels] that only verifies a single label.
  Future<void> expectLabel(
    String content, {
    Uri? completionFileUri,
    required String? label,
    required String? labelDetail,
    required String? labelDescription,
    required String? filterText,
    required String? detail,
    String? resolvedDetailPrefix,
  }) {
    return expectLabels(
      content,
      completionFileUri: completionFileUri,
      labels: [
        (
          label: label,
          labelDetail: labelDetail,
          labelDescription: labelDescription,
          filterText: filterText,
          detail: detail,
          resolvedDetailPrefix: resolvedDetailPrefix,
        ),
      ],
    );
  }

  /// Expect that invoking completion at the position marked in [content] in
  /// [completionFileUri] provides completions with the expected [labels].
  Future<void> expectLabels(
    String content, {
    Uri? completionFileUri,
    required List<ExpectedLabel> labels,
  }) async {
    completionFileUri ??= mainFileUri;

    var code = TestCode.parse(content);
    await initialize();
    await openFile(completionFileUri, code.code);

    var completions = await getCompletion(
      completionFileUri,
      code.position.position,
    );

    for (var (
          :label,
          :labelDetail,
          :labelDescription,
          :filterText,
          :detail,
          :resolvedDetailPrefix,
        )
        in labels) {
      var completion = completions.singleWhereOrNull(
        (c) => c.label == label && c.detail == detail,
      );
      if (completion == null) {
        fail(
          'Did not find completion "$label" with detail "$detail" in completion results:'
          '\n    ${completions.map((c) => '${c.label} (${c.detail})').join('\n    ')}',
        );
      }

      expect(completion.filterText, filterText);

      // If both fields are expected to be null, expect the whole object to be
      // null (to reduce payload size).
      if (labelDetail == null && labelDescription == null) {
        expect(completion.labelDetails, isNull);
      } else {
        var labelDetails = completion.labelDetails;
        if (labelDetails == null) {
          fail('Completion "$label" does not have labelDetails');
        }
        expect(labelDetails.detail, labelDetail);
        expect(labelDetails.description, labelDescription);
      }

      // Verify that resolution does not modify these results.
      var resolved = await resolveCompletion(completion);
      expect(resolved.label, completion.label);
      expect(resolved.filterText, completion.filterText);
      expect(
        resolved.detail,
        resolvedDetailPrefix != null
            ? '$resolvedDetailPrefix${completion.detail ?? ''}'
            : completion.detail,
      );
      expect(resolved.labelDetails?.detail, completion.labelDetails?.detail);
      expect(
        resolved.labelDetails?.description,
        completion.labelDetails?.description,
      );
    }
  }

  @override
  void setUp() {
    super.setUp();
    fileAPath = join(projectFolderPath, 'lib', 'a.dart');

    // TODO(dantup): Consider enabling this by default for [CompletionTest] and
    //  changing this class to test support without it (or, subclassing
    //  CompletionTest and inferring the label when labelDetails are not
    //  supported).
    setCompletionItemLabelDetailsSupport();
  }

  Future<void> test_combinator_function() async {
    var content = '''
import 'dart:math' show min^
''';

    await expectLabel(
      content,
      label: 'min',
      labelDetail: ' (…) → T',
      labelDescription: null,
      filterText: null,
      detail: '(T a, T b) → T',
    );
  }

  Future<void> test_constructor_argument() async {
    var content = '''
var a = Foo(^);

class Foo {
  final int value;
  const Foo({required this.value});
}
''';

    await expectLabel(
      content,
      label: 'value:',
      labelDetail: ' int',
      labelDescription: null,
      filterText: null,
      detail: 'int',
    );
  }

  Future<void> test_constructor_factory_argument() async {
    var content = '''
var a = Foo(^);

class Foo {
  final int value;
  const Foo._({required this.value});
  const factory Foo({required int value}) = Foo._;
}
''';

    await expectLabel(
      content,
      label: 'value:',
      labelDetail: ' int',
      labelDescription: null,
      filterText: null,
      detail: 'int',
    );
  }

  Future<void> test_imported_function_returnType_args() async {
    newFile(fileAPath, '''
String a(String a, {String b}) {}
''');
    var content = '''
import 'a.dart';
void f() {
  a^
}
''';

    await expectLabel(
      content,
      label: 'a',
      labelDetail: '(…) → String',
      labelDescription: null,
      filterText: null,
      detail: '(String a, {String b}) → String',
    );
  }

  Future<void> test_imported_function_returnType_noArgs() async {
    newFile(fileAPath, '''
String a() {}
''');
    var content = '''
import 'a.dart';
String f() {
  a^
}
''';

    await expectLabel(
      content,
      label: 'a',
      labelDetail: '() → String',
      labelDescription: null,
      filterText: null,
      detail: '() → String',
    );
  }

  Future<void> test_imported_function_void_args() async {
    newFile(fileAPath, '''
void a(String a, {String b}) {}
''');
    var content = '''
import 'a.dart';
void f() {
  a^
}
''';

    await expectLabel(
      content,
      label: 'a',
      labelDetail: '(…) → void',
      labelDescription: null,
      filterText: null,
      detail: '(String a, {String b}) → void',
    );
  }

  Future<void> test_imported_function_void_noArgs() async {
    newFile(fileAPath, '''
void a() {}
''');
    var content = '''
import 'a.dart';
void f() {
  a^
}
''';

    await expectLabel(
      content,
      label: 'a',
      labelDetail: '() → void',
      labelDescription: null,
      filterText: null,
      detail: '() → void',
    );
  }

  Future<void> test_local_function_returnType_args() async {
    var content = '''
String f(String a, {String b}) {
  f^
}
''';
    await expectLabel(
      content,
      label: 'f',
      labelDetail: '(…) → String',
      labelDescription: null,
      filterText: null,
      detail: '(String a, {String b}) → String',
    );
  }

  Future<void> test_local_function_returnType_noArgs() async {
    var content = '''
String f() {
  f^
}
''';

    await expectLabel(
      content,
      label: 'f',
      labelDetail: '() → String',
      labelDescription: null,
      filterText: null,
      detail: '() → String',
    );
  }

  Future<void> test_local_function_void_args() async {
    var content = '''
void f(String a, {String b}) {
  f^
}
''';

    await expectLabel(
      content,
      label: 'f',
      labelDetail: '(…) → void',
      labelDescription: null,
      filterText: null,
      detail: '(String a, {String b}) → void',
    );
  }

  Future<void> test_local_function_void_noArgs() async {
    var content = '''
void f() {
  f^
}
''';

    await expectLabel(
      content,
      label: 'f',
      labelDetail: '() → void',
      labelDescription: null,
      filterText: null,
      detail: '() → void',
    );
  }

  Future<void> test_local_getter() async {
    var content = '''
String a => '';
void f() {
  a^
}
''';
    await expectLabel(
      content,
      label: 'a',
      labelDetail: '() → String',
      labelDescription: null,
      filterText: null,
      detail: '() → String',
    );
  }

  Future<void> test_local_getterAndSetter() async {
    var content = '''
set a(String value) {}
String get a => '';
void f() {
  a^
}
''';
    await expectLabel(
      content,
      label: 'a',
      labelDetail: ' String',
      labelDescription: null,
      filterText: null,
      detail: 'String',
    );
  }

  Future<void> test_local_override_annotation_equals() async {
    var content = '''
class Base {
}

class Derived extends Base {
  @over^
}
''';
    await expectLabel(
      content,
      label: 'override ==',
      labelDetail: '(…) → bool',
      labelDescription: null,
      filterText: null,
      detail: '(Object other) → bool',
    );
  }

  Future<void> test_local_override_annotation_method() async {
    var content = '''
class Base {
  String aa(String a) => '';
}

class Derived extends Base {
  @over^
}
''';
    await expectLabel(
      content,
      label: 'override aa',
      labelDetail: '(…) → String',
      labelDescription: null,
      filterText: null,
      detail: '(String a) → String',
    );
  }

  /// Ensure overrides for getters and setters can be distinguished.
  ///
  /// https://github.com/dart-lang/sdk/issues/59929
  Future<void> test_local_override_getterAndSetter() async {
    var content = '''
class A {
  int? value;
}

class B extends A {
  val^
}
''';
    await expectLabels(
      content,
      labels: [
        (
          label: 'override value',
          labelDetail: ' int? get',
          labelDescription: null,
          filterText: 'value',
          detail: 'int? get',
          resolvedDetailPrefix: null,
        ),
        (
          label: 'override value',
          labelDetail: ' set (int?)',
          labelDescription: null,
          filterText: 'value',
          detail: 'set (int?)',
          resolvedDetailPrefix: null,
        ),
      ],
    );
  }

  Future<void> test_local_override_name() async {
    var content = '''
class Base {
  String aa(String a) => '';
}

class Derived extends Base {
  a^
}
''';
    await expectLabel(
      content,
      label: 'override aa',
      labelDetail: '(…) → String',
      labelDescription: null,
      filterText: 'aa',
      detail: '(String a) → String',
    );
  }

  Future<void> test_local_setter() async {
    var content = '''
set a(String value) {}
void f() {
  a^
}
''';
    await expectLabel(
      content,
      label: 'a',
      labelDetail: ' String',
      labelDescription: null,
      filterText: null,
      detail: 'String',
    );
  }

  Future<void> test_notImported_function_returnType_args() async {
    newFile(fileAPath, '''
String a(String a, {String b}) {}
''');
    var content = '''
void f() {
  a^
}
''';

    await expectLabel(
      content,
      label: 'a',
      labelDetail: '(…) → String',
      labelDescription: 'package:test/a.dart',
      filterText: null,
      detail: '(String a, {String b}) → String',
      resolvedDetailPrefix: "Auto import from 'package:test/a.dart'\n\n",
    );
  }

  Future<void> test_notImported_function_returnType_noArgs() async {
    newFile(fileAPath, '''
String a() {}
''');
    var content = '''
String f() {
  a^
}
''';

    await expectLabel(
      content,
      label: 'a',
      labelDetail: '() → String',
      labelDescription: 'package:test/a.dart',
      filterText: null,
      detail: '() → String',
      resolvedDetailPrefix: "Auto import from 'package:test/a.dart'\n\n",
    );
  }

  Future<void> test_notImported_function_void_args() async {
    newFile(fileAPath, '''
void a(String a, {String b}) {}
''');
    var content = '''
void f() {
  a^
}
''';

    await expectLabel(
      content,
      label: 'a',
      labelDetail: '(…) → void',
      labelDescription: 'package:test/a.dart',
      filterText: null,
      detail: '(String a, {String b}) → void',
      resolvedDetailPrefix: "Auto import from 'package:test/a.dart'\n\n",
    );
  }

  Future<void> test_notImported_function_void_noArgs() async {
    newFile(fileAPath, '''
void a() {}
''');
    var content = '''
void f() {
  a^
}
''';

    await expectLabel(
      content,
      label: 'a',
      labelDetail: '() → void',
      labelDescription: 'package:test/a.dart',
      filterText: null,
      detail: '() → void',
      resolvedDetailPrefix: "Auto import from 'package:test/a.dart'\n\n",
    );
  }

  Future<void> test_notImported_outsideLib_relativePath() async {
    var testMainFilePath = join(projectFolderPath, 'test', 'main.dart');
    var testFileAPath = join(projectFolderPath, 'test', 'a.dart');

    newFile(testFileAPath, '''
void a(String a, {String b}) {}
''');
    var content = '''
void f() {
  a^
}
''';

    await expectLabel(
      content,
      completionFileUri: toUri(testMainFilePath),
      label: 'a',
      labelDetail: '(…) → void',
      labelDescription: 'a.dart',
      filterText: null,
      detail: '(String a, {String b}) → void',
      resolvedDetailPrefix: "Auto import from 'a.dart'\n\n",
    );
  }

  Future<void> test_nullNotEmpty() async {
    var content = '''
bool a = ^
''';

    /// expectLabel verifies the whole labelDetails object is null if
    /// both fields are expected to be null.
    await expectLabel(
      content,
      label: 'true',
      labelDetail: null,
      labelDescription: null,
      filterText: null,
      detail: null,
    );
  }

  Future<void> test_record() async {
    var content = r'''
void f((int, int) record) {
  record.$^
}
''';

    await expectLabel(
      content,
      label: r'$1',
      labelDetail: ' int',
      labelDescription: null,
      filterText: null,
      detail: 'int',
    );
  }

  Future<void> test_variable() async {
    var content = r'''
void f(int variable) {
  varia^
}
''';

    await expectLabel(
      content,
      label: 'variable',
      labelDetail: ' int',
      labelDescription: null,
      filterText: null,
      detail: 'int',
    );
  }
}

@reflectiveTest
class CompletionTest extends AbstractCompletionTest {
  /// Checks whether the correct types of documentation are returned for
  /// completions based on [preference].
  Future<void> assertDocumentation(
    String? preference, {
    required bool includesSummary,
    required bool includesFull,
  }) async {
    var content = '''
/// Summary.
///
/// Full.
class A {}

A^
''';

    await provideConfig(initialize, {
      if (preference != null) 'documentation': preference,
    });
    var code = TestCode.parse(content);
    await openFile(mainFileUri, code.code);
    await initialAnalysis;
    var res = await getCompletion(mainFileUri, code.position.position);
    var completion = res.singleWhere((c) => c.label == 'A');

    if (includesSummary) {
      expectDocumentation(completion, contains('Summary.'));
    } else {
      expectDocumentation(completion, isNot(contains('Summary.')));
    }

    if (includesFull) {
      expectDocumentation(completion, contains('Full.'));
    } else {
      expectDocumentation(completion, isNot(contains('Full.')));
    }
  }

  /// Checks whether the correct types of documentation are returned during
  /// `completionItem/resolve` based on [preference].
  Future<void> assertResolvedDocumentation(
    String? preference, {
    required bool includesSummary,
    required bool includesFull,
  }) async {
    newFile(join(projectFolderPath, 'other_file.dart'), '''
      /// Summary.
      ///
      /// Full.
      class InOtherFile {}
''');

    var content = '''
void f() {
  InOtherF^
}
''';

    await provideConfig(initialize, {
      if (preference != null) 'documentation': preference,
    });
    var code = TestCode.parse(content);
    await openFile(mainFileUri, code.code);
    await initialAnalysis;
    var res = await getCompletion(mainFileUri, code.position.position);
    var completion = res.singleWhere((c) => c.label == 'InOtherFile');

    // Expect no docs in original response and correct type of docs added
    // during resolve.
    expectDocumentation(completion, isNull);
    var resolved = await resolveCompletion(completion);

    if (includesSummary) {
      expectDocumentation(resolved, contains('Summary.'));
    } else {
      expectDocumentation(resolved, isNot(contains('Summary.')));
    }

    if (includesFull) {
      expectDocumentation(resolved, contains('Full.'));
    } else {
      expectDocumentation(resolved, isNot(contains('Full.')));
    }
  }

  Future<void> checkCompleteFunctionCallInsertText(
    String content,
    String completion, {
    required String? editText,
    InsertTextFormat? insertTextFormat,
  }) async {
    setCompletionItemSnippetSupport();
    await provideConfig(initialize, {'completeFunctionCalls': true});
    var code = TestCode.parse(content);
    await openFile(mainFileUri, code.code);
    var res = await getCompletion(mainFileUri, code.position.position);
    var item = res.singleWhere(
      (c) => c.label == completion,
      orElse:
          () =>
              throw 'Did not find $completion in ${res.map((r) => r.label).toList()}',
    );

    expect(item.insertTextFormat, equals(insertTextFormat));
    // We always expect `insertText` to be `null` now, as we always use
    // `textEdit`.
    expect(item.insertText, isNull);

    // And the expected text should be in the `textEdit`.
    var textEdit = toTextEdit(item.textEdit!);
    expect(textEdit.newText, equals(editText));
    expect(textEdit.range, equals(code.range.range));
  }

  void expectAutoImportCompletion(List<CompletionItem> items, String file) {
    expect(
      items.singleWhereOrNull(
        (c) => c.detail?.contains("Auto import from '$file'") ?? false,
      ),
      isNotNull,
    );
  }

  /// Verifies a color completion with text [label] for the code [content] that
  /// includes a prefix for [colorHex] in the description.
  Future<void> expectColorCompletion(
    String content,
    String label,
    String colorHex,
  ) async {
    await initialize();
    var code = TestCode.parse(content);
    await openFile(mainFileUri, code.code);
    var res = await getCompletion(mainFileUri, code.position.position);
    var completion = res.singleWhere((c) => c.label == label);

    // Verify correct kind for color preview.
    expect(completion.kind, CompletionItemKind.Color);

    // Verify the docs are either entirely the hex code, or end with it.
    // VS Code's regex only allows the hex code at the start or end to show the
    // preview.
    var docs = completion.documentation?.map(
      (markup) => markup.value,
      (string) => string,
    );
    expect(docs, anyOf(equals(colorHex), endsWith('\n\n$colorHex')));
  }

  /// Expect [item] to use the default edit range, inserting the value [text].
  void expectUsesDefaultEditRange(CompletionItem item, String text) {
    expect(item.textEditText ?? item.label, text);
    expect(item.insertText, isNull);
    expect(item.textEdit, isNull);
  }

  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfig(flutter: true);
  }

  Future<void> test_annotation_beforeMember() async {
    var content = '''
class B {
  @^
  int a = 1;
}
''';

    await initialize();
    var code = TestCode.parse(content);
    await openFile(mainFileUri, code.code);
    var completions = await getCompletion(mainFileUri, code.position.position);
    var labels = completions.map((c) => c.label).toList();
    expect(labels, contains('override'));
    expect(labels, contains('deprecated'));
    expect(labels, contains('Deprecated(…)'));
  }

  Future<void> test_annotation_endOfClass() async {
    var content = '''
class B {
  @^
}
''';

    await initialize();
    var code = TestCode.parse(content);
    await openFile(mainFileUri, code.code);
    var completions = await getCompletion(mainFileUri, code.position.position);
    var labels = completions.map((c) => c.label).toList();
    expect(labels, contains('override'));
    expect(labels, contains('deprecated'));
    expect(labels, contains('Deprecated(…)'));
  }

  Future<void> test_closure() async {
    var content = '''
void f({void Function(int a, String b) closure}) {}

void g() {
  f(closure: ^);
}
''';

    var expectedContent = '''
void f({void Function(int a, String b) closure}) {}

void g() {
  f(closure: (a, b) => ^,);
}
''';

    await verifyCompletions(
      mainFileUri,
      content,
      expectCompletions: ['(a, b) {}', '(a, b) =>'],
      applyEditsFor: '(a, b) =>',
      expectedContent: expectedContent,
    );
  }

  Future<void> test_closure_requiredNamed() async {
    var content = '''
void f({void Function({int a, required String b}) closure}) {}

void g() {
  f(closure: ^);
}
''';

    var expectedContent = '''
void f({void Function({int a, required String b}) closure}) {}

void g() {
  f(closure: ({a, required b}) => ^,);
}
''';

    await verifyCompletions(
      mainFileUri,
      content,
      // Display text does not contain 'required' because it makes the
      // completion much longer, we just include it in the completion text.
      expectCompletions: ['({a, b}) {}', '({a, b}) =>'],
      applyEditsFor: '({a, b}) =>',
      expectedContent: expectedContent,
    );
  }

  Future<void> test_color_material() async {
    var content = '''
import 'package:flutter/material.dart';
var a = Colors.re^
''';

    await expectColorCompletion(content, 'red', '#FF0000');
  }

  Future<void> test_color_materialAccent() async {
    var content = '''
import 'package:flutter/material.dart';
var a = Colors.redAcce^
''';

    await expectColorCompletion(content, 'redAccent', '#FFAA00');
  }

  Future<void> test_comment() async {
    var content = '''
// foo ^
void f() {}
''';

    await initialize();
    var code = TestCode.parse(content);
    await openFile(mainFileUri, code.code);
    var res = await getCompletion(mainFileUri, code.position.position);
    expect(res, isEmpty);
  }

  Future<void> test_comment_endOfFile_withNewline() async {
    // Checks for a previous bug where invoking completion inside a comment
    // at the end of a file would return results.
    var content = '''
    // foo ^
''';

    await initialize();
    var code = TestCode.parse(content);
    await openFile(mainFileUri, code.code);
    var res = await getCompletion(mainFileUri, code.position.position);
    expect(res, isEmpty);
  }

  Future<void> test_comment_endOfFile_withoutNewline() async {
    // Checks for a previous bug where invoking completion inside a comment
    // at the very end of a file with no trailing newline would return results.
    var content = '// foo ^';

    await initialize();
    var code = TestCode.parse(content);
    await openFile(mainFileUri, code.code);
    var res = await getCompletion(mainFileUri, code.position.position);
    expect(res, isEmpty);
  }

  Future<void> test_commitCharacter_dynamicRegistration() async {
    var registrations = <Registration>[];
    // Provide empty config and collect dynamic registrations during
    // initialization.
    setDidChangeConfigurationDynamicRegistration();
    setAllSupportedTextDocumentDynamicRegistrations();
    await monitorDynamicRegistrations(
      registrations,
      () => provideConfig(initialize, {}),
    );

    Registration registration(Method method) =>
        registrationForDart(registrations, method);

    // By default, there should be no commit characters.
    var reg = registration(Method.textDocument_completion);
    var options = CompletionRegistrationOptions.fromJson(
      reg.registerOptions as Map<String, Object?>,
    );
    expect(options.allCommitCharacters, isNull);

    // When we change config, we should get a re-registration (unregister then
    // register) for completion which now includes the commit characters.
    await monitorDynamicReregistration(
      registrations,
      () => updateConfig({'previewCommitCharacters': true}),
    );
    reg = registration(Method.textDocument_completion);
    options = CompletionRegistrationOptions.fromJson(
      reg.registerOptions as Map<String, Object?>,
    );
    expect(options.allCommitCharacters, equals(dartCompletionCommitCharacters));
  }

  Future<void> test_completeFunctionCalls_constructor() async {
    await checkCompleteFunctionCallInsertText(
      '''
class Aaaaa {
  Aaaaa(int a);
}
void f(int aaa) {
  var a = new [!Aaa^!]
}
''',
      'Aaaaa(…)',
      insertTextFormat: InsertTextFormat.Snippet,
      editText: r'Aaaaa(${0:a})',
    );
  }

  Future<void> test_completeFunctionCalls_escapesDollarArgs() async {
    await checkCompleteFunctionCallInsertText(
      r'''
        int myFunction(String a$a, int b, {String c}) {
          var a = [!myFu^!]
        }
''',
      'myFunction(…)',
      insertTextFormat: InsertTextFormat.Snippet,
      // The dollar should have been escaped.
      editText: r'myFunction(${1:a\$a}, ${2:b})',
    );
  }

  Future<void> test_completeFunctionCalls_escapesDollarName() async {
    await checkCompleteFunctionCallInsertText(
      r'''
        int myFunc$tion(String a, int b, {String c}) {
          var a = [!myFu^!]
        }
''',
      r'myFunc$tion(…)',
      insertTextFormat: InsertTextFormat.Snippet,
      // The dollar should have been escaped.
      editText: r'myFunc\$tion(${1:a}, ${2:b})',
    );
  }

  Future<void> test_completeFunctionCalls_existingArgList_constructor() async {
    await checkCompleteFunctionCallInsertText(
      '''
class Aaaaa {
  Aaaaa(int a);
}
void f(int aaa) {
  var a = new [!Aaa^!]()
}
''',
      'Aaaaa(…)',
      editText: 'Aaaaa',
    );
  }

  Future<void> test_completeFunctionCalls_existingArgList_expression() async {
    await checkCompleteFunctionCallInsertText(
      '''
        int myFunction(String a, int b, {String c}) {
          var a = [!myFu^!]()
        }
''',
      'myFunction(…)',
      editText: 'myFunction',
    );
  }

  Future<void>
  test_completeFunctionCalls_existingArgList_member_noPrefix() async {
    // https://github.com/Dart-Code/Dart-Code/issues/3672
    await checkCompleteFunctionCallInsertText(
      '''
class Aaaaa {
  static foo(int a) {}
}
void f() {
  Aaaaa.[!^!]()
}
''',
      'foo(…)',
      editText: 'foo',
    );
  }

  Future<void>
  test_completeFunctionCalls_existingArgList_namedConstructor() async {
    await checkCompleteFunctionCallInsertText(
      '''
class Aaaaa {
  Aaaaa.foo(int a);
}
void f() {
  var a = new Aaaaa.[!foo^!]()
}
''',
      'foo(…)',
      editText: 'foo',
    );
  }

  Future<void> test_completeFunctionCalls_existingArgList_statement() async {
    await checkCompleteFunctionCallInsertText(
      '''
void f(int a) {
  [!f^!]()
}
''',
      'f(…)',
      editText: 'f',
    );
  }

  Future<void>
  test_completeFunctionCalls_existingArgList_suggestionSets() async {
    await checkCompleteFunctionCallInsertText(
      '''
void f(int a) {
  [!pri^!]()
}
''',
      'print(…)',
      editText: 'print',
    );
  }

  Future<void> test_completeFunctionCalls_existingPartialArgList() async {
    await checkCompleteFunctionCallInsertText(
      '''
class Aaaaa {
  Aaaaa(int a);
}
void f(int aaa) {
  var a = new [!Aaa^!](
}
''',
      'Aaaaa(…)',
      editText: 'Aaaaa',
    );
  }

  Future<void> test_completeFunctionCalls_expression() async {
    await checkCompleteFunctionCallInsertText(
      '''
int myFunction(String a, int b, {String c}) {
  var a = [!myFu^!]
}
''',
      'myFunction(…)',
      insertTextFormat: InsertTextFormat.Snippet,
      editText: r'myFunction(${1:a}, ${2:b})',
    );
  }

  Future<void> test_completeFunctionCalls_flutterSetState() async {
    // Flutter's setState method has special handling inside SuggestionBuilder
    // that already adds in a selection (which overlaps with completeFunctionCalls).
    // Ensure we don't end up with two sets of parens/placeholders in this case.
    var content = '''
import 'package:flutter/material.dart';

class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  @override
  Widget build(BuildContext context) {
    [!setSt^!]
    return const Placeholder();
  }
}
''';

    setCompletionItemSnippetSupport();
    await provideConfig(initialize, {'completeFunctionCalls': true});
    var code = TestCode.parse(content);
    await openFile(mainFileUri, code.code);
    var res = await getCompletion(mainFileUri, code.position.position);
    var item = res.singleWhere((c) => c.label.startsWith('setState('));

    // Usually the label would be "setState(…)" but here it's slightly different
    // to indicate a full statement is being inserted.
    expect(item.label, equals('setState(() {});'));

    // Ensure the snippet comes through in the expected format with the expected
    // placeholders.
    expect(item.insertTextFormat, equals(InsertTextFormat.Snippet));
    expect(item.insertText, isNull);
    var textEdit = toTextEdit(item.textEdit!);
    expect(textEdit.newText, 'setState(() {\n      \$0\n    });');
    expect(textEdit.range, equals(code.range.range));
  }

  Future<void> test_completeFunctionCalls_namedConstructor() async {
    await checkCompleteFunctionCallInsertText(
      '''
class Aaaaa {
  Aaaaa.foo(int a);
}
void f() {
  var a = new Aaaaa.[!foo^!]
}
''',
      'foo(…)',
      insertTextFormat: InsertTextFormat.Snippet,
      editText: r'foo(${0:a})',
    );
  }

  Future<void> test_completeFunctionCalls_noParameters() async {
    var content = '''
void myFunction() {}

void f() {
  [!myFu^!]
}
''';

    await checkCompleteFunctionCallInsertText(
      content,
      'myFunction()',
      editText: 'myFunction()',
      insertTextFormat: InsertTextFormat.Snippet,
    );
  }

  Future<void> test_completeFunctionCalls_optionalParameters() async {
    var content = '''
void myFunction({int a}) {}

void f() {
  [!myFu^!]
}
''';

    await checkCompleteFunctionCallInsertText(
      content,
      'myFunction(…)',
      // With optional params, there should still be parens/tab stop inside.
      editText: r'myFunction($0)',
      insertTextFormat: InsertTextFormat.Snippet,
    );
  }

  Future<void> test_completeFunctionCalls_requiredNamed() async {
    var content = '''
void myFunction(String a, int b, {required String c, String d = ''}) {}

void f() {
  [!myFu^!]
}
''';

    setCompletionItemSnippetSupport();
    await provideConfig(initialize, {'completeFunctionCalls': true});
    var code = TestCode.parse(content);
    await openFile(mainFileUri, code.code);
    var res = await getCompletion(mainFileUri, code.position.position);
    var item = res.singleWhere((c) => c.label == 'myFunction(…)');
    // Ensure the snippet comes through in the expected format with the expected
    // placeholders.
    expect(item.insertTextFormat, equals(InsertTextFormat.Snippet));
    expect(item.insertText, isNull);
    var textEdit = toTextEdit(item.textEdit!);
    expect(textEdit.newText, r'myFunction(${1:a}, ${2:b}, c: ${3:c})');
    expect(textEdit.range, equals(code.range.range));
  }

  Future<void> test_completeFunctionCalls_requiredNamed_suggestionSet() async {
    var otherFile = join(projectFolderPath, 'lib', 'other.dart');
    newFile(
      otherFile,
      "void myFunction(String a, int b, {required String c, String d = ''}) {}",
    );
    var content = '''
void f() {
  [!myFu^!]
}
''';

    setCompletionItemSnippetSupport();
    await provideConfig(initialize, {'completeFunctionCalls': true});
    var code = TestCode.parse(content);
    await openFile(mainFileUri, code.code);
    await initialAnalysis;
    var res = await getCompletion(mainFileUri, code.position.position);
    var item = res.singleWhere((c) => c.label == 'myFunction(…)');
    // Ensure the snippet comes through in the expected format with the expected
    // placeholders.
    expect(item.insertTextFormat, equals(InsertTextFormat.Snippet));
    expect(item.insertText, isNull);
    expect(item.textEdit, isNotNull);
    var originalTextEdit = item.textEdit;

    // Ensure the item can be resolved and retains the correct textEdit (since
    // textEdit may be recomputed during resolve).
    var resolved = await resolveCompletion(item);
    expect(resolved.insertText, isNull);
    expect(resolved.textEdit, originalTextEdit);
    var textEdit = toTextEdit(resolved.textEdit!);
    expect(textEdit.newText, r'myFunction(${1:a}, ${2:b}, c: ${3:c})');
    expect(textEdit.range, equals(code.range.range));
  }

  Future<void>
  test_completeFunctionCalls_resolve_producesCorrectEditWithoutInsertText() async {
    // Ensure our `resolve` call does not rely on the presence of `insertText`
    // to compute the correct edits. This is something we did incorrectly in the
    // past and broke with
    // https://github.com/dart-lang/sdk/commit/40e25ebad0bd008615b1c1d8021cb27839f00dcd
    // because the way these are combined in the VS Code LSP client means we are
    // not provided both `insertText` and `textEdit` back in the resolve call.
    //
    // Now, we never supply `insertText` and always use `textEdit`.
    var content = '''
final a = Stri^
''';

    /// Helper to verify a completion is as expected.
    void expectCorrectCompletion(CompletionItem item) {
      // Ensure this completion looks as we'd expect.
      expect(item.label, 'String.fromCharCode(…)');
      expect(item.insertText, isNull);
      expect(
        item.textEdit!.map((edit) => edit.newText, (edit) => edit.newText),
        r'String.fromCharCode(${0:charCode})',
      );
    }

    setCompletionItemSnippetSupport();
    await provideConfig(initialize, {'completeFunctionCalls': true});
    var code = TestCode.parse(content);
    await openFile(mainFileUri, code.code);
    await initialAnalysis;
    var res = await getCompletion(mainFileUri, code.position.position);

    var completion = res.singleWhere(
      (c) => c.label == 'String.fromCharCode(…)',
    );
    expectCorrectCompletion(completion);

    var resolved = await resolveCompletion(completion);
    expectCorrectCompletion(resolved);
  }

  Future<void> test_completeFunctionCalls_show() async {
    var content = '''
import 'dart:math' show mi^
''';

    setCompletionItemSnippetSupport();
    await provideConfig(initialize, {'completeFunctionCalls': true});
    var code = TestCode.parse(content);
    await openFile(mainFileUri, code.code);
    var res = await getCompletion(mainFileUri, code.position.position);
    var item = res.singleWhere((c) => c.label == 'min(…)');
    // The insert text should be a simple string with no parens/args and
    // no need for snippets.
    expect(item.insertTextFormat, isNull);
    expect(item.insertText, isNull);
    var textEdit = toTextEdit(item.textEdit!);
    expect(textEdit.newText, r'min');
  }

  Future<void> test_completeFunctionCalls_statement() async {
    await checkCompleteFunctionCallInsertText(
      '''
void f(int a) {
  [!f^!]
}
''',
      'f(…)',
      insertTextFormat: InsertTextFormat.Snippet,
      editText: r'f(${0:a})',
    );
  }

  Future<void> test_completeFunctionCalls_suggestionSets() async {
    await checkCompleteFunctionCallInsertText(
      '''
void f(int a) {
  [!pri^!]
}
''',
      'print(…)',
      insertTextFormat: InsertTextFormat.Snippet,
      editText: r'print(${0:object})',
    );
  }

  Future<void> test_completionKinds_default() async {
    newFile(join(projectFolderPath, 'file.dart'), '');
    newFolder(join(projectFolderPath, 'folder'));

    var content = "import '^';";

    await initialize();
    var code = TestCode.parse(content);
    await openFile(mainFileUri, code.code);
    var res = await getCompletion(mainFileUri, code.position.position);

    var file = res.singleWhere((c) => c.label == 'file.dart');
    var folder = res.singleWhere((c) => c.label == 'folder/');
    var builtin = res.singleWhere((c) => c.label == 'dart:core');
    // Default capabilities include File + Module but not Folder.
    expect(file.kind, equals(CompletionItemKind.File));
    // We fall back to Module if Folder isn't supported.
    expect(folder.kind, equals(CompletionItemKind.Module));
    expect(builtin.kind, equals(CompletionItemKind.Module));
  }

  Future<void> test_completionKinds_imports() async {
    // Tell the server we support some specific CompletionItemKinds.
    setCompletionItemKinds([
      CompletionItemKind.File,
      CompletionItemKind.Folder,
      CompletionItemKind.Module,
    ]);

    var content = "import '^';";

    await initialize();
    var code = TestCode.parse(content);
    await openFile(mainFileUri, code.code);
    var res = await getCompletion(mainFileUri, code.position.position);

    var file = res.singleWhere((c) => c.label == 'file.dart');
    var folder = res.singleWhere((c) => c.label == 'folder/');
    var builtin = res.singleWhere((c) => c.label == 'dart:core');
    expect(file.kind, equals(CompletionItemKind.File));
    expect(folder.kind, equals(CompletionItemKind.Folder));
    expect(builtin.kind, equals(CompletionItemKind.Module));
  }

  Future<void> test_completionKinds_supportedSubset() async {
    // Tell the server we only support the Field CompletionItemKind.
    setCompletionItemKinds([CompletionItemKind.Field]);

    var content = '''
class MyClass {
  String abcdefghij;
}

void f() {
  MyClass a;
  a.abc^
}
''';

    await initialize();
    var code = TestCode.parse(content);
    await openFile(mainFileUri, code.code);
    var res = await getCompletion(mainFileUri, code.position.position);
    var kinds = res.map((item) => item.kind).toList();

    // Ensure we only get nulls or Fields (the sample code contains Classes).
    expect(
      kinds,
      everyElement(anyOf(isNull, equals(CompletionItemKind.Field))),
    );
  }

  Future<void> test_completionTrigger_brace_block() async {
    // Brace should not trigger completion if a normal code block.
    var content = r'''
main () {^}
''';
    await _checkResultsForTriggerCharacters(content, ['{'], isEmpty);
  }

  Future<void>
  test_completionTrigger_brace_interpolatedStringExpression() async {
    // Brace should trigger completion if at the start of an interpolated expression
    var content = r'''
var a = '${^';
''';
    await _checkResultsForTriggerCharacters(content, [r'{'], isNotEmpty);
  }

  Future<void> test_completionTrigger_brace_rawString() async {
    // Brace should not trigger completion if in a raw string.
    var content = r'''
var a = r'${^';
''';
    await _checkResultsForTriggerCharacters(content, [r'{'], isEmpty);
  }

  Future<void> test_completionTrigger_brace_string() async {
    // Brace should not trigger completion if not at the start of an interpolated
    // expression.
    var content = r'''
var a = '{^';
''';
    await _checkResultsForTriggerCharacters(content, [r'{'], isEmpty);
  }

  Future<void> test_completionTrigger_colon_argument() async {
    // Colons should trigger completion after argument names.
    var content = r'''
void f({int? a}) {
  f(a:^
}
''';
    await _checkResultsForTriggerCharacters(content, [r':'], isNotEmpty);
  }

  Future<void> test_completionTrigger_colon_case() async {
    // Colons should not trigger completion in a switch case.
    var content = r'''
void f(int a) {
  switch (a) {
    case:^
  }
}
''';
    await _checkResultsForTriggerCharacters(content, [r':'], isEmpty);
  }

  Future<void> test_completionTrigger_colon_default() async {
    // Colons should not trigger completion in a switch case.
    var content = r'''
void f(int a) {
  switch (a) {
    default:^
  }
}
''';
    await _checkResultsForTriggerCharacters(content, [r':'], isEmpty);
  }

  Future<void> test_completionTrigger_colon_import() async {
    // Colons should trigger completion after argument names.
    var content = r'''
import 'package:^';
''';
    await _checkResultsForTriggerCharacters(content, [r':'], isNotEmpty);
  }

  Future<void> test_completionTrigger_quotes_endingString() async {
    // Completion triggered by a quote ending a string should not return results.
    var content = "foo(''^);";
    await _checkResultsForTriggerCharacters(content, ["'", '"'], isEmpty);
  }

  Future<void> test_completionTrigger_quotes_startingImport() async {
    // Completion triggered by a quote for import should return results.
    var content = "import '^'";
    await _checkResultsForTriggerCharacters(content, ["'", '"'], isNotEmpty);
  }

  Future<void> test_completionTrigger_quotes_startingString() async {
    // Completion triggered by a quote for normal string should not return results.
    var content = "foo('^');";
    await _checkResultsForTriggerCharacters(content, ["'", '"'], isEmpty);
  }

  Future<void> test_completionTrigger_quotes_terminatingImport() async {
    // Completion triggered by a quote ending an import should not return results.
    var content = "import ''^";
    await _checkResultsForTriggerCharacters(content, ["'", '"'], isEmpty);
  }

  Future<void> test_completionTrigger_slash_directivePath() async {
    // Slashes should trigger completion when typing in directive paths, eg.
    // after typing 'package:foo/' completion should give the next folder segments.
    var content = r'''
    import 'package:test/^';
''';
    await _checkResultsForTriggerCharacters(content, [r'/'], isNotEmpty);
  }

  Future<void> test_completionTrigger_slash_divide() async {
    // Slashes should not trigger completion when typing in a normal expression.
    var content = r'''
var a = 1 /^
''';
    await _checkResultsForTriggerCharacters(content, [r'/'], isEmpty);
  }

  Future<void> test_completionTriggerKinds_invalidParams() async {
    await initialize();

    var invalidTriggerKind = CompletionTriggerKind.fromJson(-1);
    var request = getCompletion(
      mainFileUri,
      Position(line: 0, character: 0),
      context: CompletionContext(
        triggerKind: invalidTriggerKind,
        triggerCharacter: 'A',
      ),
    );

    await expectLater(
      request,
      throwsA(isResponseError(ErrorCodes.InvalidParams)),
    );
  }

  Future<void> test_concurrentRequestsCancellation() async {
    // We expect a new completion request to cancel any in-flight request so
    // send multiple without awaiting, then check only the last one completes.
    var code = TestCode.empty;

    await initialize();
    await openFile(mainFileUri, code.code);
    var position = code.position.position;

    // Use a completer to force the requests to overlap without races.
    var completer = Completer<void>();
    CompletionHandler.delayAfterResolveForTests = completer.future;
    try {
      var responseFutures = [
        getCompletion(mainFileUri, position),
        getCompletion(mainFileUri, position),
        getCompletion(mainFileUri, position),
      ];

      var expectationFutures = [
        expectLater(
          responseFutures[0],
          throwsA(
            isResponseError(
              ErrorCodes.RequestCancelled,
              message: 'Another textDocument/completion request was started',
            ),
          ),
        ),
        expectLater(
          responseFutures[1],
          throwsA(
            isResponseError(
              ErrorCodes.RequestCancelled,
              message: 'Another textDocument/completion request was started',
            ),
          ),
        ),
        expectLater(responseFutures[2], completion(isNotEmpty)),
      ];

      // Ensure all requests started, then let them continue. This must be done
      // after the expectations are set up above, because otherwise if the
      // exceptions occur too quickly, they will be unhandled (whereas the
      // expectations attach error handlers to them).
      await pumpEventQueue(times: 50000);
      completer.complete();
      await Future.wait(expectationFutures);
    } finally {
      CompletionHandler.delayAfterResolveForTests = null;
    }
  }

  Future<void> test_dartDocPreference_full() async {
    await assertDocumentation(
      'full',
      includesSummary: true,
      includesFull: true,
    );
  }

  Future<void> test_dartDocPreference_none() async {
    await assertDocumentation(
      'none',
      includesSummary: false,
      includesFull: false,
    );
  }

  Future<void> test_dartDocPreference_summary() async {
    await assertDocumentation(
      'summary',
      includesSummary: true,
      includesFull: false,
    );
  }

  /// No preference should result in full docs.
  Future<void> test_dartDocPreference_unset() async {
    await assertDocumentation(null, includesSummary: true, includesFull: true);
  }

  Future<void> test_filterText_constructorParens() async {
    // Constructor parens should not be included in filterText.
    var content = '''
class MyClass {}

void f() {
  MyClass a = new MyCla^
}
''';

    await initialize();
    var code = TestCode.parse(content);
    await openFile(mainFileUri, code.code);
    var res = await getCompletion(mainFileUri, code.position.position);
    expect(res.any((c) => c.label == 'MyClass()'), isTrue);
    var item = res.singleWhere((c) => c.label == 'MyClass()');

    // filterText is set explicitly because it's not the same as label.
    expect(item.filterText, 'MyClass');

    // The text in the edit should also not contain the parens.
    var textEdit = toTextEdit(item.textEdit!);
    expect(textEdit.newText, 'MyClass');
  }

  Future<void> test_filterText_override_getter() async {
    // Some completions (eg. overrides) have additional text that is not part
    // of the label. That text should _not_ appear in filterText as it will
    // affect the editors relevance ranking as the user types.
    // https://github.com/dart-lang/sdk/issues/45157
    var content = '''
abstract class Person {
  String get name;
}

class Student extends Person {
  nam^
}
''';

    await initialize();
    var code = TestCode.parse(content);
    await openFile(mainFileUri, code.code);
    var res = await getCompletion(mainFileUri, code.position.position);
    var item = res.singleWhere((c) => c.label == 'override name => …');
    // filterText is set explicitly because it's not the same as label.
    expect(item.filterText, 'name');
  }

  Future<void> test_filterText_override_method() async {
    // Some completions (eg. overrides) have additional text that is not part
    // of the label. That text should _not_ appear in filterText as it will
    // affect the editors relevance ranking as the user types.
    // https://github.com/dart-lang/sdk/issues/45157
    var content = '''
abstract class Base {
  void myMethod() {};
}

class BaseImpl extends Base {
  myMet^
}
''';

    await initialize();
    var code = TestCode.parse(content);
    await openFile(mainFileUri, code.code);
    var res = await getCompletion(mainFileUri, code.position.position);
    var item = res.singleWhere((c) => c.label == 'override myMethod() { … }');
    // filterText is set explicitly because it's not the same as label.
    expect(item.filterText, 'myMethod');
  }

  /// Check that narrowing a type from String? to String in a subclass includes
  /// the correct narrowed type in the `detail` field.
  ///
  /// https://github.com/Dart-Code/Dart-Code/issues/4499
  Future<void> test_getter_narrowedBySubclass() async {
    var content = '''
void f(MyItem item) {
  item.na^
}

abstract class NullableName {
  String? get name;
}

abstract class NotNullableName implements NullableName {
  @override
  String get name;
}

abstract class MyItem implements NotNullableName, NullableName {}
''';

    await initialize();
    var code = TestCode.parse(content);
    await openFile(mainFileUri, code.code);
    var res = await getCompletion(mainFileUri, code.position.position);
    var name = res.singleWhere((c) => c.label == 'name');
    expect(name.detail, equals('String'));
  }

  Future<void> test_gettersAndSetters() async {
    var content = '''
class MyClass {
  String get justGetter => '';
  set justSetter(String value) {}
  String get getterAndSetter => '';
  set getterAndSetter(String value) {}
}

void f() {
  MyClass a;
  a.^
}
''';

    await initialize();
    var code = TestCode.parse(content);
    await openFile(mainFileUri, code.code);
    var res = await getCompletion(mainFileUri, code.position.position);
    var getter = res.singleWhere((c) => c.label == 'justGetter');
    var setter = res.singleWhere((c) => c.label == 'justSetter');
    var both = res.singleWhere((c) => c.label == 'getterAndSetter');
    expect(getter.detail, equals('String'));
    expect(setter.detail, equals('String'));
    expect(both.detail, equals('String'));
    for (var item in [getter, setter, both]) {
      expect(item.kind, equals(CompletionItemKind.Property));
    }
  }

  Future<void> test_import() async {
    var content = '''
import '^';
''';

    await initialize();
    var code = TestCode.parse(content);
    await openFile(mainFileUri, code.code);
    var res = await getCompletion(mainFileUri, code.position.position);
    expect(res.any((c) => c.label == 'dart:async'), isTrue);
  }

  Future<void> test_import_configuration() async {
    var content = '''
import 'dart:core' if (dart.library.io) '^';
''';

    await initialize();
    var code = TestCode.parse(content);
    await openFile(mainFileUri, code.code);
    var res = await getCompletion(mainFileUri, code.position.position);
    expect(res.any((c) => c.label == 'dart:async'), isTrue);
  }

  Future<void> test_import_configuration_eof() async {
    var content = '''
import 'dart:core' if (dart.library.io) '^
''';

    await initialize();
    var code = TestCode.parse(content);
    await openFile(mainFileUri, code.code);
    var res = await getCompletion(mainFileUri, code.position.position);
    expect(res.any((c) => c.label == 'dart:async'), isTrue);
  }

  Future<void> test_import_configuration_partial() async {
    var content = '''
import 'dart:core' if (dart.library.io) 'dart:^';
''';

    await initialize();
    var code = TestCode.parse(content);
    await openFile(mainFileUri, code.code);
    var res = await getCompletion(mainFileUri, code.position.position);
    expect(res.any((c) => c.label == 'dart:async'), isTrue);
  }

  Future<void> test_import_eof() async {
    var content = '''
import '^
''';

    await initialize();
    var code = TestCode.parse(content);
    await openFile(mainFileUri, code.code);
    var res = await getCompletion(mainFileUri, code.position.position);
    expect(res.any((c) => c.label == 'dart:async'), isTrue);
  }

  Future<void> test_import_partial() async {
    var content = '''
import 'dart:^';
''';

    await initialize();
    var code = TestCode.parse(content);
    await openFile(mainFileUri, code.code);
    var res = await getCompletion(mainFileUri, code.position.position);
    expect(res.any((c) => c.label == 'dart:async'), isTrue);
  }

  Future<void> test_importedSymbol_libraryImported_hidingVariable() async {
    newFile(join(projectFolderPath, 'lib', 'import.dart'), '''
enum MyEnum {
  value1,
  value2,
}
void myFunction(MyEnum _) {}
var myVariable = 1;
''');

    var content = '''
import 'import.dart' hide myVariable;

void main() {
  myFunction(MyE^);
}
''';

    var expectedContent = '''
import 'import.dart' hide myVariable;

void main() {
  myFunction(MyEnum.value1);
}
''';

    var completionLabel = 'MyEnum.value1';

    await _checkCompletionEdits(
      mainFileUri,
      content,
      completionLabel,
      expectedContent,
    );
  }

  Future<void> test_importedSymbol_libraryImported_showingEnum() async {
    newFile(join(projectFolderPath, 'lib', 'import.dart'), '''
enum MyEnum {
  value1,
  value2,
}
''');

    var content = '''
import 'import.dart' show MyEnum;

void main() {
  MyEnum _ = My^;
}
''';

    var expectedContent = '''
import 'import.dart' show MyEnum;

void main() {
  MyEnum _ = MyEnum.value1;
}
''';

    var completionLabel = 'MyEnum.value1';

    await _checkCompletionEdits(
      mainFileUri,
      content,
      completionLabel,
      expectedContent,
    );
  }

  Future<void> test_insertReplaceRanges() async {
    setCompletionItemInsertReplaceSupport();

    var content = '''
class MyClass {
  String abcdefghij;
}

void f() {
  MyClass a;
  a.abc^def
}
''';

    await initialize();
    var code = TestCode.parse(content);
    await openFile(mainFileUri, code.code);
    var res = await getCompletion(mainFileUri, code.position.position);
    expect(res.any((c) => c.label == 'abcdefghij'), isTrue);
    var item = res.singleWhere((c) => c.label == 'abcdefghij');
    // When using the replacement range, we should get exactly the symbol
    // we expect.
    var replaced = applyTextEdits(code.code, [
      textEditForReplace(item.textEdit!),
    ]);
    expect(replaced, contains('a.abcdefghij\n'));
    // When using the insert range, we should retain what was after the caret
    // ("def" in this case).
    var inserted = applyTextEdits(code.code, [
      textEditForInsert(item.textEdit!),
    ]);
    expect(inserted, contains('a.abcdefghijdef\n'));
  }

  Future<void> test_insertTextMode_multiline() async {
    setCompletionItemInsertTextModeSupport();
    var content = '''
import 'package:flutter/material.dart';

class _MyWidgetState extends State<MyWidget> {
  @override
  Widget build(BuildContext context) {
    [!setSt^!]
    return const Placeholder();
  }
}
''';

    await initialize();
    var code = TestCode.parse(content);
    await openFile(mainFileUri, code.code);
    var res = await getCompletion(mainFileUri, code.position.position);
    var item = res.singleWhere((c) => c.label.startsWith('setState'));

    // Multiline completions should always set insertTextMode.asIs.
    expect(item.insertText, isNull);
    var textEdit = toTextEdit(item.textEdit!);
    expect(textEdit.newText, contains('\n'));
    expect(item.insertTextMode, equals(InsertTextMode.asIs));
  }

  Future<void> test_insertTextMode_singleLine() async {
    setCompletionItemInsertTextModeSupport();

    var content = '''
void foo() {
  ^
}
''';

    await initialize();
    var code = TestCode.parse(content);
    await openFile(mainFileUri, code.code);
    var res = await getCompletion(mainFileUri, code.position.position);
    var item = res.singleWhere((c) => c.label.startsWith('foo'));

    // Single line completions should never set insertTextMode.asIs to
    // avoid bloating payload size where it wouldn't matter.
    expect(item.insertText, isNull);
    var textEdit = toTextEdit(item.textEdit!);
    expect(textEdit.newText, isNot(contains('\n')));
    expect(item.insertTextMode, isNull);
  }

  Future<void> test_inside_lateFinal() async {
    await checkCompleteFunctionCallInsertText(
      '''
class MyClass {
  String get myGetter => '';
  late final myField = [!myG^!]
}
''',
      'myGetter',
      editText: 'myGetter',
    );
  }

  Future<void> test_inside_nonLateFinal() async {
    var content = '''
class MyClass {
  String get myGetter => '';
  final myField = myG^
}
''';
    await initialize();
    var code = TestCode.parse(content);
    await openFile(mainFileUri, code.code);
    var res = await getCompletion(mainFileUri, code.position.position);
    expect(res, isEmpty);
  }

  Future<void> test_insideString() async {
    var content = '''
var a = "This is ^a test"
''';

    await initialize();
    var code = TestCode.parse(content);
    await openFile(mainFileUri, code.code);
    var res = await getCompletion(mainFileUri, code.position.position);
    expect(res, isEmpty);
  }

  Future<void> test_isDeprecated_notSupported() async {
    var content = '''
class MyClass {
  @deprecated
  String abcdefghij;
}

void f() {
  MyClass a;
  a.abc^
}
''';

    await initialize();
    var code = TestCode.parse(content);
    await openFile(mainFileUri, code.code);
    var res = await getCompletion(mainFileUri, code.position.position);
    var item = res.singleWhere((c) => c.label == 'abcdefghij');
    expect(item.deprecated, isNull);
    // If the does not say it supports the deprecated flag, we should show
    // '(deprecated)' in the details.
    expect(item.detail!.toLowerCase(), contains('deprecated'));
  }

  Future<void> test_isDeprecated_supportedFlag() async {
    setCompletionItemDeprecatedFlagSupport();
    var content = '''
class MyClass {
  @deprecated
  String abcdefghij;
}

void f() {
  MyClass a;
  a.abc^
}
''';

    await initialize();
    var code = TestCode.parse(content);
    await openFile(mainFileUri, code.code);
    var res = await getCompletion(mainFileUri, code.position.position);
    var item = res.singleWhere((c) => c.label == 'abcdefghij');
    expect(item.deprecated, isTrue);
    // If the client says it supports the deprecated flag, we should not show
    // deprecated in the details.
    expect(item.detail, isNot(contains('deprecated')));
  }

  Future<void> test_isDeprecated_supportedTag() async {
    setCompletionItemTagSupport([CompletionItemTag.Deprecated]);

    var content = '''
class MyClass {
  @deprecated
  String abcdefghij;
}

void f() {
  MyClass a;
  a.abc^
}
''';

    await initialize();
    var code = TestCode.parse(content);
    await openFile(mainFileUri, code.code);
    var res = await getCompletion(mainFileUri, code.position.position);
    var item = res.singleWhere((c) => c.label == 'abcdefghij');
    expect(item.tags, contains(CompletionItemTag.Deprecated));
    // If the client says it supports the deprecated tag, we should not show
    // deprecated in the details.
    expect(item.detail, isNot(contains('deprecated')));
  }

  Future<void> test_isIncomplete_falseIfAllIncluded() async {
    var content = '''
import 'a.dart';
void f() {
  A a = A();
  a.^
}
''';
    var code = TestCode.parse(content);

    // Create a class with fields aaa1 to aaa500 in the other file.
    newFile(
      join(projectFolderPath, 'lib', 'a.dart'),
      [
        'class A {',
        for (var i = 1; i <= 500; i++) 'String get aaa$i => "";',
        '}',
      ].join('\n'),
    );

    await initialize();
    await openFile(mainFileUri, code.code);
    await initialAnalysis;
    var res = await getCompletionList(mainFileUri, code.position.position);

    // Expect everything (hashCode etc. will take it over 500).
    expect(res.items, hasLength(greaterThanOrEqualTo(500)));
    expect(res.isIncomplete, isFalse);
  }

  Future<void> test_isIncomplete_trueIfNotAllIncluded() async {
    var content = '''
import 'a.dart';
void f() {
  A a = A();
  a.^
}
''';
    var code = TestCode.parse(content);

    // Create a class with fields aaa1 to aaa500 in the other file.
    newFile(
      join(projectFolderPath, 'lib', 'a.dart'),
      [
        'class A {',
        for (var i = 1; i <= 500; i++) '  String get aaa$i => "";',
        '  String get aaa => "";',
        '}',
      ].join('\n'),
    );

    await provideConfig(initialize, {'maxCompletionItems': 200});
    await openFile(mainFileUri, code.code);
    await initialAnalysis;
    var res = await getCompletionList(mainFileUri, code.position.position);

    // Should be capped at 200 and marked as incomplete.
    expect(res.items, hasLength(200));
    expect(res.isIncomplete, isTrue);
  }

  Future<void> test_itemDefaults_editRange() async {
    setCompletionItemInsertReplaceSupport();
    setCompletionListDefaults(['editRange']);

    var content = '''
void myFunction() {
  [!myFunctio^!]
}
''';
    var code = TestCode.parse(content);

    await initialize();
    await openFile(mainFileUri, code.code);
    var list = await getCompletionList(mainFileUri, code.position.position);
    var item = list.items.singleWhere((c) => c.label.startsWith('myFunction'));
    var defaultEditRange = list.itemDefaults!.editRange!.map(
      (insertReplace) => throw 'Expected Range, got CompletionItemEditRange',
      (range) => range,
    );

    // Range covers the ranged marked with [!braces!] in `content`.
    expect(defaultEditRange, code.range.range);

    // Item should use the default range.
    expectUsesDefaultEditRange(item, 'myFunction');
  }

  Future<void> test_itemDefaults_editRange_includesNonDefaultItem() async {
    setCompletionItemInsertReplaceSupport();
    setCompletionListDefaults(['editRange']);

    // In this code, we will get two completions with different edit ranges:
    //
    //   - 'b: ' will have a zero-width range because names don't replace args
    //   -  'a' will replace 'b'
    //
    // Therefore we expect 'a' to use the default range (and not have its own)
    // but 'b'` to have its own.
    //
    // Additionally, because the caret is before the identifier, we will have
    // separate default insert/replace ranges.
    var content = '''
void f(String a, {String? b}) {
  f([!^b!]);
}
''';
    var code = TestCode.parse(content);

    await initialize();
    await openFile(mainFileUri, code.code);
    var list = await getCompletionList(mainFileUri, code.position.position);
    var itemA = list.items.singleWhere((c) => c.label == 'a');
    var itemB = list.items.singleWhere((c) => c.label == 'b: ');

    // Default replace range should span `b`.
    var expectedRange = code.range.range;
    var defaultEditRange = list.itemDefaults!.editRange!.map(
      (insertReplace) => insertReplace,
      (range) => throw 'Expected Range, got CompletionItemEditRange',
    );
    expect(defaultEditRange.replace, equals(expectedRange));

    // Default insert range should be in front of `b`.
    expect(
      defaultEditRange.insert,
      Range(start: expectedRange.start, end: expectedRange.start),
    );

    // And item A should use that default.
    expectUsesDefaultEditRange(itemA, 'a');

    // Item B should have its own range, which is a single range for both
    // insert and replace that matches the insert range (in front of `b`) of
    // the default.
    var itemBTextEdit = toTextEdit(itemB.textEdit!);
    expect(itemBTextEdit.range, defaultEditRange.insert);
    expect(itemBTextEdit.newText, 'b: ');
  }

  Future<void> test_itemDefaults_textMode() async {
    setCompletionItemInsertTextModeSupport();
    setCompletionListDefaults(['insertTextMode']);

    // We only normally set InsertTextMode on multiline completions (where it
    // matters), so ensure there's a multiline completion in the results for
    // testing.
    var content = '''
import 'package:flutter/material.dart';

class _MyWidgetState extends State<MyWidget> {
  @override
  Widget build(BuildContext context) {
    [!setSt^!]
    return const Placeholder();
  }
}
''';
    var code = TestCode.parse(content);

    await initialize();
    await openFile(mainFileUri, code.code);
    var list = await getCompletionList(mainFileUri, code.position.position);
    var item = list.items.singleWhere((c) => c.label.startsWith('setState'));

    // Default should be set.
    expect(list.itemDefaults?.insertTextMode, InsertTextMode.asIs);
    // Item should not.
    expect(item.insertTextMode, isNull);
  }

  /// Exact matches should always be included when completion lists are
  /// truncated, even if they ranked poorly.
  Future<void> test_maxCompletionItems_doesNotExcludeExactMatches() async {
    var content = '''
import 'a.dart';
void f() {
  var a = Item^
}
''';
    var code = TestCode.parse(content);

    // Create classes `Item1` to `Item20` along with a field named `item`.
    // The classes will rank higher in the position above and push
    // the field out without an exception to include exact matches.
    newFile(
      join(projectFolderPath, 'lib', 'a.dart'),
      [
        'String item = "";',
        for (var i = 1; i <= 20; i++) 'class Item$i {}',
      ].join('\n'),
    );

    await provideConfig(initialize, {'maxCompletionItems': 10});
    await openFile(mainFileUri, code.code);
    await initialAnalysis;
    var res = await getCompletionList(mainFileUri, code.position.position);

    expect(res.items, hasLength(10));
    expect(res.isIncomplete, isTrue);

    // Ensure the 'Item' field is included.
    expect(res.items.map((item) => item.label), contains('item'));
  }

  /// Snippet completions should be kept when maxCompletionItems truncates
  /// because they are not ranked like other completions and might be
  /// truncated when they are exactly what the user wants.
  Future<void> test_maxCompletionItems_doesNotExcludeSnippets() async {
    var content = '''
import 'a.dart';
void f() {
  fo^
}
''';
    var code = TestCode.parse(content);

    // Create fields for1 to for20 in the other file.
    newFile(
      join(projectFolderPath, 'lib', 'a.dart'),
      [
        for (var i = 1; i <= 20; i++)
          'String for$i = '
              ';',
      ].join('\n'),
    );

    setCompletionItemSnippetSupport();
    await provideConfig(initialize, {'maxCompletionItems': 10});
    await openFile(mainFileUri, code.code);
    await initialAnalysis;
    var res = await getCompletionList(mainFileUri, code.position.position);

    // Should be capped at 10 and marked as incomplete.
    expect(res.items, hasLength(10));
    expect(res.isIncomplete, isTrue);

    // Ensure the 'for' snippet is included.
    expect(
      res.items
          .where((item) => item.kind == CompletionItemKind.Snippet)
          .map((item) => item.label)
          .contains('for'),
      isTrue,
    );
  }

  Future<void> test_namedArg_flutterChildren() async {
    var content = '''
import 'package:flutter/widgets.dart';

final a = Flex(c^);
''';

    var expectedContent = '''
import 'package:flutter/widgets.dart';

final a = Flex(children: [^],);
''';

    await verifyCompletions(
      mainFileUri,
      content,
      expectCompletions: ['children: []'],
      applyEditsFor: 'children: []',
      expectedContent: expectedContent,
    );
  }

  Future<void> test_namedArg_flutterChildren_existingValue() async {
    // Flutter's widget classes have special handling that adds `[]` after the
    // children named arg, but this should not occur if there's already a value
    // for this named arg.
    var content = '''
import 'package:flutter/widgets.dart';

final a = Flex(c^: []);
''';

    var expectedContent = '''
import 'package:flutter/widgets.dart';

final a = Flex(children: []);
''';

    await verifyCompletions(
      mainFileUri,
      content,
      expectCompletions: ['children'],
      applyEditsFor: 'children',
      expectedContent: expectedContent,
    );
  }

  Future<void> test_namedArg_insertReplaceRanges() async {
    /// Helper to check multiple completions in the same template file.
    Future<void> check(
      String code,
      String expectedLabel, {
      required String expectedReplace,
      required String expectedInsert,
    }) async {
      var content = '''
class A { const A({int argOne, int argTwo, String argThree}); }
final varOne = '';
$code
void f() { }
''';
      var expectedReplaced = '''
class A { const A({int argOne, int argTwo, String argThree}); }
final varOne = '';
$expectedReplace
void f() { }
''';
      var expectedInserted = '''
class A { const A({int argOne, int argTwo, String argThree}); }
final varOne = '';
$expectedInsert
void f() { }
''';

      await verifyCompletions(
        mainFileUri,
        content,
        expectCompletions: [expectedLabel],
        applyEditsFor: expectedLabel,
        verifyInsertReplaceRanges: true,
        expectedContent: expectedReplaced,
        expectedContentIfInserting: expectedInserted,
      );
    }

    // When at the start of the identifier, it will be set as the replacement
    // range so we don't expect the ': ,'
    await check(
      '@A(^argOne: 1)',
      'argTwo',
      expectedReplace: '@A(argTwo: 1)',
      expectedInsert: '@A(argTwoargOne: 1)',
    );

    // When adding a name to an existing value, it should always insert.
    await check(
      '@A(^1)',
      'argOne: ',
      expectedReplace: '@A(argOne: 1)',
      expectedInsert: '@A(argOne: 1)',
    );

    // When adding a name to an existing variable, it should always insert.
    await check(
      '@A(argOne: 1, ^varOne)',
      'argTwo: ',
      expectedReplace: '@A(argOne: 1, argTwo: varOne)',
      expectedInsert: '@A(argOne: 1, argTwo: varOne)',
    );

    // // Inside the identifier also should be expected to replace.
    await check(
      '@A(arg^One: 1)',
      'argTwo',
      expectedReplace: '@A(argTwo: 1)',
      expectedInsert: '@A(argTwoOne: 1)',
    );

    // If there's a space, there's no replacement range so we should still get
    // the colon/comma since this is always an insert (and both operations will
    // produce the same text).
    await check(
      '@A(^ argOne: 1)',
      'argTwo: ',
      expectedReplace: '@A(argTwo: ^, argOne: 1)',
      expectedInsert: '@A(argTwo: ^, argOne: 1)',
    );

    // Partially typed names in front of values (that aren't considered part of
    // the same identifier) should also suggest name labels.
    await check(
      '''@A(argOne: 1, argTh^'Foo')''',
      'argThree: ',
      expectedReplace: '''@A(argOne: 1, argThree: 'Foo')''',
      expectedInsert: '''@A(argOne: 1, argThree: 'Foo')''',
    );
  }

  Future<void> test_namedArg_offsetBeforeCompletionTarget() async {
    // This test checks for a previous bug where the completion target was a
    // symbol far after the cursor offset (`aaaa` here) and caused the whole
    // identifier to be used as the `targetPrefix` which would filter out
    // other symbol.
    // https://github.com/Dart-Code/Dart-Code/issues/2672#issuecomment-666085575
    var content = '''
void f() {
  myFunction(
    ^
    aaaa: '',
  );
}

void myFunction({String aaaa, String aaab, String aaac}) {}
''';

    await initialize();
    var code = TestCode.parse(content);
    await openFile(mainFileUri, code.code);
    var res = await getCompletion(mainFileUri, code.position.position);
    expect(res.any((c) => c.label == 'aaab: '), isTrue);
  }

  Future<void> test_namedArg_plainText() async {
    var content = '''
class A { const A({int one}); }
@A(^)
void f() { }
''';

    await initialize();
    var code = TestCode.parse(content);
    await openFile(mainFileUri, code.code);
    var res = await getCompletion(mainFileUri, code.position.position);
    expect(res.any((c) => c.label == 'one: '), isTrue);
    var item = res.singleWhere((c) => c.label == 'one: ');
    expect(
      item.insertTextFormat,
      anyOf(equals(InsertTextFormat.PlainText), isNull),
    );
    expect(item.insertText, isNull);
    var textEdit = toTextEdit(item.textEdit!);
    expect(textEdit.newText, item.label);
    var updated = applyTextEdits(code.code, [toTextEdit(item.textEdit!)]);
    expect(updated, contains('one: '));
  }

  Future<void> test_namedArg_snippetStringSelection_endOfString() async {
    var content = '''
class A { const A({int one}); }
@A(^)
void f() { }
''';

    setCompletionItemSnippetSupport();
    await initialize();
    var code = TestCode.parse(content);
    await openFile(mainFileUri, code.code);
    var res = await getCompletion(mainFileUri, code.position.position);
    expect(res.any((c) => c.label == 'one: '), isTrue);
    var item = res.singleWhere((c) => c.label == 'one: ');
    // As the selection is the end of the string, there's no need for a snippet
    // here. Since the insert text is also the same as the label, it does not
    // need to be provided.
    expect(item.insertTextFormat, isNull);
    expect(item.insertText, isNull);
    var textEdit = toTextEdit(item.textEdit!);
    expect(textEdit.newText, equals('one: '));
    expect(
      textEdit.range,
      equals(Range(start: code.position.position, end: code.position.position)),
    );
  }

  Future<void>
  test_namedArgTrailing_snippetStringSelection_insideString() async {
    var content = '''
void f({int one, int two}) {
  f(
    ^
    two: 2,
  );
}
''';

    setCompletionItemSnippetSupport();
    await initialize();
    var code = TestCode.parse(content);
    await openFile(mainFileUri, code.code);
    var res = await getCompletion(mainFileUri, code.position.position);
    expect(res.any((c) => c.label == 'one: '), isTrue);
    var item = res.singleWhere((c) => c.label == 'one: ');
    // Ensure the snippet comes through in the expected format with the expected
    // placeholder.
    expect(item.insertTextFormat, equals(InsertTextFormat.Snippet));
    expect(item.insertText, isNull);
    var textEdit = toTextEdit(item.textEdit!);
    expect(textEdit.newText, equals(r'one: $0,'));
    expect(
      textEdit.range,
      equals(Range(start: code.position.position, end: code.position.position)),
    );
  }

  Future<void> test_nonAnalyzedFile() async {
    var readmeFilePath = convertPath(join(projectFolderPath, 'README.md'));
    newFile(readmeFilePath, '');
    await initialize();

    var res = await getCompletion(
      pathContext.toUri(readmeFilePath),
      startOfDocPos,
    );
    expect(res, isEmpty);
  }

  Future<void> test_noOperators_propertyAccessExternal() async {
    var content = '''
class A {
  int operator-() => 0;
  int operator-(int other) => 0;
}

void f() {
  A().^
}
''';

    await initialize();
    var code = TestCode.parse(content);
    await openFile(mainFileUri, code.code);
    var completions = await getCompletion(mainFileUri, code.position.position);
    var labels = completions.map((c) => c.label).toList();
    expect(labels, isNot(contains('==(…)')));
    expect(labels, isNot(contains('-(…)')));
    expect(labels, isNot(contains('unary-()')));
  }

  Future<void> test_noOperators_propertyAccessInternal() async {
    var content = '''
class A {
  int operator-() => 0;
  int operator-(int other) => 0;

  void m() {
    this.^
  }
}
''';

    await initialize();
    var code = TestCode.parse(content);
    await openFile(mainFileUri, code.code);
    var completions = await getCompletion(mainFileUri, code.position.position);
    var labels = completions.map((c) => c.label).toList();
    expect(labels, isNot(contains('==(…)')));
    expect(labels, isNot(contains('-(…)')));
    expect(labels, isNot(contains('unary-()')));
  }

  Future<void> test_noOperators_superPropertyAccess() async {
    var content = '''
class A {
  int operator-() => 0;
  int operator-(int other) => 0;
}

class B extends A {
  void m() {
    super.^
  }
}
''';

    await initialize();
    var code = TestCode.parse(content);
    await openFile(mainFileUri, code.code);
    var completions = await getCompletion(mainFileUri, code.position.position);
    var labels = completions.map((c) => c.label).toList();
    expect(labels, isNot(contains('==(…)')));
    expect(labels, isNot(contains('-(…)')));
    expect(labels, isNot(contains('unary-()')));
  }

  Future<void> test_nullableTypes() async {
    var content = '''
String? foo(int? a, [int b = 1]) {}

void f() {
  fo^
}
''';

    await initialize();
    var code = TestCode.parse(content);
    await openFile(mainFileUri, code.code);
    await initialAnalysis;
    var res = await getCompletion(mainFileUri, code.position.position);

    var completion = res.singleWhere((c) => c.label.startsWith('foo'));
    expect(completion.detail, '(int? a, [int b = 1]) → String?');
  }

  Future<void> test_operators_override() async {
    var content = '''
class A {
  int operator-() => 0;
  int operator-(int other) => 0;
}

class B extends A {
  ^
}
''';

    await initialize();
    var code = TestCode.parse(content);
    await openFile(mainFileUri, code.code);
    var completions = await getCompletion(mainFileUri, code.position.position);
    var labels = completions.map((c) => c.label).toList();
    expect(labels, contains('override ==(Object other) { … }'));
    expect(labels, contains('override -(int other) { … }'));
    expect(labels, contains('override unary-() { … }'));
  }

  Future<void> test_plainText() async {
    var content = '''
class MyClass {
  String abcdefghij;
}

void f() {
  MyClass a;
  a.abc^
}
''';

    await initialize();
    var code = TestCode.parse(content);
    await openFile(mainFileUri, code.code);
    var res = await getCompletion(mainFileUri, code.position.position);
    expect(res.any((c) => c.label == 'abcdefghij'), isTrue);
    var item = res.singleWhere((c) => c.label == 'abcdefghij');
    expect(
      item.insertTextFormat,
      anyOf(equals(InsertTextFormat.PlainText), isNull),
    );
    expect(item.insertText, anyOf(equals('abcdefghij'), isNull));
    var updated = applyTextEdits(code.code, [toTextEdit(item.textEdit!)]);
    expect(updated, contains('a.abcdefghij'));
  }

  Future<void> test_prefixed_enumMember() async {
    var content = '''
import 'main.dart' as self;

enum MyEnum {
  one,
  two,
}

void main() {
  final x = self.MyEnum.^
}
''';

    await initialize();
    var code = TestCode.parse(content);
    await openFile(mainFileUri, code.code);
    var res = await getCompletion(mainFileUri, code.position.position);
    expect(res.any((c) => c.label == 'one'), isTrue);
  }

  Future<void> test_prefixFilter_endOfSymbol() async {
    var content = '''
class UniqueNamedClassForLspOne {}
class UniqueNamedClassForLspTwo {}
class UniqueNamedClassForLspThree {}

void f() {
  // Should match only Two and Three
  UniqueNamedClassForLspT^
}
''';

    await initialize();
    var code = TestCode.parse(content);
    await openFile(mainFileUri, code.code);
    var res = await getCompletion(mainFileUri, code.position.position);
    expect(res.any((c) => c.label == 'UniqueNamedClassForLspOne'), isFalse);
    expect(res.any((c) => c.label == 'UniqueNamedClassForLspTwo'), isTrue);
    expect(res.any((c) => c.label == 'UniqueNamedClassForLspThree'), isTrue);
  }

  Future<void> test_prefixFilter_midSymbol() async {
    var content = '''
class UniqueNamedClassForLspOne {}
class UniqueNamedClassForLspTwo {}
class UniqueNamedClassForLspThree {}

void f() {
  // Should match only Two and Three
  UniqueNamedClassForLspT^hree
}
''';

    await initialize();
    var code = TestCode.parse(content);
    await openFile(mainFileUri, code.code);
    var res = await getCompletion(mainFileUri, code.position.position);
    expect(res.any((c) => c.label == 'UniqueNamedClassForLspOne'), isFalse);
    expect(res.any((c) => c.label == 'UniqueNamedClassForLspTwo'), isTrue);
    expect(res.any((c) => c.label == 'UniqueNamedClassForLspThree'), isTrue);
  }

  Future<void> test_prefixFilter_startOfSymbol() async {
    var content = '''
class UniqueNamedClassForLspOne {}
class UniqueNamedClassForLspTwo {}
class UniqueNamedClassForLspThree {}

void f() {
  // Should match all three
  ^UniqueNamedClassForLspT
}
''';

    await initialize();
    var code = TestCode.parse(content);
    await openFile(mainFileUri, code.code);
    var res = await getCompletion(mainFileUri, code.position.position);
    expect(res.any((c) => c.label == 'UniqueNamedClassForLspOne'), isTrue);
    expect(res.any((c) => c.label == 'UniqueNamedClassForLspTwo'), isTrue);
    expect(res.any((c) => c.label == 'UniqueNamedClassForLspThree'), isTrue);
  }

  Future<void> test_setters() async {
    var content = '''
class MyClass {
  set stringSetter(String a) {}
  set noArgSetter() {}
  set multiArgSetter(a, b) {}
  set functionSetter(String Function(int a, int b) foo) {}
}

void f() {
  MyClass a;
  a.^
}
''';

    await initialize();
    var code = TestCode.parse(content);
    await openFile(mainFileUri, code.code);
    var res = await getCompletion(mainFileUri, code.position.position);
    var setters =
        res
            .where((c) => c.label.endsWith('Setter'))
            .map((c) => c.detail != null ? '${c.label} (${c.detail})' : c.label)
            .toList();
    expect(setters, [
      'stringSetter (String)',
      'noArgSetter (dynamic)',
      'multiArgSetter (dynamic)',
      // Because of how we extract the type name, we don't currently support
      // this.
      'functionSetter',
    ]);
  }

  Future<void> test_sort_sortsByRelevance() async {
    var content = '''
class UniquePrefixABC {}
class UniquePrefixAaBbCc {}

final a = UniquePrefixab^
''';

    await verifyCompletions(
      mainFileUri,
      content,
      expectCompletions: [
        // Constructors should all come before the class names, as they have
        // higher relevance in this position.
        'UniquePrefixABC()',
        'UniquePrefixAaBbCc()',
        'UniquePrefixABC',
        'UniquePrefixAaBbCc',
      ],
    );
  }

  Future<void> test_sort_truncatesByFuzzyScore() async {
    var content = '''
class UniquePrefixABC {}
class UniquePrefixAaBbCc {}

final a = UniquePrefixab^
''';

    // Enable truncation after 2 items so we can verify which
    // items were dropped.
    await provideConfig(initialize, {'maxCompletionItems': 2});
    await verifyCompletions(
      mainFileUri,
      content,
      expectNoAdditionalItems: true,
      expectCompletions: [
        // Although constructors are more relevant, when truncating we will use
        // fuzzy score, so the closer matches are kept instead and we'll get
        // constructor+class from the closer match.
        'UniquePrefixABC()',
        'UniquePrefixABC',
      ],
    );
  }

  Future<void> test_unimportedSymbols() async {
    newFile(join(projectFolderPath, 'other_file.dart'), '''
/// This class is in another file.
class InOtherFile {}
''');

    var content = '''
void f() {
  InOtherF^
}
''';

    await initialize();
    var code = TestCode.parse(content);
    await openFile(mainFileUri, code.code);
    await initialAnalysis;
    var res = await getCompletion(mainFileUri, code.position.position);

    // Find the completion for the class in the other file.
    var completion = res.singleWhere((c) => c.label == 'InOtherFile');
    expect(completion, isNotNull);
    expect(completion.textEdit, isNotNull);
    var originalTextEdit = completion.textEdit;

    // Expect no docs, this is added during resolve.
    expectDocumentation(completion, isNull);

    // Resolve the completion item (via server) to get any additional edits.
    // This is LSP's equiv of getSuggestionDetails() and is invoked by LSP
    // clients to populate additional info (in our case, any additional edits
    // for inserting the import).
    var resolved = await resolveCompletion(completion);
    expect(resolved, isNotNull);

    // Ensure the detail field was update to show this will auto-import.
    expect(
      resolved.detail,
      startsWith("Auto import from '../other_file.dart'"),
    );

    // Ensure the doc comment was added.
    expectDocumentation(resolved, equals('This class is in another file.'));

    // Ensure the edit did not change.
    expect(resolved.textEdit, originalTextEdit);

    // There should be no command for this item because it doesn't need imports
    // in other files. Same-file completions are in additionalEdits.
    expect(resolved.command, isNull);

    // Apply both the main completion edit and the additionalTextEdits atomically.
    var newContent = applyTextEdits(
      code.code,
      [
        toTextEdit(resolved.textEdit!),
      ].followedBy(resolved.additionalTextEdits!).toList(),
    );

    // Ensure both edits were made - the completion, and the inserted import.
    expect(
      newContent,
      equals('''
import '../other_file.dart';

void f() {
  InOtherFile
}
'''),
    );
  }

  Future<void> test_unimportedSymbols_dartDocPreference_full() async {
    await assertResolvedDocumentation(
      'full',
      includesSummary: true,
      includesFull: true,
    );
  }

  Future<void> test_unimportedSymbols_dartDocPreference_none() async {
    await assertResolvedDocumentation(
      'none',
      includesSummary: false,
      includesFull: false,
    );
  }

  Future<void> test_unimportedSymbols_dartDocPreference_summary() async {
    await assertResolvedDocumentation(
      'summary',
      includesSummary: true,
      includesFull: false,
    );
  }

  /// No preference should result in full docs.
  Future<void> test_unimportedSymbols_dartDocPreference_unset() async {
    await assertResolvedDocumentation(
      null,
      includesSummary: true,
      includesFull: true,
    );
  }

  Future<void>
  test_unimportedSymbols_doesNotDuplicate_importedViaMultipleLibraries() async {
    // An item that's already imported through multiple libraries that
    // export it should not result in multiple entries.
    newFile(join(projectFolderPath, 'lib/source_file.dart'), '''
class MyExportedClass {}
''');
    newFile(join(projectFolderPath, 'lib/reexport1.dart'), '''
export 'source_file.dart';
''');
    newFile(join(projectFolderPath, 'lib/reexport2.dart'), '''
export 'source_file.dart';
''');

    var content = '''
import 'reexport1.dart';
import 'reexport2.dart';

void f() {
  MyExported^
}
''';

    await initialize();
    var code = TestCode.parse(content);
    await openFile(mainFileUri, code.code);
    await initialAnalysis;
    var res = await getCompletion(mainFileUri, code.position.position);
    var completions = res.where((c) => c.label == 'MyExportedClass').toList();
    expect(completions, hasLength(1));
  }

  Future<void>
  test_unimportedSymbols_doesNotDuplicate_importedViaSingleLibrary() async {
    // An item that's already imported through a library that exports it
    // should not result in multiple entries.
    newFile(join(projectFolderPath, 'lib/source_file.dart'), '''
class MyExportedClass {}
''');
    newFile(join(projectFolderPath, 'lib/reexport1.dart'), '''
export 'source_file.dart';
''');
    newFile(join(projectFolderPath, 'lib/reexport2.dart'), '''
export 'source_file.dart';
''');

    var content = '''
import 'reexport1.dart';

void f() {
  MyExported^
}
''';

    await initialize();
    var code = TestCode.parse(content);
    await openFile(mainFileUri, code.code);
    await initialAnalysis;
    var res = await getCompletion(mainFileUri, code.position.position);

    var completions = res.where((c) => c.label == 'MyExportedClass').toList();
    expect(completions, hasLength(1));
  }

  Future<void> test_unimportedSymbols_doesNotFilterSymbolsWithSameName() async {
    // Classes here are not re-exports, so should not be filtered out.
    newFile(
      join(projectFolderPath, 'source_file1.dart'),
      'class MyDuplicatedClass {}',
    );
    newFile(
      join(projectFolderPath, 'source_file2.dart'),
      'class MyDuplicatedClass {}',
    );
    newFile(
      join(projectFolderPath, 'source_file3.dart'),
      'class MyDuplicatedClass {}',
    );

    var content = '''
void f() {
  MyDuplicated^
}
''';

    await initialize();
    var code = TestCode.parse(content);
    await openFile(mainFileUri, code.code);
    await initialAnalysis;
    var res = await getCompletion(mainFileUri, code.position.position);

    var completions = res.where((c) => c.label == 'MyDuplicatedClass').toList();
    expect(completions, hasLength(3));

    // Resolve the completions so we can get the auto-import text.
    var resolvedCompletions = await Future.wait(
      completions.map(resolveCompletion),
    );

    expectAutoImportCompletion(resolvedCompletions, '../source_file1.dart');
    expectAutoImportCompletion(resolvedCompletions, '../source_file2.dart');
    expectAutoImportCompletion(resolvedCompletions, '../source_file3.dart');
  }

  Future<void> test_unimportedSymbols_enumValues() async {
    // Enum values only show up in contexts with their types, so we need two
    // extra files - one with the Enum definition, and one with a function that
    // accepts the Enum type that is imported into the test files.
    newFile(join(projectFolderPath, 'lib', 'enum.dart'), '''
enum MyExportedEnum { One, Two }
''');
    newFile(join(projectFolderPath, 'lib', 'function_x.dart'), '''
import 'package:test/enum.dart';
void x(MyExportedEnum e) {}
''');

    var content = '''
import 'package:test/function_x.dart';

void f() {
  x(MyExported^
}
''';

    await initialize();
    var code = TestCode.parse(content);
    await openFile(mainFileUri, code.code);
    await initialAnalysis;
    var res = await getCompletion(mainFileUri, code.position.position);

    var enumCompletions =
        res.where((c) => c.label.startsWith('MyExportedEnum')).toList();
    expect(
      enumCompletions.map((c) => c.label),
      unorderedEquals([
        'MyExportedEnum',
        'MyExportedEnum.One',
        'MyExportedEnum.Two',
      ]),
    );

    var completion = enumCompletions.singleWhere(
      (c) => c.label == 'MyExportedEnum.One',
    );

    // Resolve the completion item (via server) to get its edits. This is the
    // LSP's equiv of getSuggestionDetails() and is invoked by LSP clients to
    // populate additional info (in our case, the additional edits for inserting
    // the import).
    var resolved = await resolveCompletion(completion);
    expect(resolved, isNotNull);

    // Ensure the detail field was update to show this will auto-import.
    expect(
      resolved.detail,
      startsWith("Auto import from 'package:test/enum.dart'"),
    );

    // Ensure the edit was added on.
    expect(resolved.textEdit, isNotNull);

    // Apply both the main completion edit and the additionalTextEdits atomically.
    var newContent = applyTextEdits(
      code.code,
      [
        toTextEdit(resolved.textEdit!),
      ].followedBy(resolved.additionalTextEdits!).toList(),
    );

    // Ensure both edits were made - the completion, and the inserted import.
    expect(
      newContent,
      equals('''
import 'package:test/enum.dart';
import 'package:test/function_x.dart';

void f() {
  x(MyExportedEnum.One
}
'''),
    );
  }

  Future<void> test_unimportedSymbols_enumValuesAlreadyImported() async {
    newFile(join(projectFolderPath, 'lib', 'enum.dart'), '''
enum MyExportedEnum { One, Two }
''');
    newFile(join(projectFolderPath, 'lib', 'reexport1.dart'), '''
import 'enum.dart';
export 'enum.dart';
void x(MyExportedEnum e) {}
''');
    newFile(join(projectFolderPath, 'lib', 'reexport2.dart'), '''
export 'enum.dart';
''');

    var content = '''
import 'reexport1.dart';

void f() {
  x(MyExported^
}
''';

    await initialize();
    var code = TestCode.parse(content);
    await openFile(mainFileUri, code.code);
    await initialAnalysis;
    var res = await getCompletion(mainFileUri, code.position.position);

    var completions =
        res.where((c) => c.label == 'MyExportedEnum.One').toList();
    expect(completions, hasLength(1));
    var resolved = await resolveCompletion(completions.first);
    // It should not include auto-import text since it's already imported.
    expect(resolved.detail, isNot(contains('Auto import from')));
  }

  /// Verify extensions can be auto-imported if not already in-scope.
  Future<void> test_unimportedSymbols_extension() async {
    // Define extensions in 'extensions.dart'.
    newFile(join(projectFolderPath, 'lib', 'extensions.dart'), '''
extension StringExtensions on String {
  String get empty => '';
}
''');

    // Also import the extensions into an unrelated file to ensure this doesn't
    // cause extra suggestions (https://github.com/dart-lang/sdk/issues/56320).
    newFile(
      join(projectFolderPath, 'lib', 'other.dart'),
      'import "extensions.dart";',
    );

    var content = '''
void f(String a) {
  a.empt^
}
''';

    await initialize();
    var code = TestCode.parse(content);
    await openFile(mainFileUri, code.code);
    await initialAnalysis;
    var res = await getCompletion(mainFileUri, code.position.position);

    // Expect only a single entry for the 'empty' extension member.
    var completions = res.where((c) => c.label == 'empty');
    expect(completions, hasLength(1));

    // Expect it to auto-import from 'extensions.dart'.
    var resolved = await resolveCompletion(completions.single);
    expect(
      resolved.detail,
      startsWith("Auto import from 'package:test/extensions.dart'"),
    );

    // Verify the edits.
    var newContent = applyTextEdits(
      code.code,
      [
        toTextEdit(resolved.textEdit!),
      ].followedBy(resolved.additionalTextEdits!).toList(),
    );
    expect(
      newContent,
      equals('''
import 'package:test/extensions.dart';

void f(String a) {
  a.empty
}
'''),
    );
  }

  Future<void> test_unimportedSymbols_filtersOutAlreadyImportedSymbols() async {
    newFile(join(projectFolderPath, 'lib', 'source_file.dart'), '''
class MyExportedClass {}
''');
    newFile(join(projectFolderPath, 'lib', 'reexport1.dart'), '''
export 'source_file.dart';
''');
    newFile(join(projectFolderPath, 'lib', 'reexport2.dart'), '''
export 'source_file.dart';
''');

    var content = '''
import 'reexport1.dart';

void f() {
  MyExported^
}
''';

    await initialize();
    var code = TestCode.parse(content);
    await openFile(mainFileUri, code.code);
    await initialAnalysis;
    var res = await getCompletion(mainFileUri, code.position.position);

    var completions = res.where((c) => c.label == 'MyExportedClass').toList();
    expect(completions, hasLength(1));
    var resolved = await resolveCompletion(completions.first);
    // It should not include auto-import text since it's already imported.
    expect(resolved.detail, isNull);
  }

  Future<void> test_unimportedSymbols_importsPackageUri() async {
    newFile(
      join(projectFolderPath, 'lib', 'my_class.dart'),
      'class MyClass {}',
    );

    var content = '''
void f() {
  MyClas^
}
''';

    var expectedContent = '''
import 'package:test/my_class.dart';

void f() {
  MyClass
}
''';

    var completionLabel = 'MyClass';

    await _checkCompletionEdits(
      mainFileUri,
      content,
      completionLabel,
      expectedContent,
    );
  }

  Future<void>
  test_unimportedSymbols_importsPackageUri_extensionMember() async {
    newFile(join(projectFolderPath, 'lib', 'my_extension.dart'), '''
extension MyExtension on String {
  void myExtensionMethod() {}
}
''');

    var content = '''
void f() {
  ''.myExtensionMet^
}
''';

    var expectedContent = '''
import 'package:test/my_extension.dart';

void f() {
  ''.myExtensionMethod
}
''';

    var completionLabel = 'myExtensionMethod()';
    await _checkCompletionEdits(
      mainFileUri,
      content,
      completionLabel,
      expectedContent,
    );
  }

  Future<void>
  test_unimportedSymbols_includesReexportedSymbolsForEachFile() async {
    newFile(join(projectFolderPath, 'source_file.dart'), '''
class MyExportedClass {}
''');
    newFile(join(projectFolderPath, 'reexport1.dart'), '''
export 'source_file.dart';
''');
    newFile(join(projectFolderPath, 'reexport2.dart'), '''
export 'source_file.dart';
''');

    var content = '''
void f() {
  MyExported^
}
''';

    await initialize();
    var code = TestCode.parse(content);
    await openFile(mainFileUri, code.code);
    await initialAnalysis;
    var res = await getCompletion(mainFileUri, code.position.position);

    var completions = res.where((c) => c.label == 'MyExportedClass').toList();
    expect(completions, hasLength(3));

    // Resolve the completions so we can get the auto-import text.
    var resolvedCompletions = await Future.wait(
      completions.map(resolveCompletion),
    );

    expectAutoImportCompletion(resolvedCompletions, '../source_file.dart');
    expectAutoImportCompletion(resolvedCompletions, '../reexport1.dart');
    expectAutoImportCompletion(resolvedCompletions, '../reexport2.dart');
  }

  Future<void> test_unimportedSymbols_insertReplaceRanges() async {
    setCompletionItemInsertReplaceSupport();

    newFile(join(projectFolderPath, 'other_file.dart'), '''
/// This class is in another file.
class InOtherFile {}
''');

    var content = '''
void f() {
  InOtherF^il
}
''';

    await initialize();
    var code = TestCode.parse(content);
    await openFile(mainFileUri, code.code);
    await initialAnalysis;
    var res = await getCompletion(mainFileUri, code.position.position);

    // Find the completion for the class in the other file.
    var completion = res.singleWhere((c) => c.label == 'InOtherFile');
    expect(completion, isNotNull);
    expect(completion.textEdit, isNotNull);
    var originalTextEdit = completion.textEdit;

    // Expect no docs, this is added during resolve.
    expectDocumentation(completion, isNull);

    // Resolve the completion item (via server) to get any additional edits.
    // This is LSP's equiv of getSuggestionDetails() and is invoked by LSP
    // clients to populate additional info (in our case, any additional edits
    // for inserting the import).
    var resolved = await resolveCompletion(completion);
    expect(resolved, isNotNull);

    // Ensure the detail field was update to show this will auto-import.
    expect(
      resolved.detail,
      startsWith("Auto import from '../other_file.dart'"),
    );

    // Ensure the doc comment was added.
    expectDocumentation(resolved, equals('This class is in another file.'));

    // Ensure the edit did not change.
    expect(resolved.textEdit, originalTextEdit);

    // There should be no command for this item because it doesn't need imports
    // in other files. Same-file completions are in additionalEdits.
    expect(resolved.command, isNull);

    // Apply both the main completion edit and the additionalTextEdits atomically
    // then check the contents.

    var newContentReplaceMode = applyTextEdits(
      code.code,
      [
        textEditForReplace(resolved.textEdit!),
      ].followedBy(resolved.additionalTextEdits!).toList(),
    );
    var newContentInsertMode = applyTextEdits(
      code.code,
      [
        textEditForInsert(resolved.textEdit!),
      ].followedBy(resolved.additionalTextEdits!).toList(),
    );

    // Ensure both edits were made - the completion, and the inserted import.
    expect(
      newContentReplaceMode,
      equals('''
import '../other_file.dart';

void f() {
  InOtherFile
}
'''),
    );
    // In insert mode, we'd have the trailing "il" still after the caret.
    expect(
      newContentInsertMode,
      equals('''
import '../other_file.dart';

void f() {
  InOtherFileil
}
'''),
    );
  }

  Future<void> test_unimportedSymbols_insertsIntoPartFiles() async {
    // File we'll be adding an import for.
    newFile(join(projectFolderPath, 'other_file.dart'), ''''
class InOtherFile {}
''');

    // File that will have the import added.
    var parentContent = '''
part 'main.dart';
''';
    newFile(join(projectFolderPath, 'lib', 'parent.dart'), parentContent);

    // File that we're invoking completion in.
    var content = '''
part of 'parent.dart';
void f() {
  InOtherF^
}
''';

    await initialize();
    var code = TestCode.parse(content);
    await openFile(mainFileUri, code.code);
    await initialAnalysis;
    var res = await getCompletion(mainFileUri, code.position.position);

    var completion = res.singleWhere((c) => c.label == 'InOtherFile');
    expect(completion, isNotNull);

    // Resolve the completion item to get its edits.
    var resolved = await resolveCompletion(completion);
    expect(resolved, isNotNull);
    // Ensure it has a command, since it will need to make edits in other files
    // and that's done by telling the server to send a workspace/applyEdit. LSP
    // doesn't currently support these other-file edits in the completion.
    // See https://github.com/microsoft/language-server-protocol/issues/749
    expect(resolved.command, isNotNull);

    // Apply all current-document edits.
    var newContent = applyTextEdits(
      code.code,
      [
        toTextEdit(resolved.textEdit!),
      ].followedBy(resolved.additionalTextEdits!).toList(),
    );
    expect(
      newContent,
      equals('''
part of 'parent.dart';
void f() {
  InOtherFile
}
'''),
    );

    await verifyCommandEdits(resolved.command!, '''
>>>>>>>>>> lib/parent.dart
import '../other_file.dart';

part 'main.dart';
''');
  }

  Future<void>
  test_unimportedSymbols_isIncompleteNotSetIfBudgetNotExhausted() async {
    var content = '''
void f() {
  InOtherF^
}
''';
    var code = TestCode.parse(content);

    await initialize(
      initializationOptions: {
        ...?defaultInitializationOptions,
        // Set budget high to ensure it completes.
        'completionBudgetMilliseconds': 100000,
      },
    );
    await openFile(mainFileUri, code.code);
    await initialAnalysis;
    var res = await getCompletionList(mainFileUri, code.position.position);

    // Ensure we flagged that we returned everything.
    expect(res.isIncomplete, isFalse);
  }

  Future<void> test_unimportedSymbols_isIncompleteSetIfBudgetExhausted() async {
    newFile(
      join(projectFolderPath, 'lib', 'other_file.dart'),
      'class InOtherFile {}',
    );

    var content = '''
void f() {
  InOtherF^
}
''';
    var code = TestCode.parse(content);

    await initialize(
      initializationOptions: {
        ...?defaultInitializationOptions,
        // Set budget low to ensure we don't complete.
        'completionBudgetMilliseconds': 0,
      },
    );
    await openFile(mainFileUri, code.code);
    await initialAnalysis;
    var res = await getCompletionList(mainFileUri, code.position.position);

    // Ensure we flagged that we did not return everything.
    expect(res.items, hasLength(0));
    expect(res.isIncomplete, isTrue);
  }

  Future<void> test_unimportedSymbols_libraryImported_hidingMultiple() async {
    newFile(join(projectFolderPath, 'lib', 'my_classes.dart'), '''
class MyClass1 {}
class MyClass2 {}
class MyClass3 {}
''');

    var content = '''
import 'package:test/my_classes.dart' hide MyClass1, MyClass2;
void f() {
  MyClas^
}
''';

    var expectedContent = '''
import 'package:test/my_classes.dart' hide MyClass2;
void f() {
  MyClass1
}
''';

    var completionLabel = 'MyClass1';

    await _checkCompletionEdits(
      mainFileUri,
      content,
      completionLabel,
      expectedContent,
    );
  }

  Future<void> test_unimportedSymbols_libraryImported_hidingOne() async {
    newFile(join(projectFolderPath, 'lib', 'my_classes.dart'), '''
class MyClass1 {}
class MyClass2 {}
''');

    var content = '''
import 'package:test/my_classes.dart' hide MyClass1;
void f() {
  MyClas^
}
''';

    var expectedContent = '''
import 'package:test/my_classes.dart';
void f() {
  MyClass1
}
''';

    var completionLabel = 'MyClass1';

    await _checkCompletionEdits(
      mainFileUri,
      content,
      completionLabel,
      expectedContent,
    );
  }

  Future<void> test_unimportedSymbols_libraryImported_showingOther() async {
    newFile(join(projectFolderPath, 'lib', 'my_classes.dart'), '''
class MyClass1 {}
class MyClass2 {}
''');

    var content = '''
import 'package:test/my_classes.dart' show MyClass2;
void f() {
  MyClas^
}
''';

    var expectedContent = '''
import 'package:test/my_classes.dart' show MyClass1, MyClass2;
void f() {
  MyClass1
}
''';

    var completionLabel = 'MyClass1';

    await _checkCompletionEdits(
      mainFileUri,
      content,
      completionLabel,
      expectedContent,
    );
  }

  // Code completion doesn't include prefixes for auto-imports so when an
  // auto-import is added it must be unprefixed even if the library exists with
  // a prefix (we cannot modify the inserted text during resolve).
  Future<void> test_unimportedSymbols_libraryImported_withPrefix() async {
    newFile(join(projectFolderPath, 'lib', 'my_classes.dart'), '''
class MyClass1 {}
class MyClass2 {}
''');

    var content = '''
import 'package:test/my_classes.dart' as p1 show MyClass2;
void f() {
  MyClas^
}
''';

    var expectedContent = '''
import 'package:test/my_classes.dart' as p1 show MyClass2;
import 'package:test/my_classes.dart';
void f() {
  MyClass1
}
''';

    var completionLabel = 'MyClass1';

    await _checkCompletionEdits(
      mainFileUri,
      content,
      completionLabel,
      expectedContent,
    );
  }

  /// This test reproduces a bug where the pathKey hash used in
  /// available_declarations.dart would not change with the contents of the file
  /// (as it always used 0 as the modification stamp) which would prevent
  /// completion including items from files that were open (had overlays).
  /// https://github.com/Dart-Code/Dart-Code/issues/2286#issuecomment-658597532
  Future<void> test_unimportedSymbols_modifiedFiles() async {
    var otherFilePath = join(projectFolderPath, 'lib', 'other_file.dart');
    var otherFileUri = pathContext.toUri(otherFilePath);

    var mainFileCode = TestCode.parse('MyOtherClass^');
    await initialize();
    await openFile(mainFileUri, mainFileCode.code);
    await initialAnalysis;

    // Start with a blank file.
    newFile(otherFilePath, '');
    await openFile(otherFileUri, '');
    await pumpEventQueue(times: 5000);

    // Reopen the file with a class definition.
    await closeFile(otherFileUri);
    await openFile(otherFileUri, 'class MyOtherClass {}');
    await pumpEventQueue(times: 5000);

    // Ensure the class appears in completion.
    var completions = await getCompletion(
      mainFileUri,
      mainFileCode.position.position,
    );
    var matching = completions.where((c) => c.label == 'MyOtherClass').toList();
    expect(matching, hasLength(1));
  }

  Future<void> test_unimportedSymbols_namedConstructors() async {
    newFile(join(projectFolderPath, 'other_file.dart'), '''
/// This class is in another file.
class InOtherFile {
  InOtherFile.fromJson() {}
}
''');

    var content = '''
void f() {
  var a = InOtherF^
}
''';

    await initialize();
    var code = TestCode.parse(content);
    await openFile(mainFileUri, code.code);
    await initialAnalysis;
    var res = await getCompletion(mainFileUri, code.position.position);

    // Find the completion for the class in the other file.
    var completion = res.singleWhere(
      (c) => c.label == 'InOtherFile.fromJson()',
    );
    expect(completion, isNotNull);
    expect(completion.textEdit, isNotNull);

    // Expect no docs, this is added during resolve.
    expectDocumentation(completion, isNull);

    // Resolve the completion item (via server) to get any additional edits.
    // This is LSP's equiv of getSuggestionDetails() and is invoked by LSP
    // clients to populate additional info (in our case, any additional edits
    // for inserting the import).
    var resolved = await resolveCompletion(completion);
    expect(resolved, isNotNull);

    // Apply both the main completion edit and the additionalTextEdits atomically.
    var newContent = applyTextEdits(
      code.code,
      [
        toTextEdit(resolved.textEdit!),
      ].followedBy(resolved.additionalTextEdits!).toList(),
    );

    // Ensure both edits were made - the completion, and the inserted import.
    expect(
      newContent,
      equals('''
import '../other_file.dart';

void f() {
  var a = InOtherFile.fromJson
}
'''),
    );
  }

  Future<void> test_unimportedSymbols_overrides() async {
    newFile(join(projectFolderPath, 'lib', 'a.dart'), 'class A {}');
    newFile(join(projectFolderPath, 'lib', 'b.dart'), 'class B {}');
    newFile(join(projectFolderPath, 'lib', 'c.dart'), 'class C {}');
    newFile(join(projectFolderPath, 'lib', 'd.dart'), 'class D {}');

    newFile(join(projectFolderPath, 'lib', 'base.dart'), '''
import 'a.dart';
import 'b.dart';
import 'c.dart';
import 'd.dart';

abstract class Base {
  D? myMethod(A a, B b, C c) => null;
}
''');

    // A will already be imported
    // B will already be imported but with a prefix
    // C & D are not imported and need importing (return + parameter types)
    var content = '''
import 'package:test/a.dart';
import 'package:test/b.dart' as b;
import 'package:test/base.dart';

class BaseImpl extends Base {
  myMet^
}
''';

    await initialize();
    var code = TestCode.parse(content);
    await openFile(mainFileUri, code.code);
    await initialAnalysis;
    var res = await getCompletion(mainFileUri, code.position.position);

    var completion = res.singleWhere(
      (c) => c.label == 'override myMethod(A a, b.B b, C c) { … }',
    );
    var resolved = await resolveCompletion(completion);

    var newContent = applyTextEdits(
      code.code,
      [
        toTextEdit(resolved.textEdit!),
      ].followedBy(resolved.additionalTextEdits!).toList(),
    );

    expect(
      newContent,
      equals('''
import 'package:test/a.dart';
import 'package:test/b.dart' as b;
import 'package:test/base.dart';
import 'package:test/c.dart';
import 'package:test/d.dart';

class BaseImpl extends Base {
  @override
  D? myMethod(A a, b.B b, C c) {
    // TODO: implement myMethod
    return super.myMethod(a, b, c);
  }
}
'''),
    );
  }

  Future<void>
  test_unimportedSymbols_preferRelativeImportsLib_insideLib() async {
    _enableLints([LintNames.prefer_relative_imports]);
    var importingFilePath = join(
      projectFolderPath,
      'lib',
      'nested1',
      'main.dart',
    );
    var importingFileUri = pathContext.toUri(importingFilePath);
    var importedFilePath = join(
      projectFolderPath,
      'lib',
      'nested2',
      'imported.dart',
    );

    // Create a file that will be auto-imported from completion.
    newFile(importedFilePath, 'class MyClass {}');

    var content = '''
void f() {
  MyClas^
}
''';

    var expectedContent = '''
import '../nested2/imported.dart';

void f() {
  MyClass
}
''';

    var completionLabel = 'MyClass';

    await _checkCompletionEdits(
      importingFileUri,
      content,
      completionLabel,
      expectedContent,
    );
  }

  Future<void>
  test_unimportedSymbols_preferRelativeImportsLib_outsideLib() async {
    // Files outside of the lib folder should still get absolute imports to
    // files inside lib, even with the lint enabled.
    _enableLints([LintNames.prefer_relative_imports]);
    var importingFilePath = join(
      projectFolderPath,
      'bin',
      'nested1',
      'main.dart',
    );
    var importingFileUri = pathContext.toUri(importingFilePath);
    var importedFilePath = join(
      projectFolderPath,
      'lib',
      'nested2',
      'imported.dart',
    );

    // Create a file that will be auto-imported from completion.
    newFile(importedFilePath, 'class MyClass {}');

    var content = '''
void f() {
  MyClas^
}
''';

    var expectedContent = '''
import 'package:test/nested2/imported.dart';

void f() {
  MyClass
}
''';

    var completionLabel = 'MyClass';

    await _checkCompletionEdits(
      importingFileUri,
      content,
      completionLabel,
      expectedContent,
    );
  }

  Future<void> test_unimportedSymbols_unavailableIfDisabled() async {
    newFile(join(projectFolderPath, 'other_file.dart'), 'class InOtherFile {}');

    var content = '''
void f() {
  InOtherF^
}
''';

    // applyEdit is supported in setUp, but explicitly disable the suggestions.
    await initialize(
      initializationOptions: {
        ...?defaultInitializationOptions,
        'suggestFromUnimportedLibraries': false,
      },
    );
    var code = TestCode.parse(content);
    await openFile(mainFileUri, code.code);
    await initialAnalysis;
    var res = await getCompletion(mainFileUri, code.position.position);

    // Ensure the item doesn't appear in the results (because we might not
    // be able to execute the import edits if they're in another file).
    var completion = res.singleWhereOrNull((c) => c.label == 'InOtherFile');
    expect(completion, isNull);
  }

  Future<void> test_unimportedSymbols_unavailableWithoutApplyEdit() async {
    // If client doesn't advertise support for workspace/applyEdit, we won't
    // include suggestion sets.
    setApplyEditSupport(false);

    newFile(join(projectFolderPath, 'other_file.dart'), 'class InOtherFile {}');

    var content = '''
void f() {
  InOtherF^
}
''';

    await initialize();
    var code = TestCode.parse(content);
    await openFile(mainFileUri, code.code);
    await initialAnalysis;
    var res = await getCompletion(mainFileUri, code.position.position);

    // Ensure the item doesn't appear in the results (because we might not
    // be able to execute the import edits if they're in another file).
    var completion = res.singleWhereOrNull((c) => c.label == 'InOtherFile');
    expect(completion, isNull);
  }

  Future<void> test_unopenFile() async {
    var content = '''
class MyClass {
  String abcdefghij;
}

void f() {
  MyClass a;
  a.abc^
}
''';
    var code = TestCode.parse(content);

    newFile(mainFilePath, code.code);
    await initialize();
    var res = await getCompletion(mainFileUri, code.position.position);
    expect(res.any((c) => c.label == 'abcdefghij'), isTrue);
    var item = res.singleWhere((c) => c.label == 'abcdefghij');
    expect(
      item.insertTextFormat,
      anyOf(equals(InsertTextFormat.PlainText), isNull),
    );
    expect(item.insertText, anyOf(equals('abcdefghij'), isNull));
    var updated = applyTextEdits(code.code, [toTextEdit(item.textEdit!)]);
    expect(updated, contains('a.abcdefghij'));
  }

  /// Sets up the server with a file containing [content] and checks that
  /// accepting a specific completion produces [expectedContent].
  ///
  /// [content] should contain a `^` at the location where completion should be
  /// invoked/accepted.
  Future<void> _checkCompletionEdits(
    Uri fileUri,
    String content,
    String completionLabel,
    String expectedContent,
  ) async {
    var code = TestCode.parse(content);
    await initialize();
    await openFile(fileUri, code.code);
    await initialAnalysis;
    var res = await getCompletion(fileUri, code.position.position);

    var completion = res.where((c) => c.label == completionLabel).single;
    var resolvedCompletion = await resolveCompletion(completion);

    // Apply both the main completion edit and the additionalTextEdits atomically.
    var newContent = applyTextEdits(
      code.code,
      [
        toTextEdit(resolvedCompletion.textEdit!),
      ].followedBy(resolvedCompletion.additionalTextEdits!).toList(),
    );

    expect(newContent, equals(expectedContent));
  }

  Future<void> _checkResultsForTriggerCharacters(
    String content,
    List<String> triggerCharacters,
    Matcher expectedResults,
  ) async {
    var code = TestCode.parse(content);
    await initialize();
    await openFile(mainFileUri, code.code);

    for (var triggerCharacter in triggerCharacters) {
      var context = CompletionContext(
        triggerKind: CompletionTriggerKind.TriggerCharacter,
        triggerCharacter: triggerCharacter,
      );
      var res = await getCompletion(
        mainFileUri,
        code.position.position,
        context: context,
      );
      expect(
        res,
        expectedResults,
        reason: 'No completions when using $triggerCharacter',
      );
    }
  }
}

@reflectiveTest
class DartSnippetCompletionTest extends SnippetCompletionTest {
  Future<void> test_snippets_class() async {
    var content = '''
clas^
''';

    await initialize();
    var updated = await expectAndApplySnippet(
      content,
      prefix: ClassDeclaration.prefix,
      label: ClassDeclaration.label,
    );

    expect(updated, r'''
class ${1:ClassName} {
  $0
}
''');
  }

  /// Checks that the `enableSnippets` setting can disable snippets even if the
  /// client supports them.
  Future<void> test_snippets_disabled() async {
    var content = '^';

    // Support is set in setUp, but here we disable the user preference.
    await provideConfig(initialize, {'enableSnippets': false});

    await expectNoSnippets(content);
  }

  Future<void> test_snippets_doWhile() async {
    var content = '''
void f() {
  do^
}
''';

    await initialize();
    var updated = await expectAndApplySnippet(
      content,
      prefix: DoStatement.prefix,
      label: DoStatement.label,
    );

    expect(updated, r'''
void f() {
  do {
    $0
  } while (${1:condition});
}
''');
  }

  /// Snippets completions may abort if documents are modified (because they
  /// need to obtain resolved units when building edits) but they should not
  /// prevent non-Snippet completion results from being returned (because this
  /// happens frequently while typing).
  Future<void> test_snippets_failureDoesNotPreventNonSnippets() async {
    var content = '''
void f() {
  ^
}
''';
    var code = TestCode.parse(content);

    await initialize();
    await openFile(mainFileUri, code.code);
    await initialAnalysis;

    // Use a Completer to control when the completion handler starts computing.
    var completer = Completer<void>();
    CompletionHandler.delayAfterResolveForTests = completer.future;
    try {
      // Start the completion request but don't await it yet.
      var completionRequest = getCompletionList(
        mainFileUri,
        code.position.position,
      );
      // Modify the document to ensure the snippet requests will fail to build
      // edits and then allow the handler to continue.
      await replaceFile(222, mainFileUri, '');
      completer.complete();

      // Wait for the results.
      var result = await completionRequest;

      expect(result.items, isNotEmpty);
    } finally {
      // Ensure we never leave an incomplete future if anything above throws.
      CompletionHandler.delayAfterResolveForTests = null;
    }
  }

  Future<void>
  test_snippets_flutterStateless_notAvailable_notFlutterProject() async {
    var content = '''
class A {}

stle^

class B {}
''';

    await initialize();
    await expectNoSnippet(content, FlutterStatelessWidget.prefix);
  }

  Future<void> test_snippets_for() async {
    var content = '''
void f() {
  for^
}
''';

    await initialize();
    var updated = await expectAndApplySnippet(
      content,
      prefix: ForStatement.prefix,
      label: ForStatement.label,
    );

    expect(updated, r'''
void f() {
  for (var i = 0; i < ${1:count}; i++) {
    $0
  }
}
''');
  }

  Future<void> test_snippets_forIn() async {
    var content = '''
void f() {
  forin^
}
''';

    await initialize();
    var updated = await expectAndApplySnippet(
      content,
      prefix: ForInStatement.prefix,
      label: ForInStatement.label,
    );

    expect(updated, r'''
void f() {
  for (var ${1:element} in ${2:collection}) {
    $0
  }
}
''');
  }

  Future<void> test_snippets_functionClassMember() async {
    var content = '''
class A {
  fun^
}
''';

    await initialize();
    var updated = await expectAndApplySnippet(
      content,
      prefix: FunctionDeclaration.prefix,
      label: FunctionDeclaration.label,
    );

    expect(updated, r'''
class A {
  ${1:void} ${2:name}(${3:params}) {
    $0
  }
}
''');
  }

  Future<void> test_snippets_functionNested() async {
    var content = '''
void a() {
  fun^
}
''';

    await initialize();
    var updated = await expectAndApplySnippet(
      content,
      prefix: FunctionDeclaration.prefix,
      label: FunctionDeclaration.label,
    );

    expect(updated, r'''
void a() {
  ${1:void} ${2:name}(${3:params}) {
    $0
  }
}
''');
  }

  Future<void> test_snippets_functionTopLevel() async {
    var content = '''
fun^
''';

    await initialize();
    var updated = await expectAndApplySnippet(
      content,
      prefix: FunctionDeclaration.prefix,
      label: FunctionDeclaration.label,
    );

    expect(updated, r'''
${1:void} ${2:name}(${3:params}) {
  $0
}
''');
  }

  Future<void> test_snippets_if() async {
    var content = '''
void f() {
  if^
}
''';

    await initialize();
    var updated = await expectAndApplySnippet(
      content,
      prefix: IfStatement.prefix,
      label: IfStatement.label,
    );

    expect(updated, r'''
void f() {
  if (${1:condition}) {
    $0
  }
}
''');
  }

  Future<void> test_snippets_ifElse() async {
    var content = '''
void f() {
  if^
}
''';

    await initialize();
    var updated = await expectAndApplySnippet(
      content,
      prefix: IfElseStatement.prefix,
      label: IfElseStatement.label,
    );
    var fourSpaces = '    ';
    expect(updated, '''
void f() {
  if (\${1:condition}) {
    \$0
  } else {
$fourSpaces
  }
}
''');
  }

  /// Fetch snippets with itemDefaults enabled to ensure we don't return any
  /// values that match the defaults and that using the default range applies
  /// correctly.
  Future<void> test_snippets_itemDefaults() async {
    setCompletionListDefaults([
      'editRange',
      'insertTextMode',
      'insertTextFormat',
    ]);
    var content = '''
fu^
''';

    await initialize();
    var updated = await expectAndApplySnippet(
      content,
      prefix: FunctionDeclaration.prefix,
      label: FunctionDeclaration.label,
    );

    expect(updated, r'''
${1:void} ${2:name}(${3:params}) {
  $0
}
''');
  }

  Future<void> test_snippets_mainFunction() async {
    var content = '''
class A {}

main^

class B {}
''';

    await initialize();
    var updated = await expectAndApplySnippet(
      content,
      prefix: MainFunction.prefix,
      label: MainFunction.label,
    );

    expect(updated, r'''
class A {}

void main(List<String> args) {
  $0
}

class B {}
''');
  }

  Future<void> test_snippets_notSupported() async {
    var content = '^';

    // If we don't send support for Snippet CompletionItem kinds, we don't
    // expect any snippets at all.
    setCompletionItemSnippetSupport(false);
    await initialize();
    var code = TestCode.parse(content);
    await openFile(mainFileUri, code.code);
    var res = await getCompletion(mainFileUri, code.position.position);
    expect(res.any((c) => c.kind == CompletionItemKind.Snippet), isFalse);
  }

  Future<void> test_snippets_switch() async {
    var content = '''
void f() {
  swi^
}
''';

    await initialize();
    var updated = await expectAndApplySnippet(
      content,
      prefix: SwitchStatement.prefix,
      label: SwitchStatement.label,
    );

    expect(updated, r'''
void f() {
  switch (${1:expression}) {
    case ${2:value}:
      $0
      break;
    default:
  }
}
''');
  }

  Future<void> test_snippets_testBlock() async {
    mainFilePath = join(projectFolderPath, 'test', 'foo_test.dart');
    var content = '''
void f() {
  test^
}
''';

    await initialize();
    var updated = await expectAndApplySnippet(
      content,
      prefix: TestDefinition.prefix,
      label: TestDefinition.label,
    );

    expect(updated, r'''
import 'package:test/test.dart';

void f() {
  test('${1:test name}', () {
    $0
  });
}
''');
  }

  Future<void> test_snippets_testGroupBlock() async {
    mainFilePath = join(projectFolderPath, 'test', 'foo_test.dart');
    var content = '''
void f() {
  group^
}
''';

    await initialize();
    var updated = await expectAndApplySnippet(
      content,
      prefix: TestGroupDefinition.prefix,
      label: TestGroupDefinition.label,
    );

    expect(updated, r'''
import 'package:test/test.dart';

void f() {
  group('${1:group name}', () {
    $0
  });
}
''');
  }

  Future<void> test_snippets_tryCatch() async {
    var content = '''
void f() {
  tr^
}
''';

    await initialize();
    var updated = await expectAndApplySnippet(
      content,
      prefix: TryCatchStatement.prefix,
      label: TryCatchStatement.label,
    );
    var fourSpaces = '    ';
    expect(updated, '''
void f() {
  try {
    \$0
  } catch (\${1:e}) {
$fourSpaces
  }
}
''');
  }

  Future<void> test_snippets_while() async {
    var content = '''
void f() {
  while^
}
''';

    await initialize();
    var updated = await expectAndApplySnippet(
      content,
      prefix: WhileStatement.prefix,
      label: WhileStatement.label,
    );

    expect(updated, r'''
void f() {
  while (${1:condition}) {
    $0
  }
}
''');
  }
}

@reflectiveTest
class FlutterSnippetCompletionTest extends SnippetCompletionTest {
  /// Standard import statements expected for basic Widgets.
  String get expectedImports => '''
import 'package:flutter/widgets.dart';''';

  /// Constructor params expected on Widget classes.
  String get expectedWidgetConstructorParams => '({super.key})';

  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfig(flutter: true);
  }

  Future<void> test_snippets_flutterStateful() async {
    var content = '''
import 'package:flutter/widgets.dart';

class A {}

stful^

class B {}
''';

    await initialize();
    var updated = await expectAndApplySnippet(
      content,
      prefix: FlutterStatefulWidget.prefix,
      label: FlutterStatefulWidget.label,
    );

    expect(updated, '''
import 'package:flutter/widgets.dart';

class A {}

class \${1:MyWidget} extends StatefulWidget {
  const \${1:MyWidget}$expectedWidgetConstructorParams;

  @override
  State<\${1:MyWidget}> createState() => _\${1:MyWidget}State();
}

class _\${1:MyWidget}State extends State<\${1:MyWidget}> {
  @override
  Widget build(BuildContext context) {
    return \${0:const Placeholder()};
  }
}

class B {}
''');
  }

  Future<void> test_snippets_flutterStatefulWithAnimationController() async {
    var content = '''
import 'package:flutter/widgets.dart';

class A {}

stanim^

class B {}
''';

    await initialize();
    var updated = await expectAndApplySnippet(
      content,
      prefix: FlutterStatefulWidgetWithAnimationController.prefix,
      label: FlutterStatefulWidgetWithAnimationController.label,
    );

    expect(updated, '''
import 'package:flutter/widgets.dart';

class A {}

class \${1:MyWidget} extends StatefulWidget {
  const \${1:MyWidget}$expectedWidgetConstructorParams;

  @override
  State<\${1:MyWidget}> createState() => _\${1:MyWidget}State();
}

class _\${1:MyWidget}State extends State<\${1:MyWidget}>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return \${0:const Placeholder()};
  }
}

class B {}
''');
  }

  Future<void> test_snippets_flutterStateless() async {
    var content = '''
import 'package:flutter/widgets.dart';

class A {}

stle^

class B {}
''';

    await initialize();
    var updated = await expectAndApplySnippet(
      content,
      prefix: FlutterStatelessWidget.prefix,
      label: FlutterStatelessWidget.label,
    );

    expect(updated, '''
import 'package:flutter/widgets.dart';

class A {}

class \${1:MyWidget} extends StatelessWidget {
  const \${1:MyWidget}$expectedWidgetConstructorParams;

  @override
  Widget build(BuildContext context) {
    return \${0:const Placeholder()};
  }
}

class B {}
''');
  }

  Future<void> test_snippets_flutterStateless_addsImports() async {
    var content = '''
class A {}

stle^

class B {}
''';

    await initialize();
    var updated = await expectAndApplySnippet(
      content,
      prefix: FlutterStatelessWidget.prefix,
      label: FlutterStatelessWidget.label,
    );

    expect(updated, '''
$expectedImports

class A {}

class \${1:MyWidget} extends StatelessWidget {
  const \${1:MyWidget}$expectedWidgetConstructorParams;

  @override
  Widget build(BuildContext context) {
    return \${0:const Placeholder()};
  }
}

class B {}
''');
  }

  Future<void> test_snippets_flutterStateless_addsImports_onlyPrefix() async {
    var content = '''
stless^
''';

    await initialize();
    var updated = await expectAndApplySnippet(
      content,
      prefix: FlutterStatelessWidget.prefix,
      label: FlutterStatelessWidget.label,
    );

    expect(updated, '''
$expectedImports

class \${1:MyWidget} extends StatelessWidget {
  const \${1:MyWidget}$expectedWidgetConstructorParams;

  @override
  Widget build(BuildContext context) {
    return \${0:const Placeholder()};
  }
}
''');
  }

  Future<void> test_snippets_flutterStateless_addsImports_zeroOffset() async {
    var content = '''
^
'''; // Deliberate trailing newline to ensure imports aren't inserted at "end".

    await initialize();
    var updated = await expectAndApplySnippet(
      content,
      prefix: FlutterStatelessWidget.prefix,
      label: FlutterStatelessWidget.label,
    );

    expect(updated, '''
$expectedImports

class \${1:MyWidget} extends StatelessWidget {
  const \${1:MyWidget}$expectedWidgetConstructorParams;

  @override
  Widget build(BuildContext context) {
    return \${0:const Placeholder()};
  }
}
''');
  }

  Future<void> test_snippets_flutterStateless_notAvailable_notTopLevel() async {
    var content = '''
class A {

  stle^

}
''';

    await initialize();
    await expectNoSnippet(content, FlutterStatelessWidget.prefix);
  }

  Future<void> test_snippets_flutterStateless_outsideAnalysisRoot() async {
    var content = '''
stle^
''';
    var code = TestCode.parse(content);

    await initialize();
    var otherFileUri = pathContext.toUri(convertPath('/other/file.dart'));
    await openFile(otherFileUri, code.code);
    var res = await getCompletion(otherFileUri, code.position.position);
    var snippetItems = res.where((c) => c.kind == CompletionItemKind.Snippet);
    expect(snippetItems, hasLength(0));
  }
}

abstract class SnippetCompletionTest extends AbstractLspAnalysisServerTest
    with CompletionTestMixin {
  /// Expect that there is a snippet for [prefix] at [position] with the label
  /// [label] and return the results of applying it to [content].
  Future<String> expectAndApplySnippet(
    String content, {
    required String prefix,
    required String label,
  }) async {
    var code = TestCode.parse(content);
    var (snippet: snippet, defaults: defaults) = await expectSnippet(
      code,
      prefix: prefix,
      label: label,
    );

    var textEdit = snippet.textEdit;
    var textEditText = snippet.textEditText;
    var additionalTextEdits = snippet.additionalTextEdits;

    var edits = [
      // Additional TextEdits come first, because if they have the same offset
      // as edits in the normal edit, they will be inserted first.
      // https://github.com/microsoft/vscode/issues/143888.
      ...?additionalTextEdits,
      // Then we also either have an edit itself or we just have textEditText
      // and a default range.
      if (textEdit != null)
        toTextEdit(textEdit)
      else
        TextEdit(
          newText: textEditText!,
          range: defaults!.editRange!.map(
            (ranges) =>
                throw 'Unexpected snippet with different insert/replace ranges',
            (range) => range,
          ),
        ),
    ];

    // Also apply the edit and check that it went in the right place with the
    // correct formatting. Edit groups will just appear in the raw textmate
    // snippet syntax here, as we don't do any special handling of them (and
    // assume what's coded here is correct, and that the client will correctly
    // interpret them).
    var updated = applyTextEdits(code.code, edits);
    return updated;
  }

  /// Expect that there is no snippet for [prefix] at the position of `^` within
  /// [content].
  Future<void> expectNoSnippet(String content, String prefix) async {
    var code = TestCode.parse(content);
    await openFile(mainFileUri, code.code);
    var res = await getCompletion(mainFileUri, code.position.position);
    var hasSnippet = res.any((c) => c.filterText == prefix);
    expect(hasSnippet, isFalse);
  }

  /// Expect that there are no snippets at the position of `^` within [content].
  Future<void> expectNoSnippets(String content) async {
    var code = TestCode.parse(content);
    await openFile(mainFileUri, code.code);
    var res = await getCompletion(mainFileUri, code.position.position);
    var hasAnySnippet = res.any((c) => c.kind == CompletionItemKind.Snippet);
    expect(hasAnySnippet, isFalse);
  }

  /// Expect that there is a snippet for [prefix] with the label [label] at
  /// [position] in [content].
  Future<({CompletionItem snippet, CompletionItemDefaults? defaults})>
  expectSnippet(
    TestCode code, {
    required String prefix,
    required String label,
  }) async {
    await openFile(mainFileUri, code.code);
    var res = await getCompletionList(mainFileUri, code.position.position);
    var item = res.items.singleWhere(
      (c) =>
          c.kind == CompletionItemKind.Snippet &&
          (c.filterText ?? c.label) == prefix &&
          c.label == label,
    );
    expect(item.insertTextFormat, InsertTextFormat.Snippet);
    expect(item.insertText, isNull);
    // We either expect textEdit (if we had a range) or textEditText (or we did
    // not), but never both.
    expect(item.textEdit == null, item.textEditText != null);
    expect(item.textEditText != null, res.itemDefaults?.editRange != null);
    return (snippet: item, defaults: res.itemDefaults);
  }

  @override
  void setUp() {
    super.setUp();

    // Snippet completion tests have incomplete code.
    failTestOnErrorDiagnostic = false;

    setCompletionItemSnippetSupport();
  }
}
