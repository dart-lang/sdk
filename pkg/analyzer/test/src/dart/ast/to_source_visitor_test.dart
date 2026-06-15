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
    var parseResult = parseTestCodeWithDiagnostics(code);
    var node = parseResult.findNode.singleClassDeclaration;
    _assertSource(code, node);
  }

  test_class_primaryConstructor_const_named() {
    var code = 'class const A<T>.named() {}';
    var parseResult = parseTestCodeWithDiagnostics(code);
    var node = parseResult.findNode.singleClassDeclaration;
    _assertSource(code, node);
  }

  test_class_primaryConstructor_const_unnamed() {
    var code = 'class A() {}';
    var parseResult = parseTestCodeWithDiagnostics(code);
    var node = parseResult.findNode.singleClassDeclaration;
    _assertSource(code, node);
  }

  test_class_primaryConstructor_declaringFormalParameter_optionalNamed() {
    var code = 'class A({final int a = 0}) {}';
    var parseResult = parseTestCodeWithDiagnostics(code);
    var node = parseResult.findNode.singleClassDeclaration;
    _assertSource(code, node);
  }

  test_class_primaryConstructor_declaringFormalParameter_requiredPositional() {
    var code = 'class A(final int a) {}';
    var parseResult = parseTestCodeWithDiagnostics(code);
    var node = parseResult.findNode.singleClassDeclaration;
    _assertSource(code, node);
  }

  test_class_primaryConstructor_fieldFormalParameter() {
    var code = 'class A(int this.a) {}';
    var parseResult = parseTestCodeWithDiagnostics(code);
    var node = parseResult.findNode.singleClassDeclaration;
    _assertSource(code, node);
  }

  test_class_primaryConstructor_notConst_named() {
    var code = 'class A<T>.named() {}';
    var parseResult = parseTestCodeWithDiagnostics(code);
    var node = parseResult.findNode.singleClassDeclaration;
    _assertSource(code, node);
  }

  test_class_primaryConstructor_superFormalParameter() {
    var code = 'class A(int super.a) {}';
    var parseResult = parseTestCodeWithDiagnostics(code);
    var node = parseResult.findNode.singleClassDeclaration;
    _assertSource(code, node);
  }

  test_enum_emptyBody() {
    var code = 'enum E;';
    var parseResult = parseTestCodeWithDiagnostics(code);
    var node = parseResult.findNode.singleEnumDeclaration;
    _assertSource(code, node);
  }

  test_enum_primaryConstructor_named() {
    var code = 'enum const E<T>.named(final int a) {}';
    var parseResult = parseTestCodeWithDiagnostics(code);
    var node = parseResult.findNode.singleEnumDeclaration;
    _assertSource(code, node);
  }

  test_enum_primaryConstructor_unnamed() {
    var code = 'enum E<T>(final int a) {}';
    var parseResult = parseTestCodeWithDiagnostics(code);
    var node = parseResult.findNode.singleEnumDeclaration;
    _assertSource(code, node);
  }

  test_extension_emptyBody() {
    var code = 'extension E on C;';
    var parseResult = parseTestCodeWithDiagnostics(code);
    var node = parseResult.findNode.singleExtensionDeclaration;
    _assertSource(code, node);
  }

  test_extensionType_emptyBody() {
    var code = 'extension type A(int it);';
    var parseResult = parseTestCodeWithDiagnostics(code);
    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    _assertSource(code, node);
  }

  test_extensionType_primaryConstructor_named() {
    var code = 'extension type const A<T>.named(int it) {}';
    var parseResult = parseTestCodeWithDiagnostics(code);
    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    _assertSource(code, node);
  }

  test_extensionType_primaryConstructor_unnamed() {
    var code = 'extension type A<T>(int it) {}';
    var parseResult = parseTestCodeWithDiagnostics(code);
    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    _assertSource(code, node);
  }

  test_mixin_emptyBody() {
    var code = 'mixin M;';
    var parseResult = parseTestCodeWithDiagnostics(code);
    var node = parseResult.findNode.singleMixinDeclaration;
    _assertSource(code, node);
  }

  void test_visitAdjacentStrings() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var v = 'a' 'b';
''');
    var node = parseResult.findNode.singleAdjacentStrings;
    _assertSource("'a' 'b'", node);
  }

  void test_visitAnnotation_constant() {
    var code = '@A';
    var parseResult = parseTestCodeWithDiagnostics('''
$code
void f() {}
''');
    var node = parseResult.findNode.singleAnnotation;
    _assertSource(code, node);
  }

  void test_visitAnnotation_constructor() {
    var code = '@A.foo()';
    var parseResult = parseTestCodeWithDiagnostics('''
$code
void f() {}
''');
    var node = parseResult.findNode.singleAnnotation;
    _assertSource(code, node);
  }

  void test_visitAnnotation_constructor_generic() {
    var code = '@A<int>.foo()';
    var parseResult = parseTestCodeWithDiagnostics('''
$code
void f() {}
''');
    var node = parseResult.findNode.singleAnnotation;
    _assertSource(code, node);
  }

  void test_visitArgumentList() {
    var code = '(0, 1)';
    var parseResult = parseTestCodeWithDiagnostics('''
final x = f$code;
''');
    var node = parseResult.findNode.singleArgumentList;
    _assertSource(code, node);
  }

  void test_visitAsExpression() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var v = a as T;
''');
    var node = parseResult.findNode.singleAsExpression;
    _assertSource('a as T', node);
  }

  void test_visitAssertStatement() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  assert(a);
}
''');
    var node = parseResult.findNode.singleAssertStatement;
    _assertSource('assert (a);', node);
  }

  void test_visitAssertStatement_withMessage() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  assert(a, b);
}
''');
    var node = parseResult.findNode.singleAssertStatement;
    _assertSource('assert (a, b);', node);
  }

  void test_visitAssignedVariablePattern() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f(int foo) {
  (foo) = 0;
}
''');
    var node = parseResult.findNode.singleAssignedVariablePattern;
    _assertSource('foo', node);
  }

  void test_visitAssignmentExpression() {
    var code = 'a = b';
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  $code;
}
''');
    var node = parseResult.findNode.singleAssignmentExpression;
    _assertSource(code, node);
  }

  void test_visitAwaitExpression() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() async => await e;
''');
    var node = parseResult.findNode.singleAwaitExpression;
    _assertSource('await e', node);
  }

  void test_visitBinaryExpression() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var v = a + b;
''');
    var node = parseResult.findNode.singleBinaryExpression;
    _assertSource('a + b', node);
  }

  void test_visitBinaryExpression_precedence() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var v = a * (b + c);
''');
    var node = parseResult.findNode.binary('a *');
    _assertSource('a * (b + c)', node);
  }

  void test_visitBlock_empty() {
    var code = '{}';
    var parseResult = parseTestCodeWithDiagnostics('''
void f() $code
''');
    var node = parseResult.findNode.singleBlock;
    _assertSource(code, node);
  }

  void test_visitBlock_nonEmpty() {
    var code = '{foo(); bar();}';
    var parseResult = parseTestCodeWithDiagnostics('''
void f() $code
''');
    var node = parseResult.findNode.singleBlock;
    _assertSource(code, node);
  }

  void test_visitBlockFunctionBody_async() {
    var code = 'async {}';
    var parseResult = parseTestCodeWithDiagnostics('''
void f() $code
''');
    var node = parseResult.findNode.singleBlockFunctionBody;
    _assertSource(code, node);
  }

  void test_visitBlockFunctionBody_async_star() {
    var code = 'async* {}';
    var parseResult = parseTestCodeWithDiagnostics('''
void f() $code
''');
    var node = parseResult.findNode.singleBlockFunctionBody;
    _assertSource(code, node);
  }

  void test_visitBlockFunctionBody_simple() {
    var code = '{}';
    var parseResult = parseTestCodeWithDiagnostics('''
void f() $code
''');
    var node = parseResult.findNode.singleBlockFunctionBody;
    _assertSource(code, node);
  }

  void test_visitBlockFunctionBody_sync_star() {
    var code = 'sync* {}';
    var parseResult = parseTestCodeWithDiagnostics('''
void f() $code
''');
    var node = parseResult.findNode.singleBlockFunctionBody;
    _assertSource(code, node);
  }

  void test_visitBooleanLiteral_false() {
    var code = 'false';
    var parseResult = parseTestCodeWithDiagnostics('''
final v = $code;
''');
    var node = parseResult.findNode.singleBooleanLiteral;
    _assertSource(code, node);
  }

  void test_visitBooleanLiteral_true() {
    var code = 'true';
    var parseResult = parseTestCodeWithDiagnostics('''
final v = $code;
''');
    var node = parseResult.findNode.singleBooleanLiteral;
    _assertSource(code, node);
  }

  void test_visitBreakStatement_label() {
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

  void test_visitBreakStatement_noLabel() {
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

  void test_visitCascadeExpression_field() {
    var code = 'a..b..c';
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  $code;
}
''');
    var node = parseResult.findNode.singleCascadeExpression;
    _assertSource(code, node);
  }

  void test_visitCascadeExpression_index() {
    var code = 'a..[0]..[1]';
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  $code;
}
''');
    var node = parseResult.findNode.singleCascadeExpression;
    _assertSource(code, node);
  }

  void test_visitCascadeExpression_method() {
    var code = 'a..b()..c()';
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  $code;
}
''');
    var node = parseResult.findNode.singleCascadeExpression;
    _assertSource(code, node);
  }

  void test_visitCastPattern() {
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

  void test_visitCatchClause_catch_noStack() {
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

  void test_visitCatchClause_catch_stack() {
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

  void test_visitCatchClause_on() {
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

  void test_visitCatchClause_on_catch() {
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

  void test_visitClassDeclaration_abstract() {
    var code = 'abstract class C {}';
    var parseResult = parseTestCodeWithDiagnostics(code);
    var node = parseResult.findNode.singleClassDeclaration;
    _assertSource(code, node);
  }

  void test_visitClassDeclaration_augment() {
    var code = 'augment class A {}';
    var parseResult = parseTestCodeWithDiagnostics(code);
    var node = parseResult.findNode.singleClassDeclaration;
    _assertSource(code, node);
  }

  void test_visitClassDeclaration_augment_abstract() {
    var code = 'augment abstract class C {}';
    var parseResult = parseTestCodeWithDiagnostics(code);
    var node = parseResult.findNode.singleClassDeclaration;
    _assertSource(code, node);
  }

  void test_visitClassDeclaration_base() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
base class A {}
''');
    var node = parseResult.findNode.singleClassDeclaration;
    _assertSource('base class A {}', node);
  }

  void test_visitClassDeclaration_empty() {
    var code = 'class C {}';
    var parseResult = parseTestCodeWithDiagnostics(code);
    var node = parseResult.findNode.singleClassDeclaration;
    _assertSource(code, node);
  }

  void test_visitClassDeclaration_extends() {
    var code = 'class C extends A {}';
    var parseResult = parseTestCodeWithDiagnostics('''
$code
''');
    var node = parseResult.findNode.singleClassDeclaration;
    _assertSource(code, node);
  }

  void test_visitClassDeclaration_extends_implements() {
    var code = 'class C extends A implements B {}';
    var parseResult = parseTestCodeWithDiagnostics('''
$code
''');
    var node = parseResult.findNode.singleClassDeclaration;
    _assertSource(code, node);
  }

  void test_visitClassDeclaration_extends_with() {
    var code = 'class C extends A with M {}';
    var parseResult = parseTestCodeWithDiagnostics('''
$code
void f() {}
''');
    var node = parseResult.findNode.singleClassDeclaration;
    _assertSource(code, node);
  }

  void test_visitClassDeclaration_extends_with_implements() {
    var code = 'class C extends A with M implements B {}';
    var parseResult = parseTestCodeWithDiagnostics('''
$code
void f() {}
''');
    var node = parseResult.findNode.singleClassDeclaration;
    _assertSource(code, node);
  }

  void test_visitClassDeclaration_final() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
final class A {}
''');
    var node = parseResult.findNode.singleClassDeclaration;
    _assertSource('final class A {}', node);
  }

  void test_visitClassDeclaration_implements() {
    var code = 'class C implements B {}';
    var parseResult = parseTestCodeWithDiagnostics('''
$code
''');
    var node = parseResult.findNode.singleClassDeclaration;
    _assertSource(code, node);
  }

  void test_visitClassDeclaration_interface() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
interface class A {}
''');
    var node = parseResult.findNode.singleClassDeclaration;
    _assertSource('interface class A {}', node);
  }

  void test_visitClassDeclaration_mixin() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin class A {}
''');
    var node = parseResult.findNode.singleClassDeclaration;
    _assertSource('mixin class A {}', node);
  }

  void test_visitClassDeclaration_multipleMember() {
    var code = 'class C {var a; var b;}';
    var parseResult = parseTestCodeWithDiagnostics('''
$code
''');
    var node = parseResult.findNode.singleClassDeclaration;
    _assertSource(code, node);
  }

  void test_visitClassDeclaration_parameters() {
    var code = 'class C<E> {}';
    var parseResult = parseTestCodeWithDiagnostics(code);
    var node = parseResult.findNode.singleClassDeclaration;
    _assertSource(code, node);
  }

  void test_visitClassDeclaration_parameters_extends() {
    var code = 'class C<E> extends A {}';
    var parseResult = parseTestCodeWithDiagnostics('''
$code
''');
    var node = parseResult.findNode.singleClassDeclaration;
    _assertSource(code, node);
  }

  void test_visitClassDeclaration_parameters_extends_implements() {
    var code = 'class C<E> extends A implements B {}';
    var parseResult = parseTestCodeWithDiagnostics('''
$code
''');
    var node = parseResult.findNode.singleClassDeclaration;
    _assertSource(code, node);
  }

  void test_visitClassDeclaration_parameters_extends_with() {
    var code = 'class C<E> extends A with M {}';
    var parseResult = parseTestCodeWithDiagnostics('''
$code
''');
    var node = parseResult.findNode.singleClassDeclaration;
    _assertSource(code, node);
  }

  void test_visitClassDeclaration_parameters_extends_with_implements() {
    var code = 'class C<E> extends A with M implements B {}';
    var parseResult = parseTestCodeWithDiagnostics('''
$code
''');
    var node = parseResult.findNode.singleClassDeclaration;
    _assertSource(code, node);
  }

  void test_visitClassDeclaration_parameters_implements() {
    var code = 'class C<E> implements B {}';
    var parseResult = parseTestCodeWithDiagnostics('''
$code
''');
    var node = parseResult.findNode.singleClassDeclaration;
    _assertSource(code, node);
  }

  void test_visitClassDeclaration_sealed() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
sealed class A {}
''');
    var node = parseResult.findNode.singleClassDeclaration;
    _assertSource('sealed class A {}', node);
  }

  void test_visitClassDeclaration_singleMember() {
    var code = 'class C {var a;}';
    var parseResult = parseTestCodeWithDiagnostics(code);
    var node = parseResult.findNode.singleClassDeclaration;
    _assertSource(code, node);
  }

  void test_visitClassDeclaration_withMetadata() {
    var code = '@deprecated class C {}';
    var parseResult = parseTestCodeWithDiagnostics(code);
    var node = parseResult.findNode.singleClassDeclaration;
    _assertSource(code, node);
  }

  void test_visitClassTypeAlias_abstract() {
    var code = 'abstract class C = S with M;';
    var parseResult = parseTestCodeWithDiagnostics('''
$code
''');
    var node = parseResult.findNode.singleClassTypeAlias;
    _assertSource(code, node);
  }

  void test_visitClassTypeAlias_abstract_implements() {
    var code = 'abstract class C = S with M implements I;';
    var parseResult = parseTestCodeWithDiagnostics('''
$code
''');
    var node = parseResult.findNode.singleClassTypeAlias;
    _assertSource(code, node);
  }

  void test_visitClassTypeAlias_abstractAugment() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
augment abstract class C = S with M;
// [diag.mixinApplicationClassAugmentation][column 1][length 7] A mixin application class can't be augmented.
''');
    var node = parseResult.findNode.singleClassTypeAlias;
    _assertSource('augment abstract class C = S with M;', node);
  }

  void test_visitClassTypeAlias_augment() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
