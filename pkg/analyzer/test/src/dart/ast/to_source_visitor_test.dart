// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/to_source_visitor.dart';
import 'package:analyzer/src/test_utilities/find_node.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../util/feature_sets.dart';
import '../../diagnostics/parser_diagnostics.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ToSourceVisitorTest);
  });
}

@reflectiveTest
class ToSourceVisitorTest extends ParserDiagnosticsTest {
  void test_representationDeclaration() {
    var code = '(@foo int it)';
    var findNode = _parseStringToFindNode('''
extension type E$code {}
''');
    _assertSource(code, findNode.singleRepresentationDeclaration);
  }

  void test_visitAdjacentStrings() {
    var findNode = _parseStringToFindNode(r'''
var v = 'a' 'b';
''');
    _assertSource(
      "'a' 'b'",
      findNode.adjacentStrings("'a'"),
    );
  }

  void test_visitAnnotation_constant() {
    var code = '@A';
    var findNode = _parseStringToFindNode('''
$code
void f() {}
''');
    _assertSource(code, findNode.annotation(code));
  }

  void test_visitAnnotation_constructor() {
    var code = '@A.foo()';
    var findNode = _parseStringToFindNode('''
$code
void f() {}
''');
    _assertSource(code, findNode.annotation(code));
  }

  void test_visitAnnotation_constructor_generic() {
    var code = '@A<int>.foo()';
    var findNode = _parseStringToFindNode('''
$code
void f() {}
''');
    _assertSource(code, findNode.annotation(code));
  }

  void test_visitArgumentList() {
    var code = '(0, 1)';
    var findNode = _parseStringToFindNode('''
final x = f$code;
''');
    _assertSource(code, findNode.argumentList(code));
  }

  void test_visitAsExpression() {
    var findNode = _parseStringToFindNode(r'''
var v = a as T;
''');
    _assertSource(
      'a as T',
      findNode.as_('as T'),
    );
  }

  void test_visitAssertStatement() {
    var findNode = _parseStringToFindNode(r'''
void f() {
  assert(a);
}
''');
    _assertSource(
      'assert (a);',
      findNode.assertStatement('assert'),
    );
  }

  void test_visitAssertStatement_withMessage() {
    var findNode = _parseStringToFindNode(r'''
void f() {
  assert(a, b);
}
''');
    _assertSource(
      'assert (a, b);',
      findNode.assertStatement('assert'),
    );
  }

  void test_visitAssignedVariablePattern() {
    var findNode = _parseStringToFindNode('''
void f(int foo) {
  (foo) = 0;
}
''');
    _assertSource('foo', findNode.assignedVariablePattern('foo) = 0'));
  }

  void test_visitAssignmentExpression() {
    var code = 'a = b';
    var findNode = _parseStringToFindNode('''
void f() {
  $code;
}
''');
    _assertSource(code, findNode.assignment(code));
  }

  void test_visitAwaitExpression() {
    var findNode = _parseStringToFindNode(r'''
void f() async => await e;
''');
    _assertSource(
      'await e',
      findNode.awaitExpression('await e'),
    );
  }

  void test_visitBinaryExpression() {
    var findNode = _parseStringToFindNode(r'''
var v = a + b;
''');
    _assertSource(
      'a + b',
      findNode.binary('a + b'),
    );
  }

  void test_visitBinaryExpression_precedence() {
    var findNode = _parseStringToFindNode(r'''
var v = a * (b + c);
''');
    _assertSource(
      'a * (b + c)',
      findNode.binary('a *'),
    );
  }

  void test_visitBlock_empty() {
    var code = '{}';
    var findNode = _parseStringToFindNode('''
void f() $code
''');
    _assertSource(code, findNode.block(code));
  }

  void test_visitBlock_nonEmpty() {
    var code = '{foo(); bar();}';
    var findNode = _parseStringToFindNode('''
void f() $code
''');
    _assertSource(code, findNode.block(code));
  }

  void test_visitBlockFunctionBody_async() {
    var code = 'async {}';
    var findNode = _parseStringToFindNode('''
void f() $code
''');
    _assertSource(code, findNode.blockFunctionBody(code));
  }

  void test_visitBlockFunctionBody_async_star() {
    var code = 'async* {}';
    var findNode = _parseStringToFindNode('''
void f() $code
''');
    _assertSource(code, findNode.blockFunctionBody(code));
  }

  void test_visitBlockFunctionBody_simple() {
    var code = '{}';
    var findNode = _parseStringToFindNode('''
void f() $code
''');
    _assertSource(code, findNode.blockFunctionBody(code));
  }

  void test_visitBlockFunctionBody_sync_star() {
    var code = 'sync* {}';
    var findNode = _parseStringToFindNode('''
void f() $code
''');
    _assertSource(code, findNode.blockFunctionBody(code));
  }

  void test_visitBooleanLiteral_false() {
    var code = 'false';
    var findNode = _parseStringToFindNode('''
final v = $code;
''');
    _assertSource(code, findNode.booleanLiteral(code));
  }

  void test_visitBooleanLiteral_true() {
    var code = 'true';
    var findNode = _parseStringToFindNode('''
final v = $code;
''');
    _assertSource(code, findNode.booleanLiteral(code));
  }

  void test_visitBreakStatement_label() {
    var code = 'break L;';
    var findNode = _parseStringToFindNode('''
void f() {
  L: while (true) {
    $code
  }
}
''');
    _assertSource(code, findNode.breakStatement(code));
  }

  void test_visitBreakStatement_noLabel() {
    var code = 'break;';
    var findNode = _parseStringToFindNode('''
void f() {
  while (true) {
    $code
  }
}
''');
    _assertSource(code, findNode.breakStatement(code));
  }

  void test_visitCascadeExpression_field() {
    var code = 'a..b..c';
    var findNode = _parseStringToFindNode('''
void f() {
  $code;
}
''');
    _assertSource(code, findNode.cascade(code));
  }

  void test_visitCascadeExpression_index() {
    var code = 'a..[0]..[1]';
    var findNode = _parseStringToFindNode('''
void f() {
  $code;
}
''');
    _assertSource(code, findNode.cascade(code));
  }

  void test_visitCascadeExpression_method() {
    var code = 'a..b()..c()';
    var findNode = _parseStringToFindNode('''
void f() {
  $code;
}
''');
    _assertSource(code, findNode.cascade(code));
  }

  void test_visitCastPattern() {
    var findNode = _parseStringToFindNode('''
void f(x) {
  switch (x) {
    case y as int:
      break;
  }
}
''');
    _assertSource(
      'y as int',
      findNode.castPattern('as '),
    );
  }

  void test_visitCatchClause_catch_noStack() {
    var code = 'catch (e) {}';
    var findNode = _parseStringToFindNode('''
void f() {
  try {}
  $code
}
''');
    _assertSource(code, findNode.catchClause(code));
  }

  void test_visitCatchClause_catch_stack() {
    var code = 'catch (e, s) {}';
    var findNode = _parseStringToFindNode('''
void f() {
  try {}
  $code
}
''');
    _assertSource(code, findNode.catchClause(code));
  }

  void test_visitCatchClause_on() {
    var code = 'on E {}';
    var findNode = _parseStringToFindNode('''
void f() {
  try {}
  $code
}
''');
    _assertSource(code, findNode.catchClause(code));
  }

  void test_visitCatchClause_on_catch() {
    var code = 'on E catch (e) {}';
    var findNode = _parseStringToFindNode('''
void f() {
  try {}
  $code
}
''');
    _assertSource(code, findNode.catchClause(code));
  }

  void test_visitClassDeclaration_abstract() {
    var code = 'abstract class C {}';
    var findNode = _parseStringToFindNode(code);
    _assertSource(code, findNode.classDeclaration(code));
  }

  void test_visitClassDeclaration_abstractMacro() {
    var code = 'abstract macro class C {}';
    var findNode = _parseStringToFindNode(code);
    _assertSource(code, findNode.classDeclaration(code));
  }

  void test_visitClassDeclaration_augment() {
    var code = 'augment class A {}';
    var findNode = _parseStringToFindNode(code);
    _assertSource(code, findNode.singleClassDeclaration);
  }

  void test_visitClassDeclaration_augment_abstract() {
    var code = 'augment abstract class C {}';
    var findNode = _parseStringToFindNode(code);
    _assertSource(code, findNode.singleClassDeclaration);
  }

  void test_visitClassDeclaration_base() {
    var findNode = _parseStringToFindNode(r'''
base class A {}
''');
    _assertSource(
      'base class A {}',
      findNode.classDeclaration('class A'),
    );
  }

  void test_visitClassDeclaration_empty() {
    var code = 'class C {}';
    var findNode = _parseStringToFindNode(code);
    _assertSource(code, findNode.classDeclaration(code));
  }

  void test_visitClassDeclaration_extends() {
    var code = 'class C extends A {}';
    var findNode = _parseStringToFindNode('''
$code
''');
    _assertSource(code, findNode.classDeclaration(code));
  }

  void test_visitClassDeclaration_extends_implements() {
    var code = 'class C extends A implements B {}';
    var findNode = _parseStringToFindNode('''
$code
''');
    _assertSource(code, findNode.classDeclaration(code));
  }

  void test_visitClassDeclaration_extends_with() {
    var code = 'class C extends A with M {}';
    var findNode = _parseStringToFindNode('''
$code
void f() {}
''');
    _assertSource(code, findNode.classDeclaration(code));
  }

  void test_visitClassDeclaration_extends_with_implements() {
    var code = 'class C extends A with M implements B {}';
    var findNode = _parseStringToFindNode('''
$code
void f() {}
''');
    _assertSource(code, findNode.classDeclaration(code));
  }

  void test_visitClassDeclaration_final() {
    var findNode = _parseStringToFindNode(r'''
final class A {}
''');
    _assertSource(
      'final class A {}',
      findNode.classDeclaration('class A'),
    );
  }

  void test_visitClassDeclaration_implements() {
    var code = 'class C implements B {}';
    var findNode = _parseStringToFindNode('''
$code
''');
    _assertSource(code, findNode.classDeclaration(code));
  }

  void test_visitClassDeclaration_interface() {
    var findNode = _parseStringToFindNode(r'''
interface class A {}
''');
    _assertSource(
      'interface class A {}',
      findNode.classDeclaration('class A'),
    );
  }

  void test_visitClassDeclaration_macro() {
    var findNode = _parseStringToFindNode(r'''
macro class A {}
''');
    _assertSource(
      'macro class A {}',
      findNode.classDeclaration('class A'),
    );
  }

  void test_visitClassDeclaration_mixin() {
    var findNode = _parseStringToFindNode(r'''
mixin class A {}
''');
    _assertSource(
      'mixin class A {}',
      findNode.classDeclaration('class A'),
    );
  }

  void test_visitClassDeclaration_multipleMember() {
    var code = 'class C {var a; var b;}';
    var findNode = _parseStringToFindNode('''
$code
''');
    _assertSource(code, findNode.classDeclaration(code));
  }

  void test_visitClassDeclaration_parameters() {
    var code = 'class C<E> {}';
    var findNode = _parseStringToFindNode(code);
    _assertSource(code, findNode.classDeclaration(code));
  }

  void test_visitClassDeclaration_parameters_extends() {
    var code = 'class C<E> extends A {}';
    var findNode = _parseStringToFindNode('''
$code
''');
    _assertSource(code, findNode.classDeclaration(code));
  }

  void test_visitClassDeclaration_parameters_extends_implements() {
    var code = 'class C<E> extends A implements B {}';
    var findNode = _parseStringToFindNode('''
$code
''');
    _assertSource(code, findNode.classDeclaration(code));
  }

  void test_visitClassDeclaration_parameters_extends_with() {
    var code = 'class C<E> extends A with M {}';
    var findNode = _parseStringToFindNode('''
$code
''');
    _assertSource(code, findNode.classDeclaration(code));
  }

  void test_visitClassDeclaration_parameters_extends_with_implements() {
    var code = 'class C<E> extends A with M implements B {}';
    var findNode = _parseStringToFindNode('''
$code
''');
    _assertSource(code, findNode.classDeclaration(code));
  }

  void test_visitClassDeclaration_parameters_implements() {
    var code = 'class C<E> implements B {}';
    var findNode = _parseStringToFindNode('''
$code
''');
    _assertSource(code, findNode.classDeclaration(code));
  }

  void test_visitClassDeclaration_sealed() {
    var findNode = _parseStringToFindNode(r'''
sealed class A {}
''');
    _assertSource(
      'sealed class A {}',
      findNode.classDeclaration('class A'),
    );
  }

  void test_visitClassDeclaration_singleMember() {
    var code = 'class C {var a;}';
    var findNode = _parseStringToFindNode(code);
    _assertSource(code, findNode.classDeclaration(code));
  }

