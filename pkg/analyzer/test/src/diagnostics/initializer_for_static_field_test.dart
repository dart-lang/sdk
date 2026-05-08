// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
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
    await assertErrorsInCode(
      r'''
class A(this.x) {
  static int? x;
}
''',
      [error(diag.initializerForStaticField, 8, 6)],
    );
  }

  test_class_secondaryConstructor_fieldFormalParameter() async {
    await assertErrorsInCode(
      r'''
class A {
  static int? x;
  A([this.x = 0]) {}
}
''',
      [error(diag.initializerForStaticField, 32, 6)],
    );
  }

  test_class_secondaryConstructor_initializerList() async {
    await assertErrorsInCode(
      r'''
class A {
  static int x = 1;
  A() : x = 0 {}
}
''',
      [
        error(diag.initializerForStaticField, 38, 5, messageContains: ["'x'"]),
      ],
    );
  }

  test_enum_primaryConstructor_fieldFormalParameter() async {
    await assertErrorsInCode(
      r'''
enum E(this.x) {
  v(0);

  static int? x;
}
''',
      [error(diag.initializerForStaticField, 7, 6)],
    );
  }

  test_enum_secondaryConstructor_fieldFormalParameter() async {
    await assertErrorsInCode(
      r'''
enum E {
  v(0);
  static int x = 0;
  const E(this.x);
}
''',
      [error(diag.initializerForStaticField, 47, 6)],
    );
  }

  test_enum_secondaryConstructor_initializerList() async {
    await assertErrorsInCode(
      r'''
enum E {
  v;
  static int x = 1;
  const E() : x = 0;
}
''',
      [
        error(diag.initializerForStaticField, 48, 5, messageContains: ["'x'"]),
      ],
    );
  }

  test_extensionType_primaryConstructor_fieldFormalParameter_notReportedHere() async {
    await assertErrorsInCode(
      r'''
extension type E(this.x) {
  static int? x;
}
''',
      [error(diag.expectedRepresentationField, 17, 4)],
    );
  }

  test_extensionType_secondaryConstructor_fieldFormalParameter() async {
    await assertErrorsInCode(
      r'''
extension type E(int it) {
  static int x = 0;
  E.named(this.x) : this.it = 0;
}
''',
      [error(diag.initializerForStaticField, 57, 6)],
    );
  }

  test_extensionType_secondaryConstructor_initializerList() async {
    await assertErrorsInCode(
      r'''
extension type E(int it) {
  static int x = 1;
  E.named() : x = 0, this.it = 0;
}
''',
      [
        error(diag.initializerForStaticField, 61, 5, messageContains: ["'x'"]),
      ],
    );
  }
}
