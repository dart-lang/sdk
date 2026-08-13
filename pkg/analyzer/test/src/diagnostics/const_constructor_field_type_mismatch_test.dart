// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstConstructorFieldTypeMismatchTest);
  });
}

@reflectiveTest
class ConstConstructorFieldTypeMismatchTest extends PubPackageResolutionTest {
  test_generic_int_int() async {
    await resolveTestCodeWithDiagnostics(r'''
class C<T> {
  final T x = y;
//            ^
// [diag.invalidAssignment] A value of type 'int' can't be assigned to a variable of type 'T'.
  const C();
}
const int y = 1;
var v = const C<int>();
''');
  }

  test_notGeneric_unresolved_int() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  const A(x) : y = x;
  final Unresolved y;
//      ^^^^^^^^^^
// [diag.undefinedClass] Undefined class 'Unresolved'.
}
var v = const A(0);
''');
  }

  test_notGeneric_unresolved_null() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  const A(x) : y = x;
  final Unresolved y;
//      ^^^^^^^^^^
// [diag.undefinedClass] Undefined class 'Unresolved'.
}
var v = const A(null);
''');
  }
}
