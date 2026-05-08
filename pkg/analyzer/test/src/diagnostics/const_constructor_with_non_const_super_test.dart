// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstConstructorWithNonConstSuperTest);
  });
}

@reflectiveTest
class ConstConstructorWithNonConstSuperTest extends PubPackageResolutionTest {
  test_class_explicit_constructor_newHead() async {
    await assertErrorsInCode(
      r'''
class A {}
class B extends A {
  const new(): super();
}
''',
      [error(diag.constConstructorWithNonConstSuper, 46, 7)],
    );
  }

  test_class_explicit_constructor_typeName() async {
    await assertErrorsInCode(
      r'''
class A {}
class B extends A {
  const B(): super();
}
''',
      [error(diag.constConstructorWithNonConstSuper, 44, 7)],
    );
  }

  test_class_explicit_primaryConstructor_hasBody() async {
    await assertErrorsInCode(
      r'''
class A {}
class const B() extends A {
  this : super();
}
''',
      [error(diag.constConstructorWithNonConstSuper, 48, 7)],
    );
  }

  test_class_implicit_constructor_newHead() async {
    await assertErrorsInCode(
      r'''
class A {}
class B extends A {
  const new();
}
''',
      [error(diag.constConstructorWithNonConstSuper, 39, 3)],
    );
  }

  test_class_implicit_constructor_typeName() async {
    await assertErrorsInCode(
      r'''
class A {}
class B extends A {
  const B();
}
''',
      [error(diag.constConstructorWithNonConstSuper, 39, 1)],
    );
  }

  test_class_implicit_primaryConstructor_hasBody() async {
    await assertErrorsInCode(
      r'''
class A {}
class const B() extends A {
  this;
}
''',
      [error(diag.constConstructorWithNonConstSuper, 17, 5)],
    );
  }

  test_class_implicit_primaryConstructor_noBody() async {
    await assertErrorsInCode(
      r'''
class A {}
class const B() extends A;
''',
      [error(diag.constConstructorWithNonConstSuper, 17, 5)],
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
      [error(diag.constConstructorWithNonConstSuper, 111, 9)],
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
