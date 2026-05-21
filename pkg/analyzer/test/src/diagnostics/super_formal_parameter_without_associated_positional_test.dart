// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SuperFormalParameterWithoutAssociatedPositionalTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class SuperFormalParameterWithoutAssociatedPositionalTest
    extends PubPackageResolutionTest {
  test_class_primary_optionalPositional_01() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}

class B([super.a]) extends A {}
//             ^
// [diag.superFormalParameterWithoutAssociatedPositional] No associated positional super constructor parameter.
''');
  }

  test_class_primary_requiredPositional_01() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}

class B(super.a) extends A {}
//            ^
// [diag.superFormalParameterWithoutAssociatedPositional] No associated positional super constructor parameter.
''');
  }

  test_class_secondary_optionalPositional_01() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}

class B extends A {
  B([super.a]);
//         ^
// [diag.superFormalParameterWithoutAssociatedPositional] No associated positional super constructor parameter.
}
''');
  }

  test_class_secondary_requiredPositional_01() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}

class B extends A {
  B(super.a);
//        ^
// [diag.superFormalParameterWithoutAssociatedPositional] No associated positional super constructor parameter.
}
''');
  }

  test_class_secondary_requiredPositional_12() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A(int a);
}

class B extends A {
  B(super.a, super.b);
//                 ^
// [diag.superFormalParameterWithoutAssociatedPositional] No associated positional super constructor parameter.
}
''');
  }

  test_enum_primary_requiredPositional_01() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E(super.a) {
//           ^
// [diag.superFormalParameterWithoutAssociatedPositional] No associated positional super constructor parameter.
  v(0);
}
''');
  }

  test_enum_secondary_requiredPositional_01() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v(0);
  const E(super.x);
//              ^
// [diag.superFormalParameterWithoutAssociatedPositional] No associated positional super constructor parameter.
}
''');
  }

  test_recovery_hasSuperClass_noSuperConstructor_primary() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A(int x);
}

class B(super.a) extends A {
  this : super.named();
//       ^^^^^^^^^^^^^
// [diag.undefinedConstructorInInitializer] The class 'A' doesn't have a constructor named 'named'.
}
''');
  }

  test_recovery_hasSuperClass_noSuperConstructor_secondary() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A(int x);
}

class B extends A {
  B(super.x) : super.named();
//             ^^^^^^^^^^^^^
// [diag.undefinedConstructorInInitializer] The class 'A' doesn't have a constructor named 'named'.
}
''');
  }

  test_recovery_noSuperClass_primary() async {
    await resolveTestCodeWithDiagnostics(r'''
class B(super.a) extends A {
//                       ^
// [diag.extendsNonClass] Classes can only extend other classes.
  this : super.named();
//       ^^^^^^^^^^^^^
// [diag.undefinedConstructorInInitializer] The class 'Object' doesn't have a constructor named 'named'.
}
''');
  }

  test_recovery_noSuperClass_secondary() async {
    await resolveTestCodeWithDiagnostics(r'''
class B extends A {
//              ^
// [diag.extendsNonClass] Classes can only extend other classes.
  B(super.x) : super.named();
//             ^^^^^^^^^^^^^
// [diag.undefinedConstructorInInitializer] The class 'Object' doesn't have a constructor named 'named'.
}
''');
  }
}
