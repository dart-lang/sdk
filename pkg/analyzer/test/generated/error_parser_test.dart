// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../src/dart/resolution/node_text_expectations.dart';
import '../src/diagnostics/parser_diagnostics.dart';
import '../util/feature_sets.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ErrorParserTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

/// This defines parser tests that test the parsing of code to ensure that
/// errors are correctly reported, and in some cases, not reported.
@reflectiveTest
class ErrorParserTest extends ParserDiagnosticsTest {
  void test_abstractClassMember_constructor() {
    parseTestCodeWithDiagnostics(r'''
abstract class C {
  abstract C.c();
//^^^^^^^^
// [diag.abstractClassMember] Members of classes can't be declared to be 'abstract'.
}
''');
  }

  void test_abstractClassMember_field() {
    parseTestCodeWithDiagnostics(r'''
abstract class C {
  abstract C f;
}
''');
  }

  void test_abstractClassMember_getter() {
    parseTestCodeWithDiagnostics(r'''
abstract class C {
  abstract get m;
//^^^^^^^^
// [diag.abstractClassMember] Members of classes can't be declared to be 'abstract'.
}
''');
  }

  void test_abstractClassMember_method() {
    parseTestCodeWithDiagnostics(r'''
abstract class C {
  abstract m();
//^^^^^^^^
// [diag.abstractClassMember] Members of classes can't be declared to be 'abstract'.
}
''');
  }

  void test_abstractClassMember_setter() {
    parseTestCodeWithDiagnostics(r'''
abstract class C {
  abstract set m(v);
//^^^^^^^^
// [diag.abstractClassMember] Members of classes can't be declared to be 'abstract'.
}
''');
  }

  void test_abstractEnum() {
    parseTestCodeWithDiagnostics(r'''
abstract enum E {ONE}
// [diag.extraneousModifier][column 1][length 8] Can't have modifier 'abstract' here.
''');
  }

  void test_abstractTypeDef() {
    parseTestCodeWithDiagnostics(r'''
abstract typedef F();
// [diag.extraneousModifier][column 1][length 8] Can't have modifier 'abstract' here.
''');
  }

  void test_await_missing_async2_issue36048() {
    parseTestCodeWithDiagnostics(r'''
main() { // missing async
  await foo.bar();
//^^^^^
// [diag.awaitInWrongContext] The await expression can only be used in an async function.
}
''');
  }

  void test_await_missing_async3_issue36048() {
    // missing async
    parseTestCodeWithDiagnostics(r'''
main() {
  (await foo);
// ^^^^^
// [diag.awaitInWrongContext] The await expression can only be used in an async function.
}
''');
  }

  void test_await_missing_async4_issue36048() {
    // missing async
    parseTestCodeWithDiagnostics(r'''
main() {
  [await foo];
// ^^^^^
// [diag.awaitInWrongContext] The await expression can only be used in an async function.
}
''');
  }

  void test_await_missing_async_issue36048() {
    parseTestCodeWithDiagnostics(r'''
main() { // missing async
  await foo();
//^^^^^
// [diag.awaitInWrongContext] The await expression can only be used in an async function.
}
''');
  }

  void test_breakOutsideOfLoop_breakInDoStatement() {
    parseTestCodeWithDiagnostics(r'''
void f() {
  do {break;} while (x);
}
''');
  }

  void test_breakOutsideOfLoop_breakInForStatement() {
    parseTestCodeWithDiagnostics(r'''
void f() {
  for (; x;) {break;}
}
''');
  }

  void test_breakOutsideOfLoop_breakInIfStatement() {
    parseTestCodeWithDiagnostics(r'''
void f() {
  if (x) {break;}
//        ^^^^^
// [diag.breakOutsideOfLoop] A break statement can't be used outside of a loop or switch statement.
}
''');
  }

  void test_breakOutsideOfLoop_breakInSwitchStatement() {
    parseTestCodeWithDiagnostics(r'''
void f() {
  switch (x) {case 1: break;}
}
''');
  }

  void test_breakOutsideOfLoop_breakInWhileStatement() {
    parseTestCodeWithDiagnostics(r'''
void f() {
  while (x) {break;}
}
''');
  }

  void test_breakOutsideOfLoop_functionExpression_inALoop() {
    parseTestCodeWithDiagnostics(r'''
void f() {
  for(; x;) {() {break;};}
//               ^^^^^
// [diag.breakOutsideOfLoop] A break statement can't be used outside of a loop or switch statement.
}
''');
  }

  void test_breakOutsideOfLoop_functionExpression_withALoop() {
    parseTestCodeWithDiagnostics(r'''
void f() {
  () {for (; x;) {break;}};
}
''');
  }

  void test_classInClass_abstract() {
    parseTestCodeWithDiagnostics(r'''
class C { abstract class B {} }
//        ^^^^^^^^
// [diag.abstractClassMember] Members of classes can't be declared to be 'abstract'.
//                 ^^^^^
// [diag.classInClass] Classes can't be declared inside other classes.
''');
  }

  void test_classInClass_nonAbstract() {
    parseTestCodeWithDiagnostics(r'''
class C { class B {} }
//        ^^^^^
// [diag.classInClass] Classes can't be declared inside other classes.
''');
  }

  void test_classTypeAlias_abstractAfterEq() {
    // This syntax has been removed from the language in favor of
    // "abstract class A = B with C;" (issue 18098).
    parseTestCodeWithDiagnostics(r'''
class A = abstract B with C;
//        ^^^^^^^^
// [diag.builtInIdentifierAsType] The built-in identifier 'abstract' can't be used as a type.
//                 ^
// [diag.expectedToken] Expected to find 'with'.
// [diag.expectedToken] Expected to find ';'.
//                   ^^^^
// [diag.missingConstFinalVarOrType] Variables must be declared using the keywords 'const', 'final', 'var' or a type name.
// [diag.expectedIdentifierButGotKeyword] 'with' can't be used as an identifier because it's a keyword.
// [diag.expectedToken] Expected to find ';'.
//                        ^
// [diag.missingConstFinalVarOrType] Variables must be declared using the keywords 'const', 'final', 'var' or a type name.
''');
  }

  void test_colonInPlaceOfIn() {
    parseTestCodeWithDiagnostics(r'''
void f() {
  for (var x : list) {}
//           ^
// [diag.colonInPlaceOfIn] For-in loops use 'in' rather than a colon.
}
''');
  }

  void test_constAndCovariant() {
    parseTestCodeWithDiagnostics(r'''
class C {
  covariant const C f = null;
//          ^^^^^
// [diag.conflictingModifiers] Members can't be declared to be both 'const' and 'covariant'.
}
''');
  }

  void test_constAndFinal() {
    parseTestCodeWithDiagnostics(r'''
class C {
  const final int x = null;
//      ^^^^^
// [diag.constAndFinal] Members can't be declared to be both 'const' and 'final'.
}
''');
  }

  void test_constAndVar() {
    parseTestCodeWithDiagnostics(r'''
class C {
  const var x = null;
//      ^^^
// [diag.conflictingModifiers] Members can't be declared to be both 'var' and 'const'.
}
''');
  }

  void test_constClass() {
    parseTestCodeWithDiagnostics(r'''
const class C {}
// [diag.constClass][column 1][length 5] Classes can't be declared to be 'const'.
''');
  }

  void test_constEnum() {
    // Fasta interprets the `const` as a malformed top level const
    // and `enum` as the start of an enum declaration.
    parseTestCodeWithDiagnostics(r'''
const enum E {ONE}
// [diag.expectedToken][column 1][length 5] Expected to find ';'.
//    ^^^^
// [diag.missingIdentifier] Expected an identifier.
''');
  }

  void test_constFactory() {
    parseTestCodeWithDiagnostics(r'''
class C {
  const factory C() {}
}
''');
  }

  void test_constMethod() {
    parseTestCodeWithDiagnostics(r'''
class C {
  const int m() {}
//^^^^^
// [diag.constMethod] Getters, setters and methods can't be declared to be 'const'.
}
''');
  }

  void test_constMethod_noReturnType() {
    parseTestCodeWithDiagnostics(r'''
class C {
  const m() {}
//^^^^^
// [diag.constMethod] Getters, setters and methods can't be declared to be 'const'.
}
''');
  }

  void test_constMethod_noReturnType2() {
    parseTestCodeWithDiagnostics(r'''
class C {
  const m();
//^^^^^
// [diag.constMethod] Getters, setters and methods can't be declared to be 'const'.
}
''');
  }

  void test_constructor_super_cascade_synthetic() {
    // https://github.com/dart-lang/sdk/issues/37110
    parseTestCodeWithDiagnostics(r'''
class B extends A { B(): super.. {} }
//                       ^^^^^
// [diag.invalidSuperInInitializer] Can only use 'super' in an initializer for calling the superclass constructor (e.g. 'super()' or 'super.namedConstructor()')
//                            ^^
// [diag.expectedToken] Expected to find '('.
//                               ^
// [diag.missingIdentifier] Expected an identifier.
''');
  }

  void test_constructor_super_field() {
    // https://github.com/dart-lang/sdk/issues/36262
    // https://github.com/dart-lang/sdk/issues/31198
    parseTestCodeWithDiagnostics(r'''
class B extends A { B(): super().foo {} }
//                       ^^^^^
// [diag.invalidSuperInInitializer] Can only use 'super' in an initializer for calling the superclass constructor (e.g. 'super()' or 'super.namedConstructor()')
''');
  }

  void test_constructor_super_method() {
    // https://github.com/dart-lang/sdk/issues/36262
    // https://github.com/dart-lang/sdk/issues/31198
    parseTestCodeWithDiagnostics(r'''
class B extends A { B(): super().foo() {} }
//                       ^^^^^
// [diag.invalidSuperInInitializer] Can only use 'super' in an initializer for calling the superclass constructor (e.g. 'super()' or 'super.namedConstructor()')
''');
  }

  void test_constructor_super_named_method() {
    // https://github.com/dart-lang/sdk/issues/37600
    parseTestCodeWithDiagnostics(r'''
class B extends A { B(): super.c().create() {} }
//                       ^^^^^
// [diag.invalidSuperInInitializer] Can only use 'super' in an initializer for calling the superclass constructor (e.g. 'super()' or 'super.namedConstructor()')
''');
  }

  void test_constructor_super_named_method_method() {
    // https://github.com/dart-lang/sdk/issues/37600
    parseTestCodeWithDiagnostics(r'''
class B extends A { B(): super.c().create().x() {} }
//                       ^^^^^
// [diag.invalidSuperInInitializer] Can only use 'super' in an initializer for calling the superclass constructor (e.g. 'super()' or 'super.namedConstructor()')
''');
  }

  void test_constructor_this_cascade_synthetic() {
    // https://github.com/dart-lang/sdk/issues/37110
    parseTestCodeWithDiagnostics(r'''
class B extends A { B(): this.. {} }
//                       ^^^^
// [diag.missingAssignmentInInitializer] Expected an assignment after the field name.
//                           ^^
// [diag.expectedToken] Expected to find '.'.
//                              ^
// [diag.missingIdentifier] Expected an identifier.
''');
  }

  void test_constructor_this_field() {
    // https://github.com/dart-lang/sdk/issues/36262
    // https://github.com/dart-lang/sdk/issues/31198
    parseTestCodeWithDiagnostics(r'''
class B extends A { B(): this().foo; }
//                       ^^^^
// [diag.invalidThisInInitializer] Can only use 'this' in an initializer for field initialization (e.g. 'this.x = something') and constructor redirection (e.g. 'this()' or 'this.namedConstructor())
''');
  }

  void test_constructor_this_method() {
    // https://github.com/dart-lang/sdk/issues/36262
    // https://github.com/dart-lang/sdk/issues/31198
    parseTestCodeWithDiagnostics(r'''
class B extends A { B(): this().foo(); }
//                       ^^^^
// [diag.invalidThisInInitializer] Can only use 'this' in an initializer for field initialization (e.g. 'this.x = something') and constructor redirection (e.g. 'this()' or 'this.namedConstructor())
''');
  }

  void test_constructor_this_named_method() {
    // https://github.com/dart-lang/sdk/issues/37600
    parseTestCodeWithDiagnostics(r'''
class B extends A { B(): super.c().create() {} }
//                       ^^^^^
// [diag.invalidSuperInInitializer] Can only use 'super' in an initializer for calling the superclass constructor (e.g. 'super()' or 'super.namedConstructor()')
''');
  }

  void test_constructor_this_named_method_field() {
    // https://github.com/dart-lang/sdk/issues/37600
    parseTestCodeWithDiagnostics(r'''
class B extends A { B(): super.c().create().x {} }
//                       ^^^^^
// [diag.invalidSuperInInitializer] Can only use 'super' in an initializer for calling the superclass constructor (e.g. 'super()' or 'super.namedConstructor()')
''');
  }

