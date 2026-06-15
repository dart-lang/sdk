// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstFieldInitializerNotAssignableTest);
  });
}

@reflectiveTest
class ConstFieldInitializerNotAssignableTest extends PubPackageResolutionTest {
  test_assignable_subtype() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  final num x;
  const A() : x = 1;
}
''');
  }

  test_enum_unrelated() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
//^
// [diag.constConstructorFieldTypeMismatch] In a const constructor, a value of type 'String' can't be assigned to the field 'x', which has type 'int'.
  final int x;
  const E() : x = '';
//                ^^
// [diag.constFieldInitializerNotAssignable] The initializer type 'String' can't be assigned to the field type 'int' in a const constructor.
}
''');
  }

  test_notAssignable_unrelated() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  final int x;
  const A() : x = '';
//                ^^
// [diag.constFieldInitializerNotAssignable] The initializer type 'String' can't be assigned to the field type 'int' in a const constructor.
}
''');
  }
}
