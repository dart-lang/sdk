// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UndefinedExtensionGetterTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class UndefinedExtensionGetterTest extends PubPackageResolutionTest {
  test_static_withInference() async {
    await resolveTestCodeWithDiagnostics('''
extension E on Object {}
var a = E.v;
//        ^
// [diag.undefinedExtensionGetter] The getter 'v' isn't defined for the extension 'E'.
''');
  }

  test_static_withoutInference() async {
    await resolveTestCodeWithDiagnostics('''
extension E on Object {}
void f() {
  E.v;
//  ^
// [diag.undefinedExtensionGetter] The getter 'v' isn't defined for the extension 'E'.
}
''');
  }
}