  void test_constructorPartial() {
    parseTestCodeWithDiagnostics(r'''
class C { C< }
//         ^
// [diag.expectedToken] Expected to find ';'.
//           ^
// [diag.expectedTypeName] Expected a type name.
// [diag.missingIdentifier] Expected an identifier.
''');
  }

  void test_constructorPartial2() {
    parseTestCodeWithDiagnostics(r'''
class C { C<@Foo }
//          ^^^^
// [diag.annotationOnTypeArgument] Type arguments can't have annotations because they aren't declarations.
//           ^^^
// [diag.expectedToken] Expected to find ';'.
//               ^
// [diag.expectedTypeName] Expected a type name.
// [diag.missingIdentifier] Expected an identifier.
''');
  }

  void test_constructorPartial3() {
    parseTestCodeWithDiagnostics(r'''
class C { C<@Foo @Bar() }
//          ^^^^
// [diag.annotationOnTypeArgument] Type arguments can't have annotations because they aren't declarations.
//               ^^^^^^
// [diag.annotationOnTypeArgument] Type arguments can't have annotations because they aren't declarations.
//                    ^
// [diag.expectedToken] Expected to find ';'.
//                      ^
// [diag.expectedTypeName] Expected a type name.
// [diag.missingIdentifier] Expected an identifier.
''');
  }

  void test_constructorWithReturnType() {
    parseTestCodeWithDiagnostics(r'''
class C {
  C C() {}
//^
// [diag.constructorWithReturnType] Constructors can't have a return type.
}
''');
  }

  void test_constructorWithReturnType_var() {
    parseTestCodeWithDiagnostics(r'''
class C {
  var C() {}
//^^^
// [diag.varReturnType] The return type can't be 'var'.
}
''');
  }

  void test_constTypedef() {
    // Fasta interprets the `const` as a malformed top level const
    // and `typedef` as the start of an typedef declaration.
    parseTestCodeWithDiagnostics(r'''
const typedef F();
// [diag.expectedToken][column 1][length 5] Expected to find ';'.
//    ^^^^^^^
// [diag.missingIdentifier] Expected an identifier.
''');
  }

  void test_continueOutsideOfLoop_continueInDoStatement() {
    parseTestCodeWithDiagnostics(r'''
void f() {
  do {continue;} while (x);
}
''');
  }

  void test_continueOutsideOfLoop_continueInForStatement() {
    parseTestCodeWithDiagnostics(r'''
void f() {
  for (; x;) {continue;}
}
''');
  }

  void test_continueOutsideOfLoop_continueInIfStatement() {
    parseTestCodeWithDiagnostics(r'''
void f() {
  if (x) {continue;}
//        ^^^^^^^^
// [diag.continueOutsideOfLoop] A continue statement can't be used outside of a loop or switch statement.
}
''');
  }

  void test_continueOutsideOfLoop_continueInSwitchStatement() {
    parseTestCodeWithDiagnostics(r'''
void f() {
  switch (x) {case 1: continue a;}
}
''');
  }

  void test_continueOutsideOfLoop_continueInWhileStatement() {
    parseTestCodeWithDiagnostics(r'''
void f() {
  while (x) {continue;}
}
''');
  }

  void test_continueOutsideOfLoop_functionExpression_inALoop() {
    parseTestCodeWithDiagnostics(r'''
void f() {
  for(; x;) {() {continue;};}
//               ^^^^^^^^
// [diag.continueOutsideOfLoop] A continue statement can't be used outside of a loop or switch statement.
}
''');
  }

  void test_continueOutsideOfLoop_functionExpression_withALoop() {
    parseTestCodeWithDiagnostics(r'''
void f() {
  () {for (; x;) {continue;}};
}
''');
  }

  void test_continueWithoutLabelInCase_error() {
    parseTestCodeWithDiagnostics(r'''
void f() {
  switch (x) {case 1: continue;}
//                    ^^^^^^^^
// [diag.continueWithoutLabelInCase] A continue statement in a switch statement must have a label as a target.
}
''');
  }

  void test_continueWithoutLabelInCase_noError() {
    parseTestCodeWithDiagnostics(r'''
void f() {
  switch (x) {case 1: continue a;}
}
''');
  }

  void test_continueWithoutLabelInCase_noError_switchInLoop() {
    parseTestCodeWithDiagnostics(r'''
void f() {
  while (a) { switch (b) {default: continue;}}
}
''');
  }

  void test_covariantAfterVar() {
    parseTestCodeWithDiagnostics(r'''
class C {
  var covariant f;
//    ^^^^^^^^^
// [diag.modifierOutOfOrder] The modifier 'covariant' should be before the modifier 'var'.
}
''');
  }

  void test_covariantAndFinal() {
    parseTestCodeWithDiagnostics(r'''
class C {
  covariant final f = null;
//^^^^^^^^^
// [diag.finalAndCovariant] Members can't be declared to be both 'final' and 'covariant'.
}
''');
  }

  void test_covariantAndStatic() {
    parseTestCodeWithDiagnostics(r'''
class C {
  covariant static A f;
//          ^^^^^^
// [diag.covariantAndStatic] Members can't be declared to be both 'covariant' and 'static'.
}
''');
  }

  void test_covariantAndType_local() {
    // This is currently reporting EXPECTED_TOKEN for a missing semicolon, but
    // this would be a better error message.
    parseTestCodeWithDiagnostics(r'''
void f() {
  covariant int x;
//^^^^^^^^^
// [diag.extraneousModifier] Can't have modifier 'covariant' here.
}
''');
  }

  void test_covariantConstructor() {
    parseTestCodeWithDiagnostics(r'''
class C { covariant C(); }
//        ^^^^^^^^^
// [diag.covariantMember] Getters, setters and methods can't be declared to be 'covariant'.
''');
  }

  void test_covariantMember_getter_noReturnType() {
    parseTestCodeWithDiagnostics(r'''
class C {
  static covariant get x => 0;
//       ^^^^^^^^^
// [diag.covariantAndStatic] Members can't be declared to be both 'covariant' and 'static'.
}
''');
  }

  void test_covariantMember_getter_returnType() {
    parseTestCodeWithDiagnostics(r'''
class C {
  static covariant int get x => 0;
//       ^^^^^^^^^
// [diag.covariantAndStatic] Members can't be declared to be both 'covariant' and 'static'.
}
''');
  }

  void test_covariantMember_method() {
    parseTestCodeWithDiagnostics(r'''
class C {
  covariant int m() => 0;
//^^^^^^^^^
// [diag.covariantMember] Getters, setters and methods can't be declared to be 'covariant'.
}
''');
  }

  void test_covariantTopLevelDeclaration_class() {
    parseTestCodeWithDiagnostics(r'''
covariant class C {}
// [diag.extraneousModifier][column 1][length 9] Can't have modifier 'covariant' here.
''');
  }

  void test_covariantTopLevelDeclaration_enum() {
    parseTestCodeWithDiagnostics(r'''
covariant enum E { v }
// [diag.extraneousModifier][column 1][length 9] Can't have modifier 'covariant' here.
''');
  }

  void test_covariantTopLevelDeclaration_typedef() {
    parseTestCodeWithDiagnostics(r'''
covariant typedef F();
// [diag.extraneousModifier][column 1][length 9] Can't have modifier 'covariant' here.
''');
  }

  void test_defaultValueInFunctionType_named_colon() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
typedef F = void Function({int x : 0});
//                               ^
// [diag.defaultValueInFunctionType] Parameters in a function type can't have default values.
''');

    var node = parseResult.findNode.singleFormalParameterList;
    assertParsedNodeText(node, r'''
FormalParameterList
  leftParenthesis: (
  leftDelimiter: {
  parameter: RegularFormalParameter
    type: NamedType
      name: int
    name: x
    defaultClause: FormalParameterDefaultClause
      separator: :
      value: IntegerLiteral
        literal: 0
  rightDelimiter: }
  rightParenthesis: )
''');
  }

  void test_defaultValueInFunctionType_named_equal() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
typedef F = void Function({int x = 0});
//                               ^
// [diag.defaultValueInFunctionType] Parameters in a function type can't have default values.
''');

    var node = parseResult.findNode.singleFormalParameterList;
    assertParsedNodeText(node, r'''
FormalParameterList
  leftParenthesis: (
  leftDelimiter: {
  parameter: RegularFormalParameter
    type: NamedType
      name: int
    name: x
    defaultClause: FormalParameterDefaultClause
      separator: =
      value: IntegerLiteral
        literal: 0
  rightDelimiter: }
  rightParenthesis: )
''');
  }

  void test_defaultValueInFunctionType_positional() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
typedef F = void Function([int x = 0]);
//                               ^
// [diag.defaultValueInFunctionType] Parameters in a function type can't have default values.
''');

    var node = parseResult.findNode.singleFormalParameterList;
    assertParsedNodeText(node, r'''
FormalParameterList
  leftParenthesis: (
  leftDelimiter: [
  parameter: RegularFormalParameter
    type: NamedType
      name: int
    name: x
    defaultClause: FormalParameterDefaultClause
      separator: =
      value: IntegerLiteral
        literal: 0
  rightDelimiter: ]
  rightParenthesis: )
''');
  }

  void test_directiveAfterDeclaration_classBeforeDirective() {
    // TODO(brianwilkerson): Remove codes when highlighting is fixed.
    parseTestCodeWithDiagnostics(r'''
class Foo{}
library l;
// [diag.libraryDirectiveNotFirst][column 1][length 7] The library directive must appear before all other directives.
''');
  }

  void test_directiveAfterDeclaration_classBetweenDirectives() {
    // TODO(brianwilkerson): Remove codes when highlighting is fixed.
    parseTestCodeWithDiagnostics(r'''
library l;
class Foo{}
part 'a.dart';
// [diag.directiveAfterDeclaration][column 1][length 4] Directives must appear before any declarations.
''');
  }

  void test_duplicatedModifier_const() {
    parseTestCodeWithDiagnostics(r'''
class C {
  const const m = null;
//      ^^^^^
// [diag.duplicatedModifier] The modifier 'const' was already specified.
}
''');
  }

  void test_duplicatedModifier_external() {
    parseTestCodeWithDiagnostics(r'''
class C {
  external external f();
//         ^^^^^^^^
// [diag.duplicatedModifier] The modifier 'external' was already specified.
}
''');
  }

  void test_duplicatedModifier_factory() {
    parseTestCodeWithDiagnostics(r'''
class C {
  factory factory C() {}
//        ^^^^^^^
// [diag.duplicatedModifier] The modifier 'factory' was already specified.
}
''');
  }

  void test_duplicatedModifier_final() {
    parseTestCodeWithDiagnostics(r'''
class C {
  final final m = null;
//      ^^^^^
// [diag.duplicatedModifier] The modifier 'final' was already specified.
}
''');
  }

  void test_duplicatedModifier_static() {
    parseTestCodeWithDiagnostics(r'''
class C {
  static static var m;
//       ^^^^^^
// [diag.duplicatedModifier] The modifier 'static' was already specified.
}
''');
  }

  void test_duplicatedModifier_var() {
    parseTestCodeWithDiagnostics(r'''
class C {
  var var m;
//    ^^^
// [diag.duplicatedModifier] The modifier 'var' was already specified.
}
''');
  }

  void test_duplicateLabelInSwitchStatement() {
    parseTestCodeWithDiagnostics(r'''
void f() {
  switch (e) {l1: case 0: break; l1: case 1: break;}
//                               ^^
// [diag.duplicateLabelInSwitchStatement] The label 'l1' was already used in this switch statement.
}
''');
  }

  void test_emptyEnumBody() {
    parseTestCodeWithDiagnostics(r'''
enum E {}
''');
  }

  void test_emptyFunctionBody() {
    parseTestCodeWithDiagnostics(r'''
void f();
''');
  }

  void test_enumInClass() {
    parseTestCodeWithDiagnostics(r'''
class Foo {
  enum Bar {
//^^^^
// [diag.enumInClass] Enums can't be declared inside classes.
    Bar1, Bar2, Bar3
  }
}
''');
  }

  void test_equalityCannotBeEqualityOperand_eq_eq() {
    parseTestCodeWithDiagnostics(r'''
var v = 1 == 2 == 3;
//             ^^
// [diag.equalityCannotBeEqualityOperand] A comparison expression can't be an operand of another comparison expression.
''');
  }

  void test_equalityCannotBeEqualityOperand_eq_neq() {
    parseTestCodeWithDiagnostics(r'''
var v = 1 == 2 != 3;
//             ^^
// [diag.equalityCannotBeEqualityOperand] A comparison expression can't be an operand of another comparison expression.
''');
  }

  void test_equalityCannotBeEqualityOperand_neq_eq() {
    parseTestCodeWithDiagnostics(r'''
var v = 1 != 2 == 3;
//             ^^
// [diag.equalityCannotBeEqualityOperand] A comparison expression can't be an operand of another comparison expression.
''');
  }

  void test_expectedBody_class() {
    parseTestCodeWithDiagnostics(r'''
