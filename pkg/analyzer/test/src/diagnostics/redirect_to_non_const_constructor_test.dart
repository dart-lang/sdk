// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RedirectToNonConstConstructorTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class RedirectToNonConstConstructorTest extends PubPackageResolutionTest {
  test_constRedirector_cannotResolveRedirectee() async {
    // No crash when redirectee cannot be resolved.
    await resolveTestCodeWithDiagnostics(r'''
class A {
  const factory A.b() = A.a;
//                      ^^^
// [diag.redirectToMissingConstructor] The constructor 'A.a' couldn't be found in 'A'.
}
''');
  }

  test_constRedirector_constRedirectee() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  const A.a();
  const factory A.b() = A.a;
}
''');
  }

  test_constRedirector_constRedirectee_generic() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<T> {
  const A(T value) : this._(value);
  const A._(T value) : value = value;
  final T value;
}

void main(){
  const A<int>(1);
}
''');
  }

  test_constRedirector_constRedirectee_viaInitializer() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  const A.a();
  const A.b() : this.a();
}
''');
  }

  test_constRedirector_nonConstRedirectee() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A.a();
  const factory A.b() = A.a;
//                      ^^^
// [diag.redirectToNonConstConstructor] A constant redirecting constructor can't redirect to a non-constant constructor.
}
''');
  }

  test_constRedirector_nonConstRedirectee_viaInitializer() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A.a();
  const A.b() : this.a();
//                   ^
// [diag.redirectToNonConstConstructor] A constant redirecting constructor can't redirect to a non-constant constructor.
}
''');
  }

  test_constRedirector_nonConstRedirectee_viaInitializer_unnamed() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A();
  const A.named() : this();
//                  ^^^^
// [diag.redirectToNonConstConstructor] A constant redirecting constructor can't redirect to a non-constant constructor.
}
''');
  }

  test_constRedirector_viaInitializer_cannotResolveRedirectee() async {
    // No crash when redirectee cannot be resolved.
    await resolveTestCodeWithDiagnostics(r'''
class A {
  const A.b() : this.a();
//              ^^^^^^^^
// [diag.redirectGenerativeToMissingConstructor] The constructor 'A.a' couldn't be found in 'A'.
}
''');
  }

  test_redirect_to_const() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  const A.a();
  const factory A.b() = A.a;
}
''');
  }
}
