// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../src/diagnostics/parser_diagnostics.dart';
import '../util/feature_sets.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ErrorParserTest);
  });
}

/// This defines parser tests that test the parsing of code to ensure that
/// errors are correctly reported, and in some cases, not reported.
@reflectiveTest
class ErrorParserTest extends ParserDiagnosticsTest {
  void test_abstractClassMember_constructor() {
    var parseResult = parseStringWithErrors(r'''
abstract class C {
  abstract C.c();
}
''');
    parseResult.assertErrors([error(diag.abstractClassMember, 21, 8)]);
  }

  void test_abstractClassMember_field() {
    var parseResult = parseStringWithErrors(r'''
abstract class C {
  abstract C f;
}
''');
    parseResult.assertNoErrors();
  }

  void test_abstractClassMember_getter() {
    var parseResult = parseStringWithErrors(r'''
abstract class C {
  abstract get m;
}
''');
    parseResult.assertErrors([error(diag.abstractClassMember, 21, 8)]);
  }

  void test_abstractClassMember_method() {
    var parseResult = parseStringWithErrors(r'''
abstract class C {
  abstract m();
}
''');
    parseResult.assertErrors([error(diag.abstractClassMember, 21, 8)]);
  }

  void test_abstractClassMember_setter() {
    var parseResult = parseStringWithErrors(r'''
abstract class C {
  abstract set m(v);
}
''');
    parseResult.assertErrors([error(diag.abstractClassMember, 21, 8)]);
  }

  void test_abstractEnum() {
    var parseResult = parseStringWithErrors(r'''
abstract enum E {ONE}
''');
    parseResult.assertErrors([error(diag.extraneousModifier, 0, 8)]);
  }

  void test_abstractTopLevelFunction_function() {
    var parseResult = parseStringWithErrors(r'''
abstract f(v) {}
''');
    parseResult.assertErrors([error(diag.extraneousModifier, 0, 8)]);
  }

  void test_abstractTopLevelFunction_getter() {
    var parseResult = parseStringWithErrors(r'''
abstract get m {}
''');
    parseResult.assertErrors([error(diag.extraneousModifier, 0, 8)]);
  }

  void test_abstractTopLevelFunction_setter() {
    var parseResult = parseStringWithErrors(r'''
abstract set m(v) {}
''');
    parseResult.assertErrors([error(diag.extraneousModifier, 0, 8)]);
  }

  void test_abstractTopLevelVariable() {
    var parseResult = parseStringWithErrors(r'''
abstract C f;
''');
    parseResult.assertErrors([error(diag.extraneousModifier, 0, 8)]);
  }

  void test_abstractTypeDef() {
    var parseResult = parseStringWithErrors(r'''
abstract typedef F();
''');
    parseResult.assertErrors([error(diag.extraneousModifier, 0, 8)]);
  }

  void test_await_missing_async2_issue36048() {
    var parseResult = parseStringWithErrors(r'''
main() { // missing async
  await foo.bar();
}
''');
    parseResult.assertErrors([error(diag.awaitInWrongContext, 28, 5)]);
  }

  void test_await_missing_async3_issue36048() {
    // missing async
    var parseResult = parseStringWithErrors(r'''
main() {
  (await foo);
}
''');
    parseResult.assertErrors([error(diag.awaitInWrongContext, 12, 5)]);
  }

  void test_await_missing_async4_issue36048() {
    // missing async
    var parseResult = parseStringWithErrors(r'''
main() {
  [await foo];
}
''');
    parseResult.assertErrors([error(diag.awaitInWrongContext, 12, 5)]);
  }

  void test_await_missing_async_issue36048() {
    var parseResult = parseStringWithErrors(r'''
main() { // missing async
  await foo();
}
''');
    parseResult.assertErrors([error(diag.awaitInWrongContext, 28, 5)]);
  }

  void test_breakOutsideOfLoop_breakInDoStatement() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  do {break;} while (x);
}
''');
    parseResult.assertNoErrors();
  }

  void test_breakOutsideOfLoop_breakInForStatement() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  for (; x;) {break;}
}
''');
    parseResult.assertNoErrors();
  }

  void test_breakOutsideOfLoop_breakInIfStatement() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  if (x) {break;}
}
''');
    parseResult.assertErrors([error(diag.breakOutsideOfLoop, 21, 5)]);
  }

  void test_breakOutsideOfLoop_breakInSwitchStatement() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  switch (x) {case 1: break;}
}
''');
    parseResult.assertNoErrors();
  }

  void test_breakOutsideOfLoop_breakInWhileStatement() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  while (x) {break;}
}
''');
    parseResult.assertNoErrors();
  }

  void test_breakOutsideOfLoop_functionExpression_inALoop() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  for(; x;) {() {break;};}
}
''');
    parseResult.assertErrors([error(diag.breakOutsideOfLoop, 28, 5)]);
  }

  void test_breakOutsideOfLoop_functionExpression_withALoop() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  () {for (; x;) {break;}};
}
''');
    parseResult.assertNoErrors();
  }

  void test_classInClass_abstract() {
    var parseResult = parseStringWithErrors(r'''
class C { abstract class B {} }
''');
    parseResult.assertErrors([
      error(diag.abstractClassMember, 10, 8),
      error(diag.classInClass, 19, 5),
    ]);
  }

  void test_classInClass_nonAbstract() {
    var parseResult = parseStringWithErrors(r'''
class C { class B {} }
''');
    parseResult.assertErrors([error(diag.classInClass, 10, 5)]);
  }

  void test_classTypeAlias_abstractAfterEq() {
    // This syntax has been removed from the language in favor of
    // "abstract class A = B with C;" (issue 18098).
    var parseResult = parseStringWithErrors(r'''
class A = abstract B with C;
''');
    parseResult.assertErrors([
      error(diag.builtInIdentifierAsType, 10, 8),
      error(diag.expectedToken, 19, 1),
      error(diag.expectedToken, 19, 1),
      error(diag.missingConstFinalVarOrType, 21, 4),
      error(diag.expectedIdentifierButGotKeyword, 21, 4),
      error(diag.expectedToken, 21, 4),
      error(diag.missingConstFinalVarOrType, 26, 1),
    ]);
  }

  void test_colonInPlaceOfIn() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  for (var x : list) {}
}
''');
    parseResult.assertErrors([error(diag.colonInPlaceOfIn, 24, 1)]);
  }

  void test_constAndCovariant() {
    var parseResult = parseStringWithErrors(r'''
class C {
  covariant const C f = null;
}
''');
    parseResult.assertErrors([error(diag.conflictingModifiers, 22, 5)]);
  }

  void test_constAndFinal() {
    var parseResult = parseStringWithErrors(r'''
class C {
  const final int x = null;
}
''');
    parseResult.assertErrors([error(diag.constAndFinal, 18, 5)]);
  }

  void test_constAndVar() {
    var parseResult = parseStringWithErrors(r'''
class C {
  const var x = null;
}
''');
    parseResult.assertErrors([error(diag.conflictingModifiers, 18, 3)]);
  }

  void test_constClass() {
    var parseResult = parseStringWithErrors(r'''
const class C {}
''');
    parseResult.assertErrors([error(diag.constClass, 0, 5)]);
  }

  void test_constEnum() {
    var parseResult = parseStringWithErrors(r'''
const enum E {ONE}
''');
    parseResult.assertErrors([
      // Fasta interprets the `const` as a malformed top level const
      // and `enum` as the start of an enum declaration.
      error(diag.expectedToken, 0, 5),
      error(diag.missingIdentifier, 6, 4),
    ]);
  }

  void test_constFactory() {
    var parseResult = parseStringWithErrors(r'''
class C {
  const factory C() {}
}
''');
    parseResult.assertNoErrors();
  }

  void test_constMethod() {
    var parseResult = parseStringWithErrors(r'''
class C {
  const int m() {}
}
''');
    parseResult.assertErrors([error(diag.constMethod, 12, 5)]);
  }

  void test_constMethod_noReturnType() {
    var parseResult = parseStringWithErrors(r'''
class C {
  const m() {}
}
''');
    parseResult.assertErrors([error(diag.constMethod, 12, 5)]);
  }

  void test_constMethod_noReturnType2() {
    var parseResult = parseStringWithErrors(r'''
class C {
  const m();
}
''');
    parseResult.assertErrors([error(diag.constMethod, 12, 5)]);
  }

  void test_constructor_super_cascade_synthetic() {
    // https://github.com/dart-lang/sdk/issues/37110
    var parseResult = parseStringWithErrors(r'''
class B extends A { B(): super.. {} }
''');
    parseResult.assertErrors([
      error(diag.invalidSuperInInitializer, 25, 5),
      error(diag.expectedToken, 30, 2),
      error(diag.missingIdentifier, 33, 1),
    ]);
  }

  void test_constructor_super_field() {
    // https://github.com/dart-lang/sdk/issues/36262
    // https://github.com/dart-lang/sdk/issues/31198
    var parseResult = parseStringWithErrors(r'''
class B extends A { B(): super().foo {} }
''');
    parseResult.assertErrors([error(diag.invalidSuperInInitializer, 25, 5)]);
  }

  void test_constructor_super_method() {
    // https://github.com/dart-lang/sdk/issues/36262
    // https://github.com/dart-lang/sdk/issues/31198
    var parseResult = parseStringWithErrors(r'''
class B extends A { B(): super().foo() {} }
''');
    parseResult.assertErrors([error(diag.invalidSuperInInitializer, 25, 5)]);
  }

  void test_constructor_super_named_method() {
    // https://github.com/dart-lang/sdk/issues/37600
    var parseResult = parseStringWithErrors(r'''
class B extends A { B(): super.c().create() {} }
''');
    parseResult.assertErrors([error(diag.invalidSuperInInitializer, 25, 5)]);
  }

  void test_constructor_super_named_method_method() {
    // https://github.com/dart-lang/sdk/issues/37600
    var parseResult = parseStringWithErrors(r'''
class B extends A { B(): super.c().create().x() {} }
''');
    parseResult.assertErrors([error(diag.invalidSuperInInitializer, 25, 5)]);
  }

  void test_constructor_this_cascade_synthetic() {
    // https://github.com/dart-lang/sdk/issues/37110
    var parseResult = parseStringWithErrors(r'''
class B extends A { B(): this.. {} }
''');
    parseResult.assertErrors([
      error(diag.missingAssignmentInInitializer, 25, 4),
      error(diag.expectedToken, 29, 2),
      error(diag.missingIdentifier, 32, 1),
    ]);
  }

  void test_constructor_this_field() {
    // https://github.com/dart-lang/sdk/issues/36262
    // https://github.com/dart-lang/sdk/issues/31198
    var parseResult = parseStringWithErrors(r'''
class B extends A { B(): this().foo; }
''');
    parseResult.assertErrors([error(diag.invalidThisInInitializer, 25, 4)]);
  }

  void test_constructor_this_method() {
    // https://github.com/dart-lang/sdk/issues/36262
    // https://github.com/dart-lang/sdk/issues/31198
    var parseResult = parseStringWithErrors(r'''
class B extends A { B(): this().foo(); }
''');
    parseResult.assertErrors([error(diag.invalidThisInInitializer, 25, 4)]);
  }

  void test_constructor_this_named_method() {
    // https://github.com/dart-lang/sdk/issues/37600
    var parseResult = parseStringWithErrors(r'''
class B extends A { B(): super.c().create() {} }
''');
    parseResult.assertErrors([error(diag.invalidSuperInInitializer, 25, 5)]);
  }

  void test_constructor_this_named_method_field() {
    // https://github.com/dart-lang/sdk/issues/37600
    var parseResult = parseStringWithErrors(r'''
class B extends A { B(): super.c().create().x {} }
''');
    parseResult.assertErrors([error(diag.invalidSuperInInitializer, 25, 5)]);
  }

  void test_constructorPartial() {
    var parseResult = parseStringWithErrors(r'''
class C { C< }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 11, 1),
      error(diag.expectedTypeName, 13, 1),
      error(diag.missingIdentifier, 13, 1),
    ]);
  }

  void test_constructorPartial2() {
    var parseResult = parseStringWithErrors(r'''
class C { C<@Foo }
''');
    parseResult.assertErrors([
      error(diag.annotationOnTypeArgument, 12, 4),
      error(diag.expectedToken, 13, 3),
      error(diag.expectedTypeName, 17, 1),
      error(diag.missingIdentifier, 17, 1),
    ]);
  }

  void test_constructorPartial3() {
    var parseResult = parseStringWithErrors(r'''
class C { C<@Foo @Bar() }
''');
    parseResult.assertErrors([
      error(diag.annotationOnTypeArgument, 12, 4),
      error(diag.annotationOnTypeArgument, 17, 6),
      error(diag.expectedToken, 22, 1),
      error(diag.expectedTypeName, 24, 1),
      error(diag.missingIdentifier, 24, 1),
    ]);
  }

  void test_constructorWithReturnType() {
    var parseResult = parseStringWithErrors(r'''
class C {
  C C() {}
}
''');
    parseResult.assertErrors([error(diag.constructorWithReturnType, 12, 1)]);
  }

  void test_constructorWithReturnType_var() {
    var parseResult = parseStringWithErrors(r'''
class C {
  var C() {}
}
''');
    parseResult.assertErrors([error(diag.varReturnType, 12, 3)]);
  }

  void test_constTypedef() {
    var parseResult = parseStringWithErrors(r'''
const typedef F();
''');
    parseResult.assertErrors([
      // Fasta interprets the `const` as a malformed top level const
      // and `typedef` as the start of an typedef declaration.
      error(diag.expectedToken, 0, 5),
      error(diag.missingIdentifier, 6, 7),
    ]);
  }

  void test_continueOutsideOfLoop_continueInDoStatement() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  do {continue;} while (x);
}
''');
    parseResult.assertNoErrors();
  }

  void test_continueOutsideOfLoop_continueInForStatement() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  for (; x;) {continue;}
}
''');
    parseResult.assertNoErrors();
  }

  void test_continueOutsideOfLoop_continueInIfStatement() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  if (x) {continue;}
}
''');
    parseResult.assertErrors([error(diag.continueOutsideOfLoop, 21, 8)]);
  }

  void test_continueOutsideOfLoop_continueInSwitchStatement() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  switch (x) {case 1: continue a;}
}
''');
    parseResult.assertNoErrors();
  }

  void test_continueOutsideOfLoop_continueInWhileStatement() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  while (x) {continue;}
}
''');
    parseResult.assertNoErrors();
  }

  void test_continueOutsideOfLoop_functionExpression_inALoop() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  for(; x;) {() {continue;};}
}
''');
    parseResult.assertErrors([error(diag.continueOutsideOfLoop, 28, 8)]);
  }

  void test_continueOutsideOfLoop_functionExpression_withALoop() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  () {for (; x;) {continue;}};
}
''');
    parseResult.assertNoErrors();
  }

  void test_continueWithoutLabelInCase_error() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  switch (x) {case 1: continue;}
}
''');
    parseResult.assertErrors([error(diag.continueWithoutLabelInCase, 33, 8)]);
  }

  void test_continueWithoutLabelInCase_noError() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  switch (x) {case 1: continue a;}
}
''');
    parseResult.assertNoErrors();
  }

  void test_continueWithoutLabelInCase_noError_switchInLoop() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  while (a) { switch (b) {default: continue;}}
}
''');
    parseResult.assertNoErrors();
  }

  void test_covariantAfterVar() {
    var parseResult = parseStringWithErrors(r'''
