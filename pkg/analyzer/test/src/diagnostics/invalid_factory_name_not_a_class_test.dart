// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidFactoryNameNotAClassTest);
  });
}

@reflectiveTest
class InvalidFactoryNameNotAClassTest extends PubPackageResolutionTest {
  test_notClassName() async {
    await assertErrorsInCode(r'''
int B = 0;
class A {
  factory B() => throw 0;
}
''', [
      error(CompileTimeErrorCode.INVALID_FACTORY_NAME_NOT_A_CLASS, 31, 1),
    ]);
  }

  test_notEnclosingClassName() async {
    await assertErrorsInCode(r'''
class A {
  factory B() => throw 0;
}
''', [
      error(CompileTimeErrorCode.INVALID_FACTORY_NAME_NOT_A_CLASS, 20, 1),
    ]);
  }

  test_notEnclosingClassName_inAugmentation() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';

class A {}
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';

augment class A {
  factory B() => throw 0;
}
''');

    await resolveFile2(b);
    assertErrorsInResult([
      error(CompileTimeErrorCode.INVALID_FACTORY_NAME_NOT_A_CLASS, 47, 1),
    ]);
  }

  test_valid() async {
    await assertNoErrorsInCode(r'''
class A {
  factory A() => throw 0;
}
''');
  }

  test_valid_inAugmentation() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';

class A {}

class B implements A {
  const B();
}
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';

augment class A {
  const factory A() = B;
}
''');

    await resolveFile2(b);
    assertNoErrorsInResult();
  }
}
