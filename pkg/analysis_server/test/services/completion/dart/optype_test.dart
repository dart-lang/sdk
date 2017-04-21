// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.services.completion.contributor.dart.optype;

import 'package:analysis_server/src/protocol_server.dart';
import 'package:analysis_server/src/provisional/completion/dart/completion_target.dart';
import 'package:analysis_server/src/services/completion/dart/optype.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:plugin/manager.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../mock_sdk.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(OpTypeTest);
  });
}

@reflectiveTest
class OpTypeTest {
  OpType visitor;

  void addTestSource(String content, {bool resolved: false}) {
    MemoryResourceProvider resourceProvider = new MemoryResourceProvider();
    DartSdk sdk = new MockSdk(resourceProvider: resourceProvider);

    int offset = content.indexOf('^');
    expect(offset, isNot(equals(-1)), reason: 'missing ^');
    int nextOffset = content.indexOf('^', offset + 1);
    expect(nextOffset, equals(-1), reason: 'too many ^');
    content = content.substring(0, offset) + content.substring(offset + 1);
    Source source = new _TestSource('/completionTest.dart');
    AnalysisContext context = AnalysisEngine.instance.createAnalysisContext();
    context.sourceFactory = new SourceFactory([new DartUriResolver(sdk)]);
    context.setContents(source, content);
    CompilationUnit unit = resolved
        ? context.resolveCompilationUnit2(source, source)
        : context.parseCompilationUnit(source);
    CompletionTarget completionTarget =
        new CompletionTarget.forOffset(unit, offset);
    visitor = new OpType.forCompletion(completionTarget, offset);
  }

  void assertOpType(
      {bool caseLabel: false,
      bool constructors: false,
      bool namedArgs: false,
      bool prefixed: false,
      bool returnValue: false,
      bool statementLabel: false,
      bool staticMethodBody: false,
      bool typeNames: false,
      bool varNames: false,
      bool voidReturn: false,
      CompletionSuggestionKind kind: CompletionSuggestionKind.INVOCATION}) {
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
    expect(visitor.isPrefixed, prefixed, reason: 'prefixed');
    expect(visitor.suggestKind, kind, reason: 'suggestion kind');
  }

  void processRequiredPlugins() {
    ExtensionManager manager = new ExtensionManager();
    manager.processPlugins(AnalysisEngine.instance.requiredPlugins);
  }

  void setUp() {
    processRequiredPlugins();
  }

  test_Annotation() {
    // SimpleIdentifier  Annotation  MethodDeclaration  ClassDeclaration
    addTestSource('class C { @A^ }');
    assertOpType(returnValue: true, typeNames: true);
  }

  test_ArgumentList() {
    // ArgumentList  MethodInvocation  ExpressionStatement  Block
    addTestSource('void main() {expect(^)}', resolved: false);
    // If "expect()" were resolved, then either namedArgs would be true
    // or returnValue and typeNames would be true.
    assertOpType(namedArgs: true, returnValue: true, typeNames: true);
  }

  test_ArgumentList_constructor_named_resolved_1_0() {
    // ArgumentList  InstanceCreationExpression  ExpressionStatement Block
    addTestSource(
        'main() { new A.b(^); }'
        'class A{ A.b({one, two}) {} }',
        resolved: true);
    assertOpType(namedArgs: true);
  }

  test_ArgumentList_constructor_named_resolved_1_1() {
    // ArgumentList  InstanceCreationExpression  ExpressionStatement  Block
    addTestSource(
        'main() { new A.b(o^); }'
        'class A { A.b({one, two}) {} }',
        resolved: true);
    assertOpType(namedArgs: true);
  }

  test_ArgumentList_constructor_resolved_1_0() {
    // ArgumentList  InstanceCreationExpression  ExpressionStatement Block
    addTestSource(
        'main() { new A(^); }'
        'class A{ A({one, two}) {} }',
        resolved: true);
    assertOpType(namedArgs: true);
  }

  test_ArgumentList_constructor_resolved_1_1() {
    // ArgumentList  InstanceCreationExpression  ExpressionStatement  Block
    addTestSource(
        'main() { new A(o^); }'
        'class A { A({one, two}) {} }',
        resolved: true);
    assertOpType(namedArgs: true);
  }

  test_ArgumentList_factory_named_resolved_1_0() {
    // ArgumentList  InstanceCreationExpression  ExpressionStatement Block
    addTestSource(
        'main() { new A.b(^); }'
        'class A{ factory A.b({one, two}) {} }',
        resolved: true);
    assertOpType(namedArgs: true);
  }

  test_ArgumentList_factory_named_resolved_1_1() {
    // ArgumentList  InstanceCreationExpression  ExpressionStatement  Block
    addTestSource(
        'main() { new A.b(o^); }'
        'class A { factory A.b({one, two}) {} }',
        resolved: true);
    assertOpType(namedArgs: true);
  }

  test_ArgumentList_factory_resolved_1_0() {
    // ArgumentList  InstanceCreationExpression  ExpressionStatement Block
    addTestSource(
        'main() { new A(^); }'
        'class A{ factory A({one, two}) {} }',
        resolved: true);
    assertOpType(namedArgs: true);
  }

  test_ArgumentList_factory_resolved_1_1() {
    // ArgumentList  InstanceCreationExpression  ExpressionStatement  Block
    addTestSource(
        'main() { new A(o^); }'
        'class A { factory A({one, two}) {} }',
        resolved: true);
    assertOpType(namedArgs: true);
  }

  test_ArgumentList_method_resolved_1_0() {
    // ArgumentList  MethodInvocation  ExpressionStatement  Block
    addTestSource('main() { foo(^);} foo({one, two}) {}', resolved: true);
    assertOpType(namedArgs: true);
  }

  test_ArgumentList_method_resolved_1_1() {
    // ArgumentList  MethodInvocation  ExpressionStatement  Block
    addTestSource('main() { foo(o^);} foo({one, two}) {}', resolved: true);
    assertOpType(namedArgs: true);
  }

  test_ArgumentList_namedParam() {
    // SimpleIdentifier  NamedExpression  ArgumentList  MethodInvocation
    // ExpressionStatement
    addTestSource('void main() {expect(foo: ^)}');
    assertOpType(returnValue: true, typeNames: true);
  }

  test_ArgumentList_prefixedIdentifier() {
    // SimpleIdentifier  PrefixedIdentifier  ArgumentList
    addTestSource('void main() {expect(aa.^)}');
    assertOpType(returnValue: true, typeNames: true, prefixed: true);
  }

  test_ArgumentList_resolved() {
    // ArgumentList  MethodInvocation  ExpressionStatement  Block
    addTestSource('void main() {int.parse(^)}', resolved: true);
    assertOpType(returnValue: true, typeNames: true);
  }

  test_ArgumentList_resolved_2_0() {
    // ArgumentList  MethodInvocation  ExpressionStatement  Block
    addTestSource('void main() {int.parse("16", ^)}', resolved: true);
    assertOpType(namedArgs: true);
  }

  test_AsExpression() {
    // SimpleIdentifier  TypeName  AsExpression
    addTestSource('class A {var b; X _c; foo() {var a; (a as ^).foo();}');
    assertOpType(typeNames: true);
  }

  test_AsIdentifier() {
    addTestSource('class A {var asdf; foo() {as^}');
    assertOpType(returnValue: true, typeNames: true, voidReturn: true);
  }