class C {
  var covariant f;
}
''');
    parseResult.assertErrors([error(diag.modifierOutOfOrder, 16, 9)]);
  }

  void test_covariantAndFinal() {
    var parseResult = parseStringWithErrors(r'''
class C {
  covariant final f = null;
}
''');
    parseResult.assertErrors([error(diag.finalAndCovariant, 12, 9)]);
  }

  void test_covariantAndStatic() {
    var parseResult = parseStringWithErrors(r'''
class C {
  covariant static A f;
}
''');
    parseResult.assertErrors([error(diag.covariantAndStatic, 22, 6)]);
  }

  void test_covariantAndType_local() {
    // This is currently reporting EXPECTED_TOKEN for a missing semicolon, but
    // this would be a better error message.
    var parseResult = parseStringWithErrors(r'''
void f() {
  covariant int x;
}
''');
    parseResult.assertErrors([error(diag.extraneousModifier, 13, 9)]);
  }

  void test_covariantConstructor() {
    var parseResult = parseStringWithErrors(r'''
class C { covariant C(); }
''');
    parseResult.assertErrors([error(diag.covariantMember, 10, 9)]);
  }

  void test_covariantMember_getter_noReturnType() {
    var parseResult = parseStringWithErrors(r'''
class C {
  static covariant get x => 0;
}
''');
    parseResult.assertErrors([error(diag.covariantAndStatic, 19, 9)]);
  }

  void test_covariantMember_getter_returnType() {
    var parseResult = parseStringWithErrors(r'''
class C {
  static covariant int get x => 0;
}
''');
    parseResult.assertErrors([error(diag.covariantAndStatic, 19, 9)]);
  }

  void test_covariantMember_method() {
    var parseResult = parseStringWithErrors(r'''
class C {
  covariant int m() => 0;
}
''');
    parseResult.assertErrors([error(diag.covariantMember, 12, 9)]);
  }

  void test_covariantTopLevelDeclaration_class() {
    var parseResult = parseStringWithErrors(r'''
covariant class C {}
''');
    parseResult.assertErrors([error(diag.extraneousModifier, 0, 9)]);
  }

  void test_covariantTopLevelDeclaration_enum() {
    var parseResult = parseStringWithErrors(r'''
covariant enum E { v }
''');
    parseResult.assertErrors([error(diag.extraneousModifier, 0, 9)]);
  }

  void test_covariantTopLevelDeclaration_typedef() {
    var parseResult = parseStringWithErrors(r'''
covariant typedef F();
''');
    parseResult.assertErrors([error(diag.extraneousModifier, 0, 9)]);
  }

  void test_defaultValueInFunctionType_named_colon() {
    var parseResult = parseStringWithErrors(r'''
typedef F = void Function({int x : 0});
''');
    parseResult.assertErrors([error(diag.defaultValueInFunctionType, 33, 1)]);

    var node = parseResult.findNode.singleFormalParameterList;
    assertParsedNodeText(node, r'''
FormalParameterList
  leftParenthesis: (
  leftDelimiter: {
  parameter: DefaultFormalParameter
    parameter: SimpleFormalParameter
      type: NamedType
        name: int
      name: x
    separator: :
    defaultValue: IntegerLiteral
      literal: 0
  rightDelimiter: }
  rightParenthesis: )
''');
  }

  void test_defaultValueInFunctionType_named_equal() {
    var parseResult = parseStringWithErrors(r'''
typedef F = void Function({int x = 0});
''');
    parseResult.assertErrors([error(diag.defaultValueInFunctionType, 33, 1)]);

    var node = parseResult.findNode.singleFormalParameterList;
    assertParsedNodeText(node, r'''
FormalParameterList
  leftParenthesis: (
  leftDelimiter: {
  parameter: DefaultFormalParameter
    parameter: SimpleFormalParameter
      type: NamedType
        name: int
      name: x
    separator: =
    defaultValue: IntegerLiteral
      literal: 0
  rightDelimiter: }
  rightParenthesis: )
''');
  }

  void test_defaultValueInFunctionType_positional() {
    var parseResult = parseStringWithErrors(r'''
typedef F = void Function([int x = 0]);
''');
    parseResult.assertErrors([error(diag.defaultValueInFunctionType, 33, 1)]);

    var node = parseResult.findNode.singleFormalParameterList;
    assertParsedNodeText(node, r'''
FormalParameterList
  leftParenthesis: (
  leftDelimiter: [
  parameter: DefaultFormalParameter
    parameter: SimpleFormalParameter
      type: NamedType
        name: int
      name: x
    separator: =
    defaultValue: IntegerLiteral
      literal: 0
  rightDelimiter: ]
  rightParenthesis: )
''');
  }

  void test_directiveAfterDeclaration_classBeforeDirective() {
    // TODO(brianwilkerson): Remove codes when highlighting is fixed.
    var parseResult = parseStringWithErrors(r'''
class Foo{}
library l;
''');
    parseResult.assertErrors([error(diag.libraryDirectiveNotFirst, 12, 7)]);
  }

  void test_directiveAfterDeclaration_classBetweenDirectives() {
    // TODO(brianwilkerson): Remove codes when highlighting is fixed.
    var parseResult = parseStringWithErrors(r'''
library l;
class Foo{}
part 'a.dart';
''');
    parseResult.assertErrors([error(diag.directiveAfterDeclaration, 23, 4)]);
  }

  void test_duplicatedModifier_const() {
    var parseResult = parseStringWithErrors(r'''
class C {
  const const m = null;
}
''');
    parseResult.assertErrors([error(diag.duplicatedModifier, 18, 5)]);
  }

  void test_duplicatedModifier_external() {
    var parseResult = parseStringWithErrors(r'''
class C {
  external external f();
}
''');
    parseResult.assertErrors([error(diag.duplicatedModifier, 21, 8)]);
  }

  void test_duplicatedModifier_factory() {
    var parseResult = parseStringWithErrors(r'''
class C {
  factory factory C() {}
}
''');
    parseResult.assertErrors([error(diag.duplicatedModifier, 20, 7)]);
  }

  void test_duplicatedModifier_final() {
    var parseResult = parseStringWithErrors(r'''
class C {
  final final m = null;
}
''');
    parseResult.assertErrors([error(diag.duplicatedModifier, 18, 5)]);
  }

  void test_duplicatedModifier_static() {
    var parseResult = parseStringWithErrors(r'''
class C {
  static static var m;
}
''');
    parseResult.assertErrors([error(diag.duplicatedModifier, 19, 6)]);
  }

  void test_duplicatedModifier_var() {
    var parseResult = parseStringWithErrors(r'''
class C {
  var var m;
}
''');
    parseResult.assertErrors([error(diag.duplicatedModifier, 16, 3)]);
  }

  void test_duplicateLabelInSwitchStatement() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  switch (e) {l1: case 0: break; l1: case 1: break;}
}
''');
    parseResult.assertErrors([
      error(diag.duplicateLabelInSwitchStatement, 44, 2),
    ]);
  }

  void test_emptyEnumBody() {
    var parseResult = parseStringWithErrors(r'''
enum E {}
''');
    parseResult.assertNoErrors();
  }

  void test_enumInClass() {
    var parseResult = parseStringWithErrors(r'''
class Foo {
  enum Bar {
    Bar1, Bar2, Bar3
  }
}
''');
    parseResult.assertErrors([error(diag.enumInClass, 14, 4)]);
  }

  void test_equalityCannotBeEqualityOperand_eq_eq() {
    var parseResult = parseStringWithErrors(r'''
var v = 1 == 2 == 3;
''');
    parseResult.assertErrors([
      error(diag.equalityCannotBeEqualityOperand, 15, 2),
    ]);
  }

  void test_equalityCannotBeEqualityOperand_eq_neq() {
    var parseResult = parseStringWithErrors(r'''
var v = 1 == 2 != 3;
''');
    parseResult.assertErrors([
      error(diag.equalityCannotBeEqualityOperand, 15, 2),
    ]);
  }

  void test_equalityCannotBeEqualityOperand_neq_eq() {
    var parseResult = parseStringWithErrors(r'''
var v = 1 != 2 == 3;
''');
    parseResult.assertErrors([
      error(diag.equalityCannotBeEqualityOperand, 15, 2),
    ]);
  }

  void test_expectedBody_class() {
    var parseResult = parseStringWithErrors(r'''
class A class B {}
''');
    parseResult.assertErrors([error(diag.expectedClassBody, 6, 1)]);
  }

  void test_expectedCaseOrDefault() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  switch (e) {break;}
}
''');
    parseResult.assertErrors([error(diag.expectedToken, 25, 5)]);
  }

  void test_expectedClassMember_inClass_afterType() {
    var parseResult = parseStringWithErrors(r'''
class C{ heart 2 heart }
''');
    parseResult.assertErrors([
      error(diag.missingConstFinalVarOrType, 9, 5),
      error(diag.expectedToken, 9, 5),
      error(diag.expectedClassMember, 15, 1),
      error(diag.missingConstFinalVarOrType, 17, 5),
      error(diag.expectedToken, 17, 5),
    ]);
  }

  void test_expectedClassMember_inClass_beforeType() {
    var parseResult = parseStringWithErrors(r'''
class C { 4 score }
''');
    parseResult.assertErrors([
      error(diag.expectedClassMember, 10, 1),
      error(diag.missingConstFinalVarOrType, 12, 5),
      error(diag.expectedToken, 12, 5),
    ]);
  }

  void test_expectedExecutable_afterAnnotation_atEOF() {
    // TODO(brianwilkerson): Remove codes when highlighting is fixed.
    var parseResult = parseStringWithErrors(r'''
@A
''');
    parseResult.assertErrors([error(diag.expectedExecutable, 3, 0)]);
  }

  void test_expectedExecutable_inClass_afterVoid() {
    var parseResult = parseStringWithErrors(r'''
