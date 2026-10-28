// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/to_source_visitor.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../util/feature_sets.dart';
import '../../diagnostics/parser_diagnostics.dart';
import '../resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ToSourceVisitorTest);
    defineReflectiveTests(ToSourceVisitorResolutionTest);
  });
}

@reflectiveTest
class ToSourceVisitorResolutionTest extends PubPackageResolutionTest {
  test_dotShorthandMethodInvocation() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  static A foo<T>(int a, int b) => A();
}
A x = .foo<int>(0, 1);
''');
    _assertSource(
      '.foo<int>(0, 1)',
      result.findNode.singleDotShorthandMethodInvocation,
    );
  }

  test_dotShorthandMethodInvocation_withSelector() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  static A foo<T>(int a, int b) => A();
  A get bar => this;
}
A x = .foo<int>(0, 1).bar;
''');
    _assertSource(
      '.foo<int>(0, 1)',
      result.findNode.singleDotShorthandMethodInvocation,
    );
  }

  test_dotShorthandNameExpression() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  static A foo = A();
}
A x = .foo;
''');
    _assertSource('.foo', result.findNode.singleDotShorthandNameExpression);
  }

  test_dotShorthandNameExpression_withSelector() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  static A foo = A();
  A get bar => this;
}
A x = .foo.bar;
''');
    _assertSource('.foo', result.findNode.singleDotShorthandNameExpression);
  }

  test_extensionOverride() async {
    var code = 'E(0)';
    var result = await resolveTestCodeWithDiagnostics('''
extension E on int {
  void foo() {}
}
void f() {
  $code.foo();
}
''');
    var node = result.findNode.singleExtensionOverride;
    _assertSource(code, node);

    // ignore: analyzer_v1_ast_use
    var nodeV1 = result.findNodeV1.singleExtensionOverride;
    _assertSource(code, nodeV1);
  }

  test_extensionOverride_importPrefix() async {
    var code = 'p.E(0)';
    var result = await resolveTestCodeWithDiagnostics('''
import 'test.dart' as p;
extension E on int {
  void foo() {}
}
void f() {
  $code.foo();
}
''');
    var node = result.findNode.singleExtensionOverride;
    _assertSource(code, node);

    // ignore: analyzer_v1_ast_use
    var nodeV1 = result.findNodeV1.singleExtensionOverride;
    _assertSource(code, nodeV1);
  }

  test_extensionOverride_importPrefix_typeArguments() async {
    var code = 'p.E<int>(0)';
    var result = await resolveTestCodeWithDiagnostics('''
import 'test.dart' as p;
extension E<T> on T {
  void foo() {}
}
void f() {
  $code.foo();
}
''');
    var node = result.findNode.singleExtensionOverride;
    _assertSource(code, node);

    // ignore: analyzer_v1_ast_use
    var nodeV1 = result.findNodeV1.singleExtensionOverride;
    _assertSource(code, nodeV1);
  }

  test_extensionOverride_typeArguments() async {
    var code = 'E<int>(0)';
    var result = await resolveTestCodeWithDiagnostics('''
extension E<T> on T {
  void foo() {}
}
void f() {
  $code.foo();
}
''');
    var node = result.findNode.singleExtensionOverride;
    _assertSource(code, node);

    // ignore: analyzer_v1_ast_use
    var nodeV1 = result.findNodeV1.singleExtensionOverride;
    _assertSource(code, nodeV1);
  }

  test_functionInstantiation() async {
    var result = await resolveTestCodeWithDiagnostics('''
T f<T>(T value) => value;
const g = f<int>;
''');
    _assertSource('f<int>', result.findNode.singleFunctionInstantiation);

    // ignore: analyzer_v1_ast_use
    _assertSource('f<int>', result.findNodeV1.singleFunctionReference);
  }

  test_functionInstantiation_implicitCallTearOff() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C {
  T call<T>(T value) => value;
}
int Function(int) f(C c) => c<int>;
''');
    _assertSource('c<int>', result.findNode.singleFunctionInstantiation);
    _assertSource('c', result.findNode.singleImplicitCallTearOff);

    // ignore: analyzer_v1_ast_use
    _assertSource('c<int>', result.findNodeV1.singleImplicitCallReference);
  }

  test_implicitCallTearOff() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C {
  int call(int value) => value;
}
int Function(int) f(C c) => c;
''');
    _assertSource('c', result.findNode.singleImplicitCallTearOff);

    // ignore: analyzer_v1_ast_use
    _assertSource('c', result.findNodeV1.singleImplicitCallReference);
  }

  test_implicitFunctionInstantiation() async {
    var result = await resolveTestCodeWithDiagnostics('''
T f<T>(T value) => value;
const int Function(int) g = f;
''');
    _assertSource('f', result.findNode.singleImplicitFunctionInstantiation);

    // ignore: analyzer_v1_ast_use
    _assertSource('f', result.findNodeV1.singleFunctionReference);
  }

  test_implicitFunctionInstantiation_implicitCallTearOff() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C {
  T call<T>(T value) => value;
}
int Function(int) f(C c) => c;
''');
    _assertSource('c', result.findNode.singleImplicitFunctionInstantiation);
    _assertSource('c', result.findNode.singleImplicitCallTearOff);

    // ignore: analyzer_v1_ast_use
    _assertSource('c', result.findNodeV1.singleImplicitCallReference);
  }

  test_importPrefixedNameExpression() async {
    var result = await resolveTestCodeWithDiagnostics('''
import 'dart:math' as math;
var x = math.pi;
''');
    _assertSource(
      'math.pi',
      result.findNode.singleImportPrefixedNameExpression,
    );

    // ignore: analyzer_v1_ast_use
    _assertSource('math.pi', result.findNodeV1.singlePrefixedIdentifier);
  }

  test_receiverPropertyExtraction() async {
    var result = await resolveTestCodeWithDiagnostics('''
var x = (0).isEven;
''');
    _assertSource(
      '(0).isEven',
      result.findNode.singleReceiverPropertyExtraction,
    );

    // ignore: analyzer_v1_ast_use
    _assertSource('(0).isEven', result.findNodeV1.singlePropertyAccess);
  }

  test_unqualifiedNameExpression() async {
    var result = await resolveTestCodeWithDiagnostics('''
var foo = 0;
var x = foo;
''');
    _assertSource('foo', result.findNode.singleUnqualifiedNameExpression);

    // ignore: analyzer_v1_ast_use
    _assertSource('foo', result.findNodeV1.simple('foo;'));
  }

  void _assertSource(String expected, AstNode node) {
    expect(node.toString(), expected);
  }
}

@reflectiveTest
class ToSourceVisitorTest extends ParserDiagnosticsTest {
  void test_adjacentStrings() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var v = 'a' 'b';
''');
    var node = parseResult.findNode.singleAdjacentStrings;
    _assertSource("'a' 'b'", node);
  }

  void test_annotation_constant() {
    var code = '@A';
    var parseResult = parseTestCodeWithDiagnostics('''
$code
void f() {}
''');
    var node = parseResult.findNode.singleAnnotation;
    _assertSource(code, node);
  }

  void test_annotation_constructor() {
    var code = '@A.foo()';
    var parseResult = parseTestCodeWithDiagnostics('''
$code
void f() {}
''');
    var node = parseResult.findNode.singleAnnotation;
    _assertSource(code, node);
  }

  void test_annotation_constructor_generic() {
    var code = '@A<int>.foo()';
    var parseResult = parseTestCodeWithDiagnostics('''
$code
void f() {}
''');
    var node = parseResult.findNode.singleAnnotation;
    _assertSource(code, node);
  }

  void test_argumentList() {
    var code = '(0, 1)';
    var parseResult = parseTestCodeWithDiagnostics('''
final x = f$code;
''');
    var node = parseResult.findNode.singleArgumentList;
    _assertSource(code, node);
  }

  void test_asExpression() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var v = a as T;
''');
    var node = parseResult.findNode.singleAsExpression;
    _assertSource('a as T', node);
  }

  void test_assertStatement() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  assert(a);
}
''');
    var node = parseResult.findNode.singleAssertStatement;
    _assertSource('assert (a);', node);
  }

  void test_assertStatement_withMessage() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  assert(a, b);
}
''');
    var node = parseResult.findNode.singleAssertStatement;
    _assertSource('assert (a, b);', node);
  }

  void test_assignedVariablePattern() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f(int foo) {
  (foo) = 0;
}
''');
    var node = parseResult.findNode.singleAssignedVariablePattern;
    _assertSource('foo', node);
  }

  void test_awaitExpression() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() async => await e;
''');
    var node = parseResult.findNode.singleAwaitExpression;
    _assertSource('await e', node);
  }

  void test_binaryOperatorInvocation() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var v = a + b;
''');
    var node = parseResult.findNode.singleBinaryOperatorInvocation;
    _assertSource('a + b', node);
  }

  void test_binaryOperatorInvocation_precedence() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var v = a * (b + c);
''');
    var node = parseResult.findNode.binaryOperatorInvocation('a *');
    _assertSource('a * (b + c)', node);
  }

  void test_block_empty() {
    var code = '{}';
    var parseResult = parseTestCodeWithDiagnostics('''
void f() $code
''');
    var node = parseResult.findNode.singleBlock;
    _assertSource(code, node);
  }

  void test_block_nonEmpty() {
    var code = '{foo(); bar();}';
    var parseResult = parseTestCodeWithDiagnostics('''
void f() $code
''');
    var node = parseResult.findNode.singleBlock;
    _assertSource(code, node);
  }

  void test_blockFunctionBody_async() {
    var code = 'async {}';
    var parseResult = parseTestCodeWithDiagnostics('''
void f() $code
''');
    var node = parseResult.findNode.singleBlockFunctionBody;
    _assertSource(code, node);
  }

  void test_blockFunctionBody_async_star() {
    var code = 'async* {}';
    var parseResult = parseTestCodeWithDiagnostics('''
void f() $code
''');
    var node = parseResult.findNode.singleBlockFunctionBody;
    _assertSource(code, node);
  }

  void test_blockFunctionBody_simple() {
    var code = '{}';
    var parseResult = parseTestCodeWithDiagnostics('''
void f() $code
''');
    var node = parseResult.findNode.singleBlockFunctionBody;
    _assertSource(code, node);
  }

  void test_blockFunctionBody_sync_star() {
    var code = 'sync* {}';
    var parseResult = parseTestCodeWithDiagnostics('''
void f() $code
''');
    var node = parseResult.findNode.singleBlockFunctionBody;
    _assertSource(code, node);
  }

  void test_booleanLiteral_false() {
    var code = 'false';
    var parseResult = parseTestCodeWithDiagnostics('''
final v = $code;
''');
    var node = parseResult.findNode.singleBooleanLiteral;
    _assertSource(code, node);
  }

  void test_booleanLiteral_true() {
    var code = 'true';
    var parseResult = parseTestCodeWithDiagnostics('''
final v = $code;
''');
    var node = parseResult.findNode.singleBooleanLiteral;
    _assertSource(code, node);
  }

  void test_breakStatement_label() {
    var code = 'break L;';
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  L: while (true) {
    $code
  }
}
''');
    var node = parseResult.findNode.singleBreakStatement;
    _assertSource(code, node);
  }

  void test_breakStatement_noLabel() {
    var code = 'break;';
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  while (true) {
    $code
  }
}
''');
    var node = parseResult.findNode.singleBreakStatement;
    _assertSource(code, node);
  }

  void test_callInvocation_minimal() {
    var code = '(a)()';
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  $code;
}
''');
    var node = parseResult.findNode.singleCallInvocation;
    _assertSource(code, node);
  }

  void test_callInvocation_typeArguments() {
    var code = '(a)<int>()';
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  $code;
}
''');
    var node = parseResult.findNode.singleCallInvocation;
    _assertSource(code, node);
  }

  void test_cascadeExpression_assignment() {
    var code = 'a..b = 1';
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  $code;
}
''');
    var node = parseResult.findNode.singleCascadeExpression;
    _assertSource(code, node);

    // ignore: analyzer_v1_ast_use
    var assignmentV1 = parseResult.findNodeV1.singleAssignmentExpression;
    expect(assignmentV1.toSource(), '..b = 1');
  }

  void test_cascadeExpression_field() {
    var code = 'a..b..c';
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  $code;
}
''');
    var node = parseResult.findNode.singleCascadeExpression;
    _assertSource(code, node);

    // ignore: analyzer_v1_ast_use
    var propertyV1 = parseResult.findNodeV1.propertyAccess('b..');
    expect(propertyV1.toSource(), '..b');
  }

  void test_cascadeExpression_index() {
    var code = 'a..[0]..[1]';
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  $code;
}
''');
    var node = parseResult.findNode.singleCascadeExpression;
    _assertSource(code, node);

    // ignore: analyzer_v1_ast_use
    var indexV1 = parseResult.findNodeV1.index('[0]');
    expect(indexV1.toSource(), '..[0]');
  }

  void test_cascadeExpression_index_withSelector() {
    var code = 'a..b()[0]';
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  $code;
}
''');
    var node = parseResult.findNode.singleCascadeExpression;
    _assertSource(code, node);

    // ignore: analyzer_v1_ast_use
    var indexV1 = parseResult.findNodeV1.singleIndexExpression;
    expect(indexV1.toSource(), '..b()[0]');
  }

  void test_cascadeExpression_method() {
    var code = 'a..b()..c()';
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  $code;
}
''');
    var node = parseResult.findNode.singleCascadeExpression;
    _assertSource(code, node);

    // ignore: analyzer_v1_ast_use
    var invocationV1 = parseResult.findNodeV1.methodInvocation('b()');
    expect(invocationV1.toSource(), '..b()');
  }

  void test_cascadeExpression_method_withSelector() {
    var code = 'a..b().c';
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  $code;
}
''');
    var node = parseResult.findNode.singleCascadeExpression;
    _assertSource(code, node);

    // ignore: analyzer_v1_ast_use
    var propertyV1 = parseResult.findNodeV1.singlePropertyAccess;
    expect(propertyV1.toSource(), '..b().c');
  }

  void test_cascadeExpression_nullAware() {
    var code = 'a?..b()';
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  $code;
}
''');
    var node = parseResult.findNode.singleCascadeExpression;
    _assertSource(code, node);

    // ignore: analyzer_v1_ast_use
    var invocationV1 = parseResult.findNodeV1.singleMethodInvocation;
    expect(invocationV1.toSource(), '?..b()');
  }

  void test_cascadeExpression_typeArguments() {
    var code = 'a..b<int>';
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  $code;
}
''');
    var node = parseResult.findNode.singleCascadeExpression;
    _assertSource(code, node);

    // ignore: analyzer_v1_ast_use
    var referenceV1 = parseResult.findNodeV1.singleFunctionReference;
    expect(referenceV1.toSource(), '..b<int>');
  }

  void test_castPattern() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case y as int:
      break;
  }
}
''');
    var node = parseResult.findNode.singleCastPattern;
    _assertSource('y as int', node);
  }

  void test_catchClause_catch_noStack() {
    var code = 'catch (e) {}';
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  try {}
  $code
}
''');
    var node = parseResult.findNode.singleCatchClause;
    _assertSource(code, node);
  }

  void test_catchClause_catch_stack() {
    var code = 'catch (e, s) {}';
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  try {}
  $code
}
''');
    var node = parseResult.findNode.singleCatchClause;
    _assertSource(code, node);
  }

  void test_catchClause_on() {
    var code = 'on E {}';
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  try {}
  $code
}
''');
    var node = parseResult.findNode.singleCatchClause;
    _assertSource(code, node);
  }

  void test_catchClause_on_catch() {
    var code = 'on E catch (e) {}';
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  try {}
  $code
}
''');
    var node = parseResult.findNode.singleCatchClause;
    _assertSource(code, node);
  }

  void test_classDeclaration_abstract() {
    var code = 'abstract class C {}';
    var parseResult = parseTestCodeWithDiagnostics(code);
    var node = parseResult.findNode.singleClassDeclaration;
    _assertSource(code, node);
  }

  void test_classDeclaration_augment() {
    var code = 'augment class A {}';
    var parseResult = parseTestCodeWithDiagnostics(code);
    var node = parseResult.findNode.singleClassDeclaration;
    _assertSource(code, node);
  }

  void test_classDeclaration_augment_abstract() {
    var code = 'augment abstract class C {}';
    var parseResult = parseTestCodeWithDiagnostics(code);
    var node = parseResult.findNode.singleClassDeclaration;
    _assertSource(code, node);
  }

  void test_classDeclaration_base() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
base class A {}
''');
    var node = parseResult.findNode.singleClassDeclaration;
    _assertSource('base class A {}', node);
  }

  void test_classDeclaration_empty() {
    var code = 'class C {}';
    var parseResult = parseTestCodeWithDiagnostics(code);
    var node = parseResult.findNode.singleClassDeclaration;
    _assertSource(code, node);
  }

  test_classDeclaration_emptyBody() {
    var code = 'class A;';
    var parseResult = parseTestCodeWithDiagnostics(code);
    var node = parseResult.findNode.singleClassDeclaration;
    _assertSource(code, node);

    // ignore: analyzer_v1_ast_use
    var bodyV1 = parseResult.findNodeV1.singleEmptyClassBody;
    expect(bodyV1.toSource(), ';');
  }

  void test_classDeclaration_extends() {
    var code = 'class C extends A {}';
    var parseResult = parseTestCodeWithDiagnostics('''
