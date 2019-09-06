// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/src/utilities/completion/completion_target.dart';
import 'package:analyzer_plugin/src/utilities/completion/optype.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../support/abstract_context.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(OpTypeTest);
    defineReflectiveTests(OpTypeDart1OnlyTest);
    defineReflectiveTests(OpTypeTestWithExtensionMethods);
  });
}

@reflectiveTest
// TODO: determine if tests here need to be fixed for Dart2.
class OpTypeDart1OnlyTest extends OpTypeTestCommon {
  @failingTest
  test_Annotation() async {
    // SimpleIdentifier  Annotation  MethodDeclaration  ClassDeclaration
    addTestSource('class C { @A^ }');
    await assertOpType(constructors: true, returnValue: true, typeNames: true);
    // TODO(danrubel): This test fails when fasta parser is enabled
    // because the @A is dropped from the Analyzer AST.
    // Ideally we generate a synthetic field and associate the annotation
    // with that field, but doing so breaks test_constructorAndMethodNameCollision.
    // See https://dart-review.googlesource.com/c/sdk/+/65760/3/pkg/analyzer/lib/src/fasta/ast_builder.dart#2395

    // The old Analyzer parser passes this test, but will be turned off soon.
    // It is preferable to throw only if the old analyzer is being used,
    // but there does not seem to be a reliable way to determine that here.
    // TODO(danrubel): remove this once fasta parser is enabled by default.
    throw 'Remove this exception once fasta parser is the default';
  }

  test_ArgumentList() async {
    // ArgumentList  MethodInvocation  ExpressionStatement  Block
    addTestSource('void main() {expect(^)}');
    // If "expect()" were resolved, then either namedArgs would be true
    // or returnValue and typeNames would be true.
    await assertOpType(
        constructors: true,
        namedArgs: true,
        returnValue: true,
        typeNames: true,
        functionBody: true);
  }

  test_ArgumentList_namedParam() async {
    // SimpleIdentifier  NamedExpression  ArgumentList  MethodInvocation
    // ExpressionStatement
    addTestSource('void main() {expect(foo: ^)}');
    await assertOpType(
        constructors: true,
        returnValue: true,
        typeNames: true,
        functionBody: true);
  }

  test_ArgumentList_prefixedIdentifier() async {
    // SimpleIdentifier  PrefixedIdentifier  ArgumentList
    addTestSource('void main() {expect(aa.^)}');
    await assertOpType(
        constructors: true,
        returnValue: true,
        typeNames: true,
        prefixed: true,
        functionBody: true);
  }

  test_ArgumentList_resolved() async {
    // ArgumentList  MethodInvocation  ExpressionStatement  Block
    addTestSource('void main() {int.parse(^)}');
    await assertOpType(
        constructors: true,
        returnValue: true,
        typeNames: true,
        functionBody: true);
  }

  test_AsIdentifier() async {
    addTestSource('class A {var asdf; foo() {as^}');
    await assertOpType(
        constructors: true,
        returnValue: true,
        typeNames: true,
        voidReturn: true,
        methodBody: true);
  }

  test_Assert() async {
    addTestSource('main() {assert(^)}');
    await assertOpType(
        constructors: true,
        returnValue: true,
        typeNames: true,
        functionBody: true);
  }

  test_AssertInitializer() async {
    addTestSource('class C { C() : assert(^); }');
    await assertOpType(constructors: true, returnValue: true, typeNames: true);
  }

  test_AssignmentExpression_RHS() async {
    // SimpleIdentifier  VariableDeclaration  VariableDeclarationList
    // VariableDeclarationStatement  Block
    addTestSource('class A {} main() {int a; int b = ^}');
    await assertOpType(
        constructors: true,
        returnValue: true,
        typeNames: true,
        functionBody: true);
  }

  test_AssignmentExpression_type() async {
    // SimpleIdentifier  TypeName  VariableDeclarationList
    // VariableDeclarationStatement  Block
    addTestSource('''
      main() {
        int a;
        ^ b = 1;}''');
    // TODO (danrubel) When entering 1st of 2 identifiers on assignment LHS
    // the user may be either (1) entering a type for the assignment
    // or (2) starting a new statement.
    // Consider suggesting only types
    // if only spaces separates the 1st and 2nd identifiers.
    await assertOpType(
        constructors: true,
        returnValue: true,
        typeNames: true,
        voidReturn: true,
        functionBody: true);
  }

  test_AssignmentExpression_type_newline() async {
    // SimpleIdentifier  TypeName  VariableDeclarationList
    // VariableDeclarationStatement  Block
    addTestSource('''
      main() {
        int a;
        ^
        b = 1;}''');
    // Allow non-types preceding an identifier on LHS of assignment
    // if newline follows first identifier
    // because user is probably starting a new statement
    await assertOpType(
        constructors: true,
        returnValue: true,
        typeNames: true,
        voidReturn: true,
        functionBody: true);
  }

  test_AssignmentExpression_type_partial() async {
    // SimpleIdentifier  TypeName  VariableDeclarationList
    // VariableDeclarationStatement  Block
    addTestSource('''
      main() {
        int a;
        int^ b = 1;}''');
    // TODO (danrubel) When entering 1st of 2 identifiers on assignment LHS
    // the user may be either (1) entering a type for the assignment
    // or (2) starting a new statement.
    // Consider suggesting only types
    // if only spaces separates the 1st and 2nd identifiers.
    await assertOpType(
        constructors: true,
        returnValue: true,
        typeNames: true,
        voidReturn: true,
        functionBody: true);
  }

  test_AssignmentExpression_type_partial_newline() async {
    // SimpleIdentifier  TypeName  VariableDeclarationList
    // VariableDeclarationStatement  Block
    addTestSource('''
      main() {
        int a;
        i^
        b = 1;}''');
    // Allow non-types preceding an identifier on LHS of assignment
    // if newline follows first identifier
    // because user is probably starting a new statement
    await assertOpType(
        constructors: true,
        returnValue: true,
        typeNames: true,
        voidReturn: true,
        functionBody: true);
  }

  test_AwaitExpression() async {
    // SimpleIdentifier  AwaitExpression  ExpressionStatement
    addTestSource('main() async {A a; await ^}');
    await assertOpType(
        constructors: true,
        returnValue: true,
        typeNames: true,
        functionBody: true);
  }

  test_AwaitExpression2() async {
    addTestSource('main() async {A a; await c^ await}');
    await assertOpType(
        constructors: true,
        returnValue: true,
        typeNames: true,
        functionBody: true);
  }

  test_AwaitExpression3() async {
    addTestSource('main() async {A a; await ^ await foo;}');
    await assertOpType(
        constructors: true,
        returnValue: true,
        typeNames: true,
        functionBody: true);
  }

  test_AwaitExpression4() async {
    addTestSource('main() async {A a; await ^ await bar();}');
    await assertOpType(
        constructors: true,
        returnValue: true,
        typeNames: true,
        functionBody: true);
  }

  test_AwaitExpression_assignment() async {
    addTestSource('main() async {A a; int x = await ^}');
    await assertOpType(
        constructors: true,
        returnValue: true,
        typeNames: true,
        functionBody: true);
  }

  test_AwaitExpression_assignment2() async {
    addTestSource('main() async {A a; int x = await ^ await foo;}');
    await assertOpType(
        constructors: true,
        returnValue: true,
        typeNames: true,
        functionBody: true);
  }

  test_AwaitExpression_assignment3() async {
    addTestSource('main() async {A a; int x = await v^ int y = await foo;}');
    await assertOpType(
        constructors: true,
        returnValue: true,
        typeNames: true,
        functionBody: true);
  }

  test_BinaryExpression_LHS() async {
    // SimpleIdentifier  BinaryExpression  VariableDeclaration
    // VariableDeclarationList  VariableDeclarationStatement
    addTestSource('main() {int a = 1, b = ^ + 2;}');
    await assertOpType(
        constructors: true,
        returnValue: true,
        typeNames: true,
        functionBody: true);
  }

  test_BinaryExpression_RHS() async {
    // SimpleIdentifier  BinaryExpression  VariableDeclaration
    // VariableDeclarationList  VariableDeclarationStatement
    addTestSource('main() {int a = 1, b = 2 + ^;}');
    await assertOpType(
        constructors: true,
        returnValue: true,
        typeNames: true,
        functionBody: true);
  }

  test_BinaryExpression_RHS2() async {
    // SimpleIdentifier  BinaryExpression
    addTestSource('main() {if (c < ^)}');
    await assertOpType(
        constructors: true,
        returnValue: true,
        typeNames: true,
        functionBody: true);
  }

  test_Block() async {
    // Block  BlockFunctionBody  MethodDeclaration
    addTestSource('''
      class X {
        a() {
          var f;
          localF(int arg1) { }
          {var x;}
          ^ var r;
        }
      }''');
    await assertOpType(
        constructors: true,
        returnValue: true,
        typeNames: true,
        voidReturn: true,
        methodBody: true);
  }

  test_Block_catch_2a() async {
    // '}'  Block  BlockFunctionBody  FunctionExpression
    addTestSource('main() {try {} catch () {} ^}');
    await assertOpType(
        constructors: true,
        returnValue: true,
        typeNames: true,
        voidReturn: true,
        functionBody: true);
  }

  test_Block_catch_2b() async {
    // [ExpressionStatement 'c']  Block  BlockFunctionBody
    addTestSource('main() {try {} catch () {} c^}');
    await assertOpType(
        constructors: true,
        returnValue: true,
        typeNames: true,
        voidReturn: true,
        functionBody: true);
  }