class C { void 2 void }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 15, 1),
      error(diag.expectedToken, 15, 1),
      error(diag.expectedToken, 17, 4),
      error(diag.missingIdentifier, 22, 1),
    ]);
  }

  void test_expectedExecutable_topLevel_afterType() {
    var parseResult = parseStringWithErrors(r'''
heart 2 heart
''');
    parseResult.assertErrors([
      error(diag.missingConstFinalVarOrType, 0, 5),
      error(diag.expectedToken, 0, 5),
      error(diag.expectedExecutable, 6, 1),
      error(diag.missingConstFinalVarOrType, 8, 5),
      error(diag.expectedToken, 8, 5),
    ]);
  }

  void test_expectedExecutable_topLevel_afterVoid() {
    var parseResult = parseStringWithErrors(r'''
void 2 void
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 0, 4),
      error(diag.missingIdentifier, 5, 1),
      error(diag.expectedExecutable, 5, 1),
      error(diag.expectedToken, 7, 4),
      error(diag.missingIdentifier, 12, 0),
    ]);
  }

  void test_expectedExecutable_topLevel_beforeType() {
    var parseResult = parseStringWithErrors(r'''
4 score
''');
    parseResult.assertErrors([
      error(diag.expectedExecutable, 0, 1),
      error(diag.missingConstFinalVarOrType, 2, 5),
      error(diag.expectedToken, 2, 5),
    ]);
  }

  void test_expectedExecutable_topLevel_eof() {
    var parseResult = parseStringWithErrors(r'''
x
''');
    parseResult.assertErrors([
      error(diag.missingConstFinalVarOrType, 0, 1),
      error(diag.expectedToken, 0, 1),
    ]);
  }

  void test_expectedInterpolationIdentifier() {
    var parseResult = parseStringWithErrors(r'''
var s = '$x$';
''');
    parseResult.assertErrors([error(diag.missingIdentifier, 12, 1)]);

    var node = parseResult.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: var
        variables
          VariableDeclaration
            name: s
            equals: =
            initializer: StringInterpolation
              elements
                InterpolationString
                  contents: '
                InterpolationExpression
                  leftBracket: $
                  expression: SimpleIdentifier
                    token: x
                InterpolationString
                  contents: <empty> <synthetic>
                InterpolationExpression
                  leftBracket: $
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                InterpolationString
                  contents: '
              stringValue: null
      semicolon: ;
''');
  }

  void test_expectedInterpolationIdentifier_emptyString() {
    // The scanner inserts an empty string token between the two $'s; we need to
    // make sure that the MISSING_IDENTIFIER error that is generated has a
    // nonzero width so that it will show up in the editor UI.
    var parseResult = parseStringWithErrors(r'''
var s = '$$foo';
''');
    parseResult.assertErrors([error(diag.missingIdentifier, 10, 1)]);
  }

  void test_expectedToken_commaMissingInArgumentList() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  g(x, y z);
}
''');
    parseResult.assertErrors([error(diag.expectedToken, 20, 1)]);
  }

  void test_expectedToken_parseStatement_afterVoid() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  void}
}
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 13, 4),
      error(diag.missingIdentifier, 17, 1),
      error(diag.expectedExecutable, 19, 1),
    ]);
  }

  void test_expectedToken_semicolonMissingAfterExport() {
    var parseResult = parseStringWithErrors("export '' class A {}");
    parseResult.assertErrors([error(diag.expectedToken, 7, 2)]);

    var unit = parseResult.unit;
    assertParsedNodeText(unit, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: ''
      semicolon: ; <synthetic>
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_expectedToken_semicolonMissingAfterExpression() {
    // TODO(brianwilkerson): Convert codes to errors when highlighting is fixed.
    var parseResult = parseStringWithErrors(r'''
void f() {
  x
}
''');
    parseResult.assertErrors([error(diag.expectedToken, 13, 1)]);
  }

  void test_expectedToken_semicolonMissingAfterImport() {
    // TODO(brianwilkerson): Remove codes when highlighting is fixed.
    var parseResult = parseStringWithErrors(r'''
import '' class A {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 7, 2)]);

    var node = parseResult.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: ''
      semicolon: ; <synthetic>
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_expectedToken_uriAndSemicolonMissingAfterExport() {
    var parseResult = parseStringWithErrors(r'''
export class A {}
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 0, 6),
      error(diag.expectedStringLiteral, 7, 5),
    ]);

    var node = parseResult.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: "" <synthetic>
      semicolon: ; <synthetic>
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_expectedToken_whileMissingInDoStatement() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  do {} (x);
}
''');
    parseResult.assertErrors([error(diag.expectedToken, 19, 1)]);
  }

  void test_expectedTypeName_as() {
    var parseResult = parseStringWithErrors(r'''
var v = x as;
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 12, 1)]);
  }

  void test_expectedTypeName_as_void() {
    var parseResult = parseStringWithErrors(r'''
var v = x as void;
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 13, 4)]);
  }

  void test_expectedTypeName_is() {
    var parseResult = parseStringWithErrors(r'''
var v = x is;
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 12, 1)]);
  }

  void test_expectedTypeName_is_void() {
    var parseResult = parseStringWithErrors(r'''
var v = x is void;
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 13, 4)]);
  }

  void test_exportAsType() {
    var parseResult = parseStringWithErrors(r'''
export<dynamic> foo;
''');
    parseResult.assertErrors([error(diag.builtInIdentifierAsType, 0, 6)]);
  }

  void test_exportAsType_inClass() {
    var parseResult = parseStringWithErrors(r'''
class C { export<dynamic> foo; }
''');
    parseResult.assertErrors([error(diag.builtInIdentifierAsType, 10, 6)]);
  }

  void test_externalAfterConst() {
    var parseResult = parseStringWithErrors(r'''
class C {
  const external C();
}
''');
    parseResult.assertErrors([error(diag.modifierOutOfOrder, 18, 8)]);
  }

  void test_externalAfterFactory() {
    var parseResult = parseStringWithErrors(r'''
class C {
  factory external C() {}
}
''');
    parseResult.assertErrors([error(diag.modifierOutOfOrder, 20, 8)]);
  }

  void test_externalAfterStatic() {
    var parseResult = parseStringWithErrors(r'''
class C {
  static external int m();
}
''');
    parseResult.assertErrors([error(diag.modifierOutOfOrder, 19, 8)]);
  }

  void test_externalClass() {
    var parseResult = parseStringWithErrors(r'''
external class C {}
''');
    parseResult.assertErrors([error(diag.externalClass, 0, 8)]);
  }

  void test_externalEnum() {
    var parseResult = parseStringWithErrors(r'''
external enum E {ONE}
''');
    parseResult.assertErrors([error(diag.externalEnum, 0, 8)]);
  }

  void test_externalField_const() {
    var parseResult = parseStringWithErrors(r'''
class C {
  external const A f;
}
''');
    parseResult.assertNoErrors();
  }

  void test_externalField_final() {
    var parseResult = parseStringWithErrors(r'''
class C {
  external final A f;
}
''');
    parseResult.assertNoErrors();
  }

  void test_externalField_static() {
    var parseResult = parseStringWithErrors(r'''
class C {
  external static A f;
}
''');
    parseResult.assertNoErrors();
  }

  void test_externalField_typed() {
    var parseResult = parseStringWithErrors(r'''
class C {
  external A f;
}
''');
    parseResult.assertNoErrors();
  }

  void test_externalField_untyped() {
    var parseResult = parseStringWithErrors(r'''
class C {
  external var f;
}
''');
    parseResult.assertNoErrors();
  }

  void test_externalTypedef() {
    var parseResult = parseStringWithErrors(r'''
external typedef F();
''');
    parseResult.assertErrors([error(diag.externalTypedef, 0, 8)]);
  }

  void test_extraCommaInParameterList() {
    var parseResult = parseStringWithErrors(r'''
void f(int a, , int b) {}
''');
    parseResult.assertErrors([error(diag.missingIdentifier, 14, 1)]);
  }

  void test_extraCommaTrailingNamedParameterGroup() {
    var parseResult = parseStringWithErrors(r'''
void f({int b},) {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 14, 1)]);
  }

  void test_extraCommaTrailingPositionalParameterGroup() {
    var parseResult = parseStringWithErrors(r'''
void f([int b],) {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 14, 1)]);
  }

  void test_extraTrailingCommaInParameterList() {
    var parseResult = parseStringWithErrors(r'''
void f(a,,) {}
''');
    parseResult.assertErrors([error(diag.missingIdentifier, 9, 1)]);
  }

  void test_factory_issue_36400() {
    var parseResult = parseStringWithErrors(r'''
class T { T factory T() { return null; } }
''');
    parseResult.assertErrors([error(diag.typeBeforeFactory, 10, 1)]);
  }

  void test_factoryTopLevelDeclaration_class() {
    var parseResult = parseStringWithErrors(r'''
factory class C {}
''');
    parseResult.assertErrors([error(diag.factoryTopLevelDeclaration, 0, 7)]);
  }

  void test_factoryTopLevelDeclaration_enum() {
    var parseResult = parseStringWithErrors(r'''
factory enum E { v }
''');
    parseResult.assertErrors([error(diag.factoryTopLevelDeclaration, 0, 7)]);
  }

  void test_factoryTopLevelDeclaration_typedef() {
    var parseResult = parseStringWithErrors(r'''
factory typedef F();
''');
    parseResult.assertErrors([error(diag.factoryTopLevelDeclaration, 0, 7)]);
  }

  void test_factoryWithInitializers() {
    var parseResult = parseStringWithErrors(r'''
class C {
  factory C() : x = 3 {}
}
''');
    parseResult.assertErrors([
      error(diag.missingFunctionBody, 24, 1),
      error(diag.expectedClassMember, 24, 1),
      error(diag.missingConstFinalVarOrType, 26, 1),
      error(diag.expectedToken, 30, 1),
      error(diag.missingIdentifier, 32, 1),
      error(diag.missingMethodParameters, 32, 1),
    ]);
  }

  void test_factoryWithoutBody() {
    var parseResult = parseStringWithErrors(r'''
class C {
  factory C();
}
''');
    parseResult.assertErrors([error(diag.missingFunctionBody, 23, 1)]);
  }

  void test_fieldInitializerOutsideConstructor() {
    var parseResult = parseStringWithErrors(r'''
class C {
  void m(this.x);
}
''');
    parseResult.assertNoErrors();
  }

  void test_finalAndCovariant() {
    var parseResult = parseStringWithErrors(r'''
class C {
  final covariant f = null;
}
''');
    parseResult.assertErrors([
      error(diag.modifierOutOfOrder, 18, 9),
      error(diag.finalAndCovariant, 18, 9),
    ]);
  }

  void test_finalAndVar() {
    var parseResult = parseStringWithErrors(r'''
class C {
  final var x = null;
}
''');
    parseResult.assertErrors([error(diag.finalAndVar, 18, 3)]);
  }

  void test_finalClassMember_modifierOnly() {
    var parseResult = parseStringWithErrors(r'''
class C {
  final
}
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 12, 5),
      error(diag.missingIdentifier, 18, 1),
    ]);
  }

  void test_finalConstructor() {
    var parseResult = parseStringWithErrors(r'''
class C {
  final C() {}
}
''');
    parseResult.assertErrors([error(diag.extraneousModifier, 12, 5)]);
  }

  void test_finalEnum() {
    var parseResult = parseStringWithErrors(r'''
final enum E {ONE}
''');
    parseResult.assertErrors([error(diag.finalEnum, 0, 5)]);
  }

  void test_finalMethod() {
    var parseResult = parseStringWithErrors(r'''
class C {
  final int m() {}
}
''');
    parseResult.assertErrors([error(diag.extraneousModifier, 12, 5)]);
  }

  void test_finalTypedef() {
    var parseResult = parseStringWithErrors(r'''
final typedef F();
''');
    parseResult.assertErrors([
      // Fasta interprets the `final` as a malformed top level final
      // and `typedef` as the start of an typedef declaration.
      error(diag.expectedToken, 0, 5),
      error(diag.missingIdentifier, 6, 7),
    ]);
  }

  void test_functionTypedField_invalidType_abstract() {
    var parseResult = parseStringWithErrors(r'''
Function(abstract) x = null;
''');
    parseResult.assertErrors([error(diag.builtInIdentifierAsType, 9, 8)]);
  }

  void test_functionTypedField_invalidType_class() {
    var parseResult = parseStringWithErrors(r'''
Function(class) x = null;
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 9, 5),
      error(diag.expectedIdentifierButGotKeyword, 9, 5),
    ]);
  }

  void test_functionTypedParameter_const() {
    var parseResult = parseStringWithErrors(r'''
void f(const x()) {}
''');
    parseResult.assertErrors([
      error(diag.extraneousModifier, 7, 5),
      error(diag.functionTypedParameterVar, 7, 5),
    ]);
  }

  void test_functionTypedParameter_final() {
    var parseResult = parseStringWithErrors(r'''
void f(final x()) {}
''');
    parseResult.assertErrors([
      error(diag.functionTypedParameterVar, 7, 5),
      error(diag.extraneousModifier, 7, 5),
    ]);
  }

  void test_functionTypedParameter_incomplete1() {
    var parseResult = parseStringWithErrors(r'''
void f(int Function(
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 21, 1),
      error(diag.missingFunctionBody, 21, 0),
    ]);
  }

  void test_functionTypedParameter_var() {
    var parseResult = parseStringWithErrors(r'''
void f(var x()) {}
''');
    parseResult.assertErrors([
      error(diag.functionTypedParameterVar, 7, 3),
      error(diag.extraneousModifier, 7, 3),
    ]);
  }

  void test_genericFunctionType_asIdentifier() {
    var parseResult = parseStringWithErrors(r'''
final int Function = 0;
''');
    parseResult.assertNoErrors();
  }

  void test_genericFunctionType_asIdentifier2() {
    var parseResult = parseStringWithErrors(r'''
int Function() {}
''');
    parseResult.assertNoErrors();
  }

  void test_genericFunctionType_asIdentifier3() {
    var parseResult = parseStringWithErrors(r'''
int Function() => 0;
''');
    parseResult.assertNoErrors();
  }

  void test_genericFunctionType_extraLessThan() {
    var parseResult = parseStringWithErrors(r'''
class Wrong<T> {
  T Function(<List<int> foo) bar;
}
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 30, 1),
      error(diag.expectedToken, 30, 1),
    ]);
  }

  void test_getterInFunction_block_noReturnType() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  get x { return _x; }
}
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 13, 3),
      error(diag.expectedToken, 17, 1),
    ]);

    var node = parseResult.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      returnType: NamedType
        name: void
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              ExpressionStatement
                expression: SimpleIdentifier
                  token: get
                semicolon: ; <synthetic>
              ExpressionStatement
                expression: SimpleIdentifier
                  token: x
                semicolon: ; <synthetic>
              Block
                leftBracket: {
                statements
                  ReturnStatement
                    returnKeyword: return
                    expression: SimpleIdentifier
                      token: _x
                    semicolon: ;
                rightBracket: }
            rightBracket: }