$code
''');
    var node = parseResult.findNode.singleClassDeclaration;
    _assertSource(code, node);
  }

  void test_classDeclaration_extends_implements() {
    var code = 'class C extends A implements B {}';
    var parseResult = parseTestCodeWithDiagnostics('''
$code
''');
    var node = parseResult.findNode.singleClassDeclaration;
    _assertSource(code, node);
  }

  void test_classDeclaration_extends_with() {
    var code = 'class C extends A with M {}';
    var parseResult = parseTestCodeWithDiagnostics('''
$code
void f() {}
''');
    var node = parseResult.findNode.singleClassDeclaration;
    _assertSource(code, node);
  }

  void test_classDeclaration_extends_with_implements() {
    var code = 'class C extends A with M implements B {}';
    var parseResult = parseTestCodeWithDiagnostics('''
$code
void f() {}
''');
    var node = parseResult.findNode.singleClassDeclaration;
    _assertSource(code, node);
  }

  void test_classDeclaration_final() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
final class A {}
''');
    var node = parseResult.findNode.singleClassDeclaration;
    _assertSource('final class A {}', node);
  }

  void test_classDeclaration_implements() {
    var code = 'class C implements B {}';
    var parseResult = parseTestCodeWithDiagnostics('''
$code
''');
    var node = parseResult.findNode.singleClassDeclaration;
    _assertSource(code, node);
  }

  void test_classDeclaration_interface() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
interface class A {}
''');
    var node = parseResult.findNode.singleClassDeclaration;
    _assertSource('interface class A {}', node);
  }

  void test_classDeclaration_mixin() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin class A {}
''');
    var node = parseResult.findNode.singleClassDeclaration;
    _assertSource('mixin class A {}', node);
  }

  void test_classDeclaration_multipleMember() {
    var code = 'class C {var a; var b;}';
    var parseResult = parseTestCodeWithDiagnostics('''
$code
''');
    var node = parseResult.findNode.singleClassDeclaration;
    _assertSource(code, node);
  }

  void test_classDeclaration_native() {
    var code = "class C extends A native 'code' {}";
    var parseResult = parseTestCodeWithDiagnostics('''
$code
''');
    var node = parseResult.findNode.singleClassDeclaration;
    _assertSource(code, node);
  }

  void test_classDeclaration_parameters() {
    var code = 'class C<E> {}';
    var parseResult = parseTestCodeWithDiagnostics(code);
    var node = parseResult.findNode.singleClassDeclaration;
    _assertSource(code, node);
  }

  void test_classDeclaration_parameters_extends() {
    var code = 'class C<E> extends A {}';
    var parseResult = parseTestCodeWithDiagnostics('''
$code
''');
    var node = parseResult.findNode.singleClassDeclaration;
    _assertSource(code, node);
  }

  void test_classDeclaration_parameters_extends_implements() {
    var code = 'class C<E> extends A implements B {}';
    var parseResult = parseTestCodeWithDiagnostics('''
$code
''');
    var node = parseResult.findNode.singleClassDeclaration;
    _assertSource(code, node);
  }

  void test_classDeclaration_parameters_extends_with() {
    var code = 'class C<E> extends A with M {}';
    var parseResult = parseTestCodeWithDiagnostics('''
$code
''');
    var node = parseResult.findNode.singleClassDeclaration;
    _assertSource(code, node);
  }

  void test_classDeclaration_parameters_extends_with_implements() {
    var code = 'class C<E> extends A with M implements B {}';
    var parseResult = parseTestCodeWithDiagnostics('''
$code
''');
    var node = parseResult.findNode.singleClassDeclaration;
    _assertSource(code, node);
  }

  void test_classDeclaration_parameters_implements() {
    var code = 'class C<E> implements B {}';
    var parseResult = parseTestCodeWithDiagnostics('''
$code
''');
    var node = parseResult.findNode.singleClassDeclaration;
    _assertSource(code, node);
  }

  test_classDeclaration_primaryConstructor_const_named() {
    var code = 'class const A<T>.named() {}';
    var parseResult = parseTestCodeWithDiagnostics(code);
    var node = parseResult.findNode.singleClassDeclaration;
    _assertSource(code, node);
  }

  test_classDeclaration_primaryConstructor_const_unnamed() {
    var code = 'class A() {}';
    var parseResult = parseTestCodeWithDiagnostics(code);
    var node = parseResult.findNode.singleClassDeclaration;
    _assertSource(code, node);
  }

  test_classDeclaration_primaryConstructor_declaringFormalParameter_optionalNamed() {
    var code = 'class A({final int a = 0}) {}';
    var parseResult = parseTestCodeWithDiagnostics(code);
    var node = parseResult.findNode.singleClassDeclaration;
    _assertSource(code, node);
  }

  test_classDeclaration_primaryConstructor_declaringFormalParameter_requiredPositional() {
    var code = 'class A(final int a) {}';
    var parseResult = parseTestCodeWithDiagnostics(code);
    var node = parseResult.findNode.singleClassDeclaration;
    _assertSource(code, node);
  }

  test_classDeclaration_primaryConstructor_fieldFormalParameter() {
    var code = 'class A(int this.a) {}';
    var parseResult = parseTestCodeWithDiagnostics(code);
    var node = parseResult.findNode.singleClassDeclaration;
    _assertSource(code, node);
  }

  test_classDeclaration_primaryConstructor_notConst_named() {
    var code = 'class A<T>.named() {}';
    var parseResult = parseTestCodeWithDiagnostics(code);
    var node = parseResult.findNode.singleClassDeclaration;
    _assertSource(code, node);
  }

  test_classDeclaration_primaryConstructor_superFormalParameter() {
    var code = 'class A(int super.a) {}';
    var parseResult = parseTestCodeWithDiagnostics(code);
    var node = parseResult.findNode.singleClassDeclaration;
    _assertSource(code, node);
  }

  void test_classDeclaration_sealed() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
sealed class A {}
''');
    var node = parseResult.findNode.singleClassDeclaration;
    _assertSource('sealed class A {}', node);
  }

  void test_classDeclaration_singleMember() {
    var code = 'class C {var a;}';
    var parseResult = parseTestCodeWithDiagnostics(code);
    var node = parseResult.findNode.singleClassDeclaration;
    _assertSource(code, node);

    // ignore: analyzer_v1_ast_use
    var nodeV1 = parseResult.findNodeV1.singleClassDeclaration;
    expect(nodeV1.toSource(), code);

    // ignore: analyzer_v1_ast_use
    var bodyV1 = parseResult.findNodeV1.singleBlockClassBody;
    expect(bodyV1.toSource(), ' {var a;}');
  }

  void test_classDeclaration_withMetadata() {
    var code = '@deprecated class C {}';
    var parseResult = parseTestCodeWithDiagnostics(code);
    var node = parseResult.findNode.singleClassDeclaration;
    _assertSource(code, node);
  }

  void test_classTypeAlias_abstract() {
    var code = 'abstract class C = S with M;';
    var parseResult = parseTestCodeWithDiagnostics('''
$code
''');
    var node = parseResult.findNode.singleClassTypeAlias;
    _assertSource(code, node);
  }

  void test_classTypeAlias_abstract_implements() {
    var code = 'abstract class C = S with M implements I;';
    var parseResult = parseTestCodeWithDiagnostics('''
$code
''');
    var node = parseResult.findNode.singleClassTypeAlias;
    _assertSource(code, node);
  }

  void test_classTypeAlias_abstractAugment() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
augment abstract class C = S with M;
// [diag.mixinApplicationClassAugmentation][column 1][length 7] A mixin application class can't be augmented.
''');
    var node = parseResult.findNode.singleClassTypeAlias;
    _assertSource('augment abstract class C = S with M;', node);
  }

  void test_classTypeAlias_augment() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
augment class A = S with M;
// [diag.mixinApplicationClassAugmentation][column 1][length 7] A mixin application class can't be augmented.
''');
    var node = parseResult.findNode.singleClassTypeAlias;
    _assertSource('augment class A = S with M;', node);
  }

  void test_classTypeAlias_base() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
base class A = S with M;
''');
    var node = parseResult.findNode.singleClassTypeAlias;
    _assertSource('base class A = S with M;', node);
  }

  void test_classTypeAlias_final() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
final class A = S with M;
''');
    var node = parseResult.findNode.singleClassTypeAlias;
    _assertSource('final class A = S with M;', node);
  }

  void test_classTypeAlias_generic() {
    var code = 'class C<E> = S<E> with M<E>;';
    var parseResult = parseTestCodeWithDiagnostics('''
$code
''');
    var node = parseResult.findNode.singleClassTypeAlias;
    _assertSource(code, node);
  }

  void test_classTypeAlias_implements() {
    var code = 'class C = S with M implements I;';
    var parseResult = parseTestCodeWithDiagnostics('''
$code
''');
    var node = parseResult.findNode.singleClassTypeAlias;
    _assertSource(code, node);
  }

  void test_classTypeAlias_interface() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
interface class A = S with M;
''');
    var node = parseResult.findNode.singleClassTypeAlias;
    _assertSource('interface class A = S with M;', node);
  }

  void test_classTypeAlias_minimal() {
    var code = 'class C = S with M;';
    var parseResult = parseTestCodeWithDiagnostics('''
$code
''');
    var node = parseResult.findNode.singleClassTypeAlias;
    _assertSource(code, node);

    // ignore: analyzer_v1_ast_use
    var nodeV1 = parseResult.findNodeV1.singleClassTypeAlias;
    expect(nodeV1.toSource(), code);
  }

  void test_classTypeAlias_mixin() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin class A = S with M;
''');
    var node = parseResult.findNode.singleClassTypeAlias;
    _assertSource('mixin class A = S with M;', node);
  }

  void test_classTypeAlias_parameters_abstract() {
    var code = 'abstract class C<E> = S with M;';
    var parseResult = parseTestCodeWithDiagnostics('''
$code
''');
    var node = parseResult.findNode.singleClassTypeAlias;
    _assertSource(code, node);
  }

  void test_classTypeAlias_parameters_abstract_implements() {
    var code = 'abstract class C<E> = S with M implements I;';
    var parseResult = parseTestCodeWithDiagnostics('''
$code
''');
    var node = parseResult.findNode.singleClassTypeAlias;
    _assertSource(code, node);
  }

  void test_classTypeAlias_parameters_implements() {
    var code = 'class C<E> = S with M implements I;';
    var parseResult = parseTestCodeWithDiagnostics('''
$code
''');
    var node = parseResult.findNode.singleClassTypeAlias;
    _assertSource(code, node);
  }

  void test_classTypeAlias_sealed() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
sealed class A = S with M;
''');
    var node = parseResult.findNode.singleClassTypeAlias;
    _assertSource('sealed class A = S with M;', node);
  }

  void test_classTypeAlias_withMetadata() {
    var code = '@deprecated class A = S with M;';
    var parseResult = parseTestCodeWithDiagnostics(code);
    var node = parseResult.findNode.singleClassTypeAlias;
    _assertSource(code, node);
  }

  void test_comment() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
/// foo
/// bar
void f() {}
''');
    var node = parseResult.findNode.singleComment;
    _assertSource('', node);
  }

  void test_commentReference() {
    var code = 'x';
    var parseResult = parseTestCodeWithDiagnostics('''
/// [$code]
void f() {}
''');
    var node = parseResult.findNode.singleCommentReference;
    _assertSource(code, node);
  }

  void test_commentReference_new() {
    var code = 'C.new';
    var parseResult = parseTestCodeWithDiagnostics('''
/// [$code]
void f() {}
''');
    _assertSource(code, parseResult.findNode.singleCommentReference);
  }

  void test_commentReference_operator() {
    var code = 'p.C.operator +';
    var parseResult = parseTestCodeWithDiagnostics('''
/// [$code]
void f() {}
''');
    _assertSource(code, parseResult.findNode.singleCommentReference);
  }

  void test_commentReference_propertyAccess() {
    var code = 'a.b.c';
    var parseResult = parseTestCodeWithDiagnostics('''
/// [$code]
void f() {}
''');
    var node = parseResult.findNode.singleCommentReference;
    _assertSource(code, node);

    // ignore: analyzer_v1_ast_use
    var propertyV1 = parseResult.findNodeV1.singlePropertyAccess;
    expect(propertyV1.toSource(), code);
  }

  void test_compilationUnit_declaration() {
    var code = 'var a;';
    var parseResult = parseTestCodeWithDiagnostics(code);
    var node = parseResult.findNode.unit;
    _assertSource(code, node);
  }

  void test_compilationUnit_directive() {
    var code = 'library my;';
    var parseResult = parseTestCodeWithDiagnostics(code);
    var node = parseResult.findNode.unit;
    _assertSource(code, node);
  }

  void test_compilationUnit_directive_declaration() {
    var code = 'library my; var a;';
    var parseResult = parseTestCodeWithDiagnostics(code);
    var node = parseResult.findNode.unit;
    _assertSource(code, node);
  }

  void test_compilationUnit_empty() {
    var code = '';
    var parseResult = parseTestCodeWithDiagnostics(code);
    var node = parseResult.findNode.unit;
    _assertSource(code, node);
  }

  void test_compilationUnit_libraryWithoutName() {
    var code = 'library ;';
    var parseResult = parseTestCodeWithDiagnostics(code);
    var node = parseResult.findNode.unit;
    _assertSource(code, node);
  }

  void test_compilationUnit_script() {
    var parseResult = parseTestCodeWithDiagnostics('''
#!/bin/dartvm
''');
    var node = parseResult.findNode.unit;
    _assertSource('#!/bin/dartvm', node);
  }

  void test_compilationUnit_script_declaration() {
    var parseResult = parseTestCodeWithDiagnostics('''
#!/bin/dartvm
var a;
''');
    var node = parseResult.findNode.unit;
    _assertSource('#!/bin/dartvm var a;', node);
  }

  void test_compilationUnit_script_directive() {
    var parseResult = parseTestCodeWithDiagnostics('''
#!/bin/dartvm
library my;
''');
    var node = parseResult.findNode.unit;
    _assertSource('#!/bin/dartvm library my;', node);
  }

  void test_compilationUnit_script_directives_declarations() {
    var parseResult = parseTestCodeWithDiagnostics('''
