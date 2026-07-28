// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnnecessaryFinalTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class UnnecessaryFinalTest extends PubPackageResolutionTest {
  test_final() async {
    await resolveTestCodeWithDiagnostics('''
// @dart = 3.10
class C {
  C(final int value);
}
''');
  }

  test_positional() async {
    await resolveTestCodeWithDiagnostics('''
// @dart = 3.10
class C {
  C([final this.value = 0]);
//   ^^^^^
// [diag.unnecessaryFinal] The keyword 'final' isn't necessary because the parameter is implicitly 'final'.
  int value;
}
''');
  }

  test_primaryConstructor_declaringParameter() async {
    await resolveTestCodeWithDiagnostics('''
class C(final this.x) {
//            ^^^^
// [diag.initializingDeclaringParameter] Declaring parameters can't be initializing.
  int x;
}
''');
  }

  test_primaryConstructor_parameter() async {
    await resolveTestCodeWithDiagnostics('''
class C(final int x);
''');
  }

  test_super() async {
    await resolveTestCodeWithDiagnostics('''
// @dart = 3.10
class A {
  A(this.value);
  int value;
}

class B extends A {
  B(final super.value);
//  ^^^^^
// [diag.unnecessaryFinal] The keyword 'final' isn't necessary because the parameter is implicitly 'final'.
}
''');
  }

  test_this() async {
    await resolveTestCodeWithDiagnostics('''
// @dart = 3.10
class C {
  C(final this.value);
//  ^^^^^
// [diag.unnecessaryFinal] The keyword 'final' isn't necessary because the parameter is implicitly 'final'.
  int value;
}
''');
  }
}