''');
  }

  void test_getterInFunction_block_returnType() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  int get x { return _x; }
}
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 17, 3),
      error(diag.expectedToken, 21, 1),
    ]);
  }

  void test_getterInFunction_expression_noReturnType() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  get x => _x;
}
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 13, 3),
      error(diag.missingFunctionParameters, 19, 2),
    ]);
  }

  void test_getterInFunction_expression_returnType() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  int get x => _x;
}
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 17, 3),
      error(diag.missingFunctionParameters, 23, 2),
    ]);
  }

  void test_getterNativeWithBody() {
    var parseResult = parseStringWithErrors(r'''
class C {
  String get m native "str" => 0;
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleMethodDeclaration;
    assertParsedNodeText(node, r'''
MethodDeclaration
  returnType: NamedType
    name: String
  propertyKeyword: get
  name: m
  body: ExpressionFunctionBody
    functionDefinition: =>
    expression: IntegerLiteral
      literal: 0
    semicolon: ;
''');
  }

  void test_getterWithParameters() {
    var parseResult = parseStringWithErrors(r'''
class C {
  int get x() {}
}
''');
    parseResult.assertErrors([error(diag.getterWithParameters, 21, 1)]);
  }

  void test_illegalAssignmentToNonAssignable_assign_int() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  0 = 1;
}
''');
    parseResult.assertErrors([
      error(diag.missingAssignableSelector, 13, 1),
      error(diag.illegalAssignmentToNonAssignable, 13, 1),
    ]);
  }

  void test_illegalAssignmentToNonAssignable_assign_this() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  this = 1;
}
''');
    parseResult.assertErrors([
      error(diag.missingAssignableSelector, 13, 4),
      error(diag.illegalAssignmentToNonAssignable, 13, 4),
    ]);
  }

  void test_illegalAssignmentToNonAssignable_postfix_minusMinus_literal() {
    var parseResult = parseStringWithErrors(r'''
var v = 0--;
''');
    parseResult.assertErrors([
      error(diag.illegalAssignmentToNonAssignable, 9, 2),
    ]);
  }

  void test_illegalAssignmentToNonAssignable_postfix_plusPlus_literal() {
    var parseResult = parseStringWithErrors(r'''
var v = 0++;
''');
    parseResult.assertErrors([
      error(diag.illegalAssignmentToNonAssignable, 9, 2),
    ]);
  }

  void test_illegalAssignmentToNonAssignable_postfix_plusPlus_parenthesized() {
    var parseResult = parseStringWithErrors(r'''
var v = (x)++;
''');
    parseResult.assertErrors([
      error(diag.illegalAssignmentToNonAssignable, 11, 2),
    ]);
  }

  void test_illegalAssignmentToNonAssignable_primarySelectorPostfix() {
    var parseResult = parseStringWithErrors(r'''
var v = x(y)(z)++;
''');
    parseResult.assertErrors([
      error(diag.illegalAssignmentToNonAssignable, 15, 2),
    ]);
  }

  void test_illegalAssignmentToNonAssignable_superAssigned() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  super = x;
}
''');
    parseResult.assertErrors([
      error(diag.missingAssignableSelector, 13, 5),
      error(diag.illegalAssignmentToNonAssignable, 13, 5),
    ]);
  }

  void test_implementsBeforeExtends() {
    var parseResult = parseStringWithErrors(r'''
class A implements B extends C {}
''');
    parseResult.assertErrors([error(diag.implementsBeforeExtends, 21, 7)]);
  }

  void test_implementsBeforeWith() {
    var parseResult = parseStringWithErrors(r'''
class A extends B implements C with D {}
''');
    parseResult.assertErrors([error(diag.implementsBeforeWith, 31, 4)]);
  }

  void test_initializedVariableInForEach() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  for (int a = 0 in foo) {}
}
''');
    parseResult.assertErrors([error(diag.initializedVariableInForEach, 24, 1)]);
  }

  void test_initializedVariableInForEach_annotation() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  for (@Foo var a = 0 in foo) {}
}
''');
    parseResult.assertErrors([error(diag.initializedVariableInForEach, 29, 1)]);
  }

  void test_initializedVariableInForEach_localFunction() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  for (f()) {}
}
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 20, 1),
      error(diag.missingIdentifier, 21, 1),
    ]);
  }

  void test_initializedVariableInForEach_localFunction2() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  for (T f()) {}
}
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 20, 1),
      error(diag.expectedToken, 22, 1),
    ]);
  }

  void test_initializedVariableInForEach_var() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  for (var a = 0 in foo) {}
}
''');
    parseResult.assertErrors([error(diag.initializedVariableInForEach, 24, 1)]);
  }

  void test_invalidAwaitInFor() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  await for (; ;) {}
}
''');
    parseResult.assertErrors([error(diag.invalidAwaitInFor, 13, 5)]);
  }

  void test_invalidCodePoint() {
    var parseResult = parseStringWithErrors(r'''
var s = 'begin \u{110000}';
''');
    parseResult.assertErrors([error(diag.invalidCodePoint, 15, 9)]);
  }

  @failingTest
  void test_invalidCommentReference__new_nonIdentifier() {
    var parseResult = parseStringWithErrors(r'''
/// [new 42]
void f() {}
''');
    parseResult.assertErrors([error(diag.invalidCommentReference, 9, 3)]);
  }

  @failingTest
  void test_invalidCommentReference__new_tooMuch() {
    var parseResult = parseStringWithErrors(r'''
/// [new a.b.c.d]
void f() {}
''');
    parseResult.assertErrors([error(diag.invalidCommentReference, 9, 7)]);
  }

  @failingTest
  void test_invalidCommentReference__nonNew_nonIdentifier() {
    var parseResult = parseStringWithErrors(r'''
/// [42]
void f() {}
''');
    parseResult.assertErrors([error(diag.invalidCommentReference, 5, 2)]);
  }

  @failingTest
  void test_invalidCommentReference__nonNew_tooMuch() {
    var parseResult = parseStringWithErrors(r'''
/// [a.b.c.d]
void f() {}
''');
    parseResult.assertErrors([error(diag.invalidCommentReference, 5, 7)]);
  }

  void test_invalidConstructorName_star() {
    var parseResult = parseStringWithErrors(r'''
class C {
  C.*();
}
''');
    parseResult.assertErrors([error(diag.missingIdentifier, 14, 1)]);
  }

  void test_invalidConstructorName_with() {
    var parseResult = parseStringWithErrors(r'''
class C {
  C.with();
}
''');
    parseResult.assertErrors([
      error(diag.expectedIdentifierButGotKeyword, 14, 4),
    ]);
  }

  void test_invalidConstructorSuperAssignment() {
    var parseResult = parseStringWithErrors(r'''
class C {
  C() : super = 42;
}
''');
    parseResult.assertErrors([
      error(diag.missingAssignableSelector, 18, 5),
      error(diag.invalidInitializer, 18, 10),
    ]);
  }

  void test_invalidConstructorSuperFieldAssignment() {
    var parseResult = parseStringWithErrors(r'''
class C {
  C() : super.a = 42;
}
''');
    parseResult.assertErrors([
      error(diag.fieldInitializedOutsideDeclaringClass, 24, 1),
    ]);
  }

  void test_invalidHexEscape_invalidDigit() {
    var parseResult = parseStringWithErrors(r'''
var s = 'not \x0 a';
''');
    parseResult.assertErrors([error(diag.invalidHexEscape, 13, 3)]);
  }

  void test_invalidHexEscape_tooFewDigits() {
    var parseResult = parseStringWithErrors(r'''
var s = '\x0';
''');
    parseResult.assertErrors([error(diag.invalidHexEscape, 9, 3)]);
  }

  void test_invalidInlineFunctionType() {
    var parseResult = parseStringWithErrors(r'''
typedef F = int Function(int a());
''');
    parseResult.assertErrors([error(diag.invalidInlineFunctionType, 30, 1)]);
  }

  void test_invalidInterpolation_missingClosingBrace_issue35900() {
    var parseResult = parseStringWithErrors(r'''
