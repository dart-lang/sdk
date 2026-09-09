// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/snippets/dart_snippet_request.dart';
import 'package:analysis_server/src/services/snippets/snippet_context.dart';
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
''', .inAnnotation);
  }

  Future<void> test_argumentName() async {
    await testRequest(r'''
void({required int switch}) {
  f([!sw^!]:);
}
''', .inName);
  }

  Future<void> test_block_forBody() async {
    await testRequest(r'''
foo() {
  for (var i = 0; i < 10; i++) {
    [!^!]
  }
}
''', .inBlock);
  }

  Future<void> test_class_atEnd() async {
    await testRequest(r'''
class A {
  foo() {}

  [!^!]
}
''', .inClassBody);
  }

  Future<void> test_class_atEnd_partialIdentifier() async {
    await testRequest(r'''
class A {
  foo() {}

  [!mysnip^!]
}
''', .inClassBody);
  }

  Future<void> test_class_atStart() async {
    await testRequest(r'''
class A {
  [!^!]

  foo() {}
}
''', .inClassBody);
  }

  Future<void> test_class_atStart_partialIdentifier() async {
    await testRequest(r'''
class A {
  [!mysnip^!]

  foo() {}
}
''', .inClassBody);
  }

  Future<void> test_class_beforeBody() async {
    await testRequest(r'''
class C [!^!]{}
''', .inClassDeclaration);
  }

  Future<void> test_class_betweenMembers() async {
    await testRequest(r'''
class A {
  foo() {}

  [!^!]

  bar() {}
}
''', .inClassBody);
  }

  Future<void> test_class_betweenMembers_partialIdentifier() async {
    await testRequest(r'''
class A {
  foo() {}

  [!mysnip^!]

  bar() {}
}
''', .inClassBody);
  }

  Future<void> test_class_empty() async {
    await testRequest(r'''
class A {
  [!^!]
}
''', .inClassBody);
  }

  Future<void> test_class_empty_partialIdentifier() async {
    await testRequest(r'''
class A {
  [!mysnip^!]
}
''', .inClassBody);
  }

  Future<void> test_class_primaryConstructor_emptyBody() async {
    await testRequest(r'''
class C() [!^!];
''', .inClassDeclaration);
  }

  Future<void> test_comment_dartDoc() async {
    await testRequest(r'''
/// [!^!]
class A {}
''', .inComment);
  }

  Future<void> test_comment_dartDoc_reference_member() async {
    await testRequest(r'''
class A {
  /// [ [!A^!] ]
  foo() {}
}
''', .inComment);
  }

  Future<void> test_comment_dartDoc_reference_topLevel() async {
    await testRequest(r'''
/// [ [!A^!] ]
class A {}
''', .inComment);
  }

  Future<void> test_comment_multiline_member() async {
    await testRequest(r'''
class A {
  /*
   * [!^!]
   */
  foo() {}
}
''', .inComment);
  }

  Future<void> test_comment_multiline_topLevel() async {
    await testRequest(r'''
/*
 * [!^!]
 */
class A {}
''', .inComment);
  }

  Future<void> test_comment_singleLine_member() async {
    await testRequest(r'''
class A {
  // [!^!]
  foo () {}
}
''', .inComment);
  }

  Future<void> test_comment_singleLine_topLevel() async {
    await testRequest(r'''
// [!^!]
class A {}
''', .inComment);
  }

  Future<void> test_dotShorthand_constructor() async {
    await testRequest(r'''
String _ = .[!^fromCharCode!]('42');
''', .inDotShorthand);
  }

  Future<void> test_dotShorthand_invocation() async {
    await testRequest(r'''
int _ = .[!^parse!]('42');
''', .inDotShorthand);
  }

  Future<void> test_dotShorthand_noIdentifier() async {
    await testRequest(r'''
String _ = .[!^!];
''', .inDotShorthand);
  }

  Future<void> test_dotShorthand_propertyAccess() async {
    await testRequest(r'''
Duration _ = .[!^zero!];
''', .inDotShorthand);
  }

  Future<void> test_enum_constants() async {
    await testRequest(r'''
enum A {
  [!^!]
}
''', .inEnumConstants);
  }

  Future<void> test_enum_constants_args() async {
    await testRequest(r'''
enum A {
  a([!^!]);
}
''', .inConstantExpression);
  }

  Future<void> test_enum_members() async {
    await testRequest(r'''