augment class A = S with M;
// [diag.mixinApplicationClassAugmentation][column 1][length 7] A mixin application class can't be augmented.
''');
    var node = parseResult.findNode.singleClassTypeAlias;
    _assertSource('augment class A = S with M;', node);
  }

  void test_visitClassTypeAlias_base() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
base class A = S with M;
''');
    var node = parseResult.findNode.singleClassTypeAlias;
    _assertSource('base class A = S with M;', node);
  }

  void test_visitClassTypeAlias_final() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
final class A = S with M;
''');
    var node = parseResult.findNode.singleClassTypeAlias;
    _assertSource('final class A = S with M;', node);
  }

  void test_visitClassTypeAlias_generic() {
    var code = 'class C<E> = S<E> with M<E>;';
    var parseResult = parseTestCodeWithDiagnostics('''
$code
''');
    var node = parseResult.findNode.singleClassTypeAlias;
    _assertSource(code, node);
  }

  void test_visitClassTypeAlias_implements() {
    var code = 'class C = S with M implements I;';
    var parseResult = parseTestCodeWithDiagnostics('''
$code
''');
    var node = parseResult.findNode.singleClassTypeAlias;
    _assertSource(code, node);
  }

  void test_visitClassTypeAlias_interface() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
interface class A = S with M;
''');
    var node = parseResult.findNode.singleClassTypeAlias;
    _assertSource('interface class A = S with M;', node);
  }

  void test_visitClassTypeAlias_minimal() {
    var code = 'class C = S with M;';
    var parseResult = parseTestCodeWithDiagnostics('''
$code
''');
    var node = parseResult.findNode.singleClassTypeAlias;
    _assertSource(code, node);
  }

  void test_visitClassTypeAlias_mixin() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin class A = S with M;
''');
    var node = parseResult.findNode.singleClassTypeAlias;
    _assertSource('mixin class A = S with M;', node);
  }

  void test_visitClassTypeAlias_parameters_abstract() {
    var code = 'abstract class C<E> = S with M;';
    var parseResult = parseTestCodeWithDiagnostics('''
$code
''');
    var node = parseResult.findNode.singleClassTypeAlias;
    _assertSource(code, node);
  }

  void test_visitClassTypeAlias_parameters_abstract_implements() {
    var code = 'abstract class C<E> = S with M implements I;';
    var parseResult = parseTestCodeWithDiagnostics('''
$code
''');
    var node = parseResult.findNode.singleClassTypeAlias;
    _assertSource(code, node);
  }

  void test_visitClassTypeAlias_parameters_implements() {
    var code = 'class C<E> = S with M implements I;';
    var parseResult = parseTestCodeWithDiagnostics('''
$code
''');
    var node = parseResult.findNode.singleClassTypeAlias;
    _assertSource(code, node);
  }

  void test_visitClassTypeAlias_sealed() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
sealed class A = S with M;
''');
    var node = parseResult.findNode.singleClassTypeAlias;
    _assertSource('sealed class A = S with M;', node);
  }

  void test_visitClassTypeAlias_withMetadata() {
    var code = '@deprecated class A = S with M;';
    var parseResult = parseTestCodeWithDiagnostics(code);
    var node = parseResult.findNode.singleClassTypeAlias;
    _assertSource(code, node);
  }

  void test_visitComment() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
/// foo
/// bar
void f() {}
''');
    var node = parseResult.findNode.singleComment;
    _assertSource('', node);
  }

  void test_visitCommentReference() {
    var code = '[x]';
    var parseResult = parseTestCodeWithDiagnostics('''
/// $code
void f() {}
''');
    var node = parseResult.findNode.singleCommentReference;
    _assertSource(code, node);
  }

  void test_visitCompilationUnit_declaration() {
    var code = 'var a;';
    var parseResult = parseTestCodeWithDiagnostics(code);
    var node = parseResult.findNode.unit;
    _assertSource(code, node);
  }

  void test_visitCompilationUnit_directive() {
    var code = 'library my;';
    var parseResult = parseTestCodeWithDiagnostics(code);
    var node = parseResult.findNode.unit;
    _assertSource(code, node);
  }

  void test_visitCompilationUnit_directive_declaration() {
    var code = 'library my; var a;';
    var parseResult = parseTestCodeWithDiagnostics(code);
    var node = parseResult.findNode.unit;
    _assertSource(code, node);
  }

  void test_visitCompilationUnit_empty() {
    var code = '';
    var parseResult = parseTestCodeWithDiagnostics(code);
    var node = parseResult.findNode.unit;
    _assertSource(code, node);
  }

  void test_visitCompilationUnit_libraryWithoutName() {
    var code = 'library ;';
    var parseResult = parseTestCodeWithDiagnostics(code);
    var node = parseResult.findNode.unit;
    _assertSource(code, node);
  }

  void test_visitCompilationUnit_script() {
    var parseResult = parseTestCodeWithDiagnostics('''
#!/bin/dartvm
''');
    var node = parseResult.findNode.unit;
    _assertSource('#!/bin/dartvm', node);
  }

  void test_visitCompilationUnit_script_declaration() {
    var parseResult = parseTestCodeWithDiagnostics('''
#!/bin/dartvm
var a;
''');
    var node = parseResult.findNode.unit;
    _assertSource('#!/bin/dartvm var a;', node);
  }

  void test_visitCompilationUnit_script_directive() {
    var parseResult = parseTestCodeWithDiagnostics('''
#!/bin/dartvm
library my;
''');
    var node = parseResult.findNode.unit;
    _assertSource('#!/bin/dartvm library my;', node);
  }

  void test_visitCompilationUnit_script_directives_declarations() {
    var parseResult = parseTestCodeWithDiagnostics('''
#!/bin/dartvm
library my;
var a;
''');
    var node = parseResult.findNode.unit;
    _assertSource('#!/bin/dartvm library my; var a;', node);
  }

  void test_visitConditionalExpression() {
    var code = 'a ? b : c';
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  $code;
}
''');
    var node = parseResult.findNode.singleConditionalExpression;
    _assertSource(code, node);
  }

  void test_visitConstantPattern() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  if (x case true) {}
}
''');
    var node = parseResult.findNode.singleConstantPattern;
    _assertSource('true', node);
  }

  void test_visitConstructorDeclaration_factoryHead_named() {
    var code = 'factory named() {}';
    var parseResult = parseTestCodeWithDiagnostics('''
class A {
  $code
}
''');
    var node = parseResult.findNode.singleConstructorDeclaration;
    _assertSource(code, node);
  }

  void test_visitConstructorDeclaration_factoryHead_unnamed() {
    var code = 'factory () {}';
    var parseResult = parseTestCodeWithDiagnostics('''
class A {
  $code
}
''');
    var node = parseResult.findNode.singleConstructorDeclaration;
    _assertSource(code, node);
  }

  void test_visitConstructorDeclaration_newHead_named() {
    var code = 'new named();';
    var parseResult = parseTestCodeWithDiagnostics('''
class A {
  $code
}
''');
    var node = parseResult.findNode.singleConstructorDeclaration;
    _assertSource(code, node);
  }

  void test_visitConstructorDeclaration_newHead_unnamed() {
    var code = 'new ();';
    var parseResult = parseTestCodeWithDiagnostics('''
class A {
  $code
}
''');
    var node = parseResult.findNode.singleConstructorDeclaration;
    _assertSource(code, node);
  }

  void test_visitConstructorDeclaration_singleInitializer() {
    var code = 'A() : a = b;';
    var parseResult = parseTestCodeWithDiagnostics('''
class A {
  $code
}
''');
    var node = parseResult.findNode.singleConstructorDeclaration;
    _assertSource(code, node);
  }

  void test_visitConstructorDeclaration_typeName_const() {
    var code = 'const A();';
    var parseResult = parseTestCodeWithDiagnostics('''
class A {
  $code
}
''');
    var node = parseResult.findNode.singleConstructorDeclaration;
    _assertSource(code, node);
  }

  void test_visitConstructorDeclaration_typeName_external() {
    var code = 'external A();';
    var parseResult = parseTestCodeWithDiagnostics('''
class A {
  $code
}
''');
    var node = parseResult.findNode.singleConstructorDeclaration;
    _assertSource(code, node);
  }

  void test_visitConstructorDeclaration_typeName_factory_named() {
    var code = 'factory A.named() {}';
    var parseResult = parseTestCodeWithDiagnostics('''
class A {
  $code
}
''');
    var node = parseResult.findNode.singleConstructorDeclaration;
    _assertSource(code, node);
  }

  void test_visitConstructorDeclaration_typeName_factory_unnamed() {
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
  test_visitConstructorDeclaration_typeName_formalParameters_optionalPositional() {
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
  test_visitConstructorDeclaration_typeName_formalParameters_requiredPositional() {
    var code = 'A(int a, double b);';
    var parseResult = parseTestCodeWithDiagnostics('''
class A {
  $code
}
''');
    var node = parseResult.findNode.singleConstructorDeclaration;
    _assertSource(code, node);
  }

  void test_visitConstructorDeclaration_typeName_multipleInitializers() {
    var code = 'A() : a = b, c = d {}';
    var parseResult = parseTestCodeWithDiagnostics('''
class A {
  $code
}
''');
    var node = parseResult.findNode.singleConstructorDeclaration;
    _assertSource(code, node);
  }

  void test_visitConstructorDeclaration_typeName_named() {
    var code = 'A.foo();';
    var parseResult = parseTestCodeWithDiagnostics('''
class A {
  $code
}
''');
    var node = parseResult.findNode.singleConstructorDeclaration;
    _assertSource(code, node);
  }

  void test_visitConstructorDeclaration_typeName_unnamed() {
    var code = 'A();';
    var parseResult = parseTestCodeWithDiagnostics('''
class A {
  $code
}
''');
    var node = parseResult.findNode.singleConstructorDeclaration;
    _assertSource(code, node);
  }

  void test_visitConstructorDeclaration_typeName_withInitializers() {
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

  void test_visitConstructorDeclaration_withMetadata() {
    var code = '@deprecated C() {}';
    var parseResult = parseTestCodeWithDiagnostics('''
class C {
  $code
}
''');
    var node = parseResult.findNode.singleConstructorDeclaration;
    _assertSource(code, node);
  }

  void test_visitConstructorFieldInitializer_withoutThis() {
    var code = 'a = 0';
    var parseResult = parseTestCodeWithDiagnostics('''
class C {
  C() : $code;
}
''');
    var node = parseResult.findNode.singleConstructorFieldInitializer;
    _assertSource(code, node);
  }

  void test_visitConstructorFieldInitializer_withThis() {
    var code = 'this.a = 0';
    var parseResult = parseTestCodeWithDiagnostics('''
class C {
  C() : $code;
}
''');
    var node = parseResult.findNode.singleConstructorFieldInitializer;
    _assertSource(code, node);
  }

  void test_visitConstructorName_named_prefix() {
    var code = 'prefix.A.foo';
    var parseResult = parseTestCodeWithDiagnostics('''