  test_Block_catch_2c() async {
    // [EmptyStatement]  Block  BlockFunctionBody  FunctionExpression
    addTestSource('main() {try {} catch () {} ^;}');
    await assertOpType(
        constructors: true,
        returnValue: true,
        typeNames: true,
        voidReturn: true,
        functionBody: true);
  }

  test_Block_catch_2d() async {
    // [VariableDeclarationStatement 'Foo foo']  Block  BlockFunctionBody
    addTestSource('main() {try {} catch () {} ^ Foo foo;}');
    await assertOpType(
        constructors: true,
        returnValue: true,
        typeNames: true,
        voidReturn: true,
        functionBody: true);
  }

  test_Block_catch_3a() async {
    // '}'  Block  BlockFunctionBody  FunctionExpression
    addTestSource('main() {try {} finally {} ^}');
    await assertOpType(
        constructors: true,
        returnValue: true,
        typeNames: true,
        voidReturn: true,
        functionBody: true);
  }

  test_Block_catch_3b() async {
    // [ExpressionStatement 'c']  Block  BlockFunctionBody
    addTestSource('main() {try {} finally {} c^}');
    await assertOpType(
        constructors: true,
        returnValue: true,
        typeNames: true,
        voidReturn: true,
        functionBody: true);
  }

  test_Block_catch_3c() async {
    // [EmptyStatement]  Block  BlockFunctionBody  FunctionExpression
    addTestSource('main() {try {} finally {} ^;}');
    await assertOpType(
        constructors: true,
        returnValue: true,
        typeNames: true,
        voidReturn: true,
        functionBody: true);
  }

  test_Block_catch_3d() async {
    // [VariableDeclarationStatement 'Foo foo']  Block  BlockFunctionBody
    addTestSource('main() {try {} finally {} ^ Foo foo;}');
    await assertOpType(
        constructors: true,
        returnValue: true,
        typeNames: true,
        voidReturn: true,
        functionBody: true);
  }

  test_Block_empty() async {
    // Block  BlockFunctionBody  MethodDeclaration  ClassDeclaration
    addTestSource('class A extends E implements I with M {a() {^}}');
    await assertOpType(
        constructors: true,
        returnValue: true,
        typeNames: true,
        voidReturn: true,
        methodBody: true);
  }

  test_Block_identifier_partial() async {
    addTestSource('class X {a() {var f; {var x;} D^ var r;} void b() { }}');
    await assertOpType(
        constructors: true,
        returnValue: true,
        typeNames: true,
        voidReturn: true,
        methodBody: true);
  }

  test_Block_in_constructor() async {
    addTestSource('class A {A() {^}}');
    await assertOpType(
        constructors: true,
        returnValue: true,
        typeNames: true,
        constructorBody: true,
        voidReturn: true);
  }

  test_Block_in_function() async {
    addTestSource('foo() {^}');
    await assertOpType(
        constructors: true,
        returnValue: true,
        typeNames: true,
        functionBody: true,
        voidReturn: true);
  }

  test_Block_in_method() async {
    addTestSource('class A {foo() {^}}');
    await assertOpType(
        constructors: true,
        returnValue: true,
        typeNames: true,
        methodBody: true,
        voidReturn: true);
  }

  test_Block_keyword() async {
    addTestSource('class C { static C get instance => null; } main() {C.in^}');
    await assertOpType(
        constructors: true,
        prefixed: true,
        returnValue: true,
        typeNames: true,
        voidReturn: true,
        functionBody: true);
  }

  test_Block_static() async {
    addTestSource('class A {static foo() {^}}');
    await assertOpType(
        constructors: true,
        returnValue: true,
        typeNames: true,
        staticMethodBody: true,
        methodBody: true,
        voidReturn: true);
  }

  test_CascadeExpression_selector1() async {
    // PropertyAccess  CascadeExpression  ExpressionStatement  Block
    addTestSource('''
      // looks like a cascade to the parser
      // but the user is trying to get completions for a non-cascade
      main() {A a; a.^.z}''');
    await assertOpType(
        constructors: true,
        returnValue: true,
        typeNames: true,
        voidReturn: true,
        prefixed: true,
        functionBody: true);
  }

  test_CascadeExpression_selector2() async {
    // SimpleIdentifier  PropertyAccess  CascadeExpression  ExpressionStatement
    addTestSource('main() {A a; a..^z}');
    await assertOpType(
        constructors: true,
        returnValue: true,
        voidReturn: true,
        prefixed: true,
        functionBody: true);
  }

  test_CascadeExpression_selector2_withTrailingReturn() async {
    // PropertyAccess  CascadeExpression  ExpressionStatement  Block
    addTestSource('main() {A a; a..^ return}');
    await assertOpType(
        constructors: true,
        returnValue: true,
        voidReturn: true,
        prefixed: true,
        functionBody: true);
  }

  test_CascadeExpression_target() async {
    // SimpleIdentifier  CascadeExpression  ExpressionStatement
    addTestSource('main() {A a; a^..b}');
    await assertOpType(
        constructors: true,
        returnValue: true,
        typeNames: true,
        voidReturn: true,
        functionBody: true);
  }

  test_CatchClause_typed() async {
    // Block  CatchClause  TryStatement
    addTestSource('class A {a() {try{var x;} on E catch (e) {^}}}');
    await assertOpType(
        constructors: true,
        returnValue: true,
        typeNames: true,
        voidReturn: true,
        methodBody: true);
  }

  test_CatchClause_untyped() async {
    // Block  CatchClause  TryStatement
    addTestSource('class A {a() {try{var x;} catch (e, s) {^}}}');
    await assertOpType(
        constructors: true,
        returnValue: true,
        typeNames: true,
        voidReturn: true,
        methodBody: true);
  }

  test_CommentReference() async {
    // SimpleIdentifier  CommentReference  Comment  MethodDeclaration
    addTestSource('class A {/** [^] */ mth() {}');
    await assertOpType(
        constructors: true,
        returnValue: true,
        typeNames: true,
        voidReturn: true,
        kind: CompletionSuggestionKind.IDENTIFIER);
  }

  test_ConditionalExpression_elseExpression() async {
    // SimpleIdentifier  ConditionalExpression  ReturnStatement
    addTestSource('class C {foo(){var f; {var x;} return a ? T1 : T^}}');
    await assertOpType(
        constructors: true,
        returnValue: true,
        typeNames: true,
        methodBody: true);
  }

  test_ConditionalExpression_elseExpression_empty() async {
    // SimpleIdentifier  ConditionalExpression  ReturnStatement
    addTestSource('class C {foo(){var f; {var x;} return a ? T1 : ^}}');
    await assertOpType(
        constructors: true,
        returnValue: true,
        typeNames: true,
        methodBody: true);
  }

  test_ConditionalExpression_partial_thenExpression() async {
    // SimpleIdentifier  ConditionalExpression  ReturnStatement
    addTestSource('class C {foo(){var f; {var x;} return a ? T^}}');
    await assertOpType(
        constructors: true,
        returnValue: true,
        typeNames: true,
        methodBody: true);
  }

  test_ConditionalExpression_partial_thenExpression_empty() async {
    // SimpleIdentifier  ConditionalExpression  ReturnStatement
    addTestSource('class C {foo(){var f; {var x;} return a ? ^}}');
    await assertOpType(
        constructors: true,
        returnValue: true,
        typeNames: true,
        methodBody: true);
  }

  test_ConditionalExpression_thenExpression() async {
    // SimpleIdentifier  ConditionalExpression  ReturnStatement
    addTestSource('class C {foo(){var f; {var x;} return a ? T^ : c}}');
    await assertOpType(
        constructors: true,
        returnValue: true,
        typeNames: true,
        methodBody: true);
  }

  test_ConstructorFieldInitializer_name() async {
    addTestSource(r'''
class C {
  final int foo;
  
  C() : ^
}
''');
    await assertOpType();
  }

  test_ConstructorFieldInitializer_value() async {
    addTestSource(r'''
class C {
  final int foo;
  
  C() : foo = ^
}
''');
    await assertOpType(
      constructors: true,
      returnValue: true,
      typeNames: true,
    );
  }

  test_DefaultFormalParameter_named_expression() async {
    // DefaultFormalParameter FormalParameterList MethodDeclaration
    addTestSource('class A {a(blat: ^) { }}');
    await assertOpType(
      constructors: true,
      returnValue: true,
      typeNames: true,
    );
  }

  test_DoStatement() async {
    // SimpleIdentifier  DoStatement  Block
    addTestSource('main() {do{} while(^x);}');
    await assertOpType(
        constructors: true,
        returnValue: true,
        typeNames: true,
        functionBody: true);
  }

  test_ExpressionFunctionBody() async {
    // SimpleIdentifier  ExpressionFunctionBody  FunctionExpression
    addTestSource('m(){[1].forEach((x)=>^x);}');
    await assertOpType(
        constructors: true,
        returnValue: true,
        typeNames: true,
        functionBody: true);
  }

  test_ExpressionStatement() async {
    // ExpressionStatement  Block  BlockFunctionBody
    addTestSource('n(){f(3);^}');
    await assertOpType(
        constructors: true,
        returnValue: true,
        typeNames: true,
        voidReturn: true,
        functionBody: true);
  }

  test_ForEachStatement() async {
    // SimpleIdentifier  ForEachStatement  Block
    addTestSource('main() {for(z in ^zs) {}}');
    await assertOpType(
        constructors: true,
        returnValue: true,
        typeNames: true,
        functionBody: true);
  }

  test_ForEachStatement_body_typed() async {
    // Block  ForEachStatement
    addTestSource('main(args) {for (int foo in bar) {^}}');
    await assertOpType(
        constructors: true,
        returnValue: true,
        typeNames: true,
        voidReturn: true,
        functionBody: true);
  }