  test_AsIdentifier2() {
    addTestSource('class A {var asdf; foo() {A as^}');
    assertOpType();
  }

  test_Assert() {
    addTestSource('main() {assert(^)}');
    assertOpType(returnValue: true, typeNames: true);
  }

  test_AssignmentExpression_name() {
    // SimpleIdentifier  VariableDeclaration  VariableDeclarationList
    // VariableDeclarationStatement  Block
    addTestSource('class A {} main() {int a; int ^b = 1;}');
    assertOpType(varNames: true);
  }

  test_AssignmentExpression_RHS() {
    // SimpleIdentifier  VariableDeclaration  VariableDeclarationList
    // VariableDeclarationStatement  Block
    addTestSource('class A {} main() {int a; int b = ^}');
    assertOpType(returnValue: true, typeNames: true);
  }

  test_AssignmentExpression_type() {
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
    assertOpType(returnValue: true, typeNames: true, voidReturn: true);
  }

  test_AssignmentExpression_type_newline() {
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
    assertOpType(returnValue: true, typeNames: true, voidReturn: true);
  }

  test_AssignmentExpression_type_partial() {
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
    assertOpType(returnValue: true, typeNames: true, voidReturn: true);
  }

  test_AssignmentExpression_type_partial_newline() {
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
    assertOpType(returnValue: true, typeNames: true, voidReturn: true);
  }

  test_AwaitExpression() {
    // SimpleIdentifier  AwaitExpression  ExpressionStatement
    addTestSource('main() async {A a; await ^}');
    assertOpType(returnValue: true, typeNames: true);
  }

  test_AwaitExpression2() {
    addTestSource('main() async {A a; await c^ await}');
    assertOpType(returnValue: true, typeNames: true);
  }

  test_AwaitExpression3() {
    addTestSource('main() async {A a; await ^ await foo;}');
    assertOpType(returnValue: true, typeNames: true);
  }

  test_AwaitExpression4() {
    addTestSource('main() async {A a; await ^ await bar();}');
    assertOpType(returnValue: true, typeNames: true);
  }

  test_AwaitExpression_assignment() {
    addTestSource('main() async {A a; int x = await ^}');
    assertOpType(returnValue: true, typeNames: true);
  }

  test_AwaitExpression_assignment2() {
    addTestSource('main() async {A a; int x = await ^ await foo;}');
    assertOpType(returnValue: true, typeNames: true);
  }

  test_AwaitExpression_assignment3() {
    addTestSource('main() async {A a; int x = await v^ int y = await foo;}');
    assertOpType(returnValue: true, typeNames: true);
  }

  test_BinaryExpression_LHS() {
    // SimpleIdentifier  BinaryExpression  VariableDeclaration
    // VariableDeclarationList  VariableDeclarationStatement
    addTestSource('main() {int a = 1, b = ^ + 2;}');
    assertOpType(returnValue: true, typeNames: true);
  }

  test_BinaryExpression_RHS() {
    // SimpleIdentifier  BinaryExpression  VariableDeclaration
    // VariableDeclarationList  VariableDeclarationStatement
    addTestSource('main() {int a = 1, b = 2 + ^;}');
    assertOpType(returnValue: true, typeNames: true);
  }

  test_BinaryExpression_RHS2() {
    // SimpleIdentifier  BinaryExpression
    addTestSource('main() {if (c < ^)}');
    assertOpType(returnValue: true, typeNames: true);
  }

  test_Block() {
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
    assertOpType(returnValue: true, typeNames: true, voidReturn: true);
  }

  test_Block_catch_1a() async {
    // '}'  Block  BlockFunctionBody  FunctionExpression
    addTestSource('main() {try {} ^}');
    // Only return 'on', 'catch', and 'finally' keywords
    assertOpType();
  }

  test_Block_catch_1b() async {
    // [ExpressionStatement 'c']  Block  BlockFunctionBody
    addTestSource('main() {try {} c^}');
    // Only return 'on', 'catch', and 'finally' keywords
    assertOpType();
  }

  test_Block_catch_1c() async {
    // [EmptyStatement]  Block  BlockFunctionBody  FunctionExpression
    addTestSource('main() {try {} ^;}');
    // Only return 'on', 'catch', and 'finally' keywords
    assertOpType();
  }

  test_Block_catch_1d() async {
    // [VariableDeclarationStatement 'Foo foo']  Block  BlockFunctionBody
    addTestSource('main() {try {} ^ Foo foo;}');
    // Only return 'on', 'catch', and 'finally' keywords
    assertOpType();
  }

  test_Block_catch_2a() async {
    // '}'  Block  BlockFunctionBody  FunctionExpression
    addTestSource('main() {try {} catch () {} ^}');
    assertOpType(returnValue: true, typeNames: true, voidReturn: true);
  }

  test_Block_catch_2b() async {
    // [ExpressionStatement 'c']  Block  BlockFunctionBody
    addTestSource('main() {try {} catch () {} c^}');
    assertOpType(returnValue: true, typeNames: true, voidReturn: true);
  }

  test_Block_catch_2c() async {
    // [EmptyStatement]  Block  BlockFunctionBody  FunctionExpression
    addTestSource('main() {try {} catch () {} ^;}');
    assertOpType(returnValue: true, typeNames: true, voidReturn: true);
  }

  test_Block_catch_2d() async {
    // [VariableDeclarationStatement 'Foo foo']  Block  BlockFunctionBody
    addTestSource('main() {try {} catch () {} ^ Foo foo;}');
    assertOpType(returnValue: true, typeNames: true, voidReturn: true);
  }

  test_Block_catch_3a() async {
    // '}'  Block  BlockFunctionBody  FunctionExpression
    addTestSource('main() {try {} finally {} ^}');
    assertOpType(returnValue: true, typeNames: true, voidReturn: true);
  }

  test_Block_catch_3b() async {
    // [ExpressionStatement 'c']  Block  BlockFunctionBody
    addTestSource('main() {try {} finally {} c^}');
    assertOpType(returnValue: true, typeNames: true, voidReturn: true);
  }

  test_Block_catch_3c() async {
    // [EmptyStatement]  Block  BlockFunctionBody  FunctionExpression
    addTestSource('main() {try {} finally {} ^;}');
    assertOpType(returnValue: true, typeNames: true, voidReturn: true);
  }

  test_Block_catch_3d() async {
    // [VariableDeclarationStatement 'Foo foo']  Block  BlockFunctionBody
    addTestSource('main() {try {} finally {} ^ Foo foo;}');
    assertOpType(returnValue: true, typeNames: true, voidReturn: true);
  }

  test_catch_4a1() async {
    addTestSource('main() {try {} ^ on SomeException {}}');
    assertOpType();
  }

  test_catch_4a2() async {
    addTestSource('main() {try {} c^ on SomeException {}}');
    assertOpType();
  }

  test_catch_4b1() async {
    addTestSource('main() {try {} ^ catch (e) {}}');
    assertOpType();
  }

  test_catch_4b2() async {
    addTestSource('main() {try {} c^ catch (e) {}}');
    assertOpType();
  }

  test_catch_4c1() async {
    addTestSource('main() {try {} ^ finally {}}');
    assertOpType();
  }

  test_catch_4c2() async {
    addTestSource('main() {try {} c^ finally {}}');
    assertOpType();
  }

  test_catch_5a() async {
    addTestSource('main() {try {} on ^ finally {}}');
    assertOpType(typeNames: true);
  }