class A class B {}
//    ^
// [diag.expectedClassBody] A class declaration must have a body, even if it is empty.
''');
  }

  void test_expectedCaseOrDefault() {
    parseTestCodeWithDiagnostics(r'''
void f() {
  switch (e) {break;}
//            ^^^^^
// [diag.expectedToken] Expected to find 'case'.
}
''');
  }

  void test_expectedClassMember_inClass_afterType() {
    parseTestCodeWithDiagnostics(r'''
class C{ heart 2 heart }
//       ^^^^^
// [diag.missingConstFinalVarOrType] Variables must be declared using the keywords 'const', 'final', 'var' or a type name.
// [diag.expectedToken] Expected to find ';'.
//             ^
// [diag.expectedClassMember] Expected a class member.
//               ^^^^^
// [diag.missingConstFinalVarOrType] Variables must be declared using the keywords 'const', 'final', 'var' or a type name.
// [diag.expectedToken] Expected to find ';'.
''');
  }

  void test_expectedClassMember_inClass_beforeType() {
    parseTestCodeWithDiagnostics(r'''
class C { 4 score }
//        ^
// [diag.expectedClassMember] Expected a class member.
//          ^^^^^
// [diag.missingConstFinalVarOrType] Variables must be declared using the keywords 'const', 'final', 'var' or a type name.
// [diag.expectedToken] Expected to find ';'.
''');
  }

  void test_expectedExecutable_afterAnnotation_atEOF() {
    // TODO(brianwilkerson): Remove codes when highlighting is fixed.
    parseTestCodeWithDiagnostics(r'''
@A
//^
// [diag.expectedExecutable][column 3][length 0] Expected a method, getter, setter or operator declaration.
''');
  }

  void test_expectedExecutable_inClass_afterVoid() {
    parseTestCodeWithDiagnostics(r'''
class C { void 2 void }
//             ^
// [diag.missingIdentifier] Expected an identifier.
// [diag.expectedToken] Expected to find ';'.
//               ^^^^
// [diag.expectedToken] Expected to find ';'.
//                    ^
// [diag.missingIdentifier] Expected an identifier.
''');
  }

  void test_expectedExecutable_topLevel_afterType() {
    parseTestCodeWithDiagnostics(r'''
heart 2 heart
// [diag.missingConstFinalVarOrType][column 1][length 5] Variables must be declared using the keywords 'const', 'final', 'var' or a type name.
// [diag.expectedToken][column 1][length 5] Expected to find ';'.
//    ^
// [diag.expectedExecutable] Expected a method, getter, setter or operator declaration.
//      ^^^^^
// [diag.missingConstFinalVarOrType] Variables must be declared using the keywords 'const', 'final', 'var' or a type name.
// [diag.expectedToken] Expected to find ';'.
''');
  }

  void test_expectedExecutable_topLevel_afterVoid() {
    parseTestCodeWithDiagnostics(r'''
void 2 void
// [diag.expectedToken][column 1][length 4] Expected to find ';'.
//   ^
// [diag.missingIdentifier] Expected an identifier.
// [diag.expectedExecutable] Expected a method, getter, setter or operator declaration.
//     ^^^^
// [diag.expectedToken] Expected to find ';'.
//         ^
// [diag.missingIdentifier][column 12][length 0] Expected an identifier.
''');
  }

  void test_expectedExecutable_topLevel_beforeType() {
    parseTestCodeWithDiagnostics(r'''
4 score
// [diag.expectedExecutable][column 1][length 1] Expected a method, getter, setter or operator declaration.
//^^^^^
// [diag.missingConstFinalVarOrType] Variables must be declared using the keywords 'const', 'final', 'var' or a type name.
// [diag.expectedToken] Expected to find ';'.
''');
  }

  void test_expectedExecutable_topLevel_eof() {
    parseTestCodeWithDiagnostics(r'''
x
// [diag.missingConstFinalVarOrType][column 1][length 1] Variables must be declared using the keywords 'const', 'final', 'var' or a type name.
// [diag.expectedToken][column 1][length 1] Expected to find ';'.
''');
  }

  void test_expectedInterpolationIdentifier() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var s = '$x$';
//          ^
// [diag.missingIdentifier] Expected an identifier.
''');

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
    parseTestCodeWithDiagnostics(r'''
var s = '$$foo';
//        ^
// [diag.missingIdentifier] Expected an identifier.
''');
  }

  void test_expectedToken_commaMissingInArgumentList() {
    parseTestCodeWithDiagnostics(r'''
void f() {
  g(x, y z);
//       ^
// [diag.expectedToken] Expected to find ','.
}
''');
  }

  void test_expectedToken_parseStatement_afterVoid() {
    parseTestCodeWithDiagnostics(r'''
void f() {
  void}
//^^^^
// [diag.expectedToken] Expected to find ';'.
//    ^
// [diag.missingIdentifier] Expected an identifier.
}
// [diag.expectedExecutable][column 1][length 1] Expected a method, getter, setter or operator declaration.
''');
  }

  void test_expectedToken_semicolonMissingAfterExport() {
    var parseResult = parseTestCodeWithDiagnostics(r'''export '' class A {}
//     ^^
// [diag.expectedToken] Expected to find ';'.''');

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
    parseTestCodeWithDiagnostics(r'''
void f() {
  x
//^
// [diag.expectedToken] Expected to find ';'.
}
''');
  }

  void test_expectedToken_semicolonMissingAfterImport() {
    // TODO(brianwilkerson): Remove codes when highlighting is fixed.
    var parseResult = parseTestCodeWithDiagnostics(r'''
import '' class A {}
//     ^^
// [diag.expectedToken] Expected to find ';'.
''');

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
export class A {}
// [diag.expectedToken][column 1][length 6] Expected to find ';'.
//     ^^^^^
// [diag.expectedStringLiteral] Expected a string literal.
''');

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
    parseTestCodeWithDiagnostics(r'''
void f() {
  do {} (x);
//      ^
// [diag.expectedToken] Expected to find 'while'.
}
''');
  }

  void test_expectedTypeName_as() {
    parseTestCodeWithDiagnostics(r'''
var v = x as;
//          ^
// [diag.expectedTypeName] Expected a type name.
''');
  }

  void test_expectedTypeName_as_void() {
    parseTestCodeWithDiagnostics(r'''
var v = x as void;
//           ^^^^
// [diag.expectedTypeName] Expected a type name.
''');
  }

  void test_expectedTypeName_is() {
    parseTestCodeWithDiagnostics(r'''
var v = x is;
//          ^
// [diag.expectedTypeName] Expected a type name.
''');
  }

  void test_expectedTypeName_is_void() {
    parseTestCodeWithDiagnostics(r'''
var v = x is void;
//           ^^^^
// [diag.expectedTypeName] Expected a type name.
''');
  }

  void test_exportAsType() {
    parseTestCodeWithDiagnostics(r'''
export<dynamic> foo;
// [diag.builtInIdentifierAsType][column 1][length 6] The built-in identifier 'export' can't be used as a type.
''');
  }

  void test_exportAsType_inClass() {
    parseTestCodeWithDiagnostics(r'''
class C { export<dynamic> foo; }
//        ^^^^^^
// [diag.builtInIdentifierAsType] The built-in identifier 'export' can't be used as a type.
''');
  }

  void test_externalAfterConst() {
    parseTestCodeWithDiagnostics(r'''
class C {
  const external C();
//      ^^^^^^^^
// [diag.modifierOutOfOrder] The modifier 'external' should be before the modifier 'const'.
}
''');
  }

  void test_externalAfterFactory() {
    parseTestCodeWithDiagnostics(r'''
class C {
  factory external C() {}
//        ^^^^^^^^
// [diag.modifierOutOfOrder] The modifier 'external' should be before the modifier 'factory'.
}
''');
  }

  void test_externalAfterStatic() {
    parseTestCodeWithDiagnostics(r'''
class C {
  static external int m();
//       ^^^^^^^^
// [diag.modifierOutOfOrder] The modifier 'external' should be before the modifier 'static'.
}
''');
  }

  void test_externalClass() {
    parseTestCodeWithDiagnostics(r'''
external class C {}
// [diag.externalClass][column 1][length 8] Classes can't be declared to be 'external'.
''');
  }

  void test_externalEnum() {
    parseTestCodeWithDiagnostics(r'''
external enum E {ONE}
// [diag.externalEnum][column 1][length 8] Enums can't be declared to be 'external'.
''');
  }

  void test_externalField_const() {
    parseTestCodeWithDiagnostics(r'''
class C {
  external const A f;
}
''');
  }

  void test_externalField_final() {
    parseTestCodeWithDiagnostics(r'''
class C {
  external final A f;
}
''');
  }

  void test_externalField_static() {
    parseTestCodeWithDiagnostics(r'''
class C {
  external static A f;
}
''');
  }

  void test_externalField_typed() {
    parseTestCodeWithDiagnostics(r'''
class C {
  external A f;
}
''');
  }

  void test_externalField_untyped() {
    parseTestCodeWithDiagnostics(r'''
class C {
  external var f;
}
''');
  }

  void test_externalTypedef() {
    parseTestCodeWithDiagnostics(r'''
external typedef F();
// [diag.externalTypedef][column 1][length 8] Typedefs can't be declared to be 'external'.
''');
  }

  void test_extraCommaInParameterList() {
    parseTestCodeWithDiagnostics(r'''
void f(int a, , int b) {}
//            ^
// [diag.missingIdentifier] Expected an identifier.
''');
  }

  void test_extraCommaTrailingNamedParameterGroup() {
    parseTestCodeWithDiagnostics(r'''
void f({int b},) {}
//            ^
// [diag.expectedToken] Expected to find ')'.
''');
  }

  void test_extraCommaTrailingPositionalParameterGroup() {
    parseTestCodeWithDiagnostics(r'''
void f([int b],) {}
//            ^
// [diag.expectedToken] Expected to find ')'.
''');
  }

  void test_extraTrailingCommaInParameterList() {
    parseTestCodeWithDiagnostics(r'''
void f(a,,) {}
//       ^
// [diag.missingIdentifier] Expected an identifier.
''');
  }

  void test_factory_issue_36400() {
    parseTestCodeWithDiagnostics(r'''
class T { T factory T() { return null; } }
//        ^
// [diag.typeBeforeFactory] Factory constructors cannot have a return type.
''');
  }

  void test_factoryTopLevelDeclaration_class() {
    parseTestCodeWithDiagnostics(r'''
factory class C {}
// [diag.factoryTopLevelDeclaration][column 1][length 7] Top-level declarations can't be declared to be 'factory'.
''');
  }

  void test_factoryTopLevelDeclaration_enum() {
    parseTestCodeWithDiagnostics(r'''
factory enum E { v }
// [diag.factoryTopLevelDeclaration][column 1][length 7] Top-level declarations can't be declared to be 'factory'.
''');
  }

  void test_factoryTopLevelDeclaration_typedef() {
    parseTestCodeWithDiagnostics(r'''
factory typedef F();
// [diag.factoryTopLevelDeclaration][column 1][length 7] Top-level declarations can't be declared to be 'factory'.
''');
  }

  void test_factoryWithInitializers() {
    parseTestCodeWithDiagnostics(r'''
class C {
  factory C() : x = 3 {}
//            ^
// [diag.missingFunctionBody] A function body must be provided.
// [diag.expectedClassMember] Expected a class member.
//              ^
// [diag.missingConstFinalVarOrType] Variables must be declared using the keywords 'const', 'final', 'var' or a type name.
//                  ^
// [diag.expectedToken] Expected to find ';'.
//                    ^
// [diag.missingIdentifier] Expected an identifier.
// [diag.missingMethodParameters] Methods must have an explicit list of parameters.
}
''');
  }

  @failingTest // TODO(scheglov): fix it
  void test_factoryWithoutBody() {
    parseTestCodeWithDiagnostics(r'''
class C {
  factory C();
//           ^
// [diag.missingFunctionBody] A function body must be provided.
}
''');
  }

  void test_factoryWithoutBody_language305() {
    parseTestCodeWithDiagnostics(r'''
// @dart = 3.5
class C {
  factory C();
//           ^
// [diag.missingFunctionBody] A function body must be provided.
}
''');
  }

  void test_fieldInitializerOutsideConstructor() {
    parseTestCodeWithDiagnostics(r'''
class C {
  void m(this.x);
}
''');
  }

  void test_finalAndCovariant() {
    parseTestCodeWithDiagnostics(r'''
class C {
  final covariant f = null;
//      ^^^^^^^^^
// [diag.modifierOutOfOrder] The modifier 'covariant' should be before the modifier 'final'.
// [diag.finalAndCovariant] Members can't be declared to be both 'final' and 'covariant'.
}
''');
  }

  void test_finalAndVar() {
    parseTestCodeWithDiagnostics(r'''
class C {
  final var x = null;
//      ^^^
// [diag.finalAndVar] Members can't be declared to be both 'final' and 'var'.
}
''');
  }

  void test_finalClassMember_modifierOnly() {
    parseTestCodeWithDiagnostics(r'''
class C {
  final
//^^^^^
// [diag.expectedToken] Expected to find ';'.
}
// [diag.missingIdentifier][column 1][length 1] Expected an identifier.
''');
  }

  void test_finalConstructor() {
    parseTestCodeWithDiagnostics(r'''
class C {
  final C() {}
//^^^^^
// [diag.extraneousModifier] Can't have modifier 'final' here.
}
''');
  }

  void test_finalEnum() {
    parseTestCodeWithDiagnostics(r'''
final enum E {ONE}
// [diag.finalEnum][column 1][length 5] Enums can't be declared to be 'final'.
''');
  }

  void test_finalMethod() {
    parseTestCodeWithDiagnostics(r'''
class C {
  final int m() {}
//^^^^^
// [diag.extraneousModifier] Can't have modifier 'final' here.
}
''');
  }

  void test_finalTypedef() {
    // Fasta interprets the `final` as a malformed top level final
    // and `typedef` as the start of an typedef declaration.
    parseTestCodeWithDiagnostics(r'''
final typedef F();
// [diag.expectedToken][column 1][length 5] Expected to find ';'.
//    ^^^^^^^
// [diag.missingIdentifier] Expected an identifier.
''');
  }

  void test_functionTypedField_invalidType_abstract() {
    parseTestCodeWithDiagnostics(r'''
Function(abstract) x = null;
//       ^^^^^^^^
// [diag.builtInIdentifierAsType] The built-in identifier 'abstract' can't be used as a type.
''');
  }

  void test_functionTypedField_invalidType_class() {
    parseTestCodeWithDiagnostics(r'''
Function(class) x = null;
//       ^^^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedIdentifierButGotKeyword] 'class' can't be used as an identifier because it's a keyword.
''');
  }

  void test_functionTypedParameter_const() {
    parseTestCodeWithDiagnostics(r'''
void f(const x()) {}
//     ^^^^^
// [diag.extraneousModifier] Can't have modifier 'const' here.
// [diag.functionTypedParameterVar] Function-typed parameters can't specify 'const', 'final' or 'var' in place of a return type.
''');
  }

  void test_functionTypedParameter_final() {
    parseTestCodeWithDiagnostics(r'''
void f(final x()) {}
//     ^^^^^
// [diag.functionTypedParameterVar] Function-typed parameters can't specify 'const', 'final' or 'var' in place of a return type.
// [diag.extraneousModifier] Can't have modifier 'final' here.
''');
  }

  void test_functionTypedParameter_incomplete1() {
    parseTestCodeWithDiagnostics(r'''
void f(int Function(
//                  ^
// [diag.missingFunctionBody][column 21][length 0] A function body must be provided.
// [diag.expectedToken][column 21][length 1] Expected to find ')'.
''');
  }

  void test_functionTypedParameter_var() {
    parseTestCodeWithDiagnostics(r'''
void f(var x()) {}
//     ^^^
// [diag.functionTypedParameterVar] Function-typed parameters can't specify 'const', 'final' or 'var' in place of a return type.
// [diag.extraneousModifier] Can't have modifier 'var' here.
''');
  }

  void test_genericFunctionType_asIdentifier() {
    parseTestCodeWithDiagnostics(r'''
final int Function = 0;
''');
  }

  void test_genericFunctionType_asIdentifier2() {
    parseTestCodeWithDiagnostics(r'''
int Function() {}
''');
  }

  void test_genericFunctionType_asIdentifier3() {
    parseTestCodeWithDiagnostics(r'''
int Function() => 0;
''');
  }

  void test_genericFunctionType_extraLessThan() {
    parseTestCodeWithDiagnostics(r'''
class Wrong<T> {
  T Function(<List<int> foo) bar;
//           ^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedToken] Expected to find ')'.
}
''');
  }

  void test_getterInFunction_block_noReturnType() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  get x { return _x; }
//^^^
// [diag.expectedToken] Expected to find ';'.
//    ^
// [diag.expectedToken] Expected to find ';'.
}
''');

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
    parseTestCodeWithDiagnostics(r'''
void f() {
  int get x { return _x; }
//    ^^^
// [diag.expectedToken] Expected to find ';'.
//        ^
// [diag.expectedToken] Expected to find ';'.
}
''');
  }

  void test_getterInFunction_expression_noReturnType() {
    parseTestCodeWithDiagnostics(r'''
void f() {
  get x => _x;
//^^^
// [diag.expectedToken] Expected to find ';'.
//      ^^
// [diag.missingFunctionParameters] Functions must have an explicit list of parameters.
}
''');
  }

  void test_getterInFunction_expression_returnType() {
    parseTestCodeWithDiagnostics(r'''
void f() {
  int get x => _x;
//    ^^^
// [diag.expectedToken] Expected to find ';'.
//          ^^
// [diag.missingFunctionParameters] Functions must have an explicit list of parameters.
}
''');
  }

  void test_getterNativeWithBody() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  String get m native "str" => 0;
}
''');

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
    parseTestCodeWithDiagnostics(r'''
