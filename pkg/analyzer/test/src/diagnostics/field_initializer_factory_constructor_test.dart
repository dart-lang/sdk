// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FieldInitializerFactoryConstructorTest);
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
    await assertErrorsInCode(
      r'''
// @dart = 3.5
class A {
  int Function()? x;
  factory A(int this.x());
}
''',
      [
        // TODO(srawlins): Only report one error. Theoretically change Fasta to
        // report "Field initializer in factory constructor" as a parse error.
        error(diag.fieldInitializerFactoryConstructor, 58, 12),
        error(diag.missingFunctionBody, 71, 1),
      ],
    );
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