#!/bin/dartvm
library my;
var a;
''');
    var node = parseResult.findNode.unit;
    _assertSource('#!/bin/dartvm library my; var a;', node);
  }

  void test_compoundAssignment() {
    var code = 'a += b';
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  $code;
}
''');
    var node = parseResult.findNode.singleCompoundAssignment;
    _assertSource(code, node);
  }

  void test_conditionalExpression() {
    var code = 'a ? b : c';
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  $code;
}
''');
    var node = parseResult.findNode.singleConditionalExpression;
    _assertSource(code, node);
  }

  void test_constantPattern() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  if (x case true) {}
}
''');
    var node = parseResult.findNode.singleConstantPattern;
    _assertSource('true', node);
  }

  void test_constructorDeclaration_factoryHead_named() {
    var code = 'factory named() {}';
    var parseResult = parseTestCodeWithDiagnostics('''
class A {
  $code
}
''');
    var node = parseResult.findNode.singleConstructorDeclaration;
    _assertSource(code, node);
  }

  void test_constructorDeclaration_factoryHead_unnamed() {
    var code = 'factory () {}';
    var parseResult = parseTestCodeWithDiagnostics('''
class A {
  $code
}
''');
    var node = parseResult.findNode.singleConstructorDeclaration;
    _assertSource(code, node);
  }

  void test_constructorDeclaration_newHead_named() {
    var code = 'new named();';
    var parseResult = parseTestCodeWithDiagnostics('''
class A {
  $code
}
''');
    var node = parseResult.findNode.singleConstructorDeclaration;
    _assertSource(code, node);
  }

  void test_constructorDeclaration_newHead_unnamed() {
    var code = 'new ();';
    var parseResult = parseTestCodeWithDiagnostics('''
class A {
  $code
}
''');
    var node = parseResult.findNode.singleConstructorDeclaration;
    _assertSource(code, node);
  }

  void test_constructorDeclaration_singleInitializer() {
    var code = 'A() : a = b;';
    var parseResult = parseTestCodeWithDiagnostics('''
class A {
  $code
}
''');
    var node = parseResult.findNode.singleConstructorDeclaration;
    _assertSource(code, node);

    // ignore: analyzer_v1_ast_use
    var nodeV1 = parseResult.findNodeV1.singleConstructorDeclaration;
    expect(nodeV1.toSource(), code);
  }

  void test_constructorDeclaration_typeName_const() {
    var code = 'const A();';
    var parseResult = parseTestCodeWithDiagnostics('''
class A {
  $code
}
''');
    var node = parseResult.findNode.singleConstructorDeclaration;
    _assertSource(code, node);
  }

  void test_constructorDeclaration_typeName_external() {
    var code = 'external A();';
    var parseResult = parseTestCodeWithDiagnostics('''
class A {
  $code
}
''');
    var node = parseResult.findNode.singleConstructorDeclaration;
    _assertSource(code, node);
  }

  void test_constructorDeclaration_typeName_factory_named() {
    var code = 'factory A.named() {}';
    var parseResult = parseTestCodeWithDiagnostics('''
class A {
  $code
}
''');
    var node = parseResult.findNode.singleConstructorDeclaration;
    _assertSource(code, node);
  }

  void test_constructorDeclaration_typeName_factory_unnamed() {
    var code = 'factory A() {}';
    var parseResult = parseTestCodeWithDiagnostics('''
class A {
  $code
}
''');
    var node = parseResult.findNode.singleConstructorDeclaration;
    _assertSource(code, node);
  }

  void
  test_constructorDeclaration_typeName_formalParameters_optionalPositional() {
    var code = 'A(int a, [int b = 0]);';
    var parseResult = parseTestCodeWithDiagnostics('''
class A {
  $code
}
''');
    var node = parseResult.findNode.singleConstructorDeclaration;
    _assertSource(code, node);
  }

  void
  test_constructorDeclaration_typeName_formalParameters_requiredPositional() {
    var code = 'A(int a, double b);';
    var parseResult = parseTestCodeWithDiagnostics('''
class A {
  $code
}
''');
    var node = parseResult.findNode.singleConstructorDeclaration;
    _assertSource(code, node);
  }

  void test_constructorDeclaration_typeName_multipleInitializers() {
    var code = 'A() : a = b, c = d {}';
    var parseResult = parseTestCodeWithDiagnostics('''
class A {
  $code
}
''');
    var node = parseResult.findNode.singleConstructorDeclaration;
    _assertSource(code, node);
  }

  void test_constructorDeclaration_typeName_named() {
    var code = 'A.foo();';
    var parseResult = parseTestCodeWithDiagnostics('''
class A {
  $code
}
''');
    var node = parseResult.findNode.singleConstructorDeclaration;
    _assertSource(code, node);
  }

  void test_constructorDeclaration_typeName_unnamed() {
    var code = 'A();';
    var parseResult = parseTestCodeWithDiagnostics('''
class A {
  $code
}
''');
    var node = parseResult.findNode.singleConstructorDeclaration;
    _assertSource(code, node);
  }

  void test_constructorDeclaration_typeName_withInitializers() {
    var code = 'A() : a = 0, super();';
    var parseResult = parseTestCodeWithDiagnostics('''
class A {
  int a;
  $code
}
''');
    var node = parseResult.findNode.singleConstructorDeclaration;
    _assertSource(code, node);
  }

  void test_constructorDeclaration_withMetadata() {
    var code = '@deprecated C() {}';
    var parseResult = parseTestCodeWithDiagnostics('''
class C {
  $code
}
''');
    var node = parseResult.findNode.singleConstructorDeclaration;
    _assertSource(code, node);
  }

  void test_constructorFieldInitializer_withoutThis() {
    var code = 'a = 0';
    var parseResult = parseTestCodeWithDiagnostics('''
class C {
  C() : $code;
}
''');
    var node = parseResult.findNode.singleConstructorFieldInitializer;
    _assertSource(code, node);
  }

  void test_constructorFieldInitializer_withThis() {
    var code = 'this.a = 0';
    var parseResult = parseTestCodeWithDiagnostics('''
class C {
  C() : $code;
}
''');
    var node = parseResult.findNode.singleConstructorFieldInitializer;
    _assertSource(code, node);
  }

  void test_constructorInvocation_const() {
    var code = 'const A()';
    var parseResult = parseTestCodeWithDiagnostics('''
final x = $code;
''');
    var node = parseResult.findNode.singleConstructorInvocation;
    _assertSource(code, node);
  }

  void test_constructorInvocation_named() {
    var code = 'new A.foo()';
    var parseResult = parseTestCodeWithDiagnostics('''
final x = $code;
''');
    var node = parseResult.findNode.singleConstructorInvocation;
    _assertSource(code, node);
  }

  void test_constructorInvocation_unnamed() {
    var code = 'new A()';
    var parseResult = parseTestCodeWithDiagnostics('''
final x = $code;
''');
    var node = parseResult.findNode.singleConstructorInvocation;
    _assertSource(code, node);
  }

  void test_constructorReference_named_prefix() {
    var code = 'prefix.A.foo';
    var parseResult = parseTestCodeWithDiagnostics('''
final x = new $code();
''');
    var node =
        parseResult.findNode.singleConstructorInvocation.constructorReference;
    _assertSource(code, node);

    // ignore: analyzer_v1_ast_use
    var nodeV1 = parseResult.findNodeV1.singleConstructorName;
    expect(nodeV1.toSource(), code);
    expect(nodeV1.type.toSource(), 'prefix.A');

    // ignore: analyzer_v1_ast_use
    var creationV1 = parseResult.findNodeV1.singleInstanceCreationExpression;
    expect(creationV1.toSource(), 'new $code()');
  }

  void test_constructorReference_unnamed_noPrefix() {
    var code = 'A';
    var parseResult = parseTestCodeWithDiagnostics('''
final x = new $code();
''');
    var node =
        parseResult.findNode.singleConstructorInvocation.constructorReference;
    _assertSource(code, node);
  }

  void test_constructorReference_unnamed_prefix() {
    var code = 'prefix.A';
    var parseResult = parseTestCodeWithDiagnostics('''
final x = new $code();
''');
    var node =
        parseResult.findNode.singleConstructorInvocation.constructorReference;
    _assertSource(code, node);
  }

  void test_continueStatement_label() {
    var code = 'continue L;';
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  L: while (true) {
    $code
  }
}
''');
    var node = parseResult.findNode.singleContinueStatement;
    _assertSource(code, node);
  }

  void test_continueStatement_noLabel() {
    var code = 'continue;';
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  while (true) {
    $code
  }
}
''');
    var node = parseResult.findNode.singleContinueStatement;
    _assertSource(code, node);
  }

  void test_declaredVariablePattern() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case int? a:
      break;
  }
}
''');
    var node = parseResult.findNode.singleDeclaredVariablePattern;
    _assertSource('int? a', node);
  }

  void test_directAssignment() {
    var code = 'a = b';
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  $code;
}
''');
    var node = parseResult.findNode.singleDirectAssignment;
    _assertSource(code, node);
  }

  void test_doStatement() {
    var code = 'do {} while (true);';
    var parseResult = parseTestCodeWithDiagnostics('''
void f () {
  $code
}
''');
    var node = parseResult.findNode.singleDoStatement;
    _assertSource(code, node);
  }

  void test_dotShorthandNameExpression() {
    var code = '.foo';
    var parseResult = parseTestCodeWithDiagnostics('''
final x = $code;
''');
    var node = parseResult.findNode.singleDotShorthandNameExpression;
    _assertSource(code, node);

    // ignore: analyzer_v1_ast_use
    var nodeV1 = parseResult.findNodeV1.singleDotShorthandPropertyAccess;
    expect(nodeV1.toSource(), code);
  }

  void test_dottedName_multiple() {
    var code = 'a.b.c';
    var parseResult = parseTestCodeWithDiagnostics('''
library $code;
''');
    var node = parseResult.findNode.singleDottedName;
    _assertSource(code, node);
  }

  void test_dottedName_single() {
    var code = 'my';
    var parseResult = parseTestCodeWithDiagnostics('''
library $code;
''');
    var node = parseResult.findNode.singleDottedName;
    _assertSource(code, node);
  }

  void test_doubleLiteral() {
    var code = '3.14';
    var parseResult = parseTestCodeWithDiagnostics('''
final x = $code;
''');
    var node = parseResult.findNode.singleDoubleLiteral;
    _assertSource(code, node);
  }

  void test_emptyFunctionBody() {
    var code = ';';
    var parseResult = parseTestCodeWithDiagnostics('''
abstract class A {
  void foo();
}
''');
    var node = parseResult.findNode.singleEmptyFunctionBody;
    _assertSource(code, node);
  }

  void test_emptyStatement() {
    var code = ';';
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  ;
}
''');
    var node = parseResult.findNode.singleEmptyStatement;
    _assertSource(code, node);
  }

  void test_enumConstantDeclaration_augment() {
    var code = 'augment v';
    var parseResult = parseTestCodeWithDiagnostics('''
augment enum E {
  $code
}
''');
    var node = parseResult.findNode.singleEnumConstantDeclaration;
    _assertSource(code, node);
  }

  void test_enumDeclaration_augment() {
    var code = 'augment enum E {v}';
    var parseResult = parseTestCodeWithDiagnostics('''
$code
''');
    var node = parseResult.findNode.singleEnumDeclaration;
    _assertSource(code, node);
  }

  test_enumDeclaration_blockBody_members() {
    var code = 'enum E {v; void foo() {}}';
    var parseResult = parseTestCodeWithDiagnostics(code);
    var node = parseResult.findNode.singleEnumDeclaration;
    _assertSource(code, node);

    // ignore: analyzer_v1_ast_use
    var bodyV1 = parseResult.findNodeV1.singleBlockEnumBody;
    expect(bodyV1.toSource(), ' {v; void foo() {}}');
  }

  void test_enumDeclaration_constant_arguments_named() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
enum E {
  v<double>.named(42)
}
''');
    var node = parseResult.findNode.singleEnumDeclaration;
    _assertSource('enum E {v<double>.named(42)}', node);
  }

  void test_enumDeclaration_constant_arguments_unnamed() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
enum E {
  v<double>(42)
}
''');
    var node = parseResult.findNode.singleEnumDeclaration;
    _assertSource('enum E {v<double>(42)}', node);

    // ignore: analyzer_v1_ast_use
    var constantV1 = parseResult.findNodeV1.singleEnumConstantDeclaration;
    expect(constantV1.toSource(), 'v<double>(42)');
  }

  void test_enumDeclaration_constants_multiple() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
enum E {one, two}
''');
    var node = parseResult.findNode.singleEnumDeclaration;
    _assertSource('enum E {one, two}', node);
  }

  void test_enumDeclaration_constants_single() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
enum E {one}
''');
    var node = parseResult.findNode.singleEnumDeclaration;
    _assertSource('enum E {one}', node);

    // ignore: analyzer_v1_ast_use
    var nodeV1 = parseResult.findNodeV1.singleEnumDeclaration;
    expect(nodeV1.toSource(), 'enum E {one}');
  }

  test_enumDeclaration_emptyBody() {
    var code = 'enum E;';
    var parseResult = parseTestCodeWithDiagnostics(code);
    var node = parseResult.findNode.singleEnumDeclaration;
    _assertSource(code, node);

    // ignore: analyzer_v1_ast_use
    var bodyV1 = parseResult.findNodeV1.singleEmptyEnumBody;
    expect(bodyV1.toSource(), ';');
  }

  void test_enumDeclaration_field_constructor() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
enum E {
  one, two;
  final int field;
  E(this.field);
}
''');
    var node = parseResult.findNode.singleEnumDeclaration;
    _assertSource('enum E {one, two; final int field; E(this.field);}', node);
  }

  void test_enumDeclaration_method() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
enum E {
  one, two;
  void myMethod() {}
  int get myGetter => 0;
}
''');
    var node = parseResult.findNode.singleEnumDeclaration;
    _assertSource(
      'enum E {one, two; void myMethod() {} int get myGetter => 0;}',
      node,
    );
  }

  test_enumDeclaration_primaryConstructor_named() {
    var code = 'enum const E<T>.named(final int a) {}';
    var parseResult = parseTestCodeWithDiagnostics(code);
    var node = parseResult.findNode.singleEnumDeclaration;
    _assertSource(code, node);
  }

  test_enumDeclaration_primaryConstructor_unnamed() {
    var code = 'enum E<T>(final int a) {}';
    var parseResult = parseTestCodeWithDiagnostics(code);
    var node = parseResult.findNode.singleEnumDeclaration;
    _assertSource(code, node);
  }

  void test_enumDeclaration_withoutMembers() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
enum E<T> with M1, M2 implements I1, I2 {one, two}
''');
    var node = parseResult.findNode.singleEnumDeclaration;
    _assertSource('enum E<T> with M1, M2 implements I1, I2 {one, two}', node);
  }

  void test_exportDirective_combinator() {
    var code = "export 'a.dart' show A;";
    var parseResult = parseTestCodeWithDiagnostics('''
$code
''');
    var node = parseResult.findNode.singleExportDirective;
    _assertSource(code, node);
  }

  void test_exportDirective_combinators() {
    var code = "export 'a.dart' show A hide B;";
    var parseResult = parseTestCodeWithDiagnostics('''
$code
//                     ^^^^
// [diag.multipleCombinators] At most one 'show' or 'hide' combinator can be used on an import or export directive.
''');
    var node = parseResult.findNode.singleExportDirective;
    _assertSource(code, node);
  }

  void test_exportDirective_configurations() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
export 'foo.dart'
  if (dart.library.io) 'foo_io.dart'
  if (dart.library.html) 'foo_html.dart';
''');
    var node = parseResult.findNode.singleExportDirective;
    _assertSource(
      "export 'foo.dart'"
      " if (dart.library.io) 'foo_io.dart'"
      " if (dart.library.html) 'foo_html.dart';",
      node,
    );
  }

  void test_exportDirective_minimal() {
    var code = "export 'a.dart';";
    var parseResult = parseTestCodeWithDiagnostics(code);
    var node = parseResult.findNode.singleExportDirective;
    _assertSource(code, node);
  }

  void test_exportDirective_withMetadata() {
    var code = '@deprecated export "a.dart";';
    var parseResult = parseTestCodeWithDiagnostics(code);
    var node = parseResult.findNode.singleExportDirective;
    _assertSource(code, node);
  }

  void test_expressionFunctionBody_async() {
    var code = 'async => 0;';
    var parseResult = parseTestCodeWithDiagnostics('''