final x = new $code();
''');
    var node = parseResult.findNode.singleConstructorName;
    _assertSource(code, node);
  }

  void test_visitConstructorName_unnamed_noPrefix() {
    var code = 'A';
    var parseResult = parseTestCodeWithDiagnostics('''
final x = new $code();
''');
    var node = parseResult.findNode.singleConstructorName;
    _assertSource(code, node);
  }

  void test_visitConstructorName_unnamed_prefix() {
    var code = 'prefix.A';
    var parseResult = parseTestCodeWithDiagnostics('''
final x = new $code();
''');
    var node = parseResult.findNode.singleConstructorName;
    _assertSource(code, node);
  }

  void test_visitContinueStatement_label() {
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

  void test_visitContinueStatement_noLabel() {
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

  void test_visitDeclaredVariablePattern() {
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

  void test_visitDefaultFormalParameter_annotation() {
    var code = '@deprecated p = 0';
    var parseResult = parseTestCodeWithDiagnostics('''
void f([$code]) {}
''');
    var node = parseResult.findNode.singleFormalParameter;
    _assertSource(code, node);
  }

  void test_visitDefaultFormalParameter_named_noValue() {
    var code = 'int? a';
    var parseResult = parseTestCodeWithDiagnostics('''
void f({$code}) {}
''');
    var node = parseResult.findNode.singleFormalParameter;
    _assertSource(code, node);
  }

  void test_visitDefaultFormalParameter_named_value() {
    var code = 'int? a = 0';
    var parseResult = parseTestCodeWithDiagnostics('''
void f({$code}) {}
''');
    var node = parseResult.findNode.singleFormalParameter;
    _assertSource(code, node);
  }

  void test_visitDefaultFormalParameter_positional_noValue() {
    var code = 'int? a';
    var parseResult = parseTestCodeWithDiagnostics('''
void f([$code]) {}
''');
    var node = parseResult.findNode.singleFormalParameter;
    _assertSource(code, node);
  }

  void test_visitDefaultFormalParameter_positional_value() {
    var code = 'int? a = 0';
    var parseResult = parseTestCodeWithDiagnostics('''
void f([$code]) {}
''');
    var node = parseResult.findNode.singleFormalParameter;
    _assertSource(code, node);
  }

  void test_visitDoStatement() {
    var code = 'do {} while (true);';
    var parseResult = parseTestCodeWithDiagnostics('''
void f () {
  $code
}
''');
    var node = parseResult.findNode.singleDoStatement;
    _assertSource(code, node);
  }

  void test_visitDottedName_multiple() {
    var code = 'a.b.c';
    var parseResult = parseTestCodeWithDiagnostics('''
library $code;
''');
    var node = parseResult.findNode.singleDottedName;
    _assertSource(code, node);
  }

  void test_visitDottedName_single() {
    var code = 'my';
    var parseResult = parseTestCodeWithDiagnostics('''
library $code;
''');
    var node = parseResult.findNode.singleDottedName;
    _assertSource(code, node);
  }

  void test_visitDoubleLiteral() {
    var code = '3.14';
    var parseResult = parseTestCodeWithDiagnostics('''
final x = $code;
''');
    var node = parseResult.findNode.singleDoubleLiteral;
    _assertSource(code, node);
  }

  void test_visitEmptyFunctionBody() {
    var code = ';';
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  ;
}
''');
    var node = parseResult.findNode.singleEmptyStatement;
    _assertSource(code, node);
  }

  void test_visitEmptyStatement() {
    var code = ';';
    var parseResult = parseTestCodeWithDiagnostics('''
abstract class A {
  void foo();
}
''');
    var node = parseResult.findNode.singleEmptyFunctionBody;
    _assertSource(code, node);
  }

  void test_visitEnumConstantDeclaration_augment() {
    var code = 'augment v';
    var parseResult = parseTestCodeWithDiagnostics('''
augment enum E {
  $code
}
''');
    var node = parseResult.findNode.singleEnumConstantDeclaration;
    _assertSource(code, node);
  }

  void test_visitEnumDeclaration_augment() {
    var code = 'augment enum E {v}';
    var parseResult = parseTestCodeWithDiagnostics('''
$code
''');
    var node = parseResult.findNode.singleEnumDeclaration;
    _assertSource(code, node);
  }

  void test_visitEnumDeclaration_constant_arguments_named() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
enum E {
  v<double>.named(42)
}
''');
    var node = parseResult.findNode.singleEnumDeclaration;
    _assertSource('enum E {v<double>.named(42)}', node);
  }

  void test_visitEnumDeclaration_constant_arguments_unnamed() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
enum E {
  v<double>(42)
}
''');
    var node = parseResult.findNode.singleEnumDeclaration;
    _assertSource('enum E {v<double>(42)}', node);
  }

  void test_visitEnumDeclaration_constants_multiple() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
enum E {one, two}
''');
    var node = parseResult.findNode.singleEnumDeclaration;
    _assertSource('enum E {one, two}', node);
  }

  void test_visitEnumDeclaration_constants_single() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
enum E {one}
''');
    var node = parseResult.findNode.singleEnumDeclaration;
    _assertSource('enum E {one}', node);
  }

  void test_visitEnumDeclaration_field_constructor() {
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

  void test_visitEnumDeclaration_method() {
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

  void test_visitEnumDeclaration_withoutMembers() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
enum E<T> with M1, M2 implements I1, I2 {one, two}
''');
    var node = parseResult.findNode.singleEnumDeclaration;
    _assertSource('enum E<T> with M1, M2 implements I1, I2 {one, two}', node);
  }

  void test_visitExportDirective_combinator() {
    var code = "export 'a.dart' show A;";
    var parseResult = parseTestCodeWithDiagnostics('''
$code
''');
    var node = parseResult.findNode.singleExportDirective;
    _assertSource(code, node);
  }

  void test_visitExportDirective_combinators() {
    var code = "export 'a.dart' show A hide B;";
    var parseResult = parseTestCodeWithDiagnostics('''
$code
''');
    var node = parseResult.findNode.singleExportDirective;
    _assertSource(code, node);
  }

  void test_visitExportDirective_configurations() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
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
    var parseResult = parseTestCodeWithDiagnostics(code);
    var node = parseResult.findNode.singleExportDirective;
    _assertSource(code, node);
  }

  void test_visitExportDirective_withMetadata() {
    var code = '@deprecated export "a.dart";';
    var parseResult = parseTestCodeWithDiagnostics(code);
    var node = parseResult.findNode.singleExportDirective;
    _assertSource(code, node);
  }

  void test_visitExpressionFunctionBody_async() {
    var code = 'async => 0;';
    var parseResult = parseTestCodeWithDiagnostics('''
void f() $code
''');
    var node = parseResult.findNode.singleExpressionFunctionBody;
    _assertSource(code, node);
  }

  void test_visitExpressionFunctionBody_async_star() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f() async* => 0;
//              ^^
// [diag.returnInGenerator] Can't return a value from a generator function that uses the 'async*' or 'sync*' modifier.
''');
    var node = parseResult.findNode.singleExpressionFunctionBody;
    _assertSource('async* => 0;', node);
  }

  void test_visitExpressionFunctionBody_simple() {
    var code = '=> 0;';
    var parseResult = parseTestCodeWithDiagnostics('''
void f() $code
''');
    var node = parseResult.findNode.singleExpressionFunctionBody;
    _assertSource(code, node);
  }

  void test_visitExpressionStatement() {
    var code = '1 + 2;';
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  $code
}
''');
    var node = parseResult.findNode.singleExpressionStatement;
    _assertSource(code, node);
  }

  void test_visitExtendsClause() {
    var code = 'extends A';
    var parseResult = parseTestCodeWithDiagnostics('''
class C $code {}
''');
    var node = parseResult.findNode.singleExtendsClause;
    _assertSource(code, node);
  }

  void test_visitExtensionDeclaration_augment() {
    var code = 'augment extension E {}';
    var parseResult = parseTestCodeWithDiagnostics('''
$code
''');
    var node = parseResult.findNode.singleExtensionDeclaration;
    _assertSource(code, node);
  }

  void test_visitExtensionDeclaration_empty() {
    var code = 'extension E on C {}';
    var parseResult = parseTestCodeWithDiagnostics('''
$code
''');
    var node = parseResult.findNode.singleExtensionDeclaration;
    _assertSource(code, node);
  }

  void test_visitExtensionDeclaration_multipleMember() {
    var code = 'extension E on C {static var a; static var b;}';
    var parseResult = parseTestCodeWithDiagnostics('''
$code
''');
    var node = parseResult.findNode.singleExtensionDeclaration;
    _assertSource(code, node);
  }

  void test_visitExtensionDeclaration_parameters() {
    var code = 'extension E<T> on C {}';
    var parseResult = parseTestCodeWithDiagnostics('''
$code
''');
    var node = parseResult.findNode.singleExtensionDeclaration;
    _assertSource(code, node);
  }

  void test_visitExtensionDeclaration_singleMember() {
    var code = 'extension E on C {static var a;}';
    var parseResult = parseTestCodeWithDiagnostics('''
$code
''');
    var node = parseResult.findNode.singleExtensionDeclaration;
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
    var parseResult = parseTestCodeWithDiagnostics('''
$code
''');
    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    _assertSource(code, node);
  }

  void test_visitExtensionType_augment() {
    var code = 'augment extension type E implements I {}';
    var parseResult = parseTestCodeWithDiagnostics('''
$code
''');
    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    _assertSource(code, node);
  }

  void test_visitExtensionType_implements() {
    var code = 'extension type E(int it) implements num {}';
    var parseResult = parseTestCodeWithDiagnostics('''
$code
''');
    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    _assertSource(code, node);
  }

  void test_visitExtensionType_method() {
    var code = 'extension type E(int it) {void foo() {}}';
    var parseResult = parseTestCodeWithDiagnostics('''
$code
''');
    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    _assertSource(code, node);
  }

  void test_visitFieldDeclaration_abstract() {
    var code = 'abstract var a;';
    var parseResult = parseTestCodeWithDiagnostics('''
class A {
  $code
}
''');
    var node = parseResult.findNode.singleFieldDeclaration;
    _assertSource(code, node);
  }

  void test_visitFieldDeclaration_abstract_external() {
    var parseResult = parseTestCodeWithDiagnostics('''
class A {
  abstract external var a;
//^^^^^^^^
// [diag.abstractExternalField] Fields can't be declared both 'abstract' and 'external'.
}
''');
    var node = parseResult.findNode.singleFieldDeclaration;
    _assertSource('external abstract var a;', node);
  }

  void test_visitFieldDeclaration_abstract_static() {
    var code = 'static abstract var a;';
    var parseResult = parseTestCodeWithDiagnostics('''
class A {
  $code
}
''');
    var node = parseResult.findNode.singleFieldDeclaration;
    _assertSource(code, node);
  }

  void test_visitFieldDeclaration_augment() {
    var code = 'augment var a = 0;';
    var parseResult = parseTestCodeWithDiagnostics('''
augment class A {
  $code
}
''');
    var node = parseResult.findNode.singleFieldDeclaration;
    _assertSource(code, node);
  }

  void test_visitFieldDeclaration_covariant() {
    var code = 'covariant var a;';
    var parseResult = parseTestCodeWithDiagnostics('''
class A {
  $code
}
''');
    var node = parseResult.findNode.singleFieldDeclaration;
    _assertSource(code, node);
  }

  void test_visitFieldDeclaration_external() {
    var code = 'external var a;';
    var parseResult = parseTestCodeWithDiagnostics('''
class A {
  $code
}
''');
    var node = parseResult.findNode.singleFieldDeclaration;
    _assertSource(code, node);
  }

  void test_visitFieldDeclaration_instance() {
    var code = 'var a;';
    var parseResult = parseTestCodeWithDiagnostics('''
class A {
  $code
}
''');
    var node = parseResult.findNode.singleFieldDeclaration;
    _assertSource(code, node);
  }

  void test_visitFieldDeclaration_static() {
    var code = 'static var a;';
    var parseResult = parseTestCodeWithDiagnostics('''
class A {
  $code
}
''');
    var node = parseResult.findNode.singleFieldDeclaration;
    _assertSource(code, node);
  }

  void test_visitFieldDeclaration_withMetadata() {
    var code = '@deprecated var a;';
    var parseResult = parseTestCodeWithDiagnostics('''
class A {
  $code
}
''');
    var node = parseResult.findNode.singleFieldDeclaration;
    _assertSource(code, node);
  }

  void test_visitFieldFormalParameter_annotation() {
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

  void test_visitFieldFormalParameter_functionTyped() {
    var code = 'A this.a(b)';
    var parseResult = parseTestCodeWithDiagnostics('''
class A {
  A($code);
}
''');
    var node = parseResult.findNode.singleFieldFormalParameter;
    _assertSource(code, node);
  }

  void test_visitFieldFormalParameter_functionTyped_typeParameters() {
    var code = 'A this.a<E, F>(b)';
    var parseResult = parseTestCodeWithDiagnostics('''
class A {
  A($code);
}
''');
    var node = parseResult.findNode.singleFieldFormalParameter;
    _assertSource(code, node);
  }

  void test_visitFieldFormalParameter_keyword() {
    var code = 'var this.a';
    var parseResult = parseTestCodeWithDiagnostics('''
// @dart = 3.10
class A {
  A($code);
}
''');
    var node = parseResult.findNode.singleFieldFormalParameter;
    _assertSource(code, node);
  }

  void test_visitFieldFormalParameter_keywordAndType() {
    var code = 'final A this.a';
    var parseResult = parseTestCodeWithDiagnostics('''