  test_ForEachStatement_body_untyped() async {
    // Block  ForEachStatement
    addTestSource('main(args) {for (foo in bar) {^}}');
    await assertOpType(
        constructors: true,
        returnValue: true,
        typeNames: true,
        voidReturn: true,
        functionBody: true);
  }

  test_ForEachStatement_iterable() async {
    // SimpleIdentifier  ForEachStatement  Block
    addTestSource('main(args) {for (int foo in ^) {}}');
    await assertOpType(
        constructors: true,
        returnValue: true,
        typeNames: true,
        functionBody: true);
  }

  test_ForElement_body() async {
    addTestSource('main(args) {[for (var foo in [0]) ^];}');
    await assertOpType(
        constructors: true,
        returnValue: true,
        typeNames: true,
        functionBody: true);
  }

  test_ForElement_forEachParts_iterable() async {
    addTestSource('main(args) {[for (var foo in ^) foo];}');
    await assertOpType(
        constructors: true,
        returnValue: true,
        typeNames: true,
        functionBody: true);
  }

  test_ForElement_forEachParts_type() async {
    addTestSource('main(args) {[for (i^ foo in [0]) foo];}');
    await assertOpType(typeNames: true, functionBody: true);
  }

  test_FormalParameter_partialType() async {
    // FormalParameterList MethodDeclaration
    addTestSource('class A {a(b.^ f) { }}');
    await assertOpType(
      constructors: true,
      returnValue: true,
      typeNames: true,
      prefixed: true,
    );
  }

  test_FormalParameter_partialType2() async {
    // FormalParameterList MethodDeclaration
    addTestSource('class A {a(b.z^ f) { }}');
    await assertOpType(
      constructors: true,
      returnValue: true,
      typeNames: true,
      prefixed: true,
    );
  }

  test_FormalParameter_partialType3() async {
    // FormalParameterList MethodDeclaration
    addTestSource('class A {a(b.^) { }}');
    await assertOpType(
      constructors: true,
      returnValue: true,
      typeNames: true,
      prefixed: true,
    );
  }

  test_ForStatement_condition() async {
    // SimpleIdentifier  ForStatement
    addTestSource('main() {for (int index = 0; i^)}');
    await assertOpType(
        constructors: true,
        returnValue: true,
        typeNames: true,
        functionBody: true);
  }

  test_ForStatement_updaters() async {
    // SimpleIdentifier  ForStatement
    addTestSource('main() {for (int index = 0; index < 10; i^)}');
    // TODO (danrubel) may want to exclude methods/functions with void return
    await assertOpType(
        constructors: true,
        returnValue: true,
        typeNames: true,
        voidReturn: true,
        functionBody: true);
  }

  test_ForStatement_updaters_prefix_expression() async {
    // SimpleIdentifier  PrefixExpression  ForStatement
    addTestSource('main() {for (int index = 0; index < 10; ++i^)}');
    await assertOpType(
        constructors: true,
        returnValue: true,
        typeNames: true,
        functionBody: true);
  }

  test_IfElement_condition() async {
    addTestSource('''
main() {
  [if (^)];
}
''');
    await assertOpType(
        constructors: true,
        returnValue: true,
        typeNames: true,
        functionBody: true);
  }

  test_IfElement_else() async {
    addTestSource('''
main() {
  [if (true) 0 else ^];
}
''');
    await assertOpType(
        constructors: true,
        returnValue: true,
        typeNames: true,
        functionBody: true,
        voidReturn: true);
  }

  test_IfElement_then() async {
    addTestSource('''
main() {
  [if (true) ^];
}
''');
    await assertOpType(
        constructors: true,
        returnValue: true,
        typeNames: true,
        functionBody: true,
        voidReturn: true);
  }

  test_IfStatement() async {
    // EmptyStatement  IfStatement  Block  BlockFunctionBody
    addTestSource('main(){var a; if (true) ^}');
    await assertOpType(
        constructors: true,
        returnValue: true,
        typeNames: true,
        voidReturn: true,
        functionBody: true);
  }

  test_IfStatement_condition() async {
    // SimpleIdentifier  IfStatement  Block  BlockFunctionBody
    addTestSource('main(){var a; if (^)}');
    await assertOpType(
        constructors: true,
        returnValue: true,
        typeNames: true,
        functionBody: true);
  }

  test_IfStatement_empty() async {
    // SimpleIdentifier  PrefixIdentifier  IfStatement
    addTestSource('class A {foo() {A a; if (^) something}}');
    await assertOpType(
        constructors: true,
        returnValue: true,
        typeNames: true,
        methodBody: true);
  }

  test_IfStatement_invocation() async {
    // SimpleIdentifier  PrefixIdentifier  IfStatement
    addTestSource('main() {var a; if (a.^) something}');
    await assertOpType(
        constructors: true,
        returnValue: true,
        typeNames: true,
        prefixed: true,
        functionBody: true);
  }

  test_IndexExpression() async {
    addTestSource('class C {foo(){var f; {var x;} f[^]}}');
    await assertOpType(
        constructors: true,
        returnValue: true,
        typeNames: true,
        methodBody: true);
  }

  test_IndexExpression2() async {
    addTestSource('class C {foo(){var f; {var x;} f[T^]}}');
    await assertOpType(
        constructors: true,
        returnValue: true,
        typeNames: true,
        methodBody: true);
  }

  test_InstanceCreationExpression_keyword() async {
    // InstanceCreationExpression  ExpressionStatement  Block
    addTestSource('class C {foo(){var f; {var x;} new^ }}');
    await assertOpType(
        constructors: true,
        returnValue: true,
        typeNames: true,
        voidReturn: true,
        methodBody: true);
  }

  test_InstanceCreationExpression_keyword2() async {
    // InstanceCreationExpression  ExpressionStatement  Block
    addTestSource('class C {foo(){var f; {var x;} new^ C();}}');
    await assertOpType(
        constructors: true,
        returnValue: true,
        typeNames: true,
        voidReturn: true,
        methodBody: true);
  }

  test_InterpolationExpression() async {
    // SimpleIdentifier  InterpolationExpression  StringInterpolation
    addTestSource('main() {String name; print("hello \$^");}');
    await assertOpType(
        constructors: true, returnValue: true, functionBody: true);
  }

  test_InterpolationExpression_block() async {
    // SimpleIdentifier  InterpolationExpression  StringInterpolation
    addTestSource('main() {String name; print("hello \${n^}");}');
    await assertOpType(
        constructors: true,
        returnValue: true,
        typeNames: true,
        functionBody: true);
  }

  test_InterpolationExpression_prefix_selector() async {
    // SimpleIdentifier  PrefixedIdentifier  InterpolationExpression
    addTestSource('main() {String name; print("hello \${name.^}");}');
    await assertOpType(
        constructors: true,
        returnValue: true,
        typeNames: true,
        prefixed: true,
        functionBody: true);
  }

  test_InterpolationExpression_prefix_target() async {
    // SimpleIdentifier  PrefixedIdentifier  InterpolationExpression
    addTestSource('main() {String name; print("hello \${nam^e.length}");}');
    await assertOpType(
        constructors: true,
        returnValue: true,
        typeNames: true,
        functionBody: true);
  }

  test_IsExpression_target() async {
    // IfStatement  Block  BlockFunctionBody
    addTestSource('main(){var a; if (^ is A)}');
    await assertOpType(
        constructors: true,
        returnValue: true,
        typeNames: true,
        functionBody: true);
  }

  test_Literal_list() async {
    // ']'  ListLiteral  ArgumentList  MethodInvocation
    addTestSource('main() {var Some; print([^]);}');
    await assertOpType(
        constructors: true,
        returnValue: true,
        typeNames: true,
        functionBody: true);
  }

  test_Literal_list2() async {
    // SimpleIdentifier ListLiteral  ArgumentList  MethodInvocation
    addTestSource('main() {var Some; print([S^]);}');
    await assertOpType(
        constructors: true,
        returnValue: true,
        typeNames: true,
        functionBody: true);
  }

  test_MapLiteralEntry() async {
    // MapLiteralEntry  MapLiteral  VariableDeclaration
    addTestSource('foo = {^');
    await assertOpType(constructors: true, returnValue: true, typeNames: true);
  }

  test_MapLiteralEntry1() async {
    // MapLiteralEntry  MapLiteral  VariableDeclaration
    addTestSource('foo = {T^');
    await assertOpType(constructors: true, returnValue: true, typeNames: true);
  }

  test_MapLiteralEntry2() async {
    // SimpleIdentifier  MapLiteralEntry  MapLiteral  VariableDeclaration
    addTestSource('foo = {7:T^};');
    await assertOpType(constructors: true, returnValue: true, typeNames: true);
  }

  test_MethodInvocation_no_semicolon() async {
    // MethodInvocation  ExpressionStatement  Block
    addTestSource('''
      class A implements I {
        // no semicolon between completion point and next statement
        set _s2(I x) {x.^ m(null);}
      }''');
    await assertOpType(
        constructors: true,
        returnValue: true,
        typeNames: true,
        voidReturn: true,
        prefixed: true,
        methodBody: true);
  }

  test_PostfixExpression() async {
    // SimpleIdentifier  PostfixExpression  ForStatement
    addTestSource('int x = 0; main() {ax+^+;}');
    await assertOpType(
        constructors: true,
        returnValue: true,
        typeNames: true,
        functionBody: true);
  }