void f() $code
''');
    var node = parseResult.findNode.singleExpressionFunctionBody;
    _assertSource(code, node);
  }

  void test_expressionFunctionBody_async_star() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f() async* => 0;
//              ^^
// [diag.returnInGenerator] Can't return a value from a generator function that uses the 'async*' or 'sync*' modifier.
''');
    var node = parseResult.findNode.singleExpressionFunctionBody;
    _assertSource('async* => 0;', node);
  }

  void test_expressionFunctionBody_simple() {
    var code = '=> 0;';
    var parseResult = parseTestCodeWithDiagnostics('''
void f() $code
''');
    var node = parseResult.findNode.singleExpressionFunctionBody;
    _assertSource(code, node);
  }

  void test_expressionStatement() {
    var code = '1 + 2;';
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  $code
}
''');
    var node = parseResult.findNode.singleExpressionStatement;
    _assertSource(code, node);
  }

  void test_expressionStatement_patternAssignment() {
    var code = '(a, b) = (3, 4);';
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  var a = 0, b = 0;
  $code
}
''');
    var node = parseResult.findNode.singleExpressionStatement;
    _assertSource(code, node);
  }

  void test_extendsClause() {
    var code = 'extends A';
    var parseResult = parseTestCodeWithDiagnostics('''
class C $code {}
''');
    var node = parseResult.findNode.singleExtendsClause;
    _assertSource(code, node);
  }

  void test_extensionDeclaration_augment() {
    var code = 'augment extension E {}';
    var parseResult = parseTestCodeWithDiagnostics('''
$code
''');
    var node = parseResult.findNode.singleExtensionDeclaration;
    _assertSource(code, node);
  }

  void test_extensionDeclaration_empty() {
    var code = 'extension E on C {}';
    var parseResult = parseTestCodeWithDiagnostics('''
$code
''');
    var node = parseResult.findNode.singleExtensionDeclaration;
    _assertSource(code, node);
  }

  test_extensionDeclaration_emptyBody() {
    var code = 'extension E on C;';
    var parseResult = parseTestCodeWithDiagnostics(code);
    var node = parseResult.findNode.singleExtensionDeclaration;
    _assertSource(code, node);
  }

  void test_extensionDeclaration_multipleMember() {
    var code = 'extension E on C {static var a; static var b;}';
    var parseResult = parseTestCodeWithDiagnostics('''
$code
''');
    var node = parseResult.findNode.singleExtensionDeclaration;
    _assertSource(code, node);
  }

  void test_extensionDeclaration_parameters() {
    var code = 'extension E<T> on C {}';
    var parseResult = parseTestCodeWithDiagnostics('''
$code
''');
    var node = parseResult.findNode.singleExtensionDeclaration;
    _assertSource(code, node);
  }

  void test_extensionDeclaration_singleMember() {
    var code = 'extension E on C {static var a;}';
    var parseResult = parseTestCodeWithDiagnostics('''
$code
''');
    var node = parseResult.findNode.singleExtensionDeclaration;
    _assertSource(code, node);

    // ignore: analyzer_v1_ast_use
    var nodeV1 = parseResult.findNodeV1.singleExtensionDeclaration;
    expect(nodeV1.toSource(), code);
  }

  void test_extensionTypeDeclaration() {
    var code = 'extension type E(int it) {}';
    var parseResult = parseTestCodeWithDiagnostics('''
$code
''');
    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    _assertSource(code, node);
  }

  void test_extensionTypeDeclaration_augment() {
    var code = 'augment extension type E implements I {}';
    var parseResult = parseTestCodeWithDiagnostics('''
$code
''');
    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    _assertSource(code, node);
  }

  test_extensionTypeDeclaration_emptyBody() {
    var code = 'extension type A(int it);';
    var parseResult = parseTestCodeWithDiagnostics(code);
    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    _assertSource(code, node);
  }

  void test_extensionTypeDeclaration_implements() {
    var code = 'extension type E(int it) implements num {}';
    var parseResult = parseTestCodeWithDiagnostics('''
$code
''');
    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    _assertSource(code, node);
  }

  void test_extensionTypeDeclaration_method() {
    var code = 'extension type E(int it) {void foo() {}}';
    var parseResult = parseTestCodeWithDiagnostics('''
$code
''');
    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    _assertSource(code, node);
  }

  test_extensionTypeDeclaration_primaryConstructor_named() {
    var code = 'extension type const A<T>.named(int it) {}';
    var parseResult = parseTestCodeWithDiagnostics(code);
    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    _assertSource(code, node);
  }

  test_extensionTypeDeclaration_primaryConstructor_unnamed() {
    var code = 'extension type A<T>(int it) {}';
    var parseResult = parseTestCodeWithDiagnostics(code);
    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    _assertSource(code, node);

    // ignore: analyzer_v1_ast_use
    var nodeV1 = parseResult.findNodeV1.singleExtensionTypeDeclaration;
    expect(nodeV1.toSource(), code);
  }

  void test_field_initialized() {
    var code = 'foo = bar';
    var parseResult = parseTestCodeWithDiagnostics('''
class A {
  var $code;
}
''');
    var node = parseResult.findNode.singleField;
    _assertSource(code, node);
  }

  void test_field_uninitialized() {
    var code = 'foo';
    var parseResult = parseTestCodeWithDiagnostics('''
class A {
  var $code;
}
''');
    var node = parseResult.findNode.singleField;
    _assertSource(code, node);
  }

  void test_fieldFormalParameter_annotation() {
    var code = '@deprecated this.foo';
    var parseResult = parseTestCodeWithDiagnostics('''
class A {
  final int foo;
  A($code);
}
''');
    var node = parseResult.findNode.singleFieldFormalParameter;
    _assertSource(code, node);
  }

  void test_fieldFormalParameter_functionTyped() {
    var code = 'A this.a(b)';
    var parseResult = parseTestCodeWithDiagnostics('''
class A {
  A($code);
}
''');
    var node = parseResult.findNode.singleFieldFormalParameter;
    _assertSource(code, node);
  }

  void test_fieldFormalParameter_functionTyped_typeParameters() {
    var code = 'A this.a<E, F>(b)';
    var parseResult = parseTestCodeWithDiagnostics('''
class A {
  A($code);
}
''');
    var node = parseResult.findNode.singleFieldFormalParameter;
    _assertSource(code, node);
  }

  void test_fieldFormalParameter_keyword() {
    var code = 'var this.a';
    var parseResult = parseTestCodeWithDiagnostics('''
// %before-language-feature: primary-constructors
class A {
  A($code);
}
''');
    var node = parseResult.findNode.singleFieldFormalParameter;
    _assertSource(code, node);
  }

  void test_fieldFormalParameter_keywordAndType() {
    var code = 'final A this.a';
    var parseResult = parseTestCodeWithDiagnostics('''
// %before-language-feature: primary-constructors
class A {
  A($code);
}
''');
    var node = parseResult.findNode.singleFieldFormalParameter;
    _assertSource(code, node);
  }

  void test_fieldFormalParameter_type() {
    var code = 'A this.a';
    var parseResult = parseTestCodeWithDiagnostics('''
class A {
  A($code);
}
''');
    var node = parseResult.findNode.singleFieldFormalParameter;
    _assertSource(code, node);
  }

  void test_fieldFormalParameter_type_covariant() {
    var code = 'covariant A this.a';
    var parseResult = parseTestCodeWithDiagnostics('''
class A {
  A($code);
}
''');
    var node = parseResult.findNode.singleFieldFormalParameter;
    _assertSource(code, node);
  }

  void test_fieldsDeclaration_abstract() {
    var code = 'abstract var a;';
    var parseResult = parseTestCodeWithDiagnostics('''
class A {
  $code
}
''');
    var node = parseResult.findNode.singleFieldsDeclaration;
    _assertSource(code, node);
  }

  void test_fieldsDeclaration_abstract_external() {
    var parseResult = parseTestCodeWithDiagnostics('''
class A {
  abstract external var a;
//^^^^^^^^
// [diag.abstractExternalField] Fields can't be declared both 'abstract' and 'external'.
}
''');
    var node = parseResult.findNode.singleFieldsDeclaration;
    _assertSource('external abstract var a;', node);
  }

  void test_fieldsDeclaration_abstract_static() {
    var code = 'static abstract var a;';
    var parseResult = parseTestCodeWithDiagnostics('''
class A {
  $code
}
''');
    var node = parseResult.findNode.singleFieldsDeclaration;
    _assertSource(code, node);
  }

  void test_fieldsDeclaration_augment() {
    var code = 'augment var a = 0;';
    var parseResult = parseTestCodeWithDiagnostics('''
augment class A {
  $code
}
''');
    var node = parseResult.findNode.singleFieldsDeclaration;
    _assertSource(code, node);
  }

  void test_fieldsDeclaration_const_type() {
    var code = 'const int a = 0, b = 0;';
    var parseResult = parseTestCodeWithDiagnostics('''
class A {
  $code
}
''');
    var node = parseResult.findNode.singleFieldsDeclaration;
    _assertSource(code, node);
  }

  void test_fieldsDeclaration_covariant() {
    var code = 'covariant var a;';
    var parseResult = parseTestCodeWithDiagnostics('''
class A {
  $code
}
''');
    var node = parseResult.findNode.singleFieldsDeclaration;
    _assertSource(code, node);
  }

  void test_fieldsDeclaration_external() {
    var code = 'external var a;';
    var parseResult = parseTestCodeWithDiagnostics('''
class A {
  $code
}
''');
    var node = parseResult.findNode.singleFieldsDeclaration;
    _assertSource(code, node);
  }

  void test_fieldsDeclaration_final_noType() {
    var code = 'final a = 0, b = 0;';
    var parseResult = parseTestCodeWithDiagnostics('''
class A {
  $code
}
''');
    var node = parseResult.findNode.singleFieldsDeclaration;
    _assertSource(code, node);
  }

  void test_fieldsDeclaration_instance() {
    var code = 'var a;';
    var parseResult = parseTestCodeWithDiagnostics('''
class A {
  $code
}
''');
    var node = parseResult.findNode.singleFieldsDeclaration;
    _assertSource(code, node);
  }

  void test_fieldsDeclaration_static() {
    var code = 'static var a;';
    var parseResult = parseTestCodeWithDiagnostics('''
class A {
  $code
}
''');
    var node = parseResult.findNode.singleFieldsDeclaration;
    _assertSource(code, node);
  }

  void test_fieldsDeclaration_type() {
    var code = 'int a, b;';
    var parseResult = parseTestCodeWithDiagnostics('''
class A {
  $code
}
''');
    var node = parseResult.findNode.singleFieldsDeclaration;
    _assertSource(code, node);

    // ignore: analyzer_v1_ast_use
    var nodeV1 = parseResult.findNodeV1.singleFieldDeclaration;
    expect(nodeV1.toSource(), code);
  }

  void test_fieldsDeclaration_var() {
    var code = 'var a, b;';
    var parseResult = parseTestCodeWithDiagnostics('''
class A {
  $code
}
''');
    var node = parseResult.findNode.singleFieldsDeclaration;
    _assertSource(code, node);
  }

  void test_fieldsDeclaration_withMetadata() {
    var code = '@deprecated var a;';
    var parseResult = parseTestCodeWithDiagnostics('''
class A {
  $code
}
''');
    var node = parseResult.findNode.singleFieldsDeclaration;
    _assertSource(code, node);
  }

  void test_forEachPartsWithIdentifier() {
    var code = 'e in []';
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  for ($code) {}
}
''');
    var node = parseResult.findNode.singleForEachPartsWithIdentifier;
    _assertSource(code, node);
  }

  void test_forEachPartsWithPattern() {
    var code = 'final (a, b) in c';
    var parseResult = parseTestCodeWithDiagnostics('''
void f () {
  for ($code) {}
}
''');
    var node = parseResult.findNode.singleForEachPartsWithPattern;
    _assertSource(code, node);
  }

  void test_forElement() {
    var code = 'for (e in []) 0';
    var parseResult = parseTestCodeWithDiagnostics('''
final v = [ $code ];
''');
    var node = parseResult.findNode.singleForElement;
    _assertSource(code, node);
  }

  void test_formalParameterList_empty() {
    var code = '()';
    var parseResult = parseTestCodeWithDiagnostics('''
void f$code {}
''');
    var node = parseResult.findNode.singleFormalParameterList;
    _assertSource(code, node);
  }

  void test_formalParameterList_n() {
    var code = '({a = 0})';
    var parseResult = parseTestCodeWithDiagnostics('''
void f$code {}
''');
    var node = parseResult.findNode.singleFormalParameterList;
    _assertSource(code, node);
  }

  void test_formalParameterList_namedRequired() {
    var code = '({required a, required int b})';
    var parseResult = parseTestCodeWithDiagnostics('''
void f$code {}
''');
    var node = parseResult.findNode.singleFormalParameterList;
    _assertSource(code, node);
  }

  void test_formalParameterList_nn() {
    var code = '({int a = 0, b = 1})';
    var parseResult = parseTestCodeWithDiagnostics('''
void f$code {}
''');
    var node = parseResult.findNode.singleFormalParameterList;
    _assertSource(code, node);
  }

  void test_formalParameterList_p() {
    var code = '([a = 0])';
    var parseResult = parseTestCodeWithDiagnostics('''
void f$code {}
''');
    var node = parseResult.findNode.singleFormalParameterList;
    _assertSource(code, node);
  }

  void test_formalParameterList_pp() {
    var code = '([a = 0, b = 1])';
    var parseResult = parseTestCodeWithDiagnostics('''
void f$code {}
''');
    var node = parseResult.findNode.singleFormalParameterList;
    _assertSource(code, node);
  }

  void test_formalParameterList_r() {
    var code = '(int a)';
    var parseResult = parseTestCodeWithDiagnostics('''
void f$code {}
''');
    var node = parseResult.findNode.singleFormalParameterList;
    _assertSource(code, node);
  }

  void test_formalParameterList_rn() {
    var code = '(a, {b = 1})';
    var parseResult = parseTestCodeWithDiagnostics('''
void f$code {}
''');
    var node = parseResult.findNode.singleFormalParameterList;
    _assertSource(code, node);
  }

  void test_formalParameterList_rnn() {
    var code = '(a, {b = 1, c = 2})';
    var parseResult = parseTestCodeWithDiagnostics('''
void f$code {}
''');
    var node = parseResult.findNode.singleFormalParameterList;
    _assertSource(code, node);
  }

  void test_formalParameterList_rp() {
    var code = '(a, [b = 1])';
    var parseResult = parseTestCodeWithDiagnostics('''
void f$code {}
''');
    var node = parseResult.findNode.singleFormalParameterList;
    _assertSource(code, node);
  }

  void test_formalParameterList_rpp() {
    var code = '(a, [b = 1, c = 2])';
    var parseResult = parseTestCodeWithDiagnostics('''
void f$code {}
''');
    var node = parseResult.findNode.singleFormalParameterList;
    _assertSource(code, node);
  }

  void test_formalParameterList_rr() {
    var code = '(int a, int b)';
    var parseResult = parseTestCodeWithDiagnostics('''
void f$code {}
''');
    var node = parseResult.findNode.singleFormalParameterList;
    _assertSource(code, node);
  }

  void test_formalParameterList_rrn() {
    var code = '(a, b, {c = 2})';
    var parseResult = parseTestCodeWithDiagnostics('''
void f$code {}
''');
    var node = parseResult.findNode.singleFormalParameterList;
    _assertSource(code, node);
  }

  void test_formalParameterList_rrnn() {
    var code = '(a, b, {c = 2, d = 3})';
    var parseResult = parseTestCodeWithDiagnostics('''
void f$code {}
''');
    var node = parseResult.findNode.singleFormalParameterList;
    _assertSource(code, node);
  }

  void test_formalParameterList_rrp() {
    var code = '(a, b, [c = 2])';
    var parseResult = parseTestCodeWithDiagnostics('''
void f$code {}
''');
    var node = parseResult.findNode.singleFormalParameterList;
    _assertSource(code, node);
  }

  void test_formalParameterList_rrpp() {
    var code = '(a, b, [c = 2, d = 3])';
    var parseResult = parseTestCodeWithDiagnostics('''
void f$code {}
''');
    var node = parseResult.findNode.singleFormalParameterList;
    _assertSource(code, node);
  }

  void test_forPartsWithDeclarations() {
    var code = 'var v = 0; v < 10; v++';
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  for ($code) {}
}
''');
    var node = parseResult.findNode.singleForPartsWithDeclarations;
    _assertSource(code, node);
  }

  void test_forPartsWithExpression() {
    var code = 'v = 0; v < 10; v++';
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  for ($code) {}
}
''');
    var node = parseResult.findNode.singleForPartsWithExpression;
    _assertSource(code, node);
  }

  void test_forPartsWithPattern() {
    var code = 'var (a, b) = (0, 1); a < 10; a++, b++';
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  for ($code) {}
}
''');
    var node = parseResult.findNode.singleForPartsWithPattern;
    _assertSource(code, node);
  }

  void test_forStatement() {
    var code = 'for (var v in [0]) {}';
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  $code
}
''');
    var node = parseResult.findNode.singleForStatement;
    _assertSource(code, node);
  }

  void test_forStatement_c() {
    var code = 'for (; c;) {}';
    var parseResult = parseTestCodeWithDiagnostics('''
void f () {
  $code
}
''');
    var node = parseResult.findNode.singleForStatement;
    _assertSource(code, node);
  }

  void test_forStatement_cu() {
    var code = 'for (; c; u) {}';
    var parseResult = parseTestCodeWithDiagnostics('''
void f () {
  $code
}
''');
    var node = parseResult.findNode.singleForStatement;
    _assertSource(code, node);
  }

  void test_forStatement_e() {
    var code = 'for (e;;) {}';
    var parseResult = parseTestCodeWithDiagnostics('''
void f () {
  $code
}
''');
    var node = parseResult.findNode.singleForStatement;
    _assertSource(code, node);
  }

  void test_forStatement_ec() {
    var code = 'for (e; c;) {}';
    var parseResult = parseTestCodeWithDiagnostics('''
void f () {
  $code
}
''');
    var node = parseResult.findNode.singleForStatement;
    _assertSource(code, node);
  }

  void test_forStatement_ecu() {
    var code = 'for (e; c; u) {}';
    var parseResult = parseTestCodeWithDiagnostics('''
void f () {
  $code
}
''');
    var node = parseResult.findNode.singleForStatement;
    _assertSource(code, node);
  }

  void test_forStatement_eu() {
    var code = 'for (e;; u) {}';
    var parseResult = parseTestCodeWithDiagnostics('''
void f () {
  $code
}
''');
    var node = parseResult.findNode.singleForStatement;
    _assertSource(code, node);
  }

  void test_forStatement_forEach_declared() {
    var code = 'for (final a in b) {}';
    var parseResult = parseTestCodeWithDiagnostics('''
void f () {
  $code
}
''');
    var node = parseResult.findNode.singleForStatement;
    _assertSource(code, node);
  }

  void test_forStatement_forEach_variable() {
    var code = 'for (a in b) {}';
    var parseResult = parseTestCodeWithDiagnostics('''
void f () {
  $code
}
''');
    var node = parseResult.findNode.singleForStatement;
    _assertSource(code, node);
  }

  void test_forStatement_forEach_variable_await() {
    var code = 'await for (final a in b) {}';
    var parseResult = parseTestCodeWithDiagnostics('''
void f() async {
  $code
}
''');
    var node = parseResult.findNode.singleForStatement;
    _assertSource(code, node);
  }

  void test_forStatement_i() {
    var code = 'for (var i;;) {}';
    var parseResult = parseTestCodeWithDiagnostics('''
void f () {
  $code
}
''');
    var node = parseResult.findNode.singleForStatement;
    _assertSource(code, node);
  }

  void test_forStatement_ic() {
    var code = 'for (var i; c;) {}';
    var parseResult = parseTestCodeWithDiagnostics('''
void f () {
  $code
}
''');
    var node = parseResult.findNode.singleForStatement;
    _assertSource(code, node);
  }

  void test_forStatement_icu() {
    var code = 'for (var i; c; u) {}';
    var parseResult = parseTestCodeWithDiagnostics('''