  test_catch_5b() async {
    addTestSource('main() {try {} on E^ finally {}}');
    assertOpType(typeNames: true);
  }

  test_Block_empty() {
    // Block  BlockFunctionBody  MethodDeclaration  ClassDeclaration
    addTestSource('class A extends E implements I with M {a() {^}}');
    assertOpType(returnValue: true, typeNames: true, voidReturn: true);
  }

  test_Block_final() {
    addTestSource('main() {final ^}');
    assertOpType(typeNames: true);
  }

  test_Block_final2() {
    addTestSource('main() {final S^ v;}');
    assertOpType(typeNames: true);
  }

  test_Block_final3() {
    addTestSource('main() {final ^ v;}');
    assertOpType(typeNames: true);
  }

  test_Block_final_final() {
    addTestSource('main() {final ^ final S x;}');
    assertOpType(typeNames: true);
  }

  test_Block_final_final2() {
    addTestSource('main() {final S^ final S x;}');
    assertOpType(typeNames: true);
  }

  test_Block_identifier_partial() {
    addTestSource('class X {a() {var f; {var x;} D^ var r;} void b() { }}');
    assertOpType(returnValue: true, typeNames: true, voidReturn: true);
  }

  test_Block_keyword() {
    addTestSource('class C { static C get instance => null; } main() {C.in^}');
    assertOpType(
        prefixed: true, returnValue: true, typeNames: true, voidReturn: true);
  }

  test_Block_static() {
    addTestSource('class A {static foo() {^}}');
    assertOpType(
        returnValue: true,
        typeNames: true,
        staticMethodBody: true,
        voidReturn: true);
  }

  test_Break_after_label() {
    addTestSource('main() { foo: while (true) { break foo ^ ; } }');
    assertOpType(/* No valid completions */);
  }

  test_Break_before_label() {
    addTestSource('main() { foo: while (true) { break ^ foo; } }');
    assertOpType(statementLabel: true);
  }

  test_Break_no_label() {
    addTestSource('main() { foo: while (true) { break ^; } }');
    assertOpType(statementLabel: true);
  }

  test_CascadeExpression_selector1() {
    // PropertyAccess  CascadeExpression  ExpressionStatement  Block
    addTestSource('''
      // looks like a cascade to the parser
      // but the user is trying to get completions for a non-cascade
      main() {A a; a.^.z}''');
    assertOpType(
        returnValue: true, typeNames: true, voidReturn: true, prefixed: true);
  }

  test_CascadeExpression_selector2() {
    // SimpleIdentifier  PropertyAccess  CascadeExpression  ExpressionStatement
    addTestSource('main() {A a; a..^z}');
    assertOpType(returnValue: true, voidReturn: true, prefixed: true);
  }

  test_CascadeExpression_selector2_withTrailingReturn() {
    // PropertyAccess  CascadeExpression  ExpressionStatement  Block
    addTestSource('main() {A a; a..^ return}');
    assertOpType(returnValue: true, voidReturn: true, prefixed: true);
  }

  test_CascadeExpression_target() {
    // SimpleIdentifier  CascadeExpression  ExpressionStatement
    addTestSource('main() {A a; a^..b}');
    assertOpType(returnValue: true, typeNames: true, voidReturn: true);
  }

  test_CatchClause_onType() {
    // TypeName  CatchClause  TryStatement
    addTestSource('class A {a() {try{var x;} on ^ {}}}');
    assertOpType(typeNames: true);
  }

  test_CatchClause_onType_noBrackets() {
    // TypeName  CatchClause  TryStatement
    addTestSource('class A {a() {try{var x;} on ^}}');
    assertOpType(typeNames: true);
  }

  test_CatchClause_typed() {
    // Block  CatchClause  TryStatement
    addTestSource('class A {a() {try{var x;} on E catch (e) {^}}}');
    assertOpType(returnValue: true, typeNames: true, voidReturn: true);
  }

  test_CatchClause_untyped() {
    // Block  CatchClause  TryStatement
    addTestSource('class A {a() {try{var x;} catch (e, s) {^}}}');
    assertOpType(returnValue: true, typeNames: true, voidReturn: true);
  }

  test_ClassDeclaration_body() {
    // ClassDeclaration  CompilationUnit
    addTestSource('@deprecated class A {^}');
    assertOpType(typeNames: true);
  }

  test_ClassDeclaration_body2() {
    // SimpleIdentifier  MethodDeclaration  ClassDeclaration
    addTestSource('@deprecated class A {^mth() {}}');
    assertOpType(typeNames: true);
  }

  test_Combinator_hide() {
    // SimpleIdentifier  HideCombinator  ImportDirective
    addTestSource('''
      import "/testAB.dart" hide ^;
      class X {}''');
    assertOpType();
  }

  test_Combinator_show() {
    // SimpleIdentifier  HideCombinator  ImportDirective
    addTestSource('''
      import "/testAB.dart" show ^;
      import "/testCD.dart";
      class X {}''');
    assertOpType();
  }

  test_CommentReference() {
    // SimpleIdentifier  CommentReference  Comment  MethodDeclaration
    addTestSource('class A {/** [^] */ mth() {}');
    assertOpType(
        returnValue: true,
        typeNames: true,
        voidReturn: true,
        kind: CompletionSuggestionKind.IDENTIFIER);
  }

  test_ConditionalExpression_elseExpression() {
    // SimpleIdentifier  ConditionalExpression  ReturnStatement
    addTestSource('class C {foo(){var f; {var x;} return a ? T1 : T^}}');
    assertOpType(returnValue: true, typeNames: true);
  }

  test_ConditionalExpression_elseExpression_empty() {
    // SimpleIdentifier  ConditionalExpression  ReturnStatement
    addTestSource('class C {foo(){var f; {var x;} return a ? T1 : ^}}');
    assertOpType(returnValue: true, typeNames: true);
  }

  test_ConditionalExpression_partial_thenExpression() {
    // SimpleIdentifier  ConditionalExpression  ReturnStatement
    addTestSource('class C {foo(){var f; {var x;} return a ? T^}}');
    assertOpType(returnValue: true, typeNames: true);
  }

  test_ConditionalExpression_partial_thenExpression_empty() {
    // SimpleIdentifier  ConditionalExpression  ReturnStatement
    addTestSource('class C {foo(){var f; {var x;} return a ? ^}}');
    assertOpType(returnValue: true, typeNames: true);
  }

  test_ConditionalExpression_thenExpression() {
    // SimpleIdentifier  ConditionalExpression  ReturnStatement
    addTestSource('class C {foo(){var f; {var x;} return a ? T^ : c}}');
    assertOpType(returnValue: true, typeNames: true);
  }

  test_ConstructorName() {
    // SimpleIdentifier  PrefixedIdentifier  TypeName  ConstructorName
    // InstanceCreationExpression
    addTestSource('main() {new X.^}');
    assertOpType(constructors: true, prefixed: true);
  }

  test_ConstructorName_name_resolved() {
    // SimpleIdentifier  PrefixedIdentifier  TypeName  ConstructorName
    // InstanceCreationExpression
    addTestSource('main() {new Str^ing.fromCharCodes([]);}', resolved: true);
    assertOpType(constructors: true);
  }

  test_ConstructorName_resolved() {
    // SimpleIdentifier  PrefixedIdentifier  TypeName  ConstructorName
    // InstanceCreationExpression
    addTestSource('main() {new String.fr^omCharCodes([]);}', resolved: true);
    assertOpType(constructors: true, prefixed: true);
  }

