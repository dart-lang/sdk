// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.services.completion.target;

import 'package:analysis_server/src/provisional/completion/dart/completion_target.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../abstract_context.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CompletionTargetTest);
  });
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
      expect(target.entity.toString(), entityText, reason: 'entity');
      expect(target.containingNode.toString(), nodeText,
          reason: 'containingNode');
      expect(target.argIndex, argIndex, reason: 'argIndex');
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

  test_ArgumentList_InstanceCreationExpression2() {
    // ArgumentList  InstanceCreationExpression  Block
    addTestSource('main() {new Foo(a,^)}');
    assertTarget(')', '(a)', argIndex: 1);
  }

  test_ArgumentList_InstanceCreationExpression_functionArg2() {
    // ArgumentList  InstanceCreationExpression  Block
    addTestSource('main() {new B(^)} class B{B(f()){}}');
    assertTarget(')', '()', argIndex: 0, isFunctionalArgument: true);
  }

  test_ArgumentList_InstanceCreationExpression_functionArg3() {
    // ArgumentList  InstanceCreationExpression  Block
    addTestSource('main() {new B(1, f: ^)} class B{B(int i, {f()}){}}');
    assertTarget('', 'f: ', argIndex: 1, isFunctionalArgument: true);
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

  test_ArgumentList_MethodInvocation3a() {
    // ArgumentList  MethodInvocation  Block
    addTestSource('main() {foo((n)^)}');
    assertTarget(')', '((n))', argIndex: 0);
  }

  test_ArgumentList_MethodInvocation4() {
    // ArgumentList  MethodInvocation  Block
    addTestSource('main() {foo(n,^)}');
    assertTarget(')', '(n)', argIndex: 1);
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

  test_ArgumentList_MethodInvocation_functionArg3() {
    // ArgumentList  MethodInvocation  Block
    addTestSource('main() {foo(f: ^)} foo({f()}) {}');
    assertTarget('', 'f: ', argIndex: 0, isFunctionalArgument: true);
  }

  test_ArgumentList_MethodInvocation_functionArg4() {
    // ArgumentList  MethodInvocation  Block
    addTestSource('main() {new B().boo(f: ^)} class B{boo({f()}){}}');
    assertTarget('', 'f: ', argIndex: 0, isFunctionalArgument: true);
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

  test_Block_keyword() {
    addTestSource('class C { static C get instance => null; } main() {C.in^}');
    assertTarget('in', 'C.in');
  }

  test_Block_keyword2() {
    addTestSource('class C { static C get instance => null; } main() {C.i^n}');
    assertTarget('in', 'C.in');
  }

  test_FormalParameter_partialType() {
    // SimpleIdentifier  PrefixedIdentifier  TypeName
    addTestSource('foo(b.^ f) { }');
    assertTarget('f', 'b.f');
  }

  test_FormalParameter_partialType2() {
    // SimpleIdentifier  PrefixedIdentifier  TypeName
    addTestSource('foo(b.z^ f) { }');
    assertTarget('z', 'b.z');
  }

  test_FormalParameter_partialType3() {
    // SimpleIdentifier  PrefixedIdentifier  TypeName
    addTestSource('foo(b.^) { }');
    assertTarget('', 'b.');
  }

  test_FormalParameterList() {
    // Token  FormalParameterList  FunctionExpression
    addTestSource('foo(^) { }');
    assertTarget(')', '()');
  }

  test_FunctionDeclaration_inLineComment() {
    // Comment  CompilationUnit
    addTestSource('''
      // normal comment ^
      zoo(z) { } String name;''');
    assertTarget('// normal comment ', 'zoo(z) {} String name;');
  }

  test_FunctionDeclaration_inLineComment2() {
    // Comment  CompilationUnit
    addTestSource('''
      // normal ^comment
      zoo(z) { } String name;''');
    assertTarget('// normal comment', 'zoo(z) {} String name;');
  }

  test_FunctionDeclaration_inLineComment3() {
    // Comment  CompilationUnit
    addTestSource('''
      // normal comment ^
      // normal comment 2
      zoo(z) { } String name;''');
    assertTarget('// normal comment ', 'zoo(z) {} String name;');
  }

  test_FunctionDeclaration_inLineComment4() {
    // Comment  CompilationUnit
    addTestSource('''
      // normal comment
      // normal comment 2^
      zoo(z) { } String name;''');
    assertTarget('// normal comment 2', 'zoo(z) {} String name;');
  }

  test_FunctionDeclaration_inLineDocComment() {
    // Comment  FunctionDeclaration  CompilationUnit
    addTestSource('''
      /// some dartdoc ^
      zoo(z) { } String name;''');
    assertTarget('/// some dartdoc ', '');
    expect(target.containingNode is Comment, isTrue);
    expect(target.containingNode.parent.toSource(), 'zoo(z) {}');
  }

  test_FunctionDeclaration_inLineDocComment2() {
    // Comment  FunctionDeclaration  CompilationUnit
    addTestSource('''
      /// some ^dartdoc
      zoo(z) { } String name;''');
    assertTarget('/// some dartdoc', '');
    expect(target.containingNode is Comment, isTrue);
    expect(target.containingNode.parent.toSource(), 'zoo(z) {}');
  }

  test_FunctionDeclaration_inStarComment() {
    // Comment  CompilationUnit
    addTestSource('/* ^ */ zoo(z) {} String name;');
    assertTarget('/*  */', 'zoo(z) {} String name;');
  }

  test_FunctionDeclaration_inStarComment2() {
    // Comment  CompilationUnit
    addTestSource('/*  *^/ zoo(z) {} String name;');
    assertTarget('/*  */', 'zoo(z) {} String name;');
  }

  test_FunctionDeclaration_inStarDocComment() {
    // Comment  FunctionDeclaration  CompilationUnit
    addTestSource('/** ^ */ zoo(z) { } String name;');
    assertTarget('/**  */', '');
    expect(target.containingNode is Comment, isTrue);
    expect(target.containingNode.parent.toSource(), 'zoo(z) {}');
  }

  test_FunctionDeclaration_inStarDocComment2() {
    // Comment  FunctionDeclaration  CompilationUnit
    addTestSource('/**  *^/ zoo(z) { } String name;');
    assertTarget('/**  */', '');
    expect(target.containingNode is Comment, isTrue);
    expect(target.containingNode.parent.toSource(), 'zoo(z) {}');
  }

  test_FunctionDeclaration_returnType() {
    // CompilationUnit
    addTestSource('^ zoo(z) { } String name;');
    assertTarget('zoo(z) {}', 'zoo(z) {} String name;');
  }

  test_FunctionDeclaration_returnType_afterLineComment() {
    // FunctionDeclaration  CompilationUnit
    addTestSource('''
      // normal comment
      ^ zoo(z) {} String name;''');
    assertTarget('zoo(z) {}', 'zoo(z) {} String name;');
  }

  test_FunctionDeclaration_returnType_afterLineComment2() {
    // FunctionDeclaration  CompilationUnit
    // TOD(danrubel) left align all test source
    addTestSource('''
// normal comment
^ zoo(z) {} String name;''');
    assertTarget('zoo(z) {}', 'zoo(z) {} String name;');
  }

  test_FunctionDeclaration_returnType_afterLineDocComment() {
    // SimpleIdentifier  FunctionDeclaration  CompilationUnit
    addTestSource('''
      /// some dartdoc
      ^ zoo(z) { } String name; ''');
    assertTarget('zoo', 'zoo(z) {}');
  }

  test_FunctionDeclaration_returnType_afterLineDocComment2() {
    // SimpleIdentifier  FunctionDeclaration  CompilationUnit
    addTestSource('''
/// some dartdoc
^ zoo(z) { } String name;''');
    assertTarget('zoo', 'zoo(z) {}');
  }

  test_FunctionDeclaration_returnType_afterStarComment() {
    // CompilationUnit
    addTestSource('/* */ ^ zoo(z) { } String name;');
    assertTarget('zoo(z) {}', 'zoo(z) {} String name;');
  }

  test_FunctionDeclaration_returnType_afterStarComment2() {
    // CompilationUnit
    addTestSource('/* */^ zoo(z) { } String name;');
    assertTarget('zoo(z) {}', 'zoo(z) {} String name;');
  }

  test_FunctionDeclaration_returnType_afterStarDocComment() {
    // FunctionDeclaration  CompilationUnit
    addTestSource('/** */ ^ zoo(z) { } String name;');
    assertTarget('zoo', 'zoo(z) {}');
  }

  test_FunctionDeclaration_returnType_afterStarDocComment2() {
    // FunctionDeclaration  CompilationUnit
    addTestSource('/** */^ zoo(z) { } String name;');
    assertTarget('zoo', 'zoo(z) {}');
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

  test_MapLiteralEntry() {
    // MapLiteralEntry  MapLiteral  VariableDeclaration
    addTestSource('foo = {^');
    assertTarget(' : ', '{ : }');
  }

  test_MapLiteralEntry1() {
    // MapLiteralEntry  MapLiteral  VariableDeclaration
    addTestSource('foo = {T^');
    assertTarget('T : ', '{T : }');
  }

  test_MapLiteralEntry2() {
    // SimpleIdentifier  MapLiteralEntry  MapLiteral  VariableDeclaration
    addTestSource('foo = {7:T^};');
    assertTarget('T', '7 : T');
  }

  test_MethodDeclaration_inLineComment() {
    // Comment  ClassDeclaration  CompilationUnit
    addTestSource('''
      class C2 {
        // normal comment ^
        zoo(z) { } String name; }''');
    assertTarget('// normal comment ', 'class C2 {zoo(z) {} String name;}');
  }

  test_MethodDeclaration_inLineComment2() {
    // Comment  ClassDeclaration  CompilationUnit
    addTestSource('''
      class C2 {
        // normal ^comment
        zoo(z) { } String name; }''');
    assertTarget('// normal comment', 'class C2 {zoo(z) {} String name;}');
  }

  test_MethodDeclaration_inLineComment3() {
    // Comment  ClassDeclaration  CompilationUnit
    addTestSource('''
      class C2 {
        // normal comment ^
        // normal comment 2
        zoo(z) { } String name; }''');
    assertTarget('// normal comment ', 'class C2 {zoo(z) {} String name;}');
  }

  test_MethodDeclaration_inLineComment4() {
    // Comment  ClassDeclaration  CompilationUnit
    addTestSource('''
      class C2 {
        // normal comment
        // normal comment 2^
        zoo(z) { } String name; }''');
    assertTarget('// normal comment 2', 'class C2 {zoo(z) {} String name;}');
  }

  test_MethodDeclaration_inLineDocComment() {
    // Comment  MethodDeclaration  ClassDeclaration  CompilationUnit
    addTestSource('''
      class C2 {
        /// some dartdoc ^
        zoo(z) { } String name; }''');
    assertTarget('/// some dartdoc ', '');
    expect(target.containingNode is Comment, isTrue);
    expect(target.containingNode.parent.toSource(), 'zoo(z) {}');
  }

  test_MethodDeclaration_inLineDocComment2() {
    // Comment  MethodDeclaration  ClassDeclaration  CompilationUnit
    addTestSource('''
      class C2 {
        /// some ^dartdoc
        zoo(z) { } String name; }''');
    assertTarget('/// some dartdoc', '');
    expect(target.containingNode is Comment, isTrue);
    expect(target.containingNode.parent.toSource(), 'zoo(z) {}');
  }

  test_MethodDeclaration_inStarComment() {
    // Comment  ClassDeclaration  CompilationUnit
    addTestSource('class C2 {/* ^ */ zoo(z) {} String name;}');
    assertTarget('/*  */', 'class C2 {zoo(z) {} String name;}');
  }

  test_MethodDeclaration_inStarComment2() {
    // Comment  ClassDeclaration  CompilationUnit
    addTestSource('class C2 {/*  *^/ zoo(z) {} String name;}');
    assertTarget('/*  */', 'class C2 {zoo(z) {} String name;}');
  }

  test_MethodDeclaration_inStarDocComment() {
    // Comment  MethodDeclaration  ClassDeclaration  CompilationUnit
    addTestSource('class C2 {/** ^ */ zoo(z) { } String name; }');
    assertTarget('/**  */', '');
    expect(target.containingNode is Comment, isTrue);
    expect(target.containingNode.parent.toSource(), 'zoo(z) {}');
  }

  test_MethodDeclaration_inStarDocComment2() {
    // Comment  MethodDeclaration  ClassDeclaration  CompilationUnit
    addTestSource('class C2 {/**  *^/ zoo(z) { } String name; }');
    assertTarget('/**  */', '');
    expect(target.containingNode is Comment, isTrue);
    expect(target.containingNode.parent.toSource(), 'zoo(z) {}');
  }

  test_MethodDeclaration_returnType() {
    // ClassDeclaration  CompilationUnit
    addTestSource('class C2 {^ zoo(z) { } String name; }');
    assertTarget('zoo(z) {}', 'class C2 {zoo(z) {} String name;}');
  }

  test_MethodDeclaration_returnType_afterLineComment() {
    // MethodDeclaration  ClassDeclaration  CompilationUnit
    addTestSource('''
      class C2 {
        // normal comment
        ^ zoo(z) {} String name;}''');
    assertTarget('zoo(z) {}', 'class C2 {zoo(z) {} String name;}');
  }

  test_MethodDeclaration_returnType_afterLineComment2() {
    // MethodDeclaration  ClassDeclaration  CompilationUnit
    // TOD(danrubel) left align all test source
    addTestSource('''
class C2 {
  // normal comment
^ zoo(z) {} String name;}''');
    assertTarget('zoo(z) {}', 'class C2 {zoo(z) {} String name;}');
  }

  test_MethodDeclaration_returnType_afterLineDocComment() {
    // SimpleIdentifier  MethodDeclaration  ClassDeclaration  CompilationUnit
    addTestSource('''
      class C2 {
        /// some dartdoc
        ^ zoo(z) { } String name; }''');
    assertTarget('zoo', 'zoo(z) {}');
  }

  test_MethodDeclaration_returnType_afterLineDocComment2() {
    // SimpleIdentifier  MethodDeclaration  ClassDeclaration  CompilationUnit
    addTestSource('''
class C2 {
  /// some dartdoc
^ zoo(z) { } String name; }''');
    assertTarget('zoo', 'zoo(z) {}');
  }

  test_MethodDeclaration_returnType_afterStarComment() {
    // ClassDeclaration  CompilationUnit
    addTestSource('class C2 {/* */ ^ zoo(z) { } String name; }');
    assertTarget('zoo(z) {}', 'class C2 {zoo(z) {} String name;}');
  }

  test_MethodDeclaration_returnType_afterStarComment2() {
    // ClassDeclaration  CompilationUnit
    addTestSource('class C2 {/* */^ zoo(z) { } String name; }');
    assertTarget('zoo(z) {}', 'class C2 {zoo(z) {} String name;}');
  }

  test_MethodDeclaration_returnType_afterStarDocComment() {
    // MethodDeclaration  ClassDeclaration  CompilationUnit
    addTestSource('class C2 {/** */ ^ zoo(z) { } String name; }');
    assertTarget('zoo', 'zoo(z) {}');
  }

  test_MethodDeclaration_returnType_afterStarDocComment2() {
    // MethodDeclaration  ClassDeclaration  CompilationUnit
    addTestSource('class C2 {/** */^ zoo(z) { } String name; }');
    assertTarget('zoo', 'zoo(z) {}');
  }

  test_SwitchStatement_c() {
    // Token('c') SwitchStatement
    addTestSource('main() { switch(x) {c^} }');
    assertTarget('}', 'switch (x) {}');
  }

  test_SwitchStatement_c2() {
    // Token('c') SwitchStatement
    addTestSource('main() { switch(x) { c^ } }');
    assertTarget('}', 'switch (x) {}');
  }

  test_SwitchStatement_empty() {
    // SwitchStatement
    addTestSource('main() { switch(x) {^} }');
    assertTarget('}', 'switch (x) {}');
  }

  test_SwitchStatement_empty2() {
    // SwitchStatement
    addTestSource('main() { switch(x) { ^ } }');
    assertTarget('}', 'switch (x) {}');
  }

  test_TypeArgumentList() {
    // TypeName  TypeArgumentList  TypeName
    addTestSource('main() { C<^> c; }');
    assertTarget('', '<>');
  }

  test_TypeArgumentList2() {
    // TypeName  TypeArgumentList  TypeName
    addTestSource('main() { C<C^> c; }');
    assertTarget('C', '<C>');
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
