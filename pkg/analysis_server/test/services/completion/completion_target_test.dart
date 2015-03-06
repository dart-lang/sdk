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
  Source testSource;
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
    testSource = addSource('/test.dart', content);
    CompilationUnit unit = context.parseCompilationUnit(testSource);
    target = new CompletionTarget.forOffset(unit, completionOffset);
  }

  void assertTarget(entityText, nodeText,
      {int argIndex: null, bool isFunctionalArgument: false}) {
    void assertCommon() {
      expect(target.entity.toString(), entityText);
      expect(target.containingNode.toString(), nodeText);
      expect(target.argIndex, argIndex);
    }
    // Assert with parsed unit
    assertCommon();
    CompilationUnit unit =
        context.resolveCompilationUnit2(testSource, testSource);
    target = new CompletionTarget.forOffset(unit, completionOffset);
    // Assert more with resolved unit
    assertCommon();
    expect(target.isFunctionalArgument(), isFunctionalArgument);
  }

  test_ArgumentList_InstanceCreationExpression() {
    // ArgumentList  InstanceCreationExpression  Block
    addTestSource('main() {new Foo(^)}');
    assertTarget(')', '()', argIndex: 0);
  }

  test_ArgumentList_MethodInvocation() {
    // ArgumentList  MethodInvocation  Block
    addTestSource('main() {foo(^)}');
    assertTarget(')', '()', argIndex: 0);
  }

  test_ArgumentList_MethodInvocation2() {
    // ArgumentList  MethodInvocation  Block
    addTestSource('main() {foo(^n)}');
    assertTarget('n', '(n)', argIndex: 0);
  }

  test_ArgumentList_MethodInvocation3() {
    // ArgumentList  MethodInvocation  Block
    addTestSource('main() {foo(n^)}');
    assertTarget('n', '(n)', argIndex: 0);
  }

  test_ArgumentList_MethodInvocation4() {
    // ArgumentList  MethodInvocation  Block
    addTestSource('main() {foo(n,^)}');
    assertTarget('', '(n, )', argIndex: 1);
  }

  test_ArgumentList_MethodInvocation_functionArg() {
    // ArgumentList  MethodInvocation  Block
    addTestSource('main() {foo(^)} foo(f()) {}');
    assertTarget(')', '()', argIndex: 0, isFunctionalArgument: true);
  }

  test_ArgumentList_MethodInvocation_functionArg2() {
    // ArgumentList  MethodInvocation  Block
    addTestSource('main() {new B().boo(^)} class B{boo(f()){}}');
    assertTarget(')', '()', argIndex: 0, isFunctionalArgument: true);
  }

  test_ArgumentList_InstanceCreationExpression_functionArg2() {
    // ArgumentList  InstanceCreationExpression  Block
    addTestSource('main() {new B(^)} class B{B(f()){}}');
    assertTarget(')', '()', argIndex: 0, isFunctionalArgument: true);
  }

  test_AsExpression_identifier() {
    // SimpleIdentifier  TypeName  AsExpression
    addTestSource('class A {var b; X _c; foo() {var a; (a^ as String).foo();}');
    assertTarget('a as String', '(a as String)');
  }

  test_AsExpression_keyword() {
    // SimpleIdentifier  TypeName  AsExpression
    addTestSource('class A {var b; X _c; foo() {var a; (a ^as String).foo();}');
    assertTarget('as', 'a as String');
  }

  test_AsExpression_keyword2() {
    // SimpleIdentifier  TypeName  AsExpression
    addTestSource('class A {var b; X _c; foo() {var a; (a a^s String).foo();}');
    assertTarget('as', 'a as String');
  }

  test_AsExpression_keyword3() {
    // SimpleIdentifier  TypeName  AsExpression
    addTestSource('class A {var b; X _c; foo() {var a; (a as^ String).foo();}');
    assertTarget('as', 'a as String');
  }

  test_AsExpression_type() {
    // SimpleIdentifier  TypeName  AsExpression
    addTestSource('class A {var b; X _c; foo() {var a; (a as ^String).foo();}');
    assertTarget('String', 'a as String');
  }

  test_Block() {
    // Block
    addTestSource('main() {^}');
    assertTarget('}', '{}');
  }

  test_InstanceCreationExpression_identifier() {
    // InstanceCreationExpression  ExpressionStatement  Block
    addTestSource('class C {foo(){var f; {var x;} new ^C();}}');
    assertTarget('C', 'new C()');
  }

  test_InstanceCreationExpression_keyword() {
    // InstanceCreationExpression  ExpressionStatement  Block
    addTestSource('class C {foo(){var f; {var x;} new^ }}');
    assertTarget('new ();', '{var f; {var x;} new ();}');
  }

  test_InstanceCreationExpression_keyword2() {
    // InstanceCreationExpression  ExpressionStatement  Block
    addTestSource('class C {foo(){var f; {var x;} new^ C();}}');
    assertTarget('new C();', '{var f; {var x;} new C();}');
  }

  test_VariableDeclaration_lhs_identifier_after() {
    // VariableDeclaration  VariableDeclarationList
    addTestSource('main() {int b^ = 1;}');
    assertTarget('b = 1', 'int b = 1');
  }

  test_VariableDeclaration_lhs_identifier_before() {
    // VariableDeclaration  VariableDeclarationList
    addTestSource('main() {int ^b = 1;}');
    assertTarget('b = 1', 'int b = 1');
  }
}