main () { print('${x' '); }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 20, 3),
      error(diag.expectedToken, 23, 1),
      error(diag.expectedStringLiteral, 23, 1),
      error(diag.unterminatedStringLiteral, 27, 1),
      error(diag.expectedExecutable, 28, 0),
    ]);
  }

  void test_invalidInterpolationIdentifier_startWithDigit() {
    var parseResult = parseStringWithErrors(r'''
var s = '$1';
''');
    parseResult.assertErrors([error(diag.missingIdentifier, 10, 1)]);
  }

  void test_invalidLiteralInConfiguration() {
    var parseResult = parseStringWithErrors(r'''
import 'a.dart' if (a == 'x $y z') 'a.dart';
''');
    parseResult.assertErrors([
      error(diag.invalidLiteralInConfiguration, 28, 2),
    ]);
  }

  void test_invalidOperator() {
    var parseResult = parseStringWithErrors(r'''
class C { void operator ===(x) { } }
''');
    parseResult.assertErrors([error(diag.unsupportedOperator, 24, 1)]);
  }

  void test_invalidOperator_unary() {
    var parseResult = parseStringWithErrors(r'''
class C { int operator unary- => 0; }
''');
    parseResult.assertErrors([
      error(diag.unexpectedToken, 23, 5),
      error(diag.missingMethodParameters, 28, 1),
    ]);
  }

  void test_invalidOperatorAfterSuper_assignableExpression() {
    // TODO(brianwilkerson): Convert codes to errors when highlighting is fixed.
    var parseResult = parseStringWithErrors(r'''
void f() {
  super?.v = 0;
}
''');
    parseResult.assertErrors([
      error(diag.invalidOperatorQuestionmarkPeriodForSuper, 18, 2),
    ]);
  }

  void test_invalidOperatorAfterSuper_constructorInitializer2() {
    var parseResult = parseStringWithErrors(r'''
class C { C() : super?.namedConstructor(); }
''');
    parseResult.assertErrors([
      error(diag.invalidOperatorQuestionmarkPeriodForSuper, 21, 2),
    ]);
  }

  void test_invalidOperatorAfterSuper_primaryExpression() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  super?.v;
}
''');
    parseResult.assertErrors([
      error(diag.invalidOperatorQuestionmarkPeriodForSuper, 18, 2),
    ]);
  }

  void test_invalidOperatorForSuper() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  ++super;
}
''');
    parseResult.assertErrors([error(diag.missingAssignableSelector, 15, 5)]);
  }

  void test_invalidPropertyAccess_this() {
    var parseResult = parseStringWithErrors(r'''
var v = x.this;
''');
    parseResult.assertErrors([error(diag.missingIdentifier, 10, 4)]);
  }

  void test_invalidStarAfterAsync() {
    var parseResult = parseStringWithErrors(r'''
foo() async* => 0;
''');
    parseResult.assertErrors([error(diag.returnInGenerator, 13, 2)]);
  }

  void test_invalidSync() {
    var parseResult = parseStringWithErrors(r'''
foo() sync* => 0;
''');
    parseResult.assertErrors([error(diag.returnInGenerator, 12, 2)]);
  }

  void test_invalidTopLevelSetter() {
    var parseResult = parseStringWithErrors(r'''
var set foo; main(){}
''');
    parseResult.assertErrors([
      error(diag.varReturnType, 0, 3),
      error(diag.missingFunctionParameters, 8, 3),
      error(diag.missingFunctionBody, 11, 1),
    ]);
  }

  void test_invalidTopLevelVar() {
    var parseResult = parseStringWithErrors(r'''
var Function(var arg);
''');
    parseResult.assertErrors([
      error(diag.varReturnType, 0, 3),
      error(diag.extraneousModifier, 13, 3),
      error(diag.missingFunctionBody, 21, 1),
    ]);
  }

  void test_invalidTypedef() {
    var parseResult = parseStringWithErrors(r'''
typedef var Function(var arg);
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 0, 7),
      error(diag.missingIdentifier, 8, 3),
      error(diag.missingTypedefParameters, 8, 3),
      error(diag.varReturnType, 8, 3),
      error(diag.extraneousModifier, 21, 3),
      error(diag.missingFunctionBody, 29, 1),
    ]);
  }

  void test_invalidTypedef2() {
    // https://github.com/dart-lang/sdk/issues/31171
    var parseResult = parseStringWithErrors(r'''
typedef T = typedef F = Map<String, dynamic> Function();
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 10, 1),
      error(diag.expectedTypeName, 12, 7),
    ]);
  }

  void test_invalidUnicodeEscape_incomplete_noDigits() {
    var parseResult = parseStringWithErrors(r'''
var s = '\u{';
''');
    parseResult.assertErrors([error(diag.invalidUnicodeEscapeUBracket, 9, 3)]);
  }

  void test_invalidUnicodeEscape_incomplete_noDigits_noBracket() {
    var parseResult = parseStringWithErrors(r'''
var s = '\u';
''');
    parseResult.assertErrors([error(diag.invalidUnicodeEscapeUStarted, 9, 2)]);
  }

  void test_invalidUnicodeEscape_incomplete_someDigits() {
    var parseResult = parseStringWithErrors(r'''
var s = '\u{0A';
''');
    parseResult.assertErrors([error(diag.invalidUnicodeEscapeUBracket, 9, 5)]);
  }

  void test_invalidUnicodeEscape_invalidDigit() {
    var parseResult = parseStringWithErrors(r'''
var s = '\u0 and some more';
''');
    parseResult.assertErrors([
      error(diag.invalidUnicodeEscapeUNoBracket, 9, 3),
    ]);
  }

  void test_invalidUnicodeEscape_too_high_number_variable() {
    var parseResult = parseStringWithErrors(r'''
var s = '\u{110000}';
''');
    parseResult.assertErrors([error(diag.invalidCodePoint, 9, 9)]);
  }

  void test_invalidUnicodeEscape_tooFewDigits_fixed() {
    var parseResult = parseStringWithErrors(r'''
var s = '\u04';
''');
    parseResult.assertErrors([
      error(diag.invalidUnicodeEscapeUNoBracket, 9, 4),
    ]);
  }

  void test_invalidUnicodeEscape_tooFewDigits_variable() {
    var parseResult = parseStringWithErrors(r'''
var s = '\u{}';
''');
    parseResult.assertErrors([error(diag.invalidUnicodeEscapeUBracket, 9, 4)]);
  }

  void test_invalidUnicodeEscape_tooManyDigits_variable() {
    var parseResult = parseStringWithErrors(r'''
var s = '\u{0000000001}';
''');
    parseResult.assertErrors([error(diag.invalidUnicodeEscapeUBracket, 9, 9)]);
  }

  void test_libraryDirectiveNotFirst() {
    var parseResult = parseStringWithErrors(r'''
import 'x.dart'; library l;
''');
    parseResult.assertErrors([error(diag.libraryDirectiveNotFirst, 17, 7)]);
  }

  void test_libraryDirectiveNotFirst_afterPart() {
    var parseResult = parseStringWithErrors(r'''
part 'a.dart';
library l;
''');
    parseResult.assertErrors([error(diag.libraryDirectiveNotFirst, 15, 7)]);
  }

  void test_localFunction_annotation() {
    var result = parseStringWithErrors(r'''
class C { m() { @Foo f() {} } }
''');
    result.assertNoErrors();

    var node = result.findNode.singleFunctionDeclaration;
    assertParsedNodeText(node, r'''
FunctionDeclaration
  metadata
    Annotation
      atSign: @
      name: SimpleIdentifier
        token: Foo
  name: f
  functionExpression: FunctionExpression
    parameters: FormalParameterList
      leftParenthesis: (
      rightParenthesis: )
    body: BlockFunctionBody
      block: Block
        leftBracket: {
        rightBracket: }
''');
  }

  void test_localFunctionDeclarationModifier_abstract() {
    var parseResult = parseStringWithErrors(r'''
class C { m() { abstract f() {} } }
''');
    parseResult.assertErrors([error(diag.extraneousModifier, 16, 8)]);
  }

  void test_localFunctionDeclarationModifier_external() {
    var parseResult = parseStringWithErrors(r'''
class C { m() { external f() {} } }
''');
    parseResult.assertErrors([error(diag.extraneousModifier, 16, 8)]);
  }

  void test_localFunctionDeclarationModifier_factory() {
    var parseResult = parseStringWithErrors(r'''
class C { m() { factory f() {} } }
''');
    parseResult.assertErrors([error(diag.expectedToken, 16, 7)]);
  }

  void test_localFunctionDeclarationModifier_static() {
    var parseResult = parseStringWithErrors(r'''
class C { m() { static f() {} } }
''');
    parseResult.assertErrors([error(diag.extraneousModifier, 16, 6)]);
  }

  void test_method_invalidTypeParameterExtends() {
    // Regression test for https://github.com/dart-lang/sdk/issues/25739.

    // TODO(jmesserly): ideally we'd be better at parser recovery here.
    var result = parseStringWithErrors(r'''
class C {
  f<E>(E extends num p);
}
''');
    result.assertErrors([error(diag.expectedToken, 19, 7)]);

    var member = result.findNode.singleMethodDeclaration;
    assertParsedNodeText(member, r'''
MethodDeclaration
  name: f
  typeParameters: TypeParameterList
    leftBracket: <
    typeParameters
      TypeParameter
        name: E
    rightBracket: >
  parameters: FormalParameterList
    leftParenthesis: (
    parameter: SimpleFormalParameter
      name: E
    rightParenthesis: )
  body: EmptyFunctionBody
    semicolon: ;
''');
  }

  void test_method_invalidTypeParameters() {
    var result = parseStringWithErrors(r'''
class C {
  void m<E, hello!>() {}
}
''');
    result.assertErrors([error(diag.expectedToken, 22, 5)]);

    var method = result.findNode.singleMethodDeclaration;
    assertParsedNodeText(method, r'''
MethodDeclaration
  returnType: NamedType
    name: void
  name: m
  typeParameters: TypeParameterList
    leftBracket: <
    typeParameters
      TypeParameter
        name: E
      TypeParameter
        name: hello
    rightBracket: >
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  body: BlockFunctionBody
    block: Block
      leftBracket: {
      rightBracket: }
''');
  }

  void test_missingAssignableSelector_identifiersAssigned() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  x.y = y;
}
''');
    parseResult.assertNoErrors();
  }

  void test_missingAssignableSelector_prefix_minusMinus_literal() {
    var parseResult = parseStringWithErrors(r'''
var v = --0;
''');
    parseResult.assertErrors([error(diag.missingAssignableSelector, 10, 1)]);
  }

  void test_missingAssignableSelector_prefix_plusPlus_literal() {
    var parseResult = parseStringWithErrors(r'''
var v = ++0;
''');
    parseResult.assertErrors([error(diag.missingAssignableSelector, 10, 1)]);
  }

  void test_missingAssignableSelector_selector() {
    var parseResult = parseStringWithErrors(r'''
var v = x(y)(z).a++;
''');
    parseResult.assertNoErrors();
  }

  void test_missingAssignableSelector_superAsExpressionFunctionBody() {
    var result = parseStringWithErrors(r'''
main() => super;
''');
    result.assertErrors([error(diag.missingAssignableSelector, 10, 5)]);

    var node = result.findNode.singleFunctionDeclaration;
    assertParsedNodeText(node, r'''
FunctionDeclaration
  name: main
  functionExpression: FunctionExpression
    parameters: FormalParameterList
      leftParenthesis: (
      rightParenthesis: )
    body: ExpressionFunctionBody
      functionDefinition: =>
      expression: SuperExpression
        superKeyword: super
      semicolon: ;
''');
  }

  void test_missingAssignableSelector_superPrimaryExpression() {
    var result = parseStringWithErrors(r'''
main() {super;}
''');
    result.assertErrors([error(diag.missingAssignableSelector, 8, 5)]);

    var node = result.findNode.singleFunctionDeclaration;
    assertParsedNodeText(node, r'''
FunctionDeclaration
  name: main
  functionExpression: FunctionExpression
    parameters: FormalParameterList
      leftParenthesis: (
      rightParenthesis: )
    body: BlockFunctionBody
      block: Block
        leftBracket: {
        statements
          ExpressionStatement
            expression: SuperExpression
              superKeyword: super
            semicolon: ;
        rightBracket: }
''');
  }

  void test_missingAssignableSelector_superPropertyAccessAssigned() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  super.x = x;
}
''');
    parseResult.assertNoErrors();
  }

  void test_missingCatchOrFinally() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  try {}
}
''');
    parseResult.assertErrors([error(diag.missingCatchOrFinally, 13, 3)]);
  }

  void test_missingClosingParenthesis() {
    var parseResult = parseStringWithErrors(r'''
