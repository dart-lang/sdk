// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DuplicateShownNameTest);
  });
}

@reflectiveTest
class DuplicateShownNameTest extends PubPackageResolutionTest {
  test_library_shown() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
class A {}
class B {}
''');
    await assertErrorsInCode('''
export 'lib1.dart' show A, B, A;
''', [
      error(WarningCode.DUPLICATE_SHOWN_NAME, 30, 1),
    ]);
  }

  test_part_shown() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';
export 'dart:math' show pi, Random, pi;
''');

    await assertErrorsInFile2(a, []);

    await assertErrorsInFile2(b, [
      error(WarningCode.DUPLICATE_SHOWN_NAME, 54, 2),
    ]);
  }
}