enum A {
  a;
  [!^!]
}
''', .inEnumMembers);
  }

  Future<void> test_expression_constructor() async {
    await testRequest(r'''
final a = new [!^!]
''', .inConstructorInvocation);
  }

  Future<void> test_expression_constructorName() async {
    await testRequest(r'''
class A {
  A.foo();
}
final a = new A.[!fo^!]
''', .inConstructorInvocation);
  }

  Future<void> test_expression_functionCall() async {
    await testRequest(r'''
foo() {
  print([!^!]
}
''', .inExpression);
  }

  Future<void> test_extension() async {
    await testRequest(r'''
extension on Object {
  [!^!]
}
''', .inClassBody);
  }

  Future<void> test_function_atEnd() async {
    await testRequest(r'''
foo() {
  var a = 1;
  [!^!]
}
''', .inBlock);
  }

  Future<void> test_function_atEnd_partialIdentifier() async {
    await testRequest(r'''
foo() {
  var a = 1;
  [!mysnip^!]
}
''', .inBlock);
  }

  Future<void> test_function_atStart() async {
    await testRequest(r'''
foo() {
  [!^!]
  var a = 1;
}
''', .inBlock);
  }

  Future<void> test_function_atStart_partialIdentifier() async {
    await testRequest(r'''
foo() {
  [!mysnip^!]
  var a = 1;
}
''', .inBlock);
  }

  Future<void> test_function_betweenStatements() async {
    await testRequest(r'''
foo() {
  var a = 1;
  [!^!]
  var b = 1;
}
''', .inBlock);
  }

  Future<void> test_function_betweenStatements_partialIdentifier() async {
    await testRequest(r'''
foo() {
  var a = 1;
  [!mysnip^!]
  var b = 1;
}
''', .inBlock);
  }

  Future<void> test_function_empty() async {
    await testRequest(r'''
foo() {
  [!^!]
}
''', .inBlock);
  }

  Future<void> test_function_empty_partialIdentifier() async {
    await testRequest(r'''
foo() {
  [!mysnip^!]
}
''', .inBlock);
  }

  Future<void> test_importPrefixMember() async {
    await testRequest(r'''
import 'dart:async' as a;

void f() {
  a.[!^!]
}
''', .inQualifiedMemberAccess);
  }

  Future<void> test_initializingFormal() async {
    await testRequest(r'''
class A {
  int a;
  A(this.[!f^!]);
}
''', .inQualifiedMemberAccess);
  }

  Future<void> test_method_atEnd() async {
    await testRequest(r'''
class A {
  foo() {
    var a = 1;
    [!^!]
  }
}
''', .inBlock);
  }

  Future<void> test_method_atEnd_partialIdentifier() async {
    await testRequest(r'''
class A {
  foo() {
    var a = 1;
    [!mysnip^!]
  }
}
''', .inBlock);
  }

  Future<void> test_method_atStart() async {
    await testRequest(r'''
class A {
  foo() {
    [!^!]
    var a = 1;
  }
}
''', .inBlock);
  }

  Future<void> test_method_atStart_partialIdentifier() async {
    await testRequest(r'''
class A {
  foo() {
    [!mysnip^!]
    var a = 1;
  }
}
''', .inBlock);
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
''', .inBlock);
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
''', .inBlock);
  }

  Future<void> test_method_call() async {
    await testRequest(r'''
class A {
  void foo() {
    this.[!^!]
  }
}
''', .inQualifiedMemberAccess);
  }

  Future<void> test_method_call_partialIdentifier() async {
    await testRequest(r'''
class A {
  void foo() {
    this.[!fo^!]
  }
}
''', .inQualifiedMemberAccess);
  }

  Future<void> test_method_declaration() async {
    await testRequest(r'''
class A {
  void [!foo^!]
}
''', .inIdentifierDeclaration);
  }

  Future<void> test_method_empty() async {
    await testRequest(r'''
class A {
  foo() {
    [!^!]
  }
}
''', .inBlock);
  }

  Future<void> test_method_empty_partialIdentifier() async {
    await testRequest(r'''
class A {
  foo() {
    [!mysnip^!]
  }
}
''', .inBlock);
  }

  Future<void> test_mixin() async {
    await testRequest(r'''
mixin A {
  [!^!]
}
''', .inClassBody);
  }

  Future<void> test_pattern_switch() async {
    await testRequest(r'''
