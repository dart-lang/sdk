// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DeprecatedColonForDefaultValueTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class DeprecatedColonForDefaultValueTest extends PubPackageResolutionTest {
  @override
  String get testPackageLanguageVersion => '2.19';

  test_noDefault() async {
    await resolveTestCodeWithDiagnostics(r'''
void f({int? x}) {}
''');
  }

  test_superFormalParameter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  String? a;
  A({this.a});
}

class B extends A {
  B({super.a : ''});
//           ^
// [diag.deprecatedColonForDefaultValue] Using a colon as the separator before a default value is deprecated and will not be supported in language version 3.0 and later.
}
''');
  }

  test_usesColon() async {
    await resolveTestCodeWithDiagnostics(r'''
void f({int x : 0}) {}
//            ^
// [diag.deprecatedColonForDefaultValue] Using a colon as the separator before a default value is deprecated and will not be supported in language version 3.0 and later.
''');
  }

  test_usesEqual() async {
    await resolveTestCodeWithDiagnostics(r'''
void f({int x = 0}) {}
''');
  }
}