class C {
  int get x() {}
//         ^
// [diag.getterWithParameters] Getters must be declared without a parameter list.
}
''');
  }

  void test_illegalAssignmentToNonAssignable_assign_int() {
    parseTestCodeWithDiagnostics(r'''
void f() {
  0 = 1;
//^
// [diag.missingAssignableSelector] Missing selector such as '.identifier' or '[0]'.
// [diag.illegalAssignmentToNonAssignable] Illegal assignment to non-assignable expression.
}
''');
  }

  void test_illegalAssignmentToNonAssignable_assign_this() {
    parseTestCodeWithDiagnostics(r'''
void f() {
  this = 1;
//^^^^
// [diag.missingAssignableSelector] Missing selector such as '.identifier' or '[0]'.
// [diag.illegalAssignmentToNonAssignable] Illegal assignment to non-assignable expression.
}
''');
  }

  void test_illegalAssignmentToNonAssignable_postfix_minusMinus_literal() {
    parseTestCodeWithDiagnostics(r'''
var v = 0--;
//       ^^
// [diag.illegalAssignmentToNonAssignable] Illegal assignment to non-assignable expression.
''');
  }

  void test_illegalAssignmentToNonAssignable_postfix_plusPlus_literal() {
    parseTestCodeWithDiagnostics(r'''
var v = 0++;
//       ^^
// [diag.illegalAssignmentToNonAssignable] Illegal assignment to non-assignable expression.
''');
  }

  void test_illegalAssignmentToNonAssignable_postfix_plusPlus_parenthesized() {
    parseTestCodeWithDiagnostics(r'''
var v = (x)++;
//         ^^
// [diag.illegalAssignmentToNonAssignable] Illegal assignment to non-assignable expression.
''');
  }

  void test_illegalAssignmentToNonAssignable_primarySelectorPostfix() {
    parseTestCodeWithDiagnostics(r'''
var v = x(y)(z)++;
//             ^^
// [diag.illegalAssignmentToNonAssignable] Illegal assignment to non-assignable expression.
''');
  }

  void test_illegalAssignmentToNonAssignable_superAssigned() {
    parseTestCodeWithDiagnostics(r'''
void f() {
  super = x;
//^^^^^
// [diag.missingAssignableSelector] Missing selector such as '.identifier' or '[0]'.
// [diag.illegalAssignmentToNonAssignable] Illegal assignment to non-assignable expression.
}
''');
  }

  void test_implementsBeforeExtends() {
    parseTestCodeWithDiagnostics(r'''
class A implements B extends C {}
//                   ^^^^^^^
// [diag.implementsBeforeExtends] The extends clause must be before the implements clause.
''');
  }

  void test_implementsBeforeWith() {
    parseTestCodeWithDiagnostics(r'''
class A extends B implements C with D {}
//                             ^^^^
// [diag.implementsBeforeWith] The with clause must be before the implements clause.
''');
  }

  void test_initializedVariableInForEach() {
    parseTestCodeWithDiagnostics(r'''
void f() {
  for (int a = 0 in foo) {}
//           ^
// [diag.initializedVariableInForEach] The loop variable in a for-each loop can't be initialized.
}
''');
  }

  void test_initializedVariableInForEach_annotation() {
    parseTestCodeWithDiagnostics(r'''
void f() {
  for (@Foo var a = 0 in foo) {}
//                ^
// [diag.initializedVariableInForEach] The loop variable in a for-each loop can't be initialized.
}
''');
  }

  void test_initializedVariableInForEach_localFunction() {
    parseTestCodeWithDiagnostics(r'''
void f() {
  for (f()) {}
//       ^
// [diag.expectedToken] Expected to find ';'.
//        ^
// [diag.missingIdentifier] Expected an identifier.
}
''');
  }

  void test_initializedVariableInForEach_localFunction2() {
    parseTestCodeWithDiagnostics(r'''
void f() {
  for (T f()) {}
//       ^
// [diag.expectedToken] Expected to find ';'.
//         ^
// [diag.expectedToken] Expected to find ';'.
}
''');
  }

  void test_initializedVariableInForEach_var() {
    parseTestCodeWithDiagnostics(r'''
void f() {
  for (var a = 0 in foo) {}
//           ^
// [diag.initializedVariableInForEach] The loop variable in a for-each loop can't be initialized.
}
''');
  }

  void test_invalidAwaitInFor() {
    parseTestCodeWithDiagnostics(r'''
void f() {
  await for (; ;) {}
//^^^^^
// [diag.invalidAwaitInFor] The keyword 'await' isn't allowed for a normal 'for' statement.
}
''');
  }

  void test_invalidCodePoint() {
    parseTestCodeWithDiagnostics(r'''
var s = 'begin \u{110000}';
//             ^^^^^^^^^
// [diag.invalidCodePoint] The escape sequence '\u{...}' isn't a valid code point.
''');
  }

  @failingTest // TODO(scheglov): fix it
  void test_invalidCommentReference__new_nonIdentifier() {
    parseTestCodeWithDiagnostics(r'''
/// [new 42]
//       ^^^
// [diag.invalidCommentReference] Comment references should contain a possibly prefixed identifier and can start with 'new', but shouldn't contain anything else.
void f() {}
''');
  }

  @failingTest // TODO(scheglov): fix it
  void test_invalidCommentReference__new_tooMuch() {
    parseTestCodeWithDiagnostics(r'''
/// [new a.b.c.d]
//       ^^^^^^^
// [diag.invalidCommentReference] Comment references should contain a possibly prefixed identifier and can start with 'new', but shouldn't contain anything else.
void f() {}
''');
  }

  @failingTest // TODO(scheglov): fix it
  void test_invalidCommentReference__nonNew_nonIdentifier() {
    parseTestCodeWithDiagnostics(r'''
/// [42]
//   ^^
// [diag.invalidCommentReference] Comment references should contain a possibly prefixed identifier and can start with 'new', but shouldn't contain anything else.
void f() {}
''');
  }

  @failingTest // TODO(scheglov): fix it
  void test_invalidCommentReference__nonNew_tooMuch() {
    parseTestCodeWithDiagnostics(r'''
/// [a.b.c.d]
//   ^^^^^^^
// [diag.invalidCommentReference] Comment references should contain a possibly prefixed identifier and can start with 'new', but shouldn't contain anything else.
void f() {}
''');
  }

  void test_invalidConstructorName_star() {
    parseTestCodeWithDiagnostics(r'''
class C {
  C.*();
//  ^
// [diag.missingIdentifier] Expected an identifier.
}
''');
  }

  void test_invalidConstructorName_with() {
    parseTestCodeWithDiagnostics(r'''
class C {
  C.with();
//  ^^^^
// [diag.expectedIdentifierButGotKeyword] 'with' can't be used as an identifier because it's a keyword.
}
''');
  }

  void test_invalidConstructorSuperAssignment() {
    parseTestCodeWithDiagnostics(r'''
class C {
  C() : super = 42;
//      ^^^^^
// [diag.missingAssignableSelector] Missing selector such as '.identifier' or '[0]'.
//      ^^^^^^^^^^
// [diag.invalidInitializer] Not a valid initializer.
}
''');
  }

  void test_invalidConstructorSuperFieldAssignment() {
    parseTestCodeWithDiagnostics(r'''
class C {
  C() : super.a = 42;
//            ^
// [diag.fieldInitializedOutsideDeclaringClass] A field can only be initialized in its declaring class
}
''');
  }

  void test_invalidHexEscape_invalidDigit() {
    parseTestCodeWithDiagnostics(r'''
var s = 'not \x0 a';
//           ^^^
// [diag.invalidHexEscape] An escape sequence starting with '\x' must be followed by 2 hexadecimal digits.
''');
  }

  void test_invalidHexEscape_tooFewDigits() {
    parseTestCodeWithDiagnostics(r'''
