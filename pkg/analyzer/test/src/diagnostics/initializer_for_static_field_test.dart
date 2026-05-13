// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InitializerForStaticFieldTest);
  });
}

@reflectiveTest
class InitializerForStaticFieldTest extends PubPackageResolutionTest {
  test_class_primaryConstructor_fieldFormalParameter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A(this.x) {
//      ^^^^
// [diag.initializerForStaticField] 'x' is a static field in the enclosing class. Fields initialized in a constructor can't be static.
  static int? x;
}
''');
  }

  test_class_secondaryConstructor_fieldFormalParameter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static int? x;
  A([this.x = 0]) {}
//   ^^^^
// [diag.initializerForStaticField] 'x' is a static field in the enclosing class. Fields initialized in a constructor can't be static.
}
''');
  }

  test_class_secondaryConstructor_initializerList() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static int x = 1;
  A() : x = 0 {}
//      ^^^^^
// [diag.initializerForStaticField] 'x' is a static field in the enclosing class. Fields initialized in a constructor can't be static.
}
''');
  }

  test_enum_primaryConstructor_fieldFormalParameter() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E(this.x) {
//     ^^^^
// [diag.initializerForStaticField] 'x' is a static field in the enclosing class. Fields initialized in a constructor can't be static.
  v(0);

  static int? x;
}
''');
  }

  test_enum_secondaryConstructor_fieldFormalParameter() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v(0);
  static int x = 0;
  const E(this.x);
//        ^^^^
// [diag.initializerForStaticField] 'x' is a static field in the enclosing class. Fields initialized in a constructor can't be static.
}
''');
  }

  test_enum_secondaryConstructor_initializerList() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  static int x = 1;
  const E() : x = 0;
//            ^^^^^
// [diag.initializerForStaticField] 'x' is a static field in the enclosing class. Fields initialized in a constructor can't be static.
}
''');
  }

  test_extensionType_primaryConstructor_fieldFormalParameter_notReportedHere() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(this.x) {
//               ^^^^
// [diag.expectedRepresentationField] Expected a representation field.
  static int? x;
}
''');
  }

  test_extensionType_secondaryConstructor_fieldFormalParameter() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int it) {
  static int x = 0;
  E.named(this.x) : this.it = 0;
//        ^^^^
// [diag.initializerForStaticField] 'x' is a static field in the enclosing class. Fields initialized in a constructor can't be static.
}
''');
  }

  test_extensionType_secondaryConstructor_initializerList() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int it) {
  static int x = 1;
  E.named() : x = 0, this.it = 0;
//            ^^^^^
// [diag.initializerForStaticField] 'x' is a static field in the enclosing class. Fields initialized in a constructor can't be static.
}
''');
  }
}
