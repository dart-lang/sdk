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
  test_override_defined() async {
    await resolveTestCodeWithDiagnostics('''
extension E on String {
  int get g => 0;
}
f() {
  E('a').g;
}
''');
  }

  test_override_undefined() async {
    await resolveTestCodeWithDiagnostics('''
extension E on String {}
f() {
  E('a').g;
//       ^
// [diag.undefinedExtensionGetter] The getter 'g' isn't defined for the extension 'E'.
}
''');
  }

  test_override_undefined_hasSetter() async {
    await resolveTestCodeWithDiagnostics('''
extension E on int {
  set foo(int _) {}
}
f() {
  E(0).foo;
//     ^^^
// [diag.undefinedExtensionGetter] The getter 'foo' isn't defined for the extension 'E'.
}
''');
  }

  test_override_undefined_hasSetter_plusEq() async {
    await resolveTestCodeWithDiagnostics('''
extension E on int {
  set foo(int _) {}
}
f() {
  E(0).foo += 1;
//     ^^^
// [diag.undefinedExtensionGetter] The getter 'foo' isn't defined for the extension 'E'.
}
''');
  }

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
