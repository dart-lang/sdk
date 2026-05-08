// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(
      PositionalSuperFormalParameterWithPositionalArgumentTest,
    );
  });
}

@reflectiveTest
class PositionalSuperFormalParameterWithPositionalArgumentTest
    extends PubPackageResolutionTest {
  test_primaryConstructor_notReported() async {
    await assertNoErrorsInCode(r'''
class A {
  A(int a);
}

class B(super.a) extends A {
  this : super();
}
''');
  }

  test_primaryConstructor_reported() async {
    await assertErrorsInCode(
      r'''
class A {
  A(int a, int b);
}

class B(super.a) extends A {
  this : super(0);
}
''',
      [error(diag.positionalSuperFormalParameterWithPositionalArgument, 46, 1)],
    );
  }

  test_secondaryConstructor_notReported() async {
    await assertNoErrorsInCode(r'''
class A {
  A(int a);
}

class B extends A {
  B(super.a) : super();
}
''');
  }

  test_secondaryConstructor_reported() async {
    await assertErrorsInCode(
      r'''
class A {
  A(int a, int b);
}

class B extends A {
  B(super.b) : super(0);
}
''',
      [error(diag.positionalSuperFormalParameterWithPositionalArgument, 62, 1)],
    );
  }
}
