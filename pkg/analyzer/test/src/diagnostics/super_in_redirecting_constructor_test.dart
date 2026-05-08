// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SuperInRedirectingConstructorTest);
  });
}

@reflectiveTest
class SuperInRedirectingConstructorTest extends PubPackageResolutionTest {
  test_class_primary_redirectBeforeSuper() async {
    await assertErrorsInCode(
      r'''
class A() {
  A.named() : this();
  this : this.named(), super();
}
''',
      [error(diag.primaryConstructorCannotRedirect, 43, 4)],
    );
  }

  test_class_primary_superBeforeRedirect() async {
    await assertErrorsInCode(
      r'''
class A() {
  A.named() : this();
  this : super(), this.named();
}
''',
      [error(diag.primaryConstructorCannotRedirect, 52, 4)],
    );
  }

  test_typeName_redirectionSuper() async {
    await assertErrorsInCode(
      r'''
class A {
  A() : this.name(), super();
  A.name() {}
}
''',
      [error(diag.superInRedirectingConstructor, 31, 7)],
    );
  }

  test_typeName_superRedirection() async {
    await assertErrorsInCode(
      r'''
class A {
  A() : super(), this.name();
  A.name() {}
}
''',
      [error(diag.superInRedirectingConstructor, 18, 7)],
    );
  }
}
