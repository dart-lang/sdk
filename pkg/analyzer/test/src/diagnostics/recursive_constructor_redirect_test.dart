// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RecursiveConstructorRedirectTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class RecursiveConstructorRedirectTest extends PubPackageResolutionTest {
  test_directSelfReference() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A() : this();
//      ^^^^^^
// [diag.recursiveConstructorRedirect] Constructors can't redirect to themselves either directly or indirectly.
}
''');
  }

  test_recursive() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A.a() : this.b();
//        ^^^^^^^^
// [diag.recursiveConstructorRedirect] Constructors can't redirect to themselves either directly or indirectly.
  A.b() : this.a();
//        ^^^^^^^^
// [diag.recursiveConstructorRedirect] Constructors can't redirect to themselves either directly or indirectly.
}
''');
  }

  test_valid_redirect() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A.a() : this.b();
  A.b() : this.c();
  A.c() {}
}
''');
  }
}
