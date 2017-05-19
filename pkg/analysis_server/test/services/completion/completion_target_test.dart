// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/src/provisional/completion/dart/completion_target.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
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

  Future<Null> addTestSource(String content) async {
    expect(completionOffset, isNull, reason: 'Call addTestSource exactly once');
    completionOffset = content.indexOf('^');
    expect(completionOffset, isNot(equals(-1)), reason: 'missing ^');
    int nextOffset = content.indexOf('^', completionOffset + 1);
    expect(nextOffset, equals(-1), reason: 'too many ^');
    content = content.substring(0, completionOffset) +
        content.substring(completionOffset + 1);
    testSource = addSource('/test.dart', content);
    AnalysisResult result = await driver.getResult(testSource.fullName);
    target = new CompletionTarget.forOffset(result.unit, completionOffset);
  }

  Future<Null> assertTarget(entityText, nodeText,
      {int argIndex: null, bool isFunctionalArgument: false}) async {
    void assertCommon() {
      expect(target.entity.toString(), entityText, reason: 'entity');
      expect(target.containingNode.toString(), nodeText,
          reason: 'containingNode');
      expect(target.argIndex, argIndex, reason: 'argIndex');
    }

    // Assert with parsed unit
    assertCommon();
    AnalysisResult result = await driver.getResult(testSource.fullName);
    target = new CompletionTarget.forOffset(result.unit, completionOffset);
    // Assert more with resolved unit
    assertCommon();
    expect(target.isFunctionalArgument(), isFunctionalArgument);
  }

  test_ArgumentList_InstanceCreationExpression() async {
    // ArgumentList  InstanceCreationExpression  Block
    await addTestSource('main() {new Foo(^)}');
    await assertTarget(')', '()', argIndex: 0);
  }

  test_ArgumentList_InstanceCreationExpression2() async {
    // ArgumentList  InstanceCreationExpression  Block
    await addTestSource('main() {new Foo(a,^)}');
    await assertTarget(')', '(a)', argIndex: 1);
  }

  test_ArgumentList_InstanceCreationExpression_functionArg2() async {
    // ArgumentList  InstanceCreationExpression  Block
    await addTestSource('main() {new B(^)} class B{B(f()){}}');
    await assertTarget(')', '()', argIndex: 0, isFunctionalArgument: true);
  }

  test_ArgumentList_InstanceCreationExpression_functionArg3() async {
    // ArgumentList  InstanceCreationExpression  Block
    await addTestSource('main() {new B(1, f: ^)} class B{B(int i, {f()}){}}');
    await assertTarget('', 'f: ', argIndex: 1, isFunctionalArgument: true);
  }

  test_ArgumentList_MethodInvocation() async {
    // ArgumentList  MethodInvocation  Block
    await addTestSource('main() {foo(^)}');
    await assertTarget(')', '()', argIndex: 0);
  }

  test_ArgumentList_MethodInvocation2() async {
    // ArgumentList  MethodInvocation  Block
    await addTestSource('main() {foo(^n)}');
    await assertTarget('n', '(n)', argIndex: 0);
  }

  test_ArgumentList_MethodInvocation3() async {
    // ArgumentList  MethodInvocation  Block
    await addTestSource('main() {foo(n^)}');
    await assertTarget('n', '(n)', argIndex: 0);
  }

  test_ArgumentList_MethodInvocation3a() async {
    // ArgumentList  MethodInvocation  Block
    await addTestSource('main() {foo((n)^)}');
    await assertTarget(')', '((n))', argIndex: 0);
  }

  test_ArgumentList_MethodInvocation4() async {
    // ArgumentList  MethodInvocation  Block
    await addTestSource('main() {foo(n,^)}');
    await assertTarget(')', '(n)', argIndex: 1);
  }

  test_ArgumentList_MethodInvocation_functionArg() async {
    // ArgumentList  MethodInvocation  Block
    await addTestSource('main() {foo(^)} foo(f()) {}');
    await assertTarget(')', '()', argIndex: 0, isFunctionalArgument: true);
  }

  test_ArgumentList_MethodInvocation_functionArg2() async {
    // ArgumentList  MethodInvocation  Block
    await addTestSource('main() {new B().boo(^)} class B{boo(f()){}}');
    await assertTarget(')', '()', argIndex: 0, isFunctionalArgument: true);
  }

  test_ArgumentList_MethodInvocation_functionArg3() async {
    // ArgumentList  MethodInvocation  Block
    await addTestSource('main() {foo(f: ^)} foo({f()}) {}');
    await assertTarget('', 'f: ', argIndex: 0, isFunctionalArgument: true);
  }

  test_ArgumentList_MethodInvocation_functionArg4() async {
    // ArgumentList  MethodInvocation  Block
    await addTestSource('main() {new B().boo(f: ^)} class B{boo({f()}){}}');
    await assertTarget('', 'f: ', argIndex: 0, isFunctionalArgument: true);
  }

  test_AsExpression_identifier() async {
    // SimpleIdentifier  TypeName  AsExpression
    await addTestSource(
        'class A {var b; X _c; foo() {var a; (a^ as String).foo();}');
    await assertTarget('a as String', '(a as String)');
  }

  test_AsExpression_keyword() async {
    // SimpleIdentifier  TypeName  AsExpression
    await addTestSource(
        'class A {var b; X _c; foo() {var a; (a ^as String).foo();}');
    await assertTarget('as', 'a as String');
  }

  test_AsExpression_keyword2() async {
    // SimpleIdentifier  TypeName  AsExpression
    await addTestSource(
        'class A {var b; X _c; foo() {var a; (a a^s String).foo();}');
    await assertTarget('as', 'a as String');
  }

  test_AsExpression_keyword3() async {
    // SimpleIdentifier  TypeName  AsExpression
    await addTestSource(
        'class A {var b; X _c; foo() {var a; (a as^ String).foo();}');
    await assertTarget('as', 'a as String');
  }

  test_AsExpression_type() async {
    // SimpleIdentifier  TypeName  AsExpression
    await addTestSource(
        'class A {var b; X _c; foo() {var a; (a as ^String).foo();}');
    await assertTarget('String', 'a as String');
  }

  test_Block() async {
    // Block
    await addTestSource('main() {^}');
    await assertTarget('}', '{}');
  }

  test_Block_keyword() async {
    await addTestSource(
        'class C { static C get instance => null; } main() {C.in^}');
    await assertTarget('in', 'C.in');
  }

  test_Block_keyword2() async {
    await addTestSource(
        'class C { static C get instance => null; } main() {C.i^n}');
    await assertTarget('in', 'C.in');
  }

  test_FormalParameter_partialType() async {
    // SimpleIdentifier  PrefixedIdentifier  TypeName
    await addTestSource('foo(b.^ f) { }');
    await assertTarget('f', 'b.f');
  }

  test_FormalParameter_partialType2() async {
    // SimpleIdentifier  PrefixedIdentifier  TypeName
    await addTestSource('foo(b.z^ f) { }');
    await assertTarget('z', 'b.z');
  }

  test_FormalParameter_partialType3() async {
    // SimpleIdentifier  PrefixedIdentifier  TypeName
    await addTestSource('foo(b.^) { }');
    await assertTarget('', 'b.');
  }

  test_FormalParameterList() async {
    // Token  FormalParameterList  FunctionExpression
    await addTestSource('foo(^) { }');
    await assertTarget(')', '()');
  }

  test_FunctionDeclaration_inLineComment() async {
    // Comment  CompilationUnit
    await addTestSource('''
      // normal comment ^
      zoo(z) { } String name;''');
    await assertTarget('// normal comment ', 'zoo(z) {} String name;');
  }

  test_FunctionDeclaration_inLineComment2() async {
    // Comment  CompilationUnit
    await addTestSource('''
      // normal ^comment
      zoo(z) { } String name;''');
    await assertTarget('// normal comment', 'zoo(z) {} String name;');
  }

  test_FunctionDeclaration_inLineComment3() async {
    // Comment  CompilationUnit
    await addTestSource('''
      // normal comment ^
      // normal comment 2
      zoo(z) { } String name;''');
    await assertTarget('// normal comment ', 'zoo(z) {} String name;');
  }

  test_FunctionDeclaration_inLineComment4() async {
    // Comment  CompilationUnit
    await addTestSource('''
      // normal comment
      // normal comment 2^
      zoo(z) { } String name;''');
    await assertTarget('// normal comment 2', 'zoo(z) {} String name;');
  }

  test_FunctionDeclaration_inLineDocComment() async {
    // Comment  FunctionDeclaration  CompilationUnit
    await addTestSource('''
      /// some dartdoc ^
      zoo(z) { } String name;''');
    await assertTarget('/// some dartdoc ', '');
    expect(target.containingNode is Comment, isTrue);
    expect(target.containingNode.parent.toSource(), 'zoo(z) {}');
  }

  test_FunctionDeclaration_inLineDocComment2() async {
    // Comment  FunctionDeclaration  CompilationUnit
    await addTestSource('''
      /// some ^dartdoc
      zoo(z) { } String name;''');
    await assertTarget('/// some dartdoc', '');
    expect(target.containingNode is Comment, isTrue);
    expect(target.containingNode.parent.toSource(), 'zoo(z) {}');
  }

  test_FunctionDeclaration_inStarComment() async {
    // Comment  CompilationUnit
    await addTestSource('/* ^ */ zoo(z) {} String name;');
    await assertTarget('/*  */', 'zoo(z) {} String name;');
  }

  test_FunctionDeclaration_inStarComment2() async {
    // Comment  CompilationUnit
    await addTestSource('/*  *^/ zoo(z) {} String name;');
    await assertTarget('/*  */', 'zoo(z) {} String name;');
  }

  test_FunctionDeclaration_inStarDocComment() async {
    // Comment  FunctionDeclaration  CompilationUnit
    await addTestSource('/** ^ */ zoo(z) { } String name;');
    await assertTarget('/**  */', '');
    expect(target.containingNode is Comment, isTrue);
    expect(target.containingNode.parent.toSource(), 'zoo(z) {}');
  }

  test_FunctionDeclaration_inStarDocComment2() async {
    // Comment  FunctionDeclaration  CompilationUnit
    await addTestSource('/**  *^/ zoo(z) { } String name;');
    await assertTarget('/**  */', '');
    expect(target.containingNode is Comment, isTrue);
    expect(target.containingNode.parent.toSource(), 'zoo(z) {}');
  }

  test_FunctionDeclaration_returnType() async {
    // CompilationUnit
    await addTestSource('^ zoo(z) { } String name;');
    await assertTarget('zoo(z) {}', 'zoo(z) {} String name;');
  }

  test_FunctionDeclaration_returnType_afterLineComment() async {
    // FunctionDeclaration  CompilationUnit
    await addTestSource('''
      // normal comment
      ^ zoo(z) {} String name;''');
    await assertTarget('zoo(z) {}', 'zoo(z) {} String name;');
  }

  test_FunctionDeclaration_returnType_afterLineComment2() async {
    // FunctionDeclaration  CompilationUnit
    // TOD(danrubel) left align all test source
    await addTestSource('''
// normal comment
^ zoo(z) {} String name;''');
    await assertTarget('zoo(z) {}', 'zoo(z) {} String name;');
  }

  test_FunctionDeclaration_returnType_afterLineDocComment() async {
    // SimpleIdentifier  FunctionDeclaration  CompilationUnit
    await addTestSource('''
      /// some dartdoc
      ^ zoo(z) { } String name; ''');
    await assertTarget('zoo', 'zoo(z) {}');
  }

  test_FunctionDeclaration_returnType_afterLineDocComment2() async {
    // SimpleIdentifier  FunctionDeclaration  CompilationUnit
    await addTestSource('''
/// some dartdoc
^ zoo(z) { } String name;''');
    await assertTarget('zoo', 'zoo(z) {}');
  }

  test_FunctionDeclaration_returnType_afterStarComment() async {
    // CompilationUnit
    await addTestSource('/* */ ^ zoo(z) { } String name;');
    await assertTarget('zoo(z) {}', 'zoo(z) {} String name;');
  }

  test_FunctionDeclaration_returnType_afterStarComment2() async {
    // CompilationUnit
    await addTestSource('/* */^ zoo(z) { } String name;');
    await assertTarget('zoo(z) {}', 'zoo(z) {} String name;');
  }

  test_FunctionDeclaration_returnType_afterStarDocComment() async {
    // FunctionDeclaration  CompilationUnit
    await addTestSource('/** */ ^ zoo(z) { } String name;');
    await assertTarget('zoo', 'zoo(z) {}');
  }

  test_FunctionDeclaration_returnType_afterStarDocComment2() async {
    // FunctionDeclaration  CompilationUnit
    await addTestSource('/** */^ zoo(z) { } String name;');
    await assertTarget('zoo', 'zoo(z) {}');
  }

  test_InstanceCreationExpression_identifier() async {
    // InstanceCreationExpression  ExpressionStatement  Block
    await addTestSource('class C {foo(){var f; {var x;} new ^C();}}');
    await assertTarget('C', 'new C()');
  }

  test_InstanceCreationExpression_keyword() async {
    // InstanceCreationExpression  ExpressionStatement  Block
    await addTestSource('class C {foo(){var f; {var x;} new^ }}');
    await assertTarget('new ();', '{var f; {var x;} new ();}');
  }

  test_InstanceCreationExpression_keyword2() async {
    // InstanceCreationExpression  ExpressionStatement  Block
    await addTestSource('class C {foo(){var f; {var x;} new^ C();}}');
    await assertTarget('new C();', '{var f; {var x;} new C();}');
  }

  test_MapLiteralEntry() async {
    // MapLiteralEntry  MapLiteral  VariableDeclaration
    await addTestSource('foo = {^');
    await assertTarget(' : ', '{ : }');
  }

  test_MapLiteralEntry1() async {
    // MapLiteralEntry  MapLiteral  VariableDeclaration
    await addTestSource('foo = {T^');
    await assertTarget('T : ', '{T : }');
  }

  test_MapLiteralEntry2() async {
    // SimpleIdentifier  MapLiteralEntry  MapLiteral  VariableDeclaration
    await addTestSource('foo = {7:T^};');
    await assertTarget('T', '7 : T');
  }

  test_MethodDeclaration_inLineComment() async {
    // Comment  ClassDeclaration  CompilationUnit
    await addTestSource('''
      class C2 {
        // normal comment ^
        zoo(z) { } String name; }''');
    await assertTarget(
        '// normal comment ', 'class C2 {zoo(z) {} String name;}');
  }

  test_MethodDeclaration_inLineComment2() async {
    // Comment  ClassDeclaration  CompilationUnit
    await addTestSource('''
      class C2 {
        // normal ^comment
        zoo(z) { } String name; }''');
    await assertTarget(
        '// normal comment', 'class C2 {zoo(z) {} String name;}');
  }

  test_MethodDeclaration_inLineComment3() async {
    // Comment  ClassDeclaration  CompilationUnit
    await addTestSource('''
      class C2 {
        // normal comment ^
        // normal comment 2
        zoo(z) { } String name; }''');
    await assertTarget(
        '// normal comment ', 'class C2 {zoo(z) {} String name;}');
  }

  test_MethodDeclaration_inLineComment4() async {
    // Comment  ClassDeclaration  CompilationUnit
    await addTestSource('''
      class C2 {
        // normal comment
        // normal comment 2^
        zoo(z) { } String name; }''');
    await assertTarget(
        '// normal comment 2', 'class C2 {zoo(z) {} String name;}');
  }

  test_MethodDeclaration_inLineDocComment() async {
    // Comment  MethodDeclaration  ClassDeclaration  CompilationUnit
    await addTestSource('''
      class C2 {
        /// some dartdoc ^
        zoo(z) { } String name; }''');
    await assertTarget('/// some dartdoc ', '');
    expect(target.containingNode is Comment, isTrue);
    expect(target.containingNode.parent.toSource(), 'zoo(z) {}');
  }

  test_MethodDeclaration_inLineDocComment2() async {
    // Comment  MethodDeclaration  ClassDeclaration  CompilationUnit
    await addTestSource('''
      class C2 {
        /// some ^dartdoc
        zoo(z) { } String name; }''');
    await assertTarget('/// some dartdoc', '');
    expect(target.containingNode is Comment, isTrue);
    expect(target.containingNode.parent.toSource(), 'zoo(z) {}');
  }

  test_MethodDeclaration_inStarComment() async {
    // Comment  ClassDeclaration  CompilationUnit
    await addTestSource('class C2 {/* ^ */ zoo(z) {} String name;}');
    await assertTarget('/*  */', 'class C2 {zoo(z) {} String name;}');
  }

  test_MethodDeclaration_inStarComment2() async {
    // Comment  ClassDeclaration  CompilationUnit
    await addTestSource('class C2 {/*  *^/ zoo(z) {} String name;}');
    await assertTarget('/*  */', 'class C2 {zoo(z) {} String name;}');
  }

  test_MethodDeclaration_inStarDocComment() async {
    // Comment  MethodDeclaration  ClassDeclaration  CompilationUnit
    await addTestSource('class C2 {/** ^ */ zoo(z) { } String name; }');
    await assertTarget('/**  */', '');
    expect(target.containingNode is Comment, isTrue);
    expect(target.containingNode.parent.toSource(), 'zoo(z) {}');
  }

  test_MethodDeclaration_inStarDocComment2() async {
    // Comment  MethodDeclaration  ClassDeclaration  CompilationUnit
    await addTestSource('class C2 {/**  *^/ zoo(z) { } String name; }');
    await assertTarget('/**  */', '');
    expect(target.containingNode is Comment, isTrue);
    expect(target.containingNode.parent.toSource(), 'zoo(z) {}');
  }

  test_MethodDeclaration_returnType() async {
    // ClassDeclaration  CompilationUnit
    await addTestSource('class C2 {^ zoo(z) { } String name; }');
    await assertTarget('zoo(z) {}', 'class C2 {zoo(z) {} String name;}');
  }

  test_MethodDeclaration_returnType_afterLineComment() async {
    // MethodDeclaration  ClassDeclaration  CompilationUnit
    await addTestSource('''
      class C2 {
        // normal comment
        ^ zoo(z) {} String name;}''');
    await assertTarget('zoo(z) {}', 'class C2 {zoo(z) {} String name;}');
  }

  test_MethodDeclaration_returnType_afterLineComment2() async {
    // MethodDeclaration  ClassDeclaration  CompilationUnit
    // TOD(danrubel) left align all test source
    await addTestSource('''
class C2 {
  // normal comment
^ zoo(z) {} String name;}''');
    await assertTarget('zoo(z) {}', 'class C2 {zoo(z) {} String name;}');
  }

  test_MethodDeclaration_returnType_afterLineDocComment() async {
    // SimpleIdentifier  MethodDeclaration  ClassDeclaration  CompilationUnit
    await addTestSource('''
      class C2 {
        /// some dartdoc
        ^ zoo(z) { } String name; }''');
    await assertTarget('zoo', 'zoo(z) {}');
  }

  test_MethodDeclaration_returnType_afterLineDocComment2() async {
    // SimpleIdentifier  MethodDeclaration  ClassDeclaration  CompilationUnit
    await addTestSource('''
class C2 {
  /// some dartdoc
^ zoo(z) { } String name; }''');
    await assertTarget('zoo', 'zoo(z) {}');
  }

  test_MethodDeclaration_returnType_afterStarComment() async {
    // ClassDeclaration  CompilationUnit
    await addTestSource('class C2 {/* */ ^ zoo(z) { } String name; }');
    await assertTarget('zoo(z) {}', 'class C2 {zoo(z) {} String name;}');
  }

  test_MethodDeclaration_returnType_afterStarComment2() async {
    // ClassDeclaration  CompilationUnit
    await addTestSource('class C2 {/* */^ zoo(z) { } String name; }');
    await assertTarget('zoo(z) {}', 'class C2 {zoo(z) {} String name;}');
  }

  test_MethodDeclaration_returnType_afterStarDocComment() async {
    // MethodDeclaration  ClassDeclaration  CompilationUnit
    await addTestSource('class C2 {/** */ ^ zoo(z) { } String name; }');
    await assertTarget('zoo', 'zoo(z) {}');
  }

  test_MethodDeclaration_returnType_afterStarDocComment2() async {
    // MethodDeclaration  ClassDeclaration  CompilationUnit
    await addTestSource('class C2 {/** */^ zoo(z) { } String name; }');
    await assertTarget('zoo', 'zoo(z) {}');
  }

  test_SwitchStatement_c() async {
    // Token('c') SwitchStatement
    await addTestSource('main() { switch(x) {c^} }');
    await assertTarget('}', 'switch (x) {}');
  }

  test_SwitchStatement_c2() async {
    // Token('c') SwitchStatement
    await addTestSource('main() { switch(x) { c^ } }');
    await assertTarget('}', 'switch (x) {}');
  }

  test_SwitchStatement_empty() async {
    // SwitchStatement
    await addTestSource('main() { switch(x) {^} }');
    await assertTarget('}', 'switch (x) {}');
  }

  test_SwitchStatement_empty2() async {
    // SwitchStatement
    await addTestSource('main() { switch(x) { ^ } }');
    await assertTarget('}', 'switch (x) {}');
  }

  test_TypeArgumentList() async {
    // TypeName  TypeArgumentList  TypeName
    await addTestSource('main() { C<^> c; }');
    await assertTarget('', '<>');
  }

  test_TypeArgumentList2() async {
    // TypeName  TypeArgumentList  TypeName
    await addTestSource('main() { C<C^> c; }');
    await assertTarget('C', '<C>');
  }

  test_VariableDeclaration_lhs_identifier_after() async {
    // VariableDeclaration  VariableDeclarationList
    await addTestSource('main() {int b^ = 1;}');
    await assertTarget('b = 1', 'int b = 1');
  }

  test_VariableDeclaration_lhs_identifier_before() async {
    // VariableDeclaration  VariableDeclarationList
    await addTestSource('main() {int ^b = 1;}');
    await assertTarget('b = 1', 'int b = 1');
  }
}