// @dart = 3.10
class A {
  A($code);
}
''');
    var node = parseResult.findNode.singleFieldFormalParameter;
    _assertSource(code, node);
  }

  void test_visitFieldFormalParameter_type() {
    var code = 'A this.a';
    var parseResult = parseTestCodeWithDiagnostics('''
class A {
  A($code);
}
''');
    var node = parseResult.findNode.singleFieldFormalParameter;
    _assertSource(code, node);
  }

  void test_visitFieldFormalParameter_type_covariant() {
    var code = 'covariant A this.a';
    var parseResult = parseTestCodeWithDiagnostics('''
class A {
  A($code);
}
''');
    var node = parseResult.findNode.singleFieldFormalParameter;
    _assertSource(code, node);
  }

  void test_visitForEachPartsWithIdentifier() {
    var code = 'e in []';
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  for ($code) {}
}
''');
    var node = parseResult.findNode.singleForEachPartsWithIdentifier;
    _assertSource(code, node);
  }

  void test_visitForEachPartsWithPattern() {
    var code = 'final (a, b) in c';
    var parseResult = parseTestCodeWithDiagnostics('''
void f () {
  for ($code) {}
}
''');
    var node = parseResult.findNode.singleForEachPartsWithPattern;
    _assertSource(code, node);
  }

  void test_visitForEachStatement_declared() {
    var code = 'for (final a in b) {}';
    var parseResult = parseTestCodeWithDiagnostics('''
void f () {
  $code
}
''');
    var node = parseResult.findNode.singleForStatement;
    _assertSource(code, node);
  }

  void test_visitForEachStatement_variable() {
    var code = 'for (a in b) {}';
    var parseResult = parseTestCodeWithDiagnostics('''
void f () {
  $code
}
''');
    var node = parseResult.findNode.singleForStatement;
    _assertSource(code, node);
  }

  void test_visitForEachStatement_variable_await() {
    var code = 'await for (final a in b) {}';
    var parseResult = parseTestCodeWithDiagnostics('''
void f() async {
  $code
}
''');
    var node = parseResult.findNode.singleForStatement;
    _assertSource(code, node);
  }

  void test_visitForElement() {
    var code = 'for (e in []) 0';
    var parseResult = parseTestCodeWithDiagnostics('''
final v = [ $code ];
''');
    var node = parseResult.findNode.singleForElement;
    _assertSource(code, node);
  }

  void test_visitFormalParameterList_empty() {
    var code = '()';
    var parseResult = parseTestCodeWithDiagnostics('''
void f$code {}
''');
    var node = parseResult.findNode.singleFormalParameterList;
    _assertSource(code, node);
  }

  void test_visitFormalParameterList_n() {
    var code = '({a = 0})';
    var parseResult = parseTestCodeWithDiagnostics('''
void f$code {}
''');
    var node = parseResult.findNode.singleFormalParameterList;
    _assertSource(code, node);
  }

  void test_visitFormalParameterList_namedRequired() {
    var code = '({required a, required int b})';
    var parseResult = parseTestCodeWithDiagnostics('''
void f$code {}
''');
    var node = parseResult.findNode.singleFormalParameterList;
    _assertSource(code, node);
  }

  void test_visitFormalParameterList_nn() {
    var code = '({int a = 0, b = 1})';
    var parseResult = parseTestCodeWithDiagnostics('''
void f$code {}
''');
    var node = parseResult.findNode.singleFormalParameterList;
    _assertSource(code, node);
  }

  void test_visitFormalParameterList_p() {
    var code = '([a = 0])';
    var parseResult = parseTestCodeWithDiagnostics('''
void f$code {}
''');
    var node = parseResult.findNode.singleFormalParameterList;
    _assertSource(code, node);
  }

  void test_visitFormalParameterList_pp() {
    var code = '([a = 0, b = 1])';
    var parseResult = parseTestCodeWithDiagnostics('''
void f$code {}
''');
    var node = parseResult.findNode.singleFormalParameterList;
    _assertSource(code, node);
  }

  void test_visitFormalParameterList_r() {
    var code = '(int a)';
    var parseResult = parseTestCodeWithDiagnostics('''
void f$code {}
''');
    var node = parseResult.findNode.singleFormalParameterList;
    _assertSource(code, node);
  }

  void test_visitFormalParameterList_rn() {
    var code = '(a, {b = 1})';
    var parseResult = parseTestCodeWithDiagnostics('''
void f$code {}
''');
    var node = parseResult.findNode.singleFormalParameterList;
    _assertSource(code, node);
  }

  void test_visitFormalParameterList_rnn() {
    var code = '(a, {b = 1, c = 2})';
    var parseResult = parseTestCodeWithDiagnostics('''
void f$code {}
''');
    var node = parseResult.findNode.singleFormalParameterList;
    _assertSource(code, node);
  }

  void test_visitFormalParameterList_rp() {
    var code = '(a, [b = 1])';
    var parseResult = parseTestCodeWithDiagnostics('''
void f$code {}
''');
    var node = parseResult.findNode.singleFormalParameterList;
    _assertSource(code, node);
  }

  void test_visitFormalParameterList_rpp() {
    var code = '(a, [b = 1, c = 2])';
    var parseResult = parseTestCodeWithDiagnostics('''
void f$code {}
''');
    var node = parseResult.findNode.singleFormalParameterList;
    _assertSource(code, node);
  }

  void test_visitFormalParameterList_rr() {
    var code = '(int a, int b)';
    var parseResult = parseTestCodeWithDiagnostics('''
void f$code {}
''');
    var node = parseResult.findNode.singleFormalParameterList;
    _assertSource(code, node);
  }

  void test_visitFormalParameterList_rrn() {
    var code = '(a, b, {c = 2})';
    var parseResult = parseTestCodeWithDiagnostics('''
void f$code {}
''');
    var node = parseResult.findNode.singleFormalParameterList;
    _assertSource(code, node);
  }

  void test_visitFormalParameterList_rrnn() {
    var code = '(a, b, {c = 2, d = 3})';
    var parseResult = parseTestCodeWithDiagnostics('''
void f$code {}
''');
    var node = parseResult.findNode.singleFormalParameterList;
    _assertSource(code, node);
  }

  void test_visitFormalParameterList_rrp() {
    var code = '(a, b, [c = 2])';
    var parseResult = parseTestCodeWithDiagnostics('''
void f$code {}
''');
    var node = parseResult.findNode.singleFormalParameterList;
    _assertSource(code, node);
  }

  void test_visitFormalParameterList_rrpp() {
    var code = '(a, b, [c = 2, d = 3])';
    var parseResult = parseTestCodeWithDiagnostics('''
void f$code {}
''');
    var node = parseResult.findNode.singleFormalParameterList;
    _assertSource(code, node);
  }

  void test_visitForPartsWithDeclarations() {
    var code = 'var v = 0; v < 10; v++';
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  for ($code) {}
}
''');
    var node = parseResult.findNode.singleForPartsWithDeclarations;
    _assertSource(code, node);
  }

  void test_visitForPartsWithExpression() {
    var code = 'v = 0; v < 10; v++';
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  for ($code) {}
}
''');
    var node = parseResult.findNode.singleForPartsWithExpression;
    _assertSource(code, node);
  }

  void test_visitForPartsWithPattern() {
    var code = 'var (a, b) = (0, 1); a < 10; a++, b++';
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  for ($code) {}
}
''');
    var node = parseResult.findNode.singleForPartsWithPattern;
    _assertSource(code, node);
  }

  void test_visitForStatement() {
    var code = 'for (var v in [0]) {}';
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  $code
}
''');
    var node = parseResult.findNode.singleForStatement;
    _assertSource(code, node);
  }

  void test_visitForStatement_c() {
    var code = 'for (; c;) {}';
    var parseResult = parseTestCodeWithDiagnostics('''
void f () {
  $code
}
''');
    var node = parseResult.findNode.singleForStatement;
    _assertSource(code, node);
  }

  void test_visitForStatement_cu() {
    var code = 'for (; c; u) {}';
    var parseResult = parseTestCodeWithDiagnostics('''
void f () {
  $code
}
''');
    var node = parseResult.findNode.singleForStatement;
    _assertSource(code, node);
  }

  void test_visitForStatement_e() {
    var code = 'for (e;;) {}';
    var parseResult = parseTestCodeWithDiagnostics('''
void f () {
  $code
}
''');
    var node = parseResult.findNode.singleForStatement;
    _assertSource(code, node);
  }

  void test_visitForStatement_ec() {
    var code = 'for (e; c;) {}';
    var parseResult = parseTestCodeWithDiagnostics('''
void f () {
  $code
}
''');
    var node = parseResult.findNode.singleForStatement;
    _assertSource(code, node);
  }

  void test_visitForStatement_ecu() {
    var code = 'for (e; c; u) {}';
    var parseResult = parseTestCodeWithDiagnostics('''
void f () {
  $code
}
''');
    var node = parseResult.findNode.singleForStatement;
    _assertSource(code, node);
  }

  void test_visitForStatement_eu() {
    var code = 'for (e;; u) {}';
    var parseResult = parseTestCodeWithDiagnostics('''
void f () {
  $code
}
''');
    var node = parseResult.findNode.singleForStatement;
    _assertSource(code, node);
  }

  void test_visitForStatement_i() {
    var code = 'for (var i;;) {}';
    var parseResult = parseTestCodeWithDiagnostics('''
void f () {
  $code
}
''');
    var node = parseResult.findNode.singleForStatement;
    _assertSource(code, node);
  }

  void test_visitForStatement_ic() {
    var code = 'for (var i; c;) {}';
    var parseResult = parseTestCodeWithDiagnostics('''
void f () {
  $code
}
''');
    var node = parseResult.findNode.singleForStatement;
    _assertSource(code, node);
  }

  void test_visitForStatement_icu() {
    var code = 'for (var i; c; u) {}';
    var parseResult = parseTestCodeWithDiagnostics('''
void f () {
  $code
}
''');
    var node = parseResult.findNode.singleForStatement;
    _assertSource(code, node);
  }

  void test_visitForStatement_iu() {
    var code = 'for (var i;; u) {}';
    var parseResult = parseTestCodeWithDiagnostics('''
void f () {
  $code
}
''');
    var node = parseResult.findNode.singleForStatement;
    _assertSource(code, node);
  }

  void test_visitForStatement_u() {
    var code = 'for (;; u) {}';
    var parseResult = parseTestCodeWithDiagnostics('''
void f () {
  $code
}
''');
    var node = parseResult.findNode.singleForStatement;
    _assertSource(code, node);
  }

  void test_visitFunctionDeclaration_augment() {
    var code = 'augment void f() {}';
    var parseResult = parseTestCodeWithDiagnostics(code);
    var node = parseResult.findNode.singleFunctionDeclaration;
    _assertSource(code, node);
  }

  void test_visitFunctionDeclaration_external() {
    var code = 'external void f();';
    var parseResult = parseTestCodeWithDiagnostics(code);
    var node = parseResult.findNode.singleFunctionDeclaration;
    _assertSource(code, node);
  }

  void test_visitFunctionDeclaration_getter() {
    var code = 'get foo {}';
    var parseResult = parseTestCodeWithDiagnostics(code);
    var node = parseResult.findNode.singleFunctionDeclaration;
    _assertSource(code, node);
  }

  void test_visitFunctionDeclaration_local_blockBody() {
    var code = 'void foo() {}';
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  $code
}
''');
    var node = parseResult.findNode.functionDeclaration(code);
    _assertSource(code, node);
  }

  void test_visitFunctionDeclaration_local_expressionBody() {
    var code = 'int foo() => 42;';
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  $code
}
''');
    var node = parseResult.findNode.functionDeclaration(code);
    _assertSource(code, node);
  }

  void test_visitFunctionDeclaration_normal() {
    var code = 'void foo() {}';
    var parseResult = parseTestCodeWithDiagnostics(code);
    var node = parseResult.findNode.singleFunctionDeclaration;
    _assertSource(code, node);
  }

  void test_visitFunctionDeclaration_setter() {
    var code = 'set foo(int _) {}';
    var parseResult = parseTestCodeWithDiagnostics(code);
    var node = parseResult.findNode.singleFunctionDeclaration;
    _assertSource(code, node);
  }

  void test_visitFunctionDeclaration_typeParameters() {
    var code = 'void foo<T>() {}';
    var parseResult = parseTestCodeWithDiagnostics(code);
    var node = parseResult.findNode.singleFunctionDeclaration;
    _assertSource(code, node);
  }

  void test_visitFunctionDeclaration_withMetadata() {
    var code = '@deprecated void f() {}';
    var parseResult = parseTestCodeWithDiagnostics(code);
    var node = parseResult.findNode.singleFunctionDeclaration;
    _assertSource(code, node);
  }

  void test_visitFunctionDeclarationStatement() {
    var code = 'void foo() {}';
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  $code
}
''');
    var node = parseResult.findNode.singleFunctionDeclarationStatement;
    _assertSource(code, node);
  }

  void test_visitFunctionExpression() {
    var code = '() {}';
    var parseResult = parseTestCodeWithDiagnostics('''
final f = $code;
''');
    var node = parseResult.findNode.singleFunctionExpression;
    _assertSource(code, node);
  }

  void test_visitFunctionExpression_typeParameters() {
    var code = '<T>() {}';
    var parseResult = parseTestCodeWithDiagnostics('''
