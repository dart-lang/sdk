// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MultipleSuperInitializersTest);
  });
}

@reflectiveTest
class MultipleSuperInitializersTest extends PubPackageResolutionTest {
  test_primary_twoSuperInitializers() async {
    await assertErrorsInCode(
      '''
class A {}
class B() extends A {
  this : super(), super();
}
''',
      [error(diag.multipleSuperInitializers, 51, 5)],
    );
  }

  test_typeName_oneSuperInitializer() async {
    await assertNoErrorsInCode('''
class A {}
class B extends A {
  B() : super() {}
}
''');
  }

  test_typeName_twoSuperInitializers() async {
    await assertErrorsInCode(
      '''
class A {}
class B extends A {
  B() : super(), super() {}
}
''',
      [error(diag.multipleSuperInitializers, 48, 7)],
    );
  }
}