  test_PrefixedIdentifier_class_const() async {
    // SimpleIdentifier PrefixedIdentifier ExpressionStatement Block
    addTestSource('main() {A.^}');
    await assertOpType(
        constructors: true,
        returnValue: true,
        typeNames: true,
        voidReturn: true,
        prefixed: true,
        functionBody: true);
  }

  test_PrefixedIdentifier_class_imported() async {
    // SimpleIdentifier  PrefixedIdentifier  ExpressionStatement
    addTestSource('main() {A a; a.^}');
    await assertOpType(
        constructors: true,
        returnValue: true,
        typeNames: true,
        voidReturn: true,
        prefixed: true,
        functionBody: true);
  }

  test_PrefixedIdentifier_prefix() async {
    // SimpleIdentifier  PrefixedIdentifier  ExpressionStatement
    addTestSource('class X {foo(){A^.bar}}');
    await assertOpType(
        constructors: true,
        typeNames: true,
        returnValue: true,
        voidReturn: true,
        methodBody: true);
  }

  test_PropertyAccess_expression() async {
    // SimpleIdentifier  MethodInvocation  PropertyAccess  ExpressionStatement
    addTestSource('class A {a() {"hello".to^String().length}}');
    await assertOpType(
        constructors: true,
        returnValue: true,
        typeNames: true,
        voidReturn: true,
        prefixed: true,
        methodBody: true);
  }

  test_PropertyAccess_selector() async {
    // SimpleIdentifier  PropertyAccess  ExpressionStatement  Block
    addTestSource('class A {a() {"hello".length.^}}');
    await assertOpType(
        constructors: true,
        returnValue: true,
        typeNames: true,
        voidReturn: true,
        prefixed: true,
        methodBody: true);
  }

  test_ReturnStatement() async {
    // ReturnStatement  Block
    addTestSource('f() { var vvv = 42; return ^ }');
    await assertOpType(
        constructors: true,
        returnValue: true,
        typeNames: true,
        functionBody: true);
  }

  test_SpreadElement() async {
    addTestSource(r'''
main() {
  [...^];
}
''');
    await assertOpType(
        constructors: true,
        returnValue: true,
        typeNames: true,
        functionBody: true);
  }

  test_SwitchCase_between() async {
    // SwitchCase  SwitchStatement  Block
    addTestSource('main() {switch(k) {case 1: ^ case 2: return}}');
    await assertOpType(
        constructors: true,
        returnValue: true,
        typeNames: true,
        voidReturn: true,
        functionBody: true);
  }

  test_SwitchCase_expression1() async {
    // SimpleIdentifier  SwitchCase  SwitchStatement
    addTestSource('''m() {switch (x) {case ^D: return;}}''');
    await assertOpType(
        constructors: true,
        returnValue: true,
        typeNames: true,
        functionBody: true);
  }

  test_SwitchCase_expression2() async {
    // SimpleIdentifier  SwitchCase  SwitchStatement
    addTestSource('''m() {switch (x) {case ^}}''');
    await assertOpType(
        constructors: true,
        returnValue: true,
        typeNames: true,
        functionBody: true);
  }

  test_SwitchDefault_between() async {
    // SwitchDefault  SwitchStatement  Block
    addTestSource('main() {switch(k) {case 1: ^ default: return;}}');
    await assertOpType(
        constructors: true,
        returnValue: true,
        typeNames: true,
        voidReturn: true,
        functionBody: true);
  }

  test_SwitchStatement_body_end() async {
    // Token('}')  SwitchStatement  Block
    addTestSource('main() {switch(k) {case 1:^}}');
    await assertOpType(
        constructors: true,
        returnValue: true,
        typeNames: true,
        voidReturn: true,
        functionBody: true);
  }

  test_SwitchStatement_body_end2() async {
    addTestSource('main() {switch(k) {case 1:as^}}');
    await assertOpType(
        constructors: true,
        returnValue: true,
        typeNames: true,
        voidReturn: true,
        functionBody: true);
  }

  test_SwitchStatement_expression1() async {
    // SimpleIdentifier  SwitchStatement  Block
    addTestSource('main() {switch(^k) {case 1:{}}}');
    await assertOpType(
        constructors: true,
        returnValue: true,
        typeNames: true,
        functionBody: true);
  }

  test_SwitchStatement_expression2() async {
    // SimpleIdentifier  SwitchStatement  Block
    addTestSource('main() {switch(k^) {case 1:{}}}');
    await assertOpType(
        constructors: true,
        returnValue: true,
        typeNames: true,
        functionBody: true);
  }

//
  test_SwitchStatement_expression_empty() async {
    // SimpleIdentifier  SwitchStatement  Block
    addTestSource('main() {switch(^) {case 1:{}}}');
    await assertOpType(
        constructors: true,
        returnValue: true,
        typeNames: true,
        functionBody: true);
  }

  test_ThisExpression_block() async {
    // MethodInvocation  ExpressionStatement  Block
    addTestSource('''
      class A implements I {
        // no semicolon between completion point and next statement
        set s1(I x) {} set _s2(I x) {this.^ m(null);}
      }''');
    // TODO(brianwilkerson) We should not be adding constructors here.
    await assertOpType(
        constructors: true,
        returnValue: true,
        voidReturn: true,
        prefixed: true,
        methodBody: true);
  }

  test_ThisExpression_constructor() async {
    // SimpleIdentifier  PropertyAccess  ExpressionStatement
    addTestSource('''
      class A implements I {
        A() {this.^}
      }''');
    await assertOpType(
        constructors: true,
        returnValue: true,
        voidReturn: true,
        prefixed: true,
        constructorBody: true);
  }

  test_ThrowExpression() async {
    // SimpleIdentifier  ThrowExpression  ExpressionStatement
    addTestSource('main() {throw ^;}');
    await assertOpType(
        constructors: true,
        returnValue: true,
        typeNames: true,
        functionBody: true);
  }

  test_VariableDeclarationStatement_afterSemicolon() async {
    // VariableDeclarationStatement  Block  BlockFunctionBody
    addTestSource('class A {var a; x() {var b;^}}');
    await assertOpType(
        constructors: true,
        returnValue: true,
        typeNames: true,
        voidReturn: true,
        methodBody: true);
  }

  test_VariableDeclarationStatement_RHS() async {
    // SimpleIdentifier  VariableDeclaration  VariableDeclarationList
    // VariableDeclarationStatement
    addTestSource('class C {bar(){var f; {var x;} var e = ^}}');
    await assertOpType(
        constructors: true,
        returnValue: true,
        typeNames: true,
        methodBody: true);
  }

  test_VariableDeclarationStatement_RHS_missing_semicolon() async {
    // VariableDeclaration  VariableDeclarationList
    // VariableDeclarationStatement
    addTestSource('class C {bar(){var f; {var x;} var e = ^ var g}}');
    await assertOpType(
        constructors: true,
        returnValue: true,
        typeNames: true,
        methodBody: true);
  }

  test_WhileStatement() async {
    // SimpleIdentifier  WhileStatement  Block
    addTestSource('mth() { while (b^) {} }}');
    await assertOpType(
        constructors: true,
        returnValue: true,
        typeNames: true,
        functionBody: true);
  }

  @failingTest
  test_WithClause() async {
    // WithClause  ClassDeclaration
    addTestSource('class x extends Object with ^\n{}');
    await assertOpType(constructors: true, typeNames: true);
  }
}

@reflectiveTest
class OpTypeTest extends OpTypeTestCommon {
  test_ArgumentList_constructor_named_resolved_1_0() async {
    // ArgumentList  InstanceCreationExpression  ExpressionStatement Block
    addTestSource(
      'main() { new A.b(^); }'
      'class A{ A.b({one, two}) {} }',
    );
    await assertOpType(namedArgs: true, functionBody: true);
  }

  test_ArgumentList_constructor_named_resolved_1_1() async {
    // ArgumentList  InstanceCreationExpression  ExpressionStatement  Block
    addTestSource(
      'main() { new A.b(o^); }'
      'class A { A.b({one, two}) {} }',
    );
    await assertOpType(namedArgs: true, functionBody: true);
  }

  test_ArgumentList_constructor_resolved_1_0() async {
    // ArgumentList  InstanceCreationExpression  ExpressionStatement Block
    addTestSource(
      'main() { new A(^); }'
      'class A{ A({one, two}) {} }',
    );
    await assertOpType(namedArgs: true, functionBody: true);
  }

  test_ArgumentList_constructor_resolved_1_1() async {
    // ArgumentList  InstanceCreationExpression  ExpressionStatement  Block
    addTestSource(
      'main() { new A(o^); }'
      'class A { A({one, two}) {} }',
    );
    await assertOpType(namedArgs: true, functionBody: true);
  }

  test_ArgumentList_factory_named_resolved_1_0() async {
    // ArgumentList  InstanceCreationExpression  ExpressionStatement Block
    addTestSource(
      'main() { new A.b(^); }'
      'class A{ factory A.b({one, two}) {} }',
    );
    await assertOpType(namedArgs: true, functionBody: true);
  }

  test_ArgumentList_factory_named_resolved_1_1() async {
    // ArgumentList  InstanceCreationExpression  ExpressionStatement  Block
    addTestSource(
      'main() { new A.b(o^); }'
      'class A { factory A.b({one, two}) {} }',
    );
    await assertOpType(namedArgs: true, functionBody: true);
  }

  test_ArgumentList_factory_resolved_1_0() async {
    // ArgumentList  InstanceCreationExpression  ExpressionStatement Block
    addTestSource(
      'main() { new A(^); }'
      'class A{ factory A({one, two}) {} }',
    );
    await assertOpType(namedArgs: true, functionBody: true);
  }