  void test_visitClassDeclaration_withMetadata() {
    var code = '@deprecated class C {}';
    var findNode = _parseStringToFindNode(code);
    _assertSource(code, findNode.classDeclaration(code));
  }

  void test_visitClassTypeAlias_abstract() {
    var code = 'abstract class C = S with M;';
    var findNode = _parseStringToFindNode('''
$code
''');
    _assertSource(code, findNode.classTypeAlias(code));
  }

  void test_visitClassTypeAlias_abstract_implements() {
    var code = 'abstract class C = S with M implements I;';
    var findNode = _parseStringToFindNode('''
$code
''');
    _assertSource(code, findNode.classTypeAlias(code));
  }

  void test_visitClassTypeAlias_abstractAugment() {
    // TODO(scheglov): Is this the right order of modifiers?
    var code = 'augment abstract class C = S with M;';
    var findNode = _parseStringToFindNode('''
$code
''');
    _assertSource(code, findNode.classTypeAlias('class C'));
  }

  void test_visitClassTypeAlias_abstractMacro() {
    var code = 'abstract macro class C = S with M;';
    var findNode = _parseStringToFindNode('''
$code
''');
    _assertSource(code, findNode.classTypeAlias(code));
  }

  void test_visitClassTypeAlias_augment() {
    var findNode = _parseStringToFindNode(r'''
augment class A = S with M;
''');
    _assertSource(
      'augment class A = S with M;',
      findNode.classTypeAlias('class A'),
    );
  }

  void test_visitClassTypeAlias_base() {
    var findNode = _parseStringToFindNode(r'''
base class A = S with M;
''');
    _assertSource(
      'base class A = S with M;',
      findNode.classTypeAlias('class A'),
    );
  }

  void test_visitClassTypeAlias_final() {
    var findNode = _parseStringToFindNode(r'''
final class A = S with M;
''');
    _assertSource(
      'final class A = S with M;',
      findNode.classTypeAlias('class A'),
    );
  }

  void test_visitClassTypeAlias_generic() {
    var code = 'class C<E> = S<E> with M<E>;';
    var findNode = _parseStringToFindNode('''
$code
''');
    _assertSource(code, findNode.classTypeAlias(code));
  }

  void test_visitClassTypeAlias_implements() {
    var code = 'class C = S with M implements I;';
    var findNode = _parseStringToFindNode('''
$code
''');
    _assertSource(code, findNode.classTypeAlias(code));
  }

  void test_visitClassTypeAlias_interface() {
    var findNode = _parseStringToFindNode(r'''
interface class A = S with M;
''');
    _assertSource(
      'interface class A = S with M;',
      findNode.classTypeAlias('class A'),
    );
  }

  void test_visitClassTypeAlias_macro() {
    var findNode = _parseStringToFindNode(r'''
macro class A = S with M;
''');
    _assertSource(
      'macro class A = S with M;',
      findNode.classTypeAlias('class A'),
    );
  }

  void test_visitClassTypeAlias_minimal() {
    var code = 'class C = S with M;';
    var findNode = _parseStringToFindNode('''
$code
''');
    _assertSource(code, findNode.classTypeAlias(code));
  }

  void test_visitClassTypeAlias_mixin() {
    var findNode = _parseStringToFindNode(r'''
mixin class A = S with M;
''');
    _assertSource(
      'mixin class A = S with M;',
      findNode.classTypeAlias('class A'),
    );
  }

  void test_visitClassTypeAlias_parameters_abstract() {
    var code = 'abstract class C<E> = S with M;';
    var findNode = _parseStringToFindNode('''
$code
''');
    _assertSource(code, findNode.classTypeAlias(code));
  }

  void test_visitClassTypeAlias_parameters_abstract_implements() {
    var code = 'abstract class C<E> = S with M implements I;';
    var findNode = _parseStringToFindNode('''
$code
''');
    _assertSource(code, findNode.classTypeAlias(code));
  }

  void test_visitClassTypeAlias_parameters_implements() {
    var code = 'class C<E> = S with M implements I;';
    var findNode = _parseStringToFindNode('''
$code
''');
    _assertSource(code, findNode.classTypeAlias(code));
  }

  void test_visitClassTypeAlias_sealed() {
    var findNode = _parseStringToFindNode(r'''
sealed class A = S with M;
''');
    _assertSource(
      'sealed class A = S with M;',
      findNode.classTypeAlias('class A'),
    );
  }

  void test_visitClassTypeAlias_withMetadata() {
    var code = '@deprecated class A = S with M;';
    var findNode = _parseStringToFindNode(code);
    _assertSource(code, findNode.classTypeAlias(code));
  }

  void test_visitComment() {
    var code = r'''
/// foo
/// bar
''';
    var findNode = _parseStringToFindNode('''
$code
void f() {}
''');
    _assertSource('', findNode.comment(code));
  }

  void test_visitCommentReference() {
    var code = 'x';
    var findNode = _parseStringToFindNode('''
/// [$code]
void f() {}
''');
    _assertSource('', findNode.commentReference(code));
  }

  void test_visitCompilationUnit_declaration() {
    var code = 'var a;';
    var findNode = _parseStringToFindNode(code);
    _assertSource(code, findNode.unit);
  }

  void test_visitCompilationUnit_directive() {
    var code = 'library my;';
    var findNode = _parseStringToFindNode(code);
    _assertSource(code, findNode.unit);
  }

  void test_visitCompilationUnit_directive_declaration() {
    var code = 'library my; var a;';
    var findNode = _parseStringToFindNode(code);
    _assertSource(code, findNode.unit);
  }

  void test_visitCompilationUnit_empty() {
    var code = '';
    var findNode = _parseStringToFindNode(code);
    _assertSource(code, findNode.unit);
  }

  void test_visitCompilationUnit_libraryWithoutName() {
    var code = 'library ;';
    var findNode = _parseStringToFindNode(code);
    _assertSource(code, findNode.unit);
  }

  void test_visitCompilationUnit_script() {
    var findNode = _parseStringToFindNode('''
#!/bin/dartvm
''');
    _assertSource('#!/bin/dartvm', findNode.unit);
  }

  void test_visitCompilationUnit_script_declaration() {
    var findNode = _parseStringToFindNode('''
#!/bin/dartvm
var a;
''');
    _assertSource('#!/bin/dartvm var a;', findNode.unit);
  }

  void test_visitCompilationUnit_script_directive() {
    var findNode = _parseStringToFindNode('''
#!/bin/dartvm
library my;
''');
    _assertSource('#!/bin/dartvm library my;', findNode.unit);
  }

  void test_visitCompilationUnit_script_directives_declarations() {
    var findNode = _parseStringToFindNode('''
#!/bin/dartvm
library my;
var a;
''');
    _assertSource('#!/bin/dartvm library my; var a;', findNode.unit);
  }

  void test_visitConditionalExpression() {
    var code = 'a ? b : c';
    var findNode = _parseStringToFindNode('''
void f() {
  $code;
}
''');
    _assertSource(code, findNode.conditionalExpression(code));
  }

  void test_visitConstantPattern() {
    var findNode = _parseStringToFindNode('''
void f(x) {
  if (x case true) {}
}
''');
    _assertSource(
      'true',
      findNode.constantPattern('true'),
    );
  }

  void test_visitConstructorDeclaration_const() {
    var code = 'const A();';
    var findNode = _parseStringToFindNode('''
class A {
  $code
}
''');
    _assertSource(code, findNode.constructor(code));
  }

  void test_visitConstructorDeclaration_external() {
    var code = 'external A();';
    var findNode = _parseStringToFindNode('''
class A {
  $code
}
''');
    _assertSource(code, findNode.constructor(code));
  }

  void test_visitConstructorDeclaration_minimal() {
    var code = 'A();';
    var findNode = _parseStringToFindNode('''
class A {
  $code
}
''');
    _assertSource(code, findNode.constructor(code));
  }

  void test_visitConstructorDeclaration_multipleInitializers() {
    var code = 'A() : a = b, c = d {}';
    var findNode = _parseStringToFindNode('''
class A {
  $code
}
''');
    _assertSource(code, findNode.constructor(code));
  }

  void test_visitConstructorDeclaration_multipleParameters() {
    var code = 'A(int a, double b);';
    var findNode = _parseStringToFindNode('''
class A {
  $code
}
''');
    _assertSource(code, findNode.constructor(code));
  }

  void test_visitConstructorDeclaration_named() {
    var code = 'A.foo();';
    var findNode = _parseStringToFindNode('''
class A {
  $code
}
''');
    _assertSource(code, findNode.constructor(code));
  }

  void test_visitConstructorDeclaration_singleInitializer() {
    var code = 'A() : a = b;';
    var findNode = _parseStringToFindNode('''
class A {
  $code
}
''');
    _assertSource(code, findNode.constructor(code));
  }

  void test_visitConstructorDeclaration_withMetadata() {
    var code = '@deprecated C() {}';
    var findNode = _parseStringToFindNode('''
class C {
  $code
}
''');
    _assertSource(code, findNode.constructor(code));
  }

  void test_visitConstructorFieldInitializer_withoutThis() {
    var code = 'a = 0';
    var findNode = _parseStringToFindNode('''
class C {
  C() : $code;
}
''');
    _assertSource(code, findNode.constructorFieldInitializer(code));
  }

  void test_visitConstructorFieldInitializer_withThis() {
    var code = 'this.a = 0';
    var findNode = _parseStringToFindNode('''
class C {
  C() : $code;
}
''');
    _assertSource(code, findNode.constructorFieldInitializer(code));
  }

  void test_visitConstructorName_named_prefix() {
    var code = 'prefix.A.foo';
    var findNode = _parseStringToFindNode('''
final x = new $code();
''');
    _assertSource(code, findNode.constructorName(code));
  }

  void test_visitConstructorName_unnamed_noPrefix() {
    var code = 'A';
    var findNode = _parseStringToFindNode('''
final x = new $code();
''');
    _assertSource(code, findNode.constructorName(code));
  }

  void test_visitConstructorName_unnamed_prefix() {
    var code = 'prefix.A';
    var findNode = _parseStringToFindNode('''
final x = new $code();
''');
    _assertSource(code, findNode.constructorName(code));
  }

  void test_visitContinueStatement_label() {
    var code = 'continue L;';
    var findNode = _parseStringToFindNode('''
void f() {
  L: while (true) {
    $code
  }
}
''');
    _assertSource(code, findNode.continueStatement('continue'));
  }

  void test_visitContinueStatement_noLabel() {
    var code = 'continue;';
    var findNode = _parseStringToFindNode('''
void f() {
  while (true) {
    $code
  }
}
''');
    _assertSource(code, findNode.continueStatement('continue'));
  }

  void test_visitDeclaredVariablePattern() {
    var findNode = _parseStringToFindNode('''
void f(x) {
  switch (x) {
    case int? a:
      break;
  }
}
''');
    _assertSource(
      'int? a',
      findNode.declaredVariablePattern('int?'),
    );
  }

  void test_visitDefaultFormalParameter_annotation() {
    var code = '@deprecated p = 0';
    var findNode = _parseStringToFindNode('''
void f([$code]) {}
''');
    _assertSource(code, findNode.defaultParameter(code));
  }

  void test_visitDefaultFormalParameter_named_noValue() {
    var code = 'int? a';
    var findNode = _parseStringToFindNode('''
void f({$code}) {}
''');
    _assertSource(code, findNode.defaultParameter(code));
  }

  void test_visitDefaultFormalParameter_named_value() {
    var code = 'int? a = 0';
    var findNode = _parseStringToFindNode('''
void f({$code}) {}
''');
    _assertSource(code, findNode.defaultParameter(code));
  }

  void test_visitDefaultFormalParameter_positional_noValue() {
    var code = 'int? a';
    var findNode = _parseStringToFindNode('''
void f([$code]) {}
''');
    _assertSource(code, findNode.defaultParameter(code));
  }

  void test_visitDefaultFormalParameter_positional_value() {
    var code = 'int? a = 0';
    var findNode = _parseStringToFindNode('''
void f([$code]) {}
''');
    _assertSource(code, findNode.defaultParameter(code));
  }

  void test_visitDoStatement() {
    var code = 'do {} while (true);';
    var findNode = _parseStringToFindNode('''
void f () {
  $code
}
''');
    _assertSource(code, findNode.doStatement(code));
  }

  void test_visitDoubleLiteral() {
    var code = '3.14';
    var findNode = _parseStringToFindNode('''
final x = $code;
''');
    _assertSource(code, findNode.doubleLiteral(code));
  }

  void test_visitEmptyFunctionBody() {
    var code = ';';
    var findNode = _parseStringToFindNode('''
void f() {
  ;
}
''');
    _assertSource(code, findNode.emptyStatement(code));
  }

