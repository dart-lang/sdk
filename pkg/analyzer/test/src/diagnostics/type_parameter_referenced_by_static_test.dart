// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TypeParameterReferencedByStaticTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class TypeParameterReferencedByStaticTest extends PubPackageResolutionTest {
  test_class_field() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<T> {
  static T? foo;
//       ^
// [diag.typeParameterReferencedByStatic] Static members can't reference type parameters of the class.
}
''');
  }

  test_class_getter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<T> {
  static T? get foo => null;
//       ^
// [diag.typeParameterReferencedByStatic] Static members can't reference type parameters of the class.
}
''');
  }

  test_class_method_bodyReference() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<T> {
  static foo() {
    // ignore:unused_local_variable
    T v;
//  ^
// [diag.typeParameterReferencedByStatic] Static members can't reference type parameters of the class.
  }
}
''');
  }

  test_class_method_closure() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<T> {
  static Object foo() {
    return (T a) {};
//          ^
// [diag.typeParameterReferencedByStatic] Static members can't reference type parameters of the class.
  }
}
''');
  }

  test_class_method_parameter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<T> {
  static foo(T a) {}
//           ^
// [diag.typeParameterReferencedByStatic] Static members can't reference type parameters of the class.
}
''');
  }

  test_class_method_return() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<T> {
  static T foo() {
//       ^
// [diag.typeParameterReferencedByStatic] Static members can't reference type parameters of the class.
    throw 0;
  }
}
''');
  }

  test_class_setter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<T> {
  static set foo(T _) {}
//               ^
// [diag.typeParameterReferencedByStatic] Static members can't reference type parameters of the class.
}
''');
  }

  test_expression_method() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<T> {
  static foo() {
    T;
//  ^
// [diag.typeParameterReferencedByStatic] Static members can't reference type parameters of the class.
  }
}
''');
  }

  test_extension_field() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E<T> on int {
  static T? foo;
//       ^
// [diag.typeParameterReferencedByStatic] Static members can't reference type parameters of the class.
}
''');
  }

  test_extension_method_return() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E<T> on int {
  static T foo() => throw 0;
//       ^
// [diag.typeParameterReferencedByStatic] Static members can't reference type parameters of the class.
}
''');
  }

  test_mixin_field() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin A<T> {
  static T? foo;
//       ^
// [diag.typeParameterReferencedByStatic] Static members can't reference type parameters of the class.
}
''');
  }
}