  test_ArgumentList_factory_resolved_1_1() async {
    // ArgumentList  InstanceCreationExpression  ExpressionStatement  Block
    addTestSource(
      'main() { new A(o^); }'
      'class A { factory A({one, two}) {} }',
    );
    await assertOpType(namedArgs: true, functionBody: true);
  }

  test_ArgumentList_method_resolved_1_0() async {
    // ArgumentList  MethodInvocation  ExpressionStatement  Block
    addTestSource('main() { foo(^);} foo({one, two}) {}');
    await assertOpType(namedArgs: true, functionBody: true);
  }

  test_ArgumentList_method_resolved_1_1() async {
    // ArgumentList  MethodInvocation  ExpressionStatement  Block
    addTestSource('main() { foo(o^);} foo({one, two}) {}');
    await assertOpType(namedArgs: true, functionBody: true);
  }

  test_ArgumentList_resolved_2_0() async {
    // ArgumentList  MethodInvocation  ExpressionStatement  Block
    addTestSource('void main() {int.parse("16", ^)}');
    await assertOpType(namedArgs: true, functionBody: true);
  }

  test_AsExpression() async {
    // SimpleIdentifier  TypeName  AsExpression
    addTestSource('class A {var b; X _c; foo() {var a; (a as ^).foo();}');
    await assertOpType(typeNames: true, methodBody: true);
  }

  test_AsIdentifier2() async {
    addTestSource('class A {var asdf; foo() {A as^}');
    await assertOpType(methodBody: true);
  }

  test_AssignmentExpression_name() async {
    // SimpleIdentifier  VariableDeclaration  VariableDeclarationList
    // VariableDeclarationStatement  Block
    addTestSource('class A {} main() {int a; int ^b = 1;}');
    await assertOpType(varNames: true, functionBody: true);
  }

  test_Block_catch_1a() async {
    // '}'  Block  BlockFunctionBody  FunctionExpression
    addTestSource('main() {try {} ^}');
    // Only return 'on', 'catch', and 'finally' keywords
    await assertOpType(functionBody: true);
  }

  test_Block_catch_1b() async {
    // [ExpressionStatement 'c']  Block  BlockFunctionBody
    addTestSource('main() {try {} c^}');
    // Only return 'on', 'catch', and 'finally' keywords
    await assertOpType(functionBody: true);
  }

  test_Block_catch_1c() async {
    // [EmptyStatement]  Block  BlockFunctionBody  FunctionExpression
    addTestSource('main() {try {} ^;}');
    // Only return 'on', 'catch', and 'finally' keywords
    await assertOpType(functionBody: true);
  }

  test_Block_catch_1d() async {
    // [VariableDeclarationStatement 'Foo foo']  Block  BlockFunctionBody
    addTestSource('main() {try {} ^ Foo foo;}');
    // Only return 'on', 'catch', and 'finally' keywords
    await assertOpType(functionBody: true);
  }

  test_Block_final() async {
    addTestSource('main() {final ^}');
    await assertOpType(typeNames: true, functionBody: true);
  }

  test_Block_final2() async {
    addTestSource('main() {final S^ v;}');
    await assertOpType(typeNames: true, functionBody: true);
  }

  test_Block_final3() async {
    addTestSource('main() {final ^ v;}');
    await assertOpType(typeNames: true, functionBody: true);
  }

  test_Block_final_final() async {
    addTestSource('main() {final ^ final S x;}');
    await assertOpType(typeNames: true, functionBody: true);
  }

  test_Block_final_final2() async {
    addTestSource('main() {final S^ final S x;}');
    await assertOpType(typeNames: true, functionBody: true);
  }

  test_Break_after_label() async {
    addTestSource('main() { foo: while (true) { break foo ^ ; } }');
    await assertOpType(/* No valid completions */ functionBody: true);
  }

  test_Break_before_label() async {
    addTestSource('main() { foo: while (true) { break ^ foo; } }');
    await assertOpType(statementLabel: true, functionBody: true);
  }

  test_Break_no_label() async {
    addTestSource('main() { foo: while (true) { break ^; } }');
    await assertOpType(statementLabel: true, functionBody: true);
  }

  test_catch_4a1() async {
    addTestSource('main() {try {} ^ on SomeException {}}');
    await assertOpType(functionBody: true);
  }

  test_catch_4a2() async {
    addTestSource('main() {try {} c^ on SomeException {}}');
    await assertOpType(functionBody: true);
  }

  test_catch_4b1() async {
    addTestSource('main() {try {} ^ catch (e) {}}');
    await assertOpType(functionBody: true);
  }

  test_catch_4b2() async {
    addTestSource('main() {try {} c^ catch (e) {}}');
    await assertOpType(functionBody: true);
  }

  test_catch_4c1() async {
    addTestSource('main() {try {} ^ finally {}}');
    await assertOpType(functionBody: true);
  }

  test_catch_4c2() async {
    addTestSource('main() {try {} c^ finally {}}');
    await assertOpType(functionBody: true);
  }

  test_catch_5a() async {
    addTestSource('main() {try {} on ^ finally {}}');
    await assertOpType(typeNames: true, functionBody: true);
  }

  test_catch_5b() async {
    addTestSource('main() {try {} on E^ finally {}}');
    await assertOpType(typeNames: true, functionBody: true);
  }

  test_CatchClause_onType() async {
    // TypeName  CatchClause  TryStatement
    addTestSource('class A {a() {try{var x;} on ^ {}}}');
    await assertOpType(typeNames: true, methodBody: true);
  }

  test_CatchClause_onType_noBrackets() async {
    // TypeName  CatchClause  TryStatement
    addTestSource('class A {a() {try{var x;} on ^}}');
    await assertOpType(typeNames: true, methodBody: true);
  }

  test_ClassDeclaration_body() async {
    // ClassDeclaration  CompilationUnit
    addTestSource('@deprecated class A {^}');
    await assertOpType(typeNames: true);
  }

  test_ClassDeclaration_body2() async {
    // SimpleIdentifier  MethodDeclaration  ClassDeclaration
    addTestSource('@deprecated class A {^mth() {}}');
    await assertOpType(typeNames: true);
  }

  test_Combinator_hide() async {
    // SimpleIdentifier  HideCombinator  ImportDirective
    addTestSource('''
      import "/testAB.dart" hide ^;
      class X {}''');
    await assertOpType();
  }

  test_Combinator_show() async {
    // SimpleIdentifier  HideCombinator  ImportDirective
    addTestSource('''
      import "/testAB.dart" show ^;
      import "/testCD.dart";
      class X {}''');
    await assertOpType();
  }

  test_ConstructorName() async {
    // SimpleIdentifier  PrefixedIdentifier  TypeName  ConstructorName
    // InstanceCreationExpression
    addTestSource('main() {new X.^}');
    await assertOpType(constructors: true, prefixed: true, functionBody: true);
  }

  test_ConstructorName_name_resolved() async {
    // SimpleIdentifier  PrefixedIdentifier  TypeName  ConstructorName
    // InstanceCreationExpression
    addTestSource('main() {new Str^ing.fromCharCodes([]);}');
    await assertOpType(constructors: true, functionBody: true);
  }

  test_ConstructorName_nameAndPrefix_resolved() async {
    // SimpleIdentifier  PrefixedIdentifier  TypeName  ConstructorName
    // InstanceCreationExpression
    addTestSource('''
import 'dart:core' as core;
main() {new core.String.from^CharCodes([]);}
''');
    await assertOpType(constructors: true, prefixed: true, functionBody: true);
  }

  test_ConstructorName_resolved() async {
    // SimpleIdentifier  PrefixedIdentifier  TypeName  ConstructorName
    // InstanceCreationExpression
    addTestSource('main() {new String.fr^omCharCodes([]);}');
    await assertOpType(constructors: true, prefixed: true, functionBody: true);
  }

  test_ConstructorName_unresolved() async {
    // SimpleIdentifier  PrefixedIdentifier  TypeName  ConstructorName
    // InstanceCreationExpression
    addTestSource('main() {new String.fr^omCharCodes([]);}');
    await assertOpType(constructors: true, prefixed: true, functionBody: true);
  }

  test_Continue_after_label() async {
    addTestSource('main() { foo: while (true) { continue foo ^ ; } }');
    await assertOpType(/* No valid completions */ functionBody: true);
  }

  test_Continue_before_label() async {
    addTestSource('main() { foo: while (true) { continue ^ foo; } }');
    await assertOpType(
        statementLabel: true, caseLabel: true, functionBody: true);
  }

  test_Continue_no_label() async {
    addTestSource('main() { foo: while (true) { continue ^; } }');
    await assertOpType(
        statementLabel: true, caseLabel: true, functionBody: true);
  }

  test_DoubleLiteral() async {
    addTestSource('main() { print(1.2^); }');
    // TODO expected functionBody: true
    await assertOpType(functionBody: false);
  }

  test_ExpressionStatement_name() async {
    // ExpressionStatement  Block  BlockFunctionBody  MethodDeclaration
    addTestSource('class C {a() {C ^}}');
    await assertOpType(varNames: true, methodBody: true);
  }

  test_ExpressionStatement_name_semicolon() async {
    // ExpressionStatement  Block  BlockFunctionBody  MethodDeclaration
    addTestSource('class C {a() {C ^;}}');
    await assertOpType(varNames: true, methodBody: true);
  }

  test_ExpressionStatement_prefixed_name() async {
    // ExpressionStatement  Block  BlockFunctionBody  MethodDeclaration
    addTestSource('class C {a() {x.Y ^}}');
    await assertOpType(varNames: true, methodBody: true);
  }