final f = $code;
''');
    var node = parseResult.findNode.singleFunctionExpression;
    _assertSource(code, node);
  }

  void test_visitFunctionExpressionInvocation_minimal() {
    var code = '(a)()';
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  $code;
}
''');
    var node = parseResult.findNode.singleFunctionExpressionInvocation;
    _assertSource(code, node);
  }

  void test_visitFunctionExpressionInvocation_typeArguments() {
    var code = '(a)<int>()';
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  $code;
}
''');
    var node = parseResult.findNode.singleFunctionExpressionInvocation;
    _assertSource(code, node);
  }

  void test_visitFunctionTypeAlias_generic() {
    var code = 'typedef A F<B>();';
    var parseResult = parseTestCodeWithDiagnostics('''
$code
''');
    var node = parseResult.findNode.singleFunctionTypeAlias;
    _assertSource(code, node);
  }

  void test_visitFunctionTypeAlias_nonGeneric() {
    var code = 'typedef A F();';
    var parseResult = parseTestCodeWithDiagnostics('''
$code
''');
    var node = parseResult.findNode.singleFunctionTypeAlias;
    _assertSource(code, node);
  }

  void test_visitFunctionTypeAlias_withMetadata() {
    var code = '@deprecated typedef void F();';
    var parseResult = parseTestCodeWithDiagnostics(code);
    var node = parseResult.findNode.singleFunctionTypeAlias;
    _assertSource(code, node);
  }

  void test_visitFunctionTypedFormalParameter_annotation() {
    var code = '@deprecated g()';
    var parseResult = parseTestCodeWithDiagnostics('''
void f($code) {}
''');
    var node = parseResult.findNode.singleFormalParameter;
    _assertSource(code, node);
  }

  void test_visitFunctionTypedFormalParameter_noType() {
    var code = 'int f()';
    var parseResult = parseTestCodeWithDiagnostics('''
void f($code) {}
''');
    var node = parseResult.findNode.singleFormalParameter;
    _assertSource(code, node);
  }

  void test_visitFunctionTypedFormalParameter_nullable() {
    var code = 'T f()?';
    var parseResult = parseTestCodeWithDiagnostics('''
void f($code) {}
''');
    var node = parseResult.findNode.singleFormalParameter;
    _assertSource(code, node);
  }

  void test_visitFunctionTypedFormalParameter_type() {
    var code = 'T f()';
    var parseResult = parseTestCodeWithDiagnostics('''
void f($code) {}
''');
    var node = parseResult.findNode.singleFormalParameter;
    _assertSource(code, node);
  }

  void test_visitFunctionTypedFormalParameter_type_covariant() {
    var code = 'covariant T f()?';
    var parseResult = parseTestCodeWithDiagnostics('''
class A {
  void foo($code) {}
}
''');
    var node = parseResult.findNode.singleFormalParameter;
    _assertSource(code, node);
  }

  void test_visitFunctionTypedFormalParameter_typeParameters() {
    var code = 'T f<E>()';
    var parseResult = parseTestCodeWithDiagnostics('''
void f($code) {}
''');
    var node = parseResult.findNode.singleFormalParameter;
    _assertSource(code, node);
  }

  void test_visitGenericFunctionType() {
    var code = 'int Function<T>(T)';
    var parseResult = parseTestCodeWithDiagnostics('''
void f($code x) {}
''');
    var node = parseResult.findNode.singleGenericFunctionType;
    _assertSource(code, node);
  }

  void test_visitGenericFunctionType_withQuestion() {
    var code = 'int Function<T>(T)?';
    var parseResult = parseTestCodeWithDiagnostics('''
void f($code x) {}
''');
    var node = parseResult.findNode.singleGenericFunctionType;
    _assertSource(code, node);
  }

  void test_visitGenericTypeAlias() {
    var code = 'typedef X<S> = S Function<T>(T);';
    var parseResult = parseTestCodeWithDiagnostics('''
$code
''');
    var node = parseResult.findNode.singleGenericTypeAlias;
    _assertSource(code, node);
  }

  void test_visitGuardedPattern() {
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

  void test_visitIfElement_else() {
    var code = 'if (b) 1 else 0';
    var parseResult = parseTestCodeWithDiagnostics('''
final v = [ $code ];
''');
    var node = parseResult.findNode.singleIfElement;
    _assertSource(code, node);
  }

  void test_visitIfElement_then() {
    var code = 'if (b) 1';
    var parseResult = parseTestCodeWithDiagnostics('''
final v = [ $code ];
''');
    var node = parseResult.findNode.singleIfElement;
    _assertSource(code, node);
  }

  void test_visitIfStatement_withElse() {
    var code = 'if (c) {} else {}';
    var parseResult = parseTestCodeWithDiagnostics('''
void f () {
  $code
}
''');
    var node = parseResult.findNode.singleIfStatement;
    _assertSource(code, node);
  }

  void test_visitIfStatement_withoutElse() {
    var code = 'if (c) {}';
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  $code
}
''');
    var node = parseResult.findNode.singleIfStatement;
    _assertSource(code, node);
  }

  void test_visitImplementsClause_multiple() {
    var code = 'implements A, B';
    var parseResult = parseTestCodeWithDiagnostics('''
class C $code {}
''');
    var node = parseResult.findNode.singleImplementsClause;
    _assertSource(code, node);
  }

  void test_visitImplementsClause_single() {
    var code = 'implements A';
    var parseResult = parseTestCodeWithDiagnostics('''
class C $code {}
''');
    var node = parseResult.findNode.singleImplementsClause;
    _assertSource(code, node);
  }

  void test_visitImportDirective_combinator() {
    var code = "import 'a.dart' show A;";
    var parseResult = parseTestCodeWithDiagnostics('''
$code
''');
    var node = parseResult.findNode.singleImportDirective;
    _assertSource(code, node);
  }

  void test_visitImportDirective_combinators() {
    var code = "import 'a.dart' show A hide B;";
    var parseResult = parseTestCodeWithDiagnostics('''
$code
''');
    var node = parseResult.findNode.singleImportDirective;
    _assertSource(code, node);
  }

  void test_visitImportDirective_configurations() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
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
    var parseResult = parseTestCodeWithDiagnostics(code);
    var node = parseResult.findNode.singleImportDirective;
    _assertSource(code, node);
  }

  void test_visitImportDirective_minimal() {
    var code = "import 'a.dart';";
    var parseResult = parseTestCodeWithDiagnostics(code);
    var node = parseResult.findNode.singleImportDirective;
    _assertSource(code, node);
  }

  void test_visitImportDirective_prefix() {
    var code = "import 'a.dart' as p;";
    var parseResult = parseTestCodeWithDiagnostics(code);
    var node = parseResult.findNode.singleImportDirective;
    _assertSource(code, node);
  }

  void test_visitImportDirective_prefix_combinator() {
    var code = "import 'a.dart' as p show A;";
    var parseResult = parseTestCodeWithDiagnostics('''
$code
''');
    var node = parseResult.findNode.singleImportDirective;
    _assertSource(code, node);
  }

  void test_visitImportDirective_prefix_combinators() {
    var code = "import 'a.dart' as p show A hide B;";
    var parseResult = parseTestCodeWithDiagnostics('''
$code
''');
    var node = parseResult.findNode.singleImportDirective;
    _assertSource(code, node);
  }

  void test_visitImportDirective_withMetadata() {
    var code = '@deprecated import "a.dart";';
    var parseResult = parseTestCodeWithDiagnostics(code);
    var node = parseResult.findNode.singleImportDirective;
    _assertSource(code, node);
  }

  void test_visitImportHideCombinator_multiple() {
    var code = 'hide A, B';
    var parseResult = parseTestCodeWithDiagnostics('''
import 'a.dart' $code;
''');
    var node = parseResult.findNode.singleHideCombinator;
    _assertSource(code, node);
  }

  void test_visitImportHideCombinator_single() {
    var code = 'hide A';
    var parseResult = parseTestCodeWithDiagnostics('''
import 'a.dart' $code;
''');
    var node = parseResult.findNode.singleHideCombinator;
    _assertSource(code, node);
  }

  void test_visitImportShowCombinator_multiple() {
    var code = 'show A, B';
    var parseResult = parseTestCodeWithDiagnostics('''
import 'a.dart' $code;
''');
    var node = parseResult.findNode.singleShowCombinator;
    _assertSource(code, node);
  }

  void test_visitImportShowCombinator_single() {
    var code = 'show A';
    var parseResult = parseTestCodeWithDiagnostics('''
import 'a.dart' $code;
''');
    var node = parseResult.findNode.singleShowCombinator;
    _assertSource(code, node);
  }

  void test_visitIndexExpression() {
    var code = 'a[0]';
    var parseResult = parseTestCodeWithDiagnostics('''
final x = $code;
''');
    var node = parseResult.findNode.singleIndexExpression;
    _assertSource(code, node);
  }

  void test_visitInstanceCreationExpression_const() {
    var code = 'const A()';
    var parseResult = parseTestCodeWithDiagnostics('''
final x = $code;
''');
    var node = parseResult.findNode.singleInstanceCreationExpression;
    _assertSource(code, node);
  }

  void test_visitInstanceCreationExpression_named() {
    var code = 'new A.foo()';
    var parseResult = parseTestCodeWithDiagnostics('''
final x = $code;
''');
    var node = parseResult.findNode.singleInstanceCreationExpression;
    _assertSource(code, node);
  }

  void test_visitInstanceCreationExpression_unnamed() {
    var code = 'new A()';
    var parseResult = parseTestCodeWithDiagnostics('''
final x = $code;
''');
    var node = parseResult.findNode.singleInstanceCreationExpression;
    _assertSource(code, node);
  }

  void test_visitIntegerLiteral() {
    var code = '42';
    var parseResult = parseTestCodeWithDiagnostics('''
final x = $code;
''');
    var node = parseResult.findNode.singleIntegerLiteral;
    _assertSource(code, node);
  }

  void test_visitInterpolationExpression_expression() {
    var code = r'${foo}';
    var parseResult = parseTestCodeWithDiagnostics('''
final x = "$code";
''');
    var node = parseResult.findNode.singleInterpolationExpression;
    _assertSource(code, node);
  }

  void test_visitInterpolationExpression_identifier() {
    var code = r'$foo';
    var parseResult = parseTestCodeWithDiagnostics('''
final x = "$code";
''');
    var node = parseResult.findNode.singleInterpolationExpression;
    _assertSource(code, node);
  }

  void test_visitInterpolationString() {
    var code = "ccc'";
    var parseResult = parseTestCodeWithDiagnostics('''
final x = 'a\${bb}$code;
''');
    var node = parseResult.findNode.interpolationString(code);
    _assertSource(code, node);
  }

  void test_visitIsExpression_negated() {
    var code = 'a is! int';
    var parseResult = parseTestCodeWithDiagnostics('''
final x = $code;
''');
    var node = parseResult.findNode.singleIsExpression;
    _assertSource(code, node);
  }

  void test_visitIsExpression_normal() {
    var code = 'a is int';
    var parseResult = parseTestCodeWithDiagnostics('''
final x = $code;
''');
    var node = parseResult.findNode.singleIsExpression;
    _assertSource(code, node);
  }

  void test_visitLabel() {
    var code = 'myLabel:';
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  $code for (final x in []) {}
}
''');
    var node = parseResult.findNode.singleLabel;
    _assertSource(code, node);
  }

  void test_visitLabeledStatement_multiple() {
    var code = 'a: b: return;';
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  $code
}
''');
    var node = parseResult.findNode.singleLabeledStatement;
    _assertSource(code, node);
  }

  void test_visitLabeledStatement_single() {
    var code = 'a: return;';
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  $code
}
''');
    var node = parseResult.findNode.singleLabeledStatement;
    _assertSource(code, node);
  }

  void test_visitLibraryDirective() {
    var code = 'library my;';
    var parseResult = parseTestCodeWithDiagnostics('''
$code
''');
    var node = parseResult.findNode.singleLibraryDirective;
    _assertSource(code, node);
  }

  void test_visitLibraryDirective_withMetadata() {
    var code = '@deprecated library my;';
    var parseResult = parseTestCodeWithDiagnostics(code);
    var node = parseResult.findNode.singleLibraryDirective;
    _assertSource(code, node);
  }

  void test_visitListLiteral_complex() {
    var code = '<int>[0, for (e in []) 0, if (b) 1, ...[0]]';
    var parseResult = parseTestCodeWithDiagnostics('''
final v = $code;
''');
    var node = parseResult.findNode.listLiteral(code);
    _assertSource(code, node);
  }

  void test_visitListLiteral_const() {
    var code = 'const []';
    var parseResult = parseTestCodeWithDiagnostics('''
final x = $code;
''');
    var node = parseResult.findNode.singleListLiteral;
    _assertSource(code, node);
  }

  void test_visitListLiteral_empty() {
    var code = '[]';
    var parseResult = parseTestCodeWithDiagnostics('''
final x = $code;
''');
    var node = parseResult.findNode.singleListLiteral;
    _assertSource(code, node);
  }

  void test_visitListLiteral_nonEmpty() {
    var code = '[0, 1, 2]';
    var parseResult = parseTestCodeWithDiagnostics('''
final x = $code;
''');
    var node = parseResult.findNode.singleListLiteral;
    _assertSource(code, node);
  }

  void test_visitListLiteral_withConst_withoutTypeArgs() {
    var code = 'const [0]';
    var parseResult = parseTestCodeWithDiagnostics('''
final x = $code;
''');
    var node = parseResult.findNode.singleListLiteral;
    _assertSource(code, node);
  }

  void test_visitListLiteral_withConst_withTypeArgs() {
    var code = 'const <int>[0]';
    var parseResult = parseTestCodeWithDiagnostics('''
