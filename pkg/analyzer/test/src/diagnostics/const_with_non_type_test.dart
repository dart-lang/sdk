// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstWithNonTypeTest);
  });
}

@reflectiveTest
class ConstWithNonTypeTest extends PubPackageResolutionTest {
  test_annotation() async {
    await resolveTestCodeWithDiagnostics(r'''
@Unresolved()
// [diag.constWithNonType][column 2][length 10] The name 'Unresolved' isn't a class.
void f() {}
''');
  }

  test_annotation_importPrefix() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:math' as p;

@p.A(0)
// ^
// [diag.constWithNonType] The name 'A' isn't a class.
void f() {}
''');
  }

  test_fromLibrary() async {
    newFile('$testPackageLibPath/lib1.dart', '');
    await resolveTestCodeWithDiagnostics(r'''
import 'lib1.dart' as lib;
void f() {
  const lib.A();
//          ^
// [diag.constWithNonType] The name 'A' isn't a class.
}
''');
  }

  test_variable() async {
    await resolveTestCodeWithDiagnostics(r'''
int A = 0;
f() {
  return const A();
//             ^
// [diag.constWithNonType] The name 'A' isn't a class.
}
''');
  }
}
