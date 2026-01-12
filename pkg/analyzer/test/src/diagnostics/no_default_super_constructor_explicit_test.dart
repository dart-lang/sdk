// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NoDefaultSuperConstructorExplicitTest);
  });
}

@reflectiveTest
class NoDefaultSuperConstructorExplicitTest extends PubPackageResolutionTest {
  test_requiredNamed_constructor_typeName() async {
    await assertErrorsInCode(
      r'''
// @dart = 2.16
class A {
  A({required int a});
}
class B extends A {
  B.foo();
}
''',
      [error(diag.noDefaultSuperConstructorExplicit, 73, 5)],
    );
  }

  test_requiredPositional_constructor_typeName() async {
    await assertErrorsInCode(
      r'''
// @dart = 2.16
class A {
  A(int a);
}
class B extends A {
  B.foo();
}
''',
      [error(diag.noDefaultSuperConstructorExplicit, 62, 5)],
    );
  }
}