final x = $code;
''');
    var node = parseResult.findNode.singleListLiteral;
    _assertSource(code, node);
  }

  void test_visitListLiteral_withoutConst_withoutTypeArgs() {
    var code = '[0]';
    var parseResult = parseTestCodeWithDiagnostics('''
final x = $code;
''');
    var node = parseResult.findNode.singleListLiteral;
    _assertSource(code, node);
  }

  void test_visitListLiteral_withoutConst_withTypeArgs() {
    var code = '<int>[0]';
    var parseResult = parseTestCodeWithDiagnostics('''
final x = $code;
''');
    var node = parseResult.findNode.singleListLiteral;
    _assertSource(code, node);
  }

  void test_visitListPattern_empty() {
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

  void test_visitListPattern_nonEmpty() {
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

  void test_visitListPattern_withTypeArguments() {
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

  void test_visitLogicalAndPattern() {
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

  void test_visitLogicalOrPattern() {
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

  void test_visitMapLiteral_const() {
    var code = 'const {}';
    var parseResult = parseTestCodeWithDiagnostics('''
final x = $code;
''');
    var node = parseResult.findNode.singleSetOrMapLiteral;
    _assertSource(code, node);
  }

  void test_visitMapLiteral_empty() {
    var code = '{}';
    var parseResult = parseTestCodeWithDiagnostics('''
final x = $code;
''');
    var node = parseResult.findNode.singleSetOrMapLiteral;
    _assertSource(code, node);
  }

  void test_visitMapLiteral_nonEmpty() {
    var code = '{0 : a, 1 : b, 2 : c}';
    var parseResult = parseTestCodeWithDiagnostics('''
final x = $code;
''');
    var node = parseResult.findNode.singleSetOrMapLiteral;
    _assertSource(code, node);
  }

  void test_visitMapLiteralEntry() {
    var code = '0 : a';
    var parseResult = parseTestCodeWithDiagnostics('''
final x = {$code};
''');
    var node = parseResult.findNode.singleMapLiteralEntry;
    _assertSource(code, node);
  }

  void test_visitMapPattern_empty() {
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

  void test_visitMapPattern_notEmpty() {
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

  void test_visitMapPattern_withTypeArguments() {
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

  void test_visitMapPatternEntry() {
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

  void test_visitMethodDeclaration_augment() {
    var code = 'augment void foo() {}';
    var parseResult = parseTestCodeWithDiagnostics('''
class A {
  $code
}
''');
    var node = parseResult.findNode.singleMethodDeclaration;
    _assertSource(code, node);
  }

  void test_visitMethodDeclaration_external() {
    var code = 'external foo();';
    var parseResult = parseTestCodeWithDiagnostics('''
class A {
  $code
}
''');
    var node = parseResult.findNode.singleMethodDeclaration;
    _assertSource(code, node);
  }

  void test_visitMethodDeclaration_external_returnType() {
    var code = 'external int foo();';
    var parseResult = parseTestCodeWithDiagnostics('''
class A {
  $code
}
''');
    var node = parseResult.findNode.singleMethodDeclaration;
    _assertSource(code, node);
  }

  void test_visitMethodDeclaration_getter() {
    var code = 'get foo => 0;';
    var parseResult = parseTestCodeWithDiagnostics('''
class A {
  $code
}
''');
    var node = parseResult.findNode.singleMethodDeclaration;
    _assertSource(code, node);
  }

  void test_visitMethodDeclaration_getter_returnType() {
    var code = 'int get foo => 0;';
    var parseResult = parseTestCodeWithDiagnostics('''
class A {
  $code
}
''');
    var node = parseResult.findNode.singleMethodDeclaration;
    _assertSource(code, node);
  }

  void test_visitMethodDeclaration_minimal() {
    var code = 'foo() {}';
    var parseResult = parseTestCodeWithDiagnostics('''
class A {
  $code
}
''');
    var node = parseResult.findNode.singleMethodDeclaration;
    _assertSource(code, node);
  }

  void test_visitMethodDeclaration_multipleParameters() {
    var code = 'void foo(int a, double b) {}';
    var parseResult = parseTestCodeWithDiagnostics('''
class A {
  $code
}
''');
    var node = parseResult.findNode.singleMethodDeclaration;
    _assertSource(code, node);
  }

  void test_visitMethodDeclaration_operator() {
    var code = 'operator +(int other) {}';
    var parseResult = parseTestCodeWithDiagnostics('''
class A {
  $code
}
''');
    var node = parseResult.findNode.singleMethodDeclaration;
    _assertSource(code, node);
  }

  void test_visitMethodDeclaration_operator_returnType() {
    var code = 'int operator +(int other) => 0;';
    var parseResult = parseTestCodeWithDiagnostics('''
class A {
  $code
}
''');
    var node = parseResult.findNode.singleMethodDeclaration;
    _assertSource(code, node);
  }

  void test_visitMethodDeclaration_returnType() {
    var code = 'int foo() => 0;';
    var parseResult = parseTestCodeWithDiagnostics('''
class A {
  $code
}
''');
    var node = parseResult.findNode.singleMethodDeclaration;
    _assertSource(code, node);
  }

  void test_visitMethodDeclaration_setter() {
    var code = 'set foo(int _) {}';
    var parseResult = parseTestCodeWithDiagnostics('''
class A {
  $code
}
''');
    var node = parseResult.findNode.singleMethodDeclaration;
    _assertSource(code, node);
  }

  void test_visitMethodDeclaration_setter_returnType() {
    var code = 'void set foo(int _) {}';
    var parseResult = parseTestCodeWithDiagnostics('''
class A {
  $code
}
''');
    var node = parseResult.findNode.singleMethodDeclaration;
    _assertSource(code, node);
  }

  void test_visitMethodDeclaration_static() {
    var code = 'static foo() {}';
    var parseResult = parseTestCodeWithDiagnostics('''
class A {
  $code
}
''');
    var node = parseResult.findNode.singleMethodDeclaration;
    _assertSource(code, node);
  }

  void test_visitMethodDeclaration_static_returnType() {
    var code = 'static void foo() {}';
    var parseResult = parseTestCodeWithDiagnostics('''
class A {
  $code
}
''');
    var node = parseResult.findNode.singleMethodDeclaration;
    _assertSource(code, node);
  }

  void test_visitMethodDeclaration_typeParameters() {
    var code = 'void foo<T>() {}';
    var parseResult = parseTestCodeWithDiagnostics('''
class A {
  $code
}
''');
    var node = parseResult.findNode.singleMethodDeclaration;
    _assertSource(code, node);
  }

  void test_visitMethodDeclaration_withMetadata() {
    var code = '@deprecated void foo() {}';
    var parseResult = parseTestCodeWithDiagnostics('''
class A {
  $code
}
''');
    var node = parseResult.findNode.singleMethodDeclaration;
    _assertSource(code, node);
  }

  void test_visitMethodInvocation_conditional() {
    var code = 'a?.foo()';
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  $code;
}
''');
    var node = parseResult.findNode.singleMethodInvocation;
    _assertSource(code, node);
  }

  void test_visitMethodInvocation_noTarget() {
    var code = 'foo()';
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  $code;
}
''');
    var node = parseResult.findNode.singleMethodInvocation;
    _assertSource(code, node);
  }

  void test_visitMethodInvocation_target() {
    var code = 'a.foo()';
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  $code;
}
''');
    var node = parseResult.findNode.singleMethodInvocation;
    _assertSource(code, node);
  }

  void test_visitMethodInvocation_typeArguments() {
    var code = 'foo<int>()';
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  $code;
}
''');
    var node = parseResult.findNode.singleMethodInvocation;
    _assertSource(code, node);
  }

  void test_visitMixinDeclaration_augment() {
    var code = 'augment mixin M {}';
    var parseResult = parseTestCodeWithDiagnostics(code);
    var node = parseResult.findNode.singleMixinDeclaration;
    _assertSource(code, node);
  }

  void test_visitMixinDeclaration_augment_base() {
    var code = 'augment base mixin M {}';
    var parseResult = parseTestCodeWithDiagnostics(code);
    var node = parseResult.findNode.singleMixinDeclaration;
    _assertSource(code, node);
  }

  void test_visitMixinDeclaration_base() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
base mixin M {}
''');
    var node = parseResult.findNode.singleMixinDeclaration;
    _assertSource('base mixin M {}', node);
  }

  void test_visitNamedExpression() {
    var code = 'a: 0';
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  foo($code);
}
''');
    var node = parseResult.findNode.singleNamedArgument;
    _assertSource(code, node);
  }

  void test_visitNamedFormalParameter() {
    var code = 'a = 0';
    var parseResult = parseTestCodeWithDiagnostics('''
void f({$code}) {}
''');
    var node = parseResult.findNode.singleFormalParameter;
    _assertSource(code, node);
  }

  void test_visitNamedType_multipleArgs() {
    var code = 'Map<int, String>';
    var parseResult = parseTestCodeWithDiagnostics('''
final x = <$code>[];
''');
    var node = parseResult.findNode.namedType(code);
    _assertSource(code, node);
  }

  void test_visitNamedType_nestedArg() {
    var code = 'List<Set<int>>';
    var parseResult = parseTestCodeWithDiagnostics('''
final x = <$code>[];
''');
    var node = parseResult.findNode.namedType(code);
    _assertSource(code, node);
  }

  void test_visitNamedType_noArgs() {
    var code = 'int';
    var parseResult = parseTestCodeWithDiagnostics('''
final x = <$code>[];
''');
    var node = parseResult.findNode.singleNamedType;
    _assertSource(code, node);
  }

  void test_visitNamedType_noArgs_withQuestion() {
    var code = 'int?';
    var parseResult = parseTestCodeWithDiagnostics('''
final x = <$code>[];
''');
    var node = parseResult.findNode.singleNamedType;
    _assertSource(code, node);
  }

  void test_visitNamedType_singleArg() {
    var code = 'Set<int>';
    var parseResult = parseTestCodeWithDiagnostics('''
final x = <$code>[];
''');
    var node = parseResult.findNode.namedType(code);
    _assertSource(code, node);
  }

  void test_visitNamedType_singleArg_withQuestion() {
    var code = 'Set<int>?';
    var parseResult = parseTestCodeWithDiagnostics('''
final x = <$code>[];
''');
    var node = parseResult.findNode.namedType(code);
    _assertSource(code, node);
  }

  void test_visitNativeClause() {
    var code = "native 'code'";
    var parseResult = parseTestCodeWithDiagnostics('''
class A $code {}
''');
    var node = parseResult.findNode.singleNativeClause;
    _assertSource(code, node);
  }

  void test_visitNativeFunctionBody() {
    var code = "native 'code';";
    var parseResult = parseTestCodeWithDiagnostics('''
void foo() $code
''');
    var node = parseResult.findNode.singleNativeFunctionBody;
    _assertSource(code, node);
  }

  void test_visitNullAssertPattern() {
    var code = 'y!';
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  if (x case $code) {}
}
''');
    var node = parseResult.findNode.singleNullAssertPattern;
    _assertSource(code, node);
  }

  void test_visitNullCheckPattern() {
    var code = '_?';
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  if (x case $code) {}
}
''');
    var node = parseResult.findNode.singleNullCheckPattern;
    _assertSource(code, node);
  }

  void test_visitNullLiteral() {
    var code = 'null';
    var parseResult = parseTestCodeWithDiagnostics('''
final x = $code;
''');
    var node = parseResult.findNode.singleNullLiteral;
    _assertSource(code, node);
  }

  void test_visitObjectPattern() {
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

  void test_visitParenthesizedExpression() {
    var code = '(a)';
    var parseResult = parseTestCodeWithDiagnostics('''
final x = $code;
''');
    var node = parseResult.findNode.singleParenthesizedExpression;
    _assertSource(code, node);
  }

  void test_visitParenthesizedPattern() {
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

  void test_visitPartDirective() {
    var code = "part 'a.dart';";
    var parseResult = parseTestCodeWithDiagnostics(code);
    var node = parseResult.findNode.singlePartDirective;
    _assertSource(code, node);
  }

  void test_visitPartDirective_withMetadata() {
    var code = '@deprecated part "a.dart";';
    var parseResult = parseTestCodeWithDiagnostics(code);
    var node = parseResult.findNode.singlePartDirective;
    _assertSource(code, node);
  }

  void test_visitPartOfDirective_name() {
    var parseResult = parseTestCodeWithDiagnostics(
      'part of l;',
      featureSet: FeatureSets.language_3_4,
    );
    var unit = parseResult.findNode.unit;
    var directive = unit.directives[0] as PartOfDirective;
    _assertSource("part of l;", directive);
  }

  void test_visitPartOfDirective_uri() {
    var parseResult = parseTestCodeWithDiagnostics("part of 'a.dart';");
    var unit = parseResult.findNode.unit;
    var directive = unit.directives[0] as PartOfDirective;
    _assertSource("part of 'a.dart';", directive);
  }

  void test_visitPartOfDirective_withMetadata() {
    var code = "@deprecated part of 'a.dart';";
    var parseResult = parseTestCodeWithDiagnostics(code);
    var node = parseResult.findNode.singlePartOfDirective;
    _assertSource(code, node);
  }

  void test_visitPatternAssignment() {
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

  void test_visitPatternAssignmentStatement() {
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

  void test_visitPatternField_named() {
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

  void test_visitPatternField_positional() {
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

  void test_visitPatternFieldName() {
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

  void test_visitPatternVariableDeclaration() {
    var code = 'var (a, b) = (0, 1)';
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  $code;
}
''');
    var node = parseResult.findNode.singlePatternVariableDeclaration;
    _assertSource(code, node);
  }

  void test_visitPatternVariableDeclarationStatement() {
    var code = 'var (a, b) = (0, 1);';
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  $code
}
''');
    var node = parseResult.findNode.singlePatternVariableDeclarationStatement;
    _assertSource(code, node);
  }

  void test_visitPositionalFormalParameter() {
    var code = 'a = 0';
    var parseResult = parseTestCodeWithDiagnostics('''