  void test_visitEmptyStatement() {
    var code = ';';
    var findNode = _parseStringToFindNode('''
abstract class A {
  void foo();
}
''');
    _assertSource(code, findNode.emptyFunctionBody(code));
  }

  void test_visitEnumDeclaration_constant_arguments_named() {
    var findNode = _parseStringToFindNode(r'''
enum E {
  v<double>.named(42)
}
''');
    _assertSource(
      'enum E {v<double>.named(42)}',
      findNode.enumDeclaration('enum E'),
    );
  }

  void test_visitEnumDeclaration_constant_arguments_unnamed() {
    var findNode = _parseStringToFindNode(r'''
enum E {
  v<double>(42)
}
''');
    _assertSource(
      'enum E {v<double>(42)}',
      findNode.enumDeclaration('enum E'),
    );
  }

  void test_visitEnumDeclaration_constants_multiple() {
    var findNode = _parseStringToFindNode(r'''
enum E {one, two}
''');
    _assertSource(
      'enum E {one, two}',
      findNode.enumDeclaration('E'),
    );
  }

  void test_visitEnumDeclaration_constants_single() {
    var findNode = _parseStringToFindNode(r'''
enum E {one}
''');
    _assertSource(
      'enum E {one}',
      findNode.enumDeclaration('E'),
    );
  }

  void test_visitEnumDeclaration_field_constructor() {
    var findNode = _parseStringToFindNode(r'''
enum E {
  one, two;
  final int field;
  E(this.field);
}
''');
    _assertSource(
      'enum E {one, two; final int field; E(this.field);}',
      findNode.enumDeclaration('enum E'),
    );
  }

  void test_visitEnumDeclaration_method() {
    var findNode = _parseStringToFindNode(r'''
enum E {
  one, two;
  void myMethod() {}
  int get myGetter => 0;
}
''');
    _assertSource(
      'enum E {one, two; void myMethod() {} int get myGetter => 0;}',
      findNode.enumDeclaration('enum E'),
    );
  }

  void test_visitEnumDeclaration_withoutMembers() {
    var findNode = _parseStringToFindNode(r'''
enum E<T> with M1, M2 implements I1, I2 {one, two}
''');
    _assertSource(
      'enum E<T> with M1, M2 implements I1, I2 {one, two}',
      findNode.enumDeclaration('E'),
    );
  }

  void test_visitExportDirective_combinator() {
    var code = "export 'a.dart' show A;";
    var findNode = _parseStringToFindNode('''
$code
''');
    _assertSource(code, findNode.export(code));
  }

  void test_visitExportDirective_combinators() {
    var code = "export 'a.dart' show A hide B;";
    var findNode = _parseStringToFindNode('''
$code
''');
    _assertSource(code, findNode.export(code));
  }

  void test_visitExportDirective_configurations() {
    var unit = _parseStringToFindNode(r'''
export 'foo.dart'
  if (dart.library.io) 'foo_io.dart'
  if (dart.library.html) 'foo_html.dart';
''').unit;
    var directive = unit.directives[0] as ExportDirective;
    _assertSource(
      "export 'foo.dart'"
      " if (dart.library.io) 'foo_io.dart'"
      " if (dart.library.html) 'foo_html.dart';",
      directive,
    );
  }

  void test_visitExportDirective_minimal() {
    var code = "export 'a.dart';";
    var findNode = _parseStringToFindNode(code);
    _assertSource(code, findNode.export(code));
  }

  void test_visitExportDirective_withMetadata() {
    var code = '@deprecated export "a.dart";';
    var findNode = _parseStringToFindNode(code);
    _assertSource(code, findNode.export(code));
  }

  void test_visitExpressionFunctionBody_async() {
    var code = 'async => 0;';
    var findNode = _parseStringToFindNode('''
void f() $code
''');
    _assertSource(code, findNode.expressionFunctionBody(code));
  }

  void test_visitExpressionFunctionBody_async_star() {
    var code = 'async* => 0;';
    var parseResult = parseStringWithErrors('''
void f() $code
''');
    var node = parseResult.findNode.expressionFunctionBody(code);
    _assertSource(code, node);
  }

  void test_visitExpressionFunctionBody_simple() {
    var code = '=> 0;';
    var findNode = _parseStringToFindNode('''
void f() $code
''');
    _assertSource(code, findNode.expressionFunctionBody(code));
  }

  void test_visitExpressionStatement() {
    var code = '1 + 2;';
    var findNode = _parseStringToFindNode('''
void f() {
  $code
}
''');
    _assertSource(code, findNode.expressionStatement(code));
  }

  void test_visitExtendsClause() {
    var code = 'extends A';
    var findNode = _parseStringToFindNode('''
class C $code {}
''');
    _assertSource(code, findNode.extendsClause(code));
  }

  void test_visitExtensionDeclaration_augment() {
    var code = 'augment extension E {}';
    var findNode = _parseStringToFindNode('''
$code
''');
    _assertSource(code, findNode.extensionDeclaration(code));
  }

  void test_visitExtensionDeclaration_empty() {
    var code = 'extension E on C {}';
    var findNode = _parseStringToFindNode('''
$code
''');
    _assertSource(code, findNode.extensionDeclaration(code));
  }

  void test_visitExtensionDeclaration_multipleMember() {
    var code = 'extension E on C {static var a; static var b;}';
    var findNode = _parseStringToFindNode('''
$code
''');
    _assertSource(code, findNode.extensionDeclaration(code));
  }

  void test_visitExtensionDeclaration_parameters() {
    var code = 'extension E<T> on C {}';
    var findNode = _parseStringToFindNode('''
$code
''');
    _assertSource(code, findNode.extensionDeclaration(code));
  }

  void test_visitExtensionDeclaration_singleMember() {
    var code = 'extension E on C {static var a;}';
    var findNode = _parseStringToFindNode('''
$code
''');
    _assertSource(code, findNode.extensionDeclaration(code));
  }

  void test_visitExtensionOverride_prefixedName_noTypeArgs() {
    // TODO(scheglov): restore
    // _assertSource(
    //     'p.E(o)',
    //     AstTestFactory.extensionOverride(
    //         extensionName: AstTestFactory.identifier5('p', 'E'),
    //         argumentList: AstTestFactory.argumentList(
    //             [AstTestFactory.identifier3('o')])));
  }

  void test_visitExtensionOverride_prefixedName_typeArgs() {
    // TODO(scheglov): restore
    // _assertSource(
    //     'p.E<A>(o)',
    //     AstTestFactory.extensionOverride(
    //         extensionName: AstTestFactory.identifier5('p', 'E'),
    //         typeArguments: AstTestFactory.typeArgumentList(
    //             [AstTestFactory.namedType4('A')]),
    //         argumentList: AstTestFactory.argumentList(
    //             [AstTestFactory.identifier3('o')])));
  }

  void test_visitExtensionOverride_simpleName_noTypeArgs() {
    // TODO(scheglov): restore
    // _assertSource(
    //     'E(o)',
    //     AstTestFactory.extensionOverride(
    //         extensionName: AstTestFactory.identifier3('E'),
    //         argumentList: AstTestFactory.argumentList(
    //             [AstTestFactory.identifier3('o')])));
  }

  void test_visitExtensionOverride_simpleName_typeArgs() {
    // TODO(scheglov): restore
    // _assertSource(
    //     'E<A>(o)',
    //     AstTestFactory.extensionOverride(
    //         extensionName: AstTestFactory.identifier3('E'),
    //         typeArguments: AstTestFactory.typeArgumentList(
    //             [AstTestFactory.namedType4('A')]),
    //         argumentList: AstTestFactory.argumentList(
    //             [AstTestFactory.identifier3('o')])));
  }

  void test_visitExtensionType() {
    var code = 'extension type E(int it) {}';
    var findNode = _parseStringToFindNode('''
$code
''');
    _assertSource(code, findNode.singleExtensionTypeDeclaration);
  }

  void test_visitExtensionType_implements() {
    var code = 'extension type E(int it) implements num {}';
    var findNode = _parseStringToFindNode('''
$code
''');
    _assertSource(code, findNode.singleExtensionTypeDeclaration);
  }

  void test_visitExtensionType_method() {
    var code = 'extension type E(int it) {void foo() {}}';
    var findNode = _parseStringToFindNode('''
$code
''');
    _assertSource(code, findNode.singleExtensionTypeDeclaration);
  }

  void test_visitFieldDeclaration_abstract() {
    var code = 'abstract var a;';
    var findNode = _parseStringToFindNode('''
class A {
  $code
}
''');
    _assertSource(code, findNode.fieldDeclaration(code));
  }

  void test_visitFieldDeclaration_augment() {
    var code = 'augment var a = 0;';
    var findNode = _parseStringToFindNode('''
augment class A {
  $code
}
''');
    _assertSource(code, findNode.fieldDeclaration(code));
  }

  void test_visitFieldDeclaration_external() {
    var code = 'external var a;';
    var findNode = _parseStringToFindNode('''
class A {
  $code
}
''');
    _assertSource(code, findNode.fieldDeclaration(code));
  }

  void test_visitFieldDeclaration_instance() {
    var code = 'var a;';
    var findNode = _parseStringToFindNode('''
class A {
  $code
}
''');
    _assertSource(code, findNode.fieldDeclaration(code));
  }

  void test_visitFieldDeclaration_static() {
    var code = 'static var a;';
    var findNode = _parseStringToFindNode('''
class A {
  $code
}
''');
    _assertSource(code, findNode.fieldDeclaration(code));
  }

  void test_visitFieldDeclaration_withMetadata() {
    var code = '@deprecated var a;';
    var findNode = _parseStringToFindNode('''
class A {
  $code
}
''');
    _assertSource(code, findNode.fieldDeclaration(code));
  }

  void test_visitFieldFormalParameter_annotation() {
    var code = '@deprecated this.foo';
    var findNode = _parseStringToFindNode('''
class A {
  final int foo;
  A($code);
}
''');
    _assertSource(code, findNode.fieldFormalParameter(code));
  }

  void test_visitFieldFormalParameter_functionTyped() {
    var code = 'A this.a(b)';
    var findNode = _parseStringToFindNode('''
class A {
  A($code);
}
''');
    _assertSource(code, findNode.fieldFormalParameter(code));
  }

  void test_visitFieldFormalParameter_functionTyped_typeParameters() {
    var code = 'A this.a<E, F>(b)';
    var findNode = _parseStringToFindNode('''
class A {
  A($code);
}
''');
    _assertSource(code, findNode.fieldFormalParameter(code));
  }

  void test_visitFieldFormalParameter_keyword() {
    var code = 'var this.a';
    var findNode = _parseStringToFindNode('''
class A {
  A($code);
}
''');
    _assertSource(code, findNode.fieldFormalParameter(code));
  }

  void test_visitFieldFormalParameter_keywordAndType() {
    var code = 'final A this.a';
    var findNode = _parseStringToFindNode('''
class A {
  A($code);
}
''');
    _assertSource(code, findNode.fieldFormalParameter(code));
  }

  void test_visitFieldFormalParameter_type() {
    var code = 'A this.a';
    var findNode = _parseStringToFindNode('''
class A {
  A($code);
}
''');
    _assertSource(code, findNode.fieldFormalParameter(code));
  }

  void test_visitFieldFormalParameter_type_covariant() {
    var code = 'covariant A this.a';
    var findNode = _parseStringToFindNode('''
class A {
  A($code);
}
''');
    _assertSource(code, findNode.fieldFormalParameter(code));
  }

  void test_visitForEachPartsWithIdentifier() {
    var code = 'e in []';
    var findNode = _parseStringToFindNode('''
void f() {
  for ($code) {}
}
''');
    _assertSource(code, findNode.forEachPartsWithIdentifier(code));
  }

  void test_visitForEachPartsWithPattern() {
    var code = 'final (a, b) in c';
    var findNode = _parseStringToFindNode('''
void f () {
  for ($code) {}
}
''');
    _assertSource(code, findNode.forEachPartsWithPattern(code));
  }

  void test_visitForEachStatement_declared() {
    var code = 'for (final a in b) {}';
    var findNode = _parseStringToFindNode('''
void f () {
  $code
}
''');
    _assertSource(code, findNode.forStatement(code));
  }

  void test_visitForEachStatement_variable() {
    var code = 'for (a in b) {}';
    var findNode = _parseStringToFindNode('''
void f () {
  $code
}
''');
    _assertSource(code, findNode.forStatement(code));
  }

  void test_visitForEachStatement_variable_await() {
    var code = 'await for (final a in b) {}';
    var findNode = _parseStringToFindNode('''
void f() async {
  $code
}
''');
    _assertSource(code, findNode.forStatement(code));
  }

  void test_visitForElement() {
    var code = 'for (e in []) 0';
    var findNode = _parseStringToFindNode('''
final v = [ $code ];
''');
    _assertSource(code, findNode.forElement(code));
  }

