// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PartOfDifferentLibraryTest);
  });
}

@reflectiveTest
class PartOfDifferentLibraryTest extends PubPackageResolutionTest {
  test_doesNotExist() async {
    await assertErrorsInCode('''
part 'part.dart';
''', [
      error(CompileTimeErrorCode.URI_DOES_NOT_EXIST, 5, 11),
    ]);
  }

  test_doesNotExist_generated() async {
    await assertErrorsInCode('''
part 'part.g.dart';
''', [
      error(CompileTimeErrorCode.URI_HAS_NOT_BEEN_GENERATED, 5, 13),
    ]);
  }

  test_partOfName() async {
    newFile('$testPackageLibPath/part.dart', '''
part of bar;
''');

    await assertErrorsInCode('''
library foo;
part 'part.dart';
''', [
      error(CompileTimeErrorCode.PART_OF_DIFFERENT_LIBRARY, 18, 11),
    ]);
  }

  test_partOfUri() async {
    newFile('$testPackageLibPath/part.dart', '''
part of 'other.dart';
''');

    await assertErrorsInCode('''
part 'part.dart';
''', [
      error(CompileTimeErrorCode.PART_OF_DIFFERENT_LIBRARY, 5, 11),
    ]);
  }
}
