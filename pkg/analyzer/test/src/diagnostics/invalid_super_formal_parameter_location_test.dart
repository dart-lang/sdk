// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidSuperFormalParameterLocationTest);
  });
}

@reflectiveTest
class InvalidSuperFormalParameterLocationTest extends PubPackageResolutionTest {
  test_class_constructor_external() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  external A(super.a);
//           ^^^^^
// [diag.invalidSuperFormalParameterLocation] Super parameters can only be used in non-redirecting generative constructors.
}
''');
  }

  test_class_constructor_factory() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  factory A(super.a) {
//          ^^^^^
// [diag.invalidSuperFormalParameterLocation] Super parameters can only be used in non-redirecting generative constructors.
    return A._();
  }
  A._();
}
''');
  }

  test_class_constructor_redirecting() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A(super.a) : this._();
//  ^^^^^
// [diag.invalidSuperFormalParameterLocation] Super parameters can only be used in non-redirecting generative constructors.
  A._();
}
''');
  }

  test_class_method() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  void foo(super.a) {}
//         ^^^^^
// [diag.invalidSuperFormalParameterLocation] Super parameters can only be used in non-redirecting generative constructors.
}
''');
  }

  test_extension_method() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  void foo(super.a) {}
//         ^^^^^
// [diag.invalidSuperFormalParameterLocation] Super parameters can only be used in non-redirecting generative constructors.
}
''');
  }

  test_local_function() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  // ignore:unused_element
  void g(super.a) {}
//       ^^^^^
// [diag.invalidSuperFormalParameterLocation] Super parameters can only be used in non-redirecting generative constructors.
}
''');
  }

  test_mixin_method() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  void foo(super.a) {}
//         ^^^^^
// [diag.invalidSuperFormalParameterLocation] Super parameters can only be used in non-redirecting generative constructors.
}
''');
  }

  test_unit_function() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(super.a) {}
//     ^^^^^
// [diag.invalidSuperFormalParameterLocation] Super parameters can only be used in non-redirecting generative constructors.
''');
  }

  test_valid_optionalNamed() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A({int? a});
}

class B extends A {
  B({super.a});
}
''');
  }

  test_valid_optionalPositional() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A([int? a]);
}

class B extends A {
  B([super.a]);
}
''');
  }

  test_valid_requiredNamed() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A({required int a});
}

class B extends A {
  B({required super.a});
}
''');
  }

  test_valid_requiredPositional() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A(int a);
}

class B extends A {
  B(super.a);
}
''');
  }
}
