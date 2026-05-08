// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MultipleRedirectingConstructorInvocationsTest);
  });
}

@reflectiveTest
class MultipleRedirectingConstructorInvocationsTest
    extends PubPackageResolutionTest {
  test_class_primary() async {
    await assertErrorsInCode(
      r'''
class A {}

class B() extends A {
  B.foo() : this();
  B.bar() : this();
  this : this.foo(), this.bar();
}
''',
      [
        error(diag.primaryConstructorCannotRedirect, 83, 4),
        error(diag.primaryConstructorCannotRedirect, 95, 4),
      ],
    );
  }

  test_class_typeName_twoNamed() async {
    await assertErrorsInCode(
      r'''
class A {
  A() : this.foo(), this.bar();
  A.foo() {}
  A.bar() {}
}
''',
      [error(diag.multipleRedirectingConstructorInvocations, 30, 10)],
    );
  }

  test_enum_primary() async {
    await assertErrorsInCode(
      r'''
enum E() {
  v;
  const E.foo() : this();
  const E.bar() : this();
  this : this.foo(), this.bar();
}
''',
      [
        error(diag.recursiveConstantConstructor, 24, 5),
        error(diag.recursiveConstantConstructor, 50, 5),
        error(diag.primaryConstructorCannotRedirect, 77, 4),
        error(diag.primaryConstructorCannotRedirect, 89, 4),
      ],
    );
  }

  test_enum_typeName_twoNamed() async {
    await assertErrorsInCode(
      r'''
enum E {
  v;
  const E() : this.foo(), this.bar();
  const E.foo();
  const E.bar();
}
''',
      [error(diag.multipleRedirectingConstructorInvocations, 40, 10)],
    );
  }
}
