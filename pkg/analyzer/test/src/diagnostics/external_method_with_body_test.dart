// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExternalMethodWithBodyTest);
  });
}

@reflectiveTest
class ExternalMethodWithBodyTest extends PubPackageResolutionTest {
  test_class_getter_external_blockBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  external int get foo {}
//                 ^^^
// [diag.bodyMightCompleteNormally] The body might complete normally, causing 'null' to be returned, but the return type, 'int', is a potentially non-nullable type.
//                     ^
// [diag.externalMethodWithBody] An external or native method can't have a body.
}
''');
  }

  test_class_getter_external_expressionBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  external int get foo => 0;
//                     ^^
// [diag.externalMethodWithBody] An external or native method can't have a body.
}
''');
  }

  test_class_method_external_blockBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  external void foo() {}
//                    ^
// [diag.externalMethodWithBody] An external or native method can't have a body.
}
''');
  }

  test_class_method_external_expressionBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  external void foo() => null;
//                    ^^
// [diag.externalMethodWithBody] An external or native method can't have a body.
}
''');
  }

  test_class_operator_external_blockBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  external int operator +(int other) {}
//                      ^
// [diag.bodyMightCompleteNormally] The body might complete normally, causing 'null' to be returned, but the return type, 'int', is a potentially non-nullable type.
//                                   ^
// [diag.externalMethodWithBody] An external or native method can't have a body.
}
''');
  }

  test_class_setter_external_blockBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  external void set foo(int v) {}
//                             ^
// [diag.externalMethodWithBody] An external or native method can't have a body.
}
''');
  }

  test_topLevelFunction_external_blockBody() async {
    await resolveTestCodeWithDiagnostics(r'''
external void foo() {}
//                  ^
// [diag.externalMethodWithBody] An external or native method can't have a body.
''');
  }

  test_topLevelFunction_external_expressionBody() async {
    await resolveTestCodeWithDiagnostics(r'''
external void foo() => null;
//                  ^^
// [diag.externalMethodWithBody] An external or native method can't have a body.
''');
  }
}
