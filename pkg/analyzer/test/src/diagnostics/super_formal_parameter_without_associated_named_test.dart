// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SuperFormalParameterWithoutAssociatedNamedTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class SuperFormalParameterWithoutAssociatedNamedTest
    extends PubPackageResolutionTest {
  test_explicit_optional() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}

class B extends A {
  B({super.a}) : super();
//         ^
// [diag.superFormalParameterWithoutAssociatedNamed] No associated named super constructor parameter.
}
''');
  }

  test_explicit_required() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}

class B extends A {
  B({required super.a}) : super();
//                  ^
// [diag.superFormalParameterWithoutAssociatedNamed] No associated named super constructor parameter.
}
''');
  }

  test_implicit_optional() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}

class B extends A {
  B({super.a});
//         ^
// [diag.superFormalParameterWithoutAssociatedNamed] No associated named super constructor parameter.
}
''');
  }

  test_implicit_required() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}

class B extends A {
  B({required super.a});
//                  ^
// [diag.superFormalParameterWithoutAssociatedNamed] No associated named super constructor parameter.
}
''');
  }
}