void f(int a, int b ;
''');
    parseResult.assertErrors([
      error(diag.missingFunctionBody, 20, 1),
      error(diag.expectedToken, 22, 1),
    ]);
  }

  void test_missingConstFinalVarOrType_static() {
    var parseResult = parseStringWithErrors(r'''
class A { static f; }
''');
    parseResult.assertErrors([error(diag.missingConstFinalVarOrType, 17, 1)]);
  }

  void test_missingConstFinalVarOrType_topLevel() {
    var parseResult = parseStringWithErrors(r'''
a;
''');
    parseResult.assertErrors([error(diag.missingConstFinalVarOrType, 0, 1)]);
  }

  void test_missingEnumComma() {
    var parseResult = parseStringWithErrors(r'''
enum E {one two}
''');
    parseResult.assertErrors([error(diag.expectedToken, 12, 3)]);
  }

  void test_missingExpressionInThrow() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  throw;
}
''');
    parseResult.assertErrors([error(diag.missingExpressionInThrow, 18, 1)]);
  }

  void test_missingFunctionBody_emptyNotAllowed() {
    var parseResult = parseStringWithErrors(r'''
void f();
''');
    parseResult.assertErrors([error(diag.missingFunctionBody, 8, 1)]);
  }

  void test_missingFunctionBody_invalid() {
    var parseResult = parseStringWithErrors(r'''
void f() return 0;
''');
    parseResult.assertErrors([error(diag.missingFunctionBody, 9, 6)]);
  }

  void test_missingFunctionParameters_local_nonVoid_block() {
    // The parser does not recognize this as a function declaration, so it tries
    // to parse it as an expression statement. It isn't clear what the best
    // error message is in this case.
    var parseResult = parseStringWithErrors(r'''
void f() {
  int f { return x;}
}
''');
    parseResult.assertErrors([error(diag.expectedToken, 17, 1)]);
  }

  void test_missingFunctionParameters_local_nonVoid_expression() {
    // The parser does not recognize this as a function declaration, so it tries
    // to parse it as an expression statement. It isn't clear what the best
    // error message is in this case.
    var parseResult = parseStringWithErrors(r'''
void f() {
  int f => x;
}
''');
    parseResult.assertErrors([error(diag.missingFunctionParameters, 19, 2)]);
  }

  void test_missingFunctionParameters_local_void_block() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  void f { return x;}
}
''');
    parseResult.assertErrors([error(diag.expectedToken, 18, 1)]);
  }

  void test_missingFunctionParameters_local_void_expression() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  void f => x;
}
''');
    parseResult.assertErrors([error(diag.missingFunctionParameters, 20, 2)]);
  }

  void test_missingFunctionParameters_topLevel_nonVoid_block() {
    var parseResult = parseStringWithErrors(r'''
int f { return x;}
''');
    parseResult.assertErrors([error(diag.missingFunctionParameters, 4, 1)]);
  }

  void test_missingFunctionParameters_topLevel_nonVoid_expression() {
    var parseResult = parseStringWithErrors(r'''
int f => x;
''');
    parseResult.assertErrors([error(diag.missingFunctionParameters, 4, 1)]);
  }

  void test_missingFunctionParameters_topLevel_void_block() {
    var result = parseStringWithErrors(r'''
void f { return x;}
''');
    result.assertErrors([error(diag.missingFunctionParameters, 5, 1)]);

    var node = result.findNode.singleFunctionDeclaration;
    assertParsedNodeText(node, r'''
FunctionDeclaration
  returnType: NamedType
    name: void
  name: f
  functionExpression: FunctionExpression
    parameters: FormalParameterList
      leftParenthesis: ( <synthetic>
      rightParenthesis: ) <synthetic>
    body: BlockFunctionBody
      block: Block
        leftBracket: {
        statements
          ReturnStatement
            returnKeyword: return
            expression: SimpleIdentifier
              token: x
            semicolon: ;
        rightBracket: }
''');
  }

  void test_missingFunctionParameters_topLevel_void_expression() {
    var result = parseStringWithErrors(r'''
void f => x;
''');
    result.assertErrors([error(diag.missingFunctionParameters, 5, 1)]);

    var node = result.findNode.singleFunctionDeclaration;
    assertParsedNodeText(node, r'''
FunctionDeclaration
  returnType: NamedType
    name: void
  name: f
  functionExpression: FunctionExpression
    parameters: FormalParameterList
      leftParenthesis: ( <synthetic>
      rightParenthesis: ) <synthetic>
    body: ExpressionFunctionBody
      functionDefinition: =>
      expression: SimpleIdentifier
        token: x
      semicolon: ;
''');
  }

  void test_missingIdentifier_afterOperator() {
    var parseResult = parseStringWithErrors(r'''
var a = 1 *;
''');
    parseResult.assertErrors([error(diag.missingIdentifier, 11, 1)]);
  }

  void test_missingIdentifier_beforeClosingCurly() {
    var parseResult = parseStringWithErrors(r'''
class C {
  int
}
''');
    parseResult.assertErrors([
      error(
        diag.missingConstFinalVarOrType,
        12,
        3,
      ), // offset adjusted for indentation/newlines
      error(diag.expectedToken, 12, 3),
    ]);
  }

  void test_missingIdentifier_inEnum() {
    var parseResult = parseStringWithErrors(r'''
enum E {, TWO}
''');
    parseResult.assertErrors([error(diag.missingIdentifier, 8, 1)]);
  }

  void test_missingIdentifier_inParameterGroupNamed() {
    var parseResult = parseStringWithErrors(r'''
void f(a, {}) {}
''');
    parseResult.assertErrors([error(diag.missingIdentifier, 11, 1)]);
  }

  void test_missingIdentifier_inParameterGroupOptional() {
    var parseResult = parseStringWithErrors(r'''
void f(a, []) {}
''');
    parseResult.assertErrors([error(diag.missingIdentifier, 11, 1)]);
  }

  void test_missingIdentifier_inSymbol_afterPeriod() {
    var parseResult = parseStringWithErrors(r'''
var s = #a.;
''');
    parseResult.assertErrors([error(diag.missingIdentifier, 11, 1)]);
  }

  void test_missingIdentifier_inSymbol_first() {
    var parseResult = parseStringWithErrors(r'''
var s = #;
''');
    parseResult.assertErrors([error(diag.missingIdentifier, 9, 1)]);
  }

  void test_missingIdentifierForParameterGroup() {
    var parseResult = parseStringWithErrors(r'''
void f(,) {}
''');
    parseResult.assertErrors([error(diag.missingIdentifier, 7, 1)]);
  }

  void test_missingKeywordOperator() {
    var parseResult = parseStringWithErrors(r'''
class C {
  +(x) {}
}
''');
    parseResult.assertErrors([error(diag.missingKeywordOperator, 12, 1)]);
  }

  void test_missingKeywordOperator_parseClassMember() {
    var parseResult = parseStringWithErrors(r'''
class C {
  +() {}
}
''');
    parseResult.assertErrors([error(diag.missingKeywordOperator, 12, 1)]);
  }

  void test_missingKeywordOperator_parseClassMember_afterTypeName() {
    var parseResult = parseStringWithErrors(r'''
class C {
  int +() {}
}
''');
    parseResult.assertErrors([error(diag.missingKeywordOperator, 16, 1)]);
  }

  void test_missingKeywordOperator_parseClassMember_afterVoid() {
    var parseResult = parseStringWithErrors(r'''
class C {
  void +() {}
}
''');
    parseResult.assertErrors([error(diag.missingKeywordOperator, 17, 1)]);
  }

  void test_missingMethodParameters_void_block() {
    var result = parseStringWithErrors(r'''
class C {
  void m {}
}
''');
    result.assertErrors([error(diag.missingMethodParameters, 17, 1)]);

    var member = result.findNode.singleMethodDeclaration;
    assertParsedNodeText(member, r'''
MethodDeclaration
  returnType: NamedType
    name: void
  name: m
  parameters: FormalParameterList
    leftParenthesis: ( <synthetic>
    rightParenthesis: ) <synthetic>
  body: BlockFunctionBody
    block: Block
      leftBracket: {
      rightBracket: }
''');
  }

  void test_missingMethodParameters_void_expression() {
    var parseResult = parseStringWithErrors(r'''
class C {
  void m => null;
}
''');
    parseResult.assertErrors([error(diag.missingMethodParameters, 17, 1)]);
  }

  void test_missingNameForNamedParameter_colon() {
    var result = parseStringWithErrors(r'''
typedef F = void Function({int : 0});
''');
    result.assertErrors([
      error(diag.missingIdentifier, 31, 1),
      error(diag.defaultValueInFunctionType, 31, 1),
    ]);

    var parameter = result.findNode.singleFormalParameterList;
    assertParsedNodeText(parameter, r'''
FormalParameterList
  leftParenthesis: (
  leftDelimiter: {
  parameter: DefaultFormalParameter
    parameter: SimpleFormalParameter
      type: NamedType
        name: int
      name: <empty> <synthetic>
    separator: :
    defaultValue: IntegerLiteral
      literal: 0
  rightDelimiter: }
  rightParenthesis: )
''');
  }

  void test_missingNameForNamedParameter_equals() {
    var result = parseStringWithErrors(r'''
typedef F = void Function({int = 0});
''');
    result.assertErrors([
      error(diag.missingIdentifier, 31, 1),
      error(diag.defaultValueInFunctionType, 31, 1),
    ]);

    var parameter = result.findNode.singleFormalParameterList;
    assertParsedNodeText(parameter, r'''
FormalParameterList
  leftParenthesis: (
  leftDelimiter: {
  parameter: DefaultFormalParameter
    parameter: SimpleFormalParameter
      type: NamedType
        name: int
      name: <empty> <synthetic>
    separator: =
    defaultValue: IntegerLiteral
      literal: 0
  rightDelimiter: }
  rightParenthesis: )
''');
  }

  void test_missingNameForNamedParameter_noDefault() {
    var result = parseStringWithErrors(r'''
typedef F = void Function({int});
''');
    result.assertErrors([error(diag.missingIdentifier, 30, 1)]);

    var parameter = result.findNode.singleFormalParameterList;
    assertParsedNodeText(parameter, r'''
FormalParameterList
  leftParenthesis: (
  leftDelimiter: {
  parameter: DefaultFormalParameter
    parameter: SimpleFormalParameter
      type: NamedType
        name: int
      name: <empty> <synthetic>
  rightDelimiter: }
  rightParenthesis: )
''');
  }

  void test_missingNameInPartOfDirective() {
    var parseResult = parseStringWithErrors(r'''
part of;
''');
    parseResult.assertErrors([error(diag.expectedStringLiteral, 7, 1)]);
  }

  void test_missingPrefixInDeferredImport() {
    var parseResult = parseStringWithErrors(r'''
import 'foo.dart' deferred;
''');
    parseResult.assertErrors([
      error(diag.missingPrefixInDeferredImport, 18, 8),
    ]);
  }

  void test_missingStartAfterSync() {
    var parseResult = parseStringWithErrors(r'''
main() sync {}
''');
    parseResult.assertErrors([error(diag.missingStarAfterSync, 7, 4)]);
  }

  void test_missingStatement() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  is
}
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 13, 2),
      error(diag.expectedToken, 13, 2),
      error(diag.expectedTypeName, 16, 1),
    ]);
  }

  void test_missingStatement_afterVoid() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  void;
}
''');
    parseResult.assertErrors([error(diag.missingIdentifier, 17, 1)]);
  }

  void test_missingTerminatorForParameterGroup_named() {
    var parseResult = parseStringWithErrors(r'''
void f(a, {b: 0) {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 15, 1)]);
  }

  void test_missingTerminatorForParameterGroup_optional() {
    var parseResult = parseStringWithErrors(r'''
void f(a, [b = 0) {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 16, 1)]);
  }

  void test_missingTypedefParameters_nonVoid() {
    var parseResult = parseStringWithErrors(r'''
typedef int F;
''');
    parseResult.assertErrors([error(diag.missingTypedefParameters, 13, 1)]);
  }

  void test_missingTypedefParameters_typeParameters() {
    var parseResult = parseStringWithErrors(r'''
typedef F<E>;
''');
    parseResult.assertErrors([error(diag.missingTypedefParameters, 12, 1)]);
  }

  void test_missingTypedefParameters_void() {
    var parseResult = parseStringWithErrors(r'''
typedef void F;
''');
    parseResult.assertErrors([error(diag.missingTypedefParameters, 14, 1)]);
  }

  void test_missingVariableInForEach() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  for (a < b in foo) {}
}
''');
    parseResult.assertErrors([error(diag.unexpectedToken, 20, 1)]);
  }

  void test_mixedParameterGroups_namedPositional() {
    var parseResult = parseStringWithErrors(r'''
void f(a, {b}, [c]) {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 13, 1)]);
  }

  void test_mixedParameterGroups_positionalNamed() {
    var parseResult = parseStringWithErrors(r'''
void f(a, [b], {c}) {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 13, 1)]);
  }

  void test_mixin_application_lacks_with_clause() {
    var parseResult = parseStringWithErrors(r'''
class Foo = Bar;
''');
    parseResult.assertErrors([error(diag.expectedToken, 15, 1)]);
  }

  void test_multipleExtendsClauses() {
    var parseResult = parseStringWithErrors(r'''
class A extends B extends C {}
''');
    parseResult.assertErrors([error(diag.multipleExtendsClauses, 18, 7)]);
  }

  void test_multipleImplementsClauses() {
    var parseResult = parseStringWithErrors(r'''
class A implements B implements C {}
''');
    parseResult.assertErrors([error(diag.multipleImplementsClauses, 21, 10)]);
  }

  void test_multipleLibraryDirectives() {
    var parseResult = parseStringWithErrors(r'''
library l; library m;
''');
    parseResult.assertErrors([error(diag.multipleLibraryDirectives, 11, 7)]);
  }

  void test_multipleNamedParameterGroups() {
    var parseResult = parseStringWithErrors(r'''
void f(a, {b}, {c}) {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 13, 1)]);
  }

  void test_multiplePartOfDirectives() {
    var parseResult = parseStringWithErrors(r'''
part of l; part of m;
''');
    parseResult.assertErrors([
      error(diag.partOfName, 8, 1),
      error(diag.multiplePartOfDirectives, 11, 4),
      error(diag.partOfName, 19, 1),
    ]);
  }

  void test_multiplePositionalParameterGroups() {
    var parseResult = parseStringWithErrors(r'''
void f(a, [b], [c]) {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 13, 1)]);
  }

  void test_multipleVariablesInForEach() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  for (int a, b in foo) {}
}
''');
    parseResult.assertErrors([error(diag.unexpectedToken, 23, 1)]);
  }

  void test_multipleWithClauses() {
    var parseResult = parseStringWithErrors(r'''
class A extends B with C with D {}
''');
    parseResult.assertErrors([error(diag.multipleWithClauses, 25, 4)]);
  }

  void test_namedFunctionExpression() {
    var parseResult = parseStringWithErrors(r'''
