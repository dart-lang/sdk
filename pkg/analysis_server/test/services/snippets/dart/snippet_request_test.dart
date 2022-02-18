// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/snippets/dart/snippet_manager.dart';
import 'package:analyzer/src/test_utilities/platform.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../abstract_single_unit.dart';
import 'test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SnippetRequestTest);
  });
}

@reflectiveTest
class SnippetRequestTest extends AbstractSingleUnitTest {
  SnippetRequestTest() {
    verifyNoTestUnitErrors = false;
  }

  Future<void> test_expression_constructor() async {
    await testRequest(r'''
final a = new [[^]]
''', SnippetContext.inExpressionOrStatement);
  }

  Future<void> test_expression_constructorName() async {
    await testRequest(r'''
class A {
  A.foo();
}
final a = new A.[[fo^]]
''', SnippetContext.inExpressionOrStatement);
  }

  Future<void> test_inAnnotation() async {
    await testRequest(r'''
@[[depre^]]
class A {}
''', SnippetContext.inExpressionOrStatement);
  }

  Future<void> test_inBlock_forBody() async {
    await testRequest(r'''
foo() {
  for (var i = 0; i < 10; i++) {
    [[^]]
  }
}
''', SnippetContext.inBlock);
  }

  Future<void> test_inClass_atEnd() async {
    await testRequest(r'''
class A {
  foo() {}

  [[^]]
}
''', SnippetContext.inClass);
  }

  Future<void> test_inClass_atEnd_partialIdentifier() async {
    await testRequest(r'''
class A {
  foo() {}

  [[mysnip^]]
}
''', SnippetContext.inClass);
  }

  Future<void> test_inClass_atStart() async {
    await testRequest(r'''
class A {
  [[^]]

  foo() {}
}
''', SnippetContext.inClass);
  }

  Future<void> test_inClass_atStart_partialIdentifier() async {
    await testRequest(r'''
class A {
  [[mysnip^]]

  foo() {}
}
''', SnippetContext.inClass);
  }

  Future<void> test_inClass_betweenMembers() async {
    await testRequest(r'''
class A {
  foo() {}

  [[^]]

  bar() {}
}
''', SnippetContext.inClass);
  }

  Future<void> test_inClass_betweenMembers_partialIdentifier() async {
    await testRequest(r'''
class A {
  foo() {}

  [[mysnip^]]

  bar() {}
}
''', SnippetContext.inClass);
  }

  Future<void> test_inClass_empty() async {
    await testRequest(r'''
class A {
  [[^]]
}
''', SnippetContext.inClass);
  }

  Future<void> test_inClass_empty_partialIdentifier() async {
    await testRequest(r'''
class A {
  [[mysnip^]]
}
''', SnippetContext.inClass);
  }

  Future<void> test_inComment_dartDoc() async {
    await testRequest(r'''
/// [[^]]
class A {}
''', SnippetContext.inComment);
  }

  Future<void> test_inComment_dartDoc_reference_member() async {
    await testRequest(r'''
class A {
  /// [ [[A^]] ]
  foo() {}
}
''', SnippetContext.inComment);
  }

  Future<void> test_inComment_dartDoc_reference_topLevel() async {
    await testRequest(r'''
/// [ [[A^]] ]
class A {}
''', SnippetContext.inComment);
  }

  Future<void> test_inComment_multiline_member() async {
    await testRequest(r'''
class A {
  /*
   * [[^]]
   */
  foo() {}
}
''', SnippetContext.inComment);
  }

  Future<void> test_inComment_multiline_topLevel() async {
    await testRequest(r'''
/*
 * [[^]]
 */
class A {}
''', SnippetContext.inComment);
  }

  Future<void> test_inComment_singleLine_member() async {
    await testRequest(r'''
class A {
  // [[^]]
  foo () {}
}
''', SnippetContext.inComment);
  }

  Future<void> test_inComment_singleLine_topLevel() async {
    await testRequest(r'''
// [[^]]
class A {}
''', SnippetContext.inComment);
  }

  Future<void> test_inExpression_functionCall() async {
    await testRequest(r'''
foo() {
  print([[^]]
}
''', SnippetContext.inExpressionOrStatement);
  }

  Future<void> test_inExtension() async {
    await testRequest(r'''
extension on Object {
  [[^]]
}
''', SnippetContext.inClass);
  }

  Future<void> test_inFunction_atEnd() async {
    await testRequest(r'''
foo() {
  var a = 1;
  [[^]]
}
''', SnippetContext.inBlock);
  }

  Future<void> test_inFunction_atEnd_partialIdentifier() async {
    await testRequest(r'''
foo() {
  var a = 1;
  [[mysnip^]]
}
''', SnippetContext.inBlock);
  }

  Future<void> test_inFunction_atStart() async {
    await testRequest(r'''
foo() {
  [[^]]
  var a = 1;
}
''', SnippetContext.inBlock);
  }

  Future<void> test_inFunction_atStart_partialIdentifier() async {
    await testRequest(r'''
foo() {
  [[mysnip^]]
  var a = 1;
}
''', SnippetContext.inBlock);
  }

  Future<void> test_inFunction_betweenStatements() async {
    await testRequest(r'''
foo() {
  var a = 1;
  [[^]]
  var b = 1;
}
''', SnippetContext.inBlock);
  }