  void test_visitFormalParameterList_empty() {
    var code = '()';
    var findNode = _parseStringToFindNode('''
void f$code {}
''');
    _assertSource(code, findNode.formalParameterList(code));
  }

  void test_visitFormalParameterList_n() {
    var code = '({a = 0})';
    var findNode = _parseStringToFindNode('''
void f$code {}
''');
    _assertSource(code, findNode.formalParameterList(code));
  }

  void test_visitFormalParameterList_namedRequired() {
    var code = '({required a, required int b})';
    var findNode = _parseStringToFindNode('''
void f$code {}
''');
    _assertSource(code, findNode.formalParameterList(code));
  }

  void test_visitFormalParameterList_nn() {
    var code = '({int a = 0, b = 1})';
    var findNode = _parseStringToFindNode('''
void f$code {}
''');
    _assertSource(code, findNode.formalParameterList(code));
  }

  void test_visitFormalParameterList_p() {
    var code = '([a = 0])';
    var findNode = _parseStringToFindNode('''
void f$code {}
''');
    _assertSource(code, findNode.formalParameterList(code));
  }

  void test_visitFormalParameterList_pp() {
    var code = '([a = 0, b = 1])';
    var findNode = _parseStringToFindNode('''
void f$code {}
''');
    _assertSource(code, findNode.formalParameterList(code));
  }

  void test_visitFormalParameterList_r() {
    var code = '(int a)';
    var findNode = _parseStringToFindNode('''
void f$code {}
''');
    _assertSource(code, findNode.formalParameterList(code));
  }

  void test_visitFormalParameterList_rn() {
    var code = '(a, {b = 1})';
    var findNode = _parseStringToFindNode('''
void f$code {}
''');
    _assertSource(code, findNode.formalParameterList(code));
  }

  void test_visitFormalParameterList_rnn() {
    var code = '(a, {b = 1, c = 2})';
    var findNode = _parseStringToFindNode('''
void f$code {}
''');
    _assertSource(code, findNode.formalParameterList(code));
  }

  void test_visitFormalParameterList_rp() {
    var code = '(a, [b = 1])';
    var findNode = _parseStringToFindNode('''
void f$code {}
''');
    _assertSource(code, findNode.formalParameterList(code));
  }

  void test_visitFormalParameterList_rpp() {
    var code = '(a, [b = 1, c = 2])';
    var findNode = _parseStringToFindNode('''
void f$code {}
''');
    _assertSource(code, findNode.formalParameterList(code));
  }

  void test_visitFormalParameterList_rr() {
    var code = '(int a, int b)';
    var findNode = _parseStringToFindNode('''
void f$code {}
''');
    _assertSource(code, findNode.formalParameterList(code));
  }

  void test_visitFormalParameterList_rrn() {
    var code = '(a, b, {c = 2})';
    var findNode = _parseStringToFindNode('''
void f$code {}
''');
    _assertSource(code, findNode.formalParameterList(code));
  }

  void test_visitFormalParameterList_rrnn() {
    var code = '(a, b, {c = 2, d = 3})';
    var findNode = _parseStringToFindNode('''
void f$code {}
''');
    _assertSource(code, findNode.formalParameterList(code));
  }

  void test_visitFormalParameterList_rrp() {
    var code = '(a, b, [c = 2])';
    var findNode = _parseStringToFindNode('''
void f$code {}
''');
    _assertSource(code, findNode.formalParameterList(code));
  }

  void test_visitFormalParameterList_rrpp() {
    var code = '(a, b, [c = 2, d = 3])';
    var findNode = _parseStringToFindNode('''
void f$code {}
''');
    _assertSource(code, findNode.formalParameterList(code));
  }

  void test_visitForPartsWithDeclarations() {
    var code = 'var v = 0; v < 10; v++';
    var findNode = _parseStringToFindNode('''
void f() {
  for ($code) {}
}
''');
    _assertSource(code, findNode.forPartsWithDeclarations(code));
  }

  void test_visitForPartsWithExpression() {
    var code = 'v = 0; v < 10; v++';
    var findNode = _parseStringToFindNode('''
void f() {
  for ($code) {}
}
''');
    _assertSource(code, findNode.forPartsWithExpression(code));
  }

  @failingTest
  void test_visitForPartsWithPattern() {
    // TODO(brianwilkerson): Test this when the parser allows.
    fail('Unable to parse patterns');
  }

  void test_visitForStatement() {
    var code = 'for (var v in [0]) {}';
    var findNode = _parseStringToFindNode('''
void f() {
  $code
}
''');
    _assertSource(code, findNode.forStatement(code));
  }

  void test_visitForStatement_c() {
    var code = 'for (; c;) {}';
    var findNode = _parseStringToFindNode('''
void f () {
  $code
}
''');
    _assertSource(code, findNode.forStatement(code));
  }

  void test_visitForStatement_cu() {
    var code = 'for (; c; u) {}';
    var findNode = _parseStringToFindNode('''
void f () {
  $code
}
''');
    _assertSource(code, findNode.forStatement(code));
  }

  void test_visitForStatement_e() {
    var code = 'for (e;;) {}';
    var findNode = _parseStringToFindNode('''
void f () {
  $code
}
''');
    _assertSource(code, findNode.forStatement(code));
  }

  void test_visitForStatement_ec() {
    var code = 'for (e; c;) {}';
    var findNode = _parseStringToFindNode('''
void f () {
  $code
}
''');
    _assertSource(code, findNode.forStatement(code));
  }

  void test_visitForStatement_ecu() {
    var code = 'for (e; c; u) {}';
    var findNode = _parseStringToFindNode('''
void f () {
  $code
}
''');
    _assertSource(code, findNode.forStatement(code));
  }

  void test_visitForStatement_eu() {
    var code = 'for (e;; u) {}';
    var findNode = _parseStringToFindNode('''
void f () {
  $code
}
''');
    _assertSource(code, findNode.forStatement(code));
  }

  void test_visitForStatement_i() {
    var code = 'for (var i;;) {}';
    var findNode = _parseStringToFindNode('''
void f () {
  $code
}
''');
    _assertSource(code, findNode.forStatement(code));
  }

  void test_visitForStatement_ic() {
    var code = 'for (var i; c;) {}';
    var findNode = _parseStringToFindNode('''
void f () {
  $code
}
''');
    _assertSource(code, findNode.forStatement(code));
  }

  void test_visitForStatement_icu() {
    var code = 'for (var i; c; u) {}';
    var findNode = _parseStringToFindNode('''
void f () {
  $code
}
''');
    _assertSource(code, findNode.forStatement(code));
  }

  void test_visitForStatement_iu() {
    var code = 'for (var i;; u) {}';
    var findNode = _parseStringToFindNode('''
void f () {
  $code
}
''');
    _assertSource(code, findNode.forStatement(code));
  }

  void test_visitForStatement_u() {
    var code = 'for (;; u) {}';
    var findNode = _parseStringToFindNode('''
void f () {
  $code
}
''');
    _assertSource(code, findNode.forStatement(code));
  }

  void test_visitFunctionDeclaration_external() {
    var code = 'external void f();';
    var findNode = _parseStringToFindNode(code);
    _assertSource(code, findNode.functionDeclaration(code));
  }

  void test_visitFunctionDeclaration_getter() {
    var code = 'get foo {}';
    var findNode = _parseStringToFindNode(code);
    _assertSource(code, findNode.functionDeclaration(code));
  }

  void test_visitFunctionDeclaration_local_blockBody() {
    var code = 'void foo() {}';
    var findNode = _parseStringToFindNode('''
void f() {
  $code
}
''');
    _assertSource(code, findNode.functionDeclaration(code));
  }

  void test_visitFunctionDeclaration_local_expressionBody() {
    var code = 'int foo() => 42;';
    var findNode = _parseStringToFindNode('''
void f() {
  $code
}
''');
    _assertSource(code, findNode.functionDeclaration(code));
  }

  void test_visitFunctionDeclaration_normal() {
    var code = 'void foo() {}';
    var findNode = _parseStringToFindNode(code);
    _assertSource(code, findNode.functionDeclaration(code));
  }

  void test_visitFunctionDeclaration_setter() {
    var code = 'set foo(int _) {}';
    var findNode = _parseStringToFindNode(code);
    _assertSource(code, findNode.functionDeclaration(code));
  }

  void test_visitFunctionDeclaration_typeParameters() {
    var code = 'void foo<T>() {}';
    var findNode = _parseStringToFindNode(code);
    _assertSource(code, findNode.functionDeclaration(code));
  }

  void test_visitFunctionDeclaration_withMetadata() {
    var code = '@deprecated void f() {}';
    var findNode = _parseStringToFindNode(code);
    _assertSource(code, findNode.functionDeclaration(code));
  }

  void test_visitFunctionDeclarationStatement() {
    var code = 'void foo() {}';
    var findNode = _parseStringToFindNode('''
void f() {
  $code
}
''');
    _assertSource(code, findNode.functionDeclaration(code));
  }

  void test_visitFunctionExpression() {
    var code = '() {}';
    var findNode = _parseStringToFindNode('''
final f = $code;
''');
    _assertSource(code, findNode.functionExpression(code));
  }

  void test_visitFunctionExpression_typeParameters() {
    var code = '<T>() {}';
    var findNode = _parseStringToFindNode('''
final f = $code;
''');
    _assertSource(code, findNode.functionExpression(code));
  }

  void test_visitFunctionExpressionInvocation_minimal() {
    var code = '(a)()';
    var findNode = _parseStringToFindNode('''
void f() {
  $code;
}
''');
    _assertSource(code, findNode.functionExpressionInvocation(code));
  }

  void test_visitFunctionExpressionInvocation_typeArguments() {
    var code = '(a)<int>()';
    var findNode = _parseStringToFindNode('''
void f() {
  $code;
}
''');
    _assertSource(code, findNode.functionExpressionInvocation(code));
  }

  void test_visitFunctionTypeAlias_generic() {
    var code = 'typedef A F<B>();';
    var findNode = _parseStringToFindNode('''
$code
''');
    _assertSource(code, findNode.functionTypeAlias(code));
  }

  void test_visitFunctionTypeAlias_nonGeneric() {
    var code = 'typedef A F();';
    var findNode = _parseStringToFindNode('''
$code
''');
    _assertSource(code, findNode.functionTypeAlias(code));
  }

  void test_visitFunctionTypeAlias_withMetadata() {
    var code = '@deprecated typedef void F();';
    var findNode = _parseStringToFindNode(code);
    _assertSource(code, findNode.functionTypeAlias(code));
  }

  void test_visitFunctionTypedFormalParameter_annotation() {
    var code = '@deprecated g()';
    var findNode = _parseStringToFindNode('''
void f($code) {}
''');
    _assertSource(code, findNode.functionTypedFormalParameter(code));
  }

  void test_visitFunctionTypedFormalParameter_noType() {
    var code = 'int f()';
    var findNode = _parseStringToFindNode('''
void f($code) {}
''');
    _assertSource(code, findNode.functionTypedFormalParameter(code));
  }

  void test_visitFunctionTypedFormalParameter_nullable() {
    var code = 'T f()?';
    var findNode = _parseStringToFindNode('''
void f($code) {}
''');
    _assertSource(code, findNode.functionTypedFormalParameter(code));
  }

  void test_visitFunctionTypedFormalParameter_type() {
    var code = 'T f()';
    var findNode = _parseStringToFindNode('''
void f($code) {}
''');
    _assertSource(code, findNode.functionTypedFormalParameter(code));
  }

  void test_visitFunctionTypedFormalParameter_type_covariant() {
    var code = 'covariant T f()?';
    var findNode = _parseStringToFindNode('''
class A {
  void foo($code) {}
}
''');
    _assertSource(code, findNode.functionTypedFormalParameter(code));
  }

  void test_visitFunctionTypedFormalParameter_typeParameters() {
    var code = 'T f<E>()';
    var findNode = _parseStringToFindNode('''
void f($code) {}
''');
    _assertSource(code, findNode.functionTypedFormalParameter(code));
  }

  void test_visitGenericFunctionType() {
    var code = 'int Function<T>(T)';
    var findNode = _parseStringToFindNode('''
void f($code x) {}
''');
    _assertSource(code, findNode.genericFunctionType(code));
  }

  void test_visitGenericFunctionType_withQuestion() {
    var code = 'int Function<T>(T)?';
    var findNode = _parseStringToFindNode('''
void f($code x) {}
''');
    _assertSource(code, findNode.genericFunctionType(code));
  }

  void test_visitGenericTypeAlias() {
    var code = 'typedef X<S> = S Function<T>(T);';
    var findNode = _parseStringToFindNode('''
$code
''');
    _assertSource(code, findNode.genericTypeAlias(code));
  }

