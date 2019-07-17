// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../src/dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(StaticWarningCodeTest);
  });
}

@reflectiveTest
class StaticWarningCodeTest extends DriverResolutionTest {
  test_exportDuplicatedLibraryNamed() async {
    newFile("/test/lib/lib1.dart", content: "library lib;");
    newFile("/test/lib/lib2.dart", content: "library lib;");
    await assertErrorsInCode('''
library test;
export 'lib1.dart';
export 'lib2.dart';''', [
      error(StaticWarningCode.EXPORT_DUPLICATED_LIBRARY_NAMED, 34, 19),
    ]);
  }

  test_extraPositionalArguments() async {
    await assertErrorsInCode('''
f() {}
main() {
  f(0, 1, '2');
}''', [
      error(StaticWarningCode.EXTRA_POSITIONAL_ARGUMENTS, 19, 11),
    ]);
  }

  test_extraPositionalArguments_functionExpression() async {
    await assertErrorsInCode('''
main() {
  (int x) {} (0, 1);
}''', [
      error(StaticWarningCode.EXTRA_POSITIONAL_ARGUMENTS, 22, 6),
    ]);
  }

  test_extraPositionalArgumentsCouldBeNamed() async {
    await assertErrorsInCode('''
f({x, y}) {}
main() {
  f(0, 1, '2');
}''', [
      error(
          StaticWarningCode.EXTRA_POSITIONAL_ARGUMENTS_COULD_BE_NAMED, 25, 11),
    ]);
  }

  test_extraPositionalArgumentsCouldBeNamed_functionExpression() async {
    await assertErrorsInCode('''
main() {
  (int x, {int y}) {} (0, 1);
}''', [
      error(StaticWarningCode.EXTRA_POSITIONAL_ARGUMENTS_COULD_BE_NAMED, 31, 6),
    ]);
  }

  test_fieldInitializedInInitializerAndDeclaration_final() async {
    await assertErrorsInCode('''
class A {
  final int x = 0;
  A() : x = 1 {}
}''', [
      error(StaticWarningCode.FIELD_INITIALIZED_IN_INITIALIZER_AND_DECLARATION,
          37, 1),
    ]);
  }

  test_fieldInitializerNotAssignable() async {
    await assertErrorsInCode('''
class A {
  int x;
  A() : x = '';
}''', [
      error(StaticWarningCode.FIELD_INITIALIZER_NOT_ASSIGNABLE, 31, 2),
    ]);
  }

  test_fieldInitializingFormalNotAssignable() async {
    await assertErrorsInCode('''
class A {
  int x;
  A(String this.x) {}
}''', [
      error(StrongModeCode.INVALID_PARAMETER_DECLARATION, 23, 13),
      error(StaticWarningCode.FIELD_INITIALIZING_FORMAL_NOT_ASSIGNABLE, 23, 13),
    ]);
  }

  /**
   * This test doesn't test the FINAL_INITIALIZED_IN_DECLARATION_AND_CONSTRUCTOR code, but tests the
   * FIELD_INITIALIZED_IN_INITIALIZER_AND_DECLARATION code instead. It is provided here to show
   * coverage over all of the permutations of initializers in constructor declarations.
   *
   * Note: FIELD_INITIALIZED_IN_INITIALIZER_AND_DECLARATION covers a subset of
   * FINAL_INITIALIZED_IN_DECLARATION_AND_CONSTRUCTOR, since it more specific, we use it instead of
   * the broader code
   */
  test_finalInitializedInDeclarationAndConstructor_initializers() async {
    await assertErrorsInCode('''
class A {
  final x = 0;
  A() : x = 0 {}
}''', [
      error(StaticWarningCode.FIELD_INITIALIZED_IN_INITIALIZER_AND_DECLARATION,
          33, 1),
    ]);
  }

  test_finalInitializedInDeclarationAndConstructor_initializingFormal() async {
    await assertErrorsInCode('''
class A {
  final x = 0;
  A(this.x) {}
}''', [
      error(StaticWarningCode.FINAL_INITIALIZED_IN_DECLARATION_AND_CONSTRUCTOR,
          34, 1),
    ]);
  }

  test_finalNotInitialized_inConstructor_1() async {
    await assertErrorsInCode('''
class A {
  final int x;
  A() {}
}''', [
      error(StaticWarningCode.FINAL_NOT_INITIALIZED_CONSTRUCTOR_1, 27, 1),
    ]);
  }

  test_finalNotInitialized_inConstructor_2() async {
    await assertErrorsInCode('''
class A {
  final int a;
  final int b;
  A() {}
}''', [
      error(StaticWarningCode.FINAL_NOT_INITIALIZED_CONSTRUCTOR_2, 42, 1),
    ]);
  }

  test_finalNotInitialized_inConstructor_3() async {
    await assertErrorsInCode('''
class A {
  final int a;
  final int b;
  final int c;
  A() {}
}''', [
      error(StaticWarningCode.FINAL_NOT_INITIALIZED_CONSTRUCTOR_3_PLUS, 57, 1),
    ]);
  }

  test_finalNotInitialized_instanceField_final() async {
    await assertErrorsInCode('''
class A {
  final F;
}''', [
      error(StaticWarningCode.FINAL_NOT_INITIALIZED, 18, 1),
    ]);
  }

  test_finalNotInitialized_instanceField_final_static() async {
    await assertErrorsInCode('''
class A {
  static final F;
}''', [
      error(StaticWarningCode.FINAL_NOT_INITIALIZED, 25, 1),
    ]);
  }

  test_finalNotInitialized_library_final() async {
    await assertErrorsInCode('''
final F;
''', [
      error(StaticWarningCode.FINAL_NOT_INITIALIZED, 6, 1),
    ]);
  }