  test_ConstructorName_unresolved() {
    // SimpleIdentifier  PrefixedIdentifier  TypeName  ConstructorName
    // InstanceCreationExpression
    addTestSource('main() {new String.fr^omCharCodes([]);}');
    assertOpType(constructors: true, prefixed: true);
  }

  test_Continue_after_label() {
    addTestSource('main() { foo: while (true) { continue foo ^ ; } }');
    assertOpType(/* No valid completions */);
  }

  test_Continue_before_label() {
    addTestSource('main() { foo: while (true) { continue ^ foo; } }');
    assertOpType(statementLabel: true, caseLabel: true);
  }

  test_Continue_no_label() {
    addTestSource('main() { foo: while (true) { continue ^; } }');
    assertOpType(statementLabel: true, caseLabel: true);
  }

  test_DefaultFormalParameter_named_expression() {
    // DefaultFormalParameter FormalParameterList MethodDeclaration
    addTestSource('class A {a(blat: ^) { }}');
    assertOpType(returnValue: true, typeNames: true);
  }

  test_DoStatement() {
    // SimpleIdentifier  DoStatement  Block
    addTestSource('main() {do{} while(^x);}');
    assertOpType(returnValue: true, typeNames: true);
  }

  test_ExpressionFunctionBody() {
    // SimpleIdentifier  ExpressionFunctionBody  FunctionExpression
    addTestSource('m(){[1].forEach((x)=>^x);}');
    assertOpType(returnValue: true, typeNames: true);
  }

  test_ExpressionStatement() {
    // ExpressionStatement  Block  BlockFunctionBody
    addTestSource('n(){f(3);^}');
    assertOpType(returnValue: true, typeNames: true, voidReturn: true);
  }

  test_ExpressionStatement_name() {
    // ExpressionStatement  Block  BlockFunctionBody  MethodDeclaration
    addTestSource('class C {a() {C ^}}');
    assertOpType(varNames: true);
  }

  test_ExpressionStatement_name_semicolon() {
    // ExpressionStatement  Block  BlockFunctionBody  MethodDeclaration
    addTestSource('class C {a() {C ^;}}');
    assertOpType(varNames: true);
  }

  test_ExpressionStatement_prefixed_name() {
    // ExpressionStatement  Block  BlockFunctionBody  MethodDeclaration
    addTestSource('class C {a() {x.Y ^}}');
    assertOpType(varNames: true);
  }

  test_ExpressionStatement_prefixed_name_semicolon() {
    // ExpressionStatement  Block  BlockFunctionBody  MethodDeclaration
    addTestSource('class C {a() {x.Y ^;}}');
    assertOpType(varNames: true);
  }

  test_ExtendsClause() {
    // ExtendsClause  ClassDeclaration
    addTestSource('class x extends ^\n{}');
    assertOpType(typeNames: true);
  }

  test_FieldDeclaration_name_typed() {
    // SimpleIdentifier  VariableDeclaration  VariableDeclarationList
    // FieldDeclaration
    addTestSource('class C {A ^}');
    assertOpType(varNames: true);
  }

  test_FieldDeclaration_name_var() {
    // SimpleIdentifier  VariableDeclaration  VariableDeclarationList
    // FieldDeclaration
    addTestSource('class C {var ^}');
    assertOpType();
  }

  test_ForEachStatement() {
    // SimpleIdentifier  ForEachStatement  Block
    addTestSource('main() {for(z in ^zs) {}}');
    assertOpType(returnValue: true, typeNames: true);
  }

  test_ForEachStatement_body_typed() {
    // Block  ForEachStatement
    addTestSource('main(args) {for (int foo in bar) {^}}');
    assertOpType(returnValue: true, typeNames: true, voidReturn: true);
  }

  test_ForEachStatement_body_untyped() {
    // Block  ForEachStatement
    addTestSource('main(args) {for (foo in bar) {^}}');
    assertOpType(returnValue: true, typeNames: true, voidReturn: true);
  }

  test_ForEachStatement_iterable() {
    // SimpleIdentifier  ForEachStatement  Block
    addTestSource('main(args) {for (int foo in ^) {}}');
    assertOpType(returnValue: true, typeNames: true);
  }

  test_ForEachStatement_loopVariable() {
    // SimpleIdentifier  ForEachStatement  Block
    addTestSource('main(args) {for (^ in args) {}}');
    assertOpType(typeNames: true);
  }

  test_ForEachStatement_loopVariable_name() {
    // DeclaredIdentifier  ForEachStatement  Block
    addTestSource('main(args) {for (String ^ in args) {}}');
    assertOpType();
  }

  test_ForEachStatement_loopVariable_name2() {
    // DeclaredIdentifier  ForEachStatement  Block
    addTestSource('main(args) {for (String f^ in args) {}}');
    assertOpType();
  }

  test_ForEachStatement_loopVariable_type() {
    // SimpleIdentifier  ForEachStatement  Block
    addTestSource('main(args) {for (^ foo in args) {}}');
    assertOpType(typeNames: true);
  }

  test_ForEachStatement_loopVariable_type2() {
    // DeclaredIdentifier  ForEachStatement  Block
    addTestSource('main(args) {for (S^ foo in args) {}}');
    assertOpType(typeNames: true);
  }

  test_FormalParameter_partialType() {
    // FormalParameterList MethodDeclaration
    addTestSource('class A {a(b.^ f) { }}');
    assertOpType(returnValue: true, typeNames: true, prefixed: true);
  }

  test_FormalParameter_partialType2() {
    // FormalParameterList MethodDeclaration
    addTestSource('class A {a(b.z^ f) { }}');
    assertOpType(returnValue: true, typeNames: true, prefixed: true);
  }

  test_FormalParameter_partialType3() {
    // FormalParameterList MethodDeclaration
    addTestSource('class A {a(b.^) { }}');
    assertOpType(returnValue: true, typeNames: true, prefixed: true);
  }

  test_FormalParameterList() {
    // FormalParameterList MethodDeclaration
    addTestSource('class A {a(^) { }}');
    assertOpType(typeNames: true);
  }

  test_ForStatement_condition() {
    // SimpleIdentifier  ForStatement
    addTestSource('main() {for (int index = 0; i^)}');
    assertOpType(returnValue: true, typeNames: true);
  }

  test_ForStatement_initializer() {
    // SimpleIdentifier  ForStatement
    addTestSource('main() {List a; for (^)}');
    assertOpType(typeNames: true);
  }

  test_ForStatement_initializer_inKeyword() {
    addTestSource('main() { for (var v i^) }');
    assertOpType();
  }

  test_ForStatement_initializer_type() {
    // SimpleIdentifier  ForStatement
    addTestSource('main() {List a; for (i^ v = 0;)}');
    assertOpType(typeNames: true);
  }

  test_ForStatement_initializer_variableNameEmpty_afterType() {
    addTestSource('main() { for (String ^) }');
    assertOpType(varNames: true);
  }

  test_ForStatement_updaters() {
    // SimpleIdentifier  ForStatement
    addTestSource('main() {for (int index = 0; index < 10; i^)}');
    // TODO (danrubel) may want to exclude methods/functions with void return
    assertOpType(returnValue: true, typeNames: true, voidReturn: true);
  }

  test_ForStatement_updaters_prefix_expression() {
    // SimpleIdentifier  PrefixExpression  ForStatement
    addTestSource('main() {for (int index = 0; index < 10; ++i^)}');
    assertOpType(returnValue: true, typeNames: true);
  }