f(String a) => switch (a) {
    [!^!]
};
''', .inPattern);
  }

  Future<void> test_pattern_switch_partialIdentifier() async {
    await testRequest(r'''
f(String a) => switch (a) {
    [!sw^!]
};
''', .inPattern);
  }

  Future<void> test_prefixedEnumMember() async {
    await testRequest(r'''
import 'test.dart' as self;

enum MyEnum {
  one,
  two,
}

void f() {
  self.MyEnum.[!^!]
}
''', .inQualifiedMemberAccess);
  }

  Future<void> test_return_expression() async {
    await testRequest(r'''
int f() {
  return [!sw^!]
}
''', .inExpression);
  }

  Future<void> test_return_expression_empty() async {
    await testRequest(r'''
int f() {
  return [!^!]
}
''', .inExpression);
  }

  Future<void> test_statement_forCondition() async {
    await testRequest(r'''
foo() {
  for (var i = [!^!]
}
''', .inExpression);
  }

  Future<void> test_statement_forCondition_partialIdentifier() async {
    await testRequest(r'''
foo() {
  for (var i = [!a^!]
}
''', .inExpression);
  }

  Future<void> test_string() async {
    await testRequest(r'''
const a = '[!^!]';
''', .inString);
  }

  Future<void> test_string_raw() async {
    await testRequest(r'''
const a = r'[!^!]';
''', .inString);
  }

  Future<void> test_string_unterminated() async {
    await testRequest(r'''
const a = r'[!^!]
''', .inString);
  }

  Future<void> test_topLevel_atEnd() async {
    await testRequest(r'''
class A {}

[!^!]
''', .atTopLevel);
  }

  Future<void> test_topLevel_atEnd_partialIdentifier() async {
    await testRequest(r'''
class A {}

[!mysnip^!]
''', .atTopLevel);
  }

  Future<void> test_topLevel_atStart() async {
    await testRequest(r'''
[!^!]

class A {}
''', .atTopLevel);
  }

  Future<void> test_topLevel_atStart_partialIdentifier() async {
    await testRequest(r'''
[!mysnip^!]

class A {}
''', .atTopLevel);
  }

  Future<void> test_topLevel_betweenClasses() async {
    await testRequest(r'''
class A {}

[!^!]

class B {}
''', .atTopLevel);
  }

  Future<void> test_topLevel_betweenClasses_partialIdentifier() async {
    await testRequest(r'''
class A {}

[!mysnip^!]

class B {}
''', .atTopLevel);
  }

  Future<void> test_topLevel_empty() async {
    await testRequest('[!^!]', .atTopLevel);
  }

  Future<void> test_topLevel_empty_partialIdentifier() async {
    await testRequest('[!mysnip^!]', .atTopLevel);
  }

  Future<void> test_variable_value_partialIdentifier() async {
    await testRequest(r'''
foo() {
  var a = [!a^!]
}
''', .inExpression);
  }

  Future<void> test_variableDeclaration() async {
    await testRequest(r'''
foo() {
  var [!^!]
}
''', .inIdentifierDeclaration);
  }

  Future<void> test_variableDeclaration_constant() async {
    await testRequest(r'''
foo() {
  const a = [!^!]
}
''', .inConstantExpression);
  }

  Future<void> test_variableDeclaration_partialIdentifier() async {
    await testRequest(r'''
foo() {
  var [!a^!]
}
''', .inIdentifierDeclaration);
  }

  Future<void> test_variableDeclaration_value() async {
    await testRequest(r'''
foo() {
  var a = [!^!]
}
''', .inExpression);
  }

  /// Checks that [content] produces a context of [expectedContext] where the
  /// character '^' in [content] represents the supplied offset and the range
  /// surrounded `[!` by brackets `!]` is the expected replacement range.
  ///
  /// `^`, `[!` and `!]` will be removed from the code before resolving.
  Future<void> testRequest(
    String content,
    SnippetContext expectedContext,
  ) async {
    var code = TestCode.parseNormalized(content);
    var offset = code.position.offset;
    var expectedReplacementRange = code.range.sourceRange;
    await resolveTestCode(code.code);

    var request = DartSnippetRequest(unit: testAnalysisResult, offset: offset);

    expect(request.filePath, testFile.path);
    expect(request.offset, offset);
    expect(request.context, expectedContext);
    expect(request.replacementRange, expectedReplacementRange);
  }
}
