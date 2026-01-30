// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RedirectGenerativeToMissingConstructorTest);
  });
}

@reflectiveTest
class RedirectGenerativeToMissingConstructorTest
    extends PubPackageResolutionTest {
  test_class_primary_missing() async {
    await assertErrorsInCode(
      r'''
class A() {
  this : this.noSuchConstructor();
}
''',
      [error(diag.primaryConstructorCannotRedirect, 21, 4)],
    );
  }

  test_class_typeName_missing() async {
    await assertErrorsInCode(
      r'''
class A {
  A() : this.noSuchConstructor();
}
''',
      [error(diag.redirectGenerativeToMissingConstructor, 18, 24)],
    );
  }

  test_enum_primary_missing() async {
    await assertErrorsInCode(
      r'''
enum E() {
  v;
  this : this.noSuchConstructor();
}
''',
      [error(diag.primaryConstructorCannotRedirect, 25, 4)],
    );
  }

  test_enum_typeName_missing() async {
    await assertErrorsInCode(
      r'''
enum E {
  v;
  const E() : this.noSuchConstructor();
}
''',
      [error(diag.redirectGenerativeToMissingConstructor, 28, 24)],
    );
  }
}