  test_FunctionDeclaration1() {
    // SimpleIdentifier  FunctionDeclaration  CompilationUnit
    addTestSource('const ^Fara();');
    assertOpType(typeNames: true);
  }

  test_FunctionDeclaration2() {
    // SimpleIdentifier  FunctionDeclaration  CompilationUnit
    addTestSource('const F^ara();');
    assertOpType(typeNames: true);
  }

  test_FunctionDeclaration_inLineComment() {
    // Comment  CompilationUnit
    addTestSource('''
      // normal comment ^
      zoo(z) { } String name;''');
    assertOpType();
  }

  test_FunctionDeclaration_inLineComment2() {
    // Comment  CompilationUnit
    addTestSource('''
      // normal ^comment
      zoo(z) { } String name;''');
    assertOpType();
  }

  test_FunctionDeclaration_inLineComment3() {
    // Comment  CompilationUnit
    addTestSource('''
      // normal comment ^
      // normal comment 2
      zoo(z) { } String name;''');
    assertOpType();
  }

  test_FunctionDeclaration_inLineComment4() {
    // Comment  CompilationUnit
    addTestSource('''
      // normal comment
      // normal comment 2^
      zoo(z) { } String name;''');
    assertOpType();
  }

  test_FunctionDeclaration_inLineDocComment() {
    // Comment  FunctionDeclaration  CompilationUnit
    addTestSource('''
      /// some dartdoc ^
      zoo(z) { } String name;''');
    assertOpType();
  }

  test_FunctionDeclaration_inLineDocComment2() {
    // Comment  FunctionDeclaration  CompilationUnit
    addTestSource('''
      /// some ^dartdoc
      zoo(z) { } String name;''');
    assertOpType();
  }

  test_FunctionDeclaration_inStarComment() {
    // Comment  CompilationUnit
    addTestSource('/* ^ */ zoo(z) {} String name;');
    assertOpType();
  }

  test_FunctionDeclaration_inStarComment2() {
    // Comment  CompilationUnit
    addTestSource('/*  *^/ zoo(z) {} String name;');
    assertOpType();
  }

  test_FunctionDeclaration_inStarDocComment() {
    // Comment  FunctionDeclaration  CompilationUnit
    addTestSource('/** ^ */ zoo(z) { } String name; ');
    assertOpType();
  }

  test_FunctionDeclaration_inStarDocComment2() {
    // Comment  FunctionDeclaration  CompilationUnit
    addTestSource('/**  *^/ zoo(z) { } String name;');
    assertOpType();
  }

  test_FunctionDeclaration_returnType() {
    // CompilationUnit
    addTestSource('^ zoo(z) { } String name;');
    assertOpType(typeNames: true);
  }

  test_FunctionDeclaration_returnType_afterLineComment() {
    // FunctionDeclaration  CompilationUnit
    addTestSource('''
      // normal comment
      ^ zoo(z) {} String name;''');
    assertOpType(typeNames: true);
  }

  test_FunctionDeclaration_returnType_afterLineComment2() {
    // FunctionDeclaration  CompilationUnit
    // TOD(danrubel) left align all test source
    addTestSource('''
// normal comment
^ zoo(z) {} String name;''');
    assertOpType(typeNames: true);
  }

  test_FunctionDeclaration_returnType_afterLineDocComment() {
    // SimpleIdentifier  FunctionDeclaration  CompilationUnit
    addTestSource('''
      /// some dartdoc
      ^ zoo(z) { } String name;''');
    assertOpType(typeNames: true);
  }

  test_FunctionDeclaration_returnType_afterLineDocComment2() {
    // SimpleIdentifier  FunctionDeclaration  CompilationUnit
    addTestSource('''
/// some dartdoc
^ zoo(z) { } String name;''');
    assertOpType(typeNames: true);
  }

  test_FunctionDeclaration_returnType_afterStarComment() {
    // CompilationUnit
    addTestSource('/* */ ^ zoo(z) { } String name;');
    assertOpType(typeNames: true);
  }

  test_FunctionDeclaration_returnType_afterStarComment2() {
    // CompilationUnit
    addTestSource('/* */^ zoo(z) { } String name;');
    assertOpType(typeNames: true);
  }

  test_FunctionDeclaration_returnType_afterStarDocComment() {
    // FunctionDeclaration  CompilationUnit
    addTestSource('/** */ ^ zoo(z) { } String name;');
    assertOpType(typeNames: true);
  }

  test_FunctionDeclaration_returnType_afterStarDocComment2() {
    // FunctionDeclaration  CompilationUnit
    addTestSource('/** */^ zoo(z) { } String name;');
    assertOpType(typeNames: true);
  }

  test_FunctionExpression() {
    // BlockFunctionBody  FunctionExpression  FunctionDeclaration
    addTestSource('main()^ { int b = 2; b++; b. }');
    assertOpType();
  }

  test_FunctionExpressionInvocation() {
    // ArgumentList  FunctionExpressionInvocation  ExpressionStatement
    addTestSource('main() { ((x) => x + 7)^(2) }');
    assertOpType();
  }

  test_FunctionTypeAlias() {
    // SimpleIdentifier  FunctionTypeAlias  CompilationUnit
    addTestSource('typedef n^ ;');
    assertOpType(typeNames: true);
  }

  test_IfStatement() {
    // EmptyStatement  IfStatement  Block  BlockFunctionBody
    addTestSource('main(){var a; if (true) ^}');
    assertOpType(returnValue: true, typeNames: true, voidReturn: true);
  }

  test_IfStatement_condition() {
    // SimpleIdentifier  IfStatement  Block  BlockFunctionBody
    addTestSource('main(){var a; if (^)}');
    assertOpType(returnValue: true, typeNames: true);
  }

  test_IfStatement_empty() {
    // SimpleIdentifier  PrefixIdentifier  IfStatement
    addTestSource('class A {foo() {A a; if (^) something}}');
    assertOpType(returnValue: true, typeNames: true);
  }

  test_IfStatement_invocation() {
    // SimpleIdentifier  PrefixIdentifier  IfStatement
    addTestSource('main() {var a; if (a.^) something}');
    assertOpType(returnValue: true, typeNames: true, prefixed: true);
  }

  test_ImplementsClause() {
    // ImplementsClause  ClassDeclaration
    addTestSource('class x implements ^\n{}');
    assertOpType(typeNames: true);
  }

  test_ImportDirective_dart() {
    // SimpleStringLiteral  ImportDirective
    addTestSource('''
      import "dart^";
      main() {}''');
    assertOpType();
  }

  test_IndexExpression() {
    addTestSource('class C {foo(){var f; {var x;} f[^]}}');
    assertOpType(returnValue: true, typeNames: true);
  }

  test_IndexExpression2() {
    addTestSource('class C {foo(){var f; {var x;} f[T^]}}');
    assertOpType(returnValue: true, typeNames: true);
  }

  test_InstanceCreationExpression() {
    // SimpleIdentifier  TypeName  ConstructorName  InstanceCreationExpression
    addTestSource('class C {foo(){var f; {var x;} new ^}}');
    assertOpType(constructors: true);
  }

  test_InstanceCreationExpression_keyword() {
    // InstanceCreationExpression  ExpressionStatement  Block
    addTestSource('class C {foo(){var f; {var x;} new^ }}');
    assertOpType(returnValue: true, typeNames: true, voidReturn: true);
  }