  Future<void> test_inFunction_betweenStatements_partialIdentifier() async {
    await testRequest(r'''
foo() {
  var a = 1;
  [[mysnip^]]
  var b = 1;
}
''', SnippetContext.inBlock);
  }

  Future<void> test_inFunction_empty() async {
    await testRequest(r'''
foo() {
  [[^]]
}
''', SnippetContext.inBlock);
  }

  Future<void> test_inFunction_empty_partialIdentifier() async {
    await testRequest(r'''
foo() {
  [[mysnip^]]
}
''', SnippetContext.inBlock);
  }

  Future<void> test_inMethod_atEnd() async {
    await testRequest(r'''
class A {
  foo() {
    var a = 1;
    [[^]]
  }
}
''', SnippetContext.inBlock);
  }

  Future<void> test_inMethod_atEnd_partialIdentifier() async {
    await testRequest(r'''
class A {
  foo() {
    var a = 1;
    [[mysnip^]]
  }
}
''', SnippetContext.inBlock);
  }

  Future<void> test_inMethod_atStart() async {
    await testRequest(r'''
class A {
  foo() {
    [[^]]
    var a = 1;
  }
}
''', SnippetContext.inBlock);
  }

  Future<void> test_inMethod_atStart_partialIdentifier() async {
    await testRequest(r'''
class A {
  foo() {
    [[mysnip^]]
    var a = 1;
  }
}
''', SnippetContext.inBlock);
  }

  Future<void> test_inMethod_betweenStatements() async {
    await testRequest(r'''
class A {
  foo() {
    var a = 1;
    [[^]]
    var b = 1;
  }
}
''', SnippetContext.inBlock);
  }

  Future<void> test_inMethod_betweenStatements_partialIdentifier() async {
    await testRequest(r'''
class A {
  foo() {
    var a = 1;
    [[mysnip^]]
    var b = 1;
  }
}
''', SnippetContext.inBlock);
  }

  Future<void> test_inMethod_empty() async {
    await testRequest(r'''
class A {
  foo() {
    [[^]]
  }
}
''', SnippetContext.inBlock);
  }

  Future<void> test_inMethod_empty_partialIdentifier() async {
    await testRequest(r'''
class A {
  foo() {
    [[mysnip^]]
  }
}
''', SnippetContext.inBlock);
  }

  Future<void> test_inMixin() async {
    await testRequest(r'''
mixin A {
  [[^]]
}
''', SnippetContext.inClass);
  }

  Future<void> test_inStatement_forCondition() async {
    await testRequest(r'''
foo() {
  for (var i = [[^]]
}
''', SnippetContext.inExpressionOrStatement);
  }

  Future<void> test_inStatement_variableDeclaration() async {
    await testRequest(r'''
foo() {
  var a = [[^]]
}
''', SnippetContext.inExpressionOrStatement);
  }

  Future<void> test_inString() async {
    await testRequest(r'''
const a = '[[^]]';
''', SnippetContext.inString);
  }

  Future<void> test_inString_raw() async {
    await testRequest(r'''
const a = r'[[^]]';
''', SnippetContext.inString);
  }

  Future<void> test_inString_unterminated() async {
    await testRequest(r'''
const a = r'[[^]]
''', SnippetContext.inString);
  }

  Future<void> test_topLevel_atEnd() async {
    await testRequest(r'''
class A {}

[[^]]
''', SnippetContext.atTopLevel);
  }

  Future<void> test_topLevel_atEnd_partialIdentifier() async {
    await testRequest(r'''
class A {}

[[mysnip^]]
''', SnippetContext.atTopLevel);
  }

  Future<void> test_topLevel_atStart() async {
    await testRequest(r'''
[[^]]

class A {}
''', SnippetContext.atTopLevel);
  }

  Future<void> test_topLevel_atStart_partialIdentifier() async {
    await testRequest(r'''
[[mysnip^]]

class A {}
''', SnippetContext.atTopLevel);
  }

  Future<void> test_topLevel_betweenClasses() async {
    await testRequest(r'''
class A {}

[[^]]

class B {}
''', SnippetContext.atTopLevel);
  }

  Future<void> test_topLevel_betweenClasses_partialIdentifier() async {
    await testRequest(r'''
class A {}

[[mysnip^]]

class B {}
''', SnippetContext.atTopLevel);
  }

  Future<void> test_topLevel_empty() async {
    await testRequest('[[^]]', SnippetContext.atTopLevel);
  }

  Future<void> test_topLevel_empty_partialIdentifier() async {
    await testRequest('[[mysnip^]]', SnippetContext.atTopLevel);
  }

  /// Checks that [code] produces a context of [expectedContext] where the
  /// character '^' in [code] represents the supplied offset and the range
  /// surrounded `[[` by brackets `]]` is the expected replacement range.
  ///
  /// `^`, `[[` and `]]` will be removed from the code before resolving.
  Future<void> testRequest(String code, SnippetContext expectedContext) async {
    code = normalizeNewlinesForPlatform(code);
    final offset = offsetFromMarker(code);
    final expectedReplacementRange = rangeFromMarkers(code);
    await resolveTestCode(withoutMarkers(code));

    final request = DartSnippetRequest(
      unit: testAnalysisResult,
      offset: offset,
    );

    expect(request.filePath, testFile);
    expect(request.offset, offset);
    expect(request.context, expectedContext);
    expect(request.replacementRange, expectedReplacementRange);
  }
}
