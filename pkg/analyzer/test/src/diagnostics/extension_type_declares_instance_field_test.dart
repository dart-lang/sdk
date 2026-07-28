// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExtensionTypeDeclaresInstanceFieldTest);
  });
}

@reflectiveTest
class ExtensionTypeDeclaresInstanceFieldTest extends PubPackageResolutionTest {
  Future<void> test_instance_field() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int it) {
  final int foo = 0;
//          ^^^
// [diag.extensionTypeDeclaresInstanceField] Extension types can't declare instance fields.
}
''');
  }

  Future<void> test_instance_field_abstract() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int it) {
  abstract int foo;
//             ^^^
// [diag.inducedGetterWithoutBody] The getter induced by 'foo' must have a body.
// [diag.inducedSetterWithoutBody] The setter induced by 'foo' must have a body.
}
''');
  }

  Future<void> test_instance_field_abstract_augment_getter() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int it) {
  abstract int foo;
//             ^^^
// [diag.inducedSetterNotCompleteAfterAugmentations] The setter induced by 'foo' must have a body after all augmentations are applied.
}

augment extension type E {
  augment int get foo => 0;
}
''');
  }

  Future<void> test_instance_field_abstract_augment_getter_setter() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int it) {
  abstract int foo;
}

augment extension type E {
  augment int get foo => 0;
  augment set foo(int _) {}
}
''');
  }

  Future<void> test_instance_field_abstract_augment_setter() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int it) {
  abstract int foo;
//             ^^^
// [diag.inducedGetterNotCompleteAfterAugmentations] The getter induced by 'foo' must have a body after all augmentations are applied.
}

augment extension type E {
  augment set foo(int _) {}
}
''');
  }

  Future<void> test_instance_field_abstract_final() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int it) {
  abstract final int foo;
//                   ^^^
// [diag.inducedGetterWithoutBody] The getter induced by 'foo' must have a body.
}
''');
  }

  Future<void> test_instance_field_abstract_final_augment_getter() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int it) {
  abstract final int foo;
}

augment extension type E {
  augment int get foo => 0;
}
''');
  }

  Future<void>
  test_instance_field_abstract_final_augment_getter_external() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int it) {
  abstract final int foo;
}

augment extension type E {
  augment external int get foo;
}
''');
  }

  Future<void> test_instance_field_abstract_language305() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.5
extension type E(int it) {
  abstract int foo;
//             ^^^
// [diag.extensionTypeDeclaresInstanceField] Extension types can't declare instance fields.
}
''');
  }

  Future<void> test_instance_field_external() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int it) {
  external int foo;
}
''');
  }

  Future<void> test_instance_getter() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int it) {
  int get foo => 0;
}
''');
  }

  Future<void> test_instance_getter_augment_field_abstract_final() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int it) {
  int get foo => 0;
}

augment extension type E {
  augment abstract final int foo;
}
''');
  }

  Future<void> test_instance_getter_setter_augment_field_abstract() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int it) {
  int get foo => 0;
  set foo(int _) {}
}

augment extension type E {
  augment abstract int foo;
}
''');
  }

  Future<void> test_instance_setter() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int it) {
  set foo(int _) {}
}
''');
  }

  Future<void> test_multiple() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int it) {
  String? one, two, three;
//        ^^^
// [diag.extensionTypeDeclaresInstanceField] Extension types can't declare instance fields.
//             ^^^
// [diag.extensionTypeDeclaresInstanceField] Extension types can't declare instance fields.
//                  ^^^^^
// [diag.extensionTypeDeclaresInstanceField] Extension types can't declare instance fields.
}
''');
  }

  Future<void> test_static_field() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int it) {
  static final int foo = 0;
}
''');
  }
}