var s = '\x0';
//       ^^^
// [diag.invalidHexEscape] An escape sequence starting with '\x' must be followed by 2 hexadecimal digits.
''');
  }

  void test_invalidInlineFunctionType() {
    parseTestCodeWithDiagnostics(r'''
typedef F = int Function(int a());
//                            ^
// [diag.invalidInlineFunctionType] Inline function types can't be used for parameters in a generic function type.
''');
  }

  void test_invalidInterpolation_missingClosingBrace_issue35900() {
    parseTestCodeWithDiagnostics(r'''
main () { print('${x' '); }
//                  ^^^
// [diag.expectedToken] Expected to find '}'.
//                     ^
// [diag.expectedStringLiteral] Expected a string literal.
// [diag.expectedToken] Expected to find '}'.
//                        ^
// [diag.unterminatedStringLiteral] Unterminated string literal.
//                         ^
// [diag.expectedExecutable][column 28][length 0] Expected a method, getter, setter or operator declaration.
''');
  }

  void test_invalidInterpolationIdentifier_startWithDigit() {
    parseTestCodeWithDiagnostics(r'''
var s = '$1';
//        ^
// [diag.missingIdentifier] Expected an identifier.
''');
  }

  void test_invalidLiteralInConfiguration() {
    parseTestCodeWithDiagnostics(r'''
import 'a.dart' if (a == 'x $y z') 'a.dart';
//                          ^^
// [diag.invalidLiteralInConfiguration] The literal in a configuration can't contain interpolation.
''');
  }

  void test_invalidOperator() {
    parseTestCodeWithDiagnostics(r'''
class C { void operator ===(x) { } }
//                      ^
// [diag.unsupportedOperator] The '===' operator is not supported.
''');
  }

  void test_invalidOperator_unary() {
    parseTestCodeWithDiagnostics(r'''
class C { int operator unary- => 0; }
//                     ^^^^^
// [diag.unexpectedToken] Unexpected text 'unary'.
//                          ^
// [diag.missingMethodParameters] Methods must have an explicit list of parameters.
''');
  }

  void test_invalidOperatorAfterSuper_assignableExpression() {
    // TODO(brianwilkerson): Convert codes to errors when highlighting is fixed.
    parseTestCodeWithDiagnostics(r'''
void f() {
  super?.v = 0;
//     ^^
// [diag.invalidOperatorQuestionmarkPeriodForSuper] The operator '?.' cannot be used with 'super' because 'super' cannot be null.
}
''');
  }

  void test_invalidOperatorAfterSuper_constructorInitializer2() {
    parseTestCodeWithDiagnostics(r'''
class C { C() : super?.namedConstructor(); }
//                   ^^
// [diag.invalidOperatorQuestionmarkPeriodForSuper] The operator '?.' cannot be used with 'super' because 'super' cannot be null.
''');
  }

  void test_invalidOperatorAfterSuper_primaryExpression() {
    parseTestCodeWithDiagnostics(r'''
void f() {
  super?.v;
//     ^^
// [diag.invalidOperatorQuestionmarkPeriodForSuper] The operator '?.' cannot be used with 'super' because 'super' cannot be null.
}
''');
  }

  void test_invalidOperatorForSuper() {
    parseTestCodeWithDiagnostics(r'''
void f() {
  ++super;
//  ^^^^^
// [diag.missingAssignableSelector] Missing selector such as '.identifier' or '[0]'.
}
''');
  }

  void test_invalidPropertyAccess_this() {
    parseTestCodeWithDiagnostics(r'''
var v = x.this;
//        ^^^^
// [diag.missingIdentifier] Expected an identifier.
''');
  }

  void test_invalidStarAfterAsync() {
    parseTestCodeWithDiagnostics(r'''
foo() async* => 0;
//           ^^
// [diag.returnInGenerator] Can't return a value from a generator function that uses the 'async*' or 'sync*' modifier.
''');
  }

  void test_invalidSync() {
    parseTestCodeWithDiagnostics(r'''
foo() sync* => 0;
//          ^^
// [diag.returnInGenerator] Can't return a value from a generator function that uses the 'async*' or 'sync*' modifier.
''');
  }

  void test_invalidTopLevelSetter() {
    parseTestCodeWithDiagnostics(r'''
var set foo; main(){}
// [diag.varReturnType][column 1][length 3] The return type can't be 'var'.
//      ^^^
// [diag.missingFunctionParameters] Functions must have an explicit list of parameters.
''');
  }

  void test_invalidTopLevelVar() {
    parseTestCodeWithDiagnostics(r'''
var Function(var arg);
// [diag.varReturnType][column 1][length 3] The return type can't be 'var'.
//           ^^^
// [diag.extraneousModifier] Can't have modifier 'var' here.
''');
  }

  void test_invalidTypedef() {
    parseTestCodeWithDiagnostics(r'''
typedef var Function(var arg);
// [diag.expectedToken][column 1][length 7] Expected to find ';'.
//      ^^^
// [diag.missingIdentifier] Expected an identifier.
// [diag.missingTypedefParameters] Typedefs must have an explicit list of parameters.
// [diag.varReturnType] The return type can't be 'var'.
//                   ^^^
// [diag.extraneousModifier] Can't have modifier 'var' here.
''');
  }

  void test_invalidTypedef2() {
    // https://github.com/dart-lang/sdk/issues/31171
    parseTestCodeWithDiagnostics(r'''
typedef T = typedef F = Map<String, dynamic> Function();
//        ^
// [diag.expectedToken] Expected to find ';'.
//          ^^^^^^^
// [diag.expectedTypeName] Expected a type name.
''');
  }

  void test_invalidUnicodeEscape_incomplete_noDigits() {
    parseTestCodeWithDiagnostics(r'''
var s = '\u{';
//       ^^^
// [diag.invalidUnicodeEscapeUBracket] An escape sequence starting with '\u{' must be followed by 1 to 6 hexadecimal digits followed by a '}'.
''');
  }

  void test_invalidUnicodeEscape_incomplete_noDigits_noBracket() {
    parseTestCodeWithDiagnostics(r'''
var s = '\u';
//       ^^
// [diag.invalidUnicodeEscapeUStarted] An escape sequence starting with '\u' must be followed by 4 hexadecimal digits or from 1 to 6 digits between '{' and '}'.
''');
  }

  void test_invalidUnicodeEscape_incomplete_someDigits() {
    parseTestCodeWithDiagnostics(r'''
var s = '\u{0A';
//       ^^^^^
// [diag.invalidUnicodeEscapeUBracket] An escape sequence starting with '\u{' must be followed by 1 to 6 hexadecimal digits followed by a '}'.
''');
  }

  void test_invalidUnicodeEscape_invalidDigit() {
    parseTestCodeWithDiagnostics(r'''
var s = '\u0 and some more';
//       ^^^
// [diag.invalidUnicodeEscapeUNoBracket] An escape sequence starting with '\u' must be followed by 4 hexadecimal digits.
''');
  }

  void test_invalidUnicodeEscape_too_high_number_variable() {
    parseTestCodeWithDiagnostics(r'''
var s = '\u{110000}';
//       ^^^^^^^^^
// [diag.invalidCodePoint] The escape sequence '\u{...}' isn't a valid code point.
''');
  }

  void test_invalidUnicodeEscape_tooFewDigits_fixed() {
    parseTestCodeWithDiagnostics(r'''
var s = '\u04';
//       ^^^^
// [diag.invalidUnicodeEscapeUNoBracket] An escape sequence starting with '\u' must be followed by 4 hexadecimal digits.
''');
  }

  void test_invalidUnicodeEscape_tooFewDigits_variable() {
    parseTestCodeWithDiagnostics(r'''
var s = '\u{}';
//       ^^^^
// [diag.invalidUnicodeEscapeUBracket] An escape sequence starting with '\u{' must be followed by 1 to 6 hexadecimal digits followed by a '}'.
''');
  }

  void test_invalidUnicodeEscape_tooManyDigits_variable() {
    parseTestCodeWithDiagnostics(r'''
var s = '\u{0000000001}';
//       ^^^^^^^^^
// [diag.invalidUnicodeEscapeUBracket] An escape sequence starting with '\u{' must be followed by 1 to 6 hexadecimal digits followed by a '}'.
''');
  }

  void test_libraryDirectiveNotFirst() {
    parseTestCodeWithDiagnostics(r'''
import 'x.dart'; library l;
//               ^^^^^^^
// [diag.libraryDirectiveNotFirst] The library directive must appear before all other directives.
''');
  }

  void test_libraryDirectiveNotFirst_afterPart() {
    parseTestCodeWithDiagnostics(r'''
part 'a.dart';
library l;
// [diag.libraryDirectiveNotFirst][column 1][length 7] The library directive must appear before all other directives.
''');
  }

  void test_localFunction_annotation() {
    var result = parseTestCodeWithDiagnostics(r'''
class C { m() { @Foo f() {} } }
''');

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
    parseTestCodeWithDiagnostics(r'''
class C { m() { abstract f() {} } }
//              ^^^^^^^^
// [diag.extraneousModifier] Can't have modifier 'abstract' here.
''');
  }

  void test_localFunctionDeclarationModifier_external() {
    parseTestCodeWithDiagnostics(r'''
class C { m() { external f() {} } }
//              ^^^^^^^^
// [diag.extraneousModifier] Can't have modifier 'external' here.
''');
  }

  void test_localFunctionDeclarationModifier_factory() {
    parseTestCodeWithDiagnostics(r'''
class C { m() { factory f() {} } }
//              ^^^^^^^
// [diag.expectedToken] Expected to find ';'.
''');
  }

  void test_localFunctionDeclarationModifier_static() {
    parseTestCodeWithDiagnostics(r'''
class C { m() { static f() {} } }
//              ^^^^^^
// [diag.extraneousModifier] Can't have modifier 'static' here.
''');
  }

  void test_method_invalidTypeParameterExtends() {
    // Regression test for https://github.com/dart-lang/sdk/issues/25739.

    // TODO(jmesserly): ideally we'd be better at parser recovery here.
    var result = parseTestCodeWithDiagnostics(r'''
class C {
  f<E>(E extends num p);
//       ^^^^^^^
// [diag.expectedToken] Expected to find ')'.
}
''');

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
    parameter: RegularFormalParameter
      name: E
    rightParenthesis: )
  body: EmptyFunctionBody
    semicolon: ;
''');
  }

  void test_method_invalidTypeParameters() {
    var result = parseTestCodeWithDiagnostics(r'''
class C {
  void m<E, hello!>() {}
//          ^^^^^
// [diag.expectedToken] Expected to find '>'.
}
''');

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
    parseTestCodeWithDiagnostics(r'''
void f() {
  x.y = y;
}
''');
  }

  void test_missingAssignableSelector_prefix_minusMinus_literal() {
    parseTestCodeWithDiagnostics(r'''
var v = --0;
//        ^
// [diag.missingAssignableSelector] Missing selector such as '.identifier' or '[0]'.
''');
  }

  void test_missingAssignableSelector_prefix_plusPlus_literal() {
    parseTestCodeWithDiagnostics(r'''
var v = ++0;
//        ^
// [diag.missingAssignableSelector] Missing selector such as '.identifier' or '[0]'.
''');
  }

  void test_missingAssignableSelector_selector() {
    parseTestCodeWithDiagnostics(r'''
var v = x(y)(z).a++;
''');
  }

  void test_missingAssignableSelector_superAsExpressionFunctionBody() {
    var result = parseTestCodeWithDiagnostics(r'''
main() => super;
//        ^^^^^
// [diag.missingAssignableSelector] Missing selector such as '.identifier' or '[0]'.
''');

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
    var result = parseTestCodeWithDiagnostics(r'''
main() {super;}
//      ^^^^^
// [diag.missingAssignableSelector] Missing selector such as '.identifier' or '[0]'.
''');

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
    parseTestCodeWithDiagnostics(r'''
void f() {
  super.x = x;
}
''');
  }

  void test_missingCatchOrFinally() {
    parseTestCodeWithDiagnostics(r'''
void f() {
  try {}
//^^^
// [diag.missingCatchOrFinally] A try block must be followed by an 'on', 'catch', or 'finally' clause.
}
''');
  }

  void test_missingClosingParenthesis() {
    parseTestCodeWithDiagnostics(r'''
void f(int a, int b ;
//                  ^
// [diag.expectedToken] Expected to find ')'.
''');
  }

  void test_missingConstFinalVarOrType_static() {
    parseTestCodeWithDiagnostics(r'''
class A { static f; }
//               ^
// [diag.missingConstFinalVarOrType] Variables must be declared using the keywords 'const', 'final', 'var' or a type name.
''');
  }

  void test_missingConstFinalVarOrType_topLevel() {
    parseTestCodeWithDiagnostics(r'''
a;
// [diag.missingConstFinalVarOrType][column 1][length 1] Variables must be declared using the keywords 'const', 'final', 'var' or a type name.
''');
  }

  void test_missingEnumComma() {
    parseTestCodeWithDiagnostics(r'''
enum E {one two}
//          ^^^
// [diag.expectedToken] Expected to find ','.
''');
  }

  void test_missingExpressionInThrow() {
    parseTestCodeWithDiagnostics(r'''
void f() {
  throw;
//     ^
// [diag.missingExpressionInThrow] Missing expression after 'throw'.
}
''');
  }

  void test_missingFunctionBody_invalid() {
    parseTestCodeWithDiagnostics(r'''
void f() return 0;
//       ^^^^^^
// [diag.missingFunctionBody] A function body must be provided.
''');
  }

  void test_missingFunctionParameters_local_nonVoid_block() {
    // The parser does not recognize this as a function declaration, so it tries
    // to parse it as an expression statement. It isn't clear what the best
    // error message is in this case.
    parseTestCodeWithDiagnostics(r'''
void f() {
  int f { return x;}
//    ^
// [diag.expectedToken] Expected to find ';'.
}
''');
  }

  void test_missingFunctionParameters_local_nonVoid_expression() {
    // The parser does not recognize this as a function declaration, so it tries
    // to parse it as an expression statement. It isn't clear what the best
    // error message is in this case.
    parseTestCodeWithDiagnostics(r'''
void f() {
  int f => x;
//      ^^
// [diag.missingFunctionParameters] Functions must have an explicit list of parameters.
}
''');
  }

  void test_missingFunctionParameters_local_void_block() {
    parseTestCodeWithDiagnostics(r'''
void f() {
  void f { return x;}
//     ^
// [diag.expectedToken] Expected to find ';'.
}
''');
  }

  void test_missingFunctionParameters_local_void_expression() {
    parseTestCodeWithDiagnostics(r'''
void f() {
  void f => x;
//       ^^
// [diag.missingFunctionParameters] Functions must have an explicit list of parameters.
}
''');
  }

  void test_missingFunctionParameters_topLevel_nonVoid_block() {
    parseTestCodeWithDiagnostics(r'''
int f { return x;}
//  ^
// [diag.missingFunctionParameters] Functions must have an explicit list of parameters.
''');
  }

  void test_missingFunctionParameters_topLevel_nonVoid_expression() {
    parseTestCodeWithDiagnostics(r'''
int f => x;
//  ^
// [diag.missingFunctionParameters] Functions must have an explicit list of parameters.
''');
  }

  void test_missingFunctionParameters_topLevel_void_block() {
    var result = parseTestCodeWithDiagnostics(r'''
void f { return x;}
//   ^
// [diag.missingFunctionParameters] Functions must have an explicit list of parameters.
''');

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
    var result = parseTestCodeWithDiagnostics(r'''
void f => x;
//   ^
// [diag.missingFunctionParameters] Functions must have an explicit list of parameters.
''');

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
    parseTestCodeWithDiagnostics(r'''
var a = 1 *;
//         ^
// [diag.missingIdentifier] Expected an identifier.
''');
  }

  void test_missingIdentifier_beforeClosingCurly() {
    parseTestCodeWithDiagnostics(r'''
class C {
  int
//^^^
// [diag.missingConstFinalVarOrType] Variables must be declared using the keywords 'const', 'final', 'var' or a type name.
// [diag.expectedToken] Expected to find ';'.
}
''');
  }

  void test_missingIdentifier_inEnum() {
    parseTestCodeWithDiagnostics(r'''
enum E {, TWO}
//      ^
// [diag.missingIdentifier] Expected an identifier.
''');
  }

  void test_missingIdentifier_inParameterGroupNamed() {
    parseTestCodeWithDiagnostics(r'''
void f(a, {}) {}
//         ^
// [diag.missingIdentifier] Expected an identifier.
''');
  }

  void test_missingIdentifier_inParameterGroupOptional() {
    parseTestCodeWithDiagnostics(r'''
void f(a, []) {}
//         ^
// [diag.missingIdentifier] Expected an identifier.
''');
  }

  void test_missingIdentifier_inSymbol_afterPeriod() {
    parseTestCodeWithDiagnostics(r'''
var s = #a.;
//         ^
// [diag.missingIdentifier] Expected an identifier.
''');
  }

  void test_missingIdentifier_inSymbol_first() {
    parseTestCodeWithDiagnostics(r'''
var s = #;
//       ^
// [diag.missingIdentifier] Expected an identifier.
''');
  }

  void test_missingIdentifierForParameterGroup() {
    parseTestCodeWithDiagnostics(r'''
void f(,) {}
//     ^
// [diag.missingIdentifier] Expected an identifier.
''');
  }

  void test_missingKeywordOperator() {
    parseTestCodeWithDiagnostics(r'''
class C {
  +(x) {}
//^
// [diag.missingKeywordOperator] Operator declarations must be preceded by the keyword 'operator'.
}
''');
  }

  void test_missingKeywordOperator_parseClassMember() {
    parseTestCodeWithDiagnostics(r'''
class C {
  +() {}
//^
// [diag.missingKeywordOperator] Operator declarations must be preceded by the keyword 'operator'.
}
''');
  }

  void test_missingKeywordOperator_parseClassMember_afterTypeName() {
    parseTestCodeWithDiagnostics(r'''
class C {
  int +() {}
//    ^
// [diag.missingKeywordOperator] Operator declarations must be preceded by the keyword 'operator'.
}
''');
  }

  void test_missingKeywordOperator_parseClassMember_afterVoid() {
    parseTestCodeWithDiagnostics(r'''
class C {
  void +() {}
//     ^
// [diag.missingKeywordOperator] Operator declarations must be preceded by the keyword 'operator'.
}
''');
  }

  void test_missingMethodParameters_void_block() {
    var result = parseTestCodeWithDiagnostics(r'''
class C {
  void m {}
//     ^
// [diag.missingMethodParameters] Methods must have an explicit list of parameters.
}
''');

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
    parseTestCodeWithDiagnostics(r'''
class C {
  void m => null;
//     ^
// [diag.missingMethodParameters] Methods must have an explicit list of parameters.
}
''');
  }

  void test_missingNameForNamedParameter_colon() {
    var result = parseTestCodeWithDiagnostics(r'''
typedef F = void Function({int : 0});
//                             ^
// [diag.missingIdentifier] Expected an identifier.
// [diag.defaultValueInFunctionType] Parameters in a function type can't have default values.
''');

    var parameter = result.findNode.singleFormalParameterList;
    assertParsedNodeText(parameter, r'''
FormalParameterList
  leftParenthesis: (
  leftDelimiter: {
  parameter: RegularFormalParameter
    type: NamedType
      name: int
    name: <empty> <synthetic>
    defaultClause: FormalParameterDefaultClause
      separator: :
      value: IntegerLiteral
        literal: 0
  rightDelimiter: }
  rightParenthesis: )
''');
  }

  void test_missingNameForNamedParameter_equals() {
    var result = parseTestCodeWithDiagnostics(r'''
typedef F = void Function({int = 0});
//                             ^
// [diag.missingIdentifier] Expected an identifier.
// [diag.defaultValueInFunctionType] Parameters in a function type can't have default values.
''');

    var parameter = result.findNode.singleFormalParameterList;
    assertParsedNodeText(parameter, r'''
FormalParameterList
  leftParenthesis: (
  leftDelimiter: {
  parameter: RegularFormalParameter
    type: NamedType
      name: int
    name: <empty> <synthetic>
    defaultClause: FormalParameterDefaultClause
      separator: =
      value: IntegerLiteral
        literal: 0
  rightDelimiter: }
  rightParenthesis: )
''');
  }

  void test_missingNameForNamedParameter_noDefault() {
    var result = parseTestCodeWithDiagnostics(r'''
typedef F = void Function({int});
//                            ^
// [diag.missingIdentifier] Expected an identifier.
''');

    var parameter = result.findNode.singleFormalParameterList;
    assertParsedNodeText(parameter, r'''
FormalParameterList
  leftParenthesis: (
  leftDelimiter: {
  parameter: RegularFormalParameter
    type: NamedType
      name: int
    name: <empty> <synthetic>
  rightDelimiter: }
  rightParenthesis: )
''');
  }

  void test_missingNameInPartOfDirective() {
    parseTestCodeWithDiagnostics(r'''
part of;
//     ^
// [diag.expectedStringLiteral] Expected a string literal.
''');
  }

  void test_missingPrefixInDeferredImport() {
    parseTestCodeWithDiagnostics(r'''
import 'foo.dart' deferred;
//                ^^^^^^^^
// [diag.missingPrefixInDeferredImport] Deferred imports should have a prefix.
''');
  }

  void test_missingStartAfterSync() {
    parseTestCodeWithDiagnostics(r'''
main() sync {}
//     ^^^^
// [diag.missingStarAfterSync] The modifier 'sync' must be followed by a star ('*').
''');
  }

  void test_missingStatement() {
    parseTestCodeWithDiagnostics(r'''
void f() {
  is
//^^
// [diag.missingIdentifier] Expected an identifier.
// [diag.expectedToken] Expected to find ';'.
}
// [diag.expectedTypeName][column 1][length 1] Expected a type name.
''');
  }

  void test_missingStatement_afterVoid() {
    parseTestCodeWithDiagnostics(r'''
void f() {
  void;
//    ^
// [diag.missingIdentifier] Expected an identifier.
}
''');
  }

  void test_missingTerminatorForParameterGroup_named() {
    parseTestCodeWithDiagnostics(r'''
void f(a, {b: 0) {}
//             ^
// [diag.expectedToken] Expected to find '}'.
''');
  }

  void test_missingTerminatorForParameterGroup_optional() {
    parseTestCodeWithDiagnostics(r'''
void f(a, [b = 0) {}
//              ^
// [diag.expectedToken] Expected to find ']'.
''');
  }

  void test_missingTypedefParameters_nonVoid() {
    parseTestCodeWithDiagnostics(r'''
typedef int F;
//           ^
// [diag.missingTypedefParameters] Typedefs must have an explicit list of parameters.
''');
  }

  void test_missingTypedefParameters_typeParameters() {
    parseTestCodeWithDiagnostics(r'''
typedef F<E>;
//          ^
// [diag.missingTypedefParameters] Typedefs must have an explicit list of parameters.
''');
  }

  void test_missingTypedefParameters_void() {
    parseTestCodeWithDiagnostics(r'''
typedef void F;
//            ^
// [diag.missingTypedefParameters] Typedefs must have an explicit list of parameters.
''');
  }

  void test_missingVariableInForEach() {
    parseTestCodeWithDiagnostics(r'''
void f() {
  for (a < b in foo) {}
//       ^
// [diag.unexpectedToken] Unexpected text '<'.
}
''');
  }

  void test_mixedParameterGroups_namedPositional() {
    parseTestCodeWithDiagnostics(r'''
void f(a, {b}, [c]) {}
//           ^
// [diag.expectedToken] Expected to find ')'.
''');
  }

  void test_mixedParameterGroups_positionalNamed() {
    parseTestCodeWithDiagnostics(r'''
void f(a, [b], {c}) {}
//           ^
// [diag.expectedToken] Expected to find ')'.
''');
  }

  void test_mixin_application_lacks_with_clause() {
    parseTestCodeWithDiagnostics(r'''
class Foo = Bar;
//             ^
// [diag.expectedToken] Expected to find 'with'.
''');
  }

  void test_multipleExtendsClauses() {
    parseTestCodeWithDiagnostics(r'''
class A extends B extends C {}
//                ^^^^^^^
// [diag.multipleExtendsClauses] Each class definition can have at most one extends clause.
''');
  }

  void test_multipleImplementsClauses() {
    parseTestCodeWithDiagnostics(r'''
class A implements B implements C {}
//                   ^^^^^^^^^^
// [diag.multipleImplementsClauses] Each class or mixin definition can have at most one implements clause.
''');
  }

  void test_multipleLibraryDirectives() {
    parseTestCodeWithDiagnostics(r'''
library l; library m;
//         ^^^^^^^
// [diag.multipleLibraryDirectives] Only one library directive may be declared in a file.
''');
  }

  void test_multipleNamedParameterGroups() {
    parseTestCodeWithDiagnostics(r'''
void f(a, {b}, {c}) {}
//           ^
// [diag.expectedToken] Expected to find ')'.
''');
  }

  void test_multiplePartOfDirectives() {
    parseTestCodeWithDiagnostics(r'''
part of l; part of m;
//      ^
// [diag.partOfName] The 'part of' directive can't use a name with the enhanced-parts feature.
//         ^^^^
// [diag.multiplePartOfDirectives] Only one part-of directive may be declared in a file.
//                 ^
// [diag.partOfName] The 'part of' directive can't use a name with the enhanced-parts feature.
''');
  }

  void test_multiplePositionalParameterGroups() {
    parseTestCodeWithDiagnostics(r'''
void f(a, [b], [c]) {}
//           ^
// [diag.expectedToken] Expected to find ')'.
''');
  }

  void test_multipleVariablesInForEach() {
    parseTestCodeWithDiagnostics(r'''
void f() {
  for (int a, b in foo) {}
//          ^
// [diag.unexpectedToken] Unexpected text ','.
}
''');
  }

  void test_multipleWithClauses() {
    parseTestCodeWithDiagnostics(r'''
class A extends B with C with D {}
//                       ^^^^
// [diag.multipleWithClauses] Each class definition can have at most one with clause.
''');
  }

  void test_namedFunctionExpression() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var x = (f() {});