  test_ExpressionStatement_prefixed_name_semicolon() async {
    // ExpressionStatement  Block  BlockFunctionBody  MethodDeclaration
    addTestSource('class C {a() {x.Y ^;}}');
    await assertOpType(varNames: true, methodBody: true);
  }

  test_ExtendsClause() async {
    // ExtendsClause  ClassDeclaration
    addTestSource('class x extends ^\n{}');
    await assertOpType(typeNames: true);
  }

  test_FieldDeclaration_name_typed() async {
    // SimpleIdentifier  VariableDeclaration  VariableDeclarationList
    // FieldDeclaration
    addTestSource('class C {A ^}');
    await assertOpType(varNames: true);
  }

  test_FieldDeclaration_name_var() async {
    // SimpleIdentifier  VariableDeclaration  VariableDeclarationList
    // FieldDeclaration
    addTestSource('class C {var ^}');
    await assertOpType();
  }

  test_ForEachStatement_loopVariable() async {
    // SimpleIdentifier  ForEachStatement  Block
    addTestSource('main(args) {for (^ in args) {}}');
    await assertOpType(typeNames: true, functionBody: true);
  }

  test_ForEachStatement_loopVariable_name() async {
    // DeclaredIdentifier  ForEachStatement  Block
    addTestSource('main(args) {for (String ^ in args) {}}');
    await assertOpType(functionBody: true);
  }

  test_ForEachStatement_loopVariable_name2() async {
    // DeclaredIdentifier  ForEachStatement  Block
    addTestSource('main(args) {for (String f^ in args) {}}');
    await assertOpType(functionBody: true);
  }

  test_ForEachStatement_loopVariable_type() async {
    // SimpleIdentifier  ForEachStatement  Block
    addTestSource('main(args) {for (^ foo in args) {}}');
    await assertOpType(typeNames: true, functionBody: true);
  }

  test_ForEachStatement_loopVariable_type2() async {
    // DeclaredIdentifier  ForEachStatement  Block
    addTestSource('main(args) {for (S^ foo in args) {}}');
    await assertOpType(typeNames: true, functionBody: true);
  }

  test_FormalParameterList() async {
    // FormalParameterList MethodDeclaration
    addTestSource('class A {a(^) { }}');
    await assertOpType(typeNames: true);
  }

  test_ForStatement_initializer() async {
    // SimpleIdentifier  ForStatement
    addTestSource('main() {List a; for (^)}');
    await assertOpType(typeNames: true, functionBody: true);
  }

  test_ForStatement_initializer_inKeyword() async {
    addTestSource('main() { for (var v i^) }');
    await assertOpType(functionBody: true);
  }

  test_ForStatement_initializer_type() async {
    // SimpleIdentifier  ForStatement
    addTestSource('main() {List a; for (i^ v = 0;)}');
    await assertOpType(typeNames: true, functionBody: true);
  }

  test_ForStatement_initializer_variableNameEmpty_afterType() async {
    addTestSource('main() { for (String ^) }');
    await assertOpType(varNames: true, functionBody: true);
  }

  test_FunctionDeclaration1() async {
    // SimpleIdentifier  FunctionDeclaration  CompilationUnit
    addTestSource('const ^Fara();');
    await assertOpType(typeNames: true);
  }

  test_FunctionDeclaration2() async {
    // SimpleIdentifier  FunctionDeclaration  CompilationUnit
    addTestSource('const F^ara();');
    await assertOpType(typeNames: true);
  }

  test_FunctionDeclaration_inLineComment() async {
    // Comment  CompilationUnit
    addTestSource('''
      // normal comment ^
      zoo(z) { } String name;''');
    await assertOpType();
  }

  test_FunctionDeclaration_inLineComment2() async {
    // Comment  CompilationUnit
    addTestSource('''
      // normal ^comment
      zoo(z) { } String name;''');
    await assertOpType();
  }

  test_FunctionDeclaration_inLineComment3() async {
    // Comment  CompilationUnit
    addTestSource('''
      // normal comment ^
      // normal comment 2
      zoo(z) { } String name;''');
    await assertOpType();
  }

  test_FunctionDeclaration_inLineComment4() async {
    // Comment  CompilationUnit
    addTestSource('''
      // normal comment
      // normal comment 2^
      zoo(z) { } String name;''');
    await assertOpType();
  }

  test_FunctionDeclaration_inLineDocComment() async {
    // Comment  FunctionDeclaration  CompilationUnit
    addTestSource('''
      /// some dartdoc ^
      zoo(z) { } String name;''');
    await assertOpType();
  }

  test_FunctionDeclaration_inLineDocComment2() async {
    // Comment  FunctionDeclaration  CompilationUnit
    addTestSource('''
      /// some ^dartdoc
      zoo(z) { } String name;''');
    await assertOpType();
  }

  test_FunctionDeclaration_inStarComment() async {
    // Comment  CompilationUnit
    addTestSource('/* ^ */ zoo(z) {} String name;');
    await assertOpType();
  }

  test_FunctionDeclaration_inStarComment2() async {
    // Comment  CompilationUnit
    addTestSource('/*  *^/ zoo(z) {} String name;');
    await assertOpType();
  }

  test_FunctionDeclaration_inStarDocComment() async {
    // Comment  FunctionDeclaration  CompilationUnit
    addTestSource('/** ^ */ zoo(z) { } String name; ');
    await assertOpType();
  }

  test_FunctionDeclaration_inStarDocComment2() async {
    // Comment  FunctionDeclaration  CompilationUnit
    addTestSource('/**  *^/ zoo(z) { } String name;');
    await assertOpType();
  }

  test_FunctionDeclaration_returnType() async {
    // CompilationUnit
    addTestSource('^ zoo(z) { } String name;');
    await assertOpType(typeNames: true);
  }

  test_FunctionDeclaration_returnType_afterLineComment() async {
    // FunctionDeclaration  CompilationUnit
    addTestSource('''
      // normal comment
      ^ zoo(z) {} String name;''');
    await assertOpType(typeNames: true);
  }

  test_FunctionDeclaration_returnType_afterLineComment2() async {
    // FunctionDeclaration  CompilationUnit
    // TOD(danrubel) left align all test source
    addTestSource('''
// normal comment
^ zoo(z) {} String name;''');
    await assertOpType(typeNames: true);
  }

  test_FunctionDeclaration_returnType_afterLineDocComment() async {
    // SimpleIdentifier  FunctionDeclaration  CompilationUnit
    addTestSource('''
      /// some dartdoc
      ^ zoo(z) { } String name;''');
    await assertOpType(typeNames: true);
  }

  test_FunctionDeclaration_returnType_afterLineDocComment2() async {
    // SimpleIdentifier  FunctionDeclaration  CompilationUnit
    addTestSource('''
/// some dartdoc
^ zoo(z) { } String name;''');
    await assertOpType(typeNames: true);
  }

  test_FunctionDeclaration_returnType_afterStarComment() async {
    // CompilationUnit
    addTestSource('/* */ ^ zoo(z) { } String name;');
    await assertOpType(typeNames: true);
  }

  test_FunctionDeclaration_returnType_afterStarComment2() async {
    // CompilationUnit
    addTestSource('/* */^ zoo(z) { } String name;');
    await assertOpType(typeNames: true);
  }

  test_FunctionDeclaration_returnType_afterStarDocComment() async {
    // FunctionDeclaration  CompilationUnit
    addTestSource('/** */ ^ zoo(z) { } String name;');
    await assertOpType(typeNames: true);
  }

  test_FunctionDeclaration_returnType_afterStarDocComment2() async {
    // FunctionDeclaration  CompilationUnit
    addTestSource('/** */^ zoo(z) { } String name;');
    await assertOpType(typeNames: true);
  }

  test_FunctionExpression() async {
    // BlockFunctionBody  FunctionExpression  FunctionDeclaration
    addTestSource('main()^ { int b = 2; b++; b. }');
    await assertOpType();
  }

  test_FunctionExpressionInvocation() async {
    // ArgumentList  FunctionExpressionInvocation  ExpressionStatement
    addTestSource('main() { ((x) => x + 7)^(2) }');
    await assertOpType(functionBody: true);
  }

  test_FunctionTypeAlias() async {
    // SimpleIdentifier  FunctionTypeAlias  CompilationUnit
    addTestSource('typedef n^ ;');
    await assertOpType(typeNames: true);
  }

  test_ImplementsClause() async {
    // ImplementsClause  ClassDeclaration
    addTestSource('class x implements ^\n{}');
    await assertOpType(typeNames: true);
  }

  test_ImportDirective_dart() async {
    // SimpleStringLiteral  ImportDirective
    addTestSource('''
      import "dart^";
      main() {}''');
    await assertOpType();
  }

  test_InstanceCreationExpression() async {
    // SimpleIdentifier  TypeName  ConstructorName  InstanceCreationExpression
    addTestSource('class C {foo(){var f; {var x;} new ^}}');
    await assertOpType(constructors: true, methodBody: true);
  }

  test_InstanceCreationExpression_trailingStmt() async {
    // SimpleIdentifier  TypeName  ConstructorName  InstanceCreationExpression
    addTestSource('class C {foo(){var f; {var x;} new ^ int x = 7;}}');
    await assertOpType(constructors: true, methodBody: true);
  }

  test_IntegerLiteral_inArgumentList() async {
    // TODO expected functionBody: true
    addTestSource('main() { print(1^); }');
    await assertOpType(functionBody: false);
  }

  test_IntegerLiteral_inListLiteral() async {
    // TODO expected functionBody: true
    addTestSource('main() { var items = [1^]; }');
    await assertOpType(functionBody: false);
  }