void f () {
  $code
}
''');
    var node = parseResult.findNode.singleForStatement;
    _assertSource(code, node);
  }

  void test_forStatement_iu() {
    var code = 'for (var i;; u) {}';
    var parseResult = parseTestCodeWithDiagnostics('''
void f () {
  $code
}
''');
    var node = parseResult.findNode.singleForStatement;
    _assertSource(code, node);
  }

  void test_forStatement_u() {
    var code = 'for (;; u) {}';
    var parseResult = parseTestCodeWithDiagnostics('''
void f () {
  $code
}
''');
    var node = parseResult.findNode.singleForStatement;
    _assertSource(code, node);
  }

  void test_functionExpression() {
    var code = '() {}';
    var parseResult = parseTestCodeWithDiagnostics('''
final f = $code;
''');
    var node = parseResult.findNode.singleFunctionExpression;
    _assertSource(code, node);
  }

  void test_functionExpression_typeParameters() {
    var code = '<T>() {}';
    var parseResult = parseTestCodeWithDiagnostics('''
final f = $code;
''');
    var node = parseResult.findNode.singleFunctionExpression;
    _assertSource(code, node);
  }

  void test_functionTypeAlias_generic() {
    var code = 'typedef A F<B>();';
    var parseResult = parseTestCodeWithDiagnostics('''
$code
''');
    var node = parseResult.findNode.singleFunctionTypeAlias;
    _assertSource(code, node);
  }

  void test_functionTypeAlias_nonGeneric() {
    var code = 'typedef A F();';
    var parseResult = parseTestCodeWithDiagnostics('''
$code
''');
    var node = parseResult.findNode.singleFunctionTypeAlias;
    _assertSource(code, node);
  }

  void test_functionTypeAlias_withMetadata() {
    var code = '@deprecated typedef void F();';
    var parseResult = parseTestCodeWithDiagnostics(code);
    var node = parseResult.findNode.singleFunctionTypeAlias;
    _assertSource(code, node);
  }

  void test_genericFunctionType() {
    var code = 'int Function<T>(T)';
    var parseResult = parseTestCodeWithDiagnostics('''
void f($code x) {}
''');
    var node = parseResult.findNode.singleGenericFunctionType;
    _assertSource(code, node);
  }

  void test_genericFunctionType_withQuestion() {
    var code = 'int Function<T>(T)?';
    var parseResult = parseTestCodeWithDiagnostics('''
void f($code x) {}
''');
    var node = parseResult.findNode.singleGenericFunctionType;
    _assertSource(code, node);
  }

  void test_genericTypeAlias() {
    var code = 'typedef X<S> = S Function<T>(T);';
    var parseResult = parseTestCodeWithDiagnostics('''
$code
''');
    var node = parseResult.findNode.singleGenericTypeAlias;
    _assertSource(code, node);
  }

  void test_getterDeclaration() {
    var code = 'get foo => 0;';
    var parseResult = parseTestCodeWithDiagnostics('''
class A {
  $code
}
''');
    var node = parseResult.findNode.singleGetterDeclaration;
    _assertSource(code, node);
  }

  void test_getterDeclaration_returnType() {
    var code = 'int get foo => 0;';
    var parseResult = parseTestCodeWithDiagnostics('''
class A {
  $code
}
''');
    var node = parseResult.findNode.singleGetterDeclaration;
    _assertSource(code, node);
  }

  void test_guardedPattern() {
    var code = 'var y when y > 0';
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  switch (x) {
    case var y when y > 0:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern;
    _assertSource(code, node);
  }

  void test_hideCombinator_multiple() {
    var code = 'hide A, B';
    var parseResult = parseTestCodeWithDiagnostics('''
import 'a.dart' $code;
''');
    var node = parseResult.findNode.singleHideCombinator;
    _assertSource(code, node);
  }

  void test_hideCombinator_single() {
    var code = 'hide A';
    var parseResult = parseTestCodeWithDiagnostics('''
import 'a.dart' $code;
''');
    var node = parseResult.findNode.singleHideCombinator;
    _assertSource(code, node);
  }

  void test_ifElement_else() {
    var code = 'if (b) 1 else 0';
    var parseResult = parseTestCodeWithDiagnostics('''
final v = [ $code ];
''');
    var node = parseResult.findNode.singleIfElement;
    _assertSource(code, node);
  }

  void test_ifElement_then() {
    var code = 'if (b) 1';
    var parseResult = parseTestCodeWithDiagnostics('''
final v = [ $code ];
''');
    var node = parseResult.findNode.singleIfElement;
    _assertSource(code, node);
  }

  void test_ifNull() {
    var parseResult = parseTestCodeWithDiagnostics('''
final x = a ?? (b ?? c);
''');
    var node = parseResult.findNode.ifNull('a ??');
    _assertSource('a ?? (b ?? c)', node);
  }

  void test_ifNullAssignment() {
    var code = 'a ??= b';
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  $code;
}
''');
    var node = parseResult.findNode.singleIfNullAssignment;
    _assertSource(code, node);
  }

  void test_ifStatement_withElse() {
    var code = 'if (c) {} else {}';
    var parseResult = parseTestCodeWithDiagnostics('''
void f () {
  $code
}
''');
    var node = parseResult.findNode.singleIfStatement;
    _assertSource(code, node);
  }

  void test_ifStatement_withoutElse() {
    var code = 'if (c) {}';
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  $code
}
''');
    var node = parseResult.findNode.singleIfStatement;
    _assertSource(code, node);
  }

  void test_implementsClause_multiple() {
    var code = 'implements A, B';
    var parseResult = parseTestCodeWithDiagnostics('''
class C $code {}
''');
    var node = parseResult.findNode.singleImplementsClause;
    _assertSource(code, node);
  }

  void test_implementsClause_single() {
    var code = 'implements A';
    var parseResult = parseTestCodeWithDiagnostics('''
class C $code {}
''');
    var node = parseResult.findNode.singleImplementsClause;
    _assertSource(code, node);
  }

  void test_importDirective_combinator() {
    var code = "import 'a.dart' show A;";
    var parseResult = parseTestCodeWithDiagnostics('''
$code
''');
    var node = parseResult.findNode.singleImportDirective;
    _assertSource(code, node);
  }

  void test_importDirective_combinators() {
    var code = "import 'a.dart' show A hide B;";
    var parseResult = parseTestCodeWithDiagnostics('''
$code
//                     ^^^^
// [diag.multipleCombinators] At most one 'show' or 'hide' combinator can be used on an import or export directive.
''');
    var node = parseResult.findNode.singleImportDirective;
    _assertSource(code, node);
  }

  void test_importDirective_configurations() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
import 'foo.dart'
  if (dart.library.io) 'foo_io.dart'
  if (dart.library.html) 'foo_html.dart';
''');
    var node = parseResult.findNode.singleImportDirective;
    _assertSource(
      "import 'foo.dart'"
      " if (dart.library.io) 'foo_io.dart'"
      " if (dart.library.html) 'foo_html.dart';",
      node,
    );
  }

  void test_importDirective_deferred() {
    var code = "import 'a.dart' deferred as p;";
    var parseResult = parseTestCodeWithDiagnostics(code);
    var node = parseResult.findNode.singleImportDirective;
    _assertSource(code, node);
  }

  void test_importDirective_minimal() {
    var code = "import 'a.dart';";
    var parseResult = parseTestCodeWithDiagnostics(code);
    var node = parseResult.findNode.singleImportDirective;
    _assertSource(code, node);
  }

  void test_importDirective_prefix() {
    var code = "import 'a.dart' as p;";
    var parseResult = parseTestCodeWithDiagnostics(code);
    var node = parseResult.findNode.singleImportDirective;
    _assertSource(code, node);
  }

  void test_importDirective_prefix_combinator() {
    var code = "import 'a.dart' as p show A;";
    var parseResult = parseTestCodeWithDiagnostics('''
$code
''');
    var node = parseResult.findNode.singleImportDirective;
    _assertSource(code, node);
  }

  void test_importDirective_prefix_combinators() {
    var code = "import 'a.dart' as p show A hide B;";
    var parseResult = parseTestCodeWithDiagnostics('''
$code
//                          ^^^^
// [diag.multipleCombinators] At most one 'show' or 'hide' combinator can be used on an import or export directive.
''');
    var node = parseResult.findNode.singleImportDirective;
    _assertSource(code, node);
  }

  void test_importDirective_withMetadata() {
    var code = '@deprecated import "a.dart";';
    var parseResult = parseTestCodeWithDiagnostics(code);
    var node = parseResult.findNode.singleImportDirective;
    _assertSource(code, node);
  }

  void test_incrementOrDecrementExpression() {
    var code = 'a++';
    var parseResult = parseTestCodeWithDiagnostics('''
int f() {
  $code;
}
''');
    var node = parseResult.findNode.singleIncrementOrDecrement;
    _assertSource(code, node);
  }

  void test_integerLiteral() {
    var code = '42';
    var parseResult = parseTestCodeWithDiagnostics('''
final x = $code;
''');
    var node = parseResult.findNode.singleIntegerLiteral;
    _assertSource(code, node);
  }

  void test_interpolationExpression_expression() {
    var code = r'${foo}';
    var parseResult = parseTestCodeWithDiagnostics('''
final x = "$code";
''');
    var node = parseResult.findNode.singleInterpolationExpression;
    _assertSource(code, node);
  }

  void test_interpolationExpression_identifier() {
    var code = r'$foo';
    var parseResult = parseTestCodeWithDiagnostics('''
final x = "$code";
''');
    var node = parseResult.findNode.singleInterpolationExpression;
    _assertSource(code, node);
  }

  void test_interpolationString() {
    var code = "ccc'";
    var parseResult = parseTestCodeWithDiagnostics('''
final x = 'a\${bb}$code;
''');
    var node = parseResult.findNode.interpolationString(code);
    _assertSource(code, node);
  }

  void test_isExpression_negated() {
    var code = 'a is! int';
    var parseResult = parseTestCodeWithDiagnostics('''
final x = $code;
''');
    var node = parseResult.findNode.singleIsExpression;
    _assertSource(code, node);
  }

  void test_isExpression_normal() {
    var code = 'a is int';
    var parseResult = parseTestCodeWithDiagnostics('''
final x = $code;
''');
    var node = parseResult.findNode.singleIsExpression;
    _assertSource(code, node);
  }

  void test_label() {
    var code = 'myLabel:';
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  $code for (final x in []) {}
}
''');
    var node = parseResult.findNode.singleLabel;
    _assertSource(code, node);
  }

  void test_labeledStatement_multiple() {
    var code = 'a: b: return;';
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  $code
}
''');
    var node = parseResult.findNode.singleLabeledStatement;
    _assertSource(code, node);
  }

  void test_labeledStatement_single() {
    var code = 'a: return;';
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  $code
}
''');
    var node = parseResult.findNode.singleLabeledStatement;
    _assertSource(code, node);
  }

  void test_libraryDirective() {
    var code = 'library my;';
    var parseResult = parseTestCodeWithDiagnostics('''
$code
''');
    var node = parseResult.findNode.singleLibraryDirective;
    _assertSource(code, node);
  }

  void test_libraryDirective_withMetadata() {
    var code = '@deprecated library my;';
    var parseResult = parseTestCodeWithDiagnostics(code);
    var node = parseResult.findNode.singleLibraryDirective;
    _assertSource(code, node);
  }

  void test_listLiteral_complex() {
    var code = '<int>[0, for (e in []) 0, if (b) 1, ...[0]]';
    var parseResult = parseTestCodeWithDiagnostics('''
final v = $code;
''');
    var node = parseResult.findNode.listLiteral(code);
    _assertSource(code, node);
  }

  void test_listLiteral_const() {
    var code = 'const []';
    var parseResult = parseTestCodeWithDiagnostics('''
final x = $code;
''');
    var node = parseResult.findNode.singleListLiteral;
    _assertSource(code, node);
  }

  void test_listLiteral_empty() {
    var code = '[]';
    var parseResult = parseTestCodeWithDiagnostics('''
final x = $code;
''');
    var node = parseResult.findNode.singleListLiteral;
    _assertSource(code, node);
  }

  void test_listLiteral_nonEmpty() {
    var code = '[0, 1, 2]';
    var parseResult = parseTestCodeWithDiagnostics('''
final x = $code;
''');
    var node = parseResult.findNode.singleListLiteral;
    _assertSource(code, node);
  }

  void test_listLiteral_withConst_withoutTypeArgs() {
    var code = 'const [0]';
    var parseResult = parseTestCodeWithDiagnostics('''
final x = $code;
''');
    var node = parseResult.findNode.singleListLiteral;
    _assertSource(code, node);
  }

  void test_listLiteral_withConst_withTypeArgs() {
    var code = 'const <int>[0]';
    var parseResult = parseTestCodeWithDiagnostics('''
final x = $code;
''');
    var node = parseResult.findNode.singleListLiteral;
    _assertSource(code, node);
  }

  void test_listLiteral_withoutConst_withoutTypeArgs() {
    var code = '[0]';
    var parseResult = parseTestCodeWithDiagnostics('''
final x = $code;
''');
    var node = parseResult.findNode.singleListLiteral;
    _assertSource(code, node);
  }

  void test_listLiteral_withoutConst_withTypeArgs() {
    var code = '<int>[0]';
    var parseResult = parseTestCodeWithDiagnostics('''
final x = $code;
''');
    var node = parseResult.findNode.singleListLiteral;
    _assertSource(code, node);
  }

  void test_listPattern_empty() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case []:
      break;
  }
}
''');
    var node = parseResult.findNode.singleListPattern;
    _assertSource('[]', node);
  }

  void test_listPattern_nonEmpty() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case [1, 2]:
      break;
  }
}
''');
    var node = parseResult.findNode.singleListPattern;
    _assertSource('[1, 2]', node);
  }

  void test_listPattern_withTypeArguments() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case <int>[]:
      break;
  }
}
''');
    var node = parseResult.findNode.singleListPattern;
    _assertSource('<int>[]', node);
  }

  void test_localFunctionDeclaration_blockBody() {
    var code = 'void foo() {}';
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  $code
}
''');
    var node = parseResult.findNode.localFunctionDeclaration(code);
    _assertSource(code, node);
  }

  void test_localFunctionDeclaration_expressionBody() {
    var code = 'int foo() => 42;';
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  $code
}
''');
    var node = parseResult.findNode.localFunctionDeclaration(code);
    _assertSource(code, node);

    // ignore: analyzer_v1_ast_use
    var declarationV1 = parseResult.findNodeV1.functionDeclaration('foo()');
    var functionV1 = declarationV1.functionExpression;
    expect(functionV1.toSource(), '() => 42;');
  }

  void test_localVariable_initialized() {
    var code = 'foo = bar';
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  var $code;
}
''');
    var node = parseResult.findNode.singleLocalVariable;
    _assertSource(code, node);
  }

  void test_localVariable_uninitialized() {
    var code = 'foo';
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  var $code;
}
''');
    var node = parseResult.findNode.singleLocalVariable;
    _assertSource(code, node);
  }

  void test_localVariablesDeclaration() {
    var code = 'int a';
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  $code;
}
''');
    var node = parseResult.findNode.singleLocalVariablesDeclaration;
    _assertSource(code, node);
  }

  void test_localVariablesDeclaration_late_final_metadata() {
    var code = '@a late final int x = 0, y = 1';
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  $code;
}
''');
    var node = parseResult.findNode.singleLocalVariablesDeclaration;
    _assertSource(code, node);

    // ignore: analyzer_v1_ast_use
    var nodeV1 = parseResult.findNodeV1.singleVariableDeclarationList;
    expect(nodeV1.toSource(), code);
  }

  void test_localVariablesDeclarationStatement() {
    var code = 'int a;';
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  $code
}
''');
    var node = parseResult.findNode.singleLocalVariablesDeclarationStatement;
    _assertSource(code, node);
  }

  void test_logicalAnd() {
    var parseResult = parseTestCodeWithDiagnostics('''
final x = a && (b || c);
''');
    var node = parseResult.findNode.singleLogicalAnd;
    _assertSource('a && (b || c)', node);
  }

  void test_logicalAndPattern() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case int? _ && double? _ && Object? _:
      break;
  }
}
''');
    var node = parseResult.findNode.logicalAndPattern('Object?');
    _assertSource('int? _ && double? _ && Object? _', node);
  }

  void test_logicalNot_precedence() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var v = !(a == b);
''');
    var node = parseResult.findNode.singleLogicalNot;
    _assertSource('!(a == b)', node);
  }

  void test_logicalOr() {
    var parseResult = parseTestCodeWithDiagnostics('''
