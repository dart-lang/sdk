// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PartOfNonPartTest);
  });
}

@reflectiveTest
class PartOfNonPartTest extends PubPackageResolutionTest {
  test_noPartOf() async {
    newFile('$testPackageLibPath/l2.dart', '''
library l2;
''');
    await assertErrorsInCode(r'''
library l1;
part 'l2.dart';
''', [
      error(CompileTimeErrorCode.PART_OF_NON_PART, 17, 9),
    ]);
  }

  test_partOf_dotted() async {
    newFile('$testPackageLibPath/a.dart', '''
part of foo.bar;
''');

    // No error reported in the library, only in the part.
    await assertNoErrorsInCode(r'''
library foo.bar;
part 'a.dart';
''');
  }

  test_self() async {
    await assertErrorsInCode(r'''
library lib;
part 'test.dart';
''', [
      error(CompileTimeErrorCode.PART_OF_NON_PART, 18, 11),
    ]);
  }
}
