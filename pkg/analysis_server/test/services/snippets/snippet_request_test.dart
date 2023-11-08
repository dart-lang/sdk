// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/snippets/dart_snippet_request.dart';
import 'package:analysis_server/src/services/snippets/snippet_context.dart';
import 'package:analyzer/src/test_utilities/platform.dart';
import 'package:analyzer/src/test_utilities/test_code_format.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../abstract_single_unit.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SnippetRequestTest);
  });
}

@reflectiveTest
class SnippetRequestTest extends AbstractSingleUnitTest {
  @override
  void setUp() {
    super.setUp();
    verifyNoTestUnitErrors = false;
  }

  Future<void> test_annotation() async {
    await testRequest(r'''
@[!depre^!]
class A {}
''', SnippetContext.inAnnotation);
  }

  Future<void> test_argumentName() async {
    await testRequest(r'''
void({required int switch}) {
  f([!sw^!]:);
}
''', SnippetContext.inName);
  }

  Future<void> test_block_forBody() async {
    await testRequest(r'''
foo() {
  for (var i = 0; i < 10; i++) {
    [!^!]
  }
}
''', SnippetContext.inBlock);
  }

  Future<void> test_class_atEnd() async {
    await testRequest(r'''
class A {
  foo() {}

  [!^!]
}
''', SnippetContext.inClass);
  }

  Future<void> test_class_atEnd_partialIdentifier() async {
    await testRequest(r'''
class A {
  foo() {}

  [!mysnip^!]
}
''', SnippetContext.inClass);
  }

  Future<void> test_class_atStart() async {
    await testRequest(r'''
class A {
  [!^!]

  foo() {}
}
''', SnippetContext.inClass);
  }

  Future<void> test_class_atStart_partialIdentifier() async {
    await testRequest(r'''
class A {
  [!mysnip^!]

  foo() {}
}
''', SnippetContext.inClass);
  }

  Future<void> test_class_betweenMembers() async {
    await testRequest(r'''
class A {
  foo() {}

  [!^!]

  bar() {}
}
''', SnippetContext.inClass);
  }

  Future<void> test_class_betweenMembers_partialIdentifier() async {
    await testRequest(r'''
class A {
  foo() {}

  [!mysnip^!]

  bar() {}
}
''', SnippetContext.inClass);
  }

  Future<void> test_class_empty() async {
    await testRequest(r'''
class A {
  [!^!]
}
''', SnippetContext.inClass);
  }

  Future<void> test_class_empty_partialIdentifier() async {
    await testRequest(r'''
class A {
  [!mysnip^!]
}
''', SnippetContext.inClass);
  }

  Future<void> test_comment_dartDoc() async {
    await testRequest(r'''
/// [!^!]
class A {}
''', SnippetContext.inComment);
  }

  Future<void> test_comment_dartDoc_reference_member() async {
    await testRequest(r'''
class A {
  /// [ [!A^!] ]
  foo() {}
}
''', SnippetContext.inComment);
  }

  Future<void> test_comment_dartDoc_reference_topLevel() async {
    await testRequest(r'''
/// [ [!A^!] ]
class A {}
''', SnippetContext.inComment);
  }

  Future<void> test_comment_multiline_member() async {
    await testRequest(r'''
class A {
  /*
   * [!^!]
   */
  foo() {}
}
''', SnippetContext.inComment);
  }

  Future<void> test_comment_multiline_topLevel() async {
    await testRequest(r'''
/*
 * [!^!]
 */
class A {}
''', SnippetContext.inComment);
  }

  Future<void> test_comment_singleLine_member() async {
    await testRequest(r'''
class A {
  // [!^!]
  foo () {}
}
''', SnippetContext.inComment);
  }

  Future<void> test_comment_singleLine_topLevel() async {
    await testRequest(r'''
// [!^!]
class A {}
''', SnippetContext.inComment);
  }

  Future<void> test_enum() async {
    await testRequest(r'''
enum A {
  [!^!]
}
''', SnippetContext.inClass);
  }

  Future<void> test_expression_constructor() async {
    await testRequest(r'''
final a = new [!^!]
''', SnippetContext.inConstructorInvocation);
  }

  Future<void> test_expression_constructorName() async {
    await testRequest(r'''
class A {
  A.foo();
}
final a = new A.[!fo^!]
''', SnippetContext.inConstructorInvocation);
  }

