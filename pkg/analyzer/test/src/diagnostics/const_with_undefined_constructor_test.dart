// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstWithUndefinedConstructorTest);
  });
}

@reflectiveTest
class ConstWithUndefinedConstructorTest extends PubPackageResolutionTest {
  test_class_named() async {
    await assertErrorsInCode(r'''
class A {
  const A();
}
f() {
  return const A.noSuchConstructor();
}
''', [
      error(CompileTimeErrorCode.CONST_WITH_UNDEFINED_CONSTRUCTOR, 48, 17,
          messageContains: ["class 'A'", "constructor 'noSuchConstructor'"]),
    ]);
  }

  test_class_named_prefixed() async {
    await assertErrorsInCode(r'''
import 'dart:async' as a;
f() {
  return const a.Future.noSuchConstructor();
}
''', [
      error(CompileTimeErrorCode.CONST_WITH_UNDEFINED_CONSTRUCTOR, 56, 17,
          messageContains: [
            "class 'a.Future'",
            "constructor 'noSuchConstructor'"
          ]),
    ]);
  }

  test_class_nonFunctionTypedef() async {
    await assertErrorsInCode(r'''
class A {
  const A.name();
}
typedef B = A;
f() {
  return const B();
}
''', [
      error(
          CompileTimeErrorCode.CONST_WITH_UNDEFINED_CONSTRUCTOR_DEFAULT, 66, 1),
    ]);
  }

  test_class_unnamed() async {
    await assertErrorsInCode(r'''
class A {
  const A.name();
}
f() {
  return const A();
}
''', [
      error(
          CompileTimeErrorCode.CONST_WITH_UNDEFINED_CONSTRUCTOR_DEFAULT, 51, 1,
          messageContains: ["'A'"]),
    ]);
  }

  test_class_unnamed_prefixed() async {
    newFile('$testPackageLibPath/lib1.dart', '''
class A {
  const A.name();
}
''');
    await assertErrorsInCode(r'''
import 'lib1.dart' as lib1;
f() {
  return const lib1.A();
}
''', [
      error(
          CompileTimeErrorCode.CONST_WITH_UNDEFINED_CONSTRUCTOR_DEFAULT, 49, 6,
          messageContains: ["'lib1.A'"]),
    ]);
  }

  test_enum_notConstructor_constant() async {
    await assertErrorsInCode(r'''
void f() {
  const E.v();
}

enum E {
  v
}
''', [
      error(CompileTimeErrorCode.CONST_WITH_UNDEFINED_CONSTRUCTOR, 21, 1),
    ]);
  }

  test_enum_notConstructor_method() async {
    await assertErrorsInCode(r'''
void f() {
  const E.foo();
}

enum E {
  v;
  
  void foo() {}
}
''', [
      error(CompileTimeErrorCode.CONST_WITH_UNDEFINED_CONSTRUCTOR, 21, 3),
    ]);
  }

  test_enum_unresolved() async {
    await assertErrorsInCode(r'''
void f() {
  const E.foo();
}

enum E {
  v
}
''', [
      error(CompileTimeErrorCode.CONST_WITH_UNDEFINED_CONSTRUCTOR, 21, 3),
    ]);
  }
}
