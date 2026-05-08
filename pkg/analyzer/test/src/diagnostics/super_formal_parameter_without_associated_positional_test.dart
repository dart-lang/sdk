// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SuperFormalParameterWithoutAssociatedPositionalTest);
  });
}

@reflectiveTest
class SuperFormalParameterWithoutAssociatedPositionalTest
    extends PubPackageResolutionTest {
  test_class_primary_optionalPositional_01() async {
    await assertErrorsInCode(
      r'''
class A {}

class B([super.a]) extends A {}
''',
      [error(diag.superFormalParameterWithoutAssociatedPositional, 27, 1)],
    );
  }

  test_class_primary_requiredPositional_01() async {
    await assertErrorsInCode(
      r'''
class A {}

class B(super.a) extends A {}
''',
      [error(diag.superFormalParameterWithoutAssociatedPositional, 26, 1)],
    );
  }

  test_class_secondary_optionalPositional_01() async {
    await assertErrorsInCode(
      r'''
class A {}

class B extends A {
  B([super.a]);
}
''',
      [error(diag.superFormalParameterWithoutAssociatedPositional, 43, 1)],
    );
  }

  test_class_secondary_requiredPositional_01() async {
    await assertErrorsInCode(
      r'''
class A {}

class B extends A {
  B(super.a);
}
''',
      [error(diag.superFormalParameterWithoutAssociatedPositional, 42, 1)],
    );
  }

  test_class_secondary_requiredPositional_12() async {
    await assertErrorsInCode(
      r'''
class A {
  A(int a);
}

class B extends A {
  B(super.a, super.b);
}
''',
      [error(diag.superFormalParameterWithoutAssociatedPositional, 64, 1)],
    );
  }

  test_enum_primary_requiredPositional_01() async {
    await assertErrorsInCode(
      r'''
enum E(super.a) {
  v(0);
}
''',
      [error(diag.superFormalParameterWithoutAssociatedPositional, 13, 1)],
    );
  }

  test_enum_secondary_requiredPositional_01() async {
    await assertErrorsInCode(
      r'''
enum E {
  v(0);
  const E(super.x);
}
''',
      [error(diag.superFormalParameterWithoutAssociatedPositional, 33, 1)],
    );
  }

  test_recovery_hasSuperClass_noSuperConstructor_primary() async {
    await assertErrorsInCode(
      r'''
class A {
  A(int x);
}

class B(super.a) extends A {
  this : super.named();
}
''',
      [error(diag.undefinedConstructorInInitializer, 63, 13)],
    );
  }

  test_recovery_hasSuperClass_noSuperConstructor_secondary() async {
    await assertErrorsInCode(
      r'''
class A {
  A(int x);
}

class B extends A {
  B(super.x) : super.named();
}
''',
      [error(diag.undefinedConstructorInInitializer, 60, 13)],
    );
  }

  test_recovery_noSuperClass_primary() async {
    await assertErrorsInCode(
      r'''
class B(super.a) extends A {
  this : super.named();
}
''',
      [
        error(diag.extendsNonClass, 25, 1),
        error(diag.undefinedConstructorInInitializer, 38, 13),
      ],
    );
  }

  test_recovery_noSuperClass_secondary() async {
    await assertErrorsInCode(
      r'''
class B extends A {
  B(super.x) : super.named();
}
''',
      [
        error(diag.extendsNonClass, 16, 1),
        error(diag.undefinedConstructorInInitializer, 35, 13),
      ],
    );
  }
}
