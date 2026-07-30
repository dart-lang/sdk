// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstEvalTypeBoolNumStringTest);
  });
}

@reflectiveTest
class ConstEvalTypeBoolNumStringTest extends PubPackageResolutionTest {
  test_equal_double_object_beforePatterns() async {
    await resolveTestCodeWithDiagnostics(r'''
// %before-language-feature: patterns
const a = 0.1;
const b = a == Object();
''');
  }

  test_equal_userClass_int_beforePatterns() async {
    await resolveTestCodeWithDiagnostics(r'''
// %before-language-feature: patterns
class A {
  const A();
}

const a = A();
const b = a == 0;
//        ^^^^^^
// [diag.constEvalTypeBoolNumString] In constant expressions, operands of this operator must be of type 'bool', 'num', 'String' or 'null'.
''');
  }

  test_notEqual_double_object_beforePatterns() async {
    await resolveTestCodeWithDiagnostics(r'''
// %before-language-feature: patterns
const a = 0.1;
const b = a != Object();
''');
  }

  test_notEqual_userClass_int_beforePatterns() async {
    await resolveTestCodeWithDiagnostics(r'''
// %before-language-feature: patterns
class A {
  const A();
}

const a = A();
const b = a != 0;
//        ^^^^^^
// [diag.constEvalTypeBoolNumString] In constant expressions, operands of this operator must be of type 'bool', 'num', 'String' or 'null'.
''');
  }

  test_stringInterpolation_list() async {
    await resolveTestCodeWithDiagnostics(r'''
const x = '${const [2]}';
//         ^^^^^^^^^^^^
// [diag.constEvalTypeBoolNumString] In constant expressions, operands of this operator must be of type 'bool', 'num', 'String' or 'null'.
''');
  }
}