final x = a || b && c;
''');
    var node = parseResult.findNode.singleLogicalOr;
    _assertSource('a || b && c', node);
  }

  void test_logicalOrPattern() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case int? _ || double? _ || Object? _:
      break;
  }
}
''');
    var node = parseResult.findNode.logicalOrPattern('Object?');
    _assertSource('int? _ || double? _ || Object? _', node);
  }

  void test_mapLiteralEntry() {
    var code = '0 : a';
    var parseResult = parseTestCodeWithDiagnostics('''
final x = {$code};
''');
    var node = parseResult.findNode.singleMapLiteralEntry;
    _assertSource(code, node);
  }

  void test_mapLiteralEntry_nullAwareKey() {
    var code = '?a : 0';
    var parseResult = parseTestCodeWithDiagnostics('''
final x = {$code};
''');
    var node = parseResult.findNode.singleMapLiteralEntry;
    _assertSource(code, node);
  }

  void test_mapLiteralEntry_nullAwareValue() {
    var code = '0 : ?a';
    var parseResult = parseTestCodeWithDiagnostics('''
final x = {$code};
''');
    var node = parseResult.findNode.singleMapLiteralEntry;
    _assertSource(code, node);
  }

  void test_mapPattern_empty() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case {}:
      break;
  }
}
''');
    var node = parseResult.findNode.singleMapPattern;
    _assertSource('{}', node);
  }

  void test_mapPattern_notEmpty() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case {1: 2}:
      break;
  }
}
''');
    var node = parseResult.findNode.singleMapPattern;
    _assertSource('{1: 2}', node);
  }

  void test_mapPattern_withTypeArguments() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case <int, int>{}:
      break;
  }
}
''');
    var node = parseResult.findNode.singleMapPattern;
    _assertSource('<int, int>{}', node);
  }

  void test_mapPatternEntry() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case {1: 2}:
      break;
  }
}
''');
    var node = parseResult.findNode.singleMapPatternEntry;
    _assertSource('1: 2', node);
  }

  void test_methodDeclaration_augment() {
    var code = 'augment void foo() {}';
    var parseResult = parseTestCodeWithDiagnostics('''
class A {
  $code
}
''');
    var node = parseResult.findNode.singleMethodDeclaration;
    _assertSource(code, node);
  }

  void test_methodDeclaration_external() {
    var code = 'external foo();';
    var parseResult = parseTestCodeWithDiagnostics('''
class A {
  $code
}
''');
    var node = parseResult.findNode.singleMethodDeclaration;
    _assertSource(code, node);
  }

  void test_methodDeclaration_external_returnType() {
    var code = 'external int foo();';
    var parseResult = parseTestCodeWithDiagnostics('''
class A {
  $code
}
''');
    var node = parseResult.findNode.singleMethodDeclaration;
    _assertSource(code, node);
  }

  void test_methodDeclaration_minimal() {
    var code = 'foo() {}';
    var parseResult = parseTestCodeWithDiagnostics('''
class A {
  $code
}
''');
    var node = parseResult.findNode.singleMethodDeclaration;
    _assertSource(code, node);
  }

  void test_methodDeclaration_multipleParameters() {
    var code = 'void foo(int a, double b) {}';
    var parseResult = parseTestCodeWithDiagnostics('''
class A {
  $code
}
''');
    var node = parseResult.findNode.singleMethodDeclaration;
    _assertSource(code, node);
  }

  void test_methodDeclaration_returnType() {
    var code = 'int foo() => 0;';
    var parseResult = parseTestCodeWithDiagnostics('''
class A {
  $code
}
''');
    var node = parseResult.findNode.singleMethodDeclaration;
    _assertSource(code, node);
  }

  void test_methodDeclaration_static() {
    var code = 'static foo() {}';
    var parseResult = parseTestCodeWithDiagnostics('''
class A {
  $code
}
''');
    var node = parseResult.findNode.singleMethodDeclaration;
    _assertSource(code, node);
  }

  void test_methodDeclaration_static_returnType() {
    var code = 'static void foo() {}';
    var parseResult = parseTestCodeWithDiagnostics('''
class A {
  $code
}
''');
    var node = parseResult.findNode.singleMethodDeclaration;
    _assertSource(code, node);
  }

  void test_methodDeclaration_typeParameters() {
    var code = 'void foo<T>() {}';
    var parseResult = parseTestCodeWithDiagnostics('''
class A {
  $code
}
''');
    var node = parseResult.findNode.singleMethodDeclaration;
    _assertSource(code, node);
  }

  void test_methodDeclaration_withMetadata() {
    var code = '@deprecated void foo() {}';
    var parseResult = parseTestCodeWithDiagnostics('''
class A {
  $code
}
''');
    var node = parseResult.findNode.singleMethodDeclaration;
    _assertSource(code, node);
  }

  void test_mixinDeclaration_augment() {
    var code = 'augment mixin M {}';
    var parseResult = parseTestCodeWithDiagnostics(code);
    var node = parseResult.findNode.singleMixinDeclaration;
    _assertSource(code, node);
  }

  void test_mixinDeclaration_augment_base() {
    var code = 'augment base mixin M {}';
    var parseResult = parseTestCodeWithDiagnostics(code);
    var node = parseResult.findNode.singleMixinDeclaration;
    _assertSource(code, node);
  }

  void test_mixinDeclaration_base() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
base mixin M {}
''');
    var node = parseResult.findNode.singleMixinDeclaration;
    _assertSource('base mixin M {}', node);

    // ignore: analyzer_v1_ast_use
    var nodeV1 = parseResult.findNodeV1.singleMixinDeclaration;
    expect(nodeV1.toSource(), 'base mixin M {}');
  }

  test_mixinDeclaration_emptyBody() {
    var code = 'mixin M;';
    var parseResult = parseTestCodeWithDiagnostics(code);
    var node = parseResult.findNode.singleMixinDeclaration;
    _assertSource(code, node);
  }

  void test_namedArgument() {
    var code = 'a: 0';
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  foo($code);
}
''');
    var node = parseResult.findNode.singleNamedArgument;
    _assertSource(code, node);
  }

  void test_namedType_multipleArgs() {
    var code = 'Map<int, String>';
    var parseResult = parseTestCodeWithDiagnostics('''
final x = <$code>[];
''');
    var node = parseResult.findNode.namedType(code);
    _assertSource(code, node);
  }

  void test_namedType_nestedArg() {
    var code = 'List<Set<int>>';
    var parseResult = parseTestCodeWithDiagnostics('''
final x = <$code>[];
''');
    var node = parseResult.findNode.namedType(code);
    _assertSource(code, node);
  }

  void test_namedType_noArgs() {
    var code = 'int';
    var parseResult = parseTestCodeWithDiagnostics('''
final x = <$code>[];
''');
    var node = parseResult.findNode.singleNamedType;
    _assertSource(code, node);
  }

  void test_namedType_noArgs_withQuestion() {
    var code = 'int?';
    var parseResult = parseTestCodeWithDiagnostics('''
final x = <$code>[];
''');
    var node = parseResult.findNode.singleNamedType;
    _assertSource(code, node);
  }

  void test_namedType_singleArg() {
    var code = 'Set<int>';
    var parseResult = parseTestCodeWithDiagnostics('''
final x = <$code>[];
''');
    var node = parseResult.findNode.namedType(code);
    _assertSource(code, node);
  }

  void test_namedType_singleArg_withQuestion() {
    var code = 'Set<int>?';
    var parseResult = parseTestCodeWithDiagnostics('''
final x = <$code>[];
''');
    var node = parseResult.findNode.namedType(code);
    _assertSource(code, node);
  }

  void test_nativeClause() {
    var code = "native 'code'";
    var parseResult = parseTestCodeWithDiagnostics('''
class A $code {}
''');
    var node = parseResult.findNode.singleNativeClause;
    _assertSource(code, node);
  }

  void test_nativeFunctionBody() {
    var code = "native 'code';";
    var parseResult = parseTestCodeWithDiagnostics('''
void foo() $code
''');
    var node = parseResult.findNode.singleNativeFunctionBody;
    _assertSource(code, node);
  }

  void test_nullAssertPattern_ifCase() {
    var code = 'y!';
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  if (x case $code) {}
}
''');
    var node = parseResult.findNode.singleNullAssertPattern;
    _assertSource(code, node);
  }

  void test_nullAssertPattern_switchCase() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case true!:
      break;
  }
}
''');
    var node = parseResult.findNode.singleNullAssertPattern;
    _assertSource('true!', node);
  }

  void test_nullCheckPattern() {
    var code = '_?';
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  if (x case $code) {}
}
''');
    var node = parseResult.findNode.singleNullCheckPattern;
    _assertSource(code, node);
  }

  void test_nullLiteral() {
    var code = 'null';
    var parseResult = parseTestCodeWithDiagnostics('''
final x = $code;
''');
    var node = parseResult.findNode.singleNullLiteral;
    _assertSource(code, node);
  }

  void test_objectPattern() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case C(f: 1):
      break;
  }
}
''');
    var node = parseResult.findNode.singleObjectPattern;
    _assertSource('C(f: 1)', node);
  }

  void test_operatorDeclaration() {
    var code = 'operator +(int other) {}';
    var parseResult = parseTestCodeWithDiagnostics('''
class A {
  $code
}
''');
    var node = parseResult.findNode.singleOperatorDeclaration;
    _assertSource(code, node);
  }

  void test_operatorDeclaration_returnType() {
    var code = 'int operator +(int other) => 0;';
    var parseResult = parseTestCodeWithDiagnostics('''
class A {
  $code
}
''');
    var node = parseResult.findNode.singleOperatorDeclaration;
    _assertSource(code, node);
  }

  void test_parenthesizedExpression() {
    var code = '(a)';
    var parseResult = parseTestCodeWithDiagnostics('''
final x = $code;
''');
    var node = parseResult.findNode.singleParenthesizedExpression;
    _assertSource(code, node);
  }

  void test_parenthesizedPattern() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case (3):
      break;
  }
}
''');
    var node = parseResult.findNode.singleParenthesizedPattern;
    _assertSource('(3)', node);
  }

  void test_parsedNameAccess() {
    var code = 'foo.bar';
    var parseResult = parseTestCodeWithDiagnostics('''
int f() {
  $code;
}
''');
    var node = parseResult.findNode.parsedNameAccess(code);
    _assertSource(code, node);
  }

  void test_parsedNameAccess_dotShorthandName() {
    var code = '.foo.bar';
    var parseResult = parseTestCodeWithDiagnostics('''
final x = $code;
''');
    var node = parseResult.findNode.parsedNameAccess(code);
    _assertSource(code, node);

    // ignore: analyzer_v1_ast_use
    var propertyV1 = parseResult.findNodeV1.singleDotShorthandPropertyAccess;
    expect(propertyV1.toSource(), '.foo');
  }

  void test_parsedNameAccess_dotShorthandValueArguments() {
    var code = '.foo<int>(0, 1).bar';
    var parseResult = parseTestCodeWithDiagnostics('''
final x = $code;
''');
    var node = parseResult.findNode.parsedNameAccess(code);
    _assertSource(code, node);

    // ignore: analyzer_v1_ast_use
    var invocationV1 = parseResult.findNodeV1.singleDotShorthandInvocation;
    expect(invocationV1.toSource(), '.foo<int>(0, 1)');
  }

  void test_parsedNameAccess_nullAware() {
    var code = 'foo?.bar';
    var parseResult = parseTestCodeWithDiagnostics('''
final x = $code;
''');
    var node = parseResult.findNode.parsedNameAccess(code);
    _assertSource(code, node);
  }

  void test_parsedNameAccess_valueArguments() {
    var code = 'a.foo().bar';
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  $code;
}
''');
    var node = parseResult.findNode.parsedNameAccess('.bar');
    _assertSource(code, node);

    // ignore: analyzer_v1_ast_use
    var invocationV1 = parseResult.findNodeV1.singleMethodInvocation;
    expect(invocationV1.toSource(), 'a.foo()');
  }

  void test_parsedValueArguments_dotShorthand() {
    var code = '.foo<int>(0, 1)';
    var parseResult = parseTestCodeWithDiagnostics('''
final x = $code;
''');
    var node = parseResult.findNode.parsedValueArguments(code);
    _assertSource(code, node);

    // ignore: analyzer_v1_ast_use
    var nodeV1 = parseResult.findNodeV1.singleDotShorthandInvocation;
    expect(nodeV1.toSource(), code);
  }

  void test_parsedValueArguments_nameAccess() {
    var code = 'a.foo()';
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  $code;
}
''');
    var node = parseResult.findNode.parsedValueArguments(code);
    _assertSource(code, node);

    // ignore: analyzer_v1_ast_use
    var nodeV1 = parseResult.findNodeV1.singleMethodInvocation;
    expect(nodeV1.toSource(), code);
  }

  void test_parsedValueArguments_nullAwareNameAccess() {
    var code = 'a?.foo()';
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  $code;
}
''');
    var node = parseResult.findNode.parsedValueArguments(code);
    _assertSource(code, node);
  }

  void test_parsedValueArguments_typeArguments() {
    var code = 'foo<int>()';
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  $code;
}
''');
    var node = parseResult.findNode.parsedValueArguments(code);
    _assertSource(code, node);
  }

  void test_parsedValueArguments_unqualified() {
    var code = 'foo()';
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  $code;
}
''');
    var node = parseResult.findNode.parsedValueArguments(code);
    _assertSource(code, node);
  }

  void test_partDirective() {
    var code = "part 'a.dart';";
    var parseResult = parseTestCodeWithDiagnostics(code);
    var node = parseResult.findNode.singlePartDirective;
    _assertSource(code, node);
  }

  void test_partDirective_withMetadata() {
    var code = '@deprecated part "a.dart";';
    var parseResult = parseTestCodeWithDiagnostics(code);
    var node = parseResult.findNode.singlePartDirective;
    _assertSource(code, node);
  }

  void test_partOfDirective_name() {
    var parseResult = parseTestCodeWithDiagnostics(
      'part of l;',
      featureSet: FeatureSets.language_3_4,
    );
    var node = parseResult.findNode.singlePartOfDirective;
    _assertSource("part of l;", node);
  }

  void test_partOfDirective_uri() {
    var parseResult = parseTestCodeWithDiagnostics("part of 'a.dart';");
    var node = parseResult.findNode.singlePartOfDirective;
    _assertSource("part of 'a.dart';", node);
  }

  void test_partOfDirective_withMetadata() {
    var code = "@deprecated part of 'a.dart';";
    var parseResult = parseTestCodeWithDiagnostics(code);
    var node = parseResult.findNode.singlePartOfDirective;
    _assertSource(code, node);
  }

  void test_patternAssignment() {
    var code = '(a, b) = (3, 4)';
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  var a = 0, b = 0;
  $code;
}
''');
    var node = parseResult.findNode.singlePatternAssignment;
    _assertSource(code, node);
  }

  void test_patternField_named() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case (a: 1):
      break;
  }
}
''');
    var node = parseResult.findNode.singlePatternField;
    _assertSource('a: 1', node);
  }

  void test_patternField_positional() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case (1,):
      break;
  }
}
''');
    var node = parseResult.findNode.singlePatternField;
    _assertSource('1', node);
  }

  void test_patternFieldName() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case (b: 2):
      break;
  }
}
''');
    var node = parseResult.findNode.singlePatternFieldName;
    _assertSource('b:', node);
  }

  void test_patternVariableDeclaration() {
    var code = 'var (a, b) = (0, 1)';
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  $code;
}
''');
    var node = parseResult.findNode.singlePatternVariableDeclaration;
    _assertSource(code, node);
  }

  void test_patternVariableDeclarationStatement() {
    var code = 'var (a, b) = (0, 1);';
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  $code
}
''');
    var node = parseResult.findNode.singlePatternVariableDeclarationStatement;
    _assertSource(code, node);
  }

  void test_primaryConstructorBody_block() {
    var code = 'this {foo();}';
    var parseResult = parseTestCodeWithDiagnostics('''
class A() {
  $code
}
''');
    var node = parseResult.findNode.singlePrimaryConstructorBody;
    _assertSource(code, node);
  }

  void test_primaryConstructorBody_initializers() {
    var code = 'this : x = 0, y = 1;';
    var parseResult = parseTestCodeWithDiagnostics('''
class A() {
  final int x;
  final int y;
  $code
}
''');
    var node = parseResult.findNode.singlePrimaryConstructorBody;
    _assertSource(code, node);
  }

  void test_primaryConstructorBody_metadata() {
    var code = '@deprecated this;';
    var parseResult = parseTestCodeWithDiagnostics('''
class A() {
  $code
}
''');
    var node = parseResult.findNode.singlePrimaryConstructorBody;
    _assertSource(code, node);
  }

  void test_primaryConstructorBody_simple() {
    var code = 'this;';
    var parseResult = parseTestCodeWithDiagnostics('''
class A() {
  $code
}
''');
    var node = parseResult.findNode.singlePrimaryConstructorBody;
    _assertSource(code, node);
  }

  void test_receiverIndexExpression() {
    var code = 'a[0]';
    var parseResult = parseTestCodeWithDiagnostics('''
final x = $code;
''');
    var node = parseResult.findNode.singleReceiverIndexExpression;
    _assertSource(code, node);

    // ignore: analyzer_v1_ast_use
    var nodeV1 = parseResult.findNodeV1.singleIndexExpression;
    expect(nodeV1.toSource(), code);
  }

  void test_receiverIndexExpression_nullAware() {
    var code = 'a?[0]';
    var parseResult = parseTestCodeWithDiagnostics('''
final x = $code;
''');
    var node = parseResult.findNode.singleReceiverIndexExpression;
    _assertSource(code, node);
  }

  void test_receiverPropertyExtraction() {
    var code = '(foo).bar';
    var parseResult = parseTestCodeWithDiagnostics('''
final x = $code;
''');
    var node = parseResult.findNode.singleReceiverPropertyExtraction;
    _assertSource(code, node);
  }

  void test_recordLiteral_const() {
    var code = 'const (0, a: 1)';
    var parseResult = parseTestCodeWithDiagnostics('''
final x = $code;
''');
    var node = parseResult.findNode.singleRecordLiteral;
    _assertSource(code, node);
  }

  void test_recordLiteral_mixed() {
    var code = '(0, true, a: 0, b: true)';
    var parseResult = parseTestCodeWithDiagnostics('''
final x = $code;
''');
    var node = parseResult.findNode.singleRecordLiteral;
    _assertSource(code, node);
  }

  void test_recordLiteral_named() {
    var code = '(a: 0, b: true)';
    var parseResult = parseTestCodeWithDiagnostics('''
final x = $code;
''');
    var node = parseResult.findNode.singleRecordLiteral;
    _assertSource(code, node);
  }

  void test_recordLiteral_positional() {
    var code = '(0, true)';
    var parseResult = parseTestCodeWithDiagnostics('''
final x = $code;
''');
    var node = parseResult.findNode.singleRecordLiteral;
    _assertSource(code, node);
  }

  void test_recordPattern() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case (1, 2):
      break;
  }
}
''');
    var node = parseResult.findNode.singleRecordPattern;
    _assertSource('(1, 2)', node);
  }

  void test_recordTypeAnnotation_mixed() {
    var code = '(int, bool, {int a, bool b})';
    var parseResult = parseTestCodeWithDiagnostics('''
