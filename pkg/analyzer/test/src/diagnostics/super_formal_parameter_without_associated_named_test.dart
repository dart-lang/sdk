// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SuperFormalParameterWithoutAssociatedNamedTest);
  });
}

@reflectiveTest
class SuperFormalParameterWithoutAssociatedNamedTest
    extends PubPackageResolutionTest {
  test_optional() async {
    await assertErrorsInCode(r'''
class A {
  A([int? a]);
}

class B extends A {
  B({super.a}) : super();
}
''', [
      error(
          CompileTimeErrorCode.SUPER_FORMAL_PARAMETER_WITHOUT_ASSOCIATED_NAMED,
          59,
          1)
    ]);
  }

  test_required() async {
    await assertErrorsInCode(r'''
class A {
  A([int? a]);
}

class B extends A {
  B({required super.a}) : super();
}
''', [
      error(
          CompileTimeErrorCode.SUPER_FORMAL_PARAMETER_WITHOUT_ASSOCIATED_NAMED,
          68,
          1)
    ]);
  }
}
