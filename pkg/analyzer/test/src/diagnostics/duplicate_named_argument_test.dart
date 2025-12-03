// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
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
    await assertErrorsInCode(
      r'''
class C {
  C({int? a, int? b});
}
main() {
  C(a: 1, a: 2);
}
''',
      [error(diag.duplicateNamedArgument, 54, 1)],
    );
  }

  test_constructor_nonFunctionTypedef() async {
    await assertErrorsInCode(
      r'''
class C {
  C({int? a, int? b});
}
typedef D = C;
main() {
  D(a: 1, a: 2);
}
''',
      [error(diag.duplicateNamedArgument, 69, 1)],
    );
  }

  test_constructor_superParameter() async {
    await assertErrorsInCode(
      r'''
class A {
  A({required int a});
}

class B extends A {
  B({required super.a}) : super(a: 0);
}
''',
      [error(diag.duplicateNamedArgument, 88, 1)],
    );
  }

  test_enumConstant() async {
    await assertErrorsInCode(
      r'''
enum E {
  v(a: 0, a: 1);
  const E({required int a});
}
''',
      [error(diag.duplicateNamedArgument, 19, 1)],
    );
  }

  test_function() async {
    await assertErrorsInCode(
      r'''
f({a, b}) {}
main() {
  f(a: 1, a: 2);
}
''',
      [error(diag.duplicateNamedArgument, 32, 1)],
    );
  }
}