$code f() {}
''');
    var node = parseResult.findNode.singleRecordTypeAnnotation;
    _assertSource(code, node);
  }

  void test_recordTypeAnnotation_named() {
    var code = '({int a, bool b})';
    var parseResult = parseTestCodeWithDiagnostics('''
$code f() {}
''');
    var node = parseResult.findNode.singleRecordTypeAnnotation;
    _assertSource(code, node);
  }

  void test_recordTypeAnnotation_positional() {
    var code = '(int, bool)';
    var parseResult = parseTestCodeWithDiagnostics('''
$code f() {}
''');
    var node = parseResult.findNode.singleRecordTypeAnnotation;
    _assertSource(code, node);
  }

  void test_recordTypeAnnotation_positional_nullable() {
    var code = '(int, bool)?';
    var parseResult = parseTestCodeWithDiagnostics('''
$code f() {}
''');
    var node = parseResult.findNode.singleRecordTypeAnnotation;
    _assertSource(code, node);
  }

  void test_redirectingConstructorInvocation_named() {
    var code = 'this.named()';
    var parseResult = parseTestCodeWithDiagnostics('''
class A {
  A() : $code;
}
''');
    var node = parseResult.findNode.singleRedirectingConstructorInvocation;
    _assertSource(code, node);
  }

  void test_redirectingConstructorInvocation_unnamed() {
    var code = 'this()';
    var parseResult = parseTestCodeWithDiagnostics('''
class A {
  A.named() : $code;
}
''');
    var node = parseResult.findNode.singleRedirectingConstructorInvocation;
    _assertSource(code, node);
  }

  void test_regularFormalParameter_annotation() {
    var code = '@deprecated int x';
    var parseResult = parseTestCodeWithDiagnostics('''
void f($code) {}
''');
    var node = parseResult.findNode.singleRegularFormalParameter;
    _assertSource(code, node);
  }

  void test_regularFormalParameter_functionTyped_annotation() {
    var code = '@deprecated g()';
    var parseResult = parseTestCodeWithDiagnostics('''
void f($code) {}
''');
    var node = parseResult.findNode.singleRegularFormalParameter;
    _assertSource(code, node);
  }

  void test_regularFormalParameter_functionTyped_noType() {
    var code = 'int f()';
    var parseResult = parseTestCodeWithDiagnostics('''
void f($code) {}
''');
    var node = parseResult.findNode.singleRegularFormalParameter;
    _assertSource(code, node);
  }

  void test_regularFormalParameter_functionTyped_nullable() {
    var code = 'T f()?';
    var parseResult = parseTestCodeWithDiagnostics('''
void f($code) {}
''');
    var node = parseResult.findNode.singleRegularFormalParameter;
    _assertSource(code, node);
  }

  void test_regularFormalParameter_functionTyped_type() {
    var code = 'T f()';
    var parseResult = parseTestCodeWithDiagnostics('''
void f($code) {}
''');
    var node = parseResult.findNode.singleRegularFormalParameter;
    _assertSource(code, node);
  }

  void test_regularFormalParameter_functionTyped_type_covariant() {
    var code = 'covariant T f()?';
    var parseResult = parseTestCodeWithDiagnostics('''
class A {
  void foo($code) {}
}
''');
    var node = parseResult.findNode.singleRegularFormalParameter;
    _assertSource(code, node);
  }

  void test_regularFormalParameter_functionTyped_typeParameters() {
    var code = 'T f<E>()';
    var parseResult = parseTestCodeWithDiagnostics('''
void f($code) {}
''');
    var node = parseResult.findNode.singleRegularFormalParameter;
    _assertSource(code, node);
  }

  void test_regularFormalParameter_keyword() {
    var code = 'var a';
    var parseResult = parseTestCodeWithDiagnostics('''
// %before-language-feature: primary-constructors
void f($code) {}
''');
    var node = parseResult.findNode.singleRegularFormalParameter;
    _assertSource(code, node);
  }

  void test_regularFormalParameter_keywordAndType() {
    var code = 'final int a';
    var parseResult = parseTestCodeWithDiagnostics('''
// %before-language-feature: primary-constructors
void f($code) {}
''');
    var node = parseResult.findNode.singleRegularFormalParameter;
    _assertSource(code, node);
  }

  void test_regularFormalParameter_named_noType() {
    var code = 'a = 0';
    var parseResult = parseTestCodeWithDiagnostics('''
void f({$code}) {}
''');
    var node = parseResult.findNode.singleRegularFormalParameter;
    _assertSource(code, node);
  }

  void test_regularFormalParameter_named_noValue() {
    var code = 'int? a';
    var parseResult = parseTestCodeWithDiagnostics('''
void f({$code}) {}
''');
    var node = parseResult.findNode.singleRegularFormalParameter;
    _assertSource(code, node);
  }

  void test_regularFormalParameter_named_value() {
    var code = 'int? a = 0';
    var parseResult = parseTestCodeWithDiagnostics('''
void f({$code}) {}
''');
    var node = parseResult.findNode.singleRegularFormalParameter;
    _assertSource(code, node);
  }

  void test_regularFormalParameter_positional_annotation() {
    var code = '@deprecated p = 0';
    var parseResult = parseTestCodeWithDiagnostics('''
void f([$code]) {}
''');
    var node = parseResult.findNode.singleRegularFormalParameter;
    _assertSource(code, node);
  }

  void test_regularFormalParameter_positional_noType() {
    var code = 'a = 0';
    var parseResult = parseTestCodeWithDiagnostics('''
void f([$code]) {}
''');
    var node = parseResult.findNode.singleRegularFormalParameter;
    _assertSource(code, node);
  }

  void test_regularFormalParameter_positional_noValue() {
    var code = 'int? a';
    var parseResult = parseTestCodeWithDiagnostics('''
void f([$code]) {}
''');
    var node = parseResult.findNode.singleRegularFormalParameter;
    _assertSource(code, node);
  }

  void test_regularFormalParameter_positional_value() {
    var code = 'int? a = 0';
    var parseResult = parseTestCodeWithDiagnostics('''
void f([$code]) {}
''');
    var node = parseResult.findNode.singleRegularFormalParameter;
    _assertSource(code, node);
  }

  void test_regularFormalParameter_type() {
    var code = 'int a';
    var parseResult = parseTestCodeWithDiagnostics('''
void f($code) {}
''');
    var node = parseResult.findNode.singleRegularFormalParameter;
    _assertSource(code, node);
  }

  void test_regularFormalParameter_type_covariant() {
    var code = 'covariant int a';
    var parseResult = parseTestCodeWithDiagnostics('''
class A {
  void foo($code) {}
}
''');
    var node = parseResult.findNode.singleRegularFormalParameter;
    _assertSource(code, node);
  }

  void test_relationalPattern() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case > 3:
      break;
  }
}
''');
    var node = parseResult.findNode.singleRelationalPattern;
    _assertSource('> 3', node);
  }

  void test_restPatternElement() {
    var code = '...rest';
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  if (x case [0, $code]) {}
}
''');
    var node = parseResult.findNode.singleRestPatternElement;
    _assertSource(code, node);
  }

  void test_rethrowExpression() {
    var code = 'rethrow';
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  try {} on int {
    $code;
  }
}
''');
    var node = parseResult.findNode.singleRethrowExpression;
    _assertSource(code, node);
  }

  void test_returnStatement_expression() {
    var code = 'return 0;';
    var parseResult = parseTestCodeWithDiagnostics('''
int f() {
  $code
}
''');
    var node = parseResult.findNode.singleReturnStatement;
    _assertSource(code, node);
  }

  void test_returnStatement_noExpression() {
    var code = 'return;';
    var parseResult = parseTestCodeWithDiagnostics('''
int f() {
  $code
}
''');
    var node = parseResult.findNode.singleReturnStatement;
    _assertSource(code, node);
  }

  void test_setOrMapLiteral_const() {
    var code = 'const {}';
    var parseResult = parseTestCodeWithDiagnostics('''
final x = $code;
''');
    var node = parseResult.findNode.singleSetOrMapLiteral;
    _assertSource(code, node);
  }

  void test_setOrMapLiteral_empty() {
    var code = '{}';
    var parseResult = parseTestCodeWithDiagnostics('''
final x = $code;
''');
    var node = parseResult.findNode.singleSetOrMapLiteral;
    _assertSource(code, node);
  }

  void test_setOrMapLiteral_map_complex() {
    var code =
        "<String, String>{'a' : 'b', for (c in d) 'e' : 'f', if (g) 'h' : 'i', ...{'j' : 'k'}}";
    var parseResult = parseTestCodeWithDiagnostics('''
final v = $code;
''');
    var node = parseResult.findNode.setOrMapLiteral(code);
    _assertSource(code, node);
  }

  void test_setOrMapLiteral_map_withConst_withoutTypeArgs() {
    var code = 'const {0 : a}';
    var parseResult = parseTestCodeWithDiagnostics('''
final x = $code;
''');
    var node = parseResult.findNode.singleSetOrMapLiteral;
    _assertSource(code, node);
  }

  void test_setOrMapLiteral_map_withConst_withTypeArgs() {
    var code = 'const <int, String>{0 : a}';
    var parseResult = parseTestCodeWithDiagnostics('''
final x = $code;
''');
    var node = parseResult.findNode.singleSetOrMapLiteral;
    _assertSource(code, node);
  }

  void test_setOrMapLiteral_map_withoutConst_withoutTypeArgs() {
    var code = '{0 : a}';
    var parseResult = parseTestCodeWithDiagnostics('''
final x = $code;
''');
    var node = parseResult.findNode.singleSetOrMapLiteral;
    _assertSource(code, node);
  }

  void test_setOrMapLiteral_map_withoutConst_withTypeArgs() {
    var code = '<int, String>{0 : a}';
    var parseResult = parseTestCodeWithDiagnostics('''
final x = $code;
''');
    var node = parseResult.findNode.singleSetOrMapLiteral;
    _assertSource(code, node);
  }

  void test_setOrMapLiteral_nonEmpty() {
    var code = '{0 : a, 1 : b, 2 : c}';
    var parseResult = parseTestCodeWithDiagnostics('''
final x = $code;
''');
    var node = parseResult.findNode.singleSetOrMapLiteral;
    _assertSource(code, node);
  }

  void test_setOrMapLiteral_set_complex() {
    var code = '<int>{0, for (e in l) 0, if (b) 1, ...[0]}';
    var parseResult = parseTestCodeWithDiagnostics('''
final v = $code;
''');
    var node = parseResult.findNode.singleSetOrMapLiteral;
    _assertSource(code, node);
  }

  void test_setOrMapLiteral_set_withConst_withoutTypeArgs() {
    var code = 'const {0}';
    var parseResult = parseTestCodeWithDiagnostics('''
final x = $code;
''');
    var node = parseResult.findNode.singleSetOrMapLiteral;
    _assertSource(code, node);
  }

  void test_setOrMapLiteral_set_withConst_withTypeArgs() {
    var code = 'const <int>{0}';
    var parseResult = parseTestCodeWithDiagnostics('''
final x = $code;
''');
    var node = parseResult.findNode.singleSetOrMapLiteral;
    _assertSource(code, node);
  }

  void test_setOrMapLiteral_set_withoutConst_withoutTypeArgs() {
    var code = '{0}';
    var parseResult = parseTestCodeWithDiagnostics('''
final x = $code;
''');
    var node = parseResult.findNode.singleSetOrMapLiteral;
    _assertSource(code, node);
  }

  void test_setOrMapLiteral_set_withoutConst_withTypeArgs() {
    var code = '<int>{0}';
    var parseResult = parseTestCodeWithDiagnostics('''
final x = $code;
''');
    var node = parseResult.findNode.singleSetOrMapLiteral;
    _assertSource(code, node);
  }

  void test_setterDeclaration() {
    var code = 'set foo(int _) {}';
    var parseResult = parseTestCodeWithDiagnostics('''
class A {
  $code
}
''');
    var node = parseResult.findNode.singleSetterDeclaration;
    _assertSource(code, node);
  }

  void test_setterDeclaration_returnType() {
    var code = 'void set foo(int _) {}';
    var parseResult = parseTestCodeWithDiagnostics('''
class A {
  $code
}
''');
    var node = parseResult.findNode.singleSetterDeclaration;
    _assertSource(code, node);
  }

  void test_showCombinator_multiple() {
    var code = 'show A, B';
    var parseResult = parseTestCodeWithDiagnostics('''
import 'a.dart' $code;
''');
    var node = parseResult.findNode.singleShowCombinator;
    _assertSource(code, node);
  }

  void test_showCombinator_single() {
    var code = 'show A';
    var parseResult = parseTestCodeWithDiagnostics('''
import 'a.dart' $code;
''');
    var node = parseResult.findNode.singleShowCombinator;
    _assertSource(code, node);
  }

  void test_simpleStringLiteral() {
    var code = "'str'";
    var parseResult = parseTestCodeWithDiagnostics('''
final x = $code;
''');
    var node = parseResult.findNode.singleSimpleStringLiteral;
    _assertSource(code, node);
  }

  void test_spreadElement_nonNullable() {
    var code = '...[0]';
    var parseResult = parseTestCodeWithDiagnostics('''
final x = [$code];
''');
    var node = parseResult.findNode.singleSpreadElement;
    _assertSource(code, node);
  }

  void test_spreadElement_nullable() {
    var code = '...?[0]';
    var parseResult = parseTestCodeWithDiagnostics('''
final x = [$code];
''');
    var node = parseResult.findNode.singleSpreadElement;
    _assertSource(code, node);
  }

  void test_stringInterpolation() {
    var code = r"'a${bb}ccc'";
    var parseResult = parseTestCodeWithDiagnostics('''
final x = $code;
''');
    var node = parseResult.findNode.singleStringInterpolation;
    _assertSource(code, node);
  }

  void test_superConstructorInvocation() {
    var code = 'super(0)';
    var parseResult = parseTestCodeWithDiagnostics('''
class A extends B {
  A() : $code;
}
''');
    var node = parseResult.findNode.singleSuperConstructorInvocation;
    _assertSource(code, node);
  }

  void test_superConstructorInvocation_named() {
    var code = 'super.named(0)';
    var parseResult = parseTestCodeWithDiagnostics('''
class A extends B {
  A() : $code;
}
''');
    var node = parseResult.findNode.singleSuperConstructorInvocation;
    _assertSource(code, node);
  }

  void test_superFormalParameter_annotation() {
    var code = '@deprecated super.foo';
    var parseResult = parseTestCodeWithDiagnostics('''
class A {
  A($code);
}
''');
    var node = parseResult.findNode.singleSuperFormalParameter;
    _assertSource(code, node);
  }

  void test_superFormalParameter_functionTyped() {
    var code = 'int super.a(b)';
    var parseResult = parseTestCodeWithDiagnostics('''
class A {
  A($code);
}
''');
    var node = parseResult.findNode.singleSuperFormalParameter;
    _assertSource(code, node);
  }

  void test_superFormalParameter_functionTyped_typeParameters() {
    var code = 'int super.a<E, F>(b)';
    var parseResult = parseTestCodeWithDiagnostics('''
class A {
  A($code);
}
''');
    var node = parseResult.findNode.singleSuperFormalParameter;
    _assertSource(code, node);
  }

  void test_superFormalParameter_keyword() {
    var code = 'final super.foo';
    var parseResult = parseTestCodeWithDiagnostics('''
// %before-language-feature: primary-constructors
class A {
  A($code);
}
''');
    var node = parseResult.findNode.singleSuperFormalParameter;
    _assertSource(code, node);
  }

  void test_superFormalParameter_keywordAndType() {
    var code = 'final int super.a';
    var parseResult = parseTestCodeWithDiagnostics('''
// %before-language-feature: primary-constructors
class A {
  A($code);
}
''');
    var node = parseResult.findNode.singleSuperFormalParameter;
    _assertSource(code, node);
  }

  void test_superFormalParameter_type() {
    var code = 'int super.a';
    var parseResult = parseTestCodeWithDiagnostics('''
class A {
  A($code);
}
''');
    var node = parseResult.findNode.singleSuperFormalParameter;
    _assertSource(code, node);
  }

  void test_superFormalParameter_type_covariant() {
    var code = 'covariant int super.a';
    var parseResult = parseTestCodeWithDiagnostics('''
class A {
  A($code);
}
''');
    var node = parseResult.findNode.singleSuperFormalParameter;
    _assertSource(code, node);
  }

  void test_superReference() {
    var parseResult = parseTestCodeWithDiagnostics('''
class A {
  void foo() {
    super.foo();
  }
}
''');
    var node = parseResult.findNode.singleSuperReference;
    _assertSource('super', node);

    // ignore: analyzer_v1_ast_use
    var nodeV1 = parseResult.findNodeV1.singleSuperExpression;
    expect(nodeV1.toSource(), 'super');
  }

  void test_switchCase_multipleLabels() {
    var code = 'l1: l2: case a: {}';
    var parseResult = parseTestCodeWithDiagnostics('''
// %before-language-feature: patterns
void f() {
  switch (x) {
    $code
  }
}
''');
    var node = parseResult.findNode.singleSwitchCase;
    _assertSource(code, node);
  }

  void test_switchCase_multipleStatements() {
    var code = 'case a: foo(); bar();';
    var parseResult = parseTestCodeWithDiagnostics('''
// %before-language-feature: patterns
void f() {
  switch (x) {
    $code
  }
}
''');
    var node = parseResult.findNode.singleSwitchCase;
    _assertSource(code, node);
  }

  void test_switchCase_noLabels() {
    var code = 'case a: {}';
    var parseResult = parseTestCodeWithDiagnostics('''
// %before-language-feature: patterns
void f() {
  switch (x) {
    $code
  }
}
''');
    var node = parseResult.findNode.singleSwitchCase;
    _assertSource(code, node);
  }

  void test_switchCase_singleLabel() {
    var code = 'l1: case a: {}';
    var parseResult = parseTestCodeWithDiagnostics('''
// %before-language-feature: patterns
void f() {
  switch (x) {
    $code
  }
}
''');
    var node = parseResult.findNode.singleSwitchCase;
    _assertSource(code, node);
  }

  void test_switchDefault_multipleLabels() {
    var code = 'l1: l2: default: {}';
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  switch (x) {
    $code
  }
}
''');
    var node = parseResult.findNode.singleSwitchDefault;
    _assertSource(code, node);
  }

  void test_switchDefault_multipleStatements() {
    var code = 'default: foo(); bar();';
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  switch (x) {
    $code
  }
}
''');
    var node = parseResult.findNode.singleSwitchDefault;
    _assertSource(code, node);
  }

  void test_switchDefault_noLabels() {
    var code = 'default: {}';
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  switch (x) {
    $code
  }
}
''');
    var node = parseResult.findNode.singleSwitchDefault;
    _assertSource(code, node);
  }

  void test_switchDefault_singleLabel() {
    var code = 'l1: default: {}';
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  switch (x) {
    $code
  }
}
''');
    var node = parseResult.findNode.singleSwitchDefault;
    _assertSource(code, node);
  }

  void test_switchExpression() {
    var code = 'switch (x) {0 => 1, _ => 2}';
    var parseResult = parseTestCodeWithDiagnostics('''
var result = $code;
''');
    var node = parseResult.findNode.singleSwitchExpression;
    _assertSource(code, node);
  }

  void test_switchExpressionCase() {
    var code = '0 => 1';
    var parseResult = parseTestCodeWithDiagnostics('''
var result = switch (x) {
  $code,
  _ => 2,
};
''');
    var node = parseResult.findNode.switchExpressionCase(code);
    _assertSource(code, node);
  }

  void test_switchPatternCase_multipleLabels() {
    var code = 'l1: l2: case a: {}';
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  switch (x) {
    $code
  }
}
''');
    var node = parseResult.findNode.singleSwitchPatternCase;
    _assertSource(code, node);
  }

  void test_switchPatternCase_multipleStatements() {
    var code = 'case a: foo(); bar();';
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  switch (x) {
    $code
  }
}
''');
    var node = parseResult.findNode.singleSwitchPatternCase;
    _assertSource(code, node);
  }

  void test_switchPatternCase_noLabels() {
    var code = 'case a: {}';
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  switch (x) {
    $code
  }
}
''');
    var node = parseResult.findNode.singleSwitchPatternCase;
    _assertSource(code, node);
  }

  void test_switchPatternCase_singleLabel() {
    var code = 'l1: case a: {}';
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  switch (x) {
    $code
  }
}
''');
    var node = parseResult.findNode.singleSwitchPatternCase;
    _assertSource(code, node);
  }

  void test_switchStatement() {
    var code = 'switch (x) {case 0: foo(); default: bar();}';
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  $code
}
''');
    var node = parseResult.findNode.singleSwitchStatement;
    _assertSource(code, node);
  }

  void test_symbolLiteral_multiple() {
    var code = '#a.b.c';
    var parseResult = parseTestCodeWithDiagnostics('''