  test_InstanceCreationExpression_keyword2() {
    // InstanceCreationExpression  ExpressionStatement  Block
    addTestSource('class C {foo(){var f; {var x;} new^ C();}}');
    assertOpType(returnValue: true, typeNames: true, voidReturn: true);
  }

  test_InstanceCreationExpression_trailingStmt() {
    // SimpleIdentifier  TypeName  ConstructorName  InstanceCreationExpression
    addTestSource('class C {foo(){var f; {var x;} new ^ int x = 7;}}');
    assertOpType(constructors: true);
  }

  test_InterpolationExpression() {
    // SimpleIdentifier  InterpolationExpression  StringInterpolation
    addTestSource('main() {String name; print("hello \$^");}');
    assertOpType(returnValue: true);
  }

  test_InterpolationExpression_block() {
    // SimpleIdentifier  InterpolationExpression  StringInterpolation
    addTestSource('main() {String name; print("hello \${n^}");}');
    assertOpType(returnValue: true, typeNames: true);
  }

  test_InterpolationExpression_prefix_selector() {
    // SimpleIdentifier  PrefixedIdentifier  InterpolationExpression
    addTestSource('main() {String name; print("hello \${name.^}");}');
    assertOpType(returnValue: true, typeNames: true, prefixed: true);
  }

  test_InterpolationExpression_prefix_target() {
    // SimpleIdentifier  PrefixedIdentifier  InterpolationExpression
    addTestSource('main() {String name; print("hello \${nam^e.length}");}');
    assertOpType(returnValue: true, typeNames: true);
  }

  test_IsExpression() {
    // SimpleIdentifier  TypeName  IsExpression  IfStatement
    addTestSource('main() {var x; if (x is ^) { }}');
    assertOpType(typeNames: true);
  }

  test_IsExpression_target() {
    // IfStatement  Block  BlockFunctionBody
    addTestSource('main(){var a; if (^ is A)}');
    assertOpType(returnValue: true, typeNames: true);
  }

  test_IsExpression_type_partial() {
    // SimpleIdentifier  TypeName  IsExpression  IfStatement
    addTestSource('main(){var a; if (a is Obj^)}');
    assertOpType(typeNames: true);
  }

  test_Literal_list() {
    // ']'  ListLiteral  ArgumentList  MethodInvocation
    addTestSource('main() {var Some; print([^]);}');
    assertOpType(returnValue: true, typeNames: true);
  }

  test_Literal_list2() {
    // SimpleIdentifier ListLiteral  ArgumentList  MethodInvocation
    addTestSource('main() {var Some; print([S^]);}');
    assertOpType(returnValue: true, typeNames: true);
  }

  test_Literal_string() {
    // SimpleStringLiteral  ExpressionStatement  Block
    addTestSource('class A {a() {"hel^lo"}}');
    assertOpType();
  }

  test_MapLiteralEntry() {
    // MapLiteralEntry  MapLiteral  VariableDeclaration
    addTestSource('foo = {^');
    assertOpType(returnValue: true, typeNames: true);
  }

  test_MapLiteralEntry1() {
    // MapLiteralEntry  MapLiteral  VariableDeclaration
    addTestSource('foo = {T^');
    assertOpType(returnValue: true, typeNames: true);
  }

  test_MapLiteralEntry2() {
    // SimpleIdentifier  MapLiteralEntry  MapLiteral  VariableDeclaration
    addTestSource('foo = {7:T^};');
    assertOpType(returnValue: true, typeNames: true);
  }

  test_MethodDeclaration1() {
    // SimpleIdentifier  MethodDeclaration  ClassDeclaration
    addTestSource('class Bar {const ^Fara();}');
    assertOpType(typeNames: true);
  }

  test_MethodDeclaration2() {
    // SimpleIdentifier  MethodDeclaration  ClassDeclaration
    addTestSource('class Bar {const F^ara();}');
    assertOpType(typeNames: true);
  }

  test_MethodDeclaration_inLineComment() {
    // Comment  ClassDeclaration  CompilationUnit
    addTestSource('''
      class C2 {
        // normal comment ^
        zoo(z) { } String name; }''');
    assertOpType();
  }

  test_MethodDeclaration_inLineComment2() {
    // Comment  ClassDeclaration  CompilationUnit
    addTestSource('''
      class C2 {
        // normal ^comment
        zoo(z) { } String name; }''');
    assertOpType();
  }

  test_MethodDeclaration_inLineComment3() {
    // Comment  ClassDeclaration  CompilationUnit
    addTestSource('''
      class C2 {
        // normal comment ^
        // normal comment 2
        zoo(z) { } String name; }''');
    assertOpType();
  }

  test_MethodDeclaration_inLineComment4() {
    // Comment  ClassDeclaration  CompilationUnit
    addTestSource('''
      class C2 {
        // normal comment
        // normal comment 2^
        zoo(z) { } String name; }''');
    assertOpType();
  }

  test_MethodDeclaration_inLineDocComment() {
    // Comment  MethodDeclaration  ClassDeclaration  CompilationUnit
    addTestSource('''
      class C2 {
        /// some dartdoc ^
        zoo(z) { } String name; }''');
    assertOpType();
  }

  test_MethodDeclaration_inLineDocComment2() {
    // Comment  MethodDeclaration  ClassDeclaration  CompilationUnit
    addTestSource('''
      class C2 {
        /// some ^dartdoc
        zoo(z) { } String name; }''');
    assertOpType();
  }

  test_MethodDeclaration_inStarComment() {
    // Comment  ClassDeclaration  CompilationUnit
    addTestSource('class C2 {/* ^ */ zoo(z) {} String name;}');
    assertOpType();
  }

  test_MethodDeclaration_inStarComment2() {
    // Comment  ClassDeclaration  CompilationUnit
    addTestSource('class C2 {/*  *^/ zoo(z) {} String name;}');
    assertOpType();
  }

  test_MethodDeclaration_inStarDocComment() {
    // Comment  MethodDeclaration  ClassDeclaration  CompilationUnit
    addTestSource('class C2 {/** ^ */ zoo(z) { } String name; }');
    assertOpType();
  }

  test_MethodDeclaration_inStarDocComment2() {
    // Comment  MethodDeclaration  ClassDeclaration  CompilationUnit
    addTestSource('class C2 {/**  *^/ zoo(z) { } String name; }');
    assertOpType();
  }

  test_MethodDeclaration_returnType() {
    // ClassDeclaration  CompilationUnit
    addTestSource('class C2 {^ zoo(z) { } String name; }');
    assertOpType(typeNames: true);
  }

  test_MethodDeclaration_returnType_afterLineComment() {
    // MethodDeclaration  ClassDeclaration  CompilationUnit
    addTestSource('''
      class C2 {
        // normal comment
        ^ zoo(z) {} String name;}''');
    assertOpType(typeNames: true);
  }

  test_MethodDeclaration_returnType_afterLineComment2() {
    // MethodDeclaration  ClassDeclaration  CompilationUnit
    // TOD(danrubel) left align all test source
    addTestSource('''
class C2 {
  // normal comment
^ zoo(z) {} String name;}''');
    assertOpType(typeNames: true);
  }

  test_MethodDeclaration_returnType_afterLineDocComment() {
    // SimpleIdentifier  MethodDeclaration  ClassDeclaration  CompilationUnit
    addTestSource('''
      class C2 {
        /// some dartdoc
        ^ zoo(z) { } String name; }''');
    assertOpType(typeNames: true);
  }