//       ^
// [diag.namedFunctionExpression] Function expressions can't be named.
''');

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
    var result = parseTestCodeWithDiagnostics(r'''
void f(a, b : 0) {}
//          ^
// [diag.namedParameterOutsideGroup] Named parameters must be enclosed in curly braces ('{' and '}').
''');

    var list = result.findNode.singleFormalParameterList;
    assertParsedNodeText(list, r'''
FormalParameterList
  leftParenthesis: (
  parameter: RegularFormalParameter
    name: a
  parameter: RegularFormalParameter
    name: b
    defaultClause: FormalParameterDefaultClause
      separator: :
      value: IntegerLiteral
        literal: 0
  rightParenthesis: )
''');
  }

  void test_nonConstructorFactory_field() {
    parseTestCodeWithDiagnostics(r'''
class C {
  factory int x;
//            ^
// [diag.missingFunctionParameters] Functions must have an explicit list of parameters.
// [diag.missingFunctionBody] A function body must be provided.
// [diag.missingConstFinalVarOrType] Variables must be declared using the keywords 'const', 'final', 'var' or a type name.
}
''');
  }

  void test_nonConstructorFactory_method() {
    parseTestCodeWithDiagnostics(r'''
class C {
  factory int m() {}
//            ^
// [diag.missingFunctionParameters] Functions must have an explicit list of parameters.
// [diag.missingFunctionBody] A function body must be provided.
}
''');
  }

  void test_nonIdentifierLibraryName_library() {
    parseTestCodeWithDiagnostics(r'''