  void test_visitGenericTypeAlias_augment() {
    var code = 'augment typedef A = int;';
    var findNode = _parseStringToFindNode('''
$code
''');
    _assertSource(code, findNode.genericTypeAlias(code));
  }

  void test_visitIfElement_else() {
    var code = 'if (b) 1 else 0';
    var findNode = _parseStringToFindNode('''
final v = [ $code ];
''');
    _assertSource(code, findNode.ifElement(code));
  }

  void test_visitIfElement_then() {
    var code = 'if (b) 1';
    var findNode = _parseStringToFindNode('''
final v = [ $code ];
''');
    _assertSource(code, findNode.ifElement(code));
  }

  void test_visitIfStatement_withElse() {
    var code = 'if (c) {} else {}';
    var findNode = _parseStringToFindNode('''
void f () {
  $code
}
''');
    _assertSource(code, findNode.ifStatement(code));
  }

  void test_visitIfStatement_withoutElse() {
    var code = 'if (c) {}';
    var findNode = _parseStringToFindNode('''
void f() {
  $code
}
''');
    _assertSource(code, findNode.ifStatement(code));
  }

  void test_visitImplementsClause_multiple() {
    var code = 'implements A, B';
    var findNode = _parseStringToFindNode('''
class C $code {}
''');
    _assertSource(code, findNode.implementsClause(code));
  }

  void test_visitImplementsClause_single() {
    var code = 'implements A';
    var findNode = _parseStringToFindNode('''
class C $code {}
''');
    _assertSource(code, findNode.implementsClause(code));
  }

  void test_visitImportDirective_combinator() {
    var code = "import 'a.dart' show A;";
    var findNode = _parseStringToFindNode('''
$code
''');
    _assertSource(code, findNode.import(code));
  }

  void test_visitImportDirective_combinators() {
    var code = "import 'a.dart' show A hide B;";
    var findNode = _parseStringToFindNode('''
$code
''');
    _assertSource(code, findNode.import(code));
  }

  void test_visitImportDirective_configurations() {
    var unit = _parseStringToFindNode(r'''
import 'foo.dart'
  if (dart.library.io) 'foo_io.dart'
  if (dart.library.html) 'foo_html.dart';
''').unit;
    var directive = unit.directives[0] as ImportDirective;
    _assertSource(
      "import 'foo.dart'"
      " if (dart.library.io) 'foo_io.dart'"
      " if (dart.library.html) 'foo_html.dart';",
      directive,
    );
  }

  void test_visitImportDirective_deferred() {
    var code = "import 'a.dart' deferred as p;";
    var findNode = _parseStringToFindNode(code);
    _assertSource(code, findNode.import(code));
  }

  void test_visitImportDirective_minimal() {
    var code = "import 'a.dart';";
    var findNode = _parseStringToFindNode(code);
    _assertSource(code, findNode.import(code));
  }

  void test_visitImportDirective_prefix() {
    var code = "import 'a.dart' as p;";
    var findNode = _parseStringToFindNode(code);
    _assertSource(code, findNode.import(code));
  }

  void test_visitImportDirective_prefix_combinator() {
    var code = "import 'a.dart' as p show A;";
    var findNode = _parseStringToFindNode('''
$code
''');
    _assertSource(code, findNode.import(code));
  }

  void test_visitImportDirective_prefix_combinators() {
    var code = "import 'a.dart' as p show A hide B;";
    var findNode = _parseStringToFindNode('''
$code
''');
    _assertSource(code, findNode.import(code));
  }

  void test_visitImportDirective_withMetadata() {
    var code = '@deprecated import "a.dart";';
    var findNode = _parseStringToFindNode(code);
    _assertSource(code, findNode.import(code));
  }

  void test_visitImportHideCombinator_multiple() {
    var code = 'hide A, B';
    var findNode = _parseStringToFindNode('''
import 'a.dart' $code;
''');
    _assertSource(code, findNode.hideCombinator(code));
  }

  void test_visitImportHideCombinator_single() {
    var code = 'hide A';
    var findNode = _parseStringToFindNode('''
import 'a.dart' $code;
''');
    _assertSource(code, findNode.hideCombinator(code));
  }

  void test_visitImportShowCombinator_multiple() {
    var code = 'show A, B';
    var findNode = _parseStringToFindNode('''
import 'a.dart' $code;
''');
    _assertSource(code, findNode.showCombinator(code));
  }

  void test_visitImportShowCombinator_single() {
    var code = 'show A';
    var findNode = _parseStringToFindNode('''
import 'a.dart' $code;
''');
    _assertSource(code, findNode.showCombinator(code));
  }

  void test_visitIndexExpression() {
    var code = 'a[0]';
    var findNode = _parseStringToFindNode('''
final x = $code;
''');
    _assertSource(code, findNode.index(code));
  }

  void test_visitInstanceCreationExpression_const() {
    var code = 'const A()';
    var findNode = _parseStringToFindNode('''
final x = $code;
''');
    _assertSource(code, findNode.instanceCreation(code));
  }

  void test_visitInstanceCreationExpression_named() {
    var code = 'new A.foo()';
    var findNode = _parseStringToFindNode('''
final x = $code;
''');
    _assertSource(code, findNode.instanceCreation(code));
  }

  void test_visitInstanceCreationExpression_unnamed() {
    var code = 'new A()';
    var findNode = _parseStringToFindNode('''
final x = $code;
''');
    _assertSource(code, findNode.instanceCreation(code));
  }

  void test_visitIntegerLiteral() {
    var code = '42';
    var findNode = _parseStringToFindNode('''
final x = $code;
''');
    _assertSource(code, findNode.integerLiteral(code));
  }

  void test_visitInterpolationExpression_expression() {
    var code = r'${foo}';
    var findNode = _parseStringToFindNode('''
final x = "$code";
''');
    _assertSource(code, findNode.interpolationExpression(code));
  }

  void test_visitInterpolationExpression_identifier() {
    var code = r'$foo';
    var findNode = _parseStringToFindNode('''
final x = "$code";
''');
    _assertSource(code, findNode.interpolationExpression(code));
  }

  void test_visitInterpolationString() {
    var code = "ccc'";
    var findNode = _parseStringToFindNode('''
final x = 'a\${bb}$code;
''');
    _assertSource(code, findNode.interpolationString(code));
  }

  void test_visitIsExpression_negated() {
    var code = 'a is! int';
    var findNode = _parseStringToFindNode('''
final x = $code;
''');
    _assertSource(code, findNode.isExpression(code));
  }

  void test_visitIsExpression_normal() {
    var code = 'a is int';
    var findNode = _parseStringToFindNode('''
final x = $code;
''');
    _assertSource(code, findNode.isExpression(code));
  }

  void test_visitLabel() {
    var code = 'myLabel:';
    var findNode = _parseStringToFindNode('''
void f() {
  $code for (final x in []) {}
}
''');
    _assertSource(code, findNode.label(code));
  }

  void test_visitLabeledStatement_multiple() {
    var code = 'a: b: return;';
    var findNode = _parseStringToFindNode('''
void f() {
  $code
}
''');
    _assertSource(code, findNode.labeledStatement(code));
  }

  void test_visitLabeledStatement_single() {
    var code = 'a: return;';
    var findNode = _parseStringToFindNode('''
void f() {
  $code
}
''');
    _assertSource(code, findNode.labeledStatement(code));
  }

  void test_visitLibraryDirective() {
    var code = 'library my;';
    var findNode = _parseStringToFindNode('''
$code
''');
    _assertSource(code, findNode.library(code));
  }

  void test_visitLibraryDirective_withMetadata() {
    var code = '@deprecated library my;';
    var findNode = _parseStringToFindNode(code);
    _assertSource(code, findNode.library(code));
  }

  void test_visitLibraryIdentifier_multiple() {
    var code = 'a.b.c';
    var findNode = _parseStringToFindNode('''
library $code;
''');
    _assertSource(code, findNode.libraryIdentifier(code));
  }

  void test_visitLibraryIdentifier_single() {
    var code = 'my';
    var findNode = _parseStringToFindNode('''
library $code;
''');
    _assertSource(code, findNode.libraryIdentifier(code));
  }

  void test_visitListLiteral_complex() {
    var code = '<int>[0, for (e in []) 0, if (b) 1, ...[0]]';
    var findNode = _parseStringToFindNode('''
final v = $code;
''');
    _assertSource(code, findNode.listLiteral(code));
  }

  void test_visitListLiteral_const() {
    var code = 'const []';
    var findNode = _parseStringToFindNode('''
final x = $code;
''');
    _assertSource(code, findNode.listLiteral(code));
  }

  void test_visitListLiteral_empty() {
    var code = '[]';
    var findNode = _parseStringToFindNode('''
final x = $code;
''');
    _assertSource(code, findNode.listLiteral(code));
  }

  void test_visitListLiteral_nonEmpty() {
    var code = '[0, 1, 2]';
    var findNode = _parseStringToFindNode('''
final x = $code;
''');
    _assertSource(code, findNode.listLiteral(code));
  }

  void test_visitListLiteral_withConst_withoutTypeArgs() {
    var code = 'const [0]';
    var findNode = _parseStringToFindNode('''
final x = $code;
''');
    _assertSource(code, findNode.listLiteral(code));
  }

  void test_visitListLiteral_withConst_withTypeArgs() {
    var code = 'const <int>[0]';
    var findNode = _parseStringToFindNode('''
final x = $code;
''');
    _assertSource(code, findNode.listLiteral(code));
  }

  void test_visitListLiteral_withoutConst_withoutTypeArgs() {
    var code = '[0]';
    var findNode = _parseStringToFindNode('''
final x = $code;
''');
    _assertSource(code, findNode.listLiteral(code));
  }

  void test_visitListLiteral_withoutConst_withTypeArgs() {
    var code = '<int>[0]';
    var findNode = _parseStringToFindNode('''
final x = $code;
''');
    _assertSource(code, findNode.listLiteral(code));
  }

  void test_visitListPattern_empty() {
    var findNode = _parseStringToFindNode('''
void f(x) {
  switch (x) {
    case []:
      break;
  }
}
''');
    _assertSource(
      '[]',
      findNode.listPattern('[]'),
    );
  }

  void test_visitListPattern_nonEmpty() {
    var findNode = _parseStringToFindNode('''
void f(x) {
  switch (x) {
    case [1, 2]:
      break;
  }
}
''');
    _assertSource(
      '[1, 2]',
      findNode.listPattern('1'),
    );
  }

  void test_visitListPattern_withTypeArguments() {
    var findNode = _parseStringToFindNode('''
void f(x) {
  switch (x) {
    case <int>[]:
      break;
  }
}
''');
    _assertSource(
      '<int>[]',
      findNode.listPattern('[]'),
    );
  }

  void test_visitLogicalAndPattern() {
    var findNode = _parseStringToFindNode('''
void f(x) {
  switch (x) {
    case int? _ && double? _ && Object? _:
      break;
  }
}
''');
    _assertSource(
      'int? _ && double? _ && Object? _',
      findNode.logicalAndPattern('Object?'),
    );
  }

  void test_visitLogicalOrPattern() {
    var findNode = _parseStringToFindNode('''
void f(x) {
  switch (x) {
    case int? _ || double? _ || Object? _:
      break;
  }
}
''');
    _assertSource(
      'int? _ || double? _ || Object? _',
      findNode.logicalOrPattern('Object?'),
    );
  }

  void test_visitMapLiteral_const() {
    var code = 'const {}';
    var findNode = _parseStringToFindNode('''
final x = $code;
''');
    _assertSource(code, findNode.setOrMapLiteral(code));
  }

  void test_visitMapLiteral_empty() {
    var code = '{}';
    var findNode = _parseStringToFindNode('''
final x = $code;
''');
    _assertSource(code, findNode.setOrMapLiteral(code));
  }

  void test_visitMapLiteral_nonEmpty() {
    var code = '{0 : a, 1 : b, 2 : c}';
    var findNode = _parseStringToFindNode('''
final x = $code;
''');
    _assertSource(code, findNode.setOrMapLiteral(code));
  }

  void test_visitMapLiteralEntry() {
    var code = '0 : a';
    var findNode = _parseStringToFindNode('''
final x = {$code};
''');
    _assertSource(code, findNode.mapLiteralEntry(code));
  }

  void test_visitMapPattern_empty() {
    var findNode = _parseStringToFindNode('''
void f(x) {
  switch (x) {
    case {}:
      break;
  }
}
''');
    _assertSource(
      '{}',
      findNode.mapPattern('{}'),
    );
  }

  void test_visitMapPattern_notEmpty() {
    var findNode = _parseStringToFindNode('''
void f(x) {
  switch (x) {
    case {1: 2}:
      break;
  }
}
''');
    _assertSource(
      '{1: 2}',
      findNode.mapPattern('1'),
    );
  }

