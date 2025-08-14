// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstConstructorWithNonConstSuperTest);
  });
}

@reflectiveTest
class ConstConstructorWithNonConstSuperTest extends PubPackageResolutionTest {
  test_class_explicit() async {
    await assertErrorsInCode(
      r'''
class A {
  A();
}
class B extends A {
  const B(): super();
}
''',
      [error(CompileTimeErrorCode.constConstructorWithNonConstSuper, 52, 7)],
    );
  }

  test_class_implicit() async {
    await assertErrorsInCode(
      r'''
class A {
  A();
}
class B extends A {
  const B();
}
''',
      [error(CompileTimeErrorCode.constConstructorWithNonConstSuper, 47, 1)],
    );
  }

  test_class_redirectConst_superConst() async {
    await assertNoErrorsInCode(r'''
class A {
  factory A() = A._;
  const A._();
}

class B extends A {
  const B.foo() : this.bar();
  const B.bar() : super._();
}
''');
  }

  test_class_redirectConst_superNotConst() async {
    await assertErrorsInCode(
      r'''
class A {
  factory A() = A._;
  A._();
}

class B extends A {
  const B.foo() : this.bar();
  const B.bar() : super._();
}
''',
      [error(CompileTimeErrorCode.constConstructorWithNonConstSuper, 111, 9)],
    );
  }

  test_enum() async {
    await assertNoErrorsInCode(r'''
enum E {
  v
}
''');
  }

  test_enum_hasConstructor() async {
    await assertNoErrorsInCode(r'''
enum E {
  v(0);
  const E(int a);
}
''');
  }
}
