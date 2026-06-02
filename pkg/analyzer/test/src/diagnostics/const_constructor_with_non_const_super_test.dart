// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
    await resolveTestCodeWithDiagnostics(r'''
class A {}
class B extends A {
  const new(): super();
//             ^^^^^^^
// [diag.constConstructorWithNonConstSuper] A constant constructor can't call a non-constant super constructor of 'A'.
}
''');
  }

  test_class_explicit_constructor_typeName() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
class B extends A {
  const B(): super();
//           ^^^^^^^
// [diag.constConstructorWithNonConstSuper] A constant constructor can't call a non-constant super constructor of 'A'.
}
''');
  }

  test_class_explicit_primaryConstructor_hasBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
class const B() extends A {
  this : super();
//       ^^^^^^^
// [diag.constConstructorWithNonConstSuper] A constant constructor can't call a non-constant super constructor of 'A'.
}
''');
  }

  test_class_implicit_constructor_newHead() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
class B extends A {
  const new();
//      ^^^
// [diag.constConstructorWithNonConstSuper] A constant constructor can't call a non-constant super constructor of 'A'.
}
''');
  }

  test_class_implicit_constructor_typeName() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
class B extends A {
  const B();
//      ^
// [diag.constConstructorWithNonConstSuper] A constant constructor can't call a non-constant super constructor of 'A'.
}
''');
  }

  test_class_implicit_primaryConstructor_hasBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
class const B() extends A {
//    ^^^^^
// [diag.constConstructorWithNonConstSuper] A constant constructor can't call a non-constant super constructor of 'A'.
  this;
}
''');
  }

  test_class_implicit_primaryConstructor_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
class const B() extends A;
//    ^^^^^
// [diag.constConstructorWithNonConstSuper] A constant constructor can't call a non-constant super constructor of 'A'.
''');
  }

  test_class_redirectConst_superConst() async {
    await resolveTestCodeWithDiagnostics(r'''
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
    await resolveTestCodeWithDiagnostics(r'''
class A {
  factory A() = A._;
  A._();
}

class B extends A {
  const B.foo() : this.bar();
  const B.bar() : super._();
//                ^^^^^^^^^
// [diag.constConstructorWithNonConstSuper] A constant constructor can't call a non-constant super constructor of 'A'.
}
''');
  }

  test_enum() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v
}
''');
  }

  test_enum_hasConstructor() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v(0);
  const E(int a);
}
''');
  }
}
