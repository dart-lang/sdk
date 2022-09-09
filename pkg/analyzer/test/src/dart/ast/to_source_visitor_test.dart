// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/src/dart/ast/ast_factory.dart';
import 'package:analyzer/src/dart/ast/to_source_visitor.dart';
import 'package:analyzer/src/generated/testing/ast_test_factory.dart';
import 'package:analyzer/src/generated/testing/token_factory.dart';
import 'package:analyzer/src/summary2/ast_binary_tokens.dart';
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
    final code = '@A';
    final findNode = _parseStringToFindNode('''
$code
void f() {}
''');
    _assertSource(code, findNode.annotation(code));
  }

  void test_visitAnnotation_constructor() {
    final code = '@A.foo()';
    final findNode = _parseStringToFindNode('''
$code
void f() {}
''');
    _assertSource(code, findNode.annotation(code));
  }

  void test_visitAnnotation_constructor_generic() {
    final code = '@A<int>.foo()';
    final findNode = _parseStringToFindNode('''
$code
void f() {}
''');
    _assertSource(code, findNode.annotation(code));
  }

  void test_visitArgumentList() {
    _assertSource(
        "(a, b)",
        AstTestFactory.argumentList([
          AstTestFactory.identifier3("a"),
          AstTestFactory.identifier3("b")
        ]));
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

  void test_visitAssignmentExpression() {
    _assertSource(
        "a = b",
        AstTestFactory.assignmentExpression(AstTestFactory.identifier3("a"),
            TokenType.EQ, AstTestFactory.identifier3("b")));
  }

  void test_visitAugmentationImportDirective() {
    var findNode = _parseStringToFindNode(r'''
import augment 'a.dart';
''');
    _assertSource(
      "import augment 'a.dart';",
      findNode.augmentationImportDirective('import'),
    );
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

  @failingTest
  void test_visitBinaryPattern() {
    // TODO(brianwilkerson) Test this when the parser allows.
    fail('Unable to parse patterns');
  }

  void test_visitBlock_empty() {
    final code = '{}';
    final findNode = _parseStringToFindNode('''
void f() $code
''');
    _assertSource(code, findNode.block(code));
  }

  void test_visitBlock_nonEmpty() {
    final code = '{foo(); bar();}';
    final findNode = _parseStringToFindNode('''
void f() $code
''');
    _assertSource(code, findNode.block(code));
  }

  void test_visitBlockFunctionBody_async() {
    final code = 'async {}';
    final findNode = _parseStringToFindNode('''
void f() $code
''');
    _assertSource(code, findNode.blockFunctionBody(code));
  }

  void test_visitBlockFunctionBody_async_star() {
    final code = 'async* {}';
    final findNode = _parseStringToFindNode('''
void f() $code
''');
    _assertSource(code, findNode.blockFunctionBody(code));
  }

  void test_visitBlockFunctionBody_simple() {
    final code = '{}';
    final findNode = _parseStringToFindNode('''
void f() $code
''');
    _assertSource(code, findNode.blockFunctionBody(code));
  }

  void test_visitBlockFunctionBody_sync_star() {
    final code = 'sync* {}';
    final findNode = _parseStringToFindNode('''
void f() $code
''');
    _assertSource(code, findNode.blockFunctionBody(code));
  }

  void test_visitBooleanLiteral_false() {
    final code = 'false';
    final findNode = _parseStringToFindNode('''
final v = $code;
''');
    _assertSource(code, findNode.booleanLiteral(code));
  }

  void test_visitBooleanLiteral_true() {
    final code = 'true';
    final findNode = _parseStringToFindNode('''
final v = $code;
''');
    _assertSource(code, findNode.booleanLiteral(code));
  }

  void test_visitBreakStatement_label() {
    final code = 'break L;';
    final findNode = _parseStringToFindNode('''
void f() {
  L: while (true) {
    $code
  }
}
''');
    _assertSource(code, findNode.breakStatement(code));
  }

  void test_visitBreakStatement_noLabel() {
    final code = 'break;';
    final findNode = _parseStringToFindNode('''
void f() {
  while (true) {
    $code
  }
}
''');
    _assertSource(code, findNode.breakStatement(code));
  }

  void test_visitCascadeExpression_field() {
    final code = 'a..b..c';
    final findNode = _parseStringToFindNode('''
void f() {
  $code;
}
''');
    _assertSource(code, findNode.cascade(code));
  }

  void test_visitCascadeExpression_index() {
    final code = 'a..[0]..[1]';
    final findNode = _parseStringToFindNode('''
void f() {
  $code;
}
''');
    _assertSource(code, findNode.cascade(code));
  }

  void test_visitCascadeExpression_method() {
    final code = 'a..b()..c()';
    final findNode = _parseStringToFindNode('''
void f() {
  $code;
}
''');
    _assertSource(code, findNode.cascade(code));
  }

  @failingTest
  void test_visitCastPattern() {
    // TODO(brianwilkerson) Test this when the parser allows.
    fail('Unable to parse patterns');
  }

  void test_visitCatchClause_catch_noStack() {
    final code = 'catch (e) {}';
    final findNode = _parseStringToFindNode('''
void f() {
  try {}
  $code
}
''');
    _assertSource(code, findNode.catchClause(code));
  }

  void test_visitCatchClause_catch_stack() {
    final code = 'catch (e, s) {}';
    final findNode = _parseStringToFindNode('''
void f() {
  try {}
  $code
}
''');
    _assertSource(code, findNode.catchClause(code));
  }

  void test_visitCatchClause_on() {
    final code = 'on E {}';
    final findNode = _parseStringToFindNode('''
void f() {
  try {}
  $code
}
''');
    _assertSource(code, findNode.catchClause(code));
  }

  void test_visitCatchClause_on_catch() {
    final code = 'on E catch (e) {}';
    final findNode = _parseStringToFindNode('''
void f() {
  try {}
  $code
}
''');
    _assertSource(code, findNode.catchClause(code));
  }

  void test_visitClassDeclaration_abstract() {
    _assertSource(
        "abstract class C {}",
        AstTestFactory.classDeclaration(
            Keyword.ABSTRACT, "C", null, null, null, null));
  }

  void test_visitClassDeclaration_abstractAugment() {
    ClassDeclaration declaration = AstTestFactory.classDeclaration(
        Keyword.ABSTRACT, "C", null, null, null, null,
        isAugmentation: true);
    _assertSource("abstract augment class C {}", declaration);
  }

  void test_visitClassDeclaration_abstractMacro() {
    ClassDeclaration declaration = AstTestFactory.classDeclaration(
        Keyword.ABSTRACT, "C", null, null, null, null,
        isMacro: true);
    _assertSource("abstract macro class C {}", declaration);
  }

  void test_visitClassDeclaration_augment() {
    var findNode = _parseStringToFindNode(r'''
augment class A {}
''');
    _assertSource(
      'augment class A {}',
      findNode.classDeclaration('class A'),
    );
  }

  void test_visitClassDeclaration_empty() {
    _assertSource("class C {}",
        AstTestFactory.classDeclaration(null, "C", null, null, null, null));
  }

  void test_visitClassDeclaration_extends() {
    final code = 'class C extends A {}';
    final findNode = _parseStringToFindNode('''
$code
''');
    _assertSource(code, findNode.classDeclaration(code));
  }

  void test_visitClassDeclaration_extends_implements() {
    final code = 'class C extends A implements B {}';
    final findNode = _parseStringToFindNode('''
$code
''');
    _assertSource(code, findNode.classDeclaration(code));
  }

  void test_visitClassDeclaration_extends_with() {
    final code = 'class C extends A with M {}';
    final findNode = _parseStringToFindNode('''
$code
void f() {}
''');
    _assertSource(code, findNode.classDeclaration(code));
  }

  void test_visitClassDeclaration_extends_with_implements() {
    final code = 'class C extends A with M implements B {}';
    final findNode = _parseStringToFindNode('''
$code
void f() {}
''');
    _assertSource(code, findNode.classDeclaration(code));
  }

  void test_visitClassDeclaration_implements() {
    _assertSource(
        "class C implements B {}",
        AstTestFactory.classDeclaration(null, "C", null, null, null,
            AstTestFactory.implementsClause([AstTestFactory.namedType4("B")])));
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

  void test_visitClassDeclaration_multipleMember() {
    _assertSource(
        "class C {var a; var b;}",
        AstTestFactory.classDeclaration(null, "C", null, null, null, null,
            members: [
              AstTestFactory.fieldDeclaration2(false, Keyword.VAR,
                  [AstTestFactory.variableDeclaration("a")]),
              AstTestFactory.fieldDeclaration2(
                  false, Keyword.VAR, [AstTestFactory.variableDeclaration("b")])
            ]));
  }

  void test_visitClassDeclaration_parameters() {
    _assertSource(
        "class C<E> {}",
        AstTestFactory.classDeclaration(null, "C",
            AstTestFactory.typeParameterList(["E"]), null, null, null));
  }

  void test_visitClassDeclaration_parameters_extends() {
    final code = 'class C<E> extends A {}';
    final findNode = _parseStringToFindNode('''
$code
''');
    _assertSource(code, findNode.classDeclaration(code));
  }

  void test_visitClassDeclaration_parameters_extends_implements() {
    final code = 'class C<E> extends A implements B {}';
    final findNode = _parseStringToFindNode('''
$code
''');
    _assertSource(code, findNode.classDeclaration(code));
  }

  void test_visitClassDeclaration_parameters_extends_with() {
    final code = 'class C<E> extends A with M {}';
    final findNode = _parseStringToFindNode('''
$code
''');
    _assertSource(code, findNode.classDeclaration(code));
  }

  void test_visitClassDeclaration_parameters_extends_with_implements() {
    final code = 'class C<E> extends A with M implements B {}';
    final findNode = _parseStringToFindNode('''
$code
''');
    _assertSource(code, findNode.classDeclaration(code));
  }

  void test_visitClassDeclaration_parameters_implements() {
    _assertSource(
        "class C<E> implements B {}",
        AstTestFactory.classDeclaration(
            null,
            "C",
            AstTestFactory.typeParameterList(["E"]),
            null,
            null,
            AstTestFactory.implementsClause([AstTestFactory.namedType4("B")])));
  }

  void test_visitClassDeclaration_singleMember() {
    _assertSource(
        "class C {var a;}",
        AstTestFactory.classDeclaration(null, "C", null, null, null, null,
            members: [
              AstTestFactory.fieldDeclaration2(
                  false, Keyword.VAR, [AstTestFactory.variableDeclaration("a")])
            ]));
  }

  void test_visitClassDeclaration_withMetadata() {
    final code = '@deprecated class C {}';
    final findNode = _parseStringToFindNode(code);
    _assertSource(code, findNode.classDeclaration(code));
  }

  void test_visitClassTypeAlias_abstract() {
    _assertSource(
        "abstract class C = S with M1;",
        AstTestFactory.classTypeAlias(
            "C",
            null,
            Keyword.ABSTRACT,
            AstTestFactory.namedType4("S"),
            AstTestFactory.withClause([AstTestFactory.namedType4("M1")]),
            null));
  }

  void test_visitClassTypeAlias_abstract_implements() {
    _assertSource(
        "abstract class C = S with M1 implements I;",
        AstTestFactory.classTypeAlias(
            "C",
            null,
            Keyword.ABSTRACT,
            AstTestFactory.namedType4("S"),
            AstTestFactory.withClause([AstTestFactory.namedType4("M1")]),
            AstTestFactory.implementsClause([AstTestFactory.namedType4("I")])));
  }

  void test_visitClassTypeAlias_abstractAugment() {
    _assertSource(
        "abstract augment class C = S with M1;",
        AstTestFactory.classTypeAlias(
            "C",
            null,
            Keyword.ABSTRACT,
            AstTestFactory.namedType4("S"),
            AstTestFactory.withClause([AstTestFactory.namedType4("M1")]),
            null,
            isAugmentation: true));
  }

  void test_visitClassTypeAlias_abstractMacro() {
    _assertSource(
        "abstract macro class C = S with M1;",
        AstTestFactory.classTypeAlias(
            "C",
            null,
            Keyword.ABSTRACT,
            AstTestFactory.namedType4("S"),
            AstTestFactory.withClause([AstTestFactory.namedType4("M1")]),
            null,
            isMacro: true));
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

  void test_visitClassTypeAlias_generic() {
    _assertSource(
        "class C<E> = S<E> with M1<E>;",
        AstTestFactory.classTypeAlias(
            "C",
            AstTestFactory.typeParameterList(["E"]),
            null,
            AstTestFactory.namedType4("S", [AstTestFactory.namedType4("E")]),
            AstTestFactory.withClause([
              AstTestFactory.namedType4("M1", [AstTestFactory.namedType4("E")])
            ]),
            null));
  }

  void test_visitClassTypeAlias_implements() {
    _assertSource(
        "class C = S with M1 implements I;",
        AstTestFactory.classTypeAlias(
            "C",
            null,
            null,
            AstTestFactory.namedType4("S"),
            AstTestFactory.withClause([AstTestFactory.namedType4("M1")]),
            AstTestFactory.implementsClause([AstTestFactory.namedType4("I")])));
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
    _assertSource(
        "class C = S with M1;",
        AstTestFactory.classTypeAlias(
            "C",
            null,
            null,
            AstTestFactory.namedType4("S"),
            AstTestFactory.withClause([AstTestFactory.namedType4("M1")]),
            null));
  }

  void test_visitClassTypeAlias_parameters_abstract() {
    _assertSource(
        "abstract class C<E> = S with M1;",
        AstTestFactory.classTypeAlias(
            "C",
            AstTestFactory.typeParameterList(["E"]),
            Keyword.ABSTRACT,
            AstTestFactory.namedType4("S"),
            AstTestFactory.withClause([AstTestFactory.namedType4("M1")]),
            null));
  }

  void test_visitClassTypeAlias_parameters_abstract_implements() {
    _assertSource(
        "abstract class C<E> = S with M1 implements I;",
        AstTestFactory.classTypeAlias(
            "C",
            AstTestFactory.typeParameterList(["E"]),
            Keyword.ABSTRACT,
            AstTestFactory.namedType4("S"),
            AstTestFactory.withClause([AstTestFactory.namedType4("M1")]),
            AstTestFactory.implementsClause([AstTestFactory.namedType4("I")])));
  }

  void test_visitClassTypeAlias_parameters_implements() {
    _assertSource(
        "class C<E> = S with M1 implements I;",
        AstTestFactory.classTypeAlias(
            "C",
            AstTestFactory.typeParameterList(["E"]),
            null,
            AstTestFactory.namedType4("S"),
            AstTestFactory.withClause([AstTestFactory.namedType4("M1")]),
            AstTestFactory.implementsClause([AstTestFactory.namedType4("I")])));
  }

  void test_visitClassTypeAlias_withMetadata() {
    final code = '@deprecated class A = S with M;';
    final findNode = _parseStringToFindNode(code);
    _assertSource(code, findNode.classTypeAlias(code));
  }

  void test_visitComment() {
    _assertSource(
        "",
        astFactory.blockComment(
            <Token>[TokenFactory.tokenFromString("/* comment */")]));
  }

  void test_visitCommentReference() {
    final code = 'x';
    final findNode = _parseStringToFindNode('''
/// [$code]
void f() {}
''');
    _assertSource('', findNode.commentReference(code));
  }

  void test_visitCompilationUnit_declaration() {
    _assertSource(
        "var a;",
        AstTestFactory.compilationUnit2([
          AstTestFactory.topLevelVariableDeclaration2(
              Keyword.VAR, [AstTestFactory.variableDeclaration("a")])
        ]));
  }

  void test_visitCompilationUnit_directive() {
    _assertSource(
        "library l;",
        AstTestFactory.compilationUnit3(
            [AstTestFactory.libraryDirective2("l")]));
  }

  void test_visitCompilationUnit_directive_declaration() {
    _assertSource(
        "library l; var a;",
        AstTestFactory.compilationUnit4([
          AstTestFactory.libraryDirective2("l")
        ], [
          AstTestFactory.topLevelVariableDeclaration2(
              Keyword.VAR, [AstTestFactory.variableDeclaration("a")])
        ]));
  }

  void test_visitCompilationUnit_empty() {
    _assertSource("", AstTestFactory.compilationUnit());
  }

  void test_visitCompilationUnit_script() {
    _assertSource(
        "!#/bin/dartvm", AstTestFactory.compilationUnit5("!#/bin/dartvm"));
  }

  void test_visitCompilationUnit_script_declaration() {
    _assertSource(
        "!#/bin/dartvm var a;",
        AstTestFactory.compilationUnit6("!#/bin/dartvm", [
          AstTestFactory.topLevelVariableDeclaration2(
              Keyword.VAR, [AstTestFactory.variableDeclaration("a")])
        ]));
  }

  void test_visitCompilationUnit_script_directive() {
    _assertSource(
        "!#/bin/dartvm library l;",
        AstTestFactory.compilationUnit7(
            "!#/bin/dartvm", [AstTestFactory.libraryDirective2("l")]));
  }

  void test_visitCompilationUnit_script_directives_declarations() {
    _assertSource(
        "!#/bin/dartvm library l; var a;",
        AstTestFactory.compilationUnit8("!#/bin/dartvm", [
          AstTestFactory.libraryDirective2("l")
        ], [
          AstTestFactory.topLevelVariableDeclaration2(
              Keyword.VAR, [AstTestFactory.variableDeclaration("a")])
        ]));
  }

  void test_visitConditionalExpression() {
    final code = 'a ? b : c';
    final findNode = _parseStringToFindNode('''
void f() {
  $code;
}
''');
    _assertSource(code, findNode.conditionalExpression(code));
  }

  void test_visitConstructorDeclaration_const() {
    final code = 'const A();';
    final findNode = _parseStringToFindNode('''
class A {
  $code
}
''');
    _assertSource(code, findNode.constructor(code));
  }

  void test_visitConstructorDeclaration_external() {
    _assertSource(
        "external C();",
        AstTestFactory.constructorDeclaration(AstTestFactory.identifier3("C"),
            null, AstTestFactory.formalParameterList(), []));
  }

  void test_visitConstructorDeclaration_minimal() {
    final code = 'A();';
    final findNode = _parseStringToFindNode('''
class A {
  $code
}
''');
    _assertSource(code, findNode.constructor(code));
  }

  void test_visitConstructorDeclaration_multipleInitializers() {
    final code = 'A() : a = b, c = d {}';
    final findNode = _parseStringToFindNode('''
class A {
  $code
}
''');
    _assertSource(code, findNode.constructor(code));
  }

  void test_visitConstructorDeclaration_multipleParameters() {
    final code = 'A(int a, double b);';
    final findNode = _parseStringToFindNode('''
class A {
  $code
}
''');
    _assertSource(code, findNode.constructor(code));
  }

  void test_visitConstructorDeclaration_named() {
    final code = 'A.foo();';
    final findNode = _parseStringToFindNode('''
class A {
  $code
}
''');
    _assertSource(code, findNode.constructor(code));
  }

  void test_visitConstructorDeclaration_singleInitializer() {
    final code = 'A() : a = b;';
    final findNode = _parseStringToFindNode('''
class A {
  $code
}
''');
    _assertSource(code, findNode.constructor(code));
  }

  void test_visitConstructorDeclaration_withMetadata() {
    final code = '@deprecated C() {}';
    final findNode = _parseStringToFindNode('''
class C {
  $code
}
''');
    _assertSource(code, findNode.constructor(code));
  }

  void test_visitConstructorFieldInitializer_withoutThis() {
    final code = 'a = 0';
    final findNode = _parseStringToFindNode('''
class C {
  C() : $code;
}
''');
    _assertSource(code, findNode.constructorFieldInitializer(code));
  }

  void test_visitConstructorFieldInitializer_withThis() {
    final code = 'this.a = 0';
    final findNode = _parseStringToFindNode('''
class C {
  C() : $code;
}
''');
    _assertSource(code, findNode.constructorFieldInitializer(code));
  }

  void test_visitConstructorName_named_prefix() {
    final code = 'prefix.A.foo';
    final findNode = _parseStringToFindNode('''
final x = new $code();
''');
    _assertSource(code, findNode.constructorName(code));
  }

  void test_visitConstructorName_unnamed_noPrefix() {
    final code = 'A';
    final findNode = _parseStringToFindNode('''
final x = new $code();
''');
    _assertSource(code, findNode.constructorName(code));
  }

  void test_visitConstructorName_unnamed_prefix() {
    final code = 'prefix.A';
    final findNode = _parseStringToFindNode('''
final x = new $code();
''');
    _assertSource(code, findNode.constructorName(code));
  }

  void test_visitContinueStatement_label() {
    final code = 'continue L;';
    final findNode = _parseStringToFindNode('''
void f() {
  L: while (true) {
    $code
  }
}
''');
    _assertSource(code, findNode.continueStatement('continue'));
  }

  void test_visitContinueStatement_noLabel() {
    final code = 'continue;';
    final findNode = _parseStringToFindNode('''
void f() {
  while (true) {
    $code
  }
}
''');
    _assertSource(code, findNode.continueStatement('continue'));
  }

  void test_visitDefaultFormalParameter_annotation() {
    final code = '@deprecated p = 0';
    final findNode = _parseStringToFindNode('''
void f([$code]) {}
''');
    _assertSource(code, findNode.defaultParameter(code));
  }

  void test_visitDefaultFormalParameter_named_noValue() {
    final code = 'int? a';
    final findNode = _parseStringToFindNode('''
void f({$code}) {}
''');
    _assertSource(code, findNode.defaultParameter(code));
  }

  void test_visitDefaultFormalParameter_named_value() {
    final code = 'int? a = 0';
    final findNode = _parseStringToFindNode('''
void f({$code}) {}
''');
    _assertSource(code, findNode.defaultParameter(code));
  }

  void test_visitDefaultFormalParameter_positional_noValue() {
    final code = 'int? a';
    final findNode = _parseStringToFindNode('''
void f([$code]) {}
''');
    _assertSource(code, findNode.defaultParameter(code));
  }

  void test_visitDefaultFormalParameter_positional_value() {
    final code = 'int? a = 0';
    final findNode = _parseStringToFindNode('''
void f([$code]) {}
''');
    _assertSource(code, findNode.defaultParameter(code));
  }

  void test_visitDoStatement() {
    final code = 'do {} while (true);';
    final findNode = _parseStringToFindNode('''
void f () {
  $code
}
''');
    _assertSource(code, findNode.doStatement(code));
  }

  void test_visitDoubleLiteral() {
    final code = '3.14';
    final findNode = _parseStringToFindNode('''
final x = $code;
''');
    _assertSource(code, findNode.doubleLiteral(code));
  }

  void test_visitEmptyFunctionBody() {
    final code = ';';
    final findNode = _parseStringToFindNode('''
void f() {
  ;
}
''');
    _assertSource(code, findNode.emptyStatement(code));
  }

  void test_visitEmptyStatement() {
    final code = ';';
    final findNode = _parseStringToFindNode('''
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
    final code = "export 'a.dart' show A;";
    final findNode = _parseStringToFindNode('''
$code
''');
    _assertSource(code, findNode.export(code));
  }

  void test_visitExportDirective_combinators() {
    final code = "export 'a.dart' show A hide B;";
    final findNode = _parseStringToFindNode('''
$code
''');
    _assertSource(code, findNode.export(code));
  }

  void test_visitExportDirective_configurations() {
    var unit = parseString(content: r'''
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
    _assertSource(
        "export 'a.dart';", AstTestFactory.exportDirective2("a.dart"));
  }

  void test_visitExportDirective_withMetadata() {
    final code = '@deprecated export "a.dart";';
    final findNode = _parseStringToFindNode(code);
    _assertSource(code, findNode.export(code));
  }

  void test_visitExpressionFunctionBody_async() {
    final code = 'async => 0;';
    final findNode = _parseStringToFindNode('''
void f() $code
''');
    _assertSource(code, findNode.expressionFunctionBody(code));
  }

  void test_visitExpressionFunctionBody_async_star() {
    final code = 'async* => 0;';
    final parseResult = parseStringWithErrors('''
void f() $code
''');
    final node = parseResult.findNode.expressionFunctionBody(code);
    _assertSource(code, node);
  }

  void test_visitExpressionFunctionBody_simple() {
    final code = '=> 0;';
    final findNode = _parseStringToFindNode('''
void f() $code
''');
    _assertSource(code, findNode.expressionFunctionBody(code));
  }

  @failingTest
  void test_visitExpressionPattern() {
    // TODO(brianwilkerson) Test this when the parser allows.
    fail('Unable to parse patterns');
  }

  void test_visitExpressionStatement() {
    final code = '1 + 2;';
    final findNode = _parseStringToFindNode('''
void f() {
  $code
}
''');
    _assertSource(code, findNode.expressionStatement(code));
  }

  void test_visitExtendsClause() {
    final code = 'extends A';
    final findNode = _parseStringToFindNode('''
class C $code {}
''');
    _assertSource(code, findNode.extendsClause(code));
  }

  void test_visitExtensionDeclaration_empty() {
    _assertSource(
        'extension E on C {}',
        AstTestFactory.extensionDeclaration(
            name: 'E',
            extendedType: AstTestFactory.namedType4('C'),
            isExtensionTypeDeclaration: false));
  }

  void test_visitExtensionDeclaration_multipleMember() {
    _assertSource(
        'extension E on C {var a; var b;}',
        AstTestFactory.extensionDeclaration(
            name: 'E',
            extendedType: AstTestFactory.namedType4('C'),
            members: [
              AstTestFactory.fieldDeclaration2(false, Keyword.VAR,
                  [AstTestFactory.variableDeclaration('a')]),
              AstTestFactory.fieldDeclaration2(
                  false, Keyword.VAR, [AstTestFactory.variableDeclaration('b')])
            ],
            isExtensionTypeDeclaration: false));
  }

  void test_visitExtensionDeclaration_parameters() {
    _assertSource(
        'extension E<T> on C {}',
        AstTestFactory.extensionDeclaration(
            name: 'E',
            typeParameters: AstTestFactory.typeParameterList(['T']),
            extendedType: AstTestFactory.namedType4('C'),
            isExtensionTypeDeclaration: false));
  }

  void test_visitExtensionDeclaration_singleMember() {
    _assertSource(
        'extension E on C {var a;}',
        AstTestFactory.extensionDeclaration(
            name: 'E',
            extendedType: AstTestFactory.namedType4('C'),
            members: [
              AstTestFactory.fieldDeclaration2(
                  false, Keyword.VAR, [AstTestFactory.variableDeclaration('a')])
            ],
            isExtensionTypeDeclaration: false));
  }

  void test_visitExtensionDeclarationHideClause_empty() {
    _assertSource(
        'extension type E on C hide B {}',
        AstTestFactory.extensionDeclaration(
            name: 'E',
            extendedType: AstTestFactory.namedType4('C'),
            hideClause:
                AstTestFactory.hideClause([AstTestFactory.namedType4("B")]),
            isExtensionTypeDeclaration: true));
  }

  void test_visitExtensionDeclarationHideClause_multipleMember() {
    _assertSource(
        'extension type E on C hide B {var a; var b;}',
        AstTestFactory.extensionDeclaration(
            name: 'E',
            extendedType: AstTestFactory.namedType4('C'),
            members: [
              AstTestFactory.fieldDeclaration2(false, Keyword.VAR,
                  [AstTestFactory.variableDeclaration('a')]),
              AstTestFactory.fieldDeclaration2(
                  false, Keyword.VAR, [AstTestFactory.variableDeclaration('b')])
            ],
            hideClause:
                AstTestFactory.hideClause([AstTestFactory.namedType4("B")]),
            isExtensionTypeDeclaration: true));
  }

  void test_visitExtensionDeclarationHideClause_parameters() {
    _assertSource(
        'extension type E<T> on C hide B {}',
        AstTestFactory.extensionDeclaration(
            name: 'E',
            typeParameters: AstTestFactory.typeParameterList(['T']),
            extendedType: AstTestFactory.namedType4('C'),
            hideClause:
                AstTestFactory.hideClause([AstTestFactory.namedType4("B")]),
            isExtensionTypeDeclaration: true));
  }

  void test_visitExtensionDeclarationHideClause_singleMember() {
    _assertSource(
        'extension type E on C hide B {var a;}',
        AstTestFactory.extensionDeclaration(
            name: 'E',
            extendedType: AstTestFactory.namedType4('C'),
            members: [
              AstTestFactory.fieldDeclaration2(
                  false, Keyword.VAR, [AstTestFactory.variableDeclaration('a')])
            ],
            hideClause:
                AstTestFactory.hideClause([AstTestFactory.namedType4("B")]),
            isExtensionTypeDeclaration: true));
  }

  void test_visitExtensionDeclarationShowClause_ambiguousElement() {
    _assertSource(
        'extension type E on C show foo {}',
        AstTestFactory.extensionDeclaration(
            name: 'E',
            extendedType: AstTestFactory.namedType4('C'),
            showClause: AstTestFactory.showClause(
                [AstTestFactory.showHideElement("foo")]),
            isExtensionTypeDeclaration: true));
  }

  void test_visitExtensionDeclarationShowClause_empty() {
    _assertSource(
        'extension type E on C show B {}',
        AstTestFactory.extensionDeclaration(
            name: 'E',
            extendedType: AstTestFactory.namedType4('C'),
            showClause:
                AstTestFactory.showClause([AstTestFactory.namedType4("B")]),
            isExtensionTypeDeclaration: true));
  }

  void test_visitExtensionDeclarationShowClause_getterElement() {
    _assertSource(
        'extension type E on C show get foo {}',
        AstTestFactory.extensionDeclaration(
            name: 'E',
            extendedType: AstTestFactory.namedType4('C'),
            showClause: AstTestFactory.showClause(
                [AstTestFactory.showHideElementGetter("foo")]),
            isExtensionTypeDeclaration: true));
  }

  void test_visitExtensionDeclarationShowClause_multipleMember() {
    _assertSource(
        'extension type E on C show B {var a; var b;}',
        AstTestFactory.extensionDeclaration(
            name: 'E',
            extendedType: AstTestFactory.namedType4('C'),
            members: [
              AstTestFactory.fieldDeclaration2(false, Keyword.VAR,
                  [AstTestFactory.variableDeclaration('a')]),
              AstTestFactory.fieldDeclaration2(
                  false, Keyword.VAR, [AstTestFactory.variableDeclaration('b')])
            ],
            showClause:
                AstTestFactory.showClause([AstTestFactory.namedType4("B")]),
            isExtensionTypeDeclaration: true));
  }

  void test_visitExtensionDeclarationShowClause_operatorElement() {
    _assertSource(
        'extension type E on C show operator * {}',
        AstTestFactory.extensionDeclaration(
            name: 'E',
            extendedType: AstTestFactory.namedType4('C'),
            showClause: AstTestFactory.showClause(
                [AstTestFactory.showHideElementOperator("*")]),
            isExtensionTypeDeclaration: true));
  }

  void test_visitExtensionDeclarationShowClause_parameters() {
    _assertSource(
        'extension type E<T> on C show B {}',
        AstTestFactory.extensionDeclaration(
            name: 'E',
            typeParameters: AstTestFactory.typeParameterList(['T']),
            extendedType: AstTestFactory.namedType4('C'),
            showClause:
                AstTestFactory.showClause([AstTestFactory.namedType4("B")]),
            isExtensionTypeDeclaration: true));
  }

  void test_visitExtensionDeclarationShowClause_qualifiedTypeElement() {
    _assertSource(
        'extension type E on C show prefix.B {}',
        AstTestFactory.extensionDeclaration(
            name: 'E',
            extendedType: AstTestFactory.namedType4('C'),
            showClause: AstTestFactory.showClause([
              AstTestFactory.namedType3(
                  AstTestFactory.identifier5('prefix', 'B'))
            ]),
            isExtensionTypeDeclaration: true));
  }

  void test_visitExtensionDeclarationShowClause_setterElement() {
    _assertSource(
        'extension type E on C show set foo {}',
        AstTestFactory.extensionDeclaration(
            name: 'E',
            extendedType: AstTestFactory.namedType4('C'),
            showClause: AstTestFactory.showClause(
                [AstTestFactory.showHideElementSetter("foo")]),
            isExtensionTypeDeclaration: true));
  }

  void test_visitExtensionDeclarationShowClause_singleMember() {
    _assertSource(
        'extension type E on C show B {var a;}',
        AstTestFactory.extensionDeclaration(
            name: 'E',
            extendedType: AstTestFactory.namedType4('C'),
            members: [
              AstTestFactory.fieldDeclaration2(
                  false, Keyword.VAR, [AstTestFactory.variableDeclaration('a')])
            ],
            showClause:
                AstTestFactory.showClause([AstTestFactory.namedType4("B")]),
            isExtensionTypeDeclaration: true));
  }

  void test_visitExtensionDeclarationShowClause_typeWithArgumentsElement() {
    _assertSource(
        'extension type E on C show B<int, String> {}',
        AstTestFactory.extensionDeclaration(
            name: 'E',
            extendedType: AstTestFactory.namedType4('C'),
            showClause: AstTestFactory.showClause([
              AstTestFactory.namedType3(AstTestFactory.identifier3('B'), [
                AstTestFactory.namedType4('int'),
                AstTestFactory.namedType4('String')
              ])
            ]),
            isExtensionTypeDeclaration: true));
  }

  void test_visitExtensionDeclarationShowHideClause_empty() {
    _assertSource(
        'extension type E on C show B hide foo {}',
        AstTestFactory.extensionDeclaration(
            name: 'E',
            extendedType: AstTestFactory.namedType4('C'),
            showClause:
                AstTestFactory.showClause([AstTestFactory.namedType4("B")]),
            hideClause: AstTestFactory.hideClause(
                [AstTestFactory.showHideElement("foo")]),
            isExtensionTypeDeclaration: true));
  }

  void test_visitExtensionOverride_prefixedName_noTypeArgs() {
    _assertSource(
        'p.E(o)',
        AstTestFactory.extensionOverride(
            extensionName: AstTestFactory.identifier5('p', 'E'),
            argumentList: AstTestFactory.argumentList(
                [AstTestFactory.identifier3('o')])));
  }

  void test_visitExtensionOverride_prefixedName_typeArgs() {
    _assertSource(
        'p.E<A>(o)',
        AstTestFactory.extensionOverride(
            extensionName: AstTestFactory.identifier5('p', 'E'),
            typeArguments: AstTestFactory.typeArgumentList(
                [AstTestFactory.namedType4('A')]),
            argumentList: AstTestFactory.argumentList(
                [AstTestFactory.identifier3('o')])));
  }

  void test_visitExtensionOverride_simpleName_noTypeArgs() {
    _assertSource(
        'E(o)',
        AstTestFactory.extensionOverride(
            extensionName: AstTestFactory.identifier3('E'),
            argumentList: AstTestFactory.argumentList(
                [AstTestFactory.identifier3('o')])));
  }

  void test_visitExtensionOverride_simpleName_typeArgs() {
    _assertSource(
        'E<A>(o)',
        AstTestFactory.extensionOverride(
            extensionName: AstTestFactory.identifier3('E'),
            typeArguments: AstTestFactory.typeArgumentList(
                [AstTestFactory.namedType4('A')]),
            argumentList: AstTestFactory.argumentList(
                [AstTestFactory.identifier3('o')])));
  }

  void test_visitExtensionTypeDeclaration_empty() {
    _assertSource(
        'extension type E on C {}',
        AstTestFactory.extensionDeclaration(
            name: 'E',
            extendedType: AstTestFactory.namedType4('C'),
            isExtensionTypeDeclaration: true));
  }

  void test_visitExtensionTypeDeclaration_multipleMember() {
    _assertSource(
        'extension type E on C {var a; var b;}',
        AstTestFactory.extensionDeclaration(
            name: 'E',
            extendedType: AstTestFactory.namedType4('C'),
            members: [
              AstTestFactory.fieldDeclaration2(false, Keyword.VAR,
                  [AstTestFactory.variableDeclaration('a')]),
              AstTestFactory.fieldDeclaration2(
                  false, Keyword.VAR, [AstTestFactory.variableDeclaration('b')])
            ],
            isExtensionTypeDeclaration: true));
  }

  void test_visitExtensionTypeDeclaration_parameters() {
    _assertSource(
        'extension type E<T> on C {}',
        AstTestFactory.extensionDeclaration(
            name: 'E',
            typeParameters: AstTestFactory.typeParameterList(['T']),
            extendedType: AstTestFactory.namedType4('C'),
            isExtensionTypeDeclaration: true));
  }

  void test_visitExtensionTypeDeclaration_singleMember() {
    _assertSource(
        'extension type E on C {var a;}',
        AstTestFactory.extensionDeclaration(
            name: 'E',
            extendedType: AstTestFactory.namedType4('C'),
            members: [
              AstTestFactory.fieldDeclaration2(
                  false, Keyword.VAR, [AstTestFactory.variableDeclaration('a')])
            ],
            isExtensionTypeDeclaration: true));
  }

  @failingTest
  void test_visitExtractorPattern() {
    // TODO(brianwilkerson) Test this when the parser allows.
    fail('Unable to parse patterns');
  }

  void test_visitFieldDeclaration_abstract() {
    _assertSource(
        "abstract var a;",
        AstTestFactory.fieldDeclaration(
            false, Keyword.VAR, null, [AstTestFactory.variableDeclaration("a")],
            isAbstract: true));
  }

  void test_visitFieldDeclaration_external() {
    _assertSource(
        "external var a;",
        AstTestFactory.fieldDeclaration(
            false, Keyword.VAR, null, [AstTestFactory.variableDeclaration("a")],
            isExternal: true));
  }

  void test_visitFieldDeclaration_instance() {
    _assertSource(
        "var a;",
        AstTestFactory.fieldDeclaration2(
            false, Keyword.VAR, [AstTestFactory.variableDeclaration("a")]));
  }

  void test_visitFieldDeclaration_static() {
    _assertSource(
        "static var a;",
        AstTestFactory.fieldDeclaration2(
            true, Keyword.VAR, [AstTestFactory.variableDeclaration("a")]));
  }

  void test_visitFieldDeclaration_withMetadata() {
    final code = '@deprecated var a;';
    final findNode = _parseStringToFindNode('''
class A {
  $code
}
''');
    _assertSource(code, findNode.fieldDeclaration(code));
  }

  void test_visitFieldFormalParameter_annotation() {
    final code = '@deprecated this.foo';
    final findNode = _parseStringToFindNode('''
class A {
  final int foo;
  A($code);
}
''');
    _assertSource(code, findNode.fieldFormalParameter(code));
  }

  void test_visitFieldFormalParameter_functionTyped() {
    _assertSource(
        "A this.a(b)",
        AstTestFactory.fieldFormalParameter(
            null,
            AstTestFactory.namedType4("A"),
            "a",
            AstTestFactory.formalParameterList(
                [AstTestFactory.simpleFormalParameter3("b")])));
  }

  void test_visitFieldFormalParameter_functionTyped_typeParameters() {
    _assertSource(
        "A this.a<E, F>(b)",
        astFactory.fieldFormalParameter2(
            type: AstTestFactory.namedType4('A'),
            thisKeyword: TokenFactory.tokenFromKeyword(Keyword.THIS),
            period: TokenFactory.tokenFromType(TokenType.PERIOD),
            identifier: AstTestFactory.identifier3('a'),
            typeParameters: AstTestFactory.typeParameterList(['E', 'F']),
            parameters: AstTestFactory.formalParameterList(
                [AstTestFactory.simpleFormalParameter3("b")])));
  }

  void test_visitFieldFormalParameter_keyword() {
    _assertSource("var this.a",
        AstTestFactory.fieldFormalParameter(Keyword.VAR, null, "a"));
  }

  void test_visitFieldFormalParameter_keywordAndType() {
    _assertSource(
        "final A this.a",
        AstTestFactory.fieldFormalParameter(
            Keyword.FINAL, AstTestFactory.namedType4("A"), "a"));
  }

  void test_visitFieldFormalParameter_type() {
    _assertSource(
        "A this.a",
        AstTestFactory.fieldFormalParameter(
            null, AstTestFactory.namedType4("A"), "a"));
  }

  void test_visitFieldFormalParameter_type_covariant() {
    var expected = AstTestFactory.fieldFormalParameter(
        null, AstTestFactory.namedType4("A"), "a");
    expected.covariantKeyword =
        TokenFactory.tokenFromKeyword(Keyword.COVARIANT);
    _assertSource("covariant A this.a", expected);
  }

  void test_visitForEachPartsWithIdentifier() {
    final code = 'e in []';
    final findNode = _parseStringToFindNode('''
void f() {
  for ($code) {}
}
''');
    _assertSource(code, findNode.forEachPartsWithIdentifier(code));
  }

  @failingTest
  void test_visitForEachPartsWithPattern() {
    // TODO(brianwilkerson) Test this when the parser allows.
    fail('Unable to parse patterns');
  }

  void test_visitForEachStatement_declared() {
    final code = 'for (final a in b) {}';
    final findNode = _parseStringToFindNode('''
void f () {
  $code
}
''');
    _assertSource(code, findNode.forStatement(code));
  }

  void test_visitForEachStatement_variable() {
    final code = 'for (a in b) {}';
    final findNode = _parseStringToFindNode('''
void f () {
  $code
}
''');
    _assertSource(code, findNode.forStatement(code));
  }

  void test_visitForEachStatement_variable_await() {
    final code = 'await for (final a in b) {}';
    final findNode = _parseStringToFindNode('''
void f() async {
  $code
}
''');
    _assertSource(code, findNode.forStatement(code));
  }

  void test_visitForElement() {
    final code = 'for (e in []) 0';
    final findNode = _parseStringToFindNode('''
final v = [ $code ];
''');
    _assertSource(code, findNode.forElement(code));
  }

  void test_visitFormalParameterList_empty() {
    _assertSource("()", AstTestFactory.formalParameterList());
  }

  void test_visitFormalParameterList_n() {
    final code = '({a = 0})';
    final findNode = _parseStringToFindNode('''
void f$code {}
''');
    _assertSource(code, findNode.formalParameterList(code));
  }

  void test_visitFormalParameterList_namedRequired() {
    final code = '({required a, required int b})';
    final findNode = _parseStringToFindNode('''
void f$code {}
''');
    _assertSource(code, findNode.formalParameterList(code));
  }

  void test_visitFormalParameterList_nn() {
    final code = '({int a = 0, b = 1})';
    final findNode = _parseStringToFindNode('''
void f$code {}
''');
    _assertSource(code, findNode.formalParameterList(code));
  }

  void test_visitFormalParameterList_p() {
    final code = '([a = 0])';
    final findNode = _parseStringToFindNode('''
void f$code {}
''');
    _assertSource(code, findNode.formalParameterList(code));
  }

  void test_visitFormalParameterList_pp() {
    final code = '([a = 0, b = 1])';
    final findNode = _parseStringToFindNode('''
void f$code {}
''');
    _assertSource(code, findNode.formalParameterList(code));
  }

  void test_visitFormalParameterList_r() {
    _assertSource(
        "(a)",
        AstTestFactory.formalParameterList(
            [AstTestFactory.simpleFormalParameter3("a")]));
  }

  void test_visitFormalParameterList_rn() {
    final code = '(a, {b = 1})';
    final findNode = _parseStringToFindNode('''
void f$code {}
''');
    _assertSource(code, findNode.formalParameterList(code));
  }

  void test_visitFormalParameterList_rnn() {
    final code = '(a, {b = 1, c = 2})';
    final findNode = _parseStringToFindNode('''
void f$code {}
''');
    _assertSource(code, findNode.formalParameterList(code));
  }

  void test_visitFormalParameterList_rp() {
    final code = '(a, [b = 1])';
    final findNode = _parseStringToFindNode('''
void f$code {}
''');
    _assertSource(code, findNode.formalParameterList(code));
  }

  void test_visitFormalParameterList_rpp() {
    final code = '(a, [b = 1, c = 2])';
    final findNode = _parseStringToFindNode('''
void f$code {}
''');
    _assertSource(code, findNode.formalParameterList(code));
  }

  void test_visitFormalParameterList_rr() {
    _assertSource(
        "(a, b)",
        AstTestFactory.formalParameterList([
          AstTestFactory.simpleFormalParameter3("a"),
          AstTestFactory.simpleFormalParameter3("b")
        ]));
  }

  void test_visitFormalParameterList_rrn() {
    final code = '(a, b, {c = 2})';
    final findNode = _parseStringToFindNode('''
void f$code {}
''');
    _assertSource(code, findNode.formalParameterList(code));
  }

  void test_visitFormalParameterList_rrnn() {
    final code = '(a, b, {c = 2, d = 3})';
    final findNode = _parseStringToFindNode('''
void f$code {}
''');
    _assertSource(code, findNode.formalParameterList(code));
  }

  void test_visitFormalParameterList_rrp() {
    final code = '(a, b, [c = 2])';
    final findNode = _parseStringToFindNode('''
void f$code {}
''');
    _assertSource(code, findNode.formalParameterList(code));
  }

  void test_visitFormalParameterList_rrpp() {
    final code = '(a, b, [c = 2, d = 3])';
    final findNode = _parseStringToFindNode('''
void f$code {}
''');
    _assertSource(code, findNode.formalParameterList(code));
  }

  void test_visitForPartsWithDeclarations() {
    final code = 'var v = 0; v < 10; v++';
    final findNode = _parseStringToFindNode('''
void f() {
  for ($code) {}
}
''');
    _assertSource(code, findNode.forPartsWithDeclarations(code));
  }

  void test_visitForPartsWithExpression() {
    final code = 'v = 0; v < 10; v++';
    final findNode = _parseStringToFindNode('''
void f() {
  for ($code) {}
}
''');
    _assertSource(code, findNode.forPartsWithExpression(code));
  }

  @failingTest
  void test_visitForPartsWithPattern() {
    // TODO(brianwilkerson) Test this when the parser allows.
    fail('Unable to parse patterns');
  }

  void test_visitForStatement() {
    final code = 'for (var v in [0]) {}';
    final findNode = _parseStringToFindNode('''
void f() {
  $code
}
''');
    _assertSource(code, findNode.forStatement(code));
  }

  void test_visitForStatement_c() {
    final code = 'for (; c;) {}';
    final findNode = _parseStringToFindNode('''
void f () {
  $code
}
''');
    _assertSource(code, findNode.forStatement(code));
  }

  void test_visitForStatement_cu() {
    final code = 'for (; c; u) {}';
    final findNode = _parseStringToFindNode('''
void f () {
  $code
}
''');
    _assertSource(code, findNode.forStatement(code));
  }

  void test_visitForStatement_e() {
    final code = 'for (e;;) {}';
    final findNode = _parseStringToFindNode('''
void f () {
  $code
}
''');
    _assertSource(code, findNode.forStatement(code));
  }

  void test_visitForStatement_ec() {
    final code = 'for (e; c;) {}';
    final findNode = _parseStringToFindNode('''
void f () {
  $code
}
''');
    _assertSource(code, findNode.forStatement(code));
  }

  void test_visitForStatement_ecu() {
    final code = 'for (e; c; u) {}';
    final findNode = _parseStringToFindNode('''
void f () {
  $code
}
''');
    _assertSource(code, findNode.forStatement(code));
  }

  void test_visitForStatement_eu() {
    final code = 'for (e;; u) {}';
    final findNode = _parseStringToFindNode('''
void f () {
  $code
}
''');
    _assertSource(code, findNode.forStatement(code));
  }

  void test_visitForStatement_i() {
    final code = 'for (var i;;) {}';
    final findNode = _parseStringToFindNode('''
void f () {
  $code
}
''');
    _assertSource(code, findNode.forStatement(code));
  }

  void test_visitForStatement_ic() {
    final code = 'for (var i; c;) {}';
    final findNode = _parseStringToFindNode('''
void f () {
  $code
}
''');
    _assertSource(code, findNode.forStatement(code));
  }

  void test_visitForStatement_icu() {
    final code = 'for (var i; c; u) {}';
    final findNode = _parseStringToFindNode('''
void f () {
  $code
}
''');
    _assertSource(code, findNode.forStatement(code));
  }

  void test_visitForStatement_iu() {
    final code = 'for (var i;; u) {}';
    final findNode = _parseStringToFindNode('''
void f () {
  $code
}
''');
    _assertSource(code, findNode.forStatement(code));
  }

  void test_visitForStatement_u() {
    final code = 'for (;; u) {}';
    final findNode = _parseStringToFindNode('''
void f () {
  $code
}
''');
    _assertSource(code, findNode.forStatement(code));
  }

  void test_visitFunctionDeclaration_external() {
    final code = 'external void f();';
    final findNode = _parseStringToFindNode(code);
    _assertSource(code, findNode.functionDeclaration(code));
  }

  void test_visitFunctionDeclaration_getter() {
    final code = 'get foo {}';
    final findNode = _parseStringToFindNode(code);
    _assertSource(code, findNode.functionDeclaration(code));
  }

  void test_visitFunctionDeclaration_local_blockBody() {
    final code = 'void foo() {}';
    final findNode = _parseStringToFindNode('''
void f() {
  $code
}
''');
    _assertSource(code, findNode.functionDeclaration(code));
  }

  void test_visitFunctionDeclaration_local_expressionBody() {
    final code = 'int foo() => 42;';
    final findNode = _parseStringToFindNode('''
void f() {
  $code
}
''');
    _assertSource(code, findNode.functionDeclaration(code));
  }

  void test_visitFunctionDeclaration_normal() {
    final code = 'void foo() {}';
    final findNode = _parseStringToFindNode(code);
    _assertSource(code, findNode.functionDeclaration(code));
  }

  void test_visitFunctionDeclaration_setter() {
    final code = 'set foo(int _) {}';
    final findNode = _parseStringToFindNode(code);
    _assertSource(code, findNode.functionDeclaration(code));
  }

  void test_visitFunctionDeclaration_typeParameters() {
    final code = 'void foo<T>() {}';
    final findNode = _parseStringToFindNode(code);
    _assertSource(code, findNode.functionDeclaration(code));
  }

  void test_visitFunctionDeclaration_withMetadata() {
    final code = '@deprecated void f() {}';
    final findNode = _parseStringToFindNode(code);
    _assertSource(code, findNode.functionDeclaration(code));
  }

  void test_visitFunctionDeclarationStatement() {
    final code = 'void foo() {}';
    final findNode = _parseStringToFindNode('''
void f() {
  $code
}
''');
    _assertSource(code, findNode.functionDeclaration(code));
  }

  void test_visitFunctionExpression() {
    final code = '() {}';
    final findNode = _parseStringToFindNode('''
final f = $code;
''');
    _assertSource(code, findNode.functionExpression(code));
  }

  void test_visitFunctionExpression_typeParameters() {
    final code = '<T>() {}';
    final findNode = _parseStringToFindNode('''
final f = $code;
''');
    _assertSource(code, findNode.functionExpression(code));
  }

  void test_visitFunctionExpressionInvocation_minimal() {
    final code = '(a)()';
    final findNode = _parseStringToFindNode('''
void f() {
  $code;
}
''');
    _assertSource(code, findNode.functionExpressionInvocation(code));
  }

  void test_visitFunctionExpressionInvocation_typeArguments() {
    final code = '(a)<int>()';
    final findNode = _parseStringToFindNode('''
void f() {
  $code;
}
''');
    _assertSource(code, findNode.functionExpressionInvocation(code));
  }

  void test_visitFunctionTypeAlias_generic() {
    _assertSource(
        "typedef A F<B>();",
        AstTestFactory.typeAlias(
            AstTestFactory.namedType4("A"),
            "F",
            AstTestFactory.typeParameterList(["B"]),
            AstTestFactory.formalParameterList()));
  }

  void test_visitFunctionTypeAlias_nonGeneric() {
    _assertSource(
        "typedef A F();",
        AstTestFactory.typeAlias(AstTestFactory.namedType4("A"), "F", null,
            AstTestFactory.formalParameterList()));
  }

  void test_visitFunctionTypeAlias_withMetadata() {
    final code = '@deprecated typedef void F();';
    final findNode = _parseStringToFindNode(code);
    _assertSource(code, findNode.functionTypeAlias(code));
  }

  void test_visitFunctionTypedFormalParameter_annotation() {
    final code = '@deprecated g()';
    final findNode = _parseStringToFindNode('''
void f($code) {}
''');
    _assertSource(code, findNode.functionTypedFormalParameter(code));
  }

  void test_visitFunctionTypedFormalParameter_noType() {
    _assertSource(
        "f()", AstTestFactory.functionTypedFormalParameter(null, "f"));
  }

  void test_visitFunctionTypedFormalParameter_nullable() {
    _assertSource(
        "T f()?",
        astFactory.functionTypedFormalParameter2(
            returnType: AstTestFactory.namedType4("T"),
            identifier: AstTestFactory.identifier3('f'),
            parameters: AstTestFactory.formalParameterList([]),
            question: TokenFactory.tokenFromType(TokenType.QUESTION)));
  }

  void test_visitFunctionTypedFormalParameter_type() {
    _assertSource(
        "T f()",
        AstTestFactory.functionTypedFormalParameter(
            AstTestFactory.namedType4("T"), "f"));
  }

  void test_visitFunctionTypedFormalParameter_type_covariant() {
    var expected = AstTestFactory.functionTypedFormalParameter(
        AstTestFactory.namedType4("T"), "f");
    expected.covariantKeyword =
        TokenFactory.tokenFromKeyword(Keyword.COVARIANT);
    _assertSource("covariant T f()", expected);
  }

  void test_visitFunctionTypedFormalParameter_typeParameters() {
    _assertSource(
        "T f<E>()",
        astFactory.functionTypedFormalParameter2(
            returnType: AstTestFactory.namedType4("T"),
            identifier: AstTestFactory.identifier3('f'),
            typeParameters: AstTestFactory.typeParameterList(['E']),
            parameters: AstTestFactory.formalParameterList([])));
  }

  void test_visitGenericFunctionType() {
    _assertSource(
        "int Function<T>(T)",
        AstTestFactory.genericFunctionType(
            AstTestFactory.namedType4("int"),
            AstTestFactory.typeParameterList2(['T']),
            AstTestFactory.formalParameterList([
              AstTestFactory.simpleFormalParameter4(
                  AstTestFactory.namedType4("T"), null)
            ])));
  }

  void test_visitGenericFunctionType_withQuestion() {
    _assertSource(
        "int Function<T>(T)?",
        AstTestFactory.genericFunctionType(
            AstTestFactory.namedType4("int"),
            AstTestFactory.typeParameterList2(['T']),
            AstTestFactory.formalParameterList([
              AstTestFactory.simpleFormalParameter4(
                  AstTestFactory.namedType4("T"), null)
            ]),
            question: true));
  }

  void test_visitGenericTypeAlias() {
    _assertSource(
        "typedef X<S> = S Function<T>(T);",
        AstTestFactory.genericTypeAlias(
            'X',
            AstTestFactory.typeParameterList2(['S']),
            AstTestFactory.genericFunctionType(
                AstTestFactory.namedType4("S"),
                AstTestFactory.typeParameterList2(['T']),
                AstTestFactory.formalParameterList([
                  AstTestFactory.simpleFormalParameter4(
                      AstTestFactory.namedType4("T"), null)
                ]))));
  }

  void test_visitIfElement_else() {
    _assertSource(
        'if (b) 1 else 0',
        astFactory.ifElement(
            ifKeyword: Tokens.if_(),
            leftParenthesis: Tokens.openParenthesis(),
            condition: AstTestFactory.identifier3('b'),
            rightParenthesis: Tokens.closeParenthesis(),
            thenElement: AstTestFactory.integer(1),
            elseKeyword: Tokens.else_(),
            elseElement: AstTestFactory.integer(0)));
  }

  void test_visitIfElement_then() {
    _assertSource(
        'if (b) 1',
        astFactory.ifElement(
            ifKeyword: Tokens.if_(),
            leftParenthesis: Tokens.openParenthesis(),
            condition: AstTestFactory.identifier3('b'),
            rightParenthesis: Tokens.closeParenthesis(),
            thenElement: AstTestFactory.integer(1)));
  }

  void test_visitIfStatement_withElse() {
    final code = 'if (c) {} else {}';
    final findNode = _parseStringToFindNode('''
void f () {
  $code
}
''');
    _assertSource(code, findNode.ifStatement(code));
  }

  void test_visitIfStatement_withoutElse() {
    final code = 'if (c) {}';
    final findNode = _parseStringToFindNode('''
void f() {
  $code
}
''');
    _assertSource(code, findNode.ifStatement(code));
  }

  void test_visitImplementsClause_multiple() {
    _assertSource(
        "implements A, B",
        AstTestFactory.implementsClause(
            [AstTestFactory.namedType4("A"), AstTestFactory.namedType4("B")]));
  }

  void test_visitImplementsClause_single() {
    _assertSource("implements A",
        AstTestFactory.implementsClause([AstTestFactory.namedType4("A")]));
  }

  void test_visitImportDirective_combinator() {
    final code = "import 'a.dart' show A;";
    final findNode = _parseStringToFindNode('''
$code
''');
    _assertSource(code, findNode.import(code));
  }

  void test_visitImportDirective_combinators() {
    final code = "import 'a.dart' show A hide B;";
    final findNode = _parseStringToFindNode('''
$code
''');
    _assertSource(code, findNode.import(code));
  }

  void test_visitImportDirective_configurations() {
    var unit = parseString(content: r'''
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
    _assertSource("import 'a.dart' deferred as p;",
        AstTestFactory.importDirective2("a.dart", true, "p"));
  }

  void test_visitImportDirective_minimal() {
    _assertSource(
        "import 'a.dart';", AstTestFactory.importDirective3("a.dart", null));
  }

  void test_visitImportDirective_prefix() {
    _assertSource("import 'a.dart' as p;",
        AstTestFactory.importDirective3("a.dart", "p"));
  }

  void test_visitImportDirective_prefix_combinator() {
    final code = "import 'a.dart' as p show A;";
    final findNode = _parseStringToFindNode('''
$code
''');
    _assertSource(code, findNode.import(code));
  }

  void test_visitImportDirective_prefix_combinators() {
    final code = "import 'a.dart' as p show A hide B;";
    final findNode = _parseStringToFindNode('''
$code
''');
    _assertSource(code, findNode.import(code));
  }

  void test_visitImportDirective_withMetadata() {
    final code = '@deprecated import "a.dart";';
    final findNode = _parseStringToFindNode(code);
    _assertSource(code, findNode.import(code));
  }

  void test_visitImportHideCombinator_multiple() {
    final code = 'hide A, B';
    final findNode = _parseStringToFindNode('''
import 'a.dart' $code;
''');
    _assertSource(code, findNode.hideCombinator(code));
  }

  void test_visitImportHideCombinator_single() {
    final code = 'hide A';
    final findNode = _parseStringToFindNode('''
import 'a.dart' $code;
''');
    _assertSource(code, findNode.hideCombinator(code));
  }

  void test_visitImportShowCombinator_multiple() {
    final code = 'show A, B';
    final findNode = _parseStringToFindNode('''
import 'a.dart' $code;
''');
    _assertSource(code, findNode.showCombinator(code));
  }

  void test_visitImportShowCombinator_single() {
    final code = 'show A';
    final findNode = _parseStringToFindNode('''
import 'a.dart' $code;
''');
    _assertSource(code, findNode.showCombinator(code));
  }

  void test_visitIndexExpression() {
    _assertSource(
      "a[i]",
      AstTestFactory.indexExpression(
        target: AstTestFactory.identifier3("a"),
        index: AstTestFactory.identifier3("i"),
      ),
    );
  }

  void test_visitInstanceCreationExpression_const() {
    final code = 'const A()';
    final findNode = _parseStringToFindNode('''
final x = $code;
''');
    _assertSource(code, findNode.instanceCreation(code));
  }

  void test_visitInstanceCreationExpression_named() {
    final code = 'new A.foo()';
    final findNode = _parseStringToFindNode('''
final x = $code;
''');
    _assertSource(code, findNode.instanceCreation(code));
  }

  void test_visitInstanceCreationExpression_unnamed() {
    final code = 'new A()';
    final findNode = _parseStringToFindNode('''
final x = $code;
''');
    _assertSource(code, findNode.instanceCreation(code));
  }

  void test_visitIntegerLiteral() {
    _assertSource("42", AstTestFactory.integer(42));
  }

  void test_visitInterpolationExpression_expression() {
    _assertSource(
        "\${a}",
        AstTestFactory.interpolationExpression(
            AstTestFactory.identifier3("a")));
  }

  void test_visitInterpolationExpression_identifier() {
    _assertSource("\$a", AstTestFactory.interpolationExpression2("a"));
  }

  void test_visitInterpolationString() {
    _assertSource("'x", AstTestFactory.interpolationString("'x", "x"));
  }

  void test_visitIsExpression_negated() {
    _assertSource(
        "a is! C",
        AstTestFactory.isExpression(AstTestFactory.identifier3("a"), true,
            AstTestFactory.namedType4("C")));
  }

  void test_visitIsExpression_normal() {
    _assertSource(
        "a is C",
        AstTestFactory.isExpression(AstTestFactory.identifier3("a"), false,
            AstTestFactory.namedType4("C")));
  }

  void test_visitLabel() {
    _assertSource("a:", AstTestFactory.label2("a"));
  }

  void test_visitLabeledStatement_multiple() {
    _assertSource(
        "a: b: return;",
        AstTestFactory.labeledStatement(
            [AstTestFactory.label2("a"), AstTestFactory.label2("b")],
            AstTestFactory.returnStatement()));
  }

  void test_visitLabeledStatement_single() {
    _assertSource(
        "a: return;",
        AstTestFactory.labeledStatement(
            [AstTestFactory.label2("a")], AstTestFactory.returnStatement()));
  }

  void test_visitLibraryAugmentationDirective() {
    var findNode = _parseStringToFindNode(r'''
library augment 'a.dart';
''');
    _assertSource(
      "library augment 'a.dart';",
      findNode.libraryAugmentation('library'),
    );
  }

  void test_visitLibraryDirective() {
    _assertSource("library l;", AstTestFactory.libraryDirective2("l"));
  }

  void test_visitLibraryDirective_withMetadata() {
    final code = '@deprecated library my;';
    final findNode = _parseStringToFindNode(code);
    _assertSource(code, findNode.library(code));
  }

  void test_visitLibraryIdentifier_multiple() {
    _assertSource(
        "a.b.c",
        AstTestFactory.libraryIdentifier([
          AstTestFactory.identifier3("a"),
          AstTestFactory.identifier3("b"),
          AstTestFactory.identifier3("c")
        ]));
  }

  void test_visitLibraryIdentifier_single() {
    _assertSource("a",
        AstTestFactory.libraryIdentifier([AstTestFactory.identifier3("a")]));
  }

  void test_visitListLiteral_complex() {
    final code = '<int>[0, for (e in []) 0, if (b) 1, ...[0]]';
    final findNode = _parseStringToFindNode('''
final v = $code;
''');
    _assertSource(code, findNode.listLiteral(code));
  }

  void test_visitListLiteral_const() {
    _assertSource("const []", AstTestFactory.listLiteral2(Keyword.CONST, null));
  }

  void test_visitListLiteral_empty() {
    _assertSource("[]", AstTestFactory.listLiteral());
  }

  void test_visitListLiteral_nonEmpty() {
    _assertSource(
        "[a, b, c]",
        AstTestFactory.listLiteral([
          AstTestFactory.identifier3("a"),
          AstTestFactory.identifier3("b"),
          AstTestFactory.identifier3("c")
        ]));
  }

  void test_visitListLiteral_withConst_withoutTypeArgs() {
    _assertSource(
        'const [0]',
        astFactory.listLiteral(
            TokenFactory.tokenFromKeyword(Keyword.CONST),
            null,
            Tokens.openSquareBracket(),
            [AstTestFactory.integer(0)],
            Tokens.closeSquareBracket()));
  }

  void test_visitListLiteral_withConst_withTypeArgs() {
    _assertSource(
        'const <int>[0]',
        astFactory.listLiteral(
            TokenFactory.tokenFromKeyword(Keyword.CONST),
            AstTestFactory.typeArgumentList([AstTestFactory.namedType4('int')]),
            Tokens.openSquareBracket(),
            [AstTestFactory.integer(0)],
            Tokens.closeSquareBracket()));
  }

  void test_visitListLiteral_withoutConst_withoutTypeArgs() {
    _assertSource(
        '[0]',
        astFactory.listLiteral(null, null, Tokens.openSquareBracket(),
            [AstTestFactory.integer(0)], Tokens.closeSquareBracket()));
  }

  void test_visitListLiteral_withoutConst_withTypeArgs() {
    _assertSource(
        '<int>[0]',
        astFactory.listLiteral(
            null,
            AstTestFactory.typeArgumentList([AstTestFactory.namedType4('int')]),
            Tokens.openSquareBracket(),
            [AstTestFactory.integer(0)],
            Tokens.closeSquareBracket()));
  }

  @failingTest
  void test_visitListPattern() {
    // TODO(brianwilkerson) Test this when the parser allows.
    fail('Unable to parse patterns');
  }

  void test_visitMapLiteral_const() {
    _assertSource(
        "const {}", AstTestFactory.setOrMapLiteral(Keyword.CONST, null));
  }

  void test_visitMapLiteral_empty() {
    _assertSource("{}", AstTestFactory.setOrMapLiteral(null, null));
  }

  void test_visitMapLiteral_nonEmpty() {
    _assertSource(
        "{'a' : a, 'b' : b, 'c' : c}",
        AstTestFactory.setOrMapLiteral(null, null, [
          AstTestFactory.mapLiteralEntry("a", AstTestFactory.identifier3("a")),
          AstTestFactory.mapLiteralEntry("b", AstTestFactory.identifier3("b")),
          AstTestFactory.mapLiteralEntry("c", AstTestFactory.identifier3("c"))
        ]));
  }

  void test_visitMapLiteralEntry() {
    _assertSource("'a' : b",
        AstTestFactory.mapLiteralEntry("a", AstTestFactory.identifier3("b")));
  }

  @failingTest
  void test_visitMapPattern() {
    // TODO(brianwilkerson) Test this when the parser allows.
    fail('Unable to parse patterns');
  }

  @failingTest
  void test_visitMapPatternEntry() {
    // TODO(brianwilkerson) Test this when the parser allows.
    fail('Unable to parse patterns');
  }

  void test_visitMethodDeclaration_external() {
    _assertSource(
        "external m();",
        AstTestFactory.methodDeclaration(
            null,
            null,
            null,
            null,
            AstTestFactory.identifier3("m"),
            AstTestFactory.formalParameterList()));
  }

  void test_visitMethodDeclaration_external_returnType() {
    _assertSource(
        "external T m();",
        AstTestFactory.methodDeclaration(
            null,
            AstTestFactory.namedType4("T"),
            null,
            null,
            AstTestFactory.identifier3("m"),
            AstTestFactory.formalParameterList()));
  }

  void test_visitMethodDeclaration_getter() {
    final code = 'get foo => 0;';
    final findNode = _parseStringToFindNode('''
class A {
  $code
}
''');
    _assertSource(code, findNode.methodDeclaration(code));
  }

  void test_visitMethodDeclaration_getter_returnType() {
    final code = 'int get foo => 0;';
    final findNode = _parseStringToFindNode('''
class A {
  $code
}
''');
    _assertSource(code, findNode.methodDeclaration(code));
  }

  void test_visitMethodDeclaration_minimal() {
    final code = 'foo() {}';
    final findNode = _parseStringToFindNode('''
class A {
  $code
}
''');
    _assertSource(code, findNode.methodDeclaration(code));
  }

  void test_visitMethodDeclaration_multipleParameters() {
    final code = 'void foo(int a, double b) {}';
    final findNode = _parseStringToFindNode('''
class A {
  $code
}
''');
    _assertSource(code, findNode.methodDeclaration(code));
  }

  void test_visitMethodDeclaration_operator() {
    final code = 'operator +(int other) {}';
    final findNode = _parseStringToFindNode('''
class A {
  $code
}
''');
    _assertSource(code, findNode.methodDeclaration(code));
  }

  void test_visitMethodDeclaration_operator_returnType() {
    final code = 'int operator +(int other) => 0;';
    final findNode = _parseStringToFindNode('''
class A {
  $code
}
''');
    _assertSource(code, findNode.methodDeclaration(code));
  }

  void test_visitMethodDeclaration_returnType() {
    final code = 'int foo() => 0;';
    final findNode = _parseStringToFindNode('''
class A {
  $code
}
''');
    _assertSource(code, findNode.methodDeclaration(code));
  }

  void test_visitMethodDeclaration_setter() {
    final code = 'set foo(int _) {}';
    final findNode = _parseStringToFindNode('''
class A {
  $code
}
''');
    _assertSource(code, findNode.methodDeclaration(code));
  }

  void test_visitMethodDeclaration_setter_returnType() {
    final code = 'void set foo(int _) {}';
    final findNode = _parseStringToFindNode('''
class A {
  $code
}
''');
    _assertSource(code, findNode.methodDeclaration(code));
  }

  void test_visitMethodDeclaration_static() {
    final code = 'static foo() {}';
    final findNode = _parseStringToFindNode('''
class A {
  $code
}
''');
    _assertSource(code, findNode.methodDeclaration(code));
  }

  void test_visitMethodDeclaration_static_returnType() {
    final code = 'static void foo() {}';
    final findNode = _parseStringToFindNode('''
class A {
  $code
}
''');
    _assertSource(code, findNode.methodDeclaration(code));
  }

  void test_visitMethodDeclaration_typeParameters() {
    final code = 'void foo<T>() {}';
    final findNode = _parseStringToFindNode('''
class A {
  $code
}
''');
    _assertSource(code, findNode.methodDeclaration(code));
  }

  void test_visitMethodDeclaration_withMetadata() {
    final code = '@deprecated void foo() {}';
    final findNode = _parseStringToFindNode('''
class A {
  $code
}
''');
    _assertSource(code, findNode.methodDeclaration(code));
  }

  void test_visitMethodInvocation_conditional() {
    final code = 'a?.foo()';
    final findNode = _parseStringToFindNode('''
void f() {
  $code;
}
''');
    _assertSource(code, findNode.methodInvocation(code));
  }

  void test_visitMethodInvocation_noTarget() {
    final code = 'foo()';
    final findNode = _parseStringToFindNode('''
void f() {
  $code;
}
''');
    _assertSource(code, findNode.methodInvocation(code));
  }

  void test_visitMethodInvocation_target() {
    final code = 'a.foo()';
    final findNode = _parseStringToFindNode('''
void f() {
  $code;
}
''');
    _assertSource(code, findNode.methodInvocation(code));
  }

  void test_visitMethodInvocation_typeArguments() {
    final code = 'foo<int>()';
    final findNode = _parseStringToFindNode('''
void f() {
  $code;
}
''');
    _assertSource(code, findNode.methodInvocation(code));
  }

  void test_visitNamedExpression() {
    _assertSource("a: b",
        AstTestFactory.namedExpression2("a", AstTestFactory.identifier3("b")));
  }

  void test_visitNamedFormalParameter() {
    final code = 'var a = 0';
    final findNode = _parseStringToFindNode('''
void f({$code}) {}
''');
    _assertSource(code, findNode.defaultParameter(code));
  }

  void test_visitNativeClause() {
    _assertSource("native 'code'", AstTestFactory.nativeClause("code"));
  }

  void test_visitNativeFunctionBody() {
    _assertSource("native 'str';", AstTestFactory.nativeFunctionBody("str"));
  }

  void test_visitNullLiteral() {
    _assertSource("null", AstTestFactory.nullLiteral());
  }

  void test_visitParenthesizedExpression() {
    _assertSource(
        "(a)",
        AstTestFactory.parenthesizedExpression(
            AstTestFactory.identifier3("a")));
  }

  @failingTest
  void test_visitParenthesizedPattern() {
    // TODO(brianwilkerson) Test this when the parser allows.
    fail('Unable to parse patterns');
  }

  void test_visitPartDirective() {
    _assertSource("part 'a.dart';", AstTestFactory.partDirective2("a.dart"));
  }

  void test_visitPartDirective_withMetadata() {
    final code = '@deprecated part "a.dart";';
    final findNode = _parseStringToFindNode(code);
    _assertSource(code, findNode.part(code));
  }

  void test_visitPartOfDirective_name() {
    var unit = parseString(content: 'part of l;').unit;
    var directive = unit.directives[0] as PartOfDirective;
    _assertSource("part of l;", directive);
  }

  void test_visitPartOfDirective_uri() {
    var unit = parseString(content: "part of 'a.dart';").unit;
    var directive = unit.directives[0] as PartOfDirective;
    _assertSource("part of 'a.dart';", directive);
  }

  void test_visitPartOfDirective_withMetadata() {
    final code = '@deprecated part of my.lib;';
    final findNode = _parseStringToFindNode(code);
    _assertSource(code, findNode.partOf(code));
  }

  @failingTest
  void test_visitPatternAssignment() {
    // TODO(brianwilkerson) Test this when the parser allows.
    fail('Unable to parse patterns');
  }

  @failingTest
  void test_visitPatternAssignmentStatement() {
    // TODO(brianwilkerson) Test this when the parser allows.
    fail('Unable to parse patterns');
  }

  @failingTest
  void test_visitPatternVariableDeclaration() {
    // TODO(brianwilkerson) Test this when the parser allows.
    fail('Unable to parse patterns');
  }

  @failingTest
  void test_visitPatternVariableDeclarationStatement() {
    // TODO(brianwilkerson) Test this when the parser allows.
    fail('Unable to parse patterns');
  }

  void test_visitPositionalFormalParameter() {
    final code = 'var a = 0';
    final findNode = _parseStringToFindNode('''
void f([$code]) {}
''');
    _assertSource(code, findNode.defaultParameter(code));
  }

  void test_visitPostfixExpression() {
    _assertSource(
        "a++",
        AstTestFactory.postfixExpression(
            AstTestFactory.identifier3("a"), TokenType.PLUS_PLUS));
  }

  @failingTest
  void test_visitPostfixPattern() {
    // TODO(brianwilkerson) Test this when the parser allows.
    fail('Unable to parse patterns');
  }

  void test_visitPrefixedIdentifier() {
    _assertSource("a.b", AstTestFactory.identifier5("a", "b"));
  }

  void test_visitPrefixExpression() {
    _assertSource(
        "-a",
        AstTestFactory.prefixExpression(
            TokenType.MINUS, AstTestFactory.identifier3("a")));
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
    _assertSource("a.b",
        AstTestFactory.propertyAccess2(AstTestFactory.identifier3("a"), "b"));
  }

  void test_visitPropertyAccess_conditional() {
    _assertSource(
        "a?.b",
        AstTestFactory.propertyAccess2(
            AstTestFactory.identifier3("a"), "b", TokenType.QUESTION_PERIOD));
  }

  void test_visitRecordLiteral_mixed() {
    final code = '(0, true, a: 0, b: true)';
    var findNode = _parseStringToFindNode('''
final x = $code;
''');
    _assertSource(
      code,
      findNode.recordLiteral(code),
    );
  }

  void test_visitRecordLiteral_named() {
    final code = '(a: 0, b: true)';
    var findNode = _parseStringToFindNode('''
final x = $code;
''');
    _assertSource(
      code,
      findNode.recordLiteral(code),
    );
  }

  void test_visitRecordLiteral_positional() {
    final code = '(0, true)';
    var findNode = _parseStringToFindNode('''
final x = $code;
''');
    _assertSource(
      code,
      findNode.recordLiteral(code),
    );
  }

  @failingTest
  void test_visitRecordPattern() {
    // TODO(brianwilkerson) Test this when the parser allows.
    fail('Unable to parse patterns');
  }

  @failingTest
  void test_visitRecordPatternField() {
    // TODO(brianwilkerson) Test this when the parser allows.
    fail('Unable to parse patterns');
  }

  @failingTest
  void test_visitRecordPatternFieldName() {
    // TODO(brianwilkerson) Test this when the parser allows.
    fail('Unable to parse patterns');
  }

  void test_visitRecordTypeAnnotation_mixed() {
    final code = '(int, bool, {int a, bool b})';
    var findNode = _parseStringToFindNode('''
$code f() {}
''');
    _assertSource(
      code,
      findNode.recordTypeAnnotation(code),
    );
  }

  void test_visitRecordTypeAnnotation_named() {
    final code = '({int a, bool b})';
    var findNode = _parseStringToFindNode('''
$code f() {}
''');
    _assertSource(
      code,
      findNode.recordTypeAnnotation(code),
    );
  }

  void test_visitRecordTypeAnnotation_positional() {
    final code = '(int, bool)';
    var findNode = _parseStringToFindNode('''
$code f() {}
''');
    _assertSource(
      code,
      findNode.recordTypeAnnotation(code),
    );
  }

  void test_visitRecordTypeAnnotation_positional_nullable() {
    final code = '(int, bool)?';
    var findNode = _parseStringToFindNode('''
$code f() {}
''');
    _assertSource(
      code,
      findNode.recordTypeAnnotation(code),
    );
  }

  void test_visitRedirectingConstructorInvocation_named() {
    _assertSource(
        "this.c()", AstTestFactory.redirectingConstructorInvocation2("c"));
  }

  void test_visitRedirectingConstructorInvocation_unnamed() {
    _assertSource("this()", AstTestFactory.redirectingConstructorInvocation());
  }

  @failingTest
  void test_visitRelationalPattern() {
    // TODO(brianwilkerson) Test this when the parser allows.
    fail('Unable to parse patterns');
  }

  void test_visitRethrowExpression() {
    _assertSource("rethrow", AstTestFactory.rethrowExpression());
  }

  void test_visitReturnStatement_expression() {
    _assertSource("return a;",
        AstTestFactory.returnStatement2(AstTestFactory.identifier3("a")));
  }

  void test_visitReturnStatement_noExpression() {
    _assertSource("return;", AstTestFactory.returnStatement());
  }

  void test_visitScriptTag() {
    String scriptTag = "!#/bin/dart.exe";
    _assertSource(scriptTag, AstTestFactory.scriptTag(scriptTag));
  }

  void test_visitSetOrMapLiteral_map_complex() {
    final code =
        "<String, String>{'a' : 'b', for (c in d) 'e' : 'f', if (g) 'h' : 'i', ...{'j' : 'k'}}";
    final findNode = _parseStringToFindNode('''
final v = $code;
''');
    _assertSource(code, findNode.setOrMapLiteral(code));
  }

  void test_visitSetOrMapLiteral_map_withConst_withoutTypeArgs() {
    _assertSource(
      "const {'a' : 'b'}",
      astFactory.setOrMapLiteral(
        leftBracket: Tokens.openCurlyBracket(),
        constKeyword: TokenFactory.tokenFromKeyword(Keyword.CONST),
        elements: [AstTestFactory.mapLiteralEntry3('a', 'b')],
        rightBracket: Tokens.closeCurlyBracket(),
      ),
    );
  }

  void test_visitSetOrMapLiteral_map_withConst_withTypeArgs() {
    _assertSource(
      "const <String, String>{'a' : 'b'}",
      astFactory.setOrMapLiteral(
        constKeyword: TokenFactory.tokenFromKeyword(Keyword.CONST),
        typeArguments: AstTestFactory.typeArgumentList([
          AstTestFactory.namedType4('String'),
          AstTestFactory.namedType4('String')
        ]),
        leftBracket: Tokens.openCurlyBracket(),
        elements: [AstTestFactory.mapLiteralEntry3('a', 'b')],
        rightBracket: Tokens.closeCurlyBracket(),
      ),
    );
  }

  void test_visitSetOrMapLiteral_map_withoutConst_withoutTypeArgs() {
    _assertSource(
      "{'a' : 'b'}",
      astFactory.setOrMapLiteral(
        leftBracket: Tokens.openCurlyBracket(),
        elements: [AstTestFactory.mapLiteralEntry3('a', 'b')],
        rightBracket: Tokens.closeCurlyBracket(),
      ),
    );
  }

  void test_visitSetOrMapLiteral_map_withoutConst_withTypeArgs() {
    _assertSource(
      "<String, String>{'a' : 'b'}",
      astFactory.setOrMapLiteral(
        typeArguments: AstTestFactory.typeArgumentList([
          AstTestFactory.namedType4('String'),
          AstTestFactory.namedType4('String')
        ]),
        leftBracket: Tokens.openCurlyBracket(),
        elements: [AstTestFactory.mapLiteralEntry3('a', 'b')],
        rightBracket: Tokens.closeCurlyBracket(),
      ),
    );
  }

  void test_visitSetOrMapLiteral_set_complex() {
    final code = '<int>{0, for (e in l) 0, if (b) 1, ...[0]}';
    final findNode = _parseStringToFindNode('''
final v = $code;
''');
    _assertSource(code, findNode.setOrMapLiteral(code));
  }

  void test_visitSetOrMapLiteral_set_withConst_withoutTypeArgs() {
    _assertSource(
      'const {0}',
      astFactory.setOrMapLiteral(
        constKeyword: TokenFactory.tokenFromKeyword(Keyword.CONST),
        leftBracket: Tokens.openCurlyBracket(),
        elements: [AstTestFactory.integer(0)],
        rightBracket: Tokens.closeCurlyBracket(),
      ),
    );
  }

  void test_visitSetOrMapLiteral_set_withConst_withTypeArgs() {
    _assertSource(
      'const <int>{0}',
      astFactory.setOrMapLiteral(
        constKeyword: TokenFactory.tokenFromKeyword(Keyword.CONST),
        typeArguments:
            AstTestFactory.typeArgumentList([AstTestFactory.namedType4('int')]),
        leftBracket: Tokens.openCurlyBracket(),
        elements: [AstTestFactory.integer(0)],
        rightBracket: Tokens.closeCurlyBracket(),
      ),
    );
  }

  void test_visitSetOrMapLiteral_set_withoutConst_withoutTypeArgs() {
    _assertSource(
      '{0}',
      astFactory.setOrMapLiteral(
        leftBracket: Tokens.openCurlyBracket(),
        elements: [AstTestFactory.integer(0)],
        rightBracket: Tokens.closeCurlyBracket(),
      ),
    );
  }

  void test_visitSetOrMapLiteral_set_withoutConst_withTypeArgs() {
    _assertSource(
      '<int>{0}',
      astFactory.setOrMapLiteral(
        typeArguments:
            AstTestFactory.typeArgumentList([AstTestFactory.namedType4('int')]),
        leftBracket: Tokens.openCurlyBracket(),
        elements: [AstTestFactory.integer(0)],
        rightBracket: Tokens.closeCurlyBracket(),
      ),
    );
  }

  void test_visitSimpleFormalParameter_annotation() {
    final code = '@deprecated int x';
    final findNode = _parseStringToFindNode('''
void f($code) {}
''');
    _assertSource(code, findNode.simpleFormalParameter(code));
  }

  void test_visitSimpleFormalParameter_keyword() {
    _assertSource(
        "var a", AstTestFactory.simpleFormalParameter(Keyword.VAR, "a"));
  }

  void test_visitSimpleFormalParameter_keyword_type() {
    _assertSource(
        "final A a",
        AstTestFactory.simpleFormalParameter2(
            Keyword.FINAL, AstTestFactory.namedType4("A"), "a"));
  }

  void test_visitSimpleFormalParameter_type() {
    _assertSource(
        "A a",
        AstTestFactory.simpleFormalParameter4(
            AstTestFactory.namedType4("A"), "a"));
  }

  void test_visitSimpleFormalParameter_type_covariant() {
    var expected = AstTestFactory.simpleFormalParameter4(
        AstTestFactory.namedType4("A"), "a");
    expected.covariantKeyword =
        TokenFactory.tokenFromKeyword(Keyword.COVARIANT);
    _assertSource("covariant A a", expected);
  }

  void test_visitSimpleIdentifier() {
    _assertSource("a", AstTestFactory.identifier3("a"));
  }

  void test_visitSimpleStringLiteral() {
    _assertSource("'a'", AstTestFactory.string2("a"));
  }

  void test_visitSpreadElement_nonNullable() {
    _assertSource(
        '...[0]',
        astFactory.spreadElement(
            spreadOperator:
                TokenFactory.tokenFromType(TokenType.PERIOD_PERIOD_PERIOD),
            expression: astFactory.listLiteral(
                null,
                null,
                Tokens.openSquareBracket(),
                [AstTestFactory.integer(0)],
                Tokens.closeSquareBracket())));
  }

  @failingTest
  void test_visitSpreadElement_nullable() {
    // TODO(brianwilkerson) Replace the token type below when there is one for
    //  '...?'.
    _assertSource(
        '...?[0]',
        astFactory.spreadElement(
            spreadOperator:
                TokenFactory.tokenFromType(TokenType.PERIOD_PERIOD_PERIOD),
            expression: astFactory.listLiteral(
                null,
                null,
                Tokens.openSquareBracket(),
                [AstTestFactory.integer(0)],
                Tokens.closeSquareBracket())));
  }

  void test_visitStringInterpolation() {
    _assertSource(
        "'a\${e}b'",
        AstTestFactory.string([
          AstTestFactory.interpolationString("'a", "a"),
          AstTestFactory.interpolationExpression(
              AstTestFactory.identifier3("e")),
          AstTestFactory.interpolationString("b'", "b")
        ]));
  }

  void test_visitSuperConstructorInvocation() {
    _assertSource("super()", AstTestFactory.superConstructorInvocation());
  }

  void test_visitSuperConstructorInvocation_named() {
    _assertSource("super.c()", AstTestFactory.superConstructorInvocation2("c"));
  }

  void test_visitSuperExpression() {
    _assertSource("super", AstTestFactory.superExpression());
  }

  void test_visitSuperFormalParameter_annotation() {
    final code = '@deprecated super.foo';
    final findNode = _parseStringToFindNode('''
class A {
  A($code);
}
''');
    _assertSource(code, findNode.superFormalParameter(code));
  }

  void test_visitSuperFormalParameter_functionTyped() {
    _assertSource(
        "A super.a(b)",
        AstTestFactory.superFormalParameter(
            null,
            AstTestFactory.namedType4("A"),
            "a",
            AstTestFactory.formalParameterList(
                [AstTestFactory.simpleFormalParameter3("b")])));
  }

  void test_visitSuperFormalParameter_functionTyped_typeParameters() {
    _assertSource(
        "A super.a<E, F>(b)",
        astFactory.superFormalParameter(
            type: AstTestFactory.namedType4('A'),
            superKeyword: TokenFactory.tokenFromKeyword(Keyword.SUPER),
            period: TokenFactory.tokenFromType(TokenType.PERIOD),
            identifier: AstTestFactory.identifier3('a'),
            typeParameters: AstTestFactory.typeParameterList(['E', 'F']),
            parameters: AstTestFactory.formalParameterList(
                [AstTestFactory.simpleFormalParameter3("b")])));
  }

  void test_visitSuperFormalParameter_keyword() {
    _assertSource("var super.a",
        AstTestFactory.superFormalParameter(Keyword.VAR, null, "a"));
  }

  void test_visitSuperFormalParameter_keywordAndType() {
    _assertSource(
        "final A super.a",
        AstTestFactory.superFormalParameter(
            Keyword.FINAL, AstTestFactory.namedType4("A"), "a"));
  }

  void test_visitSuperFormalParameter_type() {
    _assertSource(
        "A super.a",
        AstTestFactory.superFormalParameter(
            null, AstTestFactory.namedType4("A"), "a"));
  }

  void test_visitSuperFormalParameter_type_covariant() {
    var expected = AstTestFactory.superFormalParameter(
        null, AstTestFactory.namedType4("A"), "a");
    expected.covariantKeyword =
        TokenFactory.tokenFromKeyword(Keyword.COVARIANT);
    _assertSource("covariant A super.a", expected);
  }

  void test_visitSwitchCase_multipleLabels() {
    final code = 'l1: l2: case a: {}';
    final findNode = _parseStringToFindNode('''
void f() {
  switch (x) {
    $code
  }
}
''');
    _assertSource(code, findNode.switchCase(code));
  }

  void test_visitSwitchCase_multipleStatements() {
    final code = 'case a: foo(); bar();';
    final findNode = _parseStringToFindNode('''
void f() {
  switch (x) {
    $code
  }
}
''');
    _assertSource(code, findNode.switchCase(code));
  }

  void test_visitSwitchCase_noLabels() {
    final code = 'case a: {}';
    final findNode = _parseStringToFindNode('''
void f() {
  switch (x) {
    $code
  }
}
''');
    _assertSource(code, findNode.switchCase(code));
  }

  void test_visitSwitchCase_singleLabel() {
    final code = 'l1: case a: {}';
    final findNode = _parseStringToFindNode('''
void f() {
  switch (x) {
    $code
  }
}
''');
    _assertSource(code, findNode.switchCase(code));
  }

  void test_visitSwitchDefault_multipleLabels() {
    final code = 'l1: l2: default: {}';
    final findNode = _parseStringToFindNode('''
void f() {
  switch (x) {
    $code
  }
}
''');
    _assertSource(code, findNode.switchDefault(code));
  }

  void test_visitSwitchDefault_multipleStatements() {
    final code = 'default: foo(); bar();';
    final findNode = _parseStringToFindNode('''
void f() {
  switch (x) {
    $code
  }
}
''');
    _assertSource(code, findNode.switchDefault(code));
  }

  void test_visitSwitchDefault_noLabels() {
    final code = 'default: {}';
    final findNode = _parseStringToFindNode('''
void f() {
  switch (x) {
    $code
  }
}
''');
    _assertSource(code, findNode.switchDefault(code));
  }

  void test_visitSwitchDefault_singleLabel() {
    final code = 'l1: default: {}';
    final findNode = _parseStringToFindNode('''
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
    // TODO(brianwilkerson) Test this when the parser allows.
    fail('Unable to parse patterns');
  }

  @failingTest
  void test_visitSwitchExpressionCase() {
    // TODO(brianwilkerson) Test this when the parser allows.
    fail('Unable to parse patterns');
  }

  @failingTest
  void test_visitSwitchExpressionDefault() {
    // TODO(brianwilkerson) Test this when the parser allows.
    fail('Unable to parse patterns');
  }

  @failingTest
  void test_visitSwitchGuard() {
    // TODO(brianwilkerson) Test this when the parser allows.
    fail('Unable to parse patterns');
  }

  @failingTest
  void test_visitSwitchPatternCase() {
    // TODO(brianwilkerson) Test this when the parser allows.
    fail('Unable to parse patterns');
  }

  void test_visitSwitchStatement() {
    final code = 'switch (x) {case 0: foo(); default: bar();}';
    final findNode = _parseStringToFindNode('''
void f() {
  $code
}
''');
    _assertSource(code, findNode.switchStatement(code));
  }

  void test_visitSymbolLiteral_multiple() {
    _assertSource("#a.b.c", AstTestFactory.symbolLiteral(["a", "b", "c"]));
  }

  void test_visitSymbolLiteral_single() {
    _assertSource("#a", AstTestFactory.symbolLiteral(["a"]));
  }

  void test_visitThisExpression() {
    _assertSource("this", AstTestFactory.thisExpression());
  }

  void test_visitThrowStatement() {
    _assertSource("throw e",
        AstTestFactory.throwExpression2(AstTestFactory.identifier3("e")));
  }

  void test_visitTopLevelVariableDeclaration_external() {
    _assertSource(
        "external var a;",
        AstTestFactory.topLevelVariableDeclaration2(
            Keyword.VAR, [AstTestFactory.variableDeclaration("a")],
            isExternal: true));
  }

  void test_visitTopLevelVariableDeclaration_multiple() {
    _assertSource(
        "var a;",
        AstTestFactory.topLevelVariableDeclaration2(
            Keyword.VAR, [AstTestFactory.variableDeclaration("a")]));
  }

  void test_visitTopLevelVariableDeclaration_single() {
    _assertSource(
        "var a, b;",
        AstTestFactory.topLevelVariableDeclaration2(Keyword.VAR, [
          AstTestFactory.variableDeclaration("a"),
          AstTestFactory.variableDeclaration("b")
        ]));
  }

  void test_visitTryStatement_catch() {
    final code = 'try {} on E {}';
    final findNode = _parseStringToFindNode('''
void f() {
  $code
}
''');
    _assertSource(code, findNode.tryStatement(code));
  }

  void test_visitTryStatement_catches() {
    final code = 'try {} on E {} on F {}';
    final findNode = _parseStringToFindNode('''
void f() {
  $code
}
''');
    _assertSource(code, findNode.tryStatement(code));
  }

  void test_visitTryStatement_catchFinally() {
    final code = 'try {} on E {} finally {}';
    final findNode = _parseStringToFindNode('''
void f() {
  $code
}
''');
    _assertSource(code, findNode.tryStatement(code));
  }

  void test_visitTryStatement_finally() {
    final code = 'try {} finally {}';
    final findNode = _parseStringToFindNode('''
void f() {
  $code
}
''');
    _assertSource(code, findNode.tryStatement(code));
  }

  void test_visitTypeArgumentList_multiple() {
    _assertSource(
        "<E, F>",
        AstTestFactory.typeArgumentList2(
            [AstTestFactory.namedType4("E"), AstTestFactory.namedType4("F")]));
  }

  void test_visitTypeArgumentList_single() {
    _assertSource("<E>",
        AstTestFactory.typeArgumentList2([AstTestFactory.namedType4("E")]));
  }

  void test_visitTypeName_multipleArgs() {
    _assertSource(
        "C<D, E>",
        AstTestFactory.namedType4("C",
            [AstTestFactory.namedType4("D"), AstTestFactory.namedType4("E")]));
  }

  void test_visitTypeName_nestedArg() {
    _assertSource(
        "C<D<E>>",
        AstTestFactory.namedType4("C", [
          AstTestFactory.namedType4("D", [AstTestFactory.namedType4("E")])
        ]));
  }

  void test_visitTypeName_noArgs() {
    _assertSource("C", AstTestFactory.namedType4("C"));
  }

  void test_visitTypeName_noArgs_withQuestion() {
    _assertSource("C?", AstTestFactory.namedType4("C", null, true));
  }

  void test_visitTypeName_singleArg() {
    _assertSource("C<D>",
        AstTestFactory.namedType4("C", [AstTestFactory.namedType4("D")]));
  }

  void test_visitTypeName_singleArg_withQuestion() {
    _assertSource("C<D>?",
        AstTestFactory.namedType4("C", [AstTestFactory.namedType4("D")], true));
  }

  void test_visitTypeParameter_variance_contravariant() {
    _assertSource("in E", AstTestFactory.typeParameter3("E", "in"));
  }

  void test_visitTypeParameter_variance_covariant() {
    _assertSource("out E", AstTestFactory.typeParameter3("E", "out"));
  }

  void test_visitTypeParameter_variance_invariant() {
    _assertSource("inout E", AstTestFactory.typeParameter3("E", "inout"));
  }

  void test_visitTypeParameter_withExtends() {
    _assertSource("E extends C",
        AstTestFactory.typeParameter2("E", AstTestFactory.namedType4("C")));
  }

  void test_visitTypeParameter_withMetadata() {
    final code = '@deprecated T';
    final findNode = _parseStringToFindNode('''
class A<$code> {}
''');
    _assertSource(code, findNode.typeParameter(code));
  }

  void test_visitTypeParameter_withoutExtends() {
    _assertSource("E", AstTestFactory.typeParameter("E"));
  }

  void test_visitTypeParameterList_multiple() {
    _assertSource("<E, F>", AstTestFactory.typeParameterList2(["E", "F"]));
  }

  void test_visitTypeParameterList_single() {
    _assertSource("<E>", AstTestFactory.typeParameterList2(["E"]));
  }

  void test_visitVariableDeclaration_initialized() {
    _assertSource(
        "a = b",
        AstTestFactory.variableDeclaration2(
            "a", AstTestFactory.identifier3("b")));
  }

  void test_visitVariableDeclaration_uninitialized() {
    _assertSource("a", AstTestFactory.variableDeclaration("a"));
  }

  void test_visitVariableDeclarationList_const_type() {
    _assertSource(
        "const C a, b",
        AstTestFactory.variableDeclarationList(
            Keyword.CONST, AstTestFactory.namedType4("C"), [
          AstTestFactory.variableDeclaration("a"),
          AstTestFactory.variableDeclaration("b")
        ]));
  }

  void test_visitVariableDeclarationList_final_noType() {
    _assertSource(
        "final a, b",
        AstTestFactory.variableDeclarationList2(Keyword.FINAL, [
          AstTestFactory.variableDeclaration("a"),
          AstTestFactory.variableDeclaration("b")
        ]));
  }

  void test_visitVariableDeclarationList_type() {
    _assertSource(
        "C a, b",
        AstTestFactory.variableDeclarationList(
            null, AstTestFactory.namedType4("C"), [
          AstTestFactory.variableDeclaration("a"),
          AstTestFactory.variableDeclaration("b")
        ]));
  }

  void test_visitVariableDeclarationList_var() {
    _assertSource(
        "var a, b",
        AstTestFactory.variableDeclarationList2(Keyword.VAR, [
          AstTestFactory.variableDeclaration("a"),
          AstTestFactory.variableDeclaration("b")
        ]));
  }

  void test_visitVariableDeclarationStatement() {
    _assertSource(
        "C c;",
        AstTestFactory.variableDeclarationStatement(
            null,
            AstTestFactory.namedType4("C"),
            [AstTestFactory.variableDeclaration("c")]));
  }

  @failingTest
  void test_visitVariablePattern() {
    // TODO(brianwilkerson) Test this when the parser allows.
    fail('Unable to parse patterns');
  }

  void test_visitWhileStatement() {
    final code = 'while (true) {}';
    final findNode = _parseStringToFindNode('''
void f() {
  $code
}
''');
    _assertSource(code, findNode.whileStatement(code));
  }

  void test_visitWithClause_multiple() {
    _assertSource(
        "with A, B, C",
        AstTestFactory.withClause([
          AstTestFactory.namedType4("A"),
          AstTestFactory.namedType4("B"),
          AstTestFactory.namedType4("C")
        ]));
  }

  void test_visitWithClause_single() {
    _assertSource(
        "with A", AstTestFactory.withClause([AstTestFactory.namedType4("A")]));
  }

  void test_visitYieldStatement() {
    _assertSource("yield e;",
        AstTestFactory.yieldStatement(AstTestFactory.identifier3("e")));
  }

  void test_visitYieldStatement_each() {
    _assertSource("yield* e;",
        AstTestFactory.yieldEachStatement(AstTestFactory.identifier3("e")));
  }

  /// Assert that a [ToSourceVisitor] will produce the [expectedSource] when
  /// visiting the given [node].
  void _assertSource(String expectedSource, AstNode node) {
    StringBuffer buffer = StringBuffer();
    node.accept(ToSourceVisitor(buffer));
    expect(buffer.toString(), expectedSource);
  }

  /// TODO(scheglov) Use [parseStringWithErrors] everywhere? Or just there?
  FindNode _parseStringToFindNode(String content) {
    var parseResult = parseString(
      content: content,
      featureSet: FeatureSets.latestWithExperiments,
    );
    return FindNode(parseResult.content, parseResult.unit);
  }
}
