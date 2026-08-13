// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MultipleSuperInitializersTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class MultipleSuperInitializersTest extends PubPackageResolutionTest {
  test_primary_twoSuperInitializers() async {
    await resolveTestCodeWithDiagnostics('''
class A {}
class B() extends A {
  this : super(), super();
//                ^^^^^
// [diag.multipleSuperInitializers] A constructor can have at most one 'super' initializer.
}
''');
  }

  test_typeName_oneSuperInitializer() async {
    await resolveTestCodeWithDiagnostics('''
class A {}
class B extends A {
  B() : super() {}
}
''');
  }

  test_typeName_twoSuperInitializers() async {
    await resolveTestCodeWithDiagnostics('''
class A {}
class B extends A {
  B() : super(), super() {}
//               ^^^^^^^
// [diag.multipleSuperInitializers] A constructor can have at most one 'super' initializer.
}
''');
  }
}