library 'lib';
//      ^^^^^
// [diag.missingIdentifier] Expected an identifier.
''');
  }

  void test_nonIdentifierLibraryName_partOf() {
    parseTestCodeWithDiagnostics(r'''
part of 3;
//   ^^
// [diag.expectedToken] Expected to find ';'.
//      ^
// [diag.expectedStringLiteral] Expected a string literal.
// [diag.expectedExecutable] Expected a method, getter, setter or operator declaration.
//       ^
// [diag.unexpectedToken] Unexpected text ';'.
''');
  }

  void test_nonUserDefinableOperator() {
    parseTestCodeWithDiagnostics(r'''
class C {
  operator +=(int x) => x + 1;
//         ^^
// [diag.invalidOperator] The string '+=' isn't a user-definable operator.
}
''');
  }

  void test_optionalAfterNormalParameters_named() {
    parseTestCodeWithDiagnostics(r'''
f({a}, b) {}
//   ^
// [diag.expectedToken] Expected to find ')'.
''');
  }

  void test_optionalAfterNormalParameters_positional() {
    parseTestCodeWithDiagnostics(r'''
f([a], b) {}
//   ^
// [diag.expectedToken] Expected to find ')'.
''');
  }

  void test_parseCascadeSection_missingIdentifier() {
    var result = parseTestCodeWithDiagnostics(r'''
var x = a..();
//         ^
// [diag.missingIdentifier] Expected an identifier.
''');

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
    var result = parseTestCodeWithDiagnostics(r'''
var x = a..<E>();
//         ^
// [diag.missingIdentifier] Expected an identifier.
''');
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
    parseTestCodeWithDiagnostics(r'''
class C { C. }
//        ^
// [diag.missingMethodParameters] Methods must have an explicit list of parameters.
//           ^
// [diag.missingIdentifier] Expected an identifier.
// [diag.missingFunctionBody] A function body must be provided.
''');
  }

  void test_positionalAfterNamedArgument() {
    parseTestCodeWithDiagnostics(r'''
void f() {
  g(x: 1, 2);
//        ^
// [diag.positionalAfterNamedArgument] Positional arguments must occur before named arguments.
}
''', featureSet: FeatureSets.language_2_16);
  }

  void test_positionalParameterOutsideGroup() {
    var result = parseTestCodeWithDiagnostics(r'''
void f(a, b = 0) {}
//          ^
// [diag.namedParameterOutsideGroup] Named parameters must be enclosed in curly braces ('{' and '}').
''');
    var list = result.findNode.singleFormalParameterList;
    assertParsedNodeText(list, r'''
FormalParameterList
  leftParenthesis: (
  parameter: RegularFormalParameter
    name: a
  parameter: RegularFormalParameter
    name: b
    defaultClause: FormalParameterDefaultClause
      separator: =
      value: IntegerLiteral
        literal: 0
  rightParenthesis: )
''');
  }

  void test_redirectionInNonFactoryConstructor() {
    parseTestCodeWithDiagnostics(r'''
class C {
  C() = D;
//    ^
// [diag.redirectionInNonFactoryConstructor] Only factory constructor can specify '=' redirection.
}
''');
  }

  void test_setterInFunction_block() {
    parseTestCodeWithDiagnostics(r'''
void f() {
  set x(v) {_x = v;}
//^^^
// [diag.unexpectedToken] Unexpected text 'set'.
}
''');
  }

  void test_setterInFunction_expression() {
    parseTestCodeWithDiagnostics(r'''
void f() {
  set x(v) => _x = v;
//^^^
// [diag.unexpectedToken] Unexpected text 'set'.
}
''');
  }

  void test_staticAfterConst() {
    parseTestCodeWithDiagnostics(r'''
class C {
  final static int f = 0;
//      ^^^^^^
// [diag.modifierOutOfOrder] The modifier 'static' should be before the modifier 'final'.
}
''');
  }

  void test_staticAfterFinal() {
    parseTestCodeWithDiagnostics(r'''
class C {
  const static int f = 0;
//      ^^^^^^
// [diag.modifierOutOfOrder] The modifier 'static' should be before the modifier 'const'.
}
''');
  }

  void test_staticAfterVar() {
    parseTestCodeWithDiagnostics(r'''
class C {
  var static f = 0;
//    ^^^^^^
// [diag.modifierOutOfOrder] The modifier 'static' should be before the modifier 'var'.
}
''');
  }

  void test_staticConstructor() {
    parseTestCodeWithDiagnostics(r'''
class C {
  static C.m() {}
//^^^^^^
// [diag.staticConstructor] Constructors can't be static.
}
''');
  }

  void test_staticGetterWithoutBody() {
    parseTestCodeWithDiagnostics(r'''
class C {
  static get m;
}
''');
  }

  void test_staticOperator_noReturnType() {
    parseTestCodeWithDiagnostics(r'''
class C {
  static operator +(int x) => x + 1;
//^^^^^^
// [diag.staticOperator] Operators can't be static.
}
''');
  }

  void test_staticOperator_returnType() {
    parseTestCodeWithDiagnostics(r'''
class C {
  static int operator +(int x) => x + 1;
//^^^^^^
// [diag.staticOperator] Operators can't be static.
}
''');
  }

  void test_staticOperatorNamedMethod() {
    // operator can be used as a method name
    parseTestCodeWithDiagnostics(r'''
class C { static operator(x) => x; }
''');
  }

  void test_staticSetterWithoutBody() {
    parseTestCodeWithDiagnostics(r'''
class C {
  static set m(x);
}
''');
  }

  void test_staticTopLevelDeclaration_class() {
    parseTestCodeWithDiagnostics(r'''
static class C {}
// [diag.extraneousModifier][column 1][length 6] Can't have modifier 'static' here.
''');
  }

  void test_staticTopLevelDeclaration_enum() {
    parseTestCodeWithDiagnostics(r'''
static enum E { v }
// [diag.extraneousModifier][column 1][length 6] Can't have modifier 'static' here.
''');
  }

  void test_staticTopLevelDeclaration_function() {
    parseTestCodeWithDiagnostics(r'''
static f() {}
// [diag.extraneousModifier][column 1][length 6] Can't have modifier 'static' here.
''');
  }

  void test_staticTopLevelDeclaration_typedef() {
    parseTestCodeWithDiagnostics(r'''
static typedef F();
// [diag.extraneousModifier][column 1][length 6] Can't have modifier 'static' here.
''');
  }

  void test_staticTopLevelDeclaration_variable() {
    parseTestCodeWithDiagnostics(r'''
static var x;
// [diag.extraneousModifier][column 1][length 6] Can't have modifier 'static' here.
''');
  }

  void test_string_unterminated_interpolation_block() {
    // TODO(brianwilkerson): Remove codes when highlighting is fixed.
    parseTestCodeWithDiagnostics(r'''
m() {
 {
 '${${
//   ^
// [diag.expectedToken] Expected to find '}'.
// [diag.unterminatedStringLiteral] Unterminated string literal.
//    ^
// [diag.expectedToken][column 7][length 0] Expected to find ';'.
// [diag.expectedToken][column 7][length 1] Expected to find '}'.
''');
  }

  void test_switchCase_missingColon() {
    parseTestCodeWithDiagnostics(r'''
void f() {
  switch (a) {case 1 return 0;}
//                   ^^^^^^
// [diag.expectedToken] Expected to find ':'.
}
''');
  }

  void test_switchDefault_missingColon() {
    parseTestCodeWithDiagnostics(r'''
void f() {
  switch (a) {default return 0;}
//                    ^^^^^^
// [diag.expectedToken] Expected to find ':'.
}
''');
  }

  void test_switchHasCaseAfterDefaultCase() {
    parseTestCodeWithDiagnostics(r'''
void f() {
  switch (a) {default: return 0; case 1: return 1;}
//                               ^^^^
// [diag.switchHasCaseAfterDefaultCase] The default case should be the last case in a switch statement.
}
''');
  }

  void test_switchHasCaseAfterDefaultCase_repeated() {
    parseTestCodeWithDiagnostics(r'''
void f() {
  switch (a) {default: return 0; case 1: return 1; case 2: return 2;}
//                               ^^^^
// [diag.switchHasCaseAfterDefaultCase] The default case should be the last case in a switch statement.
//                                                 ^^^^
// [diag.switchHasCaseAfterDefaultCase] The default case should be the last case in a switch statement.
}
''');
  }

  void test_switchHasMultipleDefaultCases() {
    parseTestCodeWithDiagnostics(r'''
void f() {
  switch (a) {default: return 0; default: return 1;}
//                               ^^^^^^^
// [diag.switchHasMultipleDefaultCases] The 'default' case can only be declared once.
}
''');
  }

  void test_switchHasMultipleDefaultCases_repeated() {
    parseTestCodeWithDiagnostics(r'''
void f() {
  switch (a) {default: return 0; default: return 1; default: return 2;}
//                               ^^^^^^^
// [diag.switchHasMultipleDefaultCases] The 'default' case can only be declared once.
//                                                  ^^^^^^^
// [diag.switchHasMultipleDefaultCases] The 'default' case can only be declared once.
}
''');
  }

  void test_switchMissingBlock() {
    parseTestCodeWithDiagnostics(r'''
void f() {
  switch (a) return;
//         ^
// [diag.expectedSwitchStatementBody] A switch statement must have a body, even if it is empty.
}
''');
  }

  void test_topLevel_getter() {
    var result = parseTestCodeWithDiagnostics(r'''
get x => 7;
''');
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
    parseTestCodeWithDiagnostics(r'''
factory Function() x = null;
// [diag.factoryTopLevelDeclaration][column 1][length 7] Top-level declarations can't be declared to be 'factory'.
''');
  }

  void test_topLevelOperator_withFunction() {
    parseTestCodeWithDiagnostics(r'''
operator Function() x = null;
// [diag.topLevelOperator][column 1][length 8] Operators must be declared within a class.
''');
  }

  void test_topLevelOperator_withoutOperator() {
    parseTestCodeWithDiagnostics(r'''
+(bool x, bool y) => x | y;
// [diag.topLevelOperator][column 1][length 1] Operators must be declared within a class.
''');
  }

  void test_topLevelOperator_withoutType() {
    parseTestCodeWithDiagnostics(r'''
operator +(bool x, bool y) => x | y;
// [diag.topLevelOperator][column 1][length 8] Operators must be declared within a class.
''');
  }

  void test_topLevelOperator_withType() {
    parseTestCodeWithDiagnostics(r'''
bool operator +(bool x, bool y) => x | y;
//   ^^^^^^^^
// [diag.topLevelOperator] Operators must be declared within a class.
''');
  }

  void test_topLevelOperator_withVoid() {
    parseTestCodeWithDiagnostics(r'''
void operator +(bool x, bool y) => x | y;
//   ^^^^^^^^
// [diag.topLevelOperator] Operators must be declared within a class.
''');
  }

  void test_topLevelVariable_withMetadata() {
    parseTestCodeWithDiagnostics(r'''
String @A string;
// [diag.missingConstFinalVarOrType][column 1][length 6] Variables must be declared using the keywords 'const', 'final', 'var' or a type name.
// [diag.expectedToken][column 1][length 6] Expected to find ';'.
//        ^^^^^^
// [diag.missingConstFinalVarOrType] Variables must be declared using the keywords 'const', 'final', 'var' or a type name.
''');
  }

  void test_typedef_incomplete() {
    // TODO(brianwilkerson): Improve recovery for this case.
    parseTestCodeWithDiagnostics(r'''
class A {}
class B extends A {}

typedef T

main() {
//   ^
// [diag.expectedToken] Expected to find ';'.
//     ^
// [diag.expectedExecutable] Expected a method, getter, setter or operator declaration.
  Function<
}
''');
  }

  void test_typedef_namedFunction() {
    parseTestCodeWithDiagnostics(r'''
typedef void Function();
//           ^^^^^^^^
// [diag.expectedIdentifierButGotKeyword] 'Function' can't be used as an identifier because it's a keyword.
''');
  }

  void test_typedefInClass_withoutReturnType() {
    parseTestCodeWithDiagnostics(r'''
class C { typedef F(x); }
//        ^^^^^^^
// [diag.typedefInClass] Typedefs can't be declared inside classes.
''');
  }

  void test_typedefInClass_withReturnType() {
    parseTestCodeWithDiagnostics(r'''
class C { typedef int F(int x); }
//        ^^^^^^^
// [diag.typedefInClass] Typedefs can't be declared inside classes.
''');
  }

  void test_unexpectedCommaThenInterpolation() {
    // https://github.com/Dart-Code/Dart-Code/issues/1548
    parseTestCodeWithDiagnostics(r'''
main() { String s = 'a' 'b', 'c$foo'; return s; }
//                         ^
// [diag.expectedToken] Expected to find ';'.
//                           ^^
// [diag.missingIdentifier] Expected an identifier.
''');
  }

  void test_unexpectedTerminatorForParameterGroup_named() {
    parseTestCodeWithDiagnostics(r'''
void f(a, b}) {}
//         ^
// [diag.expectedToken] Expected to find ')'.
''');
  }

  void test_unexpectedTerminatorForParameterGroup_optional() {
    parseTestCodeWithDiagnostics(r'''
void f(a, b]) {}
//         ^
// [diag.expectedToken] Expected to find ')'.
''');
  }

  void test_unexpectedToken_endOfFieldDeclarationStatement() {
    parseTestCodeWithDiagnostics(r'''