  test_IsExpression() async {
    // SimpleIdentifier  TypeName  IsExpression  IfStatement
    addTestSource('main() {var x; if (x is ^) { }}');
    await assertOpType(typeNames: true, functionBody: true);
  }

  test_IsExpression_type_partial() async {
    // SimpleIdentifier  TypeName  IsExpression  IfStatement
    addTestSource('main(){var a; if (a is Obj^)}');
    await assertOpType(typeNames: true, functionBody: true);
  }

  test_Literal_string() async {
    // SimpleStringLiteral  ExpressionStatement  Block
    addTestSource('class A {a() {"hel^lo"}}');
    await assertOpType(methodBody: true);
  }

  test_MethodDeclaration_inClass1() async {
    // SimpleIdentifier  MethodDeclaration  ClassDeclaration
    addTestSource('class Bar {const ^Fara();}');
    await assertOpType(typeNames: true);
  }

  test_MethodDeclaration_inClass2() async {
    // SimpleIdentifier  MethodDeclaration  ClassDeclaration
    addTestSource('class Bar {const F^ara();}');
    await assertOpType(typeNames: true);
  }

  test_MethodDeclaration_inClass_inLineComment() async {
    // Comment  ClassDeclaration  CompilationUnit
    addTestSource('''
      class C2 {
        // normal comment ^
        zoo(z) { } String name; }''');
    await assertOpType();
  }

  test_MethodDeclaration_inClass_inLineComment2() async {
    // Comment  ClassDeclaration  CompilationUnit
    addTestSource('''
      class C2 {
        // normal ^comment
        zoo(z) { } String name; }''');
    await assertOpType();
  }

  test_MethodDeclaration_inClass_inLineComment3() async {
    // Comment  ClassDeclaration  CompilationUnit
    addTestSource('''
      class C2 {
        // normal comment ^
        // normal comment 2
        zoo(z) { } String name; }''');
    await assertOpType();
  }

  test_MethodDeclaration_inClass_inLineDocComment() async {
    // Comment  MethodDeclaration  ClassDeclaration  CompilationUnit
    addTestSource('''
      class C2 {
        /// some dartdoc ^
        zoo(z) { } String name; }''');
    await assertOpType();
  }

  test_MethodDeclaration_inClass_inLineDocComment2() async {
    // Comment  MethodDeclaration  ClassDeclaration  CompilationUnit
    addTestSource('''
      class C2 {
        /// some ^dartdoc
        zoo(z) { } String name; }''');
    await assertOpType();
  }

  test_MethodDeclaration_inClass_inStarComment() async {
    // Comment  ClassDeclaration  CompilationUnit
    addTestSource('class C2 {/* ^ */ zoo(z) {} String name;}');
    await assertOpType();
  }

  test_MethodDeclaration_inClass_inStarComment2() async {
    // Comment  ClassDeclaration  CompilationUnit
    addTestSource('class C2 {/*  *^/ zoo(z) {} String name;}');
    await assertOpType();
  }

  test_MethodDeclaration_inClass_inStarDocComment() async {
    // Comment  MethodDeclaration  ClassDeclaration  CompilationUnit
    addTestSource('class C2 {/** ^ */ zoo(z) { } String name; }');
    await assertOpType();
  }

  test_MethodDeclaration_inClass_inStarDocComment2() async {
    // Comment  MethodDeclaration  ClassDeclaration  CompilationUnit
    addTestSource('class C2 {/**  *^/ zoo(z) { } String name; }');
    await assertOpType();
  }

  test_MethodDeclaration_inClass_returnType() async {
    // ClassDeclaration  CompilationUnit
    addTestSource('class C2 {^ zoo(z) { } String name; }');
    await assertOpType(typeNames: true);
  }

  test_MethodDeclaration_inClass_returnType_afterLineComment() async {
    // MethodDeclaration  ClassDeclaration  CompilationUnit
    addTestSource('''
      class C2 {
        // normal comment
        ^ zoo(z) {} String name;}''');
    await assertOpType(typeNames: true);
  }

  test_MethodDeclaration_inClass_returnType_afterLineComment2() async {
    // MethodDeclaration  ClassDeclaration  CompilationUnit
    // TOD(danrubel) left align all test source
    addTestSource('''
class C2 {
  // normal comment
^ zoo(z) {} String name;}''');
    await assertOpType(typeNames: true);
  }

  test_MethodDeclaration_inClass_returnType_afterLineDocComment() async {
    // SimpleIdentifier  MethodDeclaration  ClassDeclaration  CompilationUnit
    addTestSource('''
      class C2 {
        /// some dartdoc
        ^ zoo(z) { } String name; }''');
    await assertOpType(typeNames: true);
  }

  test_MethodDeclaration_inClass_returnType_afterLineDocComment2() async {
    // SimpleIdentifier  MethodDeclaration  ClassDeclaration  CompilationUnit
    addTestSource('''
class C2 {
  /// some dartdoc
^ zoo(z) { } String name; }''');
    await assertOpType(typeNames: true);
  }

  test_MethodDeclaration_inClass_returnType_afterStarComment() async {
    // ClassDeclaration  CompilationUnit
    addTestSource('class C2 {/* */ ^ zoo(z) { } String name; }');
    await assertOpType(typeNames: true);
  }

  test_MethodDeclaration_inClass_returnType_afterStarComment2() async {
    // ClassDeclaration  CompilationUnit
    addTestSource('class C2 {/* */^ zoo(z) { } String name; }');
    await assertOpType(typeNames: true);
  }

  test_MethodDeclaration_inClass_returnType_afterStarDocComment() async {
    // MethodDeclaration  ClassDeclaration  CompilationUnit
    addTestSource('class C2 {/** */ ^ zoo(z) { } String name; }');
    await assertOpType(typeNames: true);
  }

  test_MethodDeclaration_inClass_returnType_afterStarDocComment2() async {
    // MethodDeclaration  ClassDeclaration  CompilationUnit
    addTestSource('class C2 {/** */^ zoo(z) { } String name; }');
    await assertOpType(typeNames: true);
  }

  test_methodDeclaration_inMixin1() async {
    // SimpleIdentifier  MethodDeclaration  MixinDeclaration
    addTestSource('mixin M {const ^Fara();}');
    await assertOpType(typeNames: true);
  }

  test_methodDeclaration_inMixin2() async {
    // SimpleIdentifier  MethodDeclaration  MixinDeclaration
    addTestSource('mixin M {const F^ara();}');
    await assertOpType(typeNames: true);
  }

  test_methodDeclaration_inMixin_returnType() async {
    // MixinDeclaration  CompilationUnit
    addTestSource('mixin M {^ zoo(z) { } String name; }');
    await assertOpType(typeNames: true);
  }

  test_mixinDeclaration_body() async {
    // MixinDeclaration  CompilationUnit
    addTestSource('mixin M {^}');
    await assertOpType(typeNames: true);
  }

  test_mixinDeclaration_body2() async {
    // SimpleIdentifier  MethodDeclaration  MixinDeclaration
    addTestSource('mixin M {^mth() {}}');
    await assertOpType(typeNames: true);
  }

  test_NamedExpression() async {
    addTestSource('''
main() { f(3, ^); }
void f(int a, {int b}) {}
''');
    await assertOpType(namedArgs: true, functionBody: true);
  }

  test_OnClause() async {
    // OnClause  MixinDeclaration
    addTestSource('mixin M on ^\n{}');
    await assertOpType(typeNames: true);
  }

  test_PropertyAccess_noTarget() async {
    // SimpleIdentifier  PropertyAccess  ExpressionStatement
    addTestSource('main() {.^}');
    await assertOpType(functionBody: true);
  }

  test_PropertyAccess_noTarget2() async {
    // SimpleIdentifier  PropertyAccess  CascadeExpressions
    addTestSource('main() {.^.}');
    await assertOpType(functionBody: true);
  }

  test_PropertyAccess_noTarget3() async {
    // SimpleIdentifier  PropertyAccess  CascadeExpressions
    addTestSource('main() {..^}');
    await assertOpType(functionBody: true);
  }

  test_SimpleFormalParameter_closure() async {
    // SimpleIdentifier  SimpleFormalParameter  FormalParameterList
    addTestSource('mth() { PNGS.sort((String a, Str^) => a.compareTo(b)); }');
    await assertOpType(typeNames: true, functionBody: true);
  }

  test_SimpleFormalParameter_name_typed() async {
    addTestSource('f(String ^, int b) {}');
    await assertOpType(typeNames: false, varNames: true);
  }

  test_SimpleFormalParameter_name_typed_hasName() async {
    addTestSource('f(String n^, int b) {}');
    await assertOpType(typeNames: false, varNames: true);
  }

  test_SimpleFormalParameter_name_typed_last() async {
    addTestSource('f(String ^) {}');
    await assertOpType(typeNames: false, varNames: true);
  }

  test_SimpleFormalParameter_name_typed_last_hasName() async {
    addTestSource('f(String n^) {}');
    await assertOpType(typeNames: false, varNames: true);
  }

  test_SimpleFormalParameter_type_named() async {
    addTestSource('f(^ name) {}');
    await assertOpType(typeNames: true, varNames: false);
  }

  test_SimpleFormalParameter_type_optionalNamed() async {
    // SimpleIdentifier  DefaultFormalParameter  FormalParameterList
    addTestSource('m({Str^}) {}');
    await assertOpType(typeNames: true);
  }

  test_SimpleFormalParameter_type_optionalPositional() async {
    // SimpleIdentifier  DefaultFormalParameter  FormalParameterList
    addTestSource('m([Str^]) {}');
    await assertOpType(typeNames: true);
  }

