// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UndefinedExtensionSetterTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class UndefinedExtensionSetterTest extends PubPackageResolutionTest {
  test_static_undefined() async {
    await resolveTestCodeWithDiagnostics('''
extension E on int {}
void f() {
  E.foo = 3;
//  ^^^
// [diag.undefinedExtensionSetter] The setter 'foo' isn't defined for the extension 'E'.
}
''');
  }
}
