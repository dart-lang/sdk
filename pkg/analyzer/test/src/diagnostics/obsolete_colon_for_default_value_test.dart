// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ObsoleteColonForDefaultValueTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class ObsoleteColonForDefaultValueTest extends PubPackageResolutionTest {
  test_noDefault() async {
    await resolveTestCodeWithDiagnostics('''
void f({int? x}) {}
''');
  }

  test_superFormalParameter() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  String? a;
  A({this.a});
}

class B extends A {
  B({super.a : ''});
//           ^
// [diag.obsoleteColonForDefaultValue] Using a colon as the separator before a default value is no longer supported.
}
''');
  }

  test_usesColon() async {
    await resolveTestCodeWithDiagnostics('''
void f({int x : 0}) {}
//            ^
// [diag.obsoleteColonForDefaultValue] Using a colon as the separator before a default value is no longer supported.
''');
  }

  test_usesEqual() async {
    await resolveTestCodeWithDiagnostics('''
void f({int x = 0}) {}
''');
  }
}