  test_MethodDeclaration_returnType_afterLineDocComment2() {
    // SimpleIdentifier  MethodDeclaration  ClassDeclaration  CompilationUnit
    addTestSource('''
class C2 {
  /// some dartdoc
^ zoo(z) { } String name; }''');
    assertOpType(typeNames: true);
  }

  test_MethodDeclaration_returnType_afterStarComment() {
    // ClassDeclaration  CompilationUnit
    addTestSource('class C2 {/* */ ^ zoo(z) { } String name; }');
    assertOpType(typeNames: true);
  }

  test_MethodDeclaration_returnType_afterStarComment2() {
    // ClassDeclaration  CompilationUnit
    addTestSource('class C2 {/* */^ zoo(z) { } String name; }');
    assertOpType(typeNames: true);
  }

  test_MethodDeclaration_returnType_afterStarDocComment() {
    // MethodDeclaration  ClassDeclaration  CompilationUnit
    addTestSource('class C2 {/** */ ^ zoo(z) { } String name; }');
    assertOpType(typeNames: true);
  }

  test_MethodDeclaration_returnType_afterStarDocComment2() {
    // MethodDeclaration  ClassDeclaration  CompilationUnit
    addTestSource('class C2 {/** */^ zoo(z) { } String name; }');
    assertOpType(typeNames: true);
  }

  test_MethodInvocation_no_semicolon() {
    // MethodInvocation  ExpressionStatement  Block
    addTestSource('''
      class A implements I {
        // no semicolon between completion point and next statement
        set _s2(I x) {x.^ m(null);}
      }''');
    assertOpType(
        returnValue: true, typeNames: true, voidReturn: true, prefixed: true);
  }

  test_PostfixExpression() {
    // SimpleIdentifier  PostfixExpression  ForStatement
    addTestSource('int x = 0; main() {ax+^+;}');
    assertOpType(returnValue: true, typeNames: true);
  }

  test_PrefixedIdentifier_class_const() {
    // SimpleIdentifier PrefixedIdentifier ExpressionStatement Block
    addTestSource('main() {A.^}');
    assertOpType(
        returnValue: true, typeNames: true, voidReturn: true, prefixed: true);
  }

  test_PrefixedIdentifier_class_imported() {
    // SimpleIdentifier  PrefixedIdentifier  ExpressionStatement
    addTestSource('main() {A a; a.^}');
    assertOpType(
        returnValue: true, typeNames: true, voidReturn: true, prefixed: true);
  }

  test_PrefixedIdentifier_prefix() {
    // SimpleIdentifier  PrefixedIdentifier  ExpressionStatement
    addTestSource('class X {foo(){A^.bar}}');
    assertOpType(typeNames: true, returnValue: true, voidReturn: true);
  }

  test_PropertyAccess_expression() {
    // SimpleIdentifier  MethodInvocation  PropertyAccess  ExpressionStatement
    addTestSource('class A {a() {"hello".to^String().length}}');
    assertOpType(
        returnValue: true, typeNames: true, voidReturn: true, prefixed: true);
  }

  test_PropertyAccess_noTarget() {
    // SimpleIdentifier  PropertyAccess  ExpressionStatement
    addTestSource('main() {.^}');
    assertOpType();
  }

  test_PropertyAccess_noTarget2() {
    // SimpleIdentifier  PropertyAccess  CascadeExpressions
    addTestSource('main() {.^.}');
    assertOpType();
  }

  test_PropertyAccess_noTarget3() {
    // SimpleIdentifier  PropertyAccess  CascadeExpressions
    addTestSource('main() {..^}');
    assertOpType();
  }

  test_PropertyAccess_selector() {
    // SimpleIdentifier  PropertyAccess  ExpressionStatement  Block
    addTestSource('class A {a() {"hello".length.^}}');
    assertOpType(
        returnValue: true, typeNames: true, voidReturn: true, prefixed: true);
  }

  test_ReturnStatement() {
    // ReturnStatement  Block
    addTestSource('f() { var vvv = 42; return ^ }');
    assertOpType(returnValue: true, typeNames: true);
  }

  test_SimpleFormalParameter_closure() {
    // SimpleIdentifier  SimpleFormalParameter  FormalParameterList
    addTestSource('mth() { PNGS.sort((String a, Str^) => a.compareTo(b)); }');
    assertOpType(typeNames: true);
  }

  test_SimpleFormalParameter_name1() {
    // SimpleIdentifier  SimpleFormalParameter  FormalParameterList
    addTestSource('m(String na^) {}');
    assertOpType(typeNames: false);
  }

  test_SimpleFormalParameter_name2() {
    // SimpleIdentifier  SimpleFormalParameter  FormalParameterList
    addTestSource('m(int first, String na^) {}');
    assertOpType(typeNames: false);
  }

  test_SimpleFormalParameter_type_optionalNamed() {
    // SimpleIdentifier  DefaultFormalParameter  FormalParameterList
    addTestSource('m({Str^}) {}');
    assertOpType(typeNames: true);
  }

  test_SimpleFormalParameter_type_optionalPositional() {
    // SimpleIdentifier  DefaultFormalParameter  FormalParameterList
    addTestSource('m([Str^]) {}');
    assertOpType(typeNames: true);
  }

  test_SimpleFormalParameter_type_withName() {
    // SimpleIdentifier  SimpleFormalParameter  FormalParameterList
    addTestSource('m(Str^ name) {}');
    assertOpType(typeNames: true);
  }

  test_SimpleFormalParameter_type_withoutName1() {
    // SimpleIdentifier  SimpleFormalParameter  FormalParameterList
    addTestSource('m(Str^) {}');
    assertOpType(typeNames: true);
  }

  test_SimpleFormalParameter_type_withoutName2() {
    // FormalParameterList
    addTestSource('m(^) {}');
    assertOpType(typeNames: true);
  }

  test_SimpleFormalParameter_type_withoutName3() {
    // SimpleIdentifier  SimpleFormalParameter  FormalParameterList
    addTestSource('m(int first, Str^) {}');
    assertOpType(typeNames: true);
  }

  test_SwitchCase_before() {
    // SwitchCase  SwitchStatement  Block
    addTestSource('main() {switch(k) {^case 1:}}');
    assertOpType();
  }

  test_SwitchCase_between() {
    // SwitchCase  SwitchStatement  Block
    addTestSource('main() {switch(k) {case 1: ^ case 2: return}}');
    assertOpType(returnValue: true, typeNames: true, voidReturn: true);
  }

  test_SwitchCase_expression1() {
    // SimpleIdentifier  SwitchCase  SwitchStatement
    addTestSource('''m() {switch (x) {case ^D: return;}}''');
    assertOpType(returnValue: true, typeNames: true);
  }

  test_SwitchCase_expression2() {
    // SimpleIdentifier  SwitchCase  SwitchStatement
    addTestSource('''m() {switch (x) {case ^}}''');
    assertOpType(returnValue: true, typeNames: true);
  }

  test_SwitchDefault_before() {
    // SwitchDefault  SwitchStatement  Block
    addTestSource('main() {switch(k) { ^ default: return;}}');
    assertOpType();
  }

  test_SwitchDefault_between() {
    // SwitchDefault  SwitchStatement  Block
    addTestSource('main() {switch(k) {case 1: ^ default: return;}}');
    assertOpType(returnValue: true, typeNames: true, voidReturn: true);
  }

