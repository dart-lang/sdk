// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FieldInitializerNotAssignableTest);
    defineReflectiveTests(FieldInitializerNotAssignableWithStrictCastsTest);
  });
}

@reflectiveTest
class FieldInitializerNotAssignableTest extends PubPackageResolutionTest {
  test_class_implicitCallReference() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  void call(int p) {}
}
class A {
  void Function(int) x;
  A() : x = C();
}
''');
  }

  test_class_implicitCallReference_genericFunctionInstantiation() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  void call<T>(T p) {}
}
class A {
  void Function(int) x;
  A() : x = C();
}
''');
  }

  test_class_unrelated() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int x;
  A() : x = '';
//          ^^
// [diag.fieldInitializerNotAssignable] The initializer type 'String' can't be assigned to the field type 'int'.
}
''');
  }
}

@reflectiveTest
class FieldInitializerNotAssignableWithStrictCastsTest
    extends PubPackageResolutionTest
    with WithStrictCastsMixin {
  test_constructorInitializer() async {
    await assertTestCodeWithStrictCastsDiagnostics('''
class A {
  int i;
  A(dynamic a) : i = a;
//                   ^
// [diag.fieldInitializerNotAssignable] The initializer type 'dynamic' can't be assigned to the field type 'int'.
}
''');
  }

  test_constructorInitializer_primaryConstructor() async {
    await assertTestCodeWithStrictCastsDiagnostics('''
class A(dynamic a) {
  int i;
  this : i = a;
//           ^
// [diag.fieldInitializerNotAssignable] The initializer type 'dynamic' can't be assigned to the field type 'int'.
}
''');
  }
}
