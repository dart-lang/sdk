// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
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
    await assertNoErrorsInCode(r'''
class C(this.x) {
  final int x;
}
''');
  }

  test_class_primary_fieldMissing() async {
    await assertErrorsInCode(
      r'''
class C(this.x) {}
''',
      [error(diag.initializingFormalForNonExistentField, 8, 6)],
    );
  }

  test_class_secondary_fieldExists() async {
    await assertNoErrorsInCode(r'''
class C {
  final int x;
  C(this.x);
}
''');
  }

  test_class_secondary_fieldMissing() async {
    await assertErrorsInCode(
      r'''
class A {
  A(this.x) {}
}
''',
      [error(diag.initializingFormalForNonExistentField, 14, 6)],
    );
  }

  test_class_secondary_fieldMissing_getter() async {
    await assertErrorsInCode(
      r'''
class A {
  int get x => 1;
  A(this.x) {}
}
''',
      [error(diag.initializingFormalForNonExistentField, 32, 6)],
    );
  }

  test_class_secondary_notInEnclosingClass() async {
    await assertErrorsInCode(
      r'''
class A {
  int x = 1;
}
class B extends A {
  B(this.x) {}
}
''',
      [error(diag.initializingFormalForNonExistentField, 49, 6)],
    );
  }

  test_class_secondary_optionalPositional_fieldMissing() async {
    await assertErrorsInCode(
      r'''
class A {
  A([this.x]) {}
}
''',
      [error(diag.initializingFormalForNonExistentField, 15, 6)],
    );
  }

  test_enum_primary_fieldExists() async {
    await assertNoErrorsInCode(r'''
enum E(this.x) {
  v(0);

  final int x;
}
''');
  }

  test_enum_primary_fieldMissing() async {
    await assertErrorsInCode(
      r'''
enum E(this.x) {
  v(0);
}
''',
      [error(diag.initializingFormalForNonExistentField, 7, 6)],
    );
  }

  test_enum_secondary_fieldExists() async {
    await assertNoErrorsInCode(r'''
enum E {
  v(0);
  final int x;
  const E(this.x);
}
''');
  }

  test_enum_secondary_fieldMissing() async {
    await assertErrorsInCode(
      r'''
enum E {
  v(0);
  const E(this.x);
}
''',
      [error(diag.initializingFormalForNonExistentField, 27, 6)],
    );
  }

  test_enum_secondary_fieldMissing_getter() async {
    await assertErrorsInCode(
      r'''
enum E {
  v(0);
  const E(this.x);
  int get x => 1;
}
''',
      [error(diag.initializingFormalForNonExistentField, 27, 6)],
    );
  }

  test_enum_secondary_optionalPositional_fieldMissing() async {
    await assertErrorsInCode(
      r'''
enum E {
  v;
  const E([this.x]);
}
''',
      [
        error(diag.initializingFormalForNonExistentField, 25, 6),
        error(diag.unusedElementParameter, 30, 1),
      ],
    );
  }

  test_extensionType_primary_fieldMissing_notReportedHere() async {
    await assertErrorsInCode(
      r'''
extension type E(this.x) {}
''',
      [error(diag.expectedRepresentationField, 17, 4)],
    );
  }

  test_extensionType_secondary_fieldExists() async {
    await assertNoErrorsInCode(r'''
extension type E(int it) {
  E.named(this.it);
}
''');
  }

  test_extensionType_secondary_fieldMissing() async {
    await assertErrorsInCode(
      r'''
extension type E(int it) {
  E.named(this.x) : this.it = 0;
}
''',
      [error(diag.initializingFormalForNonExistentField, 37, 6)],
    );
  }
}