var x = (f() {});
''');
    parseResult.assertErrors([error(diag.namedFunctionExpression, 9, 1)]);

    var node = parseResult.findNode.singleParenthesizedExpression;
    assertParsedNodeText(node, r'''
ParenthesizedExpression
  leftParenthesis: (
  expression: FunctionExpression
    parameters: FormalParameterList
      leftParenthesis: (
      rightParenthesis: )
    body: BlockFunctionBody
      block: Block
        leftBracket: {
        rightBracket: }
  rightParenthesis: )
''');
  }

  void test_namedParameterOutsideGroup() {
    var result = parseStringWithErrors(r'''
void f(a, b : 0) {}
''');
    result.assertErrors([error(diag.namedParameterOutsideGroup, 12, 1)]);

    var list = result.findNode.singleFormalParameterList;
    assertParsedNodeText(list, r'''
FormalParameterList
  leftParenthesis: (
  parameter: SimpleFormalParameter
    name: a
  parameter: DefaultFormalParameter
    parameter: SimpleFormalParameter
      name: b
    separator: :
    defaultValue: IntegerLiteral
      literal: 0
  rightParenthesis: )
''');
  }

  void test_nonConstructorFactory_field() {
    var parseResult = parseStringWithErrors(r'''
class C {
  factory int x;
}
''');
    parseResult.assertErrors([
      error(diag.missingFunctionParameters, 24, 1),
      error(diag.missingFunctionBody, 24, 1),
      error(diag.missingConstFinalVarOrType, 24, 1),
    ]);
  }

  void test_nonConstructorFactory_method() {
    var parseResult = parseStringWithErrors(r'''
class C {
  factory int m() {}
}
''');
    parseResult.assertErrors([
      error(diag.missingFunctionParameters, 24, 1),
      error(diag.missingFunctionBody, 24, 1),
    ]);
  }

  void test_nonIdentifierLibraryName_library() {
    var parseResult = parseStringWithErrors(r'''
library 'lib';
''');
    parseResult.assertErrors([error(diag.missingIdentifier, 8, 5)]);
  }

  void test_nonIdentifierLibraryName_partOf() {
    var parseResult = parseStringWithErrors(r'''