final x = $code;
''');
    var node = parseResult.findNode.singleSymbolLiteral;
    _assertSource(code, node);
  }

  void test_symbolLiteral_single() {
    var code = '#a';
    var parseResult = parseTestCodeWithDiagnostics('''
final x = $code;
''');
    var node = parseResult.findNode.singleSymbolLiteral;
    _assertSource(code, node);
  }

  void test_thisExpression() {
    var code = 'this';
    var parseResult = parseTestCodeWithDiagnostics('''
class A {
  void foo() {
    $code;
  }
}
''');
    var node = parseResult.findNode.singleThisExpression;
    _assertSource(code, node);
  }

  void test_throwExpression() {
    var code = 'throw 0';
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  $code;
}
''');
    var node = parseResult.findNode.singleThrowExpression;
    _assertSource(code, node);
  }

  void test_topLevelFunctionDeclaration_augment() {
    var code = 'augment void f() {}';
    var parseResult = parseTestCodeWithDiagnostics(code);
    var node = parseResult.findNode.singleTopLevelFunctionDeclaration;
    _assertSource(code, node);
  }

  void test_topLevelFunctionDeclaration_external() {
    var code = 'external void f();';
    var parseResult = parseTestCodeWithDiagnostics(code);
    var node = parseResult.findNode.singleTopLevelFunctionDeclaration;
    _assertSource(code, node);
  }

  void test_topLevelFunctionDeclaration_normal() {
    var code = 'void foo() {}';
    var parseResult = parseTestCodeWithDiagnostics(code);
    var node = parseResult.findNode.singleTopLevelFunctionDeclaration;
    _assertSource(code, node);
  }

  void test_topLevelFunctionDeclaration_typeParameters() {
    var code = 'void foo<T>(int a) {}';
    var parseResult = parseTestCodeWithDiagnostics(code);
    var node = parseResult.findNode.singleTopLevelFunctionDeclaration;
    _assertSource(code, node);

    // ignore: analyzer_v1_ast_use
    var declarationV1 = parseResult.findNodeV1.singleFunctionDeclaration;
    var functionV1 = declarationV1.functionExpression;
    expect(functionV1.toSource(), '<T>(int a) {}');
  }

  void test_topLevelFunctionDeclaration_withMetadata() {
    var code = '@deprecated void f() {}';
    var parseResult = parseTestCodeWithDiagnostics(code);
    var node = parseResult.findNode.singleTopLevelFunctionDeclaration;
    _assertSource(code, node);
  }

  void test_topLevelGetterDeclaration() {
    var code = 'get foo {}';
    var parseResult = parseTestCodeWithDiagnostics(code);
    var node = parseResult.findNode.singleTopLevelGetterDeclaration;
    _assertSource(code, node);

    // ignore: analyzer_v1_ast_use
    var declarationV1 = parseResult.findNodeV1.singleFunctionDeclaration;
    var functionV1 = declarationV1.functionExpression;
    expect(functionV1.toSource(), ' {}');
  }

  void test_topLevelSetterDeclaration() {
    var code = 'set foo(int _) {}';
    var parseResult = parseTestCodeWithDiagnostics(code);
    var node = parseResult.findNode.singleTopLevelSetterDeclaration;
    _assertSource(code, node);
  }

  void test_topLevelVariable_initialized() {
    var code = 'foo = bar';
    var parseResult = parseTestCodeWithDiagnostics('''
var $code;
''');
    var node = parseResult.findNode.singleTopLevelVariable;
    _assertSource(code, node);
  }

  void test_topLevelVariable_uninitialized() {
    var code = 'foo';
    var parseResult = parseTestCodeWithDiagnostics('''
var $code;
''');
    var node = parseResult.findNode.singleTopLevelVariable;
    _assertSource(code, node);
  }

  void test_topLevelVariablesDeclaration_abstract() {
    var code = 'abstract var a;';
    var parseResult = parseTestCodeWithDiagnostics('''
$code
''');
    var node = parseResult.findNode.singleTopLevelVariablesDeclaration;
    _assertSource(code, node);
  }

  void test_topLevelVariablesDeclaration_augment() {
    var code = 'augment var a = 0;';
    var parseResult = parseTestCodeWithDiagnostics('''
$code
''');
    var node = parseResult.findNode.singleTopLevelVariablesDeclaration;
    _assertSource(code, node);
  }

  void test_topLevelVariablesDeclaration_external() {
    var code = 'external var a;';
    var parseResult = parseTestCodeWithDiagnostics('''
$code
''');
    var node = parseResult.findNode.singleTopLevelVariablesDeclaration;
    _assertSource(code, node);
  }

  void test_topLevelVariablesDeclaration_external_abstract() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
external abstract var a;
//       ^^^^^^^^
// [diag.abstractExternalField] Fields can't be declared both 'abstract' and 'external'.
''');
    var node = parseResult.findNode.singleTopLevelVariablesDeclaration;
    _assertSource('external abstract var a;', node);
  }

  void test_topLevelVariablesDeclaration_multiple() {
    var code = 'var a = 0, b = 1;';
    var parseResult = parseTestCodeWithDiagnostics('''
$code
''');
    var node = parseResult.findNode.singleTopLevelVariablesDeclaration;
    _assertSource(code, node);

    // ignore: analyzer_v1_ast_use
    var listV1 = parseResult.findNodeV1.singleVariableDeclarationList;
    expect(listV1.toSource(), 'var a = 0, b = 1');
  }

  void test_topLevelVariablesDeclaration_single() {
    var code = 'var a;';
    var parseResult = parseTestCodeWithDiagnostics('''
$code
''');
    var node = parseResult.findNode.singleTopLevelVariablesDeclaration;
    _assertSource(code, node);
  }

  void test_topLevelVariablesDeclaration_withMetadata() {
    var code = '@deprecated var a;';
    var parseResult = parseTestCodeWithDiagnostics('''
$code
''');
    var node = parseResult.findNode.singleTopLevelVariablesDeclaration;
    _assertSource(code, node);
  }

  void test_tryStatement_catch() {
    var code = 'try {} on E {}';
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  $code
}
''');
    var node = parseResult.findNode.singleTryStatement;
    _assertSource(code, node);
  }

  void test_tryStatement_catches() {
    var code = 'try {} on E {} on F {}';
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  $code
}
''');
    var node = parseResult.findNode.singleTryStatement;
    _assertSource(code, node);
  }

  void test_tryStatement_catchFinally() {
    var code = 'try {} on E {} finally {}';
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  $code
}
''');
    var node = parseResult.findNode.singleTryStatement;
    _assertSource(code, node);
  }

  void test_tryStatement_finally() {
    var code = 'try {} finally {}';
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  $code
}
''');
    var node = parseResult.findNode.singleTryStatement;
    _assertSource(code, node);
  }

  void test_typeArgumentList_multiple() {
    var code = '<int, String>';
    var parseResult = parseTestCodeWithDiagnostics('''
final x = $code[];
''');
    var node = parseResult.findNode.singleTypeArgumentList;
    _assertSource(code, node);
  }

  void test_typeArgumentList_single() {
    var code = '<int>';
    var parseResult = parseTestCodeWithDiagnostics('''
final x = $code[];
''');
    var node = parseResult.findNode.singleTypeArgumentList;
    _assertSource(code, node);
  }

  void test_typeParameter_variance_contravariant() {
    var code = 'in T';
    var parseResult = parseTestCodeWithDiagnostics('''
class A<$code> {}
''');
    var node = parseResult.findNode.singleTypeParameter;
    _assertSource(code, node);
  }

  void test_typeParameter_variance_covariant() {
    var code = 'out T';
    var parseResult = parseTestCodeWithDiagnostics('''
class A<$code> {}
''');
    var node = parseResult.findNode.singleTypeParameter;
    _assertSource(code, node);
  }

  void test_typeParameter_variance_invariant() {
    var code = 'inout T';
    var parseResult = parseTestCodeWithDiagnostics('''
class A<$code> {}
''');
    var node = parseResult.findNode.singleTypeParameter;
    _assertSource(code, node);
  }

  void test_typeParameter_withExtends() {
    var code = 'T extends num';
    var parseResult = parseTestCodeWithDiagnostics('''
class A<$code> {}
''');
    var node = parseResult.findNode.singleTypeParameter;
    _assertSource(code, node);
  }

  void test_typeParameter_withMetadata() {
    var code = '@deprecated T';
    var parseResult = parseTestCodeWithDiagnostics('''
class A<$code> {}
''');
    var node = parseResult.findNode.singleTypeParameter;
    _assertSource(code, node);
  }

  void test_typeParameter_withoutExtends() {
    var code = 'T';
    var parseResult = parseTestCodeWithDiagnostics('''
class A<$code> {}
''');
    var node = parseResult.findNode.singleTypeParameter;
    _assertSource(code, node);
  }

  void test_typeParameterList_multiple() {
    var code = '<T, U>';
    var parseResult = parseTestCodeWithDiagnostics('''
class A$code {}
''');
    var node = parseResult.findNode.singleTypeParameterList;
    _assertSource(code, node);
  }

  void test_typeParameterList_single() {
    var code = '<T>';
    var parseResult = parseTestCodeWithDiagnostics('''
class A$code {}
''');
    var node = parseResult.findNode.singleTypeParameterList;
    _assertSource(code, node);
  }

  void test_unaryOperatorInvocation() {
    var code = '-foo';
    var parseResult = parseTestCodeWithDiagnostics('''
int f() {
  $code;
}
''');
    var node = parseResult.findNode.singleUnaryOperatorInvocation;
    _assertSource(code, node);
  }

  void test_whileStatement() {
    var code = 'while (true) {}';
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  $code
}
''');
    var node = parseResult.findNode.singleWhileStatement;
    _assertSource(code, node);
  }

  void test_wildcardPattern() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case int? _:
      break;
  }
}
''');
    var node = parseResult.findNode.singleWildcardPattern;
    _assertSource('int? _', node);
  }

  void test_withClause_multiple() {
    var code = 'with A, B, C';
    var parseResult = parseTestCodeWithDiagnostics('''
class X $code {}
''');
    var node = parseResult.findNode.singleWithClause;
    _assertSource(code, node);
  }

  void test_withClause_single() {
    var code = 'with M';
    var parseResult = parseTestCodeWithDiagnostics('''
class X $code {}
''');
    var node = parseResult.findNode.singleWithClause;
    _assertSource(code, node);
  }

  void test_yieldStatement() {
    var code = 'yield e;';
    var parseResult = parseTestCodeWithDiagnostics('''
void f() sync* {
  $code
}
''');
    var node = parseResult.findNode.singleYieldStatement;
    _assertSource(code, node);
  }

  void test_yieldStatement_each() {
    var code = 'yield* e;';
    var parseResult = parseTestCodeWithDiagnostics('''
void f() sync* {
  $code
}
''');
    var node = parseResult.findNode.singleYieldStatement;
    _assertSource(code, node);
  }

  /// Assert that a [ToSourceVisitor] will produce the [expectedSource] when
  /// visiting the given [node].
  void _assertSource(String expectedSource, AstNode node) {
    StringBuffer buffer = StringBuffer();
    node.accept2(ToSourceVisitor(buffer));
    expect(buffer.toString(), expectedSource);
  }
}
