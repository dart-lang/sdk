// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidConstructorNameTest);
  });
}

@reflectiveTest
class InvalidConstructorNameTest extends PubPackageResolutionTest {
  test_class_notEnclosingClassName_defined() async {
    await assertErrorsInCode(
      r'''
class A {
  B() : super();
}
class B {}
''',
      [error(diag.invalidConstructorName, 12, 1)],
    );
  }

  test_class_notEnclosingClassName_named() async {
    await assertErrorsInCode(
      r'''
class A {}
class B {
  A.foo();
  B.foo();
}
''',
      [error(diag.invalidConstructorName, 23, 1)],
    );
  }

  test_class_notEnclosingClassName_new() async {
    await assertErrorsInCode(
      r'''
class A {}

class B {
  A.new();
  B();
}
''',
      [error(diag.invalidConstructorName, 24, 1)],
    );
  }

  test_class_notEnclosingClassName_undefined() async {
    await assertErrorsInCode(
      r'''
class A {
  B() : super();
}
''',
      [error(diag.invalidConstructorName, 12, 1)],
    );
  }

  test_enum_named() async {
    await assertErrorsInCode(
      r'''
class A {}

enum E {
  v.foo();
  const A.foo();
  const E.foo();
}
''',
      [
        error(diag.invalidConstructorName, 40, 1),
        error(diag.unusedElement, 59, 3),
      ],
    );
  }
}
