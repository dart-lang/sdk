// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConflictingConstructorAndStaticMethodTest);
  });
}

@reflectiveTest
class ConflictingConstructorAndStaticMethodTest
    extends PubPackageResolutionTest {
  test_class() async {
    await assertErrorsInCode(r'''
class C {
  C.foo();
  static void foo() {}
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_CONSTRUCTOR_AND_STATIC_METHOD, 14,
          3),
    ]);
  }

  test_class_OK_notSameClass() async {
    await assertNoErrorsInCode(r'''
class A {
  static void foo() {}
}
class B extends A {
  B.foo();
}
''');
  }

  test_class_OK_notStatic() async {
    await assertNoErrorsInCode(r'''
class C {
  C.foo();
  void foo() {}
}
''');
  }

  test_enum() async {
    await assertNoErrorsInCode(r'''
enum E {
  v.foo();
  const E.foo(); // _$foo
  static void foo() {}
}
''');
  }
}
