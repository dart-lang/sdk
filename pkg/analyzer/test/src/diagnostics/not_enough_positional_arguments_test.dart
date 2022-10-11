// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NotEnoughPositionalArgumentsTest);
  });
}

@reflectiveTest
class NotEnoughPositionalArgumentsTest extends PubPackageResolutionTest {
  test_annotation_named() async {
    await assertErrorsInCode(r'''
class A {
  const A.named(int p);
}
@A.named()
void f() {
}
''', [
      error(CompileTimeErrorCode.NOT_ENOUGH_POSITIONAL_ARGUMENTS_NAME_SINGULAR,
          45, 1,
          messageContains: ["expected by 'named'"]),
    ]);
  }

  test_annotation_withArgumentList() async {
    await assertErrorsInCode(r'''
class A {
  const A(int p);
}
@A()
void f() {
}
''', [
      error(CompileTimeErrorCode.NOT_ENOUGH_POSITIONAL_ARGUMENTS_NAME_SINGULAR,
          33, 1,
          messageContains: ["expected by 'A.new'"]),
    ]);
  }

  test_annotation_withoutArgumentList() async {
    await assertErrorsInCode(r'''
class A {
  const A(int p);
}
const a = A();
@a
void f() {
}
''', [
      error(CompileTimeErrorCode.CONST_CONSTRUCTOR_PARAM_TYPE_MISMATCH, 40, 3),
      error(CompileTimeErrorCode.NOT_ENOUGH_POSITIONAL_ARGUMENTS_NAME_SINGULAR,
          42, 1,
          messageContains: ["expected by 'A.new'"]),
    ]);
  }

  test_const() async {
    await assertErrorsInCode(r'''
class A {
  const A(int p);
}
main() {
  const A();
}
''', [
      error(CompileTimeErrorCode.CONST_CONSTRUCTOR_PARAM_TYPE_MISMATCH, 41, 9),
      error(CompileTimeErrorCode.NOT_ENOUGH_POSITIONAL_ARGUMENTS_NAME_SINGULAR,
          49, 1,
          messageContains: ["expected by 'A.new'"]),
    ]);
  }

  test_const_namedArgument_insteadOfRequiredPositional() async {
    await assertErrorsInCode(r'''
class A {
  const A(int p);
}
main() {
  const A(p: 0);
}
''', [
      error(CompileTimeErrorCode.CONST_CONSTRUCTOR_PARAM_TYPE_MISMATCH, 41, 13),
      error(CompileTimeErrorCode.NOT_ENOUGH_POSITIONAL_ARGUMENTS_NAME_SINGULAR,
          49, 1),
      error(CompileTimeErrorCode.UNDEFINED_NAMED_PARAMETER, 49, 1),
    ]);
  }

  test_const_super() async {
    await assertErrorsInCode(r'''
class A {
  const A(int p);
}
class B extends A {
  const B() : super();
}
''', [
      error(CompileTimeErrorCode.NOT_ENOUGH_POSITIONAL_ARGUMENTS_NAME_SINGULAR,
          70, 1,
          messageContains: ["expected by 'A.new'"]),
    ]);
  }

  test_const_super_named() async {
    await assertErrorsInCode(r'''
class A {
  const A.named(int p);
}
class B extends A {
  const B() : super.named();
}
''', [
      error(CompileTimeErrorCode.NOT_ENOUGH_POSITIONAL_ARGUMENTS_NAME_SINGULAR,
          82, 1,
          messageContains: ["expected by 'named'"]),
    ]);
  }

  test_constructor_named() async {
    await assertErrorsInCode(r'''
class A {
  A.named(int x, int y, {int? n});
}

void f() {
  A.named(5, n: 1);
}
''', [
      error(CompileTimeErrorCode.NOT_ENOUGH_POSITIONAL_ARGUMENTS_NAME_SINGULAR,
          70, 1,
          messageContains: ["expected by 'named'"]),
    ]);
  }

  test_constructor_positionalAndNamed() async {
    await assertErrorsInCode(r'''
class A {
  A(int x, int y, {int? n});
}

void f() {
  A(5, n: 1);
}
''', [
      error(CompileTimeErrorCode.NOT_ENOUGH_POSITIONAL_ARGUMENTS_NAME_SINGULAR,
          58, 1,
          messageContains: ["expected by 'A.new'"]),
    ]);
  }

  test_enumConstant_withArgumentList() async {
    await assertErrorsInCode(r'''
enum E {
  v();
  const E(int a);
}
''', [
      error(CompileTimeErrorCode.CONST_CONSTRUCTOR_PARAM_TYPE_MISMATCH, 11, 3),
      error(CompileTimeErrorCode.NOT_ENOUGH_POSITIONAL_ARGUMENTS_NAME_SINGULAR,
          13, 1,
          messageContains: ["expected by 'E'"]),
    ]);
  }

  test_enumConstant_withoutArgumentList() async {
    await assertErrorsInCode(r'''
enum E {
  v;
  const E(int a);
}
''', [
      error(CompileTimeErrorCode.CONST_CONSTRUCTOR_PARAM_TYPE_MISMATCH, 11, 1),
      error(CompileTimeErrorCode.NOT_ENOUGH_POSITIONAL_ARGUMENTS_NAME_SINGULAR,
          11, 1,
          messageContains: ["expected by 'E'"]),
    ]);
  }

  test_functionExpression_plural() async {
    await assertErrorsInCode('''
main() {
  (int x, int y) {} ();
}''', [
      error(CompileTimeErrorCode.NOT_ENOUGH_POSITIONAL_ARGUMENTS_PLURAL, 30, 1),
    ]);
  }

  test_functionExpression_singular() async {
    await assertErrorsInCode('''
main() {
  (int x) {} ();
}''', [
      error(
          CompileTimeErrorCode.NOT_ENOUGH_POSITIONAL_ARGUMENTS_SINGULAR, 23, 1),
    ]);
  }

  test_functionInvocation() async {
    await assertErrorsInCode('''
f(int a, String b) {}
main() {
  f();
}''', [
      error(CompileTimeErrorCode.NOT_ENOUGH_POSITIONAL_ARGUMENTS_NAME_PLURAL,
          35, 1,
          messageContains: ["expected by 'f'"]),
    ]);
  }

  test_getterReturningFunction() async {
    await assertErrorsInCode('''
typedef Getter(self);
Getter getter = (x) => x;
main() {
  getter();
}''', [
      error(CompileTimeErrorCode.NOT_ENOUGH_POSITIONAL_ARGUMENTS_NAME_SINGULAR,
          66, 1,
          messageContains: ["expected by 'getter'"]),
    ]);
  }

  test_superParameter_optional() async {
    await assertNoErrorsInCode(r'''
class A {
  A(int? a);
}

class B extends A {
  B([super.a]) : super();
}
''');
  }

  test_superParameter_required() async {
    await assertNoErrorsInCode(r'''
class A {
  A(int a);
}

class B extends A {
  B(super.a) : super();
}
''');
  }
}
