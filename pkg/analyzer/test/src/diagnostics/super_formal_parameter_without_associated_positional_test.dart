// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SuperFormalParameterWithoutAssociatedPositionalTest);
  });
}

@reflectiveTest
class SuperFormalParameterWithoutAssociatedPositionalTest
    extends PubPackageResolutionTest {
  test_explicit_optional() async {
    await assertErrorsInCode(
      r'''
class A {}

class B extends A {
  B([super.a]) : super();
}
''',
      [error(diag.superFormalParameterWithoutAssociatedPositional, 43, 1)],
    );
  }

  test_explicit_required() async {
    await assertErrorsInCode(
      r'''
class A {}

class B extends A {
  B(super.a) : super();
}
''',
      [error(diag.superFormalParameterWithoutAssociatedPositional, 42, 1)],
    );
  }

  test_implicit_optional() async {
    await assertErrorsInCode(
      r'''
class A {}

class B extends A {
  B([super.a]);
}
''',
      [error(diag.superFormalParameterWithoutAssociatedPositional, 43, 1)],
    );
  }

  test_implicit_required() async {
    await assertErrorsInCode(
      r'''
class A {}

class B extends A {
  B(super.a);
}
''',
      [error(diag.superFormalParameterWithoutAssociatedPositional, 42, 1)],
    );
  }
}