void f([$code]) {}
''');
    var node = parseResult.findNode.singleFormalParameter;
    _assertSource(code, node);
  }

  void test_visitPostfixExpression() {
    var code = 'a++';
    var parseResult = parseTestCodeWithDiagnostics('''
int f() {
  $code;
}
''');
    var node = parseResult.findNode.singlePostfixExpression;
    _assertSource(code, node);
  }

  void test_visitPostfixPattern() {
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

  void test_visitPrefixedIdentifier() {
    var code = 'foo.bar';
    var parseResult = parseTestCodeWithDiagnostics('''
int f() {
  $code;
}
''');
    var node = parseResult.findNode.singlePrefixedIdentifier;
    _assertSource(code, node);
  }

  void test_visitPrefixExpression() {
    var code = '-foo';
    var parseResult = parseTestCodeWithDiagnostics('''
int f() {
  $code;
}
''');
    var node = parseResult.findNode.singlePrefixExpression;
    _assertSource(code, node);
  }

  void test_visitPrefixExpression_precedence() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var v = !(a == b);
''');
    var node = parseResult.findNode.singlePrefixExpression;
    _assertSource('!(a == b)', node);
  }

  void test_visitPrimaryConstructorBody_block() {
    var code = 'this {foo();}';
    var parseResult = parseTestCodeWithDiagnostics('''
class A() {
  $code
}
''');
    var node = parseResult.findNode.singlePrimaryConstructorBody;
    _assertSource(code, node);
  }

  void test_visitPrimaryConstructorBody_initializers() {
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

  void test_visitPrimaryConstructorBody_metadata() {
    var code = '@deprecated this;';
    var parseResult = parseTestCodeWithDiagnostics('''
class A() {
  $code
}
''');
    var node = parseResult.findNode.singlePrimaryConstructorBody;
    _assertSource(code, node);
  }

  void test_visitPrimaryConstructorBody_simple() {
    var code = 'this;';
    var parseResult = parseTestCodeWithDiagnostics('''
class A() {
  $code
}
''');
    var node = parseResult.findNode.singlePrimaryConstructorBody;
    _assertSource(code, node);
  }

  void test_visitPropertyAccess() {
    var code = '(foo).bar';
    var parseResult = parseTestCodeWithDiagnostics('''
final x = $code;
''');
    var node = parseResult.findNode.singlePropertyAccess;
    _assertSource(code, node);
  }

  void test_visitPropertyAccess_conditional() {
    var code = 'foo?.bar';
    var parseResult = parseTestCodeWithDiagnostics('''
final x = $code;
''');
    var node = parseResult.findNode.singlePropertyAccess;
    _assertSource(code, node);
  }

  void test_visitRecordLiteral_mixed() {
    var code = '(0, true, a: 0, b: true)';
    var parseResult = parseTestCodeWithDiagnostics('''
final x = $code;
''');
    var node = parseResult.findNode.singleRecordLiteral;
    _assertSource(code, node);
  }

  void test_visitRecordLiteral_named() {
    var code = '(a: 0, b: true)';
    var parseResult = parseTestCodeWithDiagnostics('''
final x = $code;
''');
    var node = parseResult.findNode.singleRecordLiteral;
    _assertSource(code, node);
  }

  void test_visitRecordLiteral_positional() {
    var code = '(0, true)';
    var parseResult = parseTestCodeWithDiagnostics('''
final x = $code;
''');
    var node = parseResult.findNode.singleRecordLiteral;
    _assertSource(code, node);
  }

  void test_visitRecordPattern() {
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

  void test_visitRecordTypeAnnotation_mixed() {
    var code = '(int, bool, {int a, bool b})';
    var parseResult = parseTestCodeWithDiagnostics('''
$code f() {}
''');
    var node = parseResult.findNode.singleRecordTypeAnnotation;
    _assertSource(code, node);
  }

  void test_visitRecordTypeAnnotation_named() {
    var code = '({int a, bool b})';
    var parseResult = parseTestCodeWithDiagnostics('''
$code f() {}
''');
    var node = parseResult.findNode.singleRecordTypeAnnotation;
    _assertSource(code, node);
  }

  void test_visitRecordTypeAnnotation_positional() {
    var code = '(int, bool)';
    var parseResult = parseTestCodeWithDiagnostics('''
$code f() {}
''');
    var node = parseResult.findNode.singleRecordTypeAnnotation;
    _assertSource(code, node);
  }

  void test_visitRecordTypeAnnotation_positional_nullable() {
    var code = '(int, bool)?';
    var parseResult = parseTestCodeWithDiagnostics('''
$code f() {}
''');
    var node = parseResult.findNode.singleRecordTypeAnnotation;
    _assertSource(code, node);
  }

  void test_visitRedirectingConstructorInvocation_named() {
    var code = 'this.named()';
    var parseResult = parseTestCodeWithDiagnostics('''
class A {
  A() : $code;
}
''');
    var node = parseResult.findNode.singleRedirectingConstructorInvocation;
    _assertSource(code, node);
  }

  void test_visitRedirectingConstructorInvocation_unnamed() {
    var code = 'this()';
    var parseResult = parseTestCodeWithDiagnostics('''
class A {
  A.named() : $code;
}
''');
    var node = parseResult.findNode.singleRedirectingConstructorInvocation;
    _assertSource(code, node);
  }

  void test_visitRelationalPattern() {
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

  void test_visitRestPatternElement() {
    var code = '...rest';
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  if (x case [0, $code]) {}
}
''');
    var node = parseResult.findNode.singleRestPatternElement;
    _assertSource(code, node);
  }

  void test_visitRethrowExpression() {
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

  void test_visitReturnStatement_expression() {
    var code = 'return 0;';
    var parseResult = parseTestCodeWithDiagnostics('''
int f() {
  $code
}
''');
    var node = parseResult.findNode.singleReturnStatement;
    _assertSource(code, node);
  }

  void test_visitReturnStatement_noExpression() {
    var code = 'return;';
    var parseResult = parseTestCodeWithDiagnostics('''
int f() {
  $code
}
''');
    var node = parseResult.findNode.singleReturnStatement;
    _assertSource(code, node);
  }

  void test_visitSetOrMapLiteral_map_complex() {
    var code =
        "<String, String>{'a' : 'b', for (c in d) 'e' : 'f', if (g) 'h' : 'i', ...{'j' : 'k'}}";
    var parseResult = parseTestCodeWithDiagnostics('''
final v = $code;
''');
    var node = parseResult.findNode.setOrMapLiteral(code);
    _assertSource(code, node);
  }

  void test_visitSetOrMapLiteral_map_withConst_withoutTypeArgs() {
    var code = 'const {0 : a}';
    var parseResult = parseTestCodeWithDiagnostics('''
final x = $code;
''');
    var node = parseResult.findNode.singleSetOrMapLiteral;
    _assertSource(code, node);
  }

  void test_visitSetOrMapLiteral_map_withConst_withTypeArgs() {
    var code = 'const <int, String>{0 : a}';
    var parseResult = parseTestCodeWithDiagnostics('''
final x = $code;
''');
    var node = parseResult.findNode.singleSetOrMapLiteral;
    _assertSource(code, node);
  }

  void test_visitSetOrMapLiteral_map_withoutConst_withoutTypeArgs() {
    var code = '{0 : a}';
    var parseResult = parseTestCodeWithDiagnostics('''
final x = $code;
''');
    var node = parseResult.findNode.singleSetOrMapLiteral;
    _assertSource(code, node);
  }

  void test_visitSetOrMapLiteral_map_withoutConst_withTypeArgs() {
    var code = '<int, String>{0 : a}';
    var parseResult = parseTestCodeWithDiagnostics('''
final x = $code;
''');
    var node = parseResult.findNode.singleSetOrMapLiteral;
    _assertSource(code, node);
  }

  void test_visitSetOrMapLiteral_set_complex() {
    var code = '<int>{0, for (e in l) 0, if (b) 1, ...[0]}';
    var parseResult = parseTestCodeWithDiagnostics('''
final v = $code;
''');
    var node = parseResult.findNode.singleSetOrMapLiteral;
    _assertSource(code, node);
  }

  void test_visitSetOrMapLiteral_set_withConst_withoutTypeArgs() {
    var code = 'const {0}';
    var parseResult = parseTestCodeWithDiagnostics('''
final x = $code;
''');
    var node = parseResult.findNode.singleSetOrMapLiteral;
    _assertSource(code, node);
  }

  void test_visitSetOrMapLiteral_set_withConst_withTypeArgs() {
    var code = 'const <int>{0}';
    var parseResult = parseTestCodeWithDiagnostics('''
final x = $code;
''');
    var node = parseResult.findNode.singleSetOrMapLiteral;
    _assertSource(code, node);
  }

  void test_visitSetOrMapLiteral_set_withoutConst_withoutTypeArgs() {
    var code = '{0}';
    var parseResult = parseTestCodeWithDiagnostics('''
final x = $code;
''');
    var node = parseResult.findNode.singleSetOrMapLiteral;
    _assertSource(code, node);
  }

  void test_visitSetOrMapLiteral_set_withoutConst_withTypeArgs() {
    var code = '<int>{0}';
    var parseResult = parseTestCodeWithDiagnostics('''
final x = $code;
''');
    var node = parseResult.findNode.singleSetOrMapLiteral;
    _assertSource(code, node);
  }

  void test_visitSimpleFormalParameter_annotation() {
    var code = '@deprecated int x';
    var parseResult = parseTestCodeWithDiagnostics('''
void f($code) {}
''');
    var node = parseResult.findNode.singleRegularFormalParameter;
    _assertSource(code, node);
  }

  void test_visitSimpleFormalParameter_keyword() {
    var code = 'var a';
    var parseResult = parseTestCodeWithDiagnostics('''
// @dart = 3.10
void f($code) {}
''');
    var node = parseResult.findNode.singleRegularFormalParameter;
    _assertSource(code, node);
  }

  void test_visitSimpleFormalParameter_keyword_type() {
    var code = 'final int a';
    var parseResult = parseTestCodeWithDiagnostics('''
// @dart = 3.10
void f($code) {}
''');
    var node = parseResult.findNode.singleRegularFormalParameter;
    _assertSource(code, node);
  }

  void test_visitSimpleFormalParameter_type() {
    var code = 'int a';
    var parseResult = parseTestCodeWithDiagnostics('''
void f($code) {}
''');
    var node = parseResult.findNode.singleRegularFormalParameter;
    _assertSource(code, node);
  }

  void test_visitSimpleFormalParameter_type_covariant() {
    var code = 'covariant int a';
    var parseResult = parseTestCodeWithDiagnostics('''
class A {
  void foo($code) {}
}
''');
    var node = parseResult.findNode.singleRegularFormalParameter;
    _assertSource(code, node);
  }

  void test_visitSimpleIdentifier() {
    var code = 'foo';
    var parseResult = parseTestCodeWithDiagnostics('''
var x = $code;
''');
    var node = parseResult.findNode.singleSimpleIdentifier;
    _assertSource(code, node);
  }

  void test_visitSimpleStringLiteral() {
    var code = "'str'";
    var parseResult = parseTestCodeWithDiagnostics('''
final x = $code;
''');
    var node = parseResult.findNode.singleSimpleStringLiteral;
    _assertSource(code, node);
  }

  void test_visitSpreadElement_nonNullable() {
    var code = '...[0]';
    var parseResult = parseTestCodeWithDiagnostics('''
final x = [$code];
''');
    var node = parseResult.findNode.singleSpreadElement;
    _assertSource(code, node);
  }

  void test_visitSpreadElement_nullable() {
    var code = '...?[0]';
    var parseResult = parseTestCodeWithDiagnostics('''
final x = [$code];
''');
    var node = parseResult.findNode.singleSpreadElement;
    _assertSource(code, node);
  }

  void test_visitStringInterpolation() {
    var code = r"'a${bb}ccc'";
    var parseResult = parseTestCodeWithDiagnostics('''
final x = $code;
''');
    var node = parseResult.findNode.singleStringInterpolation;
    _assertSource(code, node);
  }

  void test_visitSuperConstructorInvocation() {
    var code = 'super(0)';
    var parseResult = parseTestCodeWithDiagnostics('''
class A extends B {
  A() : $code;
}
''');
    var node = parseResult.findNode.singleSuperConstructorInvocation;
    _assertSource(code, node);
  }

  void test_visitSuperConstructorInvocation_named() {
    var code = 'super.named(0)';
    var parseResult = parseTestCodeWithDiagnostics('''
class A extends B {
  A() : $code;
}
''');
    var node = parseResult.findNode.singleSuperConstructorInvocation;
    _assertSource(code, node);
  }

  void test_visitSuperExpression() {
    var parseResult = parseTestCodeWithDiagnostics('''
class A {
  void foo() {
    super.foo();
  }
}
''');
    var node = parseResult.findNode.singleSuperExpression;
    _assertSource('super', node);
  }

  void test_visitSuperFormalParameter_annotation() {
    var code = '@deprecated super.foo';
    var parseResult = parseTestCodeWithDiagnostics('''
class A {
  A($code);
}
''');
    var node = parseResult.findNode.singleSuperFormalParameter;
    _assertSource(code, node);
  }

  void test_visitSuperFormalParameter_functionTyped() {
    var code = 'int super.a(b)';
    var parseResult = parseTestCodeWithDiagnostics('''
class A {
  A($code);
}
''');
    var node = parseResult.findNode.singleSuperFormalParameter;
    _assertSource(code, node);
  }

  void test_visitSuperFormalParameter_functionTyped_typeParameters() {
    var code = 'int super.a<E, F>(b)';
    var parseResult = parseTestCodeWithDiagnostics('''
class A {
  A($code);
}
''');
    var node = parseResult.findNode.singleSuperFormalParameter;
    _assertSource(code, node);
  }

  void test_visitSuperFormalParameter_keyword() {
    var code = 'final super.foo';
    var parseResult = parseTestCodeWithDiagnostics('''
// @dart = 3.10
class A {
  A($code);
}
''');
    var node = parseResult.findNode.singleSuperFormalParameter;
    _assertSource(code, node);
  }

  void test_visitSuperFormalParameter_keywordAndType() {
    var code = 'final int super.a';
    var parseResult = parseTestCodeWithDiagnostics('''
// @dart = 3.10
class A {
  A($code);
}
''');
    var node = parseResult.findNode.singleSuperFormalParameter;
    _assertSource(code, node);
  }

  void test_visitSuperFormalParameter_type() {
    var code = 'int super.a';
    var parseResult = parseTestCodeWithDiagnostics('''
class A {
  A($code);
}
''');
    var node = parseResult.findNode.singleSuperFormalParameter;
    _assertSource(code, node);
  }

  void test_visitSuperFormalParameter_type_covariant() {
    var code = 'covariant int super.a';
    var parseResult = parseTestCodeWithDiagnostics('''
class A {
  A($code);
}
''');
    var node = parseResult.findNode.singleSuperFormalParameter;
    _assertSource(code, node);
  }

  void test_visitSwitchCase_multipleLabels() {
    var code = 'l1: l2: case a: {}';
    var parseResult = parseTestCodeWithDiagnostics('''
// @dart = 2.19
void f() {
  switch (x) {
    $code
  }
}
''');
    var node = parseResult.findNode.singleSwitchCase;
    _assertSource(code, node);
  }

  void test_visitSwitchCase_multipleStatements() {
    var code = 'case a: foo(); bar();';
    var parseResult = parseTestCodeWithDiagnostics('''
// @dart = 2.19
void f() {
  switch (x) {
    $code
  }
}
''');
    var node = parseResult.findNode.singleSwitchCase;
    _assertSource(code, node);
  }

  void test_visitSwitchCase_noLabels() {
    var code = 'case a: {}';
    var parseResult = parseTestCodeWithDiagnostics('''
// @dart = 2.19
void f() {
  switch (x) {
    $code
  }
}
''');
    var node = parseResult.findNode.singleSwitchCase;
    _assertSource(code, node);
  }

  void test_visitSwitchCase_singleLabel() {
    var code = 'l1: case a: {}';
    var parseResult = parseTestCodeWithDiagnostics('''
// @dart = 2.19
void f() {
  switch (x) {
    $code
  }
}
''');
    var node = parseResult.findNode.singleSwitchCase;
    _assertSource(code, node);
  }

  void test_visitSwitchDefault_multipleLabels() {
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

  void test_visitSwitchDefault_multipleStatements() {
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

  void test_visitSwitchDefault_noLabels() {
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

  void test_visitSwitchDefault_singleLabel() {
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

  void test_visitSwitchExpression() {
    var code = 'switch (x) {0 => 1, _ => 2}';
    var parseResult = parseTestCodeWithDiagnostics('''
var result = $code;
''');
    var node = parseResult.findNode.singleSwitchExpression;
    _assertSource(code, node);
  }

  void test_visitSwitchExpressionCase() {
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

  void test_visitSwitchPatternCase_multipleLabels() {
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

  void test_visitSwitchPatternCase_multipleStatements() {
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

  void test_visitSwitchPatternCase_noLabels() {
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

  void test_visitSwitchPatternCase_singleLabel() {
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

  void test_visitSwitchStatement() {
    var code = 'switch (x) {case 0: foo(); default: bar();}';
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  $code
}
''');
    var node = parseResult.findNode.singleSwitchStatement;
    _assertSource(code, node);
  }

  void test_visitSymbolLiteral_multiple() {
    var code = '#a.b.c';
    var parseResult = parseTestCodeWithDiagnostics('''
final x = $code;
''');
    var node = parseResult.findNode.singleSymbolLiteral;
    _assertSource(code, node);
  }

  void test_visitSymbolLiteral_single() {
    var code = '#a';
    var parseResult = parseTestCodeWithDiagnostics('''
final x = $code;
''');
    var node = parseResult.findNode.singleSymbolLiteral;
    _assertSource(code, node);
  }

  void test_visitThisExpression() {
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

  void test_visitThrowStatement() {
    var code = 'throw 0';
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  $code;
}
''');
    var node = parseResult.findNode.singleThrowExpression;
    _assertSource(code, node);
  }

  void test_visitTopLevelVariableDeclaration_abstract() {
    var code = 'abstract var a;';
    var parseResult = parseTestCodeWithDiagnostics('''
$code
''');
    var node = parseResult.findNode.singleTopLevelVariableDeclaration;
    _assertSource(code, node);
  }

  void test_visitTopLevelVariableDeclaration_augment() {
    var code = 'augment var a = 0;';
    var parseResult = parseTestCodeWithDiagnostics('''
$code
''');
    var node = parseResult.findNode.singleTopLevelVariableDeclaration;
    _assertSource(code, node);
  }

  void test_visitTopLevelVariableDeclaration_external() {
    var code = 'external var a;';
    var parseResult = parseTestCodeWithDiagnostics('''
$code
''');
    var node = parseResult.findNode.singleTopLevelVariableDeclaration;
    _assertSource(code, node);
  }

  void test_visitTopLevelVariableDeclaration_external_abstract() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
external abstract var a;
//       ^^^^^^^^
// [diag.abstractExternalField] Fields can't be declared both 'abstract' and 'external'.
''');
    var node = parseResult.findNode.singleTopLevelVariableDeclaration;
    _assertSource('external abstract var a;', node);
  }

  void test_visitTopLevelVariableDeclaration_multiple() {
    var code = 'var a = 0, b = 1;';
    var parseResult = parseTestCodeWithDiagnostics('''
$code
''');
    var node = parseResult.findNode.singleTopLevelVariableDeclaration;
    _assertSource(code, node);
  }

  void test_visitTopLevelVariableDeclaration_single() {
    var code = 'var a;';
    var parseResult = parseTestCodeWithDiagnostics('''
$code
''');
    var node = parseResult.findNode.singleTopLevelVariableDeclaration;
    _assertSource(code, node);
  }

  void test_visitTopLevelVariableDeclaration_withMetadata() {
    var code = '@deprecated var a;';
    var parseResult = parseTestCodeWithDiagnostics('''
$code
''');
    var node = parseResult.findNode.singleTopLevelVariableDeclaration;
    _assertSource(code, node);
  }

  void test_visitTryStatement_catch() {
    var code = 'try {} on E {}';
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  $code
}
''');
    var node = parseResult.findNode.singleTryStatement;
    _assertSource(code, node);
  }

  void test_visitTryStatement_catches() {
    var code = 'try {} on E {} on F {}';
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  $code
}
''');
    var node = parseResult.findNode.singleTryStatement;
    _assertSource(code, node);
  }

  void test_visitTryStatement_catchFinally() {
    var code = 'try {} on E {} finally {}';
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  $code
}
''');
    var node = parseResult.findNode.singleTryStatement;
    _assertSource(code, node);
  }

  void test_visitTryStatement_finally() {
    var code = 'try {} finally {}';
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  $code
}
''');
    var node = parseResult.findNode.singleTryStatement;
    _assertSource(code, node);
  }

  void test_visitTypeArgumentList_multiple() {
    var code = '<int, String>';
    var parseResult = parseTestCodeWithDiagnostics('''
final x = $code[];
''');
    var node = parseResult.findNode.singleTypeArgumentList;
    _assertSource(code, node);
  }

  void test_visitTypeArgumentList_single() {
    var code = '<int>';
    var parseResult = parseTestCodeWithDiagnostics('''
final x = $code[];
''');
    var node = parseResult.findNode.singleTypeArgumentList;
    _assertSource(code, node);
  }

  void test_visitTypeParameter_variance_contravariant() {
    var code = 'in T';
    var parseResult = parseTestCodeWithDiagnostics('''
class A<$code> {}
''');
    var node = parseResult.findNode.singleTypeParameter;
    _assertSource(code, node);
  }

  void test_visitTypeParameter_variance_covariant() {
    var code = 'out T';
    var parseResult = parseTestCodeWithDiagnostics('''
class A<$code> {}
''');
    var node = parseResult.findNode.singleTypeParameter;
    _assertSource(code, node);
  }

  void test_visitTypeParameter_variance_invariant() {
    var code = 'inout T';
    var parseResult = parseTestCodeWithDiagnostics('''
class A<$code> {}
''');
    var node = parseResult.findNode.singleTypeParameter;
    _assertSource(code, node);
  }

  void test_visitTypeParameter_withExtends() {
    var code = 'T extends num';
    var parseResult = parseTestCodeWithDiagnostics('''
class A<$code> {}
''');
    var node = parseResult.findNode.singleTypeParameter;
    _assertSource(code, node);
  }

  void test_visitTypeParameter_withMetadata() {
    var code = '@deprecated T';
    var parseResult = parseTestCodeWithDiagnostics('''
class A<$code> {}
''');
    var node = parseResult.findNode.singleTypeParameter;
    _assertSource(code, node);
  }

  void test_visitTypeParameter_withoutExtends() {
    var code = 'T';
    var parseResult = parseTestCodeWithDiagnostics('''
class A<$code> {}
''');
    var node = parseResult.findNode.singleTypeParameter;
    _assertSource(code, node);
  }

  void test_visitTypeParameterList_multiple() {
    var code = '<T, U>';
    var parseResult = parseTestCodeWithDiagnostics('''
class A$code {}
''');
    var node = parseResult.findNode.singleTypeParameterList;
    _assertSource(code, node);
  }

  void test_visitTypeParameterList_single() {
    var code = '<T>';
    var parseResult = parseTestCodeWithDiagnostics('''
class A$code {}
''');
    var node = parseResult.findNode.singleTypeParameterList;
    _assertSource(code, node);
  }

  void test_visitVariableDeclaration_initialized() {
    var code = 'foo = bar';
    var parseResult = parseTestCodeWithDiagnostics('''
var $code;
''');
    var node = parseResult.findNode.singleVariableDeclaration;
    _assertSource(code, node);
  }

  void test_visitVariableDeclaration_uninitialized() {
    var code = 'foo';
    var parseResult = parseTestCodeWithDiagnostics('''
var $code;
''');
    var node = parseResult.findNode.singleVariableDeclaration;
    _assertSource(code, node);
  }

  void test_visitVariableDeclarationList_const_type() {
    var code = 'const int a = 0, b = 0';
    var parseResult = parseTestCodeWithDiagnostics('''
$code;
''');
    var node = parseResult.findNode.singleVariableDeclarationList;
    _assertSource(code, node);
  }

  void test_visitVariableDeclarationList_final_noType() {
    var code = 'final a = 0, b = 0';
    var parseResult = parseTestCodeWithDiagnostics('''
$code;
''');
    var node = parseResult.findNode.singleVariableDeclarationList;
    _assertSource(code, node);
  }

  void test_visitVariableDeclarationList_type() {
    var code = 'int a, b';
    var parseResult = parseTestCodeWithDiagnostics('''
$code;
''');
    var node = parseResult.findNode.singleVariableDeclarationList;
    _assertSource(code, node);
  }

  void test_visitVariableDeclarationList_var() {
    var code = 'var a, b';
    var parseResult = parseTestCodeWithDiagnostics('''
$code;
''');
    var node = parseResult.findNode.singleVariableDeclarationList;
    _assertSource(code, node);
  }

  void test_visitVariableDeclarationStatement() {
    var code = 'int a';
    var parseResult = parseTestCodeWithDiagnostics('''
$code;
''');
    var node = parseResult.findNode.singleVariableDeclarationList;
    _assertSource(code, node);
  }

  void test_visitWhileStatement() {
    var code = 'while (true) {}';
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  $code
}
''');
    var node = parseResult.findNode.singleWhileStatement;
    _assertSource(code, node);
  }

  void test_visitWildcardPattern() {
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

  void test_visitWithClause_multiple() {
    var code = 'with A, B, C';
    var parseResult = parseTestCodeWithDiagnostics('''
class X $code {}
''');
    var node = parseResult.findNode.singleWithClause;
    _assertSource(code, node);
  }

  void test_visitWithClause_single() {
    var code = 'with M';
    var parseResult = parseTestCodeWithDiagnostics('''
class X $code {}
''');
    var node = parseResult.findNode.singleWithClause;
    _assertSource(code, node);
  }

  void test_visitYieldStatement() {
    var code = 'yield e;';
    var parseResult = parseTestCodeWithDiagnostics('''
void f() sync* {
  $code
}
''');
    var node = parseResult.findNode.singleYieldStatement;
    _assertSource(code, node);
  }

  void test_visitYieldStatement_each() {
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
    node.accept(ToSourceVisitor(buffer));
    expect(buffer.toString(), expectedSource);
  }
}