part of 3;
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 5, 2),
      error(diag.expectedStringLiteral, 8, 1),
      error(diag.expectedExecutable, 8, 1),
      error(diag.unexpectedToken, 9, 1),
    ]);
  }

  void test_nonUserDefinableOperator() {
    var parseResult = parseStringWithErrors(r'''
class C {
  operator +=(int x) => x + 1;
}
''');
    parseResult.assertErrors([error(diag.invalidOperator, 21, 2)]);
  }

  void test_optionalAfterNormalParameters_named() {
    var parseResult = parseStringWithErrors(r'''
f({a}, b) {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 5, 1)]);
  }

  void test_optionalAfterNormalParameters_positional() {
    var parseResult = parseStringWithErrors(r'''
f([a], b) {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 5, 1)]);
  }

  void test_parseCascadeSection_missingIdentifier() {
    var result = parseStringWithErrors(r'''
var x = a..();
''');
    result.assertErrors([
      error(diag.missingIdentifier, 11, 1), // at '('
    ]);

    var methodInvocation = result.findNode.singleMethodInvocation;
    assertParsedNodeText(methodInvocation, r'''
MethodInvocation
  operator: ..
  methodName: SimpleIdentifier
    token: <empty> <synthetic>
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
''');
  }

  void test_parseCascadeSection_missingIdentifier_typeArguments() {
    var result = parseStringWithErrors(r'''
var x = a..<E>();
''');
    result.assertErrors([
      error(diag.missingIdentifier, 11, 1), // at '<'
    ]);
    var methodInvocation = result.findNode.singleMethodInvocation;
    assertParsedNodeText(methodInvocation, r'''
MethodInvocation
  operator: ..
  methodName: SimpleIdentifier
    token: <empty> <synthetic>
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: E
    rightBracket: >
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
''');
  }

  void test_partialNamedConstructor() {
    var parseResult = parseStringWithErrors(r'''
class C { C. }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 13, 1),
      error(diag.missingMethodParameters, 10, 1),
      error(diag.missingFunctionBody, 13, 1),
    ]);
  }

  void test_positionalAfterNamedArgument() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  g(x: 1, 2);
}
''', featureSet: FeatureSets.language_2_16);
    parseResult.assertErrors([error(diag.positionalAfterNamedArgument, 21, 1)]);
  }

  void test_positionalParameterOutsideGroup() {
    var result = parseStringWithErrors(r'''
void f(a, b = 0) {}
''');
    result.assertErrors([error(diag.namedParameterOutsideGroup, 12, 1)]);
    var list = result.findNode.singleFormalParameterList;
    assertParsedNodeText(list, r'''
FormalParameterList
  leftParenthesis: (
  parameter: SimpleFormalParameter
    name: a
  parameter: DefaultFormalParameter
    parameter: SimpleFormalParameter
      name: b
    separator: =
    defaultValue: IntegerLiteral
      literal: 0
  rightParenthesis: )
''');
  }

  void test_redirectionInNonFactoryConstructor() {
    var parseResult = parseStringWithErrors(r'''
class C {
  C() = D;
}
''');
    parseResult.assertErrors([
      error(diag.redirectionInNonFactoryConstructor, 16, 1),
    ]);
  }

  void test_setterInFunction_block() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  set x(v) {_x = v;}
}
''');
    parseResult.assertErrors([error(diag.unexpectedToken, 13, 3)]);
  }

  void test_setterInFunction_expression() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  set x(v) => _x = v;
}
''');
    parseResult.assertErrors([error(diag.unexpectedToken, 13, 3)]);
  }

  void test_staticAfterConst() {
    var parseResult = parseStringWithErrors(r'''
class C {
  final static int f = 0;
}
''');
    parseResult.assertErrors([error(diag.modifierOutOfOrder, 18, 6)]);
  }

  void test_staticAfterFinal() {
    var parseResult = parseStringWithErrors(r'''
class C {
  const static int f = 0;
}
''');
    parseResult.assertErrors([error(diag.modifierOutOfOrder, 18, 6)]);
  }

  void test_staticAfterVar() {
    var parseResult = parseStringWithErrors(r'''
class C {
  var static f = 0;
}
''');
    parseResult.assertErrors([error(diag.modifierOutOfOrder, 16, 6)]);
  }

  void test_staticConstructor() {
    var parseResult = parseStringWithErrors(r'''
class C {
  static C.m() {}
}
''');
    parseResult.assertErrors([error(diag.staticConstructor, 12, 6)]);
  }

  void test_staticGetterWithoutBody() {
    var parseResult = parseStringWithErrors(r'''
class C {
  static get m;
}
''');
    parseResult.assertErrors([error(diag.missingFunctionBody, 24, 1)]);
  }

  void test_staticOperator_noReturnType() {
    var parseResult = parseStringWithErrors(r'''
class C {
  static operator +(int x) => x + 1;
}
''');
    parseResult.assertErrors([error(diag.staticOperator, 12, 6)]);
  }

  void test_staticOperator_returnType() {
    var parseResult = parseStringWithErrors(r'''
class C {
  static int operator +(int x) => x + 1;
}
''');
    parseResult.assertErrors([error(diag.staticOperator, 12, 6)]);
  }

  void test_staticOperatorNamedMethod() {
    // operator can be used as a method name
    var parseResult = parseStringWithErrors(r'''
class C { static operator(x) => x; }
''');
    parseResult.assertNoErrors();
  }

  void test_staticSetterWithoutBody() {
    var parseResult = parseStringWithErrors(r'''
class C {
  static set m(x);
}
''');
    parseResult.assertErrors([error(diag.missingFunctionBody, 27, 1)]);
  }

  void test_staticTopLevelDeclaration_class() {
    var parseResult = parseStringWithErrors(r'''
static class C {}
''');
    parseResult.assertErrors([error(diag.extraneousModifier, 0, 6)]);
  }

  void test_staticTopLevelDeclaration_enum() {
    var parseResult = parseStringWithErrors(r'''
static enum E { v }
''');
    parseResult.assertErrors([error(diag.extraneousModifier, 0, 6)]);
  }

  void test_staticTopLevelDeclaration_function() {
    var parseResult = parseStringWithErrors(r'''
static f() {}
''');
    parseResult.assertErrors([error(diag.extraneousModifier, 0, 6)]);
  }

  void test_staticTopLevelDeclaration_typedef() {
    var parseResult = parseStringWithErrors(r'''
static typedef F();
''');
    parseResult.assertErrors([error(diag.extraneousModifier, 0, 6)]);
  }

  void test_staticTopLevelDeclaration_variable() {
    var parseResult = parseStringWithErrors(r'''
static var x;
''');
    parseResult.assertErrors([error(diag.extraneousModifier, 0, 6)]);
  }

  void test_string_unterminated_interpolation_block() {
    // TODO(brianwilkerson): Remove codes when highlighting is fixed.
    var parseResult = parseStringWithErrors(r'''
m() {
 {
 '${${
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 14, 1),
      error(diag.unterminatedStringLiteral, 15, 1),
      error(diag.expectedToken, 16, 1),
      error(diag.expectedToken, 16, 0),
    ]);
  }

  void test_switchCase_missingColon() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  switch (a) {case 1 return 0;}
}
''');
    parseResult.assertErrors([error(diag.expectedToken, 32, 6)]);
  }

  void test_switchDefault_missingColon() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  switch (a) {default return 0;}
}
''');
    parseResult.assertErrors([error(diag.expectedToken, 33, 6)]);
  }

  void test_switchHasCaseAfterDefaultCase() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  switch (a) {default: return 0; case 1: return 1;}
}
''');
    parseResult.assertErrors([
      error(diag.switchHasCaseAfterDefaultCase, 44, 4),
    ]);
  }

  void test_switchHasCaseAfterDefaultCase_repeated() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  switch (a) {default: return 0; case 1: return 1; case 2: return 2;}
}
''');
    parseResult.assertErrors([
      error(diag.switchHasCaseAfterDefaultCase, 44, 4),
      error(diag.switchHasCaseAfterDefaultCase, 62, 4),
    ]);
  }

  void test_switchHasMultipleDefaultCases() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  switch (a) {default: return 0; default: return 1;}
}
''');
    parseResult.assertErrors([
      error(diag.switchHasMultipleDefaultCases, 44, 7),
    ]);
  }

  void test_switchHasMultipleDefaultCases_repeated() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  switch (a) {default: return 0; default: return 1; default: return 2;}
}
''');
    parseResult.assertErrors([
      error(diag.switchHasMultipleDefaultCases, 44, 7),
      error(diag.switchHasMultipleDefaultCases, 63, 7),
    ]);
  }

  void test_switchMissingBlock() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  switch (a) return;
}
''');
    parseResult.assertErrors([error(diag.expectedSwitchStatementBody, 22, 1)]);
  }

  void test_topLevel_getter() {
    var result = parseStringWithErrors(r'''
get x => 7;
''');
    result.assertNoErrors();
    var node = result.findNode.singleFunctionDeclaration;
    assertParsedNodeText(node, r'''
FunctionDeclaration
  propertyKeyword: get
  name: x
  functionExpression: FunctionExpression
    body: ExpressionFunctionBody
      functionDefinition: =>
      expression: IntegerLiteral
        literal: 7
      semicolon: ;
''');
  }

  void test_topLevelFactory_withFunction() {
    var parseResult = parseStringWithErrors(r'''
factory Function() x = null;
''');
    parseResult.assertErrors([error(diag.factoryTopLevelDeclaration, 0, 7)]);
  }

  void test_topLevelOperator_withFunction() {
    var parseResult = parseStringWithErrors(r'''
operator Function() x = null;
''');
    parseResult.assertErrors([error(diag.topLevelOperator, 0, 8)]);
  }

  void test_topLevelOperator_withoutOperator() {
    var parseResult = parseStringWithErrors(r'''
+(bool x, bool y) => x | y;
''');
    parseResult.assertErrors([error(diag.topLevelOperator, 0, 1)]);
  }

  void test_topLevelOperator_withoutType() {
    var parseResult = parseStringWithErrors(r'''
operator +(bool x, bool y) => x | y;
''');
    parseResult.assertErrors([error(diag.topLevelOperator, 0, 8)]);
  }

  void test_topLevelOperator_withType() {
    var parseResult = parseStringWithErrors(r'''
bool operator +(bool x, bool y) => x | y;
''');
    parseResult.assertErrors([error(diag.topLevelOperator, 5, 8)]);
  }

  void test_topLevelOperator_withVoid() {
    var parseResult = parseStringWithErrors(r'''
void operator +(bool x, bool y) => x | y;
''');
    parseResult.assertErrors([error(diag.topLevelOperator, 5, 8)]);
  }

  void test_topLevelVariable_withMetadata() {
    var parseResult = parseStringWithErrors(r'''
String @A string;
''');
    parseResult.assertErrors([
      error(diag.missingConstFinalVarOrType, 0, 6),
      error(diag.expectedToken, 0, 6),
      error(diag.missingConstFinalVarOrType, 10, 6),
    ]);
  }

  void test_typedef_incomplete() {
    // TODO(brianwilkerson): Improve recovery for this case.
    var parseResult = parseStringWithErrors(r'''
class A {}
class B extends A {}

typedef T

main() {
  Function<
}
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 49, 1),
      error(diag.expectedExecutable, 51, 1),
    ]);
  }

  void test_typedef_namedFunction() {
    var parseResult = parseStringWithErrors(r'''
typedef void Function();
''');
    parseResult.assertErrors([
      error(diag.expectedIdentifierButGotKeyword, 13, 8),
    ]);
  }

  void test_typedefInClass_withoutReturnType() {
    var parseResult = parseStringWithErrors(r'''
class C { typedef F(x); }
''');
    parseResult.assertErrors([error(diag.typedefInClass, 10, 7)]);
  }

  void test_typedefInClass_withReturnType() {
    var parseResult = parseStringWithErrors(r'''
class C { typedef int F(int x); }
''');
    parseResult.assertErrors([error(diag.typedefInClass, 10, 7)]);
  }

  void test_unexpectedCommaThenInterpolation() {
    // https://github.com/Dart-Code/Dart-Code/issues/1548
    var parseResult = parseStringWithErrors(r'''
main() { String s = 'a' 'b', 'c$foo'; return s; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 27, 1),
      error(diag.missingIdentifier, 29, 2),
    ]);
  }

  void test_unexpectedTerminatorForParameterGroup_named() {
    var parseResult = parseStringWithErrors(r'''
void f(a, b}) {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 11, 1)]);
  }

  void test_unexpectedTerminatorForParameterGroup_optional() {
    var parseResult = parseStringWithErrors(r'''
void f(a, b]) {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 11, 1)]);
  }

  void test_unexpectedToken_endOfFieldDeclarationStatement() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  String s = (null));
}
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 29, 1),
      error(diag.missingIdentifier, 30, 1),
      error(diag.unexpectedToken, 30, 1),
    ]);
  }

  void test_unexpectedToken_invalidPostfixExpression() {
    var parseResult = parseStringWithErrors(r'''
var v = f()++;
''');
    parseResult.assertErrors([
      error(diag.illegalAssignmentToNonAssignable, 11, 2),
    ]);
  }

  void test_unexpectedToken_invalidPrefixExpression() {
    var parseResult = parseStringWithErrors(r'''
var v = ++f();
''');
    parseResult.assertErrors([error(diag.missingAssignableSelector, 12, 1)]);
  }

  void test_unexpectedToken_returnInExpressionFunctionBody() {
    var parseResult = parseStringWithErrors(r'''
f() => return null;
''');
    parseResult.assertErrors([error(diag.unexpectedToken, 7, 6)]);
  }

  void test_unexpectedToken_semicolonBetweenClassMembers() {
    var parseResult = parseStringWithErrors(r'''
class C { int x; ; int y;}
''');
    parseResult.assertErrors([error(diag.expectedClassMember, 17, 1)]);
  }

  void test_unexpectedToken_semicolonBetweenCompilationUnitMembers() {
    var parseResult = parseStringWithErrors(r'''
int x; ; int y;
''');
    parseResult.assertErrors([error(diag.unexpectedToken, 7, 1)]);
  }

  void test_unnamedLibraryDirective() {
    parseStringWithErrors(
      'library;',
      featureSet: FeatureSets.language_2_18,
    ).assertErrors([error(diag.experimentNotEnabled, 0, 7)]);
  }

  void test_unnamedLibraryDirective_enabled() {
    var parseResult = parseStringWithErrors('library;');
    parseResult.assertNoErrors();
  }

  void test_unterminatedString_at_eof() {
    // Although the "unterminated string" error message is produced by the
    // scanner, we need to verify that the parser can handle the tokens
    // produced by the scanner when an unterminated string is encountered.
    var parseResult = parseStringWithErrors(r'''
void main() {
  var x = "''');
    parseResult.assertErrors([
      error(diag.unterminatedStringLiteral, 24, 1),
      error(diag.expectedToken, 25, 1),
      error(diag.expectedToken, 24, 1),
    ]);
  }

  void test_unterminatedString_at_eol() {
    // Although the "unterminated string" error message is produced by the
    // scanner, we need to verify that the parser can handle the tokens
    // produced by the scanner when an unterminated string is encountered.
    var parseResult = parseStringWithErrors(r'''
void main() {
  var x = "
;
}
''');
    parseResult.assertErrors([error(diag.unterminatedStringLiteral, 24, 1)]);
  }

  void test_unterminatedString_multiline_at_eof_3_quotes() {
    // Although the "unterminated string" error message is produced by the
    // scanner, we need to verify that the parser can handle the tokens
    // produced by the scanner when an unterminated string is encountered.
    // TODO(brianwilkerson): Remove codes when highlighting is fixed.
    var parseResult = parseStringWithErrors(r'''
void main() {
  var x = """''');
    parseResult.assertErrors([
      error(diag.expectedToken, 24, 3),
      error(diag.unterminatedStringLiteral, 26, 1),
      error(diag.expectedToken, 27, 1),
    ]);
  }

  void test_unterminatedString_multiline_at_eof_4_quotes() {
    // Although the "unterminated string" error message is produced by the
    // scanner, we need to verify that the parser can handle the tokens
    // produced by the scanner when an unterminated string is encountered.
    // TODO(brianwilkerson): Remove codes when highlighting is fixed.
    var parseResult = parseStringWithErrors(r'''
void main() {
  var x = """"''');
    parseResult.assertErrors([
      error(diag.expectedToken, 24, 4),
      error(diag.unterminatedStringLiteral, 27, 1),
      error(diag.expectedToken, 28, 1),
    ]);
  }

  void test_unterminatedString_multiline_at_eof_5_quotes() {
    // Although the "unterminated string" error message is produced by the
    // scanner, we need to verify that the parser can handle the tokens
    // produced by the scanner when an unterminated string is encountered.
    // TODO(brianwilkerson): Remove codes when highlighting is fixed.
    var parseResult = parseStringWithErrors(r'''
void main() {
  var x = """""''');
    parseResult.assertErrors([
      error(diag.expectedToken, 24, 5),
      error(diag.unterminatedStringLiteral, 28, 1),
      error(diag.expectedToken, 29, 1),
    ]);
  }

  void test_useOfUnaryPlusOperator() {
    var result = parseStringWithErrors('var v = +x;');
    result.assertErrors([error(diag.missingIdentifier, 8, 1)]);
    var binaryExpression = result.findNode.singleBinaryExpression;
    assertParsedNodeText(binaryExpression, r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: <empty> <synthetic>
  operator: +
  rightOperand: SimpleIdentifier
    token: x
''');
  }

  void test_varAndType_field() {
    var parseResult = parseStringWithErrors(r'''
class C { var int x; }
''');
    parseResult.assertErrors([error(diag.varAndType, 10, 3)]);
  }

  void test_varAndType_local() {
    // This is currently reporting EXPECTED_TOKEN for a missing semicolon, but
    // this would be a better error message.
    var parseResult = parseStringWithErrors(r'''
void f() {
  var int x;
}
''');
    parseResult.assertErrors([error(diag.varAndType, 13, 3)]);
  }

  void test_varAndType_parameter() {
    // This is currently reporting EXPECTED_TOKEN for a missing semicolon, but
    // this would be a better error message.
    var parseResult = parseStringWithErrors(r'''
void f(var int x) {}
''');
    parseResult.assertErrors([
      error(diag.extraneousModifier, 7, 3),
      error(diag.varAndType, 7, 3),
    ]);
  }

  void test_varAndType_topLevelVariable() {
    var parseResult = parseStringWithErrors(r'''
var int x;
''');
    parseResult.assertErrors([error(diag.varAndType, 0, 3)]);
  }

  void test_varAsTypeName_as() {
    var parseResult = parseStringWithErrors(r'''
var v = x as var;
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 10, 2),
      error(diag.expectedTypeName, 13, 3),
      error(diag.missingIdentifier, 16, 1),
    ]);
  }

  void test_varClass() {
    var parseResult = parseStringWithErrors(r'''
var class C {}
''');
    parseResult.assertErrors([
      // Fasta interprets the `var` as a malformed top level var
      // and `class` as the start of a class declaration.
      error(diag.expectedToken, 0, 3),
      error(diag.missingIdentifier, 4, 5),
    ]);
  }

  void test_varEnum() {
    var parseResult = parseStringWithErrors(r'''
var enum E {ONE}
''');
    parseResult.assertErrors([
      // Fasta interprets the `var` as a malformed top level var
      // and `enum` as the start of an enum declaration.
      error(diag.expectedToken, 0, 3),
      error(diag.missingIdentifier, 4, 4),
    ]);
  }

  void test_varReturnType() {
    var parseResult = parseStringWithErrors(r'''
class C {
  var m() {}
}
''');
    parseResult.assertErrors([error(diag.varReturnType, 12, 3)]);
  }

  void test_varTypedef() {
    var parseResult = parseStringWithErrors(r'''
var typedef F();
''');
    parseResult.assertErrors([
      // Fasta interprets the `var` as a malformed top level var
      // and `typedef` as the start of an typedef declaration.
      error(diag.expectedToken, 0, 3),
      error(diag.missingIdentifier, 4, 7),
    ]);
  }

  void test_voidParameter() {
    var result = parseStringWithErrors(r'''
void f(void a) {}
''');
    result.assertNoErrors();
    var node = result.findNode.singleFormalParameter;
    assertParsedNodeText(node, r'''
SimpleFormalParameter
  type: NamedType
    name: void
  name: a
''');
  }

  void test_voidVariable_parseClassMember_initializer() {
    var parseResult = parseStringWithErrors(r'''
class C {
  void x = 0;
}
''');
    parseResult.assertNoErrors();
  }

  void test_voidVariable_parseClassMember_noInitializer() {
    var parseResult = parseStringWithErrors(r'''
class C {
  void x;
}
''');
    parseResult.assertNoErrors();
  }

  void test_voidVariable_parseCompilationUnit_initializer() {
    var parseResult = parseStringWithErrors(r'''
void x = 0;
''');
    parseResult.assertNoErrors();
  }

  void test_voidVariable_parseCompilationUnit_noInitializer() {
    var parseResult = parseStringWithErrors(r'''
void x;
''');
    parseResult.assertNoErrors();
  }

  void test_voidVariable_parseCompilationUnitMember_initializer() {
    var parseResult = parseStringWithErrors(r'''
void a = 0;
''');
    parseResult.assertNoErrors();
  }

  void test_voidVariable_parseCompilationUnitMember_noInitializer() {
    var parseResult = parseStringWithErrors(r'''
void a;
''');
    parseResult.assertNoErrors();
  }

  void test_voidVariable_statement_initializer() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  void x = 0;
}
''');
    parseResult.assertNoErrors();
  }

  void test_voidVariable_statement_noInitializer() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  void x;
}
''');
    parseResult.assertNoErrors();
  }

  void test_withBeforeExtends() {
    var parseResult = parseStringWithErrors(r'''
class A with B extends C {}
''');
    parseResult.assertErrors([error(diag.withBeforeExtends, 15, 7)]);
  }

  void test_withWithoutExtends() {
    var parseResult = parseStringWithErrors(r'''
class A with B, C {}
''');
    parseResult.assertNoErrors();
  }

  void test_wrongSeparatorForPositionalParameter() {
    var parseResult = parseStringWithErrors(r'''
void f(a, [b : 0]) {}
''');
    parseResult.assertErrors([
      error(diag.wrongSeparatorForPositionalParameter, 13, 1),
    ]);
  }

  void test_wrongTerminatorForParameterGroup_named() {
    var parseResult = parseStringWithErrors(r'''
void f(a, {b, c]) {}
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 15, 1),
      error(diag.expectedToken, 16, 1),
    ]);
  }

  void test_wrongTerminatorForParameterGroup_optional() {
    var parseResult = parseStringWithErrors(r'''
void f(a, [b, c}) {}
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 15, 1),
      error(diag.expectedToken, 16, 1),
    ]);
  }

  void test_yieldAsLabel() {
    // yield can be used as a label
    var parseResult = parseStringWithErrors('main() { yield: break yield; }');
    parseResult.assertNoErrors();
  }
}