  void test_visitMapPattern_withTypeArguments() {
    var findNode = _parseStringToFindNode('''
void f(x) {
  switch (x) {
    case <int, int>{}:
      break;
  }
}
''');
    _assertSource(
      '<int, int>{}',
      findNode.mapPattern('{}'),
    );
  }

  void test_visitMapPatternEntry() {
    var findNode = _parseStringToFindNode('''
void f(x) {
  switch (x) {
    case {1: 2}:
      break;
  }
}
''');
    _assertSource(
      '1: 2',
      findNode.mapPatternEntry('1'),
    );
  }

  void test_visitMethodDeclaration_augment() {
    var code = 'augment void foo() {}';
    var findNode = _parseStringToFindNode('''
class A {
  $code
}
''');
    _assertSource(code, findNode.singleMethodDeclaration);
  }

  void test_visitMethodDeclaration_external() {
    var code = 'external foo();';
    var findNode = _parseStringToFindNode('''
class A {
  $code
}
''');
    _assertSource(code, findNode.methodDeclaration(code));
  }

  void test_visitMethodDeclaration_external_returnType() {
    var code = 'external int foo();';
    var findNode = _parseStringToFindNode('''
class A {
  $code
}
''');
    _assertSource(code, findNode.methodDeclaration(code));
  }

  void test_visitMethodDeclaration_getter() {
    var code = 'get foo => 0;';
    var findNode = _parseStringToFindNode('''
class A {
  $code
}
''');
    _assertSource(code, findNode.methodDeclaration(code));
  }

  void test_visitMethodDeclaration_getter_returnType() {
    var code = 'int get foo => 0;';
    var findNode = _parseStringToFindNode('''
class A {
  $code
}
''');
    _assertSource(code, findNode.methodDeclaration(code));
  }

  void test_visitMethodDeclaration_minimal() {
    var code = 'foo() {}';
    var findNode = _parseStringToFindNode('''
class A {
  $code
}
''');
    _assertSource(code, findNode.methodDeclaration(code));
  }

  void test_visitMethodDeclaration_multipleParameters() {
    var code = 'void foo(int a, double b) {}';
    var findNode = _parseStringToFindNode('''
class A {
  $code
}
''');
    _assertSource(code, findNode.methodDeclaration(code));
  }

  void test_visitMethodDeclaration_operator() {
    var code = 'operator +(int other) {}';
    var findNode = _parseStringToFindNode('''
class A {
  $code
}
''');
    _assertSource(code, findNode.methodDeclaration(code));
  }

  void test_visitMethodDeclaration_operator_returnType() {
    var code = 'int operator +(int other) => 0;';
    var findNode = _parseStringToFindNode('''
class A {
  $code
}
''');
    _assertSource(code, findNode.methodDeclaration(code));
  }

  void test_visitMethodDeclaration_returnType() {
    var code = 'int foo() => 0;';
    var findNode = _parseStringToFindNode('''
class A {
  $code
}
''');
    _assertSource(code, findNode.methodDeclaration(code));
  }

  void test_visitMethodDeclaration_setter() {
    var code = 'set foo(int _) {}';
    var findNode = _parseStringToFindNode('''
class A {
  $code
}
''');
    _assertSource(code, findNode.methodDeclaration(code));
  }

  void test_visitMethodDeclaration_setter_returnType() {
    var code = 'void set foo(int _) {}';
    var findNode = _parseStringToFindNode('''
class A {
  $code
}
''');
    _assertSource(code, findNode.methodDeclaration(code));
  }

  void test_visitMethodDeclaration_static() {
    var code = 'static foo() {}';
    var findNode = _parseStringToFindNode('''
class A {
  $code
}
''');
    _assertSource(code, findNode.methodDeclaration(code));
  }

  void test_visitMethodDeclaration_static_returnType() {
    var code = 'static void foo() {}';
    var findNode = _parseStringToFindNode('''
class A {
  $code
}
''');
    _assertSource(code, findNode.methodDeclaration(code));
  }

  void test_visitMethodDeclaration_typeParameters() {
    var code = 'void foo<T>() {}';
    var findNode = _parseStringToFindNode('''
class A {
  $code
}
''');
    _assertSource(code, findNode.methodDeclaration(code));
  }

  void test_visitMethodDeclaration_withMetadata() {
    var code = '@deprecated void foo() {}';
    var findNode = _parseStringToFindNode('''
class A {
  $code
}
''');
    _assertSource(code, findNode.methodDeclaration(code));
  }

  void test_visitMethodInvocation_conditional() {
    var code = 'a?.foo()';
    var findNode = _parseStringToFindNode('''
void f() {
  $code;
}
''');
    _assertSource(code, findNode.methodInvocation(code));
  }

  void test_visitMethodInvocation_noTarget() {
    var code = 'foo()';
    var findNode = _parseStringToFindNode('''
void f() {
  $code;
}
''');
    _assertSource(code, findNode.methodInvocation(code));
  }

  void test_visitMethodInvocation_target() {
    var code = 'a.foo()';
    var findNode = _parseStringToFindNode('''
void f() {
  $code;
}
''');
    _assertSource(code, findNode.methodInvocation(code));
  }

  void test_visitMethodInvocation_typeArguments() {
    var code = 'foo<int>()';
    var findNode = _parseStringToFindNode('''
void f() {
  $code;
}
''');
    _assertSource(code, findNode.methodInvocation(code));
  }

  void test_visitMixinDeclaration_augment() {
    var code = 'augment mixin M {}';
    var findNode = _parseStringToFindNode(code);
    _assertSource(
      code,
      findNode.singleMixinDeclaration,
    );
  }

  void test_visitMixinDeclaration_augment_base() {
    var code = 'augment base mixin M {}';
    var findNode = _parseStringToFindNode(code);
    _assertSource(
      code,
      findNode.singleMixinDeclaration,
    );
  }

  void test_visitMixinDeclaration_base() {
    var findNode = _parseStringToFindNode(r'''
base mixin M {}
''');
    _assertSource(
      'base mixin M {}',
      findNode.mixinDeclaration('mixin M'),
    );
  }

  void test_visitNamedExpression() {
    var code = 'a: 0';
    var findNode = _parseStringToFindNode('''
void f() {
  foo($code);
}
''');
    _assertSource(code, findNode.namedExpression(code));
  }

  void test_visitNamedFormalParameter() {
    var code = 'var a = 0';
    var findNode = _parseStringToFindNode('''
void f({$code}) {}
''');
    _assertSource(code, findNode.defaultParameter(code));
  }

  void test_visitNamedType_multipleArgs() {
    var code = 'Map<int, String>';
    var findNode = _parseStringToFindNode('''
final x = <$code>[];
''');
    _assertSource(code, findNode.namedType(code));
  }

  void test_visitNamedType_nestedArg() {
    var code = 'List<Set<int>>';
    var findNode = _parseStringToFindNode('''
final x = <$code>[];
''');
    _assertSource(code, findNode.namedType(code));
  }

  void test_visitNamedType_noArgs() {
    var code = 'int';
    var findNode = _parseStringToFindNode('''
final x = <$code>[];
''');
    _assertSource(code, findNode.namedType(code));
  }

  void test_visitNamedType_noArgs_withQuestion() {
    var code = 'int?';
    var findNode = _parseStringToFindNode('''
final x = <$code>[];
''');
    _assertSource(code, findNode.namedType(code));
  }

  void test_visitNamedType_singleArg() {
    var code = 'Set<int>';
    var findNode = _parseStringToFindNode('''
final x = <$code>[];
''');
    _assertSource(code, findNode.namedType(code));
  }

  void test_visitNamedType_singleArg_withQuestion() {
    var code = 'Set<int>?';
    var findNode = _parseStringToFindNode('''
final x = <$code>[];
''');
    _assertSource(code, findNode.namedType(code));
  }

  void test_visitNativeClause() {
    var code = "native 'code'";
    var findNode = _parseStringToFindNode('''
class A $code {}
''');
    _assertSource(code, findNode.nativeClause(code));
  }

  void test_visitNativeFunctionBody() {
    var code = "native 'code';";
    var findNode = _parseStringToFindNode('''
void foo() $code
''');
    _assertSource(code, findNode.nativeFunctionBody(code));
  }

  void test_visitNullLiteral() {
    var code = 'null';
    var findNode = _parseStringToFindNode('''
final x = $code;
''');
    _assertSource(code, findNode.nullLiteral(code));
  }

  void test_visitObjectPattern() {
    var findNode = _parseStringToFindNode('''
void f(x) {
  switch (x) {
    case C(f: 1):
      break;
  }
}
''');
    _assertSource(
      'C(f: 1)',
      findNode.objectPattern('C'),
    );
  }

  void test_visitParenthesizedExpression() {
    var code = '(a)';
    var findNode = _parseStringToFindNode('''
final x = $code;
''');
    _assertSource(code, findNode.parenthesized(code));
  }

  void test_visitParenthesizedPattern() {
    var findNode = _parseStringToFindNode('''
void f(x) {
  switch (x) {
    case (3):
      break;
  }
}
''');
    _assertSource(
      '(3)',
      findNode.parenthesizedPattern('(3'),
    );
  }

  void test_visitPartDirective() {
    var code = "part 'a.dart';";
    var findNode = _parseStringToFindNode(code);
    _assertSource(code, findNode.part(code));
  }

  void test_visitPartDirective_configurations() {
    var unit = _parseStringToFindNode(r'''
part 'foo.dart'
  if (dart.library.io) 'foo_io.dart'
  if (dart.library.html) 'foo_html.dart';
''').unit;
    var directive = unit.directives[0] as PartDirective;
    _assertSource(
      "part 'foo.dart'"
      " if (dart.library.io) 'foo_io.dart'"
      " if (dart.library.html) 'foo_html.dart';",
      directive,
    );
  }

  void test_visitPartDirective_withMetadata() {
    var code = '@deprecated part "a.dart";';
    var findNode = _parseStringToFindNode(code);
    _assertSource(code, findNode.part(code));
  }

  void test_visitPartOfDirective_name() {
    var unit = _parseStringToFindNode(
      'part of l;',
      featureSet: FeatureSets.language_3_4,
    ).unit;
    var directive = unit.directives[0] as PartOfDirective;
    _assertSource("part of l;", directive);
  }

  void test_visitPartOfDirective_uri() {
    var unit = _parseStringToFindNode("part of 'a.dart';").unit;
    var directive = unit.directives[0] as PartOfDirective;
    _assertSource("part of 'a.dart';", directive);
  }

  void test_visitPartOfDirective_withMetadata() {
    var code = "@deprecated part of 'a.dart';";
    var findNode = _parseStringToFindNode(code);
    _assertSource(code, findNode.partOf(code));
  }

  @failingTest
  void test_visitPatternAssignment() {
    // TODO(brianwilkerson): Test this when the parser allows.
    fail('Unable to parse patterns');
  }

  @failingTest
  void test_visitPatternAssignmentStatement() {
    // TODO(brianwilkerson): Test this when the parser allows.
    fail('Unable to parse patterns');
  }

  void test_visitPatternField_named() {
    var findNode = _parseStringToFindNode('''
void f(x) {
  switch (x) {
    case (a: 1):
      break;
  }
}
''');
    _assertSource(
      'a: 1',
      findNode.patternField('1'),
    );
  }

  void test_visitPatternField_positional() {
    var findNode = _parseStringToFindNode('''
void f(x) {
  switch (x) {
    case (1,):
      break;
  }
}
''');
    _assertSource(
      '1',
      findNode.patternField('1'),
    );
  }

  void test_visitPatternFieldName() {
    var findNode = _parseStringToFindNode('''
void f(x) {
  switch (x) {
    case (b: 2):
      break;
  }
}
''');
    _assertSource(
      'b:',
      findNode.patternFieldName('b:'),
    );
  }

  @failingTest
  void test_visitPatternVariableDeclaration() {
    // TODO(brianwilkerson): Test this when the parser allows.
    fail('Unable to parse patterns');
  }

  @failingTest
  void test_visitPatternVariableDeclarationStatement() {
    // TODO(brianwilkerson): Test this when the parser allows.
    fail('Unable to parse patterns');
  }

  void test_visitPositionalFormalParameter() {
    var code = 'var a = 0';
    var findNode = _parseStringToFindNode('''
void f([$code]) {}
''');
    _assertSource(code, findNode.defaultParameter(code));
  }

  void test_visitPostfixExpression() {
    var code = 'a++';
    var findNode = _parseStringToFindNode('''
int f() {
  $code;
}
''');
    _assertSource(code, findNode.postfix(code));
  }

  void test_visitPostfixPattern() {
    var findNode = _parseStringToFindNode('''
void f(x) {
  switch (x) {
    case true!:
      break;
  }
}
''');
    _assertSource(
      'true!',
      findNode.nullAssertPattern('true'),
    );
  }

