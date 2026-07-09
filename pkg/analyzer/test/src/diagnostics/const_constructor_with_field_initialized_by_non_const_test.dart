// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstConstructorWithFieldInitializedByNonConstTest);
  });
}

@reflectiveTest
class ConstConstructorWithFieldInitializedByNonConstTest
    extends PubPackageResolutionTest {
  test_class_factoryConstructor() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  final List<int> list = f();
  const factory A() = B;
}
class B implements A {
  final List<int> list = const [];
  const B();
}
List<int> f() {
  return [3];
}
''');
  }

  test_class_instanceField() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  final int i = f();
//              ^^^
// [diag.constEvalMethodInvocation] Methods can't be invoked in constant expressions.
  const A();
//^^^^^
// [diag.constConstructorWithFieldInitializedByNonConst] Can't define the 'const' constructor because the field 'i' is initialized with a non-constant value.
}
int f() {
  return 3;
}
''');
  }

  test_class_instanceField_asExpression() async {
    await resolveTestCodeWithDiagnostics(r'''
dynamic y = 2;
class A {
  const A();
//^^^^^
// [diag.constConstructorWithFieldInitializedByNonConst] Can't define the 'const' constructor because the field 'x' is initialized with a non-constant value.
  final x = y as num;
}
''');
  }

  test_class_staticField() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static final int i = f();
  const A();
}
int f() {
  return 3;
}
''');
  }

  //   test_enum_factoryConstructor() async {
  //     await assertErrorsInCode(r'''
  // enum E {
  //   v;
  //   final int i = f();
  //   const factory E();
  // }
  // int f() => 0;
  // ''', [
  //       error(CompileTimeErrorCode.CONST_EVAL_METHOD_INVOCATION, 30, 3),
  //       error(
  //           CompileTimeErrorCode
  //               .CONST_CONSTRUCTOR_WITH_FIELD_INITIALIZED_BY_NON_CONST,
  //           37,
  //           5),
  //     ]);
  //   }

  test_enum_instanceField() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  final int i = f();
//              ^^^
// [diag.constEvalMethodInvocation] Methods can't be invoked in constant expressions.
  const E();
//^^^^^
// [diag.constConstructorWithFieldInitializedByNonConst] Can't define the 'const' constructor because the field 'i' is initialized with a non-constant value.
}
int f() => 0;
''');
  }

  test_enum_staticField() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  static final int i = f();
  const E();
}
int f() => 0;
''');
  }

  test_mixinClass_factory() async {
    await resolveTestCodeWithDiagnostics(r'''
int e = 3;
mixin class MixinClassFactory {
  final int foo = e;
  const factory MixinClassFactory.x() = A;
}

mixin class A implements MixinClassFactory {
  @override
  final int foo = 0;
  const A();
}
''');
  }
}