  test_finalNotInitialized_local_final() async {
    await assertErrorsInCode('''
f() {
  final int x;
}''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 18, 1),
      error(StaticWarningCode.FINAL_NOT_INITIALIZED, 18, 1),
    ]);
  }

  test_functionWithoutCall_direct() async {
    await assertNoErrorsInCode('''
class A implements Function {
}''');
  }

  test_functionWithoutCall_direct_typeAlias() async {
    await assertNoErrorsInCode('''
class M {}
class A = Object with M implements Function;''');
  }

  test_functionWithoutCall_indirect_extends() async {
    await assertNoErrorsInCode('''
abstract class A implements Function {
}
class B extends A {
}''');
  }

  test_functionWithoutCall_indirect_extends_typeAlias() async {
    await assertNoErrorsInCode('''
abstract class A implements Function {}
class M {}
class B = A with M;''');
  }

  test_functionWithoutCall_indirect_implements() async {
    await assertNoErrorsInCode('''
abstract class A implements Function {
}
class B implements A {
}''');
  }

  test_functionWithoutCall_indirect_implements_typeAlias() async {
    await assertNoErrorsInCode('''
abstract class A implements Function {}
class M {}
class B = Object with M implements A;''');
  }

  test_functionWithoutCall_mixin_implements() async {
    await assertNoErrorsInCode('''
abstract class A implements Function {}
class B extends Object with A {}''');
  }

  test_functionWithoutCall_mixin_implements_typeAlias() async {
    await assertNoErrorsInCode('''
abstract class A implements Function {}
class B = Object with A;''');
  }

  test_generalizedVoid_andVoidLhsError() async {
    await assertErrorsInCode('''
void main() {
  void x;
  x && true;
}
''', [
      error(StaticWarningCode.USE_OF_VOID_RESULT, 26, 1),
    ]);
  }

  test_generalizedVoid_andVoidRhsError() async {
    await assertErrorsInCode('''
void main() {
  void x;
  true && x;
}
''', [
      error(StaticWarningCode.USE_OF_VOID_RESULT, 34, 1),
    ]);
  }

  test_generalizedVoid_assignmentToVoidParameterOk() async {
    // Note: the spec may decide to disallow this, but at this point that seems
    // highly unlikely.
    await assertNoErrorsInCode('''
void main() {
  void x;
  f(x);
}
void f(void x) {}
''');
  }

  test_generalizedVoid_assignToVoid_notStrong_error() async {
    // See StrongModeStaticTypeAnalyzer2Test.test_generalizedVoid_assignToVoidOk
    // for testing that this does not have errors in strong mode.
    await assertNoErrorsInCode('''
void main() {
  void x;
  x = 42;
}
''');
  }

  test_generalizedVoid_interpolateVoidValueError() async {
    await assertErrorsInCode(r'''
void main() {
  void x;
  "$x";
}
''', [
      error(StaticWarningCode.USE_OF_VOID_RESULT, 28, 1),
    ]);
  }

  test_generalizedVoid_negateVoidValueError() async {
    await assertErrorsInCode('''
void main() {
  void x;
  !x;
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 21, 1),
      error(StaticWarningCode.USE_OF_VOID_RESULT, 27, 1),
    ]);
  }

  test_generalizedVoid_orVoidLhsError() async {
    await assertErrorsInCode('''
void main() {
  void x;
  x || true;
}
''', [
      error(StaticWarningCode.USE_OF_VOID_RESULT, 26, 1),
    ]);
  }

  test_generalizedVoid_orVoidRhsError() async {
    await assertErrorsInCode('''
void main() {
  void x;
  false || x;
}
''', [
      error(StaticWarningCode.USE_OF_VOID_RESULT, 35, 1),
    ]);
  }

  test_generalizedVoid_throwVoidValueError() async {
    await assertErrorsInCode('''
void main() {
  void x;
  throw x;
}
''', [
      error(StaticWarningCode.USE_OF_VOID_RESULT, 32, 1),
    ]);
  }

  test_generalizedVoid_unaryNegativeVoidValueError() async {
    await assertErrorsInCode('''
void main() {
  void x;
  -x;
}
''', [
      // TODO(mfairhurst) suppress UNDEFINED_OPERATOR
      error(HintCode.UNUSED_LOCAL_VARIABLE, 21, 1),
      error(StaticTypeWarningCode.UNDEFINED_OPERATOR, 26, 1),
      error(StaticWarningCode.USE_OF_VOID_RESULT, 27, 1),
    ]);
  }

  test_generalizedVoid_useOfInForeachIterableError() async {
    await assertErrorsInCode('''
void main() {
  void x;
  for (var v in x) {}
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 35, 1),
      error(StaticWarningCode.USE_OF_VOID_RESULT, 40, 1),
    ]);
  }

  test_generalizedVoid_useOfVoidAsIndexAssignError() async {
    await assertErrorsInCode('''
void main(List list) {
  void x;
  list[x] = null;
}
''', [
      error(StaticWarningCode.USE_OF_VOID_RESULT, 40, 1),
    ]);
  }

  test_generalizedVoid_useOfVoidAsIndexError() async {
    await assertErrorsInCode('''
void main(List list) {
  void x;
  list[x];
}
''', [
      error(StaticWarningCode.USE_OF_VOID_RESULT, 40, 1),
    ]);
  }

  test_generalizedVoid_useOfVoidAssignedToDynamicError() async {
    await assertErrorsInCode('''
void main() {
  void x;
  dynamic z = x;
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 34, 1),
      error(StaticWarningCode.USE_OF_VOID_RESULT, 38, 1),
    ]);
  }

  test_generalizedVoid_useOfVoidByIndexingError() async {
    await assertErrorsInCode('''
void main() {
  void x;
  x[0];
}
''', [
      error(StaticWarningCode.USE_OF_VOID_RESULT, 27, 3),
    ]);
  }

  test_generalizedVoid_useOfVoidCallSetterError() async {
    await assertErrorsInCode('''
void main() {
  void x;
  x.foo = null;
}
''', [
      error(StaticWarningCode.USE_OF_VOID_RESULT, 28, 3),
    ]);
  }

  test_generalizedVoid_useOfVoidCastsOk() async {
    await assertNoErrorsInCode('''
void use(dynamic x) { }
void main() {
  void x;
  use(x as int);
}
''');
  }

  test_generalizedVoid_useOfVoidInConditionalConditionError() async {
    await assertErrorsInCode('''
void main() {
  void x;
  x ? null : null;
}
''', [
      error(StaticWarningCode.USE_OF_VOID_RESULT, 26, 1),
    ]);
  }

  @failingTest
  test_generalizedVoid_useOfVoidInConditionalLhsError() async {
    // TODO(mfairhurst) Enable this.
    await assertErrorsInCode('''
void main(bool c) {
  void x;
  c ? x : null;
}
''', [
      error(StaticWarningCode.USE_OF_VOID_RESULT, 36, 1),
    ]);
  }

  @failingTest
  test_generalizedVoid_useOfVoidInConditionalRhsError() async {
    // TODO(mfairhurst) Enable this.
    await assertErrorsInCode('''
void main(bool c) {
  void x;
  c ? null : x;
}
''', [
      error(StaticWarningCode.USE_OF_VOID_RESULT, 43, 1),
    ]);
  }

  test_generalizedVoid_useOfVoidInDoWhileConditionError() async {
    await assertErrorsInCode('''
void main() {
  void x;
  do {} while (x);
}
''', [
      error(StaticWarningCode.USE_OF_VOID_RESULT, 39, 1),
    ]);
  }

  test_generalizedVoid_useOfVoidInExpStmtOk() async {
    await assertNoErrorsInCode('''
void main() {
  void x;
  x;
}
''');
  }

  @failingTest // This test may be completely invalid.
  test_generalizedVoid_useOfVoidInForeachVariableError() async {
    await assertErrorsInCode('''
void main() {
  void x;
  for (x in [1, 2]) {}
}
''', [
      error(StaticWarningCode.USE_OF_VOID_RESULT, 31, 1),
    ]);
  }

  test_generalizedVoid_useOfVoidInForPartsOk() async {
    await assertNoErrorsInCode('''
void main() {
  void x;
  for (x; false; x) {}
}
''');
  }

  test_generalizedVoid_useOfVoidInIsTestError() async {
    await assertErrorsInCode('''
void main() {
  void x;
  x is int;
}
''', [
      error(StaticWarningCode.USE_OF_VOID_RESULT, 26, 1),
    ]);
  }

  test_generalizedVoid_useOfVoidInListLiteralError() async {
    await assertErrorsInCode('''
void main() {
  void x;
  <dynamic>[x];
}
''', [
      error(StaticWarningCode.USE_OF_VOID_RESULT, 36, 1),
    ]);
  }

  test_generalizedVoid_useOfVoidInListLiteralOk() async {
    await assertNoErrorsInCode('''
void main() {
  void x;
  <void>[x]; // not strong mode; we have to specify <void>.
}
''');
  }

  test_generalizedVoid_useOfVoidInMapLiteralKeyError() async {
    await assertErrorsInCode('''
void main() {
  void x;
  var m2 = <dynamic, int>{x : 4};
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 30, 2),
      error(StaticWarningCode.USE_OF_VOID_RESULT, 50, 1),
    ]);
  }

  test_generalizedVoid_useOfVoidInMapLiteralKeyOk() async {
    await assertNoErrorsInCode('''
void main() {
  void x;
  var m2 = <void, int>{x : 4}; // not strong mode; we have to specify <void>.
}
''');
  }

  test_generalizedVoid_useOfVoidInMapLiteralValueError() async {
    await assertErrorsInCode('''
void main() {
  void x;
  var m1 = <int, dynamic>{4: x};
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 30, 2),
      error(StaticWarningCode.USE_OF_VOID_RESULT, 53, 1),
    ]);
  }

  test_generalizedVoid_useOfVoidInMapLiteralValueOk() async {
    await assertNoErrorsInCode('''
void main() {
  void x;
  var m1 = <int, void>{4: x}; // not strong mode; we have to specify <void>.
}
''');
  }

  test_generalizedVoid_useOfVoidInNullOperatorLhsError() async {
    await assertErrorsInCode('''
void main() {
  void x;
  x ?? 499;
}
''', [
      error(StaticWarningCode.USE_OF_VOID_RESULT, 26, 1),
    ]);
  }

  test_generalizedVoid_useOfVoidInNullOperatorRhsOk() async {
    await assertNoErrorsInCode('''
void main() {
  void x;
  null ?? x;
}
''');
  }

  test_generalizedVoid_useOfVoidInSpecialAssignmentError() async {
    await assertErrorsInCode('''
void main() {
  void x;
  x += 1;
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 21, 1),
      error(StaticWarningCode.USE_OF_VOID_RESULT, 28, 2),
    ]);
  }

  test_generalizedVoid_useOfVoidInSwitchExpressionError() async {
    await assertErrorsInCode('''
void main() {
  void x;
  switch(x) {}
}
''', [
      error(StaticWarningCode.USE_OF_VOID_RESULT, 33, 1),
    ]);
  }

  test_generalizedVoid_useOfVoidInWhileConditionError() async {
    await assertErrorsInCode('''
void main() {
  void x;
  while (x) {};
}
''', [
      error(StaticWarningCode.USE_OF_VOID_RESULT, 33, 1),
    ]);
  }

  test_generalizedVoid_useOfVoidNullPropertyAccessError() async {
    await assertErrorsInCode('''
void main() {
  void x;
  x?.foo;
}
''', [
      error(StaticWarningCode.USE_OF_VOID_RESULT, 29, 3),
    ]);
  }

  test_generalizedVoid_useOfVoidPropertyAccessError() async {
    await assertErrorsInCode('''
void main() {
  void x;
  x.foo;
}
''', [
      error(StaticWarningCode.USE_OF_VOID_RESULT, 28, 3),
    ]);
  }

  @failingTest
  test_generalizedVoid_useOfVoidReturnInNonVoidFunctionError() async {
    // TODO(mfairhurst) Get this test to pass once codebase is compliant.
    await assertErrorsInCode('''
dynamic main() {
  void x;
  return x;
}
''', [
      error(StaticTypeWarningCode.RETURN_OF_INVALID_TYPE, 36, 1),
    ]);
  }

  test_generalizedVoid_useOfVoidReturnInVoidFunctionOk() async {
    await assertNoErrorsInCode('''
void main() {
  void x;
  return x;
}
''');
  }

  test_generalizedVoid_useOfVoidWhenArgumentError() async {
    await assertErrorsInCode('''
void use(dynamic x) { }
void main() {
  void x;
  use(x);
}
''', [
      error(StaticWarningCode.USE_OF_VOID_RESULT, 54, 1),
    ]);
  }

  test_generalizedVoid_useOfVoidWithInitializerOk() async {
    await assertNoErrorsInCode('''
void main() {
  void x;
  void y = x;
}
''');
  }

  test_generalizedVoid_yieldStarVoid_asyncStar() async {
    await assertErrorsInCode('''
main(void x) async* {
  yield* x;
}
''', [
      error(StaticWarningCode.USE_OF_VOID_RESULT, 31, 1),
    ]);
  }

  test_generalizedVoid_yieldStarVoid_syncStar() async {
    await assertErrorsInCode('''
main(void x) sync* {
  yield* x;
}
''', [
      error(StaticWarningCode.USE_OF_VOID_RESULT, 30, 1),
    ]);
  }

  test_generalizedVoid_yieldVoid_asyncStar() async {
    await assertErrorsInCode('''
main(void x) async* {
  yield x;
}
''', [
      error(StaticWarningCode.USE_OF_VOID_RESULT, 30, 1),
    ]);
  }

  test_generalizedVoid_yieldVoid_syncStar() async {
    await assertErrorsInCode('''
main(void x) sync* {
  yield x;
}
''', [
      error(StaticWarningCode.USE_OF_VOID_RESULT, 29, 1),
    ]);
  }

  test_importDuplicatedLibraryNamed() async {
    newFile("/test/lib/lib1.dart", content: "library lib;");
    newFile("/test/lib/lib2.dart", content: "library lib;");
    await assertErrorsInCode('''
library test;
import 'lib1.dart';
import 'lib2.dart';''', [
      error(HintCode.UNUSED_IMPORT, 21, 11),
      error(StaticWarningCode.IMPORT_DUPLICATED_LIBRARY_NAMED, 34, 19),
      error(HintCode.UNUSED_IMPORT, 41, 11),
    ]);
  }

  test_importOfNonLibrary() async {
    newFile("/test/lib/lib1.dart", content: '''
part of lib;
class A {}''');
    await assertErrorsInCode('''
library lib;
import 'lib1.dart' deferred as p;
var a = new p.A();''', [
      error(StaticWarningCode.IMPORT_OF_NON_LIBRARY, 20, 11),
    ]);
  }

  test_invalidGetterOverrideReturnType() async {
    await assertErrorsInCode('''
class A {
  int get g { return 0; }
}
class B extends A {
  String get g { return 'a'; }
}''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 60, 28),
    ]);
  }

  test_invalidGetterOverrideReturnType_implicit() async {
    await assertErrorsInCode('''
class A {
  String f;
}
class B extends A {
  int f;
}''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 46, 5),
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 46, 5),
    ]);
  }

  test_invalidGetterOverrideReturnType_twoInterfaces() async {
    // test from language/override_inheritance_field_test_11.dart
    await assertErrorsInCode('''
abstract class I {
  int get getter => null;
}
abstract class J {
  num get getter => null;
}
abstract class A implements I, J {}
class B extends A {
  String get getter => null;
}''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 152, 26),
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 152, 26),
    ]);
  }

  test_invalidGetterOverrideReturnType_twoInterfaces_conflicting() async {
    await assertErrorsInCode('''
abstract class I<U> {
  U get g => null;
}
abstract class J<V> {
  V get g => null;
}
class B implements I<int>, J<String> {
  double get g => null;
}''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 127, 21),
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 127, 21),
    ]);
  }

  test_invalidMethodOverrideNamedParamType() async {
    await assertErrorsInCode('''
class A {
  m({int a}) {}
}
class B implements A {
  m({String a}) {}
}''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 53, 16),
    ]);
  }

  test_invalidMethodOverrideNormalParamType_interface() async {
    await assertErrorsInCode('''
class A {
  m(int a) {}
}
class B implements A {
  m(String a) {}
}''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 51, 14),
    ]);
  }

  test_invalidMethodOverrideNormalParamType_superclass() async {
    await assertErrorsInCode('''
class A {
  m(int a) {}
}
class B extends A {
  m(String a) {}
}''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 48, 14),
    ]);
  }

  test_invalidMethodOverrideNormalParamType_superclass_interface() async {
    await assertErrorsInCode('''
abstract class I<U> {
  m(U u) => null;
}
abstract class J<V> {
  m(V v) => null;
}
class B extends I<int> implements J<String> {
  m(double d) {}
}''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 132, 14),
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 132, 14),
    ]);
  }

  test_invalidMethodOverrideNormalParamType_twoInterfaces() async {
    await assertErrorsInCode('''
abstract class I {
  m(int n);
}
abstract class J {
  m(num n);
}
abstract class A implements I, J {}
class B extends A {
  m(String n) {}
}''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 124, 14),
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 124, 14),
    ]);
  }

  test_invalidMethodOverrideNormalParamType_twoInterfaces_conflicting() async {
    // language/override_inheritance_generic_test/08
    await assertErrorsInCode('''
abstract class I<U> {
  m(U u) => null;
}
abstract class J<V> {
  m(V v) => null;
}
class B implements I<int>, J<String> {
  m(double d) {}
}''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 125, 14),
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 125, 14),
    ]);
  }

  test_invalidMethodOverrideOptionalParamType() async {
    await assertErrorsInCode('''
class A {
  m([int a]) {}
}
class B implements A {
  m([String a]) {}
}''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 53, 16),
    ]);
  }

  test_invalidMethodOverrideOptionalParamType_twoInterfaces() async {
    await assertErrorsInCode('''
abstract class I {
  m([int n]);
}
abstract class J {
  m([num n]);
}
abstract class A implements I, J {}
class B extends A {
  m([String n]) {}
}''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 128, 16),
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 128, 16),
    ]);
  }

  test_invalidMethodOverrideReturnType_interface() async {
    await assertErrorsInCode('''
class A {
  int m() { return 0; }
}
class B implements A {
  String m() { return 'a'; }
}''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 61, 26),
    ]);
  }

  test_invalidMethodOverrideReturnType_interface_grandparent() async {
    await assertErrorsInCode('''
abstract class A {
  int m();
}
abstract class B implements A {
}
class C implements B {
  String m() { return 'a'; }
}''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 91, 26),
    ]);
  }

  test_invalidMethodOverrideReturnType_mixin() async {
    await assertErrorsInCode('''
class A {
  int m() { return 0; }
}
class B extends Object with A {
  String m() { return 'a'; }
}''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 70, 26),
    ]);
  }

  test_invalidMethodOverrideReturnType_superclass() async {
    await assertErrorsInCode('''
class A {
  int m() { return 0; }
}
class B extends A {
  String m() { return 'a'; }
}''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 58, 26),
    ]);
  }

  test_invalidMethodOverrideReturnType_superclass_grandparent() async {
    await assertErrorsInCode('''
class A {
  int m() { return 0; }
}
class B extends A {
}
class C extends B {
  String m() { return 'a'; }
}''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 80, 26),
    ]);
  }

  test_invalidMethodOverrideReturnType_twoInterfaces() async {
    await assertErrorsInCode('''
abstract class I {
  int m();
}
abstract class J {
  num m();
}
abstract class A implements I, J {}
class B extends A {
  String m() => '';
}''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 122, 17),
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 122, 17),
    ]);
  }

  test_invalidMethodOverrideReturnType_void() async {
    await assertErrorsInCode('''
class A {
  int m() { return 0; }
}
class B extends A {
  void m() {}
}''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 58, 11),
    ]);
  }

  test_invalidOverrideNamed_fewerNamedParameters() async {
    await assertErrorsInCode('''
class A {
  m({a, b}) {}
}
class B extends A {
  m({a}) {}
}''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 49, 9),
    ]);
  }

  test_invalidOverrideNamed_missingNamedParameter() async {
    await assertErrorsInCode('''
class A {
  m({a, b}) {}
}
class B extends A {
  m({a, c}) {}
}''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 49, 12),
    ]);
  }

  test_invalidOverridePositional_optional() async {
    await assertErrorsInCode('''
class A {
  m([a, b]) {}
}
class B extends A {
  m([a]) {}
}''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 49, 9),
    ]);
  }

  test_invalidOverridePositional_optionalAndRequired() async {
    await assertErrorsInCode('''
class A {
  m(a, b, [c, d]) {}
}
class B extends A {
  m(a, b, [c]) {}
}''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 55, 15),
    ]);
  }

  test_invalidOverridePositional_optionalAndRequired2() async {
    await assertErrorsInCode('''
class A {
  m(a, b, [c, d]) {}
}
class B extends A {
  m(a, [c, d]) {}
}''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 55, 15),
    ]);
  }

  test_invalidOverrideRequired() async {
    await assertErrorsInCode('''
class A {
  m(a) {}
}
class B extends A {
  m(a, b) {}
}''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 44, 10),
    ]);
  }

  test_invalidSetterOverrideNormalParamType() async {
    await assertErrorsInCode('''
class A {
  void set s(int v) {}
}
class B extends A {
  void set s(String v) {}
}''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 57, 23),
    ]);
  }

  test_invalidSetterOverrideNormalParamType_superclass_interface() async {
    await assertErrorsInCode('''
abstract class I {
  set setter14(int _) => null;
}
abstract class J {
  set setter14(num _) => null;
}
abstract class A extends I implements J {}
class B extends A {
  set setter14(String _) => null;
}''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 169, 31),
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 169, 31),
    ]);
  }

  test_invalidSetterOverrideNormalParamType_twoInterfaces() async {
    // test from language/override_inheritance_field_test_34.dart
    await assertErrorsInCode('''
abstract class I {
  set setter14(int _) => null;
}
abstract class J {
  set setter14(num _) => null;
}
abstract class A implements I, J {}
class B extends A {
  set setter14(String _) => null;
}''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 162, 31),
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 162, 31),
    ]);
  }

  test_invalidSetterOverrideNormalParamType_twoInterfaces_conflicting() async {
    await assertErrorsInCode('''
abstract class I<U> {
  set s(U u) {}
}
abstract class J<V> {
  set s(V v) {}
}
class B implements I<int>, J<String> {
  set s(double d) {}
}''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 121, 18),
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 121, 18),
    ]);
  }

  test_mismatchedAccessorTypes_topLevel() async {
    await assertErrorsInCode('''
int get g { return 0; }
set g(String v) {}''', [
      error(StaticWarningCode.MISMATCHED_GETTER_AND_SETTER_TYPES, 0, 23),
    ]);
  }

  test_missingEnumConstantInSwitch() async {
    await assertErrorsInCode('''
enum E { ONE, TWO, THREE, FOUR }
bool odd(E e) {
  switch (e) {
    case E.ONE:
    case E.THREE: return true;
  }
  return false;
}''', [
      error(StaticWarningCode.MISSING_ENUM_CONSTANT_IN_SWITCH, 51, 10),
      error(StaticWarningCode.MISSING_ENUM_CONSTANT_IN_SWITCH, 51, 10),
    ]);
  }

  test_mixedReturnTypes_localFunction() async {
    await assertErrorsInCode('''
class C {
  m(int x) {
    return (int y) {
      if (y < 0) {
        return;
      }
      return 0;
    };
  }
}''', [
      error(StaticWarningCode.RETURN_WITHOUT_VALUE, 71, 7),
    ]);
  }

  test_mixedReturnTypes_method() async {
    await assertErrorsInCode('''
class C {
  m(int x) {
    if (x < 0) {
      return;
    }
    return 0;
  }
}''', [
      error(StaticWarningCode.MIXED_RETURN_TYPES, 46, 6),
      error(StaticWarningCode.MIXED_RETURN_TYPES, 64, 6),
    ]);
  }

  test_mixedReturnTypes_topLevelFunction() async {
    await assertErrorsInCode('''
f(int x) {
  if (x < 0) {
    return;
  }
  return 0;
}''', [
      error(StaticWarningCode.MIXED_RETURN_TYPES, 30, 6),
      error(StaticWarningCode.MIXED_RETURN_TYPES, 44, 6),
    ]);
  }

  test_newWithAbstractClass() async {
    await assertErrorsInCode('''
abstract class A {}
void f() {
  A a = new A();
}''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 35, 1),
      error(StaticWarningCode.NEW_WITH_ABSTRACT_CLASS, 43, 1),
    ]);
  }

  test_newWithAbstractClass_generic() async {
    await assertErrorsInCode('''
abstract class A<E> {}
void f() {
  var a = new A<int>();
}''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 40, 1),
      error(StaticWarningCode.NEW_WITH_ABSTRACT_CLASS, 48, 6),
    ]);

    ClassDeclaration classA = result.unit.declarations[0];
    FunctionDeclaration f = result.unit.declarations[1];
    BlockFunctionBody body = f.functionExpression.body;
    VariableDeclarationStatement a = body.block.statements[0];
    InstanceCreationExpression init = a.variables.variables[0].initializer;
    expect(init.staticType,
        classA.declaredElement.type.instantiate([typeProvider.intType]));
  }

  test_newWithInvalidTypeParameters() async {
    await assertErrorsInCode('''
class A {}
f() { return new A<A>(); }''', [
      error(StaticWarningCode.NEW_WITH_INVALID_TYPE_PARAMETERS, 28, 4),
    ]);
  }

  test_newWithInvalidTypeParameters_tooFew() async {
    await assertErrorsInCode('''
class A {}
class C<K, V> {}
f(p) {
  return new C<A>();
}''', [
      error(StaticWarningCode.NEW_WITH_INVALID_TYPE_PARAMETERS, 48, 4),
    ]);
  }

  test_newWithInvalidTypeParameters_tooMany() async {
    await assertErrorsInCode('''
class A {}
class C<E> {}
f(p) {
  return new C<A, A>();
}''', [
      error(StaticWarningCode.NEW_WITH_INVALID_TYPE_PARAMETERS, 45, 7),
    ]);
  }

  test_newWithNonType() async {
    await assertErrorsInCode('''
var A = 0;
void f() {
  var a = new A();
}''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 28, 1),
      error(StaticWarningCode.NEW_WITH_NON_TYPE, 36, 1),
    ]);
  }

  test_newWithNonType_fromLibrary() async {
    newFile("/test/lib/lib.dart", content: "class B {}");
    await assertErrorsInCode('''
import 'lib.dart' as lib;
void f() {
  var a = new lib.A();
}
lib.B b;''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 43, 1),
      error(StaticWarningCode.NEW_WITH_NON_TYPE, 55, 1),
    ]);
  }

  test_newWithUndefinedConstructor() async {
    await assertErrorsInCode('''
class A {
  A() {}
}
f() {
  new A.name();
}''', [
      error(StaticWarningCode.NEW_WITH_UNDEFINED_CONSTRUCTOR, 35, 4),
    ]);
  }

  test_newWithUndefinedConstructorDefault() async {
    await assertErrorsInCode('''
class A {
  A.name() {}
}
f() {
  new A();
}''', [
      error(StaticWarningCode.NEW_WITH_UNDEFINED_CONSTRUCTOR_DEFAULT, 38, 1),
    ]);
  }

  test_nonAbstractClassInheritsAbstractMemberFivePlus() async {
    await assertErrorsInCode('''
abstract class A {
  m();
  n();
  o();
  p();
  q();
}
class C extends A {
}''', [
      error(
          StaticWarningCode
              .NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_FIVE_PLUS,
          62,
          1),
    ]);
  }

  test_nonAbstractClassInheritsAbstractMemberFour() async {
    await assertErrorsInCode('''
abstract class A {
  m();
  n();
  o();
  p();
}
class C extends A {
}''', [
      error(StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_FOUR,
          55, 1),
    ]);
  }

  test_nonAbstractClassInheritsAbstractMemberOne_classTypeAlias_interface() async {
    // 15979
    await assertErrorsInCode('''
abstract class M {}
abstract class A {}
abstract class I {
  m();
}
class B = A with M implements I;''', [
      error(StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE,
          74, 1),
    ]);
  }

  test_nonAbstractClassInheritsAbstractMemberOne_classTypeAlias_mixin() async {
    // 15979
    await assertErrorsInCode('''
abstract class M {
  m();
}
abstract class A {}
class B = A with M;''', [
      error(StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE,
          54, 1),
    ]);
  }

  test_nonAbstractClassInheritsAbstractMemberOne_classTypeAlias_superclass() async {
    // 15979
    await assertErrorsInCode('''
class M {}
abstract class A {
  m();
}
class B = A with M;''', [
      error(StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE,
          45, 1),
    ]);
  }

  test_nonAbstractClassInheritsAbstractMemberOne_ensureCorrectFunctionSubtypeIsUsedInImplementation() async {
    // 15028
    await assertErrorsInCode('''
class C {
  foo(int x) => x;
}
abstract class D {
  foo(x, [y]);
}
class E extends C implements D {}''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 73, 1),
    ]);
  }

  test_nonAbstractClassInheritsAbstractMemberOne_getter_fromInterface() async {
    await assertErrorsInCode('''
class I {
  int get g {return 1;}
}
class C implements I {
}''', [
      error(StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE,
          42, 1),
    ]);
  }

  test_nonAbstractClassInheritsAbstractMemberOne_getter_fromSuperclass() async {
    await assertErrorsInCode('''
abstract class A {
  int get g;
}
class C extends A {
}''', [
      error(StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE,
          40, 1),
    ]);
  }

  test_nonAbstractClassInheritsAbstractMemberOne_method_fromInterface() async {
    await assertErrorsInCode('''
class I {
  m(p) {}
}
class C implements I {
}''', [
      error(StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE,
          28, 1),
    ]);
  }

  test_nonAbstractClassInheritsAbstractMemberOne_method_fromInterface_abstractNSM() async {
    await assertErrorsInCode('''
class I {
  m(p) {}
}
class C implements I {
  noSuchMethod(v);
}''', [
      error(StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE,
          28, 1),
    ]);
  }

  test_nonAbstractClassInheritsAbstractMemberOne_method_fromInterface_abstractOverrideNSM() async {
    await assertNoErrorsInCode('''
class I {
  m(p) {}
}
class B {
  noSuchMethod(v) => null;
}
class C extends B implements I {
  noSuchMethod(v);
}''');
  }

  test_nonAbstractClassInheritsAbstractMemberOne_method_fromInterface_ifcNSM() async {
    await assertErrorsInCode('''
class I {
  m(p) {}
  noSuchMethod(v) => null;
}
class C implements I {
}''', [
      error(StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE,
          55, 1),
    ]);
  }

  test_nonAbstractClassInheritsAbstractMemberOne_method_fromSuperclass() async {
    await assertErrorsInCode('''
abstract class A {
  m(p);
}
class C extends A {
}''', [
      error(StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE,
          35, 1),
    ]);
  }

  test_nonAbstractClassInheritsAbstractMemberOne_method_optionalParamCount() async {
    // 7640
    await assertErrorsInCode('''
abstract class A {
  int x(int a);
}
abstract class B {
  int x(int a, [int b]);
}
class C implements A, B {
}''', [
      error(StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE,
          89, 1),
    ]);
  }

  test_nonAbstractClassInheritsAbstractMemberOne_mixinInherits_getter() async {
    // 15001
    await assertErrorsInCode('''
abstract class A { get g1; get g2; }
abstract class B implements A { get g1 => 1; }
class C extends Object with B {}''', [
      error(StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE,
          90, 1),
    ]);
  }

  test_nonAbstractClassInheritsAbstractMemberOne_mixinInherits_method() async {
    // 15001
    await assertErrorsInCode('''
abstract class A { m1(); m2(); }
abstract class B implements A { m1() => 1; }
class C extends Object with B {}''', [
      error(StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE,
          84, 1),
    ]);
  }

  test_nonAbstractClassInheritsAbstractMemberOne_mixinInherits_setter() async {
    // 15001
    await assertErrorsInCode('''
abstract class A { set s1(v); set s2(v); }
abstract class B implements A { set s1(v) {} }
class C extends Object with B {}''', [
      error(StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE,
          96, 1),
    ]);
  }

  test_nonAbstractClassInheritsAbstractMemberOne_noSuchMethod_interface() async {
    // 15979
    await assertErrorsInCode('''
class I {
  noSuchMethod(v) => '';
}
abstract class A {
  m();
}
class B extends A implements I {
}''', [
      error(StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE,
          71, 1),
    ]);
  }

  test_nonAbstractClassInheritsAbstractMemberOne_setter_and_implicitSetter() async {
    // test from language/override_inheritance_abstract_test_14.dart
    await assertErrorsInCode('''
abstract class A {
  set field(_);
}
abstract class I {
  var field;
}
class B extends A implements I {
  get field => 0;
}''', [
      error(StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE,
          77, 1),
    ]);
  }

  test_nonAbstractClassInheritsAbstractMemberOne_setter_fromInterface() async {
    await assertErrorsInCode('''
class I {
  set s(int i) {}
}
class C implements I {
}''', [
      error(StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE,
          36, 1),
    ]);
  }

  test_nonAbstractClassInheritsAbstractMemberOne_setter_fromSuperclass() async {
    await assertErrorsInCode('''
abstract class A {
  set s(int i);
}
class C extends A {
}''', [
      error(StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE,
          43, 1),
    ]);
  }

  test_nonAbstractClassInheritsAbstractMemberOne_superclasses_interface() async {
    // bug 11154
    await assertErrorsInCode('''
class A {
  get a => 'a';
}
abstract class B implements A {
  get b => 'b';
}
class C extends B {
}''', [
      error(StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE,
          84, 1),
    ]);
  }

  test_nonAbstractClassInheritsAbstractMemberOne_variable_fromInterface_missingGetter() async {
    // 16133
    await assertErrorsInCode('''
class I {
  var v;
}
class C implements I {
  set v(_) {}
}''', [
      error(StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE,
          27, 1),
    ]);
  }

  test_nonAbstractClassInheritsAbstractMemberOne_variable_fromInterface_missingSetter() async {
    // 16133
    await assertErrorsInCode('''
class I {
  var v;
}
class C implements I {
  get v => 1;
}''', [
      error(StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE,
          27, 1),
    ]);
  }

  test_nonAbstractClassInheritsAbstractMemberThree() async {
    await assertErrorsInCode('''
abstract class A {
  m();
  n();
  o();
}
class C extends A {
}''', [
      error(StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_THREE,
          48, 1),
    ]);
  }

  test_nonAbstractClassInheritsAbstractMemberTwo() async {
    await assertErrorsInCode('''
abstract class A {
  m();
  n();
}
class C extends A {
}''', [
      error(StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_TWO,
          41, 1),
    ]);
  }

  test_nonAbstractClassInheritsAbstractMemberTwo_variable_fromInterface_missingBoth() async {
    // 16133
    await assertErrorsInCode('''
class I {
  var v;
}
class C implements I {
}''', [
      error(StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_TWO,
          27, 1),
    ]);
  }

  test_nonTypeInCatchClause_noElement() async {
    await assertErrorsInCode('''
f() {
  try {
  } on T catch (e) {
  }
}''', [
      error(StaticWarningCode.NON_TYPE_IN_CATCH_CLAUSE, 21, 1),
      error(HintCode.UNUSED_CATCH_CLAUSE, 30, 1),
    ]);
  }

  test_nonTypeInCatchClause_notType() async {
    await assertErrorsInCode('''
var T = 0;
f() {
  try {
  } on T catch (e) {
  }
}''', [
      error(StaticWarningCode.NON_TYPE_IN_CATCH_CLAUSE, 32, 1),
      error(HintCode.UNUSED_CATCH_CLAUSE, 41, 1),
    ]);
  }

  test_nonVoidReturnForOperator() async {
    await assertErrorsInCode('''
class A {
  int operator []=(a, b) { return a; }
}''', [
      error(StaticWarningCode.NON_VOID_RETURN_FOR_OPERATOR, 12, 3),
    ]);
  }

  test_nonVoidReturnForSetter_function() async {
    await assertErrorsInCode('''
int set x(int v) {
  return 42;
}''', [
      error(StaticWarningCode.NON_VOID_RETURN_FOR_SETTER, 0, 3),
    ]);
  }

  test_nonVoidReturnForSetter_method() async {
    await assertErrorsInCode('''
class A {
  int set x(int v) {
    return 42;
  }
}''', [
      error(StaticWarningCode.NON_VOID_RETURN_FOR_SETTER, 12, 3),
    ]);
  }

  test_notAType() async {
    await assertErrorsInCode('''
f() {}
main() {
  f v = null;
}''', [
      error(StaticWarningCode.NOT_A_TYPE, 18, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 20, 1),
    ]);
  }

  test_notEnoughRequiredArguments() async {
    await assertErrorsInCode('''
f(int a, String b) {}
main() {
  f();
}''', [
      error(StaticWarningCode.NOT_ENOUGH_REQUIRED_ARGUMENTS, 34, 2),
    ]);
  }

  test_notEnoughRequiredArguments_functionExpression() async {
    await assertErrorsInCode('''
main() {
  (int x) {} ();
}''', [
      error(StaticWarningCode.NOT_ENOUGH_REQUIRED_ARGUMENTS, 22, 2),
    ]);
  }

  test_notEnoughRequiredArguments_getterReturningFunction() async {
    await assertErrorsInCode('''
typedef Getter(self);
Getter getter = (x) => x;
main() {
  getter();
}''', [
      error(StaticWarningCode.NOT_ENOUGH_REQUIRED_ARGUMENTS, 65, 2),
    ]);
  }

  test_partOfDifferentLibrary() async {
    newFile("/test/lib/part.dart", content: "part of lub;");
    await assertErrorsInCode('''
library lib;
part 'part.dart';''', [
      error(StaticWarningCode.PART_OF_DIFFERENT_LIBRARY, 18, 11),
    ]);
  }

  test_redirectToInvalidFunctionType() async {
    await assertErrorsInCode('''
class A implements B {
  A(int p) {}
}
class B {
  factory B() = A;
}''', [
      error(StaticWarningCode.REDIRECT_TO_INVALID_FUNCTION_TYPE, 65, 1),
    ]);
  }

  test_redirectToInvalidReturnType() async {
    await assertErrorsInCode('''
class A {
  A() {}
}
class B {
  factory B() = A;
}''', [
      error(StaticWarningCode.REDIRECT_TO_INVALID_RETURN_TYPE, 47, 1),
    ]);
  }

  test_redirectToMissingConstructor_named() async {
    await assertErrorsInCode('''
class A implements B{
  A() {}
}
class B {
  factory B() = A.name;
}''', [
      error(StaticWarningCode.REDIRECT_TO_MISSING_CONSTRUCTOR, 59, 6),
    ]);
  }

  test_redirectToMissingConstructor_unnamed() async {
    await assertErrorsInCode('''
class A implements B{
  A.name() {}
}
class B {
  factory B() = A;
}''', [
      error(StaticWarningCode.REDIRECT_TO_MISSING_CONSTRUCTOR, 64, 1),
    ]);
  }

  test_redirectToNonClass_notAType() async {
    await assertErrorsInCode('''
class B {
  int A;
  factory B() = A;
}''', [
      error(StaticWarningCode.REDIRECT_TO_NON_CLASS, 35, 1),
    ]);
  }

  test_redirectToNonClass_undefinedIdentifier() async {
    await assertErrorsInCode('''
class B {
  factory B() = A;
}''', [
      error(StaticWarningCode.REDIRECT_TO_NON_CLASS, 26, 1),
    ]);
  }

  test_returnWithoutValue_async() async {
    await assertErrorsInCode('''
import 'dart:async';
Future<int> f() async {
  return;
}
''', [
      error(StaticWarningCode.RETURN_WITHOUT_VALUE, 47, 7),
    ]);
  }

  test_returnWithoutValue_async_future_object_with_return() async {
    await assertErrorsInCode('''
import 'dart:async';
Future<Object> f() async {
  return;
}
''', [
      error(StaticWarningCode.RETURN_WITHOUT_VALUE, 50, 7),
    ]);
  }

  test_returnWithoutValue_factoryConstructor() async {
    await assertErrorsInCode('''
class A { factory A() { return; } }
''', [
      error(StaticWarningCode.RETURN_WITHOUT_VALUE, 24, 7),
    ]);
  }

  test_returnWithoutValue_function() async {
    await assertErrorsInCode('''
int f() { return; }
''', [
      error(StaticWarningCode.RETURN_WITHOUT_VALUE, 10, 7),
    ]);
  }

  test_returnWithoutValue_method() async {
    await assertErrorsInCode('''
class A { int m() { return; } }
''', [
      error(StaticWarningCode.RETURN_WITHOUT_VALUE, 20, 7),
    ]);
  }

  test_returnWithoutValue_mixedReturnTypes_function() async {
    // Tests that only the RETURN_WITHOUT_VALUE warning is created, and no
    // MIXED_RETURN_TYPES are created.
    await assertErrorsInCode('''
int f(int x) {
  if (x < 0) {
    return 1;
  }
  return;
}''', [
      error(StaticWarningCode.RETURN_WITHOUT_VALUE, 50, 7),
    ]);
  }

  test_returnWithoutValue_Null() async {
    // Test that block bodied functions with return type Null and an empty
    // return cause a static warning.
    await assertNoErrorsInCode('''
Null f() {return;}
''');
  }

  test_staticAccessToInstanceMember_method_invocation() async {
    await assertErrorsInCode('''
class A {
  m() {}
}
main() {
  A.m();
}''', [
      error(StaticWarningCode.STATIC_ACCESS_TO_INSTANCE_MEMBER, 34, 1),
    ]);
  }

  test_staticAccessToInstanceMember_method_reference() async {
    await assertErrorsInCode('''
class A {
  m() {}
}
main() {
  A.m;
}''', [
      error(StaticWarningCode.STATIC_ACCESS_TO_INSTANCE_MEMBER, 34, 1),
    ]);
  }

  test_staticAccessToInstanceMember_propertyAccess_field() async {
    await assertErrorsInCode('''
class A {
  var f;
}
main() {
  A.f;
}''', [
      error(StaticWarningCode.STATIC_ACCESS_TO_INSTANCE_MEMBER, 34, 1),
    ]);
  }

  test_staticAccessToInstanceMember_propertyAccess_getter() async {
    await assertErrorsInCode('''
class A {
  get f => 42;
}
main() {
  A.f;
}''', [
      error(StaticWarningCode.STATIC_ACCESS_TO_INSTANCE_MEMBER, 40, 1),
    ]);
  }

  test_staticAccessToInstanceMember_propertyAccess_setter() async {
    await assertErrorsInCode('''
class A {
  set f(x) {}
}
main() {
  A.f = 42;
}''', [
      error(StaticWarningCode.STATIC_ACCESS_TO_INSTANCE_MEMBER, 39, 1),
    ]);
  }

  test_switchExpressionNotAssignable() async {
    await assertErrorsInCode('''
f(int p) {
  switch (p) {
    case 'a': break;
  }
}''', [
      error(StaticWarningCode.SWITCH_EXPRESSION_NOT_ASSIGNABLE, 21, 1),
    ]);
  }

  test_typeAnnotationDeferredClass_asExpression() async {
    newFile("/test/lib/lib1.dart", content: '''
library lib1;
class A {}''');
    await assertErrorsInCode('''
library root;
import 'lib1.dart' deferred as a;
f(var v) {
  v as a.A;
}''', [
      error(StaticWarningCode.TYPE_ANNOTATION_DEFERRED_CLASS, 66, 3),
    ]);
  }

  test_typeAnnotationDeferredClass_catchClause() async {
    newFile("/test/lib/lib1.dart", content: '''
library lib1;
class A {}''');
    await assertErrorsInCode('''
library root;
import 'lib1.dart' deferred as a;
f(var v) {
  try {
  } on a.A {
  }
}''', [
      error(StaticWarningCode.TYPE_ANNOTATION_DEFERRED_CLASS, 74, 3),
    ]);
  }

  test_typeAnnotationDeferredClass_fieldFormalParameter() async {
    newFile("/test/lib/lib1.dart", content: '''
library lib1;
class A {}''');
    await assertErrorsInCode('''
library root;
import 'lib1.dart' deferred as a;
class C {
  var v;
  C(a.A this.v);
}''', [
      error(StaticWarningCode.TYPE_ANNOTATION_DEFERRED_CLASS, 71, 3),
    ]);
  }

  test_typeAnnotationDeferredClass_functionDeclaration_returnType() async {
    newFile("/test/lib/lib1.dart", content: '''
library lib1;
class A {}''');
    await assertErrorsInCode('''
library root;
import 'lib1.dart' deferred as a;
a.A f() { return null; }''', [
      error(StaticWarningCode.TYPE_ANNOTATION_DEFERRED_CLASS, 48, 3),
    ]);
  }

  test_typeAnnotationDeferredClass_functionTypedFormalParameter_returnType() async {
    newFile("/test/lib/lib1.dart", content: '''
library lib1;
class A {}''');
    await assertErrorsInCode('''
library root;
import 'lib1.dart' deferred as a;
f(a.A g()) {}''', [
      error(StaticWarningCode.TYPE_ANNOTATION_DEFERRED_CLASS, 50, 3),
    ]);
  }

  test_typeAnnotationDeferredClass_isExpression() async {
    newFile("/test/lib/lib1.dart", content: '''
library lib1;
class A {}''');
    await assertErrorsInCode('''
library root;
import 'lib1.dart' deferred as a;
f(var v) {
  bool b = v is a.A;
}''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 66, 1),
      error(StaticWarningCode.TYPE_ANNOTATION_DEFERRED_CLASS, 75, 3),
    ]);
  }

  test_typeAnnotationDeferredClass_methodDeclaration_returnType() async {
    newFile("/test/lib/lib1.dart", content: '''
library lib1;
class A {}''');
    await assertErrorsInCode('''
library root;
import 'lib1.dart' deferred as a;
class C {
  a.A m() { return null; }
}''', [
      error(StaticWarningCode.TYPE_ANNOTATION_DEFERRED_CLASS, 60, 3),
    ]);
  }

  test_typeAnnotationDeferredClass_simpleFormalParameter() async {
    newFile("/test/lib/lib1.dart", content: '''
library lib1;
class A {}''');
    await assertErrorsInCode('''
library root;
import 'lib1.dart' deferred as a;
f(a.A v) {}''', [
      error(StaticWarningCode.TYPE_ANNOTATION_DEFERRED_CLASS, 50, 3),
    ]);
  }

  test_typeAnnotationDeferredClass_typeArgumentList() async {
    newFile("/test/lib/lib1.dart", content: '''
library lib1;
class A {}''');
    await assertErrorsInCode('''
library root;
import 'lib1.dart' deferred as a;
class C<E> {}
C<a.A> c;''', [
      error(StaticWarningCode.TYPE_ANNOTATION_DEFERRED_CLASS, 64, 3),
    ]);
  }

  test_typeAnnotationDeferredClass_typeArgumentList2() async {
    newFile("/test/lib/lib1.dart", content: '''
library lib1;
class A {}''');
    await assertErrorsInCode('''
library root;
import 'lib1.dart' deferred as a;
class C<E, F> {}
C<a.A, a.A> c;''', [
      error(StaticWarningCode.TYPE_ANNOTATION_DEFERRED_CLASS, 67, 3),
      error(StaticWarningCode.TYPE_ANNOTATION_DEFERRED_CLASS, 72, 3),
    ]);
  }

  test_typeAnnotationDeferredClass_typeParameter_bound() async {
    newFile("/test/lib/lib1.dart", content: '''
library lib1;
class A {}''');
    await assertErrorsInCode('''
library root;
import 'lib1.dart' deferred as a;
class C<E extends a.A> {}''', [
      error(StaticWarningCode.TYPE_ANNOTATION_DEFERRED_CLASS, 66, 3),
    ]);
  }

  test_typeAnnotationDeferredClass_variableDeclarationList() async {
    newFile("/test/lib/lib1.dart", content: '''
library lib1;
class A {}''');
    await assertErrorsInCode('''
library root;
import 'lib1.dart' deferred as a;
a.A v;''', [
      error(StaticWarningCode.TYPE_ANNOTATION_DEFERRED_CLASS, 48, 3),
    ]);
  }

  test_typeParameterReferencedByStatic_field() async {
    await assertErrorsInCode('''
class A<K> {
  static K k;
}''', [
      error(StaticWarningCode.TYPE_PARAMETER_REFERENCED_BY_STATIC, 22, 1),
    ]);
  }

  test_typeParameterReferencedByStatic_getter() async {
    await assertErrorsInCode('''
class A<K> {
  static K get k => null;
}''', [
      error(StaticWarningCode.TYPE_PARAMETER_REFERENCED_BY_STATIC, 22, 1),
    ]);
  }

  test_typeParameterReferencedByStatic_methodBodyReference() async {
    await assertErrorsInCode('''
class A<K> {
  static m() {
    K k;
  }
}''', [
      error(StaticWarningCode.TYPE_PARAMETER_REFERENCED_BY_STATIC, 32, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 34, 1),
    ]);
  }

  test_typeParameterReferencedByStatic_methodParameter() async {
    await assertErrorsInCode('''
class A<K> {
  static m(K k) {}
}''', [
      error(StaticWarningCode.TYPE_PARAMETER_REFERENCED_BY_STATIC, 24, 1),
    ]);
  }

  test_typeParameterReferencedByStatic_methodReturn() async {
    await assertErrorsInCode('''
class A<K> {
  static K m() { return null; }
}''', [
      error(StaticWarningCode.TYPE_PARAMETER_REFERENCED_BY_STATIC, 22, 1),
    ]);
  }

  test_typeParameterReferencedByStatic_setter() async {
    await assertErrorsInCode('''
class A<K> {
  static set s(K k) {}
}''', [
      error(StaticWarningCode.TYPE_PARAMETER_REFERENCED_BY_STATIC, 28, 1),
    ]);
  }

  test_typeParameterReferencedByStatic_simpleIdentifier() async {
    await assertErrorsInCode('''
class A<T> {
  static foo() {
    T;
  }
}
''', [
      error(StaticWarningCode.TYPE_PARAMETER_REFERENCED_BY_STATIC, 34, 1),
    ]);
  }

  test_typePromotion_functionType_arg_InterToDyn() async {
    await assertNoErrorsInCode('''
typedef FuncDyn(x);
typedef FuncA(A a);
class A {}
class B {}
main(FuncA f) {
  if (f is FuncDyn) {
    f(new B());
  }
}''');
  }

  test_typeTestNonType() async {
    await assertErrorsInCode('''
var A = 0;
f(var p) {
  if (p is A) {
  }
}''', [
      error(StaticWarningCode.TYPE_TEST_WITH_NON_TYPE, 33, 1),
    ]);
  }

  test_typeTestWithUndefinedName() async {
    await assertErrorsInCode('''
f(var p) {
  if (p is A) {
  }
}''', [
      error(StaticWarningCode.TYPE_TEST_WITH_UNDEFINED_NAME, 22, 1),
    ]);
  }

  test_undefinedClass_instanceCreation() async {
    await assertErrorsInCode('''
f() { new C(); }
''', [
      error(StaticWarningCode.UNDEFINED_CLASS, 10, 1),
    ]);
  }

  test_undefinedClass_variableDeclaration() async {
    await assertErrorsInCode('''
f() { C c; }
''', [
      error(StaticWarningCode.UNDEFINED_CLASS, 6, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 8, 1),
    ]);
  }

  test_undefinedClassBoolean_variableDeclaration() async {
    await assertErrorsInCode('''
f() { boolean v; }
''', [
      error(StaticWarningCode.UNDEFINED_CLASS_BOOLEAN, 6, 7),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 14, 1),
    ]);
  }

  @failingTest
  test_undefinedIdentifier_commentReference() async {
    await assertErrorsInCode('''
/** [m] xxx [new B.c] */
class A {
}''', [
      error(StaticWarningCode.UNDEFINED_IDENTIFIER, 5, 1),
      error(StaticWarningCode.UNDEFINED_IDENTIFIER, 17, 1),
    ]);
  }

  test_undefinedIdentifier_for() async {
    await assertErrorsInCode('''
f(var l) {
  for (e in l) {
  }
}''', [
      error(StaticWarningCode.UNDEFINED_IDENTIFIER, 18, 1),
    ]);
  }

  test_undefinedIdentifier_function() async {
    await assertErrorsInCode('''
int a() => b;
''', [
      error(StaticWarningCode.UNDEFINED_IDENTIFIER, 11, 1),
    ]);
  }

  test_undefinedIdentifier_importCore_withShow() async {
    await assertErrorsInCode('''
import 'dart:core' show List;
main() {
  List;
  String;
}''', [
      error(StaticWarningCode.UNDEFINED_IDENTIFIER, 49, 6),
    ]);
  }

  test_undefinedIdentifier_initializer() async {
    await assertErrorsInCode('''
var a = b;
''', [
      error(StaticWarningCode.UNDEFINED_IDENTIFIER, 8, 1),
    ]);
  }

  test_undefinedIdentifier_methodInvocation() async {
    await assertErrorsInCode('''
f() { C.m(); }
''', [
      error(StaticWarningCode.UNDEFINED_IDENTIFIER, 6, 1),
    ]);
  }

  test_undefinedIdentifier_private_getter() async {
    newFile("/test/lib/lib.dart", content: '''
library lib;
class A {
  var _foo;
}''');
    await assertErrorsInCode('''
import 'lib.dart';
class B extends A {
  test() {
    var v = _foo;
  }
}''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 58, 1),
      error(StaticWarningCode.UNDEFINED_IDENTIFIER, 62, 4),
    ]);
  }

  test_undefinedIdentifier_private_setter() async {
    newFile("/test/lib/lib.dart", content: '''
library lib;
class A {
  var _foo;
}''');
    await assertErrorsInCode('''
import 'lib.dart';
class B extends A {
  test() {
    _foo = 42;
  }
}''', [
      error(StaticWarningCode.UNDEFINED_IDENTIFIER, 54, 4),
    ]);
  }

  test_undefinedIdentifierAwait_function() async {
    await assertErrorsInCode('''
void a() { await; }
''', [
      error(StaticWarningCode.UNDEFINED_IDENTIFIER_AWAIT, 11, 5),
    ]);
  }

  test_undefinedNamedParameter() async {
    await assertErrorsInCode('''
f({a, b}) {}
main() {
  f(c: 1);
}''', [
      error(StaticWarningCode.UNDEFINED_NAMED_PARAMETER, 26, 1),
    ]);
  }

  test_undefinedStaticMethodOrGetter_getter() async {
    await assertErrorsInCode('''
class C {}
f(var p) {
  f(C.m);
}''', [
      error(StaticTypeWarningCode.UNDEFINED_GETTER, 28, 1),
    ]);
  }

  test_undefinedStaticMethodOrGetter_getter_inSuperclass() async {
    await assertErrorsInCode('''
class S {
  static int get g => 0;
}
class C extends S {}
f(var p) {
  f(C.g);
}''', [
      error(StaticTypeWarningCode.UNDEFINED_GETTER, 75, 1),
    ]);
  }

  test_undefinedStaticMethodOrGetter_setter_inSuperclass() async {
    await assertErrorsInCode('''
class S {
  static set s(int i) {}
}
class C extends S {}
f(var p) {
  f(C.s = 1);
}''', [
      error(StaticTypeWarningCode.UNDEFINED_SETTER, 75, 1),
    ]);
  }

  test_useOfVoidResult_assignmentExpression_function() async {
    await assertErrorsInCode('''
void f() {}
class A {
  n() {
    var a;
    a = f();
  }
}''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 38, 1),
      error(StaticWarningCode.USE_OF_VOID_RESULT, 49, 1),
    ]);
  }

  test_useOfVoidResult_assignmentExpression_method() async {
    await assertErrorsInCode('''
class A {
  void m() {}
  n() {
    var a;
    a = m();
  }
}''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 40, 1),
      error(StaticWarningCode.USE_OF_VOID_RESULT, 51, 1),
    ]);
  }

  test_useOfVoidResult_await() async {
    await assertNoErrorsInCode('''
main() async {
  void x;
  await x;
}''');
  }

  test_useOfVoidResult_inForLoop_error() async {
    await assertErrorsInCode('''
class A {
  void m() {}
  n() {
    for(Object a = m();;) {}
  }
}''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 47, 1),
      error(StaticWarningCode.USE_OF_VOID_RESULT, 51, 1),
    ]);
  }

  test_useOfVoidResult_inForLoop_ok() async {
    await assertNoErrorsInCode('''
class A {
  void m() {}
  n() {
    for(void a = m();;) {}
  }
}''');
  }

  test_useOfVoidResult_variableDeclaration_function_error() async {
    await assertErrorsInCode('''
void f() {}
class A {
  n() {
    Object a = f();
  }
}''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 41, 1),
      error(StaticWarningCode.USE_OF_VOID_RESULT, 45, 1),
    ]);
  }

  test_useOfVoidResult_variableDeclaration_function_ok() async {
    await assertNoErrorsInCode('''
void f() {}
class A {
  n() {
    void a = f();
  }
}''');
  }

  test_useOfVoidResult_variableDeclaration_method2() async {
    await assertErrorsInCode('''
class A {
  void m() {}
  n() {
    Object a = m(), b = m();
  }
}''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 43, 1),
      error(StaticWarningCode.USE_OF_VOID_RESULT, 47, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 52, 1),
      error(StaticWarningCode.USE_OF_VOID_RESULT, 56, 1),
    ]);
  }

  test_useOfVoidResult_variableDeclaration_method_error() async {
    await assertErrorsInCode('''
class A {
  void m() {}
  n() {
    Object a = m();
  }
}''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 43, 1),
      error(StaticWarningCode.USE_OF_VOID_RESULT, 47, 1),
    ]);
  }

  test_useOfVoidResult_variableDeclaration_method_ok() async {
    await assertNoErrorsInCode('''
class A {
  void m() {}
  n() {
    void a = m();
  }
}''');
  }

  test_voidReturnForGetter() async {
    await assertNoErrorsInCode('''
class S {
  void get value {}
}''');
  }
}
