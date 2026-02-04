// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NonRedirectingGenerativeConstructorWithPrimaryTest);
  });
}

@reflectiveTest
class NonRedirectingGenerativeConstructorWithPrimaryTest
    extends PubPackageResolutionTest {
  test_class_factory() async {
    await assertNoErrorsInCode(r'''
class C(int x) {
  factory C.named() => C(0);
}
''');
  }

  test_class_generative_nonRedirecting() async {
    await assertErrorsInCode(
      r'''
class C(int x) {
  C.named();
}
''',
      [error(diag.nonRedirectingGenerativeConstructorWithPrimary, 19, 7)],
    );
  }

  test_class_generative_redirectingToNonPrimary() async {
    await assertErrorsInCode(
      r'''
class C(int x) {
  C.named1() : this.named2();
  C.named2();
}
''',
      [error(diag.nonRedirectingGenerativeConstructorWithPrimary, 49, 8)],
    );
  }

  test_class_generative_redirectingToPrimary() async {
    await assertNoErrorsInCode(r'''
class C(int x) {
  C.named() : this(0);
}
''');
  }

  test_class_noPrimaryConstructor() async {
    await assertNoErrorsInCode(r'''
class C {
  C.named();
}
''');
  }

  test_enum_factory() async {
    await assertNoErrorsInCode(r'''
enum E(int x) {
  v(0);
  factory E.named() => E.v;
}
''');
  }

  test_enum_generative_nonRedirecting() async {
    await assertErrorsInCode(
      r'''
enum E(int x) {
  v(0);
  const E.named();
}
''',
      [
        error(diag.nonRedirectingGenerativeConstructorWithPrimary, 32, 7),
        error(diag.unusedElement, 34, 5),
      ],
    );
  }

  test_enum_generative_redirectingToPrimary() async {
    await assertErrorsInCode(
      r'''
enum E(int x) {
  v(0);
  const E.named(int x) : this(x);
}
''',
      [error(diag.unusedElement, 34, 5)],
    );
  }

  test_enum_noPrimaryConstructor() async {
    await assertNoErrorsInCode(r'''
enum E {
  v;
  const E();
}
''');
  }

  test_extensionType_generative_nonRedirecting() async {
    // Extension types can have non-redirecting generative constructors.
    await assertNoErrorsInCode(r'''
extension type E(int x) {
  E.named(this.x);
}
''');
  }
}
