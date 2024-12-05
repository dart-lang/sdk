// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(EnumWithoutConstantsTest);
  });
}

@reflectiveTest
class EnumWithoutConstantsTest extends PubPackageResolutionTest {
  test_hasConstants_inAugmentation() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment enum E {
  v
}
''');

    await assertNoErrorsInCode('''
part 'a.dart';
enum E {}
''');
  }

  test_noConstants() async {
    await assertErrorsInCode('''
enum E {}
''', [
      error(CompileTimeErrorCode.ENUM_WITHOUT_CONSTANTS, 5, 1),
    ]);
  }

  test_noConstants_hasAugmentation() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';
enum E {}
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';
augment enum E {}
''');

    await assertErrorsInFile2(a, [
      error(CompileTimeErrorCode.ENUM_WITHOUT_CONSTANTS, 20, 1),
    ]);

    await assertErrorsInFile2(b, []);
  }
}
