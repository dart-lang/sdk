// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExtensionDeclaresFieldTest);
  });
}

@reflectiveTest
class ExtensionDeclaresFieldTest extends PubPackageResolutionTest {
  test_instance_field_abstract() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  abstract int v;
//             ^
// [diag.inducedGetterWithoutBody] The getter induced by 'v' must have a body.
// [diag.inducedSetterWithoutBody] The setter induced by 'v' must have a body.
}
''');
  }

  test_instance_field_abstract_augment_getter() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  abstract int v;
//             ^
// [diag.inducedSetterNotCompleteAfterAugmentations] The setter induced by 'v' must have a body after all augmentations are applied.
}

augment extension E {
  augment int get v => 0;
}
''');
  }

  test_instance_field_abstract_augment_getter_setter() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  abstract int v;
}

augment extension E {
  augment int get v => 0;
  augment set v(int _) {}
}
''');
  }

  test_instance_field_abstract_augment_setter() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  abstract int v;
//             ^
// [diag.inducedGetterNotCompleteAfterAugmentations] The getter induced by 'v' must have a body after all augmentations are applied.
}

augment extension E {
  augment set v(int _) {}
}
''');
  }

  test_instance_field_abstract_final() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  abstract final int v;
//                   ^
// [diag.inducedGetterWithoutBody] The getter induced by 'v' must have a body.
}
''');
  }

  test_instance_field_abstract_final_augment_getter() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  abstract final int v;
}

augment extension E {
  augment int get v => 0;
}
''');
  }

  test_instance_field_abstract_final_augment_getter_external() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  abstract final int v;
}

augment extension E {
  augment external int get v;
}
''');
  }

  test_instance_field_abstract_language305() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.5
extension E on int {
  abstract int v;
//             ^
// [diag.extensionDeclaresInstanceField] Extensions can't declare instance fields.
}
''');
  }

  test_instance_getter_abstract() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  int get foo;
//        ^^^
// [diag.extensionDeclaresAbstractMember] Extensions can't declare abstract members.
}
''');
  }

  test_instance_getter_augment_abstract_field_final() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  int get v => 0;
}

augment extension E {
  augment abstract final int v;
}
''');
  }

  test_instance_getter_setter_augment_field_abstract() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  int get v => 0;
  set v(int _) {}
}

augment extension E {
  augment abstract int v;
}
''');
  }

  test_instanceField1_final_late_typeInt() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  late final int v;
//               ^
// [diag.extensionDeclaresInstanceField] Extensions can't declare instance fields.
}
''');
  }

  test_instanceField1_typeIntQ() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  int? v;
//     ^
// [diag.extensionDeclaresInstanceField] Extensions can't declare instance fields.
}
''');
  }

  test_instanceField3_typeIntQ() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  int? v1, v2;
//     ^^
// [diag.extensionDeclaresInstanceField] Extensions can't declare instance fields.
//         ^^
// [diag.extensionDeclaresInstanceField] Extensions can't declare instance fields.
}
''');
  }

  test_none() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {}
''');
  }

  test_staticField1_typeInt() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  static int v = 0;
}
''');
  }
}