  Future<void> test_expression_functionCall() async {
    await testRequest(r'''
foo() {
  print([!^!]
}
''', SnippetContext.inExpression);
  }

  Future<void> test_extension() async {
    await testRequest(r'''
extension on Object {
  [!^!]
}
''', SnippetContext.inClass);
  }

  Future<void> test_function_atEnd() async {
    await testRequest(r'''
foo() {
  var a = 1;
  [!^!]
}
''', SnippetContext.inBlock);
  }

  Future<void> test_function_atEnd_partialIdentifier() async {
    await testRequest(r'''
foo() {
  var a = 1;
  [!mysnip^!]
}
''', SnippetContext.inBlock);
  }

  Future<void> test_function_atStart() async {
    await testRequest(r'''
foo() {
  [!^!]
  var a = 1;
}
''', SnippetContext.inBlock);
  }

  Future<void> test_function_atStart_partialIdentifier() async {
    await testRequest(r'''
foo() {
  [!mysnip^!]
  var a = 1;
}
''', SnippetContext.inBlock);
  }

  Future<void> test_function_betweenStatements() async {
    await testRequest(r'''
foo() {
  var a = 1;
  [!^!]
  var b = 1;
}
''', SnippetContext.inBlock);
  }

  Future<void> test_function_betweenStatements_partialIdentifier() async {
    await testRequest(r'''
foo() {
  var a = 1;
  [!mysnip^!]
  var b = 1;
}
''', SnippetContext.inBlock);
  }

  Future<void> test_function_empty() async {
    await testRequest(r'''
foo() {
  [!^!]
}
''', SnippetContext.inBlock);
  }

  Future<void> test_function_empty_partialIdentifier() async {
    await testRequest(r'''
foo() {
  [!mysnip^!]
}
''', SnippetContext.inBlock);
  }

  Future<void> test_initializingFormal() async {
    await testRequest(r'''
class A {
  int a;
  A(this.[!f^!]);
}
''', SnippetContext.inQualifiedMemberAccess);
  }

  Future<void> test_method_atEnd() async {
    await testRequest(r'''
class A {
  foo() {
    var a = 1;
    [!^!]
  }
}
''', SnippetContext.inBlock);
  }

  Future<void> test_method_atEnd_partialIdentifier() async {
    await testRequest(r'''
class A {
  foo() {
    var a = 1;
    [!mysnip^!]
  }
}
''', SnippetContext.inBlock);
  }

  Future<void> test_method_atStart() async {
    await testRequest(r'''
class A {
  foo() {
    [!^!]
    var a = 1;
  }
}
''', SnippetContext.inBlock);
  }

  Future<void> test_method_atStart_partialIdentifier() async {
    await testRequest(r'''
class A {
  foo() {
    [!mysnip^!]
    var a = 1;
  }
}
''', SnippetContext.inBlock);
  }

  Future<void> test_method_betweenStatements() async {
    await testRequest(r'''
class A {
  foo() {
    var a = 1;
    [!^!]
    var b = 1;
  }
}
''', SnippetContext.inBlock);
  }

  Future<void> test_method_betweenStatements_partialIdentifier() async {
    await testRequest(r'''
class A {
  foo() {
    var a = 1;
    [!mysnip^!]
    var b = 1;
  }
}
''', SnippetContext.inBlock);
  }

  Future<void> test_method_call() async {
    await testRequest(r'''
class A {
  void foo() {
    this.[!^!]
  }
}
''', SnippetContext.inQualifiedMemberAccess);
  }

  Future<void> test_method_call_partialIdentifier() async {
    await testRequest(r'''
class A {
  void foo() {
    this.[!fo^!]
  }
}
''', SnippetContext.inQualifiedMemberAccess);
  }

  Future<void> test_method_declaration() async {
    await testRequest(r'''
class A {
  void [!foo^!]
}
''', SnippetContext.inIdentifierDeclaration);
  }

  Future<void> test_method_empty() async {
    await testRequest(r'''
class A {
  foo() {
    [!^!]
  }
}
''', SnippetContext.inBlock);
  }

  Future<void> test_method_empty_partialIdentifier() async {
    await testRequest(r'''
class A {
  foo() {
    [!mysnip^!]
  }
}
''', SnippetContext.inBlock);
  }