  test_SwitchStatement_body_empty() {
    // Token('}')  SwitchStatement  Block
    addTestSource('main() {switch(k) {^}}');
    assertOpType();
  }

  test_SwitchStatement_body_end() {
    // Token('}')  SwitchStatement  Block
    addTestSource('main() {switch(k) {case 1:^}}');
    assertOpType(returnValue: true, typeNames: true, voidReturn: true);
  }

  test_SwitchStatement_body_end2() {
    addTestSource('main() {switch(k) {case 1:as^}}');
    assertOpType(returnValue: true, typeNames: true, voidReturn: true);
  }

  test_SwitchStatement_expression1() {
    // SimpleIdentifier  SwitchStatement  Block
    addTestSource('main() {switch(^k) {case 1:{}}}');
    assertOpType(returnValue: true, typeNames: true);
  }

  test_SwitchStatement_expression2() {
    // SimpleIdentifier  SwitchStatement  Block
    addTestSource('main() {switch(k^) {case 1:{}}}');
    assertOpType(returnValue: true, typeNames: true);
  }

  test_SwitchStatement_expression_empty() {
    // SimpleIdentifier  SwitchStatement  Block
    addTestSource('main() {switch(^) {case 1:{}}}');
    assertOpType(returnValue: true, typeNames: true);
  }

  test_ThisExpression_block() {
    // MethodInvocation  ExpressionStatement  Block
    addTestSource('''
      class A implements I {
        // no semicolon between completion point and next statement
        set s1(I x) {} set _s2(I x) {this.^ m(null);}
      }''');
    assertOpType(returnValue: true, voidReturn: true, prefixed: true);
  }

  test_ThisExpression_constructor() {
    // SimpleIdentifier  PropertyAccess  ExpressionStatement
    addTestSource('''
      class A implements I {
        A() {this.^}
      }''');
    assertOpType(returnValue: true, voidReturn: true, prefixed: true);
  }

  test_ThisExpression_constructor_param() {
    // SimpleIdentifier  FieldFormalParameter  FormalParameterList
    addTestSource('''
      class A implements I {
        A(this.^) {}
      }''');
    assertOpType(prefixed: true);
  }

  test_ThisExpression_constructor_param2() {
    // SimpleIdentifier  FieldFormalParameter  FormalParameterList
    addTestSource('''
      class A implements I {
        A(this.f^) {}
      }''');
    assertOpType(prefixed: true);
  }

  test_ThisExpression_constructor_param3() {
    // SimpleIdentifier  FieldFormalParameter  FormalParameterList
    addTestSource('''
      class A implements I {
        A(this.^f) {}
      }''');
    assertOpType(prefixed: true);
  }

  test_ThisExpression_constructor_param4() {
    // FieldFormalParameter  FormalParameterList  ConstructorDeclaration
    addTestSource('''
      class A implements I {
        A(Str^ this.foo) {}
      }''');
    assertOpType(typeNames: true);
  }

  test_ThrowExpression() {
    // SimpleIdentifier  ThrowExpression  ExpressionStatement
    addTestSource('main() {throw ^;}');
    assertOpType(returnValue: true, typeNames: true);
  }

  test_TopLevelVariableDeclaration_typed_name() {
    // SimpleIdentifier  VariableDeclaration  VariableDeclarationList
    // TopLevelVariableDeclaration
    // _OpTypeAstVisitor.visitVariableDeclarationList is executed with this
    // source, but _OpTypeAstVisitor.visitTopLevelVariableDeclaration is called
    // for test_TopLevelVariableDeclaration_typed_name_semicolon
    addTestSource('class A {} B ^');
    assertOpType(varNames: true);
  }

  test_TopLevelVariableDeclaration_typed_name_semicolon() {
    // SimpleIdentifier  VariableDeclaration  VariableDeclarationList
    // TopLevelVariableDeclaration
    // See comment in test_TopLevelVariableDeclaration_typed_name
    addTestSource('class A {} B ^;');
    assertOpType(varNames: true);
  }

  test_TopLevelVariableDeclaration_untyped_name() {
    // SimpleIdentifier  VariableDeclaration  VariableDeclarationList
    // TopLevelVariableDeclaration
    addTestSource('class A {} var ^');
    assertOpType();
  }

  test_TypeArgumentList() {
    // SimpleIdentifier  BinaryExpression  ExpressionStatement
    addTestSource('main() { C<^> c; }');
    assertOpType(typeNames: true);
  }

  test_TypeArgumentList2() {
    // TypeName  TypeArgumentList  TypeName
    addTestSource('main() { C<C^> c; }');
    assertOpType(typeNames: true);
  }

  test_TypeParameter() {
    // SimpleIdentifier  TypeParameter  TypeParameterList
    addTestSource('class tezetst <String, ^List> {}');
    assertOpType();
  }

  test_TypeParameterList_empty() {
    // SimpleIdentifier  TypeParameter  TypeParameterList
    addTestSource('class tezetst <^> {}');
    assertOpType();
  }

  test_VariableDeclaration_name() {
    // SimpleIdentifier  VariableDeclaration  VariableDeclarationList
    // VariableDeclarationStatement  Block
    addTestSource('main() {var ^}');
    assertOpType();
  }

  test_VariableDeclaration_name_hasSome_parameterizedType() {
    // SimpleIdentifier  VariableDeclaration  VariableDeclarationList
    // VariableDeclarationStatement  Block
    addTestSource('main() {List<int> m^}');
    assertOpType(varNames: true);
  }

  test_VariableDeclaration_name_hasSome_simpleType() {
    // SimpleIdentifier  VariableDeclaration  VariableDeclarationList
    // VariableDeclarationStatement  Block
    addTestSource('main() {String m^}');
    assertOpType(varNames: true);
  }

  test_VariableDeclarationList_final() {
    // VariableDeclarationList  VariableDeclarationStatement  Block
    addTestSource('main() {final ^}');
    assertOpType(typeNames: true);
  }

  test_VariableDeclarationStatement_afterSemicolon() {
    // VariableDeclarationStatement  Block  BlockFunctionBody
    addTestSource('class A {var a; x() {var b;^}}');
    assertOpType(returnValue: true, typeNames: true, voidReturn: true);
  }

  test_VariableDeclarationStatement_RHS() {
    // SimpleIdentifier  VariableDeclaration  VariableDeclarationList
    // VariableDeclarationStatement
    addTestSource('class C {bar(){var f; {var x;} var e = ^}}');
    assertOpType(returnValue: true, typeNames: true);
  }

  test_VariableDeclarationStatement_RHS_missing_semicolon() {
    // VariableDeclaration  VariableDeclarationList
    // VariableDeclarationStatement
    addTestSource('class C {bar(){var f; {var x;} var e = ^ var g}}');
    assertOpType(returnValue: true, typeNames: true);
  }

  test_WhileStatement() {
    // SimpleIdentifier  WhileStatement  Block
    addTestSource('mth() { while (b^) {} }}');
    assertOpType(returnValue: true, typeNames: true);
  }

  test_WithClause() {
    // WithClause  ClassDeclaration
    addTestSource('class x extends Object with ^\n{}');
    assertOpType(typeNames: true);
  }
}

class _TestSource implements Source {
  String fullName;
  _TestSource(this.fullName);

  @override
  String get encoding => fullName;

  @override
  bool get isInSystemLibrary => false;

  @override
  String get shortName => fullName;

  @override
  Source get source => this;

  @override
  Uri get uri => new Uri.file(fullName);

  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
