// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.services.completion.target;

import 'package:analysis_server/src/services/completion/completion_target.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:unittest/unittest.dart';

import '../../abstract_context.dart';
import '../../reflective_tests.dart';

main() {
  groupSep = ' | ';
  runReflectiveTests(CompletionTargetTest);
}

@reflectiveTest
class CompletionTargetTest extends AbstractContextTest {
  int completionOffset;
  CompletionTarget target;

  void addTestSource(String content) {
    expect(completionOffset, isNull, reason: 'Call addTestSource exactly once');
    completionOffset = content.indexOf('^');
    expect(completionOffset, isNot(equals(-1)), reason: 'missing ^');
    int nextOffset = content.indexOf('^', completionOffset + 1);
    expect(nextOffset, equals(-1), reason: 'too many ^');
    content = content.substring(0, completionOffset) +
        content.substring(completionOffset + 1);
    Source testSource = addSource('/test.dart', content);
    CompilationUnit unit = context.parseCompilationUnit(testSource);
    target = new CompletionTarget.forOffset(unit, completionOffset);
  }

  test_AsExpression_identifier() {
    // SimpleIdentifier  TypeName  AsExpression
    addTestSource('class A {var b; X _c; foo() {var a; (a^ as String).foo();}');
    expect(target.entity.toString(), 'a as String');
    expect(target.containingNode.toString(), '(a as String)');
  }

  test_AsExpression_keyword() {
    // SimpleIdentifier  TypeName  AsExpression
    addTestSource('class A {var b; X _c; foo() {var a; (a ^as String).foo();}');
    expect(target.entity.toString(), 'as');
    expect(target.containingNode.toString(), 'a as String');
  }

  test_AsExpression_keyword2() {
    // SimpleIdentifier  TypeName  AsExpression
    addTestSource('class A {var b; X _c; foo() {var a; (a a^s String).foo();}');
    expect(target.entity.toString(), 'as');
    expect(target.containingNode.toString(), 'a as String');
  }

  test_AsExpression_keyword3() {
    // SimpleIdentifier  TypeName  AsExpression
    addTestSource('class A {var b; X _c; foo() {var a; (a as^ String).foo();}');
    expect(target.entity.toString(), 'as');
    expect(target.containingNode.toString(), 'a as String');
  }

  test_AsExpression_type() {
    // SimpleIdentifier  TypeName  AsExpression
    addTestSource('class A {var b; X _c; foo() {var a; (a as ^String).foo();}');
    expect(target.entity.toString(), 'String');
    expect(target.containingNode.toString(), 'a as String');
  }

  test_InstanceCreationExpression_keyword() {
    // InstanceCreationExpression  ExpressionStatement  Block
    addTestSource('class C {foo(){var f; {var x;} new^ }}');
    expect(target.entity.toString(), 'new ();');
    expect(target.containingNode.toString(), '{var f; {var x;} new ();}');
  }

  test_InstanceCreationExpression_keyword2() {
    // InstanceCreationExpression  ExpressionStatement  Block
    addTestSource('class C {foo(){var f; {var x;} new^ C();}}');
    expect(target.entity.toString(), 'new C();');
    expect(target.containingNode.toString(), '{var f; {var x;} new C();}');
  }

  test_InstanceCreationExpression_identifier() {
    // InstanceCreationExpression  ExpressionStatement  Block
    addTestSource('class C {foo(){var f; {var x;} new ^C();}}');
    expect(target.entity.toString(), 'C');
    expect(target.containingNode.toString(), 'new C()');
  }

  test_VariableDeclaration_lhs_identifier_after() {
    // VariableDeclaration  VariableDeclarationList
    addTestSource('main() {int b^ = 1;}');
    expect(target.entity.toString(), 'b = 1');
    expect(target.containingNode.toString(), 'int b = 1');
  }

  test_VariableDeclaration_lhs_identifier_before() {
    // VariableDeclaration  VariableDeclarationList
    addTestSource('main() {int ^b = 1;}');
    expect(target.entity.toString(), 'b = 1');
    expect(target.containingNode.toString(), 'int b = 1');
  }
}