  Future<void> test_mixin() async {
    await testRequest(r'''
mixin A {
  [!^!]
}
''', SnippetContext.inClass);
  }

  Future<void> test_pattern_switch() async {
    await testRequest(r'''
f(String a) => switch (a) {
    [!^!]
};
''', SnippetContext.inPattern);
  }

  Future<void> test_pattern_switch_partialIdentifier() async {
    await testRequest(r'''
f(String a) => switch (a) {
    [!sw^!]
};
''', SnippetContext.inPattern);
  }

  Future<void> test_statement_forCondition() async {
    await testRequest(r'''
foo() {
  for (var i = [!^!]
}
''', SnippetContext.inExpression);
  }

  Future<void> test_statement_forCondition_partialIdentifier() async {
    await testRequest(r'''
foo() {
  for (var i = [!a^!]
}
''', SnippetContext.inExpression);
  }

  Future<void> test_string() async {
    await testRequest(r'''
const a = '[!^!]';
''', SnippetContext.inString);
  }

  Future<void> test_string_raw() async {
    await testRequest(r'''
const a = r'[!^!]';
''', SnippetContext.inString);
  }

  Future<void> test_string_unterminated() async {
    await testRequest(r'''
const a = r'[!^!]
''', SnippetContext.inString);
  }

  Future<void> test_topLevel_atEnd() async {
    await testRequest(r'''
class A {}

[!^!]
''', SnippetContext.atTopLevel);
  }

  Future<void> test_topLevel_atEnd_partialIdentifier() async {
    await testRequest(r'''
class A {}

[!mysnip^!]
''', SnippetContext.atTopLevel);
  }

  Future<void> test_topLevel_atStart() async {
    await testRequest(r'''
[!^!]

class A {}
''', SnippetContext.atTopLevel);
  }

  Future<void> test_topLevel_atStart_partialIdentifier() async {
    await testRequest(r'''
[!mysnip^!]

class A {}
''', SnippetContext.atTopLevel);
  }

  Future<void> test_topLevel_betweenClasses() async {
    await testRequest(r'''
class A {}

[!^!]

class B {}
''', SnippetContext.atTopLevel);
  }

  Future<void> test_topLevel_betweenClasses_partialIdentifier() async {
    await testRequest(r'''
class A {}

[!mysnip^!]

class B {}
''', SnippetContext.atTopLevel);
  }

  Future<void> test_topLevel_empty() async {
    await testRequest('[!^!]', SnippetContext.atTopLevel);
  }

  Future<void> test_topLevel_empty_partialIdentifier() async {
    await testRequest('[!mysnip^!]', SnippetContext.atTopLevel);
  }

  Future<void> test_variable_value_partialIdentifier() async {
    await testRequest(r'''
foo() {
  var a = [!a^!]
}
''', SnippetContext.inExpression);
  }

  Future<void> test_variableDeclaration() async {
    await testRequest(r'''
foo() {
  var [!^!]
}
''', SnippetContext.inIdentifierDeclaration);
  }

  Future<void> test_variableDeclaration_partialIdentifier() async {
    await testRequest(r'''
foo() {
  var [!a^!]
}
''', SnippetContext.inIdentifierDeclaration);
  }

  Future<void> test_variableDeclaration_value() async {
    await testRequest(r'''
foo() {
  var a = [!^!]
}
''', SnippetContext.inExpression);
  }

  /// Checks that [content] produces a context of [expectedContext] where the
  /// character '^' in [content] represents the supplied offset and the range
  /// surrounded `[!` by brackets `!]` is the expected replacement range.
  ///
  /// `^`, `[!` and `!]` will be removed from the code before resolving.
  Future<void> testRequest(
      String content, SnippetContext expectedContext) async {
    final code = TestCode.parse(normalizeNewlinesForPlatform(content));
    final offset = code.position.offset;
    final expectedReplacementRange = code.range.sourceRange;
    await resolveTestCode(code.code);

    final request = DartSnippetRequest(
      unit: testAnalysisResult,
      offset: offset,
    );

    expect(request.filePath, testFile.path);
    expect(request.offset, offset);
    expect(request.context, expectedContext);
    expect(request.replacementRange, expectedReplacementRange);
  }
}
