// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NonRedirectingGenerativeConstructorWithPrimaryTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class NonRedirectingGenerativeConstructorWithPrimaryTest
    extends PubPackageResolutionTest {
  test_class_factory() async {
    await resolveTestCodeWithDiagnostics(r'''
class C(int x) {
  factory C.named() => C(0);
}
''');
  }

  test_class_generative_augmentationOfPrimary() async {
    await resolveTestCodeWithDiagnostics(r'''
class C({int p = 0});

augment class C {
  augment C({int p});
}
''');
  }

  test_class_generative_augmentationRedirectingToPrimary() async {
    await resolveTestCodeWithDiagnostics(r'''
class C(int x) {
  C.named(int x);
}

augment class C {
  augment C.named(int x) : this(x);
}
''');
  }

  test_class_generative_augmentationRedirectingToPrimary_sameClass() async {
    await resolveTestCodeWithDiagnostics(r'''
class C(int x) {
  C.named(int x);
  augment C.named(int x) : this(x);
}
''');
  }

  test_class_generative_augmentationRedirectingToUnresolved() async {
    await resolveTestCodeWithDiagnostics(r'''
class C(int x) {
  C.named();
}

augment class C {
  augment C.named() : this.missing();
//                    ^^^^^^^^^^^^^^
// [diag.redirectGenerativeToMissingConstructor] The constructor 'C.missing' couldn't be found in 'C'.
}
''');
  }

  test_class_generative_nonRedirecting() async {
    await resolveTestCodeWithDiagnostics(r'''
class C(int x) {
  C.named();
//^^^^^^^
// [diag.nonRedirectingGenerativeConstructorWithPrimary] Classes with primary constructors can't have non-redirecting generative constructors.
}
''');
  }

  test_class_generative_redirectingToNonPrimary() async {
    await resolveTestCodeWithDiagnostics(r'''
class C(int x) {
  C.named1() : this.named2();
  C.named2();
//^^^^^^^^
// [diag.nonRedirectingGenerativeConstructorWithPrimary] Classes with primary constructors can't have non-redirecting generative constructors.
}
''');
  }

  test_class_generative_redirectingToPrimary() async {
    await resolveTestCodeWithDiagnostics(r'''
class C(int x) {
  C.named() : this(0);
}
''');
  }

  test_class_generative_redirectingToUnresolved() async {
    await resolveTestCodeWithDiagnostics(r'''
class C(int x) {
  C.named() : this.missing();
//            ^^^^^^^^^^^^^^
// [diag.redirectGenerativeToMissingConstructor] The constructor 'C.missing' couldn't be found in 'C'.
}
''');
  }

  test_class_noPrimaryConstructor() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  C.named();
}
''');
  }

  test_enum_factory() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E(int x) {
  v(0);
  factory E.named() => E.v;
}
''');
  }

  test_enum_generative_nonRedirecting() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E(int x) {
  v(0);
  const E.named();
//      ^^^^^^^
// [diag.nonRedirectingGenerativeConstructorWithPrimary] Classes with primary constructors can't have non-redirecting generative constructors.
//        ^^^^^
// [diag.unusedElement] The declaration 'E.named' isn't referenced.
}
''');
  }

  test_enum_generative_redirectingToPrimary() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E(int x) {
  v(0);
  const E.named(int x) : this(x);
//        ^^^^^
// [diag.unusedElement] The declaration 'E.named' isn't referenced.
}
''');
  }

  test_enum_noPrimaryConstructor() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  const E();
}
''');
  }

  test_extensionType_generative_nonRedirecting() async {
    // Extension types can have non-redirecting generative constructors.
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int x) {
  E.named(this.x);
}
''');
  }
}
