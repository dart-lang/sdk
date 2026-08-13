// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FieldInitializerFactoryConstructorTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class FieldInitializerFactoryConstructorTest extends PubPackageResolutionTest {
  test_class_fieldFormalParameter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int x = 0;
  factory A(this.x) => throw 0;
//          ^^^^^^
// [diag.fieldInitializerFactoryConstructor] Initializing formal parameters can't be used in factory constructors.
}
''');
  }

  test_class_fieldFormalParameter_functionTyped() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int Function()? x;
  factory A(int this.x());
//          ^^^^^^^^^^^^
// [diag.fieldInitializerFactoryConstructor] Initializing formal parameters can't be used in factory constructors.
}
''');
  }

  test_class_fieldFormalParameter_functionTyped_language305() async {
    // TODO(srawlins): Only report one error. Theoretically change Fasta to
    // report "Field initializer in factory constructor" as a parse error.
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.5
class A {
  int Function()? x;
  factory A(int this.x());
//          ^^^^^^^^^^^^
// [diag.fieldInitializerFactoryConstructor] Initializing formal parameters can't be used in factory constructors.
//                       ^
// [diag.missingFunctionBody] A function body must be provided.
}
''');
  }

  test_enum_fieldFormalParameter() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  final int x = 0;
  const E();
  factory E._(this.x) => throw 0;
//            ^^^^^^
// [diag.fieldInitializerFactoryConstructor] Initializing formal parameters can't be used in factory constructors.
}

void f() {
  E._(0);
}
''');
  }
}
