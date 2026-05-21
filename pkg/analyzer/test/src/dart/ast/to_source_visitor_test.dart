// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/to_source_visitor.dart';
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
  test_class_emptyBody() {
    var code = 'class A;';
    var parseResult = parseStringWithErrors(code);
    var node = parseResult.findNode.classDeclaration(code);
    _assertSource(code, node);
  }

  test_class_primaryConstructor_const_named() {
    var code = 'class const A<T>.named() {}';
    var parseResult = parseStringWithErrors(code);
    var node = parseResult.findNode.classDeclaration(code);
    _assertSource(code, node);
  }

  test_class_primaryConstructor_const_unnamed() {
    var code = 'class A() {}';
    var parseResult = parseStringWithErrors(code);
    var node = parseResult.findNode.classDeclaration(code);
    _assertSource(code, node);
  }

  test_class_primaryConstructor_declaringFormalParameter_optionalNamed() {
    var code = 'class A({final int a = 0}) {}';
    var parseResult = parseStringWithErrors(code);
    var node = parseResult.findNode.classDeclaration(code);
    _assertSource(code, node);
  }

  test_class_primaryConstructor_declaringFormalParameter_requiredPositional() {
    var code = 'class A(final int a) {}';
    var parseResult = parseStringWithErrors(code);
    var node = parseResult.findNode.classDeclaration(code);
    _assertSource(code, node);
  }

  test_class_primaryConstructor_fieldFormalParameter() {
    var code = 'class A(int this.a) {}';
    var parseResult = parseStringWithErrors(code);
    var node = parseResult.findNode.classDeclaration(code);
    _assertSource(code, node);
  }

  test_class_primaryConstructor_notConst_named() {
    var code = 'class A<T>.named() {}';
    var parseResult = parseStringWithErrors(code);
    var node = parseResult.findNode.classDeclaration(code);
    _assertSource(code, node);
  }

  test_class_primaryConstructor_superFormalParameter() {
    var code = 'class A(int super.a) {}';
    var parseResult = parseStringWithErrors(code);
    var node = parseResult.findNode.classDeclaration(code);
    _assertSource(code, node);
  }

  test_enum_emptyBody() {
    var code = 'enum E;';
    var parseResult = parseStringWithErrors(code);
    var node = parseResult.findNode.enumDeclaration(code);
    _assertSource(code, node);
  }

  test_enum_primaryConstructor_named() {
    var code = 'enum const E<T>.named(final int a) {}';
    var parseResult = parseStringWithErrors(code);
    var node = parseResult.findNode.enumDeclaration(code);
    _assertSource(code, node);
  }

  test_enum_primaryConstructor_unnamed() {
    var code = 'enum E<T>(final int a) {}';
    var parseResult = parseStringWithErrors(code);
    var node = parseResult.findNode.enumDeclaration(code);
    _assertSource(code, node);
  }

  test_extension_emptyBody() {
    var code = 'extension E on C;';
    var parseResult = parseStringWithErrors(code);
    var node = parseResult.findNode.extensionDeclaration(code);
    _assertSource(code, node);
  }

  test_extensionType_emptyBody() {
    var code = 'extension type A(int it);';
    var parseResult = parseStringWithErrors(code);
    var node = parseResult.findNode.extensionTypeDeclaration(code);
    _assertSource(code, node);
  }

  test_extensionType_primaryConstructor_named() {
    var code = 'extension type const A<T>.named(int it) {}';
    var parseResult = parseStringWithErrors(code);
    var node = parseResult.findNode.extensionTypeDeclaration(code);
    _assertSource(code, node);
  }

  test_extensionType_primaryConstructor_unnamed() {
    var code = 'extension type A<T>(int it) {}';
    var parseResult = parseStringWithErrors(code);
    var node = parseResult.findNode.extensionTypeDeclaration(code);
    _assertSource(code, node);
  }

  test_mixin_emptyBody() {
    var code = 'mixin M;';
    var parseResult = parseStringWithErrors(code);
    var node = parseResult.findNode.mixinDeclaration(code);
    _assertSource(code, node);
  }

  void test_visitAdjacentStrings() {
    var parseResult = parseStringWithErrors(r'''
var v = 'a' 'b';
''');
    var node = parseResult.findNode.adjacentStrings("'a'");
    _assertSource("'a' 'b'", node);
  }

  void test_visitAnnotation_constant() {
    var code = '@A';
    var parseResult = parseStringWithErrors('''
$code
void f() {}
''');
    var node = parseResult.findNode.annotation(code);
    _assertSource(code, node);
  }

  void test_visitAnnotation_constructor() {
    var code = '@A.foo()';
    var parseResult = parseStringWithErrors('''
$code
void f() {}
''');
    var node = parseResult.findNode.annotation(code);
    _assertSource(code, node);
  }

  void test_visitAnnotation_constructor_generic() {
    var code = '@A<int>.foo()';
    var parseResult = parseStringWithErrors('''
$code
void f() {}
''');
    var node = parseResult.findNode.annotation(code);
    _assertSource(code, node);
  }

  void test_visitArgumentList() {
    var code = '(0, 1)';
    var parseResult = parseStringWithErrors('''
final x = f$code;
''');
    var node = parseResult.findNode.argumentList(code);
    _assertSource(code, node);
  }

  void test_visitAsExpression() {
    var parseResult = parseStringWithErrors(r'''
var v = a as T;
''');
    var node = parseResult.findNode.as_('as T');
    _assertSource('a as T', node);
  }

  void test_visitAssertStatement() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  assert(a);
}
''');
    var node = parseResult.findNode.assertStatement('assert');
    _assertSource('assert (a);', node);
  }

  void test_visitAssertStatement_withMessage() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  assert(a, b);
}
''');
    var node = parseResult.findNode.assertStatement('assert');
    _assertSource('assert (a, b);', node);
  }

  void test_visitAssignedVariablePattern() {
    var parseResult = parseStringWithErrors('''
void f(int foo) {
  (foo) = 0;
}
''');
    var node = parseResult.findNode.assignedVariablePattern('foo) = 0');
    _assertSource('foo', node);
  }

  void test_visitAssignmentExpression() {
    var code = 'a = b';
    var parseResult = parseStringWithErrors('''
void f() {
  $code;
}
''');
    var node = parseResult.findNode.assignment(code);
    _assertSource(code, node);
  }

  void test_visitAwaitExpression() {
    var parseResult = parseStringWithErrors(r'''
void f() async => await e;
''');
    var node = parseResult.findNode.awaitExpression('await e');
    _assertSource('await e', node);
  }

  void test_visitBinaryExpression() {
    var parseResult = parseStringWithErrors(r'''
var v = a + b;
''');
    var node = parseResult.findNode.binary('a + b');
    _assertSource('a + b', node);
  }

  void test_visitBinaryExpression_precedence() {
    var parseResult = parseStringWithErrors(r'''
var v = a * (b + c);
''');
    var node = parseResult.findNode.binary('a *');
    _assertSource('a * (b + c)', node);
  }

  void test_visitBlock_empty() {
    var code = '{}';
    var parseResult = parseStringWithErrors('''
void f() $code
''');
    var node = parseResult.findNode.block(code);
    _assertSource(code, node);
  }

  void test_visitBlock_nonEmpty() {
    var code = '{foo(); bar();}';
    var parseResult = parseStringWithErrors('''
void f() $code
''');
    var node = parseResult.findNode.block(code);
    _assertSource(code, node);
  }

  void test_visitBlockFunctionBody_async() {
    var code = 'async {}';
    var parseResult = parseStringWithErrors('''
void f() $code
''');
    var node = parseResult.findNode.blockFunctionBody(code);
    _assertSource(code, node);
  }

  void test_visitBlockFunctionBody_async_star() {
    var code = 'async* {}';
    var parseResult = parseStringWithErrors('''
void f() $code
''');
    var node = parseResult.findNode.blockFunctionBody(code);
    _assertSource(code, node);
  }

  void test_visitBlockFunctionBody_simple() {
    var code = '{}';
    var parseResult = parseStringWithErrors('''
void f() $code
''');
    var node = parseResult.findNode.blockFunctionBody(code);
    _assertSource(code, node);
  }

  void test_visitBlockFunctionBody_sync_star() {
    var code = 'sync* {}';
    var parseResult = parseStringWithErrors('''
void f() $code
''');
    var node = parseResult.findNode.blockFunctionBody(code);
    _assertSource(code, node);
  }

  void test_visitBooleanLiteral_false() {
    var code = 'false';
    var parseResult = parseStringWithErrors('''
final v = $code;
''');
    var node = parseResult.findNode.booleanLiteral(code);
    _assertSource(code, node);
  }

  void test_visitBooleanLiteral_true() {
    var code = 'true';
    var parseResult = parseStringWithErrors('''
final v = $code;
''');
    var node = parseResult.findNode.booleanLiteral(code);
    _assertSource(code, node);
  }

  void test_visitBreakStatement_label() {
    var code = 'break L;';
    var parseResult = parseStringWithErrors('''
void f() {
  L: while (true) {
    $code
  }
}
''');
    var node = parseResult.findNode.breakStatement(code);
    _assertSource(code, node);
  }

  void test_visitBreakStatement_noLabel() {
    var code = 'break;';
    var parseResult = parseStringWithErrors('''
void f() {
  while (true) {
    $code
  }
}
''');
    var node = parseResult.findNode.breakStatement(code);
    _assertSource(code, node);
  }

  void test_visitCascadeExpression_field() {
    var code = 'a..b..c';
    var parseResult = parseStringWithErrors('''
void f() {
  $code;
}
''');
    var node = parseResult.findNode.cascade(code);
    _assertSource(code, node);
  }

  void test_visitCascadeExpression_index() {
    var code = 'a..[0]..[1]';
    var parseResult = parseStringWithErrors('''
void f() {
  $code;
}
''');
    var node = parseResult.findNode.cascade(code);
    _assertSource(code, node);
  }

  void test_visitCascadeExpression_method() {
    var code = 'a..b()..c()';
    var parseResult = parseStringWithErrors('''
void f() {
  $code;
}
''');
    var node = parseResult.findNode.cascade(code);
    _assertSource(code, node);
  }

  void test_visitCastPattern() {
    var parseResult = parseStringWithErrors('''
void f(x) {
  switch (x) {
    case y as int:
      break;
  }
}
''');
    var node = parseResult.findNode.castPattern('as ');
    _assertSource('y as int', node);
  }

  void test_visitCatchClause_catch_noStack() {
    var code = 'catch (e) {}';
    var parseResult = parseStringWithErrors('''
void f() {
  try {}
  $code
}
''');
    var node = parseResult.findNode.catchClause(code);
    _assertSource(code, node);
  }

  void test_visitCatchClause_catch_stack() {
    var code = 'catch (e, s) {}';
    var parseResult = parseStringWithErrors('''
void f() {
  try {}
  $code
}
''');
    var node = parseResult.findNode.catchClause(code);
    _assertSource(code, node);
  }

  void test_visitCatchClause_on() {
    var code = 'on E {}';
    var parseResult = parseStringWithErrors('''
void f() {
  try {}
  $code
}
''');
    var node = parseResult.findNode.catchClause(code);
    _assertSource(code, node);
  }

  void test_visitCatchClause_on_catch() {
    var code = 'on E catch (e) {}';
    var parseResult = parseStringWithErrors('''
void f() {
  try {}
  $code
}
''');
    var node = parseResult.findNode.catchClause(code);
    _assertSource(code, node);
  }

  void test_visitClassDeclaration_abstract() {
    var code = 'abstract class C {}';
    var parseResult = parseStringWithErrors(code);
    var node = parseResult.findNode.classDeclaration(code);
    _assertSource(code, node);
  }

  void test_visitClassDeclaration_augment() {
    var code = 'augment class A {}';
    var parseResult = parseStringWithErrors(code);
    var node = parseResult.findNode.singleClassDeclaration;
    _assertSource(code, node);
  }

  void test_visitClassDeclaration_augment_abstract() {
    var code = 'augment abstract class C {}';
    var parseResult = parseStringWithErrors(code);
    var node = parseResult.findNode.singleClassDeclaration;
    _assertSource(code, node);
  }

  void test_visitClassDeclaration_base() {
    var parseResult = parseStringWithErrors(r'''
base class A {}
''');
    var node = parseResult.findNode.classDeclaration('class A');
    _assertSource('base class A {}', node);
  }

  void test_visitClassDeclaration_empty() {
    var code = 'class C {}';
    var parseResult = parseStringWithErrors(code);
    var node = parseResult.findNode.classDeclaration(code);
    _assertSource(code, node);
  }

  void test_visitClassDeclaration_extends() {
    var code = 'class C extends A {}';
    var parseResult = parseStringWithErrors('''
$code
''');
    var node = parseResult.findNode.classDeclaration(code);
    _assertSource(code, node);
  }

  void test_visitClassDeclaration_extends_implements() {
    var code = 'class C extends A implements B {}';
    var parseResult = parseStringWithErrors('''
$code
''');
    var node = parseResult.findNode.classDeclaration(code);
    _assertSource(code, node);
  }

  void test_visitClassDeclaration_extends_with() {
    var code = 'class C extends A with M {}';
    var parseResult = parseStringWithErrors('''
$code
void f() {}
''');
    var node = parseResult.findNode.classDeclaration(code);
    _assertSource(code, node);
  }

  void test_visitClassDeclaration_extends_with_implements() {
    var code = 'class C extends A with M implements B {}';
    var parseResult = parseStringWithErrors('''
$code
void f() {}
''');
    var node = parseResult.findNode.classDeclaration(code);
    _assertSource(code, node);
  }

  void test_visitClassDeclaration_final() {
    var parseResult = parseStringWithErrors(r'''
final class A {}
''');
    var node = parseResult.findNode.classDeclaration('class A');
    _assertSource('final class A {}', node);
  }

  void test_visitClassDeclaration_implements() {
    var code = 'class C implements B {}';
    var parseResult = parseStringWithErrors('''
$code
''');
    var node = parseResult.findNode.classDeclaration(code);
    _assertSource(code, node);
  }

  void test_visitClassDeclaration_interface() {
    var parseResult = parseStringWithErrors(r'''
interface class A {}
''');
    var node = parseResult.findNode.classDeclaration('class A');
    _assertSource('interface class A {}', node);
  }

  void test_visitClassDeclaration_mixin() {
    var parseResult = parseStringWithErrors(r'''
mixin class A {}
''');
    var node = parseResult.findNode.classDeclaration('class A');
    _assertSource('mixin class A {}', node);
  }

  void test_visitClassDeclaration_multipleMember() {
    var code = 'class C {var a; var b;}';
    var parseResult = parseStringWithErrors('''
$code
''');
    var node = parseResult.findNode.classDeclaration(code);
    _assertSource(code, node);
  }

  void test_visitClassDeclaration_parameters() {
    var code = 'class C<E> {}';
    var parseResult = parseStringWithErrors(code);
    var node = parseResult.findNode.classDeclaration(code);
    _assertSource(code, node);
  }

  void test_visitClassDeclaration_parameters_extends() {
    var code = 'class C<E> extends A {}';
    var parseResult = parseStringWithErrors('''
$code
''');
    var node = parseResult.findNode.classDeclaration(code);
    _assertSource(code, node);
  }

  void test_visitClassDeclaration_parameters_extends_implements() {
    var code = 'class C<E> extends A implements B {}';
    var parseResult = parseStringWithErrors('''
$code
''');
    var node = parseResult.findNode.classDeclaration(code);
    _assertSource(code, node);
  }

  void test_visitClassDeclaration_parameters_extends_with() {
    var code = 'class C<E> extends A with M {}';
    var parseResult = parseStringWithErrors('''
$code
''');
    var node = parseResult.findNode.classDeclaration(code);
    _assertSource(code, node);
  }

  void test_visitClassDeclaration_parameters_extends_with_implements() {
    var code = 'class C<E> extends A with M implements B {}';
    var parseResult = parseStringWithErrors('''
$code
''');
    var node = parseResult.findNode.classDeclaration(code);
    _assertSource(code, node);
  }

  void test_visitClassDeclaration_parameters_implements() {
    var code = 'class C<E> implements B {}';
    var parseResult = parseStringWithErrors('''
$code
''');
    var node = parseResult.findNode.classDeclaration(code);
    _assertSource(code, node);
  }

  void test_visitClassDeclaration_sealed() {
    var parseResult = parseStringWithErrors(r'''
sealed class A {}
''');
    var node = parseResult.findNode.classDeclaration('class A');
    _assertSource('sealed class A {}', node);
  }

  void test_visitClassDeclaration_singleMember() {
    var code = 'class C {var a;}';
    var parseResult = parseStringWithErrors(code);
    var node = parseResult.findNode.classDeclaration(code);
    _assertSource(code, node);
  }

  void test_visitClassDeclaration_withMetadata() {
    var code = '@deprecated class C {}';
    var parseResult = parseStringWithErrors(code);
    var node = parseResult.findNode.classDeclaration(code);
    _assertSource(code, node);
  }

  void test_visitClassTypeAlias_abstract() {
    var code = 'abstract class C = S with M;';
    var parseResult = parseStringWithErrors('''
$code
''');
    var node = parseResult.findNode.classTypeAlias(code);
    _assertSource(code, node);
  }

  void test_visitClassTypeAlias_abstract_implements() {
    var code = 'abstract class C = S with M implements I;';
    var parseResult = parseStringWithErrors('''
$code
''');
    var node = parseResult.findNode.classTypeAlias(code);
    _assertSource(code, node);
  }

  void test_visitClassTypeAlias_abstractAugment() {
    var code = 'augment abstract class C = S with M;';
    var parseResult = parseStringWithErrors('''
$code
''');
    var node = parseResult.findNode.classTypeAlias('class C');
    _assertSource(code, node);
  }

  void test_visitClassTypeAlias_augment() {
    var parseResult = parseStringWithErrors(r'''
augment class A = S with M;
''');
    var node = parseResult.findNode.classTypeAlias('class A');
    _assertSource('augment class A = S with M;', node);
  }

  void test_visitClassTypeAlias_base() {
    var parseResult = parseStringWithErrors(r'''
base class A = S with M;
''');
    var node = parseResult.findNode.classTypeAlias('class A');
    _assertSource('base class A = S with M;', node);
  }

  void test_visitClassTypeAlias_final() {
    var parseResult = parseStringWithErrors(r'''
final class A = S with M;
''');
    var node = parseResult.findNode.classTypeAlias('class A');
    _assertSource('final class A = S with M;', node);
  }

  void test_visitClassTypeAlias_generic() {
    var code = 'class C<E> = S<E> with M<E>;';
    var parseResult = parseStringWithErrors('''
$code
''');
    var node = parseResult.findNode.classTypeAlias(code);
    _assertSource(code, node);
  }

  void test_visitClassTypeAlias_implements() {
    var code = 'class C = S with M implements I;';
    var parseResult = parseStringWithErrors('''
$code
''');
    var node = parseResult.findNode.classTypeAlias(code);
    _assertSource(code, node);
  }

  void test_visitClassTypeAlias_interface() {
    var parseResult = parseStringWithErrors(r'''
interface class A = S with M;
''');
    var node = parseResult.findNode.classTypeAlias('class A');
    _assertSource('interface class A = S with M;', node);
  }

  void test_visitClassTypeAlias_minimal() {
    var code = 'class C = S with M;';
    var parseResult = parseStringWithErrors('''
$code
''');
    var node = parseResult.findNode.classTypeAlias(code);
    _assertSource(code, node);
  }

  void test_visitClassTypeAlias_mixin() {
    var parseResult = parseStringWithErrors(r'''
mixin class A = S with M;
''');
    var node = parseResult.findNode.classTypeAlias('class A');
    _assertSource('mixin class A = S with M;', node);
  }

  void test_visitClassTypeAlias_parameters_abstract() {
    var code = 'abstract class C<E> = S with M;';
    var parseResult = parseStringWithErrors('''
$code
''');
    var node = parseResult.findNode.classTypeAlias(code);
    _assertSource(code, node);
  }

  void test_visitClassTypeAlias_parameters_abstract_implements() {
    var code = 'abstract class C<E> = S with M implements I;';
    var parseResult = parseStringWithErrors('''
$code
''');
    var node = parseResult.findNode.classTypeAlias(code);
    _assertSource(code, node);
  }

  void test_visitClassTypeAlias_parameters_implements() {
    var code = 'class C<E> = S with M implements I;';
    var parseResult = parseStringWithErrors('''
$code
''');
    var node = parseResult.findNode.classTypeAlias(code);
    _assertSource(code, node);
  }

  void test_visitClassTypeAlias_sealed() {
    var parseResult = parseStringWithErrors(r'''
sealed class A = S with M;
''');
    var node = parseResult.findNode.classTypeAlias('class A');
    _assertSource('sealed class A = S with M;', node);
  }

  void test_visitClassTypeAlias_withMetadata() {
    var code = '@deprecated class A = S with M;';
    var parseResult = parseStringWithErrors(code);
    var node = parseResult.findNode.classTypeAlias(code);
    _assertSource(code, node);
  }

  void test_visitComment() {
    var code = r'''
/// foo
/// bar
''';
    var parseResult = parseStringWithErrors('''
$code
void f() {}
''');
    var node = parseResult.findNode.comment(code);
    _assertSource('', node);
  }

  void test_visitCommentReference() {
    var code = 'x';
    var parseResult = parseStringWithErrors('''
/// [$code]
void f() {}
''');
    var node = parseResult.findNode.commentReference(code);
    _assertSource('[x]', node);
  }

  void test_visitCompilationUnit_declaration() {
    var code = 'var a;';
    var parseResult = parseStringWithErrors(code);
    var node = parseResult.findNode.unit;
    _assertSource(code, node);
  }

  void test_visitCompilationUnit_directive() {
    var code = 'library my;';
    var parseResult = parseStringWithErrors(code);
    var node = parseResult.findNode.unit;
    _assertSource(code, node);
  }

  void test_visitCompilationUnit_directive_declaration() {
    var code = 'library my; var a;';
    var parseResult = parseStringWithErrors(code);
    var node = parseResult.findNode.unit;
    _assertSource(code, node);
  }

  void test_visitCompilationUnit_empty() {
    var code = '';
    var parseResult = parseStringWithErrors(code);
    var node = parseResult.findNode.unit;
    _assertSource(code, node);
  }

  void test_visitCompilationUnit_libraryWithoutName() {
    var code = 'library ;';
    var parseResult = parseStringWithErrors(code);
    var node = parseResult.findNode.unit;
    _assertSource(code, node);
  }

  void test_visitCompilationUnit_script() {
    var parseResult = parseStringWithErrors('''
#!/bin/dartvm
''');
    var node = parseResult.findNode.unit;
    _assertSource('#!/bin/dartvm', node);
  }

  void test_visitCompilationUnit_script_declaration() {
    var parseResult = parseStringWithErrors('''
#!/bin/dartvm
var a;
''');
    var node = parseResult.findNode.unit;
    _assertSource('#!/bin/dartvm var a;', node);
  }

  void test_visitCompilationUnit_script_directive() {
    var parseResult = parseStringWithErrors('''
#!/bin/dartvm
library my;
''');
    var node = parseResult.findNode.unit;
    _assertSource('#!/bin/dartvm library my;', node);
  }

  void test_visitCompilationUnit_script_directives_declarations() {
    var parseResult = parseStringWithErrors('''
#!/bin/dartvm
library my;
var a;
''');
    var node = parseResult.findNode.unit;
    _assertSource('#!/bin/dartvm library my; var a;', node);
  }

  void test_visitConditionalExpression() {
    var code = 'a ? b : c';
    var parseResult = parseStringWithErrors('''
void f() {
  $code;
}
''');
    var node = parseResult.findNode.conditionalExpression(code);
    _assertSource(code, node);
  }

  void test_visitConstantPattern() {
    var parseResult = parseStringWithErrors('''
void f(x) {
  if (x case true) {}
}
''');
    var node = parseResult.findNode.constantPattern('true');
    _assertSource('true', node);
  }

  void test_visitConstructorDeclaration_factoryHead_named() {
    var code = 'factory named() {}';
    var parseResult = parseStringWithErrors('''
class A {
  $code
}
''');
    var node = parseResult.findNode.constructor(code);
    _assertSource(code, node);
  }

  void test_visitConstructorDeclaration_factoryHead_unnamed() {
    var code = 'factory () {}';
    var parseResult = parseStringWithErrors('''
class A {
  $code
}
''');
    var node = parseResult.findNode.constructor(code);
    _assertSource(code, node);
  }

  void test_visitConstructorDeclaration_newHead_named() {
    var code = 'new named();';
    var parseResult = parseStringWithErrors('''
class A {
  $code
}
''');
    var node = parseResult.findNode.constructor(code);
    _assertSource(code, node);
  }

  void test_visitConstructorDeclaration_newHead_unnamed() {
    var code = 'new ();';
    var parseResult = parseStringWithErrors('''
class A {
  $code
}
''');
    var node = parseResult.findNode.constructor('new');
    _assertSource(code, node);
  }

  void test_visitConstructorDeclaration_singleInitializer() {
    var code = 'A() : a = b;';
    var parseResult = parseStringWithErrors('''
class A {
  $code
}
''');
    var node = parseResult.findNode.constructor(code);
    _assertSource(code, node);
  }

  void test_visitConstructorDeclaration_typeName_const() {
    var code = 'const A();';
    var parseResult = parseStringWithErrors('''
class A {
  $code
}
''');
    var node = parseResult.findNode.constructor(code);
    _assertSource(code, node);
  }

  void test_visitConstructorDeclaration_typeName_external() {
    var code = 'external A();';
    var parseResult = parseStringWithErrors('''
class A {
  $code
}
''');
    var node = parseResult.findNode.constructor(code);
    _assertSource(code, node);
  }

  void test_visitConstructorDeclaration_typeName_factory_named() {
    var code = 'factory A.named() {}';
    var parseResult = parseStringWithErrors('''
class A {
  $code
}
''');
    var node = parseResult.findNode.constructor(code);
    _assertSource(code, node);
  }

  void test_visitConstructorDeclaration_typeName_factory_unnamed() {
    var code = 'factory A() {}';
    var parseResult = parseStringWithErrors('''
class A {
  $code
}
''');
    var node = parseResult.findNode.constructor(code);
    _assertSource(code, node);
  }

  void
  test_visitConstructorDeclaration_typeName_formalParameters_optionalPositional() {
    var code = 'A(int a, [int b = 0]);';
    var parseResult = parseStringWithErrors('''
class A {
  $code
}
''');
    var node = parseResult.findNode.constructor(code);
    _assertSource(code, node);
  }

  void
  test_visitConstructorDeclaration_typeName_formalParameters_requiredPositional() {
    var code = 'A(int a, double b);';
    var parseResult = parseStringWithErrors('''
class A {
  $code
}
''');
    var node = parseResult.findNode.constructor(code);
    _assertSource(code, node);
  }

  void test_visitConstructorDeclaration_typeName_multipleInitializers() {
    var code = 'A() : a = b, c = d {}';
    var parseResult = parseStringWithErrors('''
class A {
  $code
}
''');
    var node = parseResult.findNode.constructor(code);
    _assertSource(code, node);
  }

  void test_visitConstructorDeclaration_typeName_named() {
    var code = 'A.foo();';
    var parseResult = parseStringWithErrors('''
class A {
  $code
}
''');
    var node = parseResult.findNode.constructor(code);
    _assertSource(code, node);
  }

  void test_visitConstructorDeclaration_typeName_unnamed() {
    var code = 'A();';
    var parseResult = parseStringWithErrors('''
class A {
  $code
}
''');
    var node = parseResult.findNode.constructor(code);
    _assertSource(code, node);
  }

  void test_visitConstructorDeclaration_typeName_withInitializers() {
    var code = 'A() : a = 0, super();';
    var parseResult = parseStringWithErrors('''
class A {
  int a;
  $code
}
''');
    var node = parseResult.findNode.constructor(code);
    _assertSource(code, node);
  }

  void test_visitConstructorDeclaration_withMetadata() {
    var code = '@deprecated C() {}';
    var parseResult = parseStringWithErrors('''
class C {
  $code
}
''');
    var node = parseResult.findNode.constructor(code);
    _assertSource(code, node);
  }

  void test_visitConstructorFieldInitializer_withoutThis() {
    var code = 'a = 0';
    var parseResult = parseStringWithErrors('''
class C {
  C() : $code;
}
''');
    var node = parseResult.findNode.constructorFieldInitializer(code);
    _assertSource(code, node);
  }

  void test_visitConstructorFieldInitializer_withThis() {
    var code = 'this.a = 0';
    var parseResult = parseStringWithErrors('''
class C {
  C() : $code;
}
''');
    var node = parseResult.findNode.constructorFieldInitializer(code);
    _assertSource(code, node);
  }

  void test_visitConstructorName_named_prefix() {
    var code = 'prefix.A.foo';
    var parseResult = parseStringWithErrors('''
final x = new $code();
''');
    var node = parseResult.findNode.constructorName(code);
    _assertSource(code, node);
  }

  void test_visitConstructorName_unnamed_noPrefix() {
    var code = 'A';
    var parseResult = parseStringWithErrors('''
final x = new $code();
''');
    var node = parseResult.findNode.constructorName(code);
    _assertSource(code, node);
  }

  void test_visitConstructorName_unnamed_prefix() {
    var code = 'prefix.A';
    var parseResult = parseStringWithErrors('''
final x = new $code();
''');
    var node = parseResult.findNode.constructorName(code);
    _assertSource(code, node);
  }

  void test_visitContinueStatement_label() {
    var code = 'continue L;';
    var parseResult = parseStringWithErrors('''
void f() {
  L: while (true) {
    $code
  }
}
''');
    var node = parseResult.findNode.continueStatement('continue');
    _assertSource(code, node);
  }

  void test_visitContinueStatement_noLabel() {
    var code = 'continue;';
    var parseResult = parseStringWithErrors('''
void f() {
  while (true) {
    $code
  }
}
''');
    var node = parseResult.findNode.continueStatement('continue');
    _assertSource(code, node);
  }

  void test_visitDeclaredVariablePattern() {
    var parseResult = parseStringWithErrors('''
void f(x) {
  switch (x) {
    case int? a:
      break;
  }
}
''');
    var node = parseResult.findNode.declaredVariablePattern('int?');
    _assertSource('int? a', node);
  }

  void test_visitDefaultFormalParameter_annotation() {
    var code = '@deprecated p = 0';
    var parseResult = parseStringWithErrors('''
void f([$code]) {}
''');
    var node = parseResult.findNode.formalParameter(code);
    _assertSource(code, node);
  }

  void test_visitDefaultFormalParameter_named_noValue() {
    var code = 'int? a';
    var parseResult = parseStringWithErrors('''
void f({$code}) {}
''');
    var node = parseResult.findNode.formalParameter(code);
    _assertSource(code, node);
  }

  void test_visitDefaultFormalParameter_named_value() {
    var code = 'int? a = 0';
    var parseResult = parseStringWithErrors('''
void f({$code}) {}
''');
    var node = parseResult.findNode.formalParameter(code);
    _assertSource(code, node);
  }

  void test_visitDefaultFormalParameter_positional_noValue() {
    var code = 'int? a';
    var parseResult = parseStringWithErrors('''
void f([$code]) {}
''');
    var node = parseResult.findNode.formalParameter(code);
    _assertSource(code, node);
  }

  void test_visitDefaultFormalParameter_positional_value() {
    var code = 'int? a = 0';
    var parseResult = parseStringWithErrors('''
void f([$code]) {}
''');
    var node = parseResult.findNode.formalParameter(code);
    _assertSource(code, node);
  }

  void test_visitDoStatement() {
    var code = 'do {} while (true);';
    var parseResult = parseStringWithErrors('''
void f () {
  $code
}
''');
    var node = parseResult.findNode.doStatement(code);
    _assertSource(code, node);
  }

  void test_visitDottedName_multiple() {
    var code = 'a.b.c';
    var parseResult = parseStringWithErrors('''
library $code;
''');
    var node = parseResult.findNode.singleDottedName;
    _assertSource(code, node);
  }

  void test_visitDottedName_single() {
    var code = 'my';
    var parseResult = parseStringWithErrors('''
library $code;
''');
    var node = parseResult.findNode.singleDottedName;
    _assertSource(code, node);
  }

  void test_visitDoubleLiteral() {
    var code = '3.14';
    var parseResult = parseStringWithErrors('''
final x = $code;
''');
    var node = parseResult.findNode.doubleLiteral(code);
    _assertSource(code, node);
  }

  void test_visitEmptyFunctionBody() {
    var code = ';';
    var parseResult = parseStringWithErrors('''
void f() {
  ;
}
''');
    var node = parseResult.findNode.emptyStatement(code);
    _assertSource(code, node);
  }

  void test_visitEmptyStatement() {
    var code = ';';
    var parseResult = parseStringWithErrors('''
abstract class A {
  void foo();
}
''');
    var node = parseResult.findNode.emptyFunctionBody(code);
    _assertSource(code, node);
  }

  void test_visitEnumConstantDeclaration_augment() {
    var code = 'augment v';
    var parseResult = parseStringWithErrors('''
augment enum E {
  $code
}
''');
    var node = parseResult.findNode.enumConstantDeclaration(code);
    _assertSource(code, node);
  }

  void test_visitEnumDeclaration_augment() {
    var code = 'augment enum E {v}';
    var parseResult = parseStringWithErrors('''
$code
''');
    var node = parseResult.findNode.enumDeclaration('enum E');
    _assertSource(code, node);
  }

  void test_visitEnumDeclaration_constant_arguments_named() {
    var parseResult = parseStringWithErrors(r'''
enum E {
  v<double>.named(42)
}
''');
    var node = parseResult.findNode.enumDeclaration('enum E');
    _assertSource('enum E {v<double>.named(42)}', node);
  }

  void test_visitEnumDeclaration_constant_arguments_unnamed() {
    var parseResult = parseStringWithErrors(r'''
enum E {
  v<double>(42)
}
''');
    var node = parseResult.findNode.enumDeclaration('enum E');
    _assertSource('enum E {v<double>(42)}', node);
  }

  void test_visitEnumDeclaration_constants_multiple() {
    var parseResult = parseStringWithErrors(r'''
enum E {one, two}
''');
    var node = parseResult.findNode.enumDeclaration('E');
    _assertSource('enum E {one, two}', node);
  }

  void test_visitEnumDeclaration_constants_single() {
    var parseResult = parseStringWithErrors(r'''
enum E {one}
''');
    var node = parseResult.findNode.enumDeclaration('E');
    _assertSource('enum E {one}', node);
  }

  void test_visitEnumDeclaration_field_constructor() {
    var parseResult = parseStringWithErrors(r'''
enum E {
  one, two;
  final int field;
  E(this.field);
}
''');
    var node = parseResult.findNode.enumDeclaration('enum E');
    _assertSource('enum E {one, two; final int field; E(this.field);}', node);
  }

  void test_visitEnumDeclaration_method() {
    var parseResult = parseStringWithErrors(r'''
enum E {
  one, two;
  void myMethod() {}
  int get myGetter => 0;
}
''');
    var node = parseResult.findNode.enumDeclaration('enum E');
    _assertSource(
      'enum E {one, two; void myMethod() {} int get myGetter => 0;}',
      node,
    );
  }

  void test_visitEnumDeclaration_withoutMembers() {
    var parseResult = parseStringWithErrors(r'''
enum E<T> with M1, M2 implements I1, I2 {one, two}
''');
    var node = parseResult.findNode.enumDeclaration('E');
    _assertSource('enum E<T> with M1, M2 implements I1, I2 {one, two}', node);
  }

  void test_visitExportDirective_combinator() {
    var code = "export 'a.dart' show A;";
    var parseResult = parseStringWithErrors('''
$code
''');
    var node = parseResult.findNode.export(code);
    _assertSource(code, node);
  }

  void test_visitExportDirective_combinators() {
    var code = "export 'a.dart' show A hide B;";
    var parseResult = parseStringWithErrors('''
$code
''');
    var node = parseResult.findNode.export(code);
    _assertSource(code, node);
  }

  void test_visitExportDirective_configurations() {
    var parseResult = parseStringWithErrors(r'''
export 'foo.dart'
  if (dart.library.io) 'foo_io.dart'
  if (dart.library.html) 'foo_html.dart';
''');
    var unit = parseResult.findNode.unit;
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
    var parseResult = parseStringWithErrors(code);
    var node = parseResult.findNode.export(code);
    _assertSource(code, node);
  }

  void test_visitExportDirective_withMetadata() {
    var code = '@deprecated export "a.dart";';
    var parseResult = parseStringWithErrors(code);
    var node = parseResult.findNode.export(code);
    _assertSource(code, node);
  }

  void test_visitExpressionFunctionBody_async() {
    var code = 'async => 0;';
    var parseResult = parseStringWithErrors('''
void f() $code
''');
    var node = parseResult.findNode.expressionFunctionBody(code);
    _assertSource(code, node);
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
    var parseResult = parseStringWithErrors('''
void f() $code
''');
    var node = parseResult.findNode.expressionFunctionBody(code);
    _assertSource(code, node);
  }

  void test_visitExpressionStatement() {
    var code = '1 + 2;';
    var parseResult = parseStringWithErrors('''
void f() {
  $code
}
''');
    var node = parseResult.findNode.expressionStatement(code);
    _assertSource(code, node);
  }

  void test_visitExtendsClause() {
    var code = 'extends A';
    var parseResult = parseStringWithErrors('''
class C $code {}
''');
    var node = parseResult.findNode.extendsClause(code);
    _assertSource(code, node);
  }

  void test_visitExtensionDeclaration_augment() {
    var code = 'augment extension E {}';
    var parseResult = parseStringWithErrors('''
$code
''');
    var node = parseResult.findNode.extensionDeclaration(code);
    _assertSource(code, node);
  }

  void test_visitExtensionDeclaration_empty() {
    var code = 'extension E on C {}';
    var parseResult = parseStringWithErrors('''
$code
''');
    var node = parseResult.findNode.extensionDeclaration(code);
    _assertSource(code, node);
  }

  void test_visitExtensionDeclaration_multipleMember() {
    var code = 'extension E on C {static var a; static var b;}';
    var parseResult = parseStringWithErrors('''
$code
''');
    var node = parseResult.findNode.extensionDeclaration(code);
    _assertSource(code, node);
  }

  void test_visitExtensionDeclaration_parameters() {
    var code = 'extension E<T> on C {}';
    var parseResult = parseStringWithErrors('''
$code
''');
    var node = parseResult.findNode.extensionDeclaration(code);
    _assertSource(code, node);
  }

  void test_visitExtensionDeclaration_singleMember() {
    var code = 'extension E on C {static var a;}';
    var parseResult = parseStringWithErrors('''
$code
''');
    var node = parseResult.findNode.extensionDeclaration(code);
    _assertSource(code, node);
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
    var parseResult = parseStringWithErrors('''
$code
''');
    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    _assertSource(code, node);
  }

  void test_visitExtensionType_augment() {
    var code = 'augment extension type E(int it) {}';
    var parseResult = parseStringWithErrors('''
$code
''');
    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    _assertSource(code, node);
  }

  void test_visitExtensionType_implements() {
    var code = 'extension type E(int it) implements num {}';
    var parseResult = parseStringWithErrors('''
$code
''');
    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    _assertSource(code, node);
  }

  void test_visitExtensionType_method() {
    var code = 'extension type E(int it) {void foo() {}}';
    var parseResult = parseStringWithErrors('''
$code
''');
    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    _assertSource(code, node);
  }

  void test_visitFieldDeclaration_abstract() {
    var code = 'abstract var a;';
    var parseResult = parseStringWithErrors('''
class A {
  $code
}
''');
    var node = parseResult.findNode.fieldDeclaration(code);
    _assertSource(code, node);
  }

  void test_visitFieldDeclaration_abstract_external() {
    var code = 'abstract external var a;';
    var parseResult = parseStringWithErrors('''
class A {
  $code
}
''');
    var node = parseResult.findNode.fieldDeclaration(code);
    _assertSource('external abstract var a;', node);
  }

  void test_visitFieldDeclaration_abstract_static() {
    var code = 'abstract static var a;';
    var parseResult = parseStringWithErrors('''
class A {
  $code
}
''');
    var node = parseResult.findNode.fieldDeclaration(code);
    _assertSource('static abstract var a;', node);
  }

  void test_visitFieldDeclaration_augment() {
    var code = 'augment var a = 0;';
    var parseResult = parseStringWithErrors('''
augment class A {
  $code
}
''');
    var node = parseResult.findNode.fieldDeclaration(code);
    _assertSource(code, node);
  }

  void test_visitFieldDeclaration_covariant() {
    var code = 'covariant var a;';
    var parseResult = parseStringWithErrors('''
class A {
  $code
}
''');
    var node = parseResult.findNode.fieldDeclaration(code);
    _assertSource(code, node);
  }

  void test_visitFieldDeclaration_external() {
    var code = 'external var a;';
    var parseResult = parseStringWithErrors('''
class A {
  $code
}
''');
    var node = parseResult.findNode.fieldDeclaration(code);
    _assertSource(code, node);
  }

  void test_visitFieldDeclaration_instance() {
    var code = 'var a;';
    var parseResult = parseStringWithErrors('''
class A {
  $code
}
''');
    var node = parseResult.findNode.fieldDeclaration(code);
    _assertSource(code, node);
  }

  void test_visitFieldDeclaration_static() {
    var code = 'static var a;';
    var parseResult = parseStringWithErrors('''
class A {
  $code
}
''');
    var node = parseResult.findNode.fieldDeclaration(code);
    _assertSource(code, node);
  }

  void test_visitFieldDeclaration_withMetadata() {
    var code = '@deprecated var a;';
    var parseResult = parseStringWithErrors('''
class A {
  $code
}
''');
    var node = parseResult.findNode.fieldDeclaration(code);
    _assertSource(code, node);
  }

  void test_visitFieldFormalParameter_annotation() {
    var code = '@deprecated this.foo';
    var parseResult = parseStringWithErrors('''
class A {
  final int foo;
  A($code);
}
''');
    var node = parseResult.findNode.fieldFormalParameter(code);
    _assertSource(code, node);
  }

  void test_visitFieldFormalParameter_functionTyped() {
    var code = 'A this.a(b)';
    var parseResult = parseStringWithErrors('''
class A {
  A($code);
}
''');
    var node = parseResult.findNode.fieldFormalParameter(code);
    _assertSource(code, node);
  }

  void test_visitFieldFormalParameter_functionTyped_typeParameters() {
    var code = 'A this.a<E, F>(b)';
    var parseResult = parseStringWithErrors('''
class A {
  A($code);
}
''');
    var node = parseResult.findNode.fieldFormalParameter(code);
    _assertSource(code, node);
  }

  void test_visitFieldFormalParameter_keyword() {
    var code = 'var this.a';
    var parseResult = parseStringWithErrors('''
// @dart = 3.10
class A {
  A($code);
}
''');
    var node = parseResult.findNode.fieldFormalParameter(code);
    _assertSource(code, node);
  }

  void test_visitFieldFormalParameter_keywordAndType() {
    var code = 'final A this.a';
    var parseResult = parseStringWithErrors('''
// @dart = 3.10
class A {
  A($code);
}
''');
    var node = parseResult.findNode.fieldFormalParameter(code);
    _assertSource(code, node);
  }

  void test_visitFieldFormalParameter_type() {
    var code = 'A this.a';
    var parseResult = parseStringWithErrors('''
class A {
  A($code);
}
''');
    var node = parseResult.findNode.fieldFormalParameter(code);
    _assertSource(code, node);
  }

  void test_visitFieldFormalParameter_type_covariant() {
    var code = 'covariant A this.a';
    var parseResult = parseStringWithErrors('''
class A {
  A($code);
}
''');
    var node = parseResult.findNode.fieldFormalParameter(code);
    _assertSource(code, node);
  }

  void test_visitForEachPartsWithIdentifier() {
    var code = 'e in []';
    var parseResult = parseStringWithErrors('''
void f() {
  for ($code) {}
}
''');
    var node = parseResult.findNode.forEachPartsWithIdentifier(code);
    _assertSource(code, node);
  }

  void test_visitForEachPartsWithPattern() {
    var code = 'final (a, b) in c';
    var parseResult = parseStringWithErrors('''
void f () {
  for ($code) {}
}
''');
    var node = parseResult.findNode.forEachPartsWithPattern(code);
    _assertSource(code, node);
  }

  void test_visitForEachStatement_declared() {
    var code = 'for (final a in b) {}';
    var parseResult = parseStringWithErrors('''
void f () {
  $code
}
''');
    var node = parseResult.findNode.forStatement(code);
    _assertSource(code, node);
  }

  void test_visitForEachStatement_variable() {
    var code = 'for (a in b) {}';
    var parseResult = parseStringWithErrors('''
void f () {
  $code
}
''');
    var node = parseResult.findNode.forStatement(code);
    _assertSource(code, node);
  }

  void test_visitForEachStatement_variable_await() {
    var code = 'await for (final a in b) {}';
    var parseResult = parseStringWithErrors('''
void f() async {
  $code
}
''');
    var node = parseResult.findNode.forStatement(code);
    _assertSource(code, node);
  }

  void test_visitForElement() {
    var code = 'for (e in []) 0';
    var parseResult = parseStringWithErrors('''
final v = [ $code ];
''');
    var node = parseResult.findNode.forElement(code);
    _assertSource(code, node);
  }

  void test_visitFormalParameterList_empty() {
    var code = '()';
    var parseResult = parseStringWithErrors('''
void f$code {}
''');
    var node = parseResult.findNode.formalParameterList(code);
    _assertSource(code, node);
  }

  void test_visitFormalParameterList_n() {
    var code = '({a = 0})';
    var parseResult = parseStringWithErrors('''
void f$code {}
''');
    var node = parseResult.findNode.formalParameterList(code);
    _assertSource(code, node);
  }

  void test_visitFormalParameterList_namedRequired() {
    var code = '({required a, required int b})';
    var parseResult = parseStringWithErrors('''
void f$code {}
''');
    var node = parseResult.findNode.formalParameterList(code);
    _assertSource(code, node);
  }

  void test_visitFormalParameterList_nn() {
    var code = '({int a = 0, b = 1})';
    var parseResult = parseStringWithErrors('''
void f$code {}
''');
    var node = parseResult.findNode.formalParameterList(code);
    _assertSource(code, node);
  }

  void test_visitFormalParameterList_p() {
    var code = '([a = 0])';
    var parseResult = parseStringWithErrors('''
void f$code {}
''');
    var node = parseResult.findNode.formalParameterList(code);
    _assertSource(code, node);
  }

  void test_visitFormalParameterList_pp() {
    var code = '([a = 0, b = 1])';
    var parseResult = parseStringWithErrors('''
void f$code {}
''');
    var node = parseResult.findNode.formalParameterList(code);
    _assertSource(code, node);
  }

  void test_visitFormalParameterList_r() {
    var code = '(int a)';
    var parseResult = parseStringWithErrors('''
void f$code {}
''');
    var node = parseResult.findNode.formalParameterList(code);
    _assertSource(code, node);
  }

  void test_visitFormalParameterList_rn() {
    var code = '(a, {b = 1})';
    var parseResult = parseStringWithErrors('''
void f$code {}
''');
    var node = parseResult.findNode.formalParameterList(code);
    _assertSource(code, node);
  }

  void test_visitFormalParameterList_rnn() {
    var code = '(a, {b = 1, c = 2})';
    var parseResult = parseStringWithErrors('''
void f$code {}
''');
    var node = parseResult.findNode.formalParameterList(code);
    _assertSource(code, node);
  }

  void test_visitFormalParameterList_rp() {
    var code = '(a, [b = 1])';
    var parseResult = parseStringWithErrors('''
void f$code {}
''');
    var node = parseResult.findNode.formalParameterList(code);
    _assertSource(code, node);
  }

  void test_visitFormalParameterList_rpp() {
    var code = '(a, [b = 1, c = 2])';
    var parseResult = parseStringWithErrors('''
void f$code {}
''');
    var node = parseResult.findNode.formalParameterList(code);
    _assertSource(code, node);
  }

  void test_visitFormalParameterList_rr() {
    var code = '(int a, int b)';
    var parseResult = parseStringWithErrors('''
void f$code {}
''');
    var node = parseResult.findNode.formalParameterList(code);
    _assertSource(code, node);
  }

  void test_visitFormalParameterList_rrn() {
    var code = '(a, b, {c = 2})';
    var parseResult = parseStringWithErrors('''
void f$code {}
''');
    var node = parseResult.findNode.formalParameterList(code);
    _assertSource(code, node);
  }

  void test_visitFormalParameterList_rrnn() {
    var code = '(a, b, {c = 2, d = 3})';
    var parseResult = parseStringWithErrors('''
void f$code {}
''');
    var node = parseResult.findNode.formalParameterList(code);
    _assertSource(code, node);
  }

  void test_visitFormalParameterList_rrp() {
    var code = '(a, b, [c = 2])';
    var parseResult = parseStringWithErrors('''
void f$code {}
''');
    var node = parseResult.findNode.formalParameterList(code);
    _assertSource(code, node);
  }

  void test_visitFormalParameterList_rrpp() {
    var code = '(a, b, [c = 2, d = 3])';
    var parseResult = parseStringWithErrors('''
void f$code {}
''');
    var node = parseResult.findNode.formalParameterList(code);
    _assertSource(code, node);
  }

  void test_visitForPartsWithDeclarations() {
    var code = 'var v = 0; v < 10; v++';
    var parseResult = parseStringWithErrors('''
void f() {
  for ($code) {}
}
''');
    var node = parseResult.findNode.forPartsWithDeclarations(code);
    _assertSource(code, node);
  }

  void test_visitForPartsWithExpression() {
    var code = 'v = 0; v < 10; v++';
    var parseResult = parseStringWithErrors('''
void f() {
  for ($code) {}
}
''');
    var node = parseResult.findNode.forPartsWithExpression(code);
    _assertSource(code, node);
  }

  void test_visitForPartsWithPattern() {
    var code = 'var (a, b) = (0, 1); a < 10; a++, b++';
    var parseResult = parseStringWithErrors('''
void f() {
  for ($code) {}
}
''');
    var node = parseResult.findNode.forPartsWithPattern(code);
    _assertSource(code, node);
  }

  void test_visitForStatement() {
    var code = 'for (var v in [0]) {}';
    var parseResult = parseStringWithErrors('''
void f() {
  $code
}
''');
    var node = parseResult.findNode.forStatement(code);
    _assertSource(code, node);
  }

  void test_visitForStatement_c() {
    var code = 'for (; c;) {}';
    var parseResult = parseStringWithErrors('''
void f () {
  $code
}
''');
    var node = parseResult.findNode.forStatement(code);
    _assertSource(code, node);
  }

  void test_visitForStatement_cu() {
    var code = 'for (; c; u) {}';
    var parseResult = parseStringWithErrors('''
void f () {
  $code
}
''');
    var node = parseResult.findNode.forStatement(code);
    _assertSource(code, node);
  }

  void test_visitForStatement_e() {
    var code = 'for (e;;) {}';
    var parseResult = parseStringWithErrors('''
void f () {
  $code
}
''');
    var node = parseResult.findNode.forStatement(code);
    _assertSource(code, node);
  }

  void test_visitForStatement_ec() {
    var code = 'for (e; c;) {}';
    var parseResult = parseStringWithErrors('''
void f () {
  $code
}
''');
    var node = parseResult.findNode.forStatement(code);
    _assertSource(code, node);
  }

  void test_visitForStatement_ecu() {
    var code = 'for (e; c; u) {}';
    var parseResult = parseStringWithErrors('''
void f () {
  $code
}
''');
    var node = parseResult.findNode.forStatement(code);
    _assertSource(code, node);
  }

  void test_visitForStatement_eu() {
    var code = 'for (e;; u) {}';
    var parseResult = parseStringWithErrors('''
void f () {
  $code
}
''');
    var node = parseResult.findNode.forStatement(code);
    _assertSource(code, node);
  }

  void test_visitForStatement_i() {
    var code = 'for (var i;;) {}';
    var parseResult = parseStringWithErrors('''
void f () {
  $code
}
''');
    var node = parseResult.findNode.forStatement(code);
    _assertSource(code, node);
  }

  void test_visitForStatement_ic() {
    var code = 'for (var i; c;) {}';
    var parseResult = parseStringWithErrors('''
void f () {
  $code
}
''');
    var node = parseResult.findNode.forStatement(code);
    _assertSource(code, node);
  }

  void test_visitForStatement_icu() {
    var code = 'for (var i; c; u) {}';
    var parseResult = parseStringWithErrors('''
void f () {
  $code
}
''');
    var node = parseResult.findNode.forStatement(code);
    _assertSource(code, node);
  }

  void test_visitForStatement_iu() {
    var code = 'for (var i;; u) {}';
    var parseResult = parseStringWithErrors('''
void f () {
  $code
}
''');
    var node = parseResult.findNode.forStatement(code);
    _assertSource(code, node);
  }

  void test_visitForStatement_u() {
    var code = 'for (;; u) {}';
    var parseResult = parseStringWithErrors('''
void f () {
  $code
}
''');
    var node = parseResult.findNode.forStatement(code);
    _assertSource(code, node);
  }

  void test_visitFunctionDeclaration_augment() {
    var code = 'augment void f() {}';
    var parseResult = parseStringWithErrors(code);
    var node = parseResult.findNode.functionDeclaration(code);
    _assertSource(code, node);
  }

  void test_visitFunctionDeclaration_external() {
    var code = 'external void f();';
    var parseResult = parseStringWithErrors(code);
    var node = parseResult.findNode.functionDeclaration(code);
    _assertSource(code, node);
  }

  void test_visitFunctionDeclaration_getter() {
    var code = 'get foo {}';
    var parseResult = parseStringWithErrors(code);
    var node = parseResult.findNode.functionDeclaration(code);
    _assertSource(code, node);
  }

  void test_visitFunctionDeclaration_local_blockBody() {
    var code = 'void foo() {}';
    var parseResult = parseStringWithErrors('''
void f() {
  $code
}
''');
    var node = parseResult.findNode.functionDeclaration(code);
    _assertSource(code, node);
  }

  void test_visitFunctionDeclaration_local_expressionBody() {
    var code = 'int foo() => 42;';
    var parseResult = parseStringWithErrors('''
void f() {
  $code
}
''');
    var node = parseResult.findNode.functionDeclaration(code);
    _assertSource(code, node);
  }

  void test_visitFunctionDeclaration_normal() {
    var code = 'void foo() {}';
    var parseResult = parseStringWithErrors(code);
    var node = parseResult.findNode.functionDeclaration(code);
    _assertSource(code, node);
  }

  void test_visitFunctionDeclaration_setter() {
    var code = 'set foo(int _) {}';
    var parseResult = parseStringWithErrors(code);
    var node = parseResult.findNode.functionDeclaration(code);
    _assertSource(code, node);
  }

  void test_visitFunctionDeclaration_typeParameters() {
    var code = 'void foo<T>() {}';
    var parseResult = parseStringWithErrors(code);
    var node = parseResult.findNode.functionDeclaration(code);
    _assertSource(code, node);
  }

  void test_visitFunctionDeclaration_withMetadata() {
    var code = '@deprecated void f() {}';
    var parseResult = parseStringWithErrors(code);
    var node = parseResult.findNode.functionDeclaration(code);
    _assertSource(code, node);
  }

  void test_visitFunctionDeclarationStatement() {
    var code = 'void foo() {}';
    var parseResult = parseStringWithErrors('''
void f() {
  $code
}
''');
    var node = parseResult.findNode.functionDeclaration(code);
    _assertSource(code, node);
  }

  void test_visitFunctionExpression() {
    var code = '() {}';
    var parseResult = parseStringWithErrors('''
final f = $code;
''');
    var node = parseResult.findNode.functionExpression(code);
    _assertSource(code, node);
  }

  void test_visitFunctionExpression_typeParameters() {
    var code = '<T>() {}';
    var parseResult = parseStringWithErrors('''
final f = $code;
''');
    var node = parseResult.findNode.functionExpression(code);
    _assertSource(code, node);
  }

  void test_visitFunctionExpressionInvocation_minimal() {
    var code = '(a)()';
    var parseResult = parseStringWithErrors('''
void f() {
  $code;
}
''');
    var node = parseResult.findNode.functionExpressionInvocation(code);
    _assertSource(code, node);
  }

  void test_visitFunctionExpressionInvocation_typeArguments() {
    var code = '(a)<int>()';
    var parseResult = parseStringWithErrors('''
void f() {
  $code;
}
''');
    var node = parseResult.findNode.functionExpressionInvocation(code);
    _assertSource(code, node);
  }

  void test_visitFunctionTypeAlias_augment() {
    var code = 'augment typedef void F();';
    var parseResult = parseStringWithErrors('''
$code
''');
    var node = parseResult.findNode.functionTypeAlias(code);
    _assertSource(code, node);
  }

  void test_visitFunctionTypeAlias_generic() {
    var code = 'typedef A F<B>();';
    var parseResult = parseStringWithErrors('''
$code
''');
    var node = parseResult.findNode.functionTypeAlias(code);
    _assertSource(code, node);
  }

  void test_visitFunctionTypeAlias_nonGeneric() {
    var code = 'typedef A F();';
    var parseResult = parseStringWithErrors('''
$code
''');
    var node = parseResult.findNode.functionTypeAlias(code);
    _assertSource(code, node);
  }

  void test_visitFunctionTypeAlias_withMetadata() {
    var code = '@deprecated typedef void F();';
    var parseResult = parseStringWithErrors(code);
    var node = parseResult.findNode.functionTypeAlias(code);
    _assertSource(code, node);
  }

  void test_visitFunctionTypedFormalParameter_annotation() {
    var code = '@deprecated g()';
    var parseResult = parseStringWithErrors('''
void f($code) {}
''');
    var node = parseResult.findNode.formalParameter(code);
    _assertSource(code, node);
  }

  void test_visitFunctionTypedFormalParameter_noType() {
    var code = 'int f()';
    var parseResult = parseStringWithErrors('''
void f($code) {}
''');
    var node = parseResult.findNode.formalParameter(code);
    _assertSource(code, node);
  }

  void test_visitFunctionTypedFormalParameter_nullable() {
    var code = 'T f()?';
    var parseResult = parseStringWithErrors('''
void f($code) {}
''');
    var node = parseResult.findNode.formalParameter(code);
    _assertSource(code, node);
  }

  void test_visitFunctionTypedFormalParameter_type() {
    var code = 'T f()';
    var parseResult = parseStringWithErrors('''
void f($code) {}
''');
    var node = parseResult.findNode.formalParameter(code);
    _assertSource(code, node);
  }

  void test_visitFunctionTypedFormalParameter_type_covariant() {
    var code = 'covariant T f()?';
    var parseResult = parseStringWithErrors('''
class A {
  void foo($code) {}
}
''');
    var node = parseResult.findNode.formalParameter(code);
    _assertSource(code, node);
  }

  void test_visitFunctionTypedFormalParameter_typeParameters() {
    var code = 'T f<E>()';
    var parseResult = parseStringWithErrors('''
void f($code) {}
''');
    var node = parseResult.findNode.formalParameter(code);
    _assertSource(code, node);
  }

  void test_visitGenericFunctionType() {
    var code = 'int Function<T>(T)';
    var parseResult = parseStringWithErrors('''
void f($code x) {}
''');
    var node = parseResult.findNode.genericFunctionType(code);
    _assertSource(code, node);
  }

  void test_visitGenericFunctionType_withQuestion() {
    var code = 'int Function<T>(T)?';
    var parseResult = parseStringWithErrors('''
void f($code x) {}
''');
    var node = parseResult.findNode.genericFunctionType(code);
    _assertSource(code, node);
  }

  void test_visitGenericTypeAlias() {
    var code = 'typedef X<S> = S Function<T>(T);';
    var parseResult = parseStringWithErrors('''
$code
''');
    var node = parseResult.findNode.genericTypeAlias(code);
    _assertSource(code, node);
  }

  void test_visitGenericTypeAlias_augment() {
    var code = 'augment typedef A = int;';
    var parseResult = parseStringWithErrors('''
$code
''');
    var node = parseResult.findNode.genericTypeAlias(code);
    _assertSource(code, node);
  }

  void test_visitGuardedPattern() {
    var code = 'var y when y > 0';
    var parseResult = parseStringWithErrors('''
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

  void test_visitIfElement_else() {
    var code = 'if (b) 1 else 0';
    var parseResult = parseStringWithErrors('''
final v = [ $code ];
''');
    var node = parseResult.findNode.ifElement(code);
    _assertSource(code, node);
  }

  void test_visitIfElement_then() {
    var code = 'if (b) 1';
    var parseResult = parseStringWithErrors('''
final v = [ $code ];
''');
    var node = parseResult.findNode.ifElement(code);
    _assertSource(code, node);
  }

  void test_visitIfStatement_withElse() {
    var code = 'if (c) {} else {}';
    var parseResult = parseStringWithErrors('''
void f () {
  $code
}
''');
    var node = parseResult.findNode.ifStatement(code);
    _assertSource(code, node);
  }

  void test_visitIfStatement_withoutElse() {
    var code = 'if (c) {}';
    var parseResult = parseStringWithErrors('''
void f() {
  $code
}
''');
    var node = parseResult.findNode.ifStatement(code);
    _assertSource(code, node);
  }

  void test_visitImplementsClause_multiple() {
    var code = 'implements A, B';
    var parseResult = parseStringWithErrors('''
class C $code {}
''');
    var node = parseResult.findNode.implementsClause(code);
    _assertSource(code, node);
  }

  void test_visitImplementsClause_single() {
    var code = 'implements A';
    var parseResult = parseStringWithErrors('''
class C $code {}
''');
    var node = parseResult.findNode.implementsClause(code);
    _assertSource(code, node);
  }

  void test_visitImportDirective_combinator() {
    var code = "import 'a.dart' show A;";
    var parseResult = parseStringWithErrors('''
$code
''');
    var node = parseResult.findNode.import(code);
    _assertSource(code, node);
  }

  void test_visitImportDirective_combinators() {
    var code = "import 'a.dart' show A hide B;";
    var parseResult = parseStringWithErrors('''
$code
''');
    var node = parseResult.findNode.import(code);
    _assertSource(code, node);
  }

  void test_visitImportDirective_configurations() {
    var parseResult = parseStringWithErrors(r'''
import 'foo.dart'
  if (dart.library.io) 'foo_io.dart'
  if (dart.library.html) 'foo_html.dart';
''');
    var unit = parseResult.findNode.unit;
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
    var parseResult = parseStringWithErrors(code);
    var node = parseResult.findNode.import(code);
    _assertSource(code, node);
  }

  void test_visitImportDirective_minimal() {
    var code = "import 'a.dart';";
    var parseResult = parseStringWithErrors(code);
    var node = parseResult.findNode.import(code);
    _assertSource(code, node);
  }

  void test_visitImportDirective_prefix() {
    var code = "import 'a.dart' as p;";
    var parseResult = parseStringWithErrors(code);
    var node = parseResult.findNode.import(code);
    _assertSource(code, node);
  }

  void test_visitImportDirective_prefix_combinator() {
    var code = "import 'a.dart' as p show A;";
    var parseResult = parseStringWithErrors('''
$code
''');
    var node = parseResult.findNode.import(code);
    _assertSource(code, node);
  }

  void test_visitImportDirective_prefix_combinators() {
    var code = "import 'a.dart' as p show A hide B;";
    var parseResult = parseStringWithErrors('''
$code
''');
    var node = parseResult.findNode.import(code);
    _assertSource(code, node);
  }

  void test_visitImportDirective_withMetadata() {
    var code = '@deprecated import "a.dart";';
    var parseResult = parseStringWithErrors(code);
    var node = parseResult.findNode.import(code);
    _assertSource(code, node);
  }

  void test_visitImportHideCombinator_multiple() {
    var code = 'hide A, B';
    var parseResult = parseStringWithErrors('''
import 'a.dart' $code;
''');
    var node = parseResult.findNode.hideCombinator(code);
    _assertSource(code, node);
  }

  void test_visitImportHideCombinator_single() {
    var code = 'hide A';
    var parseResult = parseStringWithErrors('''
import 'a.dart' $code;
''');
    var node = parseResult.findNode.hideCombinator(code);
    _assertSource(code, node);
  }

  void test_visitImportShowCombinator_multiple() {
    var code = 'show A, B';
    var parseResult = parseStringWithErrors('''
import 'a.dart' $code;
''');
    var node = parseResult.findNode.showCombinator(code);
    _assertSource(code, node);
  }

  void test_visitImportShowCombinator_single() {
    var code = 'show A';
    var parseResult = parseStringWithErrors('''
import 'a.dart' $code;
''');
    var node = parseResult.findNode.showCombinator(code);
    _assertSource(code, node);
  }

  void test_visitIndexExpression() {
    var code = 'a[0]';
    var parseResult = parseStringWithErrors('''
final x = $code;
''');
    var node = parseResult.findNode.index(code);
    _assertSource(code, node);
  }

  void test_visitInstanceCreationExpression_const() {
    var code = 'const A()';
    var parseResult = parseStringWithErrors('''
final x = $code;
''');
    var node = parseResult.findNode.instanceCreation(code);
    _assertSource(code, node);
  }

  void test_visitInstanceCreationExpression_named() {
    var code = 'new A.foo()';
    var parseResult = parseStringWithErrors('''
final x = $code;
''');
    var node = parseResult.findNode.instanceCreation(code);
    _assertSource(code, node);
  }

  void test_visitInstanceCreationExpression_unnamed() {
    var code = 'new A()';
    var parseResult = parseStringWithErrors('''
final x = $code;
''');
    var node = parseResult.findNode.instanceCreation(code);
    _assertSource(code, node);
  }

  void test_visitIntegerLiteral() {
    var code = '42';
    var parseResult = parseStringWithErrors('''
final x = $code;
''');
    var node = parseResult.findNode.integerLiteral(code);
    _assertSource(code, node);
  }

  void test_visitInterpolationExpression_expression() {
    var code = r'${foo}';
    var parseResult = parseStringWithErrors('''
final x = "$code";
''');
    var node = parseResult.findNode.interpolationExpression(code);
    _assertSource(code, node);
  }

  void test_visitInterpolationExpression_identifier() {
    var code = r'$foo';
    var parseResult = parseStringWithErrors('''
final x = "$code";
''');
    var node = parseResult.findNode.interpolationExpression(code);
    _assertSource(code, node);
  }

  void test_visitInterpolationString() {
    var code = "ccc'";
    var parseResult = parseStringWithErrors('''
final x = 'a\${bb}$code;
''');
    var node = parseResult.findNode.interpolationString(code);
    _assertSource(code, node);
  }

  void test_visitIsExpression_negated() {
    var code = 'a is! int';
    var parseResult = parseStringWithErrors('''
final x = $code;
''');
    var node = parseResult.findNode.isExpression(code);
    _assertSource(code, node);
  }

  void test_visitIsExpression_normal() {
    var code = 'a is int';
    var parseResult = parseStringWithErrors('''
final x = $code;
''');
    var node = parseResult.findNode.isExpression(code);
    _assertSource(code, node);
  }

  void test_visitLabel() {
    var code = 'myLabel:';
    var parseResult = parseStringWithErrors('''
void f() {
  $code for (final x in []) {}
}
''');
    var node = parseResult.findNode.label(code);
    _assertSource(code, node);
  }

  void test_visitLabeledStatement_multiple() {
    var code = 'a: b: return;';
    var parseResult = parseStringWithErrors('''
void f() {
  $code
}
''');
    var node = parseResult.findNode.labeledStatement(code);
    _assertSource(code, node);
  }

  void test_visitLabeledStatement_single() {
    var code = 'a: return;';
    var parseResult = parseStringWithErrors('''
void f() {
  $code
}
''');
    var node = parseResult.findNode.labeledStatement(code);
    _assertSource(code, node);
  }

  void test_visitLibraryDirective() {
    var code = 'library my;';
    var parseResult = parseStringWithErrors('''
$code
''');
    var node = parseResult.findNode.library(code);
    _assertSource(code, node);
  }

  void test_visitLibraryDirective_withMetadata() {
    var code = '@deprecated library my;';
    var parseResult = parseStringWithErrors(code);
    var node = parseResult.findNode.library(code);
    _assertSource(code, node);
  }

  void test_visitListLiteral_complex() {
    var code = '<int>[0, for (e in []) 0, if (b) 1, ...[0]]';
    var parseResult = parseStringWithErrors('''
final v = $code;
''');
    var node = parseResult.findNode.listLiteral(code);
    _assertSource(code, node);
  }

  void test_visitListLiteral_const() {
    var code = 'const []';
    var parseResult = parseStringWithErrors('''
final x = $code;
''');
    var node = parseResult.findNode.listLiteral(code);
    _assertSource(code, node);
  }

  void test_visitListLiteral_empty() {
    var code = '[]';
    var parseResult = parseStringWithErrors('''
final x = $code;
''');
    var node = parseResult.findNode.listLiteral(code);
    _assertSource(code, node);
  }

  void test_visitListLiteral_nonEmpty() {
    var code = '[0, 1, 2]';
    var parseResult = parseStringWithErrors('''
final x = $code;
''');
    var node = parseResult.findNode.listLiteral(code);
    _assertSource(code, node);
  }

  void test_visitListLiteral_withConst_withoutTypeArgs() {
    var code = 'const [0]';
    var parseResult = parseStringWithErrors('''
final x = $code;
''');
    var node = parseResult.findNode.listLiteral(code);
    _assertSource(code, node);
  }

  void test_visitListLiteral_withConst_withTypeArgs() {
    var code = 'const <int>[0]';
    var parseResult = parseStringWithErrors('''
final x = $code;
''');
    var node = parseResult.findNode.listLiteral(code);
    _assertSource(code, node);
  }

  void test_visitListLiteral_withoutConst_withoutTypeArgs() {
    var code = '[0]';
    var parseResult = parseStringWithErrors('''
final x = $code;
''');
    var node = parseResult.findNode.listLiteral(code);
    _assertSource(code, node);
  }

  void test_visitListLiteral_withoutConst_withTypeArgs() {
    var code = '<int>[0]';
    var parseResult = parseStringWithErrors('''
final x = $code;
''');
    var node = parseResult.findNode.listLiteral(code);
    _assertSource(code, node);
  }

  void test_visitListPattern_empty() {
    var parseResult = parseStringWithErrors('''
void f(x) {
  switch (x) {
    case []:
      break;
  }
}
''');
    var node = parseResult.findNode.listPattern('[]');
    _assertSource('[]', node);
  }

  void test_visitListPattern_nonEmpty() {
    var parseResult = parseStringWithErrors('''
void f(x) {
  switch (x) {
    case [1, 2]:
      break;
  }
}
''');
    var node = parseResult.findNode.listPattern('1');
    _assertSource('[1, 2]', node);
  }

  void test_visitListPattern_withTypeArguments() {
    var parseResult = parseStringWithErrors('''
void f(x) {
  switch (x) {
    case <int>[]:
      break;
  }
}
''');
    var node = parseResult.findNode.listPattern('[]');
    _assertSource('<int>[]', node);
  }

  void test_visitLogicalAndPattern() {
    var parseResult = parseStringWithErrors('''
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

  void test_visitLogicalOrPattern() {
    var parseResult = parseStringWithErrors('''
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

  void test_visitMapLiteral_const() {
    var code = 'const {}';
    var parseResult = parseStringWithErrors('''
final x = $code;
''');
    var node = parseResult.findNode.setOrMapLiteral(code);
    _assertSource(code, node);
  }

  void test_visitMapLiteral_empty() {
    var code = '{}';
    var parseResult = parseStringWithErrors('''
final x = $code;
''');
    var node = parseResult.findNode.setOrMapLiteral(code);
    _assertSource(code, node);
  }

  void test_visitMapLiteral_nonEmpty() {
    var code = '{0 : a, 1 : b, 2 : c}';
    var parseResult = parseStringWithErrors('''
final x = $code;
''');
    var node = parseResult.findNode.setOrMapLiteral(code);
    _assertSource(code, node);
  }

  void test_visitMapLiteralEntry() {
    var code = '0 : a';
    var parseResult = parseStringWithErrors('''
final x = {$code};
''');
    var node = parseResult.findNode.mapLiteralEntry(code);
    _assertSource(code, node);
  }

  void test_visitMapPattern_empty() {
    var parseResult = parseStringWithErrors('''
void f(x) {
  switch (x) {
    case {}:
      break;
  }
}
''');
    var node = parseResult.findNode.mapPattern('{}');
    _assertSource('{}', node);
  }

  void test_visitMapPattern_notEmpty() {
    var parseResult = parseStringWithErrors('''
void f(x) {
  switch (x) {
    case {1: 2}:
      break;
  }
}
''');
    var node = parseResult.findNode.mapPattern('1');
    _assertSource('{1: 2}', node);
  }

  void test_visitMapPattern_withTypeArguments() {
    var parseResult = parseStringWithErrors('''
void f(x) {
  switch (x) {
    case <int, int>{}:
      break;
  }
}
''');
    var node = parseResult.findNode.mapPattern('{}');
    _assertSource('<int, int>{}', node);
  }

  void test_visitMapPatternEntry() {
    var parseResult = parseStringWithErrors('''
void f(x) {
  switch (x) {
    case {1: 2}:
      break;
  }
}
''');
    var node = parseResult.findNode.mapPatternEntry('1');
    _assertSource('1: 2', node);
  }

  void test_visitMethodDeclaration_augment() {
    var code = 'augment void foo() {}';
    var parseResult = parseStringWithErrors('''
class A {
  $code
}
''');
    var node = parseResult.findNode.singleMethodDeclaration;
    _assertSource(code, node);
  }

  void test_visitMethodDeclaration_external() {
    var code = 'external foo();';
    var parseResult = parseStringWithErrors('''
class A {
  $code
}
''');
    var node = parseResult.findNode.methodDeclaration(code);
    _assertSource(code, node);
  }

  void test_visitMethodDeclaration_external_returnType() {
    var code = 'external int foo();';
    var parseResult = parseStringWithErrors('''
class A {
  $code
}
''');
    var node = parseResult.findNode.methodDeclaration(code);
    _assertSource(code, node);
  }

  void test_visitMethodDeclaration_getter() {
    var code = 'get foo => 0;';
    var parseResult = parseStringWithErrors('''
class A {
  $code
}
''');
    var node = parseResult.findNode.methodDeclaration(code);
    _assertSource(code, node);
  }

  void test_visitMethodDeclaration_getter_returnType() {
    var code = 'int get foo => 0;';
    var parseResult = parseStringWithErrors('''
class A {
  $code
}
''');
    var node = parseResult.findNode.methodDeclaration(code);
    _assertSource(code, node);
  }

  void test_visitMethodDeclaration_minimal() {
    var code = 'foo() {}';
    var parseResult = parseStringWithErrors('''
class A {
  $code
}
''');
    var node = parseResult.findNode.methodDeclaration(code);
    _assertSource(code, node);
  }

  void test_visitMethodDeclaration_multipleParameters() {
    var code = 'void foo(int a, double b) {}';
    var parseResult = parseStringWithErrors('''
class A {
  $code
}
''');
    var node = parseResult.findNode.methodDeclaration(code);
    _assertSource(code, node);
  }

  void test_visitMethodDeclaration_operator() {
    var code = 'operator +(int other) {}';
    var parseResult = parseStringWithErrors('''
class A {
  $code
}
''');
    var node = parseResult.findNode.methodDeclaration(code);
    _assertSource(code, node);
  }

  void test_visitMethodDeclaration_operator_returnType() {
    var code = 'int operator +(int other) => 0;';
    var parseResult = parseStringWithErrors('''
class A {
  $code
}
''');
    var node = parseResult.findNode.methodDeclaration(code);
    _assertSource(code, node);
  }

  void test_visitMethodDeclaration_returnType() {
    var code = 'int foo() => 0;';
    var parseResult = parseStringWithErrors('''
class A {
  $code
}
''');
    var node = parseResult.findNode.methodDeclaration(code);
    _assertSource(code, node);
  }

  void test_visitMethodDeclaration_setter() {
    var code = 'set foo(int _) {}';
    var parseResult = parseStringWithErrors('''
class A {
  $code
}
''');
    var node = parseResult.findNode.methodDeclaration(code);
    _assertSource(code, node);
  }

  void test_visitMethodDeclaration_setter_returnType() {
    var code = 'void set foo(int _) {}';
    var parseResult = parseStringWithErrors('''
class A {
  $code
}
''');
    var node = parseResult.findNode.methodDeclaration(code);
    _assertSource(code, node);
  }

  void test_visitMethodDeclaration_static() {
    var code = 'static foo() {}';
    var parseResult = parseStringWithErrors('''
class A {
  $code
}
''');
    var node = parseResult.findNode.methodDeclaration(code);
    _assertSource(code, node);
  }

  void test_visitMethodDeclaration_static_returnType() {
    var code = 'static void foo() {}';
    var parseResult = parseStringWithErrors('''
class A {
  $code
}
''');
    var node = parseResult.findNode.methodDeclaration(code);
    _assertSource(code, node);
  }

  void test_visitMethodDeclaration_typeParameters() {
    var code = 'void foo<T>() {}';
    var parseResult = parseStringWithErrors('''
class A {
  $code
}
''');
    var node = parseResult.findNode.methodDeclaration(code);
    _assertSource(code, node);
  }

  void test_visitMethodDeclaration_withMetadata() {
    var code = '@deprecated void foo() {}';
    var parseResult = parseStringWithErrors('''
class A {
  $code
}
''');
    var node = parseResult.findNode.methodDeclaration(code);
    _assertSource(code, node);
  }

  void test_visitMethodInvocation_conditional() {
    var code = 'a?.foo()';
    var parseResult = parseStringWithErrors('''
void f() {
  $code;
}
''');
    var node = parseResult.findNode.methodInvocation(code);
    _assertSource(code, node);
  }

  void test_visitMethodInvocation_noTarget() {
    var code = 'foo()';
    var parseResult = parseStringWithErrors('''
void f() {
  $code;
}
''');
    var node = parseResult.findNode.methodInvocation(code);
    _assertSource(code, node);
  }

  void test_visitMethodInvocation_target() {
    var code = 'a.foo()';
    var parseResult = parseStringWithErrors('''
void f() {
  $code;
}
''');
    var node = parseResult.findNode.methodInvocation(code);
    _assertSource(code, node);
  }

  void test_visitMethodInvocation_typeArguments() {
    var code = 'foo<int>()';
    var parseResult = parseStringWithErrors('''
void f() {
  $code;
}
''');
    var node = parseResult.findNode.methodInvocation(code);
    _assertSource(code, node);
  }

  void test_visitMixinDeclaration_augment() {
    var code = 'augment mixin M {}';
    var parseResult = parseStringWithErrors(code);
    var node = parseResult.findNode.singleMixinDeclaration;
    _assertSource(code, node);
  }

  void test_visitMixinDeclaration_augment_base() {
    var code = 'augment base mixin M {}';
    var parseResult = parseStringWithErrors(code);
    var node = parseResult.findNode.singleMixinDeclaration;
    _assertSource(code, node);
  }

  void test_visitMixinDeclaration_base() {
    var parseResult = parseStringWithErrors(r'''
base mixin M {}
''');
    var node = parseResult.findNode.mixinDeclaration('mixin M');
    _assertSource('base mixin M {}', node);
  }

  void test_visitNamedExpression() {
    var code = 'a: 0';
    var parseResult = parseStringWithErrors('''
void f() {
  foo($code);
}
''');
    var node = parseResult.findNode.namedArgument(code);
    _assertSource(code, node);
  }

  void test_visitNamedFormalParameter() {
    var code = 'a = 0';
    var parseResult = parseStringWithErrors('''
void f({$code}) {}
''');
    var node = parseResult.findNode.formalParameter(code);
    _assertSource(code, node);
  }

  void test_visitNamedType_multipleArgs() {
    var code = 'Map<int, String>';
    var parseResult = parseStringWithErrors('''
final x = <$code>[];
''');
    var node = parseResult.findNode.namedType(code);
    _assertSource(code, node);
  }

  void test_visitNamedType_nestedArg() {
    var code = 'List<Set<int>>';
    var parseResult = parseStringWithErrors('''
final x = <$code>[];
''');
    var node = parseResult.findNode.namedType(code);
    _assertSource(code, node);
  }

  void test_visitNamedType_noArgs() {
    var code = 'int';
    var parseResult = parseStringWithErrors('''
final x = <$code>[];
''');
    var node = parseResult.findNode.namedType(code);
    _assertSource(code, node);
  }

  void test_visitNamedType_noArgs_withQuestion() {
    var code = 'int?';
    var parseResult = parseStringWithErrors('''
final x = <$code>[];
''');
    var node = parseResult.findNode.namedType(code);
    _assertSource(code, node);
  }

  void test_visitNamedType_singleArg() {
    var code = 'Set<int>';
    var parseResult = parseStringWithErrors('''
final x = <$code>[];
''');
    var node = parseResult.findNode.namedType(code);
    _assertSource(code, node);
  }

  void test_visitNamedType_singleArg_withQuestion() {
    var code = 'Set<int>?';
    var parseResult = parseStringWithErrors('''
final x = <$code>[];
''');
    var node = parseResult.findNode.namedType(code);
    _assertSource(code, node);
  }

  void test_visitNativeClause() {
    var code = "native 'code'";
    var parseResult = parseStringWithErrors('''
class A $code {}
''');
    var node = parseResult.findNode.nativeClause(code);
    _assertSource(code, node);
  }

  void test_visitNativeFunctionBody() {
    var code = "native 'code';";
    var parseResult = parseStringWithErrors('''
void foo() $code
''');
    var node = parseResult.findNode.nativeFunctionBody(code);
    _assertSource(code, node);
  }

  void test_visitNullAssertPattern() {
    var code = 'y!';
    var parseResult = parseStringWithErrors('''
void f(x) {
  if (x case $code) {}
}
''');
    var node = parseResult.findNode.nullAssertPattern(code);
    _assertSource(code, node);
  }

  void test_visitNullCheckPattern() {
    var code = '_?';
    var parseResult = parseStringWithErrors('''
void f(x) {
  if (x case $code) {}
}
''');
    var node = parseResult.findNode.nullCheckPattern(code);
    _assertSource(code, node);
  }

  void test_visitNullLiteral() {
    var code = 'null';
    var parseResult = parseStringWithErrors('''
final x = $code;
''');
    var node = parseResult.findNode.nullLiteral(code);
    _assertSource(code, node);
  }

  void test_visitObjectPattern() {
    var parseResult = parseStringWithErrors('''
void f(x) {
  switch (x) {
    case C(f: 1):
      break;
  }
}
''');
    var node = parseResult.findNode.objectPattern('C');
    _assertSource('C(f: 1)', node);
  }

  void test_visitParenthesizedExpression() {
    var code = '(a)';
    var parseResult = parseStringWithErrors('''
final x = $code;
''');
    var node = parseResult.findNode.parenthesized(code);
    _assertSource(code, node);
  }

  void test_visitParenthesizedPattern() {
    var parseResult = parseStringWithErrors('''
void f(x) {
  switch (x) {
    case (3):
      break;
  }
}
''');
    var node = parseResult.findNode.parenthesizedPattern('(3');
    _assertSource('(3)', node);
  }

  void test_visitPartDirective() {
    var code = "part 'a.dart';";
    var parseResult = parseStringWithErrors(code);
    var node = parseResult.findNode.part(code);
    _assertSource(code, node);
  }

  void test_visitPartDirective_withMetadata() {
    var code = '@deprecated part "a.dart";';
    var parseResult = parseStringWithErrors(code);
    var node = parseResult.findNode.part(code);
    _assertSource(code, node);
  }

  void test_visitPartOfDirective_name() {
    var parseResult = parseStringWithErrors(
      'part of l;',
      featureSet: FeatureSets.language_3_4,
    );
    var unit = parseResult.findNode.unit;
    var directive = unit.directives[0] as PartOfDirective;
    _assertSource("part of l;", directive);
  }

  void test_visitPartOfDirective_uri() {
    var parseResult = parseStringWithErrors("part of 'a.dart';");
    var unit = parseResult.findNode.unit;
    var directive = unit.directives[0] as PartOfDirective;
    _assertSource("part of 'a.dart';", directive);
  }

  void test_visitPartOfDirective_withMetadata() {
    var code = "@deprecated part of 'a.dart';";
    var parseResult = parseStringWithErrors(code);
    var node = parseResult.findNode.partOf(code);
    _assertSource(code, node);
  }

  void test_visitPatternAssignment() {
    var code = '(a, b) = (3, 4)';
    var parseResult = parseStringWithErrors('''
void f() {
  var a = 0, b = 0;
  $code;
}
''');
    var node = parseResult.findNode.patternAssignment(code);
    _assertSource(code, node);
  }

  void test_visitPatternAssignmentStatement() {
    var code = '(a, b) = (3, 4);';
    var parseResult = parseStringWithErrors('''
void f() {
  var a = 0, b = 0;
  $code
}
''');
    var node = parseResult.findNode.statement(code);
    _assertSource(code, node);
  }

  void test_visitPatternField_named() {
    var parseResult = parseStringWithErrors('''
void f(x) {
  switch (x) {
    case (a: 1):
      break;
  }
}
''');
    var node = parseResult.findNode.patternField('1');
    _assertSource('a: 1', node);
  }

  void test_visitPatternField_positional() {
    var parseResult = parseStringWithErrors('''
void f(x) {
  switch (x) {
    case (1,):
      break;
  }
}
''');
    var node = parseResult.findNode.patternField('1');
    _assertSource('1', node);
  }

  void test_visitPatternFieldName() {
    var parseResult = parseStringWithErrors('''
void f(x) {
  switch (x) {
    case (b: 2):
      break;
  }
}
''');
    var node = parseResult.findNode.patternFieldName('b:');
    _assertSource('b:', node);
  }

  void test_visitPatternVariableDeclaration() {
    var code = 'var (a, b) = (0, 1)';
    var parseResult = parseStringWithErrors('''
void f() {
  $code;
}
''');
    var node = parseResult.findNode.patternVariableDeclaration(code);
    _assertSource(code, node);
  }

  void test_visitPatternVariableDeclarationStatement() {
    var code = 'var (a, b) = (0, 1);';
    var parseResult = parseStringWithErrors('''
void f() {
  $code
}
''');
    var node = parseResult.findNode.patternVariableDeclarationStatement(code);
    _assertSource(code, node);
  }

  void test_visitPositionalFormalParameter() {
    var code = 'a = 0';
    var parseResult = parseStringWithErrors('''
void f([$code]) {}
''');
    var node = parseResult.findNode.formalParameter(code);
    _assertSource(code, node);
  }

  void test_visitPostfixExpression() {
    var code = 'a++';
    var parseResult = parseStringWithErrors('''
int f() {
  $code;
}
''');
    var node = parseResult.findNode.postfix(code);
    _assertSource(code, node);
  }

  void test_visitPostfixPattern() {
    var parseResult = parseStringWithErrors('''
void f(x) {
  switch (x) {
    case true!:
      break;
  }
}
''');
    var node = parseResult.findNode.nullAssertPattern('true');
    _assertSource('true!', node);
  }

  void test_visitPrefixedIdentifier() {
    var code = 'foo.bar';
    var parseResult = parseStringWithErrors('''
int f() {
  $code;
}
''');
    var node = parseResult.findNode.prefixed(code);
    _assertSource(code, node);
  }

  void test_visitPrefixExpression() {
    var code = '-foo';
    var parseResult = parseStringWithErrors('''
int f() {
  $code;
}
''');
    var node = parseResult.findNode.prefix(code);
    _assertSource(code, node);
  }

  void test_visitPrefixExpression_precedence() {
    var parseResult = parseStringWithErrors(r'''
var v = !(a == b);
''');
    var node = parseResult.findNode.prefix('!');
    _assertSource('!(a == b)', node);
  }

  void test_visitPrimaryConstructorBody_block() {
    var code = 'this {foo();}';
    var parseResult = parseStringWithErrors('''
class A() {
  $code
}
''');
    var node = parseResult.findNode.singlePrimaryConstructorBody;
    _assertSource(code, node);
  }

  void test_visitPrimaryConstructorBody_initializers() {
    var code = 'this : x = 0, y = 1;';
    var parseResult = parseStringWithErrors('''
class A() {
  final int x;
  final int y;
  $code
}
''');
    var node = parseResult.findNode.singlePrimaryConstructorBody;
    _assertSource(code, node);
  }

  void test_visitPrimaryConstructorBody_metadata() {
    var code = '@deprecated this;';
    var parseResult = parseStringWithErrors('''
class A() {
  $code
}
''');
    var node = parseResult.findNode.singlePrimaryConstructorBody;
    _assertSource(code, node);
  }

  void test_visitPrimaryConstructorBody_simple() {
    var code = 'this;';
    var parseResult = parseStringWithErrors('''
class A() {
  $code
}
''');
    var node = parseResult.findNode.singlePrimaryConstructorBody;
    _assertSource(code, node);
  }

  void test_visitPropertyAccess() {
    var code = '(foo).bar';
    var parseResult = parseStringWithErrors('''
final x = $code;
''');
    var node = parseResult.findNode.propertyAccess(code);
    _assertSource(code, node);
  }

  void test_visitPropertyAccess_conditional() {
    var code = 'foo?.bar';
    var parseResult = parseStringWithErrors('''
final x = $code;
''');
    var node = parseResult.findNode.propertyAccess(code);
    _assertSource(code, node);
  }

  void test_visitRecordLiteral_mixed() {
    var code = '(0, true, a: 0, b: true)';
    var parseResult = parseStringWithErrors('''
final x = $code;
''');
    var node = parseResult.findNode.recordLiteral(code);
    _assertSource(code, node);
  }

  void test_visitRecordLiteral_named() {
    var code = '(a: 0, b: true)';
    var parseResult = parseStringWithErrors('''
final x = $code;
''');
    var node = parseResult.findNode.recordLiteral(code);
    _assertSource(code, node);
  }

  void test_visitRecordLiteral_positional() {
    var code = '(0, true)';
    var parseResult = parseStringWithErrors('''
final x = $code;
''');
    var node = parseResult.findNode.recordLiteral(code);
    _assertSource(code, node);
  }

  void test_visitRecordPattern() {
    var parseResult = parseStringWithErrors('''
void f(x) {
  switch (x) {
    case (1, 2):
      break;
  }
}
''');
    var node = parseResult.findNode.recordPattern('(1');
    _assertSource('(1, 2)', node);
  }

  void test_visitRecordTypeAnnotation_mixed() {
    var code = '(int, bool, {int a, bool b})';
    var parseResult = parseStringWithErrors('''
$code f() {}
''');
    var node = parseResult.findNode.recordTypeAnnotation(code);
    _assertSource(code, node);
  }

  void test_visitRecordTypeAnnotation_named() {
    var code = '({int a, bool b})';
    var parseResult = parseStringWithErrors('''
$code f() {}
''');
    var node = parseResult.findNode.recordTypeAnnotation(code);
    _assertSource(code, node);
  }

  void test_visitRecordTypeAnnotation_positional() {
    var code = '(int, bool)';
    var parseResult = parseStringWithErrors('''
$code f() {}
''');
    var node = parseResult.findNode.recordTypeAnnotation(code);
    _assertSource(code, node);
  }

  void test_visitRecordTypeAnnotation_positional_nullable() {
    var code = '(int, bool)?';
    var parseResult = parseStringWithErrors('''
$code f() {}
''');
    var node = parseResult.findNode.recordTypeAnnotation(code);
    _assertSource(code, node);
  }

  void test_visitRedirectingConstructorInvocation_named() {
    var code = 'this.named()';
    var parseResult = parseStringWithErrors('''
class A {
  A() : $code;
}
''');
    var node = parseResult.findNode.redirectingConstructorInvocation(code);
    _assertSource(code, node);
  }

  void test_visitRedirectingConstructorInvocation_unnamed() {
    var code = 'this()';
    var parseResult = parseStringWithErrors('''
class A {
  A.named() : $code;
}
''');
    var node = parseResult.findNode.redirectingConstructorInvocation(code);
    _assertSource(code, node);
  }

  void test_visitRelationalPattern() {
    var parseResult = parseStringWithErrors('''
void f(x) {
  switch (x) {
    case > 3:
      break;
  }
}
''');
    var node = parseResult.findNode.relationalPattern('>');
    _assertSource('> 3', node);
  }

  void test_visitRestPatternElement() {
    var code = '...rest';
    var parseResult = parseStringWithErrors('''
void f(x) {
  if (x case [0, $code]) {}
}
''');
    var node = parseResult.findNode.restPatternElement(code);
    _assertSource(code, node);
  }

  void test_visitRethrowExpression() {
    var code = 'rethrow';
    var parseResult = parseStringWithErrors('''
void f() {
  try {} on int {
    $code;
  }
}
''');
    var node = parseResult.findNode.rethrow_(code);
    _assertSource(code, node);
  }

  void test_visitReturnStatement_expression() {
    var code = 'return 0;';
    var parseResult = parseStringWithErrors('''
int f() {
  $code
}
''');
    var node = parseResult.findNode.returnStatement(code);
    _assertSource(code, node);
  }

  void test_visitReturnStatement_noExpression() {
    var code = 'return;';
    var parseResult = parseStringWithErrors('''
int f() {
  $code
}
''');
    var node = parseResult.findNode.returnStatement(code);
    _assertSource(code, node);
  }

  void test_visitSetOrMapLiteral_map_complex() {
    var code =
        "<String, String>{'a' : 'b', for (c in d) 'e' : 'f', if (g) 'h' : 'i', ...{'j' : 'k'}}";
    var parseResult = parseStringWithErrors('''
final v = $code;
''');
    var node = parseResult.findNode.setOrMapLiteral(code);
    _assertSource(code, node);
  }

  void test_visitSetOrMapLiteral_map_withConst_withoutTypeArgs() {
    var code = 'const {0 : a}';
    var parseResult = parseStringWithErrors('''
final x = $code;
''');
    var node = parseResult.findNode.setOrMapLiteral(code);
    _assertSource(code, node);
  }

  void test_visitSetOrMapLiteral_map_withConst_withTypeArgs() {
    var code = 'const <int, String>{0 : a}';
    var parseResult = parseStringWithErrors('''
final x = $code;
''');
    var node = parseResult.findNode.setOrMapLiteral(code);
    _assertSource(code, node);
  }

  void test_visitSetOrMapLiteral_map_withoutConst_withoutTypeArgs() {
    var code = '{0 : a}';
    var parseResult = parseStringWithErrors('''
final x = $code;
''');
    var node = parseResult.findNode.setOrMapLiteral(code);
    _assertSource(code, node);
  }

  void test_visitSetOrMapLiteral_map_withoutConst_withTypeArgs() {
    var code = '<int, String>{0 : a}';
    var parseResult = parseStringWithErrors('''
final x = $code;
''');
    var node = parseResult.findNode.setOrMapLiteral(code);
    _assertSource(code, node);
  }

  void test_visitSetOrMapLiteral_set_complex() {
    var code = '<int>{0, for (e in l) 0, if (b) 1, ...[0]}';
    var parseResult = parseStringWithErrors('''
final v = $code;
''');
    var node = parseResult.findNode.setOrMapLiteral(code);
    _assertSource(code, node);
  }

  void test_visitSetOrMapLiteral_set_withConst_withoutTypeArgs() {
    var code = 'const {0}';
    var parseResult = parseStringWithErrors('''
final x = $code;
''');
    var node = parseResult.findNode.setOrMapLiteral(code);
    _assertSource(code, node);
  }

  void test_visitSetOrMapLiteral_set_withConst_withTypeArgs() {
    var code = 'const <int>{0}';
    var parseResult = parseStringWithErrors('''
final x = $code;
''');
    var node = parseResult.findNode.setOrMapLiteral(code);
    _assertSource(code, node);
  }

  void test_visitSetOrMapLiteral_set_withoutConst_withoutTypeArgs() {
    var code = '{0}';
    var parseResult = parseStringWithErrors('''
final x = $code;
''');
    var node = parseResult.findNode.setOrMapLiteral(code);
    _assertSource(code, node);
  }

  void test_visitSetOrMapLiteral_set_withoutConst_withTypeArgs() {
    var code = '<int>{0}';
    var parseResult = parseStringWithErrors('''
final x = $code;
''');
    var node = parseResult.findNode.setOrMapLiteral(code);
    _assertSource(code, node);
  }

  void test_visitSimpleFormalParameter_annotation() {
    var code = '@deprecated int x';
    var parseResult = parseStringWithErrors('''
void f($code) {}
''');
    var node = parseResult.findNode.regularFormalParameter(code);
    _assertSource(code, node);
  }

  void test_visitSimpleFormalParameter_keyword() {
    var code = 'var a';
    var parseResult = parseStringWithErrors('''
// @dart = 3.10
void f($code) {}
''');
    var node = parseResult.findNode.regularFormalParameter(code);
    _assertSource(code, node);
  }

  void test_visitSimpleFormalParameter_keyword_type() {
    var code = 'final int a';
    var parseResult = parseStringWithErrors('''
// @dart = 3.10
void f($code) {}
''');
    var node = parseResult.findNode.regularFormalParameter(code);
    _assertSource(code, node);
  }

  void test_visitSimpleFormalParameter_type() {
    var code = 'int a';
    var parseResult = parseStringWithErrors('''
void f($code) {}
''');
    var node = parseResult.findNode.regularFormalParameter(code);
    _assertSource(code, node);
  }

  void test_visitSimpleFormalParameter_type_covariant() {
    var code = 'covariant int a';
    var parseResult = parseStringWithErrors('''
class A {
  void foo($code) {}
}
''');
    var node = parseResult.findNode.regularFormalParameter(code);
    _assertSource(code, node);
  }

  void test_visitSimpleIdentifier() {
    var code = 'foo';
    var parseResult = parseStringWithErrors('''
var x = $code;
''');
    var node = parseResult.findNode.simple(code);
    _assertSource(code, node);
  }

  void test_visitSimpleStringLiteral() {
    var code = "'str'";
    var parseResult = parseStringWithErrors('''
final x = $code;
''');
    var node = parseResult.findNode.simpleStringLiteral(code);
    _assertSource(code, node);
  }

  void test_visitSpreadElement_nonNullable() {
    var code = '...[0]';
    var parseResult = parseStringWithErrors('''
final x = [$code];
''');
    var node = parseResult.findNode.spreadElement(code);
    _assertSource(code, node);
  }

  void test_visitSpreadElement_nullable() {
    var code = '...?[0]';
    var parseResult = parseStringWithErrors('''
final x = [$code];
''');
    var node = parseResult.findNode.spreadElement(code);
    _assertSource(code, node);
  }

  void test_visitStringInterpolation() {
    var code = r"'a${bb}ccc'";
    var parseResult = parseStringWithErrors('''
final x = $code;
''');
    var node = parseResult.findNode.stringInterpolation(code);
    _assertSource(code, node);
  }

  void test_visitSuperConstructorInvocation() {
    var code = 'super(0)';
    var parseResult = parseStringWithErrors('''
class A extends B {
  A() : $code;
}
''');
    var node = parseResult.findNode.superConstructorInvocation(code);
    _assertSource(code, node);
  }

  void test_visitSuperConstructorInvocation_named() {
    var code = 'super.named(0)';
    var parseResult = parseStringWithErrors('''
class A extends B {
  A() : $code;
}
''');
    var node = parseResult.findNode.superConstructorInvocation(code);
    _assertSource(code, node);
  }

  void test_visitSuperExpression() {
    var parseResult = parseStringWithErrors('''
class A {
  void foo() {
    super.foo();
  }
}
''');
    var node = parseResult.findNode.super_('super.foo');
    _assertSource('super', node);
  }

  void test_visitSuperFormalParameter_annotation() {
    var code = '@deprecated super.foo';
    var parseResult = parseStringWithErrors('''
class A {
  A($code);
}
''');
    var node = parseResult.findNode.superFormalParameter(code);
    _assertSource(code, node);
  }

  void test_visitSuperFormalParameter_functionTyped() {
    var code = 'int super.a(b)';
    var parseResult = parseStringWithErrors('''
class A {
  A($code);
}
''');
    var node = parseResult.findNode.superFormalParameter(code);
    _assertSource(code, node);
  }

  void test_visitSuperFormalParameter_functionTyped_typeParameters() {
    var code = 'int super.a<E, F>(b)';
    var parseResult = parseStringWithErrors('''
class A {
  A($code);
}
''');
    var node = parseResult.findNode.superFormalParameter(code);
    _assertSource(code, node);
  }

  void test_visitSuperFormalParameter_keyword() {
    var code = 'final super.foo';
    var parseResult = parseStringWithErrors('''
// @dart = 3.10
class A {
  A($code);
}
''');
    var node = parseResult.findNode.superFormalParameter(code);
    _assertSource(code, node);
  }

  void test_visitSuperFormalParameter_keywordAndType() {
    var code = 'final int super.a';
    var parseResult = parseStringWithErrors('''
// @dart = 3.10
class A {
  A($code);
}
''');
    var node = parseResult.findNode.superFormalParameter(code);
    _assertSource(code, node);
  }

  void test_visitSuperFormalParameter_type() {
    var code = 'int super.a';
    var parseResult = parseStringWithErrors('''
class A {
  A($code);
}
''');
    var node = parseResult.findNode.superFormalParameter(code);
    _assertSource(code, node);
  }

  void test_visitSuperFormalParameter_type_covariant() {
    var code = 'covariant int super.a';
    var parseResult = parseStringWithErrors('''
class A {
  A($code);
}
''');
    var node = parseResult.findNode.superFormalParameter(code);
    _assertSource(code, node);
  }

  void test_visitSwitchCase_multipleLabels() {
    var code = 'l1: l2: case a: {}';
    var parseResult = parseStringWithErrors('''
// @dart = 2.19
void f() {
  switch (x) {
    $code
  }
}
''');
    var node = parseResult.findNode.switchCase(code);
    _assertSource(code, node);
  }

  void test_visitSwitchCase_multipleStatements() {
    var code = 'case a: foo(); bar();';
    var parseResult = parseStringWithErrors('''
// @dart = 2.19
void f() {
  switch (x) {
    $code
  }
}
''');
    var node = parseResult.findNode.switchCase(code);
    _assertSource(code, node);
  }

  void test_visitSwitchCase_noLabels() {
    var code = 'case a: {}';
    var parseResult = parseStringWithErrors('''
// @dart = 2.19
void f() {
  switch (x) {
    $code
  }
}
''');
    var node = parseResult.findNode.switchCase(code);
    _assertSource(code, node);
  }

  void test_visitSwitchCase_singleLabel() {
    var code = 'l1: case a: {}';
    var parseResult = parseStringWithErrors('''
// @dart = 2.19
void f() {
  switch (x) {
    $code
  }
}
''');
    var node = parseResult.findNode.switchCase(code);
    _assertSource(code, node);
  }

  void test_visitSwitchDefault_multipleLabels() {
    var code = 'l1: l2: default: {}';
    var parseResult = parseStringWithErrors('''
void f() {
  switch (x) {
    $code
  }
}
''');
    var node = parseResult.findNode.switchDefault(code);
    _assertSource(code, node);
  }

  void test_visitSwitchDefault_multipleStatements() {
    var code = 'default: foo(); bar();';
    var parseResult = parseStringWithErrors('''
void f() {
  switch (x) {
    $code
  }
}
''');
    var node = parseResult.findNode.switchDefault(code);
    _assertSource(code, node);
  }

  void test_visitSwitchDefault_noLabels() {
    var code = 'default: {}';
    var parseResult = parseStringWithErrors('''
void f() {
  switch (x) {
    $code
  }
}
''');
    var node = parseResult.findNode.switchDefault(code);
    _assertSource(code, node);
  }

  void test_visitSwitchDefault_singleLabel() {
    var code = 'l1: default: {}';
    var parseResult = parseStringWithErrors('''
void f() {
  switch (x) {
    $code
  }
}
''');
    var node = parseResult.findNode.switchDefault(code);
    _assertSource(code, node);
  }

  void test_visitSwitchExpression() {
    var code = 'switch (x) {0 => 1, _ => 2}';
    var parseResult = parseStringWithErrors('''
var result = $code;
''');
    var node = parseResult.findNode.switchExpression('switch');
    _assertSource(code, node);
  }

  void test_visitSwitchExpressionCase() {
    var code = '0 => 1';
    var parseResult = parseStringWithErrors('''
var result = switch (x) {
  $code,
  _ => 2,
};
''');
    var node = parseResult.findNode.switchExpressionCase(code);
    _assertSource(code, node);
  }

  void test_visitSwitchPatternCase_multipleLabels() {
    var code = 'l1: l2: case a: {}';
    var parseResult = parseStringWithErrors('''
void f() {
  switch (x) {
    $code
  }
}
''');
    var node = parseResult.findNode.switchPatternCase(code);
    _assertSource(code, node);
  }

  void test_visitSwitchPatternCase_multipleStatements() {
    var code = 'case a: foo(); bar();';
    var parseResult = parseStringWithErrors('''
void f() {
  switch (x) {
    $code
  }
}
''');
    var node = parseResult.findNode.switchPatternCase(code);
    _assertSource(code, node);
  }

  void test_visitSwitchPatternCase_noLabels() {
    var code = 'case a: {}';
    var parseResult = parseStringWithErrors('''
void f() {
  switch (x) {
    $code
  }
}
''');
    var node = parseResult.findNode.switchPatternCase(code);
    _assertSource(code, node);
  }

  void test_visitSwitchPatternCase_singleLabel() {
    var code = 'l1: case a: {}';
    var parseResult = parseStringWithErrors('''
void f() {
  switch (x) {
    $code
  }
}
''');
    var node = parseResult.findNode.switchPatternCase(code);
    _assertSource(code, node);
  }

  void test_visitSwitchStatement() {
    var code = 'switch (x) {case 0: foo(); default: bar();}';
    var parseResult = parseStringWithErrors('''
void f() {
  $code
}
''');
    var node = parseResult.findNode.switchStatement(code);
    _assertSource(code, node);
  }

  void test_visitSymbolLiteral_multiple() {
    var code = '#a.b.c';
    var parseResult = parseStringWithErrors('''
final x = $code;
''');
    var node = parseResult.findNode.symbolLiteral(code);
    _assertSource(code, node);
  }

  void test_visitSymbolLiteral_single() {
    var code = '#a';
    var parseResult = parseStringWithErrors('''
final x = $code;
''');
    var node = parseResult.findNode.symbolLiteral(code);
    _assertSource(code, node);
  }

  void test_visitThisExpression() {
    var code = 'this';
    var parseResult = parseStringWithErrors('''
class A {
  void foo() {
    $code;
  }
}
''');
    var node = parseResult.findNode.this_(code);
    _assertSource(code, node);
  }

  void test_visitThrowStatement() {
    var code = 'throw 0';
    var parseResult = parseStringWithErrors('''
void f() {
  $code;
}
''');
    var node = parseResult.findNode.throw_(code);
    _assertSource(code, node);
  }

  void test_visitTopLevelVariableDeclaration_abstract() {
    var code = 'abstract var a;';
    var parseResult = parseStringWithErrors('''
$code
''');
    var node = parseResult.findNode.topLevelVariableDeclaration(code);
    _assertSource(code, node);
  }

  void test_visitTopLevelVariableDeclaration_augment() {
    var code = 'augment var a = 0;';
    var parseResult = parseStringWithErrors('''
$code
''');
    var node = parseResult.findNode.topLevelVariableDeclaration(code);
    _assertSource(code, node);
  }

  void test_visitTopLevelVariableDeclaration_external() {
    var code = 'external var a;';
    var parseResult = parseStringWithErrors('''
$code
''');
    var node = parseResult.findNode.topLevelVariableDeclaration(code);
    _assertSource(code, node);
  }

  void test_visitTopLevelVariableDeclaration_external_abstract() {
    var code = 'external abstract var a;';
    var parseResult = parseStringWithErrors('''
$code
''');
    var node = parseResult.findNode.topLevelVariableDeclaration(code);
    _assertSource(code, node);
  }

  void test_visitTopLevelVariableDeclaration_multiple() {
    var code = 'var a = 0, b = 1;';
    var parseResult = parseStringWithErrors('''
$code
''');
    var node = parseResult.findNode.topLevelVariableDeclaration(code);
    _assertSource(code, node);
  }

  void test_visitTopLevelVariableDeclaration_single() {
    var code = 'var a;';
    var parseResult = parseStringWithErrors('''
$code
''');
    var node = parseResult.findNode.topLevelVariableDeclaration(code);
    _assertSource(code, node);
  }

  void test_visitTopLevelVariableDeclaration_withMetadata() {
    var code = '@deprecated var a;';
    var parseResult = parseStringWithErrors('''
$code
''');
    var node = parseResult.findNode.topLevelVariableDeclaration(code);
    _assertSource(code, node);
  }

  void test_visitTryStatement_catch() {
    var code = 'try {} on E {}';
    var parseResult = parseStringWithErrors('''
void f() {
  $code
}
''');
    var node = parseResult.findNode.tryStatement(code);
    _assertSource(code, node);
  }

  void test_visitTryStatement_catches() {
    var code = 'try {} on E {} on F {}';
    var parseResult = parseStringWithErrors('''
void f() {
  $code
}
''');
    var node = parseResult.findNode.tryStatement(code);
    _assertSource(code, node);
  }

  void test_visitTryStatement_catchFinally() {
    var code = 'try {} on E {} finally {}';
    var parseResult = parseStringWithErrors('''
void f() {
  $code
}
''');
    var node = parseResult.findNode.tryStatement(code);
    _assertSource(code, node);
  }

  void test_visitTryStatement_finally() {
    var code = 'try {} finally {}';
    var parseResult = parseStringWithErrors('''
void f() {
  $code
}
''');
    var node = parseResult.findNode.tryStatement(code);
    _assertSource(code, node);
  }

  void test_visitTypeArgumentList_multiple() {
    var code = '<int, String>';
    var parseResult = parseStringWithErrors('''
final x = $code[];
''');
    var node = parseResult.findNode.typeArgumentList(code);
    _assertSource(code, node);
  }

  void test_visitTypeArgumentList_single() {
    var code = '<int>';
    var parseResult = parseStringWithErrors('''
final x = $code[];
''');
    var node = parseResult.findNode.typeArgumentList(code);
    _assertSource(code, node);
  }

  void test_visitTypeParameter_variance_contravariant() {
    var code = 'in T';
    var parseResult = parseStringWithErrors('''
class A<$code> {}
''');
    var node = parseResult.findNode.typeParameter(code);
    _assertSource(code, node);
  }

  void test_visitTypeParameter_variance_covariant() {
    var code = 'out T';
    var parseResult = parseStringWithErrors('''
class A<$code> {}
''');
    var node = parseResult.findNode.typeParameter(code);
    _assertSource(code, node);
  }

  void test_visitTypeParameter_variance_invariant() {
    var code = 'inout T';
    var parseResult = parseStringWithErrors('''
class A<$code> {}
''');
    var node = parseResult.findNode.typeParameter(code);
    _assertSource(code, node);
  }

  void test_visitTypeParameter_withExtends() {
    var code = 'T extends num';
    var parseResult = parseStringWithErrors('''
class A<$code> {}
''');
    var node = parseResult.findNode.typeParameter(code);
    _assertSource(code, node);
  }

  void test_visitTypeParameter_withMetadata() {
    var code = '@deprecated T';
    var parseResult = parseStringWithErrors('''
class A<$code> {}
''');
    var node = parseResult.findNode.typeParameter(code);
    _assertSource(code, node);
  }

  void test_visitTypeParameter_withoutExtends() {
    var code = 'T';
    var parseResult = parseStringWithErrors('''
class A<$code> {}
''');
    var node = parseResult.findNode.typeParameter(code);
    _assertSource(code, node);
  }

  void test_visitTypeParameterList_multiple() {
    var code = '<T, U>';
    var parseResult = parseStringWithErrors('''
class A$code {}
''');
    // Find from the offset after the `<` because NodeLocator usually picks
    // the name for the offset between the name and `<`.
    var node = parseResult.findNode.typeParameterList('T, U>');
    _assertSource(code, node);
  }

  void test_visitTypeParameterList_single() {
    var code = '<T>';
    var parseResult = parseStringWithErrors('''
class A$code {}
''');
    // Find from the offset after the `<` because NodeLocator usually picks
    // the name for the offset between the name and `<`.
    var node = parseResult.findNode.typeParameterList('T>');
    _assertSource(code, node);
  }

  void test_visitVariableDeclaration_initialized() {
    var code = 'foo = bar';
    var parseResult = parseStringWithErrors('''
var $code;
''');
    var node = parseResult.findNode.variableDeclaration(code);
    _assertSource(code, node);
  }

  void test_visitVariableDeclaration_uninitialized() {
    var code = 'foo';
    var parseResult = parseStringWithErrors('''
var $code;
''');
    var node = parseResult.findNode.variableDeclaration(code);
    _assertSource(code, node);
  }

  void test_visitVariableDeclarationList_const_type() {
    var code = 'const int a = 0, b = 0';
    var parseResult = parseStringWithErrors('''
$code;
''');
    var node = parseResult.findNode.variableDeclarationList(code);
    _assertSource(code, node);
  }

  void test_visitVariableDeclarationList_final_noType() {
    var code = 'final a = 0, b = 0';
    var parseResult = parseStringWithErrors('''
$code;
''');
    var node = parseResult.findNode.variableDeclarationList(code);
    _assertSource(code, node);
  }

  void test_visitVariableDeclarationList_type() {
    var code = 'int a, b';
    var parseResult = parseStringWithErrors('''
$code;
''');
    var node = parseResult.findNode.variableDeclarationList(code);
    _assertSource(code, node);
  }

  void test_visitVariableDeclarationList_var() {
    var code = 'var a, b';
    var parseResult = parseStringWithErrors('''
$code;
''');
    var node = parseResult.findNode.variableDeclarationList(code);
    _assertSource(code, node);
  }

  void test_visitVariableDeclarationStatement() {
    var code = 'int a';
    var parseResult = parseStringWithErrors('''
$code;
''');
    var node = parseResult.findNode.variableDeclarationList(code);
    _assertSource(code, node);
  }

  void test_visitWhileStatement() {
    var code = 'while (true) {}';
    var parseResult = parseStringWithErrors('''
void f() {
  $code
}
''');
    var node = parseResult.findNode.whileStatement(code);
    _assertSource(code, node);
  }

  void test_visitWildcardPattern() {
    var parseResult = parseStringWithErrors('''
void f(x) {
  switch (x) {
    case int? _:
      break;
  }
}
''');
    var node = parseResult.findNode.wildcardPattern('int?');
    _assertSource('int? _', node);
  }

  void test_visitWithClause_multiple() {
    var code = 'with A, B, C';
    var parseResult = parseStringWithErrors('''
class X $code {}
''');
    var node = parseResult.findNode.withClause(code);
    _assertSource(code, node);
  }

  void test_visitWithClause_single() {
    var code = 'with M';
    var parseResult = parseStringWithErrors('''
class X $code {}
''');
    var node = parseResult.findNode.withClause(code);
    _assertSource(code, node);
  }

  void test_visitYieldStatement() {
    var code = 'yield e;';
    var parseResult = parseStringWithErrors('''
void f() sync* {
  $code
}
''');
    var node = parseResult.findNode.yieldStatement(code);
    _assertSource(code, node);
  }

  void test_visitYieldStatement_each() {
    var code = 'yield* e;';
    var parseResult = parseStringWithErrors('''
void f() sync* {
  $code
}
''');
    var node = parseResult.findNode.yieldStatement(code);
    _assertSource(code, node);
  }

  /// Assert that a [ToSourceVisitor] will produce the [expectedSource] when
  /// visiting the given [node].
  void _assertSource(String expectedSource, AstNode node) {
    StringBuffer buffer = StringBuffer();
    node.accept(ToSourceVisitor(buffer));
    expect(buffer.toString(), expectedSource);
  }
}
