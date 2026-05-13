// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DuplicateNamedArgumentTest);
  });
}

@reflectiveTest
class DuplicateNamedArgumentTest extends PubPackageResolutionTest {
  test_constructor() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  C({int? a, int? b});
}
main() {
  C(a: 1, a: 2);
//        ^
// [diag.duplicateNamedArgument] The argument for the named parameter 'a' was already specified.
}
''');
  }

  test_constructor_nonFunctionTypedef() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  C({int? a, int? b});
}
typedef D = C;
main() {
  D(a: 1, a: 2);
//        ^
// [diag.duplicateNamedArgument] The argument for the named parameter 'a' was already specified.
}
''');
  }

  test_constructor_superParameter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A({required int a});
}

class B extends A {
  B({required super.a}) : super(a: 0);
//                              ^
// [diag.duplicateNamedArgument] The argument for the named parameter 'a' was already specified.
}
''');
  }

  test_enumConstant() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v(a: 0, a: 1);
//        ^
// [diag.duplicateNamedArgument] The argument for the named parameter 'a' was already specified.
  const E({required int a});
}
''');
  }

  test_function() async {
    await resolveTestCodeWithDiagnostics(r'''
f({a, b}) {}
main() {
  f(a: 1, a: 2);
//        ^
// [diag.duplicateNamedArgument] The argument for the named parameter 'a' was already specified.
}
''');
  }
}