  void test_visitPrefixedIdentifier() {
    var code = 'foo.bar';
    var findNode = _parseStringToFindNode('''
int f() {
  $code;
}
''');
    _assertSource(code, findNode.prefixed(code));
  }

  void test_visitPrefixExpression() {
    var code = '-foo';
    var findNode = _parseStringToFindNode('''
int f() {
  $code;
}
''');
    _assertSource(code, findNode.prefix(code));
  }

  void test_visitPrefixExpression_precedence() {
    var findNode = _parseStringToFindNode(r'''
var v = !(a == b);
''');
    _assertSource(
      '!(a == b)',
      findNode.prefix('!'),
    );
  }

  void test_visitPropertyAccess() {
    var code = '(foo).bar';
    var findNode = _parseStringToFindNode('''
final x = $code;
''');
    _assertSource(code, findNode.propertyAccess(code));
  }

  void test_visitPropertyAccess_conditional() {
    var code = 'foo?.bar';
    var findNode = _parseStringToFindNode('''
final x = $code;
''');
    _assertSource(code, findNode.propertyAccess(code));
  }

  void test_visitRecordLiteral_mixed() {
    var code = '(0, true, a: 0, b: true)';
    var findNode = _parseStringToFindNode('''
final x = $code;
''');
    _assertSource(
      code,
      findNode.recordLiteral(code),
    );
  }

  void test_visitRecordLiteral_named() {
    var code = '(a: 0, b: true)';
    var findNode = _parseStringToFindNode('''
final x = $code;
''');
    _assertSource(
      code,
      findNode.recordLiteral(code),
    );
  }

  void test_visitRecordLiteral_positional() {
    var code = '(0, true)';
    var findNode = _parseStringToFindNode('''
final x = $code;
''');
    _assertSource(
      code,
      findNode.recordLiteral(code),
    );
  }

  void test_visitRecordPattern() {
    var findNode = _parseStringToFindNode('''
void f(x) {
  switch (x) {
    case (1, 2):
      break;
  }
}
''');
    _assertSource(
      '(1, 2)',
      findNode.recordPattern('(1'),
    );
  }

  void test_visitRecordTypeAnnotation_mixed() {
    var code = '(int, bool, {int a, bool b})';
    var findNode = _parseStringToFindNode('''
$code f() {}
''');
    _assertSource(
      code,
      findNode.recordTypeAnnotation(code),
    );
  }

  void test_visitRecordTypeAnnotation_named() {
    var code = '({int a, bool b})';
    var findNode = _parseStringToFindNode('''
$code f() {}
''');
    _assertSource(
      code,
      findNode.recordTypeAnnotation(code),
    );
  }

  void test_visitRecordTypeAnnotation_positional() {
    var code = '(int, bool)';
    var findNode = _parseStringToFindNode('''
$code f() {}
''');
    _assertSource(
      code,
      findNode.recordTypeAnnotation(code),
    );
  }

  void test_visitRecordTypeAnnotation_positional_nullable() {
    var code = '(int, bool)?';
    var findNode = _parseStringToFindNode('''
$code f() {}
''');
    _assertSource(
      code,
      findNode.recordTypeAnnotation(code),
    );
  }

  void test_visitRedirectingConstructorInvocation_named() {
    var code = 'this.named()';
    var findNode = _parseStringToFindNode('''
class A {
  A() : $code;
}
''');
    _assertSource(
      code,
      findNode.redirectingConstructorInvocation(code),
    );
  }

  void test_visitRedirectingConstructorInvocation_unnamed() {
    var code = 'this()';
    var findNode = _parseStringToFindNode('''
class A {
  A.named() : $code;
}
''');
    _assertSource(
      code,
      findNode.redirectingConstructorInvocation(code),
    );
  }

  void test_visitRelationalPattern() {
    var findNode = _parseStringToFindNode('''
void f(x) {
  switch (x) {
    case > 3:
      break;
  }
}
''');
    _assertSource(
      '> 3',
      findNode.relationalPattern('>'),
    );
  }

  void test_visitRethrowExpression() {
    var code = 'rethrow';
    var findNode = _parseStringToFindNode('''
void f() {
  try {} on int {
    $code;
  }
}
''');
    _assertSource(code, findNode.rethrow_(code));
  }

  void test_visitReturnStatement_expression() {
    var code = 'return 0;';
    var findNode = _parseStringToFindNode('''
int f() {
  $code
}
''');
    _assertSource(code, findNode.returnStatement(code));
  }

  void test_visitReturnStatement_noExpression() {
    var code = 'return;';
    var findNode = _parseStringToFindNode('''
int f() {
  $code
}
''');
    _assertSource(code, findNode.returnStatement(code));
  }

  void test_visitSetOrMapLiteral_map_complex() {
    var code =
        "<String, String>{'a' : 'b', for (c in d) 'e' : 'f', if (g) 'h' : 'i', ...{'j' : 'k'}}";
    var findNode = _parseStringToFindNode('''
final v = $code;
''');
    _assertSource(code, findNode.setOrMapLiteral(code));
  }

  void test_visitSetOrMapLiteral_map_withConst_withoutTypeArgs() {
    var code = 'const {0 : a}';
    var findNode = _parseStringToFindNode('''
final x = $code;
''');
    _assertSource(code, findNode.setOrMapLiteral(code));
  }

  void test_visitSetOrMapLiteral_map_withConst_withTypeArgs() {
    var code = 'const <int, String>{0 : a}';
    var findNode = _parseStringToFindNode('''
final x = $code;
''');
    _assertSource(code, findNode.setOrMapLiteral(code));
  }

  void test_visitSetOrMapLiteral_map_withoutConst_withoutTypeArgs() {
    var code = '{0 : a}';
    var findNode = _parseStringToFindNode('''
final x = $code;
''');
    _assertSource(code, findNode.setOrMapLiteral(code));
  }

  void test_visitSetOrMapLiteral_map_withoutConst_withTypeArgs() {
    var code = '<int, String>{0 : a}';
    var findNode = _parseStringToFindNode('''
final x = $code;
''');
    _assertSource(code, findNode.setOrMapLiteral(code));
  }

  void test_visitSetOrMapLiteral_set_complex() {
    var code = '<int>{0, for (e in l) 0, if (b) 1, ...[0]}';
    var findNode = _parseStringToFindNode('''
final v = $code;
''');
    _assertSource(code, findNode.setOrMapLiteral(code));
  }

  void test_visitSetOrMapLiteral_set_withConst_withoutTypeArgs() {
    var code = 'const {0}';
    var findNode = _parseStringToFindNode('''
final x = $code;
''');
    _assertSource(code, findNode.setOrMapLiteral(code));
  }

  void test_visitSetOrMapLiteral_set_withConst_withTypeArgs() {
    var code = 'const <int>{0}';
    var findNode = _parseStringToFindNode('''
final x = $code;
''');
    _assertSource(code, findNode.setOrMapLiteral(code));
  }

  void test_visitSetOrMapLiteral_set_withoutConst_withoutTypeArgs() {
    var code = '{0}';
    var findNode = _parseStringToFindNode('''
final x = $code;
''');
    _assertSource(code, findNode.setOrMapLiteral(code));
  }

  void test_visitSetOrMapLiteral_set_withoutConst_withTypeArgs() {
    var code = '<int>{0}';
    var findNode = _parseStringToFindNode('''
final x = $code;
''');
    _assertSource(code, findNode.setOrMapLiteral(code));
  }

  void test_visitSimpleFormalParameter_annotation() {
    var code = '@deprecated int x';
    var findNode = _parseStringToFindNode('''
void f($code) {}
''');
    _assertSource(code, findNode.simpleFormalParameter(code));
  }

  void test_visitSimpleFormalParameter_keyword() {
    var code = 'var a';
    var findNode = _parseStringToFindNode('''
void f($code) {}
''');
    _assertSource(code, findNode.simpleFormalParameter(code));
  }

  void test_visitSimpleFormalParameter_keyword_type() {
    var code = 'final int a';
    var findNode = _parseStringToFindNode('''
void f($code) {}
''');
    _assertSource(code, findNode.simpleFormalParameter(code));
  }

  void test_visitSimpleFormalParameter_type() {
    var code = 'int a';
    var findNode = _parseStringToFindNode('''
void f($code) {}
''');
    _assertSource(code, findNode.simpleFormalParameter(code));
  }

  void test_visitSimpleFormalParameter_type_covariant() {
    var code = 'covariant int a';
    var findNode = _parseStringToFindNode('''
class A {
  void foo($code) {}
}
''');
    _assertSource(code, findNode.simpleFormalParameter(code));
  }

  void test_visitSimpleIdentifier() {
    var code = 'foo';
    var findNode = _parseStringToFindNode('''
var x = $code;
''');
    _assertSource(code, findNode.simple(code));
  }

  void test_visitSimpleStringLiteral() {
    var code = "'str'";
    var findNode = _parseStringToFindNode('''
final x = $code;
''');
    _assertSource(code, findNode.simpleStringLiteral(code));
  }

  void test_visitSpreadElement_nonNullable() {
    var code = '...[0]';
    var findNode = _parseStringToFindNode('''
final x = [$code];
''');
    _assertSource(code, findNode.spreadElement(code));
  }

  void test_visitSpreadElement_nullable() {
    var code = '...?[0]';
    var findNode = _parseStringToFindNode('''
final x = [$code];
''');
    _assertSource(code, findNode.spreadElement(code));
  }

  void test_visitStringInterpolation() {
    var code = r"'a${bb}ccc'";
    var findNode = _parseStringToFindNode('''
final x = $code;
''');
    _assertSource(code, findNode.stringInterpolation(code));
  }

  void test_visitSuperConstructorInvocation() {
    var code = 'super(0)';
    var findNode = _parseStringToFindNode('''
class A extends B {
  A() : $code;
}
''');
    _assertSource(code, findNode.superConstructorInvocation(code));
  }

  void test_visitSuperConstructorInvocation_named() {
    var code = 'super.named(0)';
    var findNode = _parseStringToFindNode('''
class A extends B {
  A() : $code;
}
''');
    _assertSource(code, findNode.superConstructorInvocation(code));
  }

  void test_visitSuperExpression() {
    var findNode = _parseStringToFindNode('''
class A {
  void foo() {
    super.foo();
  }
}
''');
    _assertSource('super', findNode.super_('super.foo'));
  }

  void test_visitSuperFormalParameter_annotation() {
    var code = '@deprecated super.foo';
    var findNode = _parseStringToFindNode('''
class A {
  A($code);
}
''');
    _assertSource(code, findNode.superFormalParameter(code));
  }

  void test_visitSuperFormalParameter_functionTyped() {
    var code = 'int super.a(b)';
    var findNode = _parseStringToFindNode('''
class A {
  A($code);
}
''');
    _assertSource(code, findNode.superFormalParameter(code));
  }

  void test_visitSuperFormalParameter_functionTyped_typeParameters() {
    var code = 'int super.a<E, F>(b)';
    var findNode = _parseStringToFindNode('''
class A {
  A($code);
}
''');
    _assertSource(code, findNode.superFormalParameter(code));
  }

  void test_visitSuperFormalParameter_keyword() {
    var code = 'final super.foo';
    var findNode = _parseStringToFindNode('''
class A {
  A($code);
}
''');
    _assertSource(code, findNode.superFormalParameter(code));
  }

  void test_visitSuperFormalParameter_keywordAndType() {
    var code = 'final int super.a';
    var findNode = _parseStringToFindNode('''
class A {
  A($code);
}
''');
    _assertSource(code, findNode.superFormalParameter(code));
  }

  void test_visitSuperFormalParameter_type() {
    var code = 'int super.a';
    var findNode = _parseStringToFindNode('''
class A {
  A($code);
}
''');
    _assertSource(code, findNode.superFormalParameter(code));
  }

  void test_visitSuperFormalParameter_type_covariant() {
    var code = 'covariant int super.a';
    var findNode = _parseStringToFindNode('''
class A {
  A($code);
}
''');
    _assertSource(code, findNode.superFormalParameter(code));
  }

  void test_visitSwitchCase_multipleLabels() {
    var code = 'l1: l2: case a: {}';
    var findNode = _parseStringToFindNode('''
// @dart = 2.19
void f() {
  switch (x) {
    $code
  }
}
''');
    _assertSource(code, findNode.switchCase(code));
  }

  void test_visitSwitchCase_multipleStatements() {
    var code = 'case a: foo(); bar();';
    var findNode = _parseStringToFindNode('''
// @dart = 2.19
void f() {
  switch (x) {
    $code
  }
}
''');
    _assertSource(code, findNode.switchCase(code));
  }

