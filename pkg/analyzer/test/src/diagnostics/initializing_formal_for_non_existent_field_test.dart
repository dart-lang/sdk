// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InitializingFormalForNonExistentFieldTest);
  });
}

@reflectiveTest
class InitializingFormalForNonExistentFieldTest
    extends PubPackageResolutionTest {
  test_class_primary_fieldExists() async {
    await resolveTestCodeWithDiagnostics(r'''
class C(this.x) {
  final int x;
}
''');
  }

  test_class_primary_fieldMissing() async {
    await resolveTestCodeWithDiagnostics(r'''
class C(this.x) {}
//      ^^^^^^
// [diag.initializingFormalForNonExistentField] 'x' isn't a field in the enclosing class.
''');
  }

  test_class_secondary_fieldExists() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  final int x;
  C(this.x);
}
''');
  }

  test_class_secondary_fieldExists_augmentationAfterWildcard() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  int? x;
  C(int? _);
}

augment class C {
  augment C(this.x);
}
''');
  }

  test_class_secondary_fieldMissing() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A(this.x) {}
//  ^^^^^^
// [diag.initializingFormalForNonExistentField] 'x' isn't a field in the enclosing class.
}
''');
  }

  test_class_secondary_fieldMissing_getter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int get x => 1;
  A(this.x) {}
//  ^^^^^^
// [diag.initializingFormalForNonExistentField] 'x' isn't a field in the enclosing class.
}
''');
  }

  test_class_secondary_notInEnclosingClass() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int x = 1;
}
class B extends A {
  B(this.x) {}
//  ^^^^^^
// [diag.initializingFormalForNonExistentField] 'x' isn't a field in the enclosing class.
}
''');
  }

  test_class_secondary_optionalPositional_fieldMissing() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A([this.x]) {}
//   ^^^^^^
// [diag.initializingFormalForNonExistentField] 'x' isn't a field in the enclosing class.
}
''');
  }

  test_enum_primary_fieldExists() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E(this.x) {
  v(0);

  final int x;
}
''');
  }

  test_enum_primary_fieldMissing() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E(this.x) {
//     ^^^^^^
// [diag.initializingFormalForNonExistentField] 'x' isn't a field in the enclosing class.
  v(0);
}
''');
  }

  test_enum_secondary_fieldExists() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v(0);
  final int x;
  const E(this.x);
}
''');
  }

  test_enum_secondary_fieldMissing() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v(0);
  const E(this.x);
//        ^^^^^^
// [diag.initializingFormalForNonExistentField] 'x' isn't a field in the enclosing class.
}
''');
  }

  test_enum_secondary_fieldMissing_getter() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v(0);
  const E(this.x);
//        ^^^^^^
// [diag.initializingFormalForNonExistentField] 'x' isn't a field in the enclosing class.
  int get x => 1;
}
''');
  }

  test_enum_secondary_optionalPositional_fieldMissing() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  const E([this.x]);
//         ^^^^^^
// [diag.initializingFormalForNonExistentField] 'x' isn't a field in the enclosing class.
//              ^
// [diag.unusedElementParameter] A value for optional parameter 'x' isn't ever given.
}
''');
  }

  test_extensionType_primary_fieldMissing_notReportedHere() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(this.x) {}
//               ^^^^
// [diag.expectedRepresentationField] Expected a representation field.
''');
  }

  test_extensionType_secondary_fieldExists() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int it) {
  E.named(this.it);
}
''');
  }

  test_extensionType_secondary_fieldMissing() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int it) {
  E.named(this.x) : this.it = 0;
//        ^^^^^^
// [diag.initializingFormalForNonExistentField] 'x' isn't a field in the enclosing class.
}
''');
  }
}
