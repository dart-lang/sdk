// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AssertInRedirectingConstructorTest);
  });
}

@reflectiveTest
class AssertInRedirectingConstructorTest extends PubPackageResolutionTest {
  test_class_primary_assertBeforeRedirection() async {
    await assertErrorsInCode(
      r'''
class A(int x) {
  A.named() : this(0);
  this : assert(x > 0), this.named();
}
''',
      [error(diag.primaryConstructorCannotRedirect, 64, 4)],
    );
  }

  test_class_primary_redirectionBeforeAssert() async {
    await assertErrorsInCode(
      r'''
class A(int x) {
  A.named() : this(0);
  this : this.named(), assert(x > 0);
}
''',
      [error(diag.primaryConstructorCannotRedirect, 49, 4)],
    );
  }

  test_class_typeName_assertBeforeRedirection() async {
    await assertErrorsInCode(
      r'''
class A {
  A(int x) : assert(x > 0), this.name();
  A.name() {}
}
''',
      [error(diag.assertInRedirectingConstructor, 23, 13)],
    );
  }

  test_class_typeName_justAssert() async {
    await assertNoErrorsInCode(r'''
class A {
  A(int x) : assert(x > 0);
  A.name() {}
}
''');
  }

  test_class_typeName_justRedirection() async {
    await assertNoErrorsInCode(r'''
class A {
  A(int x) : this.name();
  A.name() {}
}
''');
  }

  test_class_typeName_redirectionBeforeAssert() async {
    await assertErrorsInCode(
      r'''
class A {
  A(int x) : this.name(), assert(x > 0);
  A.name() {}
}
''',
      [error(diag.assertInRedirectingConstructor, 36, 13)],
    );
  }

  test_enum_primary_assertBeforeRedirection() async {
    await assertErrorsInCode(
      r'''
enum E(int x) {
  v(0);
  const E.named() : this(0);
  this : assert(x > -1), this.named();
}
''',
      [
        error(diag.recursiveConstantConstructor, 32, 7),
        error(diag.primaryConstructorCannotRedirect, 78, 4),
      ],
    );
  }

  test_enum_primary_redirectionBeforeAssert() async {
    await assertErrorsInCode(
      r'''
enum E(int x) {
  v(0);
  const E.named() : this(0);
  this : this.named(), assert(x > -1);
}
''',
      [
        error(diag.recursiveConstantConstructor, 32, 7),
        error(diag.primaryConstructorCannotRedirect, 62, 4),
      ],
    );
  }

  test_enum_redirectionBeforeAssert() async {
    await assertErrorsInCode(
      r'''
enum E {
  v(42);
  const E(int x) : this.name(), assert(x > 0);
  const E.name();
}
''',
      [error(diag.assertInRedirectingConstructor, 50, 13)],
    );
  }

  test_enum_typeName_assertBeforeRedirection() async {
    await assertErrorsInCode(
      r'''
enum E {
  v(42);
  const E(int x) : assert(x > 0), this.name();
  const E.name();
}
''',
      [error(diag.assertInRedirectingConstructor, 37, 13)],
    );
  }

  test_enum_typeName_justAssert() async {
    await assertNoErrorsInCode(r'''
enum E {
  v(42);
  const E(int x) : assert(x > 0);
}
''');
  }

  test_enum_typeName_justRedirection() async {
    await assertNoErrorsInCode(r'''
enum E {
  v(0);
  const E(int x) : this.name();
  const E.name();
}
''');
  }
}