void f() {
  String s = (null));
//                ^
// [diag.expectedToken] Expected to find ';'.
//                 ^
// [diag.missingIdentifier] Expected an identifier.
// [diag.unexpectedToken] Unexpected text ';'.
}
''');
  }

  void test_unexpectedToken_invalidPostfixExpression() {
    parseTestCodeWithDiagnostics(r'''
var v = f()++;
//         ^^
// [diag.illegalAssignmentToNonAssignable] Illegal assignment to non-assignable expression.
''');
  }

  void test_unexpectedToken_invalidPrefixExpression() {
    parseTestCodeWithDiagnostics(r'''
var v = ++f();
//          ^
// [diag.missingAssignableSelector] Missing selector such as '.identifier' or '[0]'.
''');
  }

  void test_unexpectedToken_returnInExpressionFunctionBody() {
    parseTestCodeWithDiagnostics(r'''
f() => return null;
//     ^^^^^^
// [diag.unexpectedToken] Unexpected text 'return'.
''');
  }

  void test_unexpectedToken_semicolonBetweenClassMembers() {
    parseTestCodeWithDiagnostics(r'''
class C { int x; ; int y;}
//               ^
// [diag.expectedClassMember] Expected a class member.
''');
  }

  void test_unexpectedToken_semicolonBetweenCompilationUnitMembers() {
    parseTestCodeWithDiagnostics(r'''
int x; ; int y;
//     ^
// [diag.unexpectedToken] Unexpected text ';'.
''');
  }

  void test_unnamedLibraryDirective() {
    parseTestCodeWithDiagnostics(
      r'''library;
// [diag.experimentNotEnabled][column 1][length 7] This requires the 'unnamed-libraries' language feature to be enabled.''',
      featureSet: FeatureSets.language_2_18,
    );
  }

  void test_unnamedLibraryDirective_enabled() {
    parseTestCodeWithDiagnostics('library;');
  }

  void test_unterminatedString_at_eof() {
    // Although the "unterminated string" error message is produced by the
    // scanner, we need to verify that the parser can handle the tokens
    // produced by the scanner when an unterminated string is encountered.
    parseTestCodeWithDiagnostics(r'''
void main() {
  var x = "
//        ^
// [diag.expectedToken] Expected to find ';'.
// [diag.unterminatedStringLiteral] Unterminated string literal.
// [diag.expectedToken][column 12][length 1] Expected to find '}'.
''');
  }

  void test_unterminatedString_at_eol() {
    // Although the "unterminated string" error message is produced by the
    // scanner, we need to verify that the parser can handle the tokens
    // produced by the scanner when an unterminated string is encountered.
    parseTestCodeWithDiagnostics(r'''
void main() {
  var x = "
//        ^
// [diag.unterminatedStringLiteral] Unterminated string literal.
;
}
''');
  }

  void test_unterminatedString_multiline_at_eof_3_quotes() {
    // Although the "unterminated string" error message is produced by the
    // scanner, we need to verify that the parser can handle the tokens
    // produced by the scanner when an unterminated string is encountered.
    // TODO(brianwilkerson): Remove codes when highlighting is fixed.
    parseTestCodeWithDiagnostics(r'''
void main() {
  var x = """
//        ^^^
// [diag.expectedToken] Expected to find ';'.
//          ^
// [diag.unterminatedStringLiteral] Unterminated string literal.
// [diag.expectedToken][column 14][length 1] Expected to find '}'.''');
  }

  void test_unterminatedString_multiline_at_eof_4_quotes() {
    // Although the "unterminated string" error message is produced by the
    // scanner, we need to verify that the parser can handle the tokens
    // produced by the scanner when an unterminated string is encountered.
    // TODO(brianwilkerson): Remove codes when highlighting is fixed.
    parseTestCodeWithDiagnostics(r'''
void main() {
  var x = """"
//        ^^^^
// [diag.expectedToken] Expected to find ';'.
//           ^
// [diag.unterminatedStringLiteral] Unterminated string literal.
// [diag.expectedToken][column 15][length 1] Expected to find '}'.''');
  }

  void test_unterminatedString_multiline_at_eof_5_quotes() {
    // Although the "unterminated string" error message is produced by the
    // scanner, we need to verify that the parser can handle the tokens
    // produced by the scanner when an unterminated string is encountered.
    // TODO(brianwilkerson): Remove codes when highlighting is fixed.
    parseTestCodeWithDiagnostics(r'''
void main() {
  var x = """""
//        ^^^^^
// [diag.expectedToken] Expected to find ';'.
//            ^
// [diag.unterminatedStringLiteral] Unterminated string literal.
// [diag.expectedToken][column 16][length 1] Expected to find '}'.''');
  }

  void test_useOfUnaryPlusOperator() {
    var result = parseTestCodeWithDiagnostics(r'''var v = +x;
//      ^
// [diag.missingIdentifier] Expected an identifier.''');
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
    parseTestCodeWithDiagnostics(r'''
class C { var int x; }
//        ^^^
// [diag.varAndType] Variables can't be declared using both 'var' and a type name.
''');
  }

  void test_varAndType_local() {
    // This is currently reporting EXPECTED_TOKEN for a missing semicolon, but
    // this would be a better error message.
    parseTestCodeWithDiagnostics(r'''
void f() {
  var int x;
//^^^
// [diag.varAndType] Variables can't be declared using both 'var' and a type name.
}
''');
  }

  void test_varAndType_parameter() {
    // This is currently reporting EXPECTED_TOKEN for a missing semicolon, but
    // this would be a better error message.
    parseTestCodeWithDiagnostics(r'''
void f(var int x) {}
//     ^^^
// [diag.extraneousModifier] Can't have modifier 'var' here.
// [diag.varAndType] Variables can't be declared using both 'var' and a type name.
''');
  }

  void test_varAndType_topLevelVariable() {
    parseTestCodeWithDiagnostics(r'''
var int x;
// [diag.varAndType][column 1][length 3] Variables can't be declared using both 'var' and a type name.
''');
  }

  void test_varAsTypeName_as() {
    parseTestCodeWithDiagnostics(r'''
var v = x as var;
//        ^^
// [diag.expectedToken] Expected to find ';'.
//           ^^^
// [diag.expectedTypeName] Expected a type name.
//              ^
// [diag.missingIdentifier] Expected an identifier.
''');
  }

  void test_varClass() {
    // Fasta interprets the `var` as a malformed top level var
    // and `class` as the start of a class declaration.
    parseTestCodeWithDiagnostics(r'''
var class C {}
// [diag.expectedToken][column 1][length 3] Expected to find ';'.
//  ^^^^^
// [diag.missingIdentifier] Expected an identifier.
''');
  }

  void test_varEnum() {
    // Fasta interprets the `var` as a malformed top level var
    // and `enum` as the start of an enum declaration.
    parseTestCodeWithDiagnostics(r'''
var enum E {ONE}
// [diag.expectedToken][column 1][length 3] Expected to find ';'.
//  ^^^^
// [diag.missingIdentifier] Expected an identifier.
''');
  }

  void test_varReturnType() {
    parseTestCodeWithDiagnostics(r'''
class C {
  var m() {}
//^^^
// [diag.varReturnType] The return type can't be 'var'.
}
''');
  }

  void test_varTypedef() {
    // Fasta interprets the `var` as a malformed top level var
    // and `typedef` as the start of an typedef declaration.
    parseTestCodeWithDiagnostics(r'''
var typedef F();
// [diag.expectedToken][column 1][length 3] Expected to find ';'.
//  ^^^^^^^
// [diag.missingIdentifier] Expected an identifier.
''');
  }

  void test_voidParameter() {
    var result = parseTestCodeWithDiagnostics(r'''
void f(void a) {}
''');
    var node = result.findNode.singleFormalParameter;
    assertParsedNodeText(node, r'''
RegularFormalParameter
  type: NamedType
    name: void
  name: a
''');
  }

  void test_voidVariable_parseClassMember_initializer() {
    parseTestCodeWithDiagnostics(r'''
class C {
  void x = 0;
}
''');
  }

  void test_voidVariable_parseClassMember_noInitializer() {
    parseTestCodeWithDiagnostics(r'''
class C {
  void x;
}
''');
  }

  void test_voidVariable_parseCompilationUnit_initializer() {
    parseTestCodeWithDiagnostics(r'''
void x = 0;
''');
  }

  void test_voidVariable_parseCompilationUnit_noInitializer() {
    parseTestCodeWithDiagnostics(r'''
void x;
''');
  }

  void test_voidVariable_parseCompilationUnitMember_initializer() {
    parseTestCodeWithDiagnostics(r'''
void a = 0;
''');
  }

  void test_voidVariable_parseCompilationUnitMember_noInitializer() {
    parseTestCodeWithDiagnostics(r'''
void a;
''');
  }

  void test_voidVariable_statement_initializer() {
    parseTestCodeWithDiagnostics(r'''
void f() {
  void x = 0;
}
''');
  }

  void test_voidVariable_statement_noInitializer() {
    parseTestCodeWithDiagnostics(r'''
void f() {
  void x;
}
''');
  }

  void test_withBeforeExtends() {
    parseTestCodeWithDiagnostics(r'''
class A with B extends C {}
//             ^^^^^^^
// [diag.withBeforeExtends] The extends clause must be before the with clause.
''');
  }

  void test_withWithoutExtends() {
    parseTestCodeWithDiagnostics(r'''
class A with B, C {}
''');
  }

  void test_wrongSeparatorForPositionalParameter() {
    parseTestCodeWithDiagnostics(r'''
void f(a, [b : 0]) {}
//           ^
// [diag.wrongSeparatorForPositionalParameter] The default value of a positional parameter should be preceded by '='.
''');
  }

  void test_wrongTerminatorForParameterGroup_named() {
    parseTestCodeWithDiagnostics(r'''
void f(a, {b, c]) {}
//             ^
// [diag.expectedToken] Expected to find '}'.
//              ^
// [diag.expectedToken] Expected to find '}'.
''');
  }

  void test_wrongTerminatorForParameterGroup_optional() {
    parseTestCodeWithDiagnostics(r'''
void f(a, [b, c}) {}
//             ^
// [diag.expectedToken] Expected to find ']'.
//              ^
// [diag.expectedToken] Expected to find ']'.
''');
  }

  void test_yieldAsLabel() {
    // yield can be used as a label
    parseTestCodeWithDiagnostics('main() { yield: break yield; }');
  }
}
