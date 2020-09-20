// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidAnnotationTest);
  });
}

@reflectiveTest
class InvalidAnnotationTest extends PubPackageResolutionTest {
  test_importWithPrefix_notConstantVariable() async {
    newFile('$testPackageLibPath/lib.dart', content: r'''
library lib;
final V = 0;
''');
    await assertErrorsInCode(r'''
import 'lib.dart' as p;
@p.V
main() {
}
''', [
      error(CompileTimeErrorCode.INVALID_ANNOTATION, 24, 4),
    ]);
  }

  test_importWithPrefix_notVariableOrConstructorInvocation() async {
    newFile('$testPackageLibPath/lib.dart', content: r'''
library lib;
typedef V();
''');
    await assertErrorsInCode(r'''
import 'lib.dart' as p;
@p.V
main() {
}
''', [
      error(CompileTimeErrorCode.INVALID_ANNOTATION, 24, 4),
    ]);
  }

  test_notConstantVariable() async {
    await assertErrorsInCode(r'''
final V = 0;
@V
main() {
}
''', [
      error(CompileTimeErrorCode.INVALID_ANNOTATION, 13, 2),
    ]);
  }

  test_notVariableOrConstructorInvocation() async {
    await assertErrorsInCode(r'''
typedef V();
@V
main() {
}
''', [
      error(CompileTimeErrorCode.INVALID_ANNOTATION, 13, 2),
    ]);
  }

  test_staticMethodReference() async {
    await assertErrorsInCode(r'''
class A {
  static f() {}
}
@A.f
main() {
}
''', [
      error(CompileTimeErrorCode.INVALID_ANNOTATION, 28, 4),
    ]);
  }
}
