// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UndefinedNamedParameterTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class UndefinedNamedParameterTest extends PubPackageResolutionTest {
  test_constConstructor() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  const A();
}
main() {
  const A(p: 0);
//        ^
// [diag.undefinedNamedParameter] The named parameter 'p' isn't defined.
}
''');
  }

  test_constructor() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A();
}
main() {
  A(p: 0);
//  ^
// [diag.undefinedNamedParameter] The named parameter 'p' isn't defined.
}
''');
  }

  test_enumConstant() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v(a: 0);
//  ^
// [diag.undefinedNamedParameter] The named parameter 'a' isn't defined.
  const E();
}
''');
  }

  test_function() async {
    await resolveTestCodeWithDiagnostics('''
f({a, b}) {}
main() {
  f(c: 1);
//  ^
// [diag.undefinedNamedParameter] The named parameter 'c' isn't defined.
}''');
  }

  test_method() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  m() {}
}
main() {
  A().m(p: 0);
//      ^
// [diag.undefinedNamedParameter] The named parameter 'p' isn't defined.
}
''');
  }
}