  test_SimpleFormalParameter_type_withName() async {
    // SimpleIdentifier  SimpleFormalParameter  FormalParameterList
    addTestSource('m(Str^ name) {}');
    await assertOpType(typeNames: true);
  }

  test_SimpleFormalParameter_type_withoutName1() async {
    // SimpleIdentifier  SimpleFormalParameter  FormalParameterList
    addTestSource('m(Str^) {}');
    await assertOpType(typeNames: true);
  }

  test_SimpleFormalParameter_type_withoutName2() async {
    // FormalParameterList
    addTestSource('m(^) {}');
    await assertOpType(typeNames: true);
  }

  test_SimpleFormalParameter_type_withoutName3() async {
    // SimpleIdentifier  SimpleFormalParameter  FormalParameterList
    addTestSource('m(int first, Str^) {}');
    await assertOpType(typeNames: true);
  }

  test_SimpleFormalParameter_untyped() async {
    addTestSource('main(final ^) {}');
    await assertOpType(typeNames: true, varNames: false);
  }

  test_SwitchCase_before() async {
    // SwitchCase  SwitchStatement  Block
    addTestSource('main() {switch(k) {^case 1:}}');
    await assertOpType(functionBody: true);
  }

  test_SwitchDefault_before() async {
    // SwitchDefault  SwitchStatement  Block
    addTestSource('main() {switch(k) { ^ default: return;}}');
    await assertOpType(functionBody: true);
  }

  test_SwitchStatement_body_empty() async {
    // Token('}')  SwitchStatement  Block
    addTestSource('main() {switch(k) {^}}');
    await assertOpType(functionBody: true);
  }

  test_ThisExpression_constructor_param() async {
    // SimpleIdentifier  FieldFormalParameter  FormalParameterList
    addTestSource('''
      class A implements I {
        A(this.^) {}
      }''');
    await assertOpType(prefixed: true);
  }

  test_ThisExpression_constructor_param2() async {
    // SimpleIdentifier  FieldFormalParameter  FormalParameterList
    addTestSource('''
      class A implements I {
        A(this.f^) {}
      }''');
    await assertOpType(prefixed: true);
  }

  test_ThisExpression_constructor_param3() async {
    // SimpleIdentifier  FieldFormalParameter  FormalParameterList
    addTestSource('''
      class A implements I {
        A(this.^f) {}
      }''');
    await assertOpType(prefixed: true);
  }

  test_ThisExpression_constructor_param4() async {
    // FieldFormalParameter  FormalParameterList  ConstructorDeclaration
    addTestSource('''
      class A implements I {
        A(Str^ this.foo) {}
      }''');
    await assertOpType(typeNames: true);
  }

  test_TopLevelVariableDeclaration_typed_name() async {
    // SimpleIdentifier  VariableDeclaration  VariableDeclarationList
    // TopLevelVariableDeclaration
    // _OpTypeAstVisitor.visitVariableDeclarationList is executed with this
    // source, but _OpTypeAstVisitor.visitTopLevelVariableDeclaration is called
    // for test_TopLevelVariableDeclaration_typed_name_semicolon
    addTestSource('class A {} B ^');
    await assertOpType(varNames: true);
  }

  test_TopLevelVariableDeclaration_typed_name_semicolon() async {
    // SimpleIdentifier  VariableDeclaration  VariableDeclarationList
    // TopLevelVariableDeclaration
    // See comment in test_TopLevelVariableDeclaration_typed_name
    addTestSource('class A {} B ^;');
    await assertOpType(varNames: true);
  }

  test_TopLevelVariableDeclaration_untyped_name() async {
    // SimpleIdentifier  VariableDeclaration  VariableDeclarationList
    // TopLevelVariableDeclaration
    addTestSource('class A {} var ^');
    await assertOpType();
  }

  test_TypeArgumentList() async {
    // SimpleIdentifier  BinaryExpression  ExpressionStatement
    addTestSource('main() { C<^> c; }');
    await assertOpType(typeNames: true, functionBody: true);
  }

  test_TypeArgumentList2() async {
    // TypeName  TypeArgumentList  TypeName
    addTestSource('main() { C<C^> c; }');
    await assertOpType(typeNames: true, functionBody: true);
  }

  test_TypeParameter() async {
    // SimpleIdentifier  TypeParameter  TypeParameterList
    addTestSource('class tezetst <String, ^List> {}');
    await assertOpType();
  }

  test_TypeParameterList_empty() async {
    // SimpleIdentifier  TypeParameter  TypeParameterList
    addTestSource('class tezetst <^> {}');
    await assertOpType();
  }

  test_VariableDeclaration_name() async {
    // SimpleIdentifier  VariableDeclaration  VariableDeclarationList
    // VariableDeclarationStatement  Block
    addTestSource('main() {var ^}');
    await assertOpType(functionBody: true);
  }

  test_VariableDeclaration_name_hasSome_parameterizedType() async {
    // SimpleIdentifier  VariableDeclaration  VariableDeclarationList
    // VariableDeclarationStatement  Block
    addTestSource('main() {List<int> m^}');
    await assertOpType(varNames: true, functionBody: true);
  }

  test_VariableDeclaration_name_hasSome_simpleType() async {
    // SimpleIdentifier  VariableDeclaration  VariableDeclarationList
    // VariableDeclarationStatement  Block
    addTestSource('main() {String m^}');
    await assertOpType(varNames: true, functionBody: true);
  }

  test_VariableDeclarationList_final() async {
    // VariableDeclarationList  VariableDeclarationStatement  Block
    addTestSource('main() {final ^}');
    await assertOpType(typeNames: true, functionBody: true);
  }
}

/// Common test methods to Dart1/Dart2 versions of OpType tests.
class OpTypeTestCommon extends AbstractContextTest {
  String testPath;
  int completionOffset;
  OpType visitor;

  void addTestSource(String content) {
    completionOffset = content.indexOf('^');
    expect(completionOffset, isNot(equals(-1)), reason: 'missing ^');
    int nextOffset = content.indexOf('^', completionOffset + 1);
    expect(nextOffset, equals(-1), reason: 'too many ^');
    content = content.substring(0, completionOffset) +
        content.substring(completionOffset + 1);
    super.addSource(testPath, content);
  }

  Future<void> assertOpType(
      {bool caseLabel: false,
      bool constructors: false,
      bool namedArgs: false,
      bool prefixed: false,
      bool returnValue: false,
      bool statementLabel: false,
      bool staticMethodBody: false,
      bool methodBody: false,
      bool functionBody: false,
      bool constructorBody: false,
      bool typeNames: false,
      bool varNames: false,
      bool voidReturn: false,
      CompletionSuggestionKind kind:
          CompletionSuggestionKind.INVOCATION}) async {
    ResolvedUnitResult resolvedUnit = await driver.getResult(testPath);

    CompletionTarget completionTarget =
        new CompletionTarget.forOffset(resolvedUnit.unit, completionOffset);
    visitor = new OpType.forCompletion(completionTarget, completionOffset);

    expect(visitor.includeCaseLabelSuggestions, caseLabel, reason: 'caseLabel');
    expect(visitor.includeConstructorSuggestions, constructors,
        reason: 'constructors');
    expect(visitor.includeNamedArgumentSuggestions, namedArgs,
        reason: 'namedArgs');
    expect(visitor.includeReturnValueSuggestions, returnValue,
        reason: 'returnValue');
    expect(visitor.includeStatementLabelSuggestions, statementLabel,
        reason: 'statementLabel');
    expect(visitor.includeTypeNameSuggestions, typeNames, reason: 'typeNames');
    expect(visitor.includeVarNameSuggestions, varNames, reason: 'varNames');
    expect(visitor.includeVoidReturnSuggestions, voidReturn,
        reason: 'voidReturn');
    expect(visitor.inStaticMethodBody, staticMethodBody,
        reason: 'staticMethodBody');
    expect(visitor.inMethodBody, methodBody, reason: 'methodBody');
    expect(visitor.inFunctionBody, functionBody, reason: 'functionBody');
    expect(visitor.inConstructorBody, constructorBody,
        reason: 'constructorBody');
    expect(visitor.isPrefixed, prefixed, reason: 'prefixed');
    expect(visitor.suggestKind, kind, reason: 'suggestion kind');
  }

  @override
  void setUp() {
    super.setUp();
    testPath = convertPath('/completionTest.dart');
  }
}

@reflectiveTest
class OpTypeTestWithExtensionMethods extends OpTypeTestCommon {
  @override
  void setUp() {
    createAnalysisOptionsFile(
      experiments: [
        EnableString.extension_methods,
      ],
    );
    super.setUp();
  }

  test_extensionDeclaration_body() async {
    // ExtensionDeclaration  CompilationUnit
    addTestSource('extension E on int {^}');
    await assertOpType(typeNames: true);
  }

  test_extensionDeclaration_body2() async {
    // SimpleIdentifier  MethodDeclaration  ExtensionDeclaration
    addTestSource('extension E on int {^mth() {}}');
    await assertOpType(typeNames: true);
  }

  test_methodDeclaration_inExtension1() async {
    // SimpleIdentifier  ExtensionDeclaration  MixinDeclaration
    addTestSource('extension E on int {const ^Fara();}');
    await assertOpType(typeNames: true);
  }

  test_methodDeclaration_inExtension2() async {
    // SimpleIdentifier  ExtensionDeclaration  MixinDeclaration
    addTestSource('extension E on int {const F^ara();}');
    await assertOpType(typeNames: true);
  }

  test_methodDeclaration_inExtension_returnType() async {
    // ExtensionDeclaration  CompilationUnit
    addTestSource('extension E on int {^ zoo(z) { } String name; }');
    await assertOpType(typeNames: true);
  }
}
