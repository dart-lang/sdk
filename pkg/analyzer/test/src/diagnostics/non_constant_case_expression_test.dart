// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NonConstantCaseExpressionTest);
    defineReflectiveTests(NonConstantCaseExpressionTest_Language219);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class NonConstantCaseExpressionTest extends PubPackageResolutionTest {
  test_constField() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(C e) {
  switch (e) {
    case C.zero:
      break;
    default:
      break;
  }
}

class C {
  static const zero = C(0);

  final int a;
  const C(this.a);
}
''');
  }

  test_typeLiteral() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(e) {
  switch (e) {
    case bool:
    case int:
      break;
    default:
      break;
  }
}
''');
  }
}

@reflectiveTest
class NonConstantCaseExpressionTest_Language219 extends PubPackageResolutionTest
    with WithLanguage219Mixin {
  test_constField() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(C e) {
  switch (e) {
    case C.zero:
      break;
    default:
      break;
  }
}

class C {
  static const zero = C(0);

  final int a;
  const C(this.a);
}
''');
  }

  test_parameter() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(var e, int a) {
  switch (e) {
    case 3 + a:
//           ^
// [diag.nonConstantCaseExpression] Case expressions must be constant.
      break;
  }
}
''');
  }

  test_typeLiteral() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(e) {
  switch (e) {
    case bool:
    case int:
      break;
    default:
      break;
  }
}
''');
  }
}