  void test_visitSwitchCase_noLabels() {
    var code = 'case a: {}';
    var findNode = _parseStringToFindNode('''
// @dart = 2.19
void f() {
  switch (x) {
    $code
  }
}
''');
    _assertSource(code, findNode.switchCase(code));
  }

  void test_visitSwitchCase_singleLabel() {
    var code = 'l1: case a: {}';
    var findNode = _parseStringToFindNode('''
// @dart = 2.19
void f() {
  switch (x) {
    $code
  }
}
''');
    _assertSource(code, findNode.switchCase(code));
  }

  void test_visitSwitchDefault_multipleLabels() {
    var code = 'l1: l2: default: {}';
    var findNode = _parseStringToFindNode('''
void f() {
  switch (x) {
    $code
  }
}
''');
    _assertSource(code, findNode.switchDefault(code));
  }

  void test_visitSwitchDefault_multipleStatements() {
    var code = 'default: foo(); bar();';
    var findNode = _parseStringToFindNode('''
void f() {
  switch (x) {
    $code
  }
}
''');
    _assertSource(code, findNode.switchDefault(code));
  }

  void test_visitSwitchDefault_noLabels() {
    var code = 'default: {}';
    var findNode = _parseStringToFindNode('''
void f() {
  switch (x) {
    $code
  }
}
''');
    _assertSource(code, findNode.switchDefault(code));
  }

  void test_visitSwitchDefault_singleLabel() {
    var code = 'l1: default: {}';
    var findNode = _parseStringToFindNode('''
void f() {
  switch (x) {
    $code
  }
}
''');
    _assertSource(code, findNode.switchDefault(code));
  }

  @failingTest
  void test_visitSwitchExpression() {
    // TODO(brianwilkerson): Test this when the parser allows.
    fail('Unable to parse patterns');
  }

  @failingTest
  void test_visitSwitchExpressionCase() {
    // TODO(brianwilkerson): Test this when the parser allows.
    fail('Unable to parse patterns');
  }

  @failingTest
  void test_visitSwitchExpressionDefault() {
    // TODO(brianwilkerson): Test this when the parser allows.
    fail('Unable to parse patterns');
  }

  @failingTest
  void test_visitSwitchGuard() {
    // TODO(brianwilkerson): Test this when the parser allows.
    fail('Unable to parse patterns');
  }

  void test_visitSwitchPatternCase_multipleLabels() {
    var code = 'l1: l2: case a: {}';
    var findNode = _parseStringToFindNode('''
void f() {
  switch (x) {
    $code
  }
}
''');
    _assertSource(code, findNode.switchPatternCase(code));
  }

  void test_visitSwitchPatternCase_multipleStatements() {
    var code = 'case a: foo(); bar();';
    var findNode = _parseStringToFindNode('''
void f() {
  switch (x) {
    $code
  }
}
''');
    _assertSource(code, findNode.switchPatternCase(code));
  }

  void test_visitSwitchPatternCase_noLabels() {
    var code = 'case a: {}';
    var findNode = _parseStringToFindNode('''
void f() {
  switch (x) {
    $code
  }
}
''');
    _assertSource(code, findNode.switchPatternCase(code));
  }

  void test_visitSwitchPatternCase_singleLabel() {
    var code = 'l1: case a: {}';
    var findNode = _parseStringToFindNode('''
void f() {
  switch (x) {
    $code
  }
}
''');
    _assertSource(code, findNode.switchPatternCase(code));
  }

  void test_visitSwitchStatement() {
    var code = 'switch (x) {case 0: foo(); default: bar();}';
    var findNode = _parseStringToFindNode('''
void f() {
  $code
}
''');
    _assertSource(code, findNode.switchStatement(code));
  }

  void test_visitSymbolLiteral_multiple() {
    var code = '#a.b.c';
    var findNode = _parseStringToFindNode('''
final x = $code;
''');
    _assertSource(code, findNode.symbolLiteral(code));
  }

  void test_visitSymbolLiteral_single() {
    var code = '#a';
    var findNode = _parseStringToFindNode('''
final x = $code;
''');
    _assertSource(code, findNode.symbolLiteral(code));
  }

  void test_visitThisExpression() {
    var code = 'this';
    var findNode = _parseStringToFindNode('''
class A {
  void foo() {
    $code;
  }
}
''');
    _assertSource(code, findNode.this_(code));
  }

  void test_visitThrowStatement() {
    var code = 'throw 0';
    var findNode = _parseStringToFindNode('''
void f() {
  $code;
}
''');
    _assertSource(code, findNode.throw_(code));
  }

  void test_visitTopLevelVariableDeclaration_augment() {
    var code = 'augment var a = 0;';
    var findNode = _parseStringToFindNode('''
$code
''');
    _assertSource(code, findNode.topLevelVariableDeclaration(code));
  }

  void test_visitTopLevelVariableDeclaration_external() {
    var code = 'external var a;';
    var findNode = _parseStringToFindNode('''
$code
''');
    _assertSource(code, findNode.topLevelVariableDeclaration(code));
  }

  void test_visitTopLevelVariableDeclaration_multiple() {
    var code = 'var a = 0, b = 1;';
    var findNode = _parseStringToFindNode('''
$code
''');
    _assertSource(code, findNode.topLevelVariableDeclaration(code));
  }

  void test_visitTopLevelVariableDeclaration_single() {
    var code = 'var a;';
    var findNode = _parseStringToFindNode('''
$code
''');
    _assertSource(code, findNode.topLevelVariableDeclaration(code));
  }

  void test_visitTopLevelVariableDeclaration_withMetadata() {
    var code = '@deprecated var a;';
    var findNode = _parseStringToFindNode('''
$code
''');
    _assertSource(code, findNode.topLevelVariableDeclaration(code));
  }

  void test_visitTryStatement_catch() {
    var code = 'try {} on E {}';
    var findNode = _parseStringToFindNode('''
void f() {
  $code
}
''');
    _assertSource(code, findNode.tryStatement(code));
  }

  void test_visitTryStatement_catches() {
    var code = 'try {} on E {} on F {}';
    var findNode = _parseStringToFindNode('''
void f() {
  $code
}
''');
    _assertSource(code, findNode.tryStatement(code));
  }

  void test_visitTryStatement_catchFinally() {
    var code = 'try {} on E {} finally {}';
    var findNode = _parseStringToFindNode('''
void f() {
  $code
}
''');
    _assertSource(code, findNode.tryStatement(code));
  }

  void test_visitTryStatement_finally() {
    var code = 'try {} finally {}';
    var findNode = _parseStringToFindNode('''
void f() {
  $code
}
''');
    _assertSource(code, findNode.tryStatement(code));
  }

  void test_visitTypeArgumentList_multiple() {
    var code = '<int, String>';
    var findNode = _parseStringToFindNode('''
final x = $code[];
''');
    _assertSource(code, findNode.typeArgumentList(code));
  }

  void test_visitTypeArgumentList_single() {
    var code = '<int>';
    var findNode = _parseStringToFindNode('''
final x = $code[];
''');
    _assertSource(code, findNode.typeArgumentList(code));
  }

  void test_visitTypeParameter_variance_contravariant() {
    var code = 'in T';
    var findNode = _parseStringToFindNode('''
class A<$code> {}
''', featureSet: FeatureSets.latestWithVariance);
    _assertSource(code, findNode.typeParameter(code));
  }

  void test_visitTypeParameter_variance_covariant() {
    var code = 'out T';
    var findNode = _parseStringToFindNode('''
class A<$code> {}
''', featureSet: FeatureSets.latestWithVariance);
    _assertSource(code, findNode.typeParameter(code));
  }

  void test_visitTypeParameter_variance_invariant() {
    var code = 'inout T';
    var findNode = _parseStringToFindNode('''
class A<$code> {}
''', featureSet: FeatureSets.latestWithVariance);
    _assertSource(code, findNode.typeParameter(code));
  }

  void test_visitTypeParameter_withExtends() {
    var code = 'T extends num';
    var findNode = _parseStringToFindNode('''
class A<$code> {}
''');
    _assertSource(code, findNode.typeParameter(code));
  }

  void test_visitTypeParameter_withMetadata() {
    var code = '@deprecated T';
    var findNode = _parseStringToFindNode('''
class A<$code> {}
''');
    _assertSource(code, findNode.typeParameter(code));
  }

  void test_visitTypeParameter_withoutExtends() {
    var code = 'T';
    var findNode = _parseStringToFindNode('''
class A<$code> {}
''', featureSet: FeatureSets.latestWithVariance);
    _assertSource(code, findNode.typeParameter(code));
  }

  void test_visitTypeParameterList_multiple() {
    var code = '<T, U>';
    var findNode = _parseStringToFindNode('''
class A$code {}
''');
    // Find from the offset after the `<` because NodeLocator usually picks
    // the name for the offset between the name and `<`.
    _assertSource(code, findNode.typeParameterList('T, U>'));
  }

  void test_visitTypeParameterList_single() {
    var code = '<T>';
    var findNode = _parseStringToFindNode('''
class A$code {}
''');
    // Find from the offset after the `<` because NodeLocator usually picks
    // the name for the offset between the name and `<`.
    _assertSource(code, findNode.typeParameterList('T>'));
  }

  void test_visitVariableDeclaration_initialized() {
    var code = 'foo = bar';
    var findNode = _parseStringToFindNode('''
var $code;
''', featureSet: FeatureSets.latestWithVariance);
    _assertSource(code, findNode.variableDeclaration(code));
  }

  void test_visitVariableDeclaration_uninitialized() {
    var code = 'foo';
    var findNode = _parseStringToFindNode('''
var $code;
''', featureSet: FeatureSets.latestWithVariance);
    _assertSource(code, findNode.variableDeclaration(code));
  }

  void test_visitVariableDeclarationList_const_type() {
    var code = 'const int a = 0, b = 0';
    var findNode = _parseStringToFindNode('''
$code;
''');
    _assertSource(code, findNode.variableDeclarationList(code));
  }

  void test_visitVariableDeclarationList_final_noType() {
    var code = 'final a = 0, b = 0';
    var findNode = _parseStringToFindNode('''
$code;
''');
    _assertSource(code, findNode.variableDeclarationList(code));
  }

  void test_visitVariableDeclarationList_type() {
    var code = 'int a, b';
    var findNode = _parseStringToFindNode('''
$code;
''');
    _assertSource(code, findNode.variableDeclarationList(code));
  }

  void test_visitVariableDeclarationList_var() {
    var code = 'var a, b';
    var findNode = _parseStringToFindNode('''
$code;
''');
    _assertSource(code, findNode.variableDeclarationList(code));
  }

  void test_visitVariableDeclarationStatement() {
    var code = 'int a';
    var findNode = _parseStringToFindNode('''
$code;
''');
    _assertSource(code, findNode.variableDeclarationList(code));
  }

  void test_visitWhileStatement() {
    var code = 'while (true) {}';
    var findNode = _parseStringToFindNode('''
void f() {
  $code
}
''');
    _assertSource(code, findNode.whileStatement(code));
  }

  void test_visitWildcardPattern() {
    var findNode = _parseStringToFindNode('''
void f(x) {
  switch (x) {
    case int? _:
      break;
  }
}
''');
    _assertSource(
      'int? _',
      findNode.wildcardPattern('int?'),
    );
  }

  void test_visitWithClause_multiple() {
    var code = 'with A, B, C';
    var findNode = _parseStringToFindNode('''
class X $code {}
''');
    _assertSource(code, findNode.withClause(code));
  }

  void test_visitWithClause_single() {
    var code = 'with M';
    var findNode = _parseStringToFindNode('''
class X $code {}
''');
    _assertSource(code, findNode.withClause(code));
  }

  void test_visitYieldStatement() {
    var code = 'yield e;';
    var findNode = _parseStringToFindNode('''
void f() sync* {
  $code
}
''');
    _assertSource(code, findNode.yieldStatement(code));
  }

  void test_visitYieldStatement_each() {
    var code = 'yield* e;';
    var findNode = _parseStringToFindNode('''
void f() sync* {
  $code
}
''');
    _assertSource(code, findNode.yieldStatement(code));
  }

  /// Assert that a [ToSourceVisitor] will produce the [expectedSource] when
  /// visiting the given [node].
  void _assertSource(String expectedSource, AstNode node) {
    StringBuffer buffer = StringBuffer();
    node.accept(ToSourceVisitor(buffer));
    expect(buffer.toString(), expectedSource);
  }

  // TODO(scheglov): Use [parseStringWithErrors] everywhere? Or just there?
  FindNode _parseStringToFindNode(
    String content, {
    FeatureSet? featureSet,
  }) {
    var parseResult = parseString(
      content: content,
      featureSet: featureSet ?? FeatureSets.latestWithExperiments,
    );
    return FindNode(parseResult.content, parseResult.unit);
  }
}
