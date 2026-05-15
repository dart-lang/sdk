// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InitializerForNonExistentFieldTest);
  });
}

@reflectiveTest
class InitializerForNonExistentFieldTest extends PubPackageResolutionTest {
  test_const() async {
    // Check that the absence of a matching field doesn't cause a
    // crash during constant evaluation.
    await resolveTestCodeWithDiagnostics(r'''
class A {
  const A() : x = 'foo';
//            ^^^^^^^^^
// [diag.initializerForNonExistentField] 'x' isn't a field in the enclosing class.
}
A a = const A();
''');
  }

  test_getter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int get x => 0;
  A() : x = 0;
//      ^^^^^
// [diag.initializerForNonExistentField] 'x' isn't a field in the enclosing class.
}
''');
  }

  test_initializer() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A() : x = 0 {}
//      ^^^^^
// [diag.initializerForNonExistentField] 'x' isn't a field in the enclosing class.
}
''');
  }
}
