// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RecursiveConstructorRedirectTest);
  });
}

@reflectiveTest
class RecursiveConstructorRedirectTest extends PubPackageResolutionTest {
  test_directSelfReference() async {
    await assertErrorsInCode(
      r'''
class A {
  A() : this();
}
''',
      [error(diag.recursiveConstructorRedirect, 18, 6)],
    );
  }

  test_recursive() async {
    await assertErrorsInCode(
      r'''
class A {
  A.a() : this.b();
  A.b() : this.a();
}
''',
      [
        error(diag.recursiveConstructorRedirect, 20, 8),
        error(diag.recursiveConstructorRedirect, 40, 8),
      ],
    );
  }

  test_valid_redirect() async {
    await assertNoErrorsInCode(r'''
class A {
  A.a() : this.b();
  A.b() : this.c();
  A.c() {}
}
''');
  }
}
