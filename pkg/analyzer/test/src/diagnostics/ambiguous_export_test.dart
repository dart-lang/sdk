// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AmbiguousExportTest);
  });
}

@reflectiveTest
class AmbiguousExportTest extends PubPackageResolutionTest {
  test_library_class() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
class N {}
''');
    newFile('$testPackageLibPath/lib2.dart', r'''
class N {}
''');
    await assertErrorsInCode(r'''
export 'lib1.dart';
export 'lib2.dart';
''', [
      error(CompileTimeErrorCode.AMBIGUOUS_EXPORT, 27, 11),
    ]);
  }

  test_library_extensions_bothExported() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
extension E on String {}
''');
    newFile('$testPackageLibPath/lib2.dart', r'''
extension E on String {}
''');
    await assertErrorsInCode(r'''
export 'lib1.dart';
export 'lib2.dart';
''', [
      error(CompileTimeErrorCode.AMBIGUOUS_EXPORT, 27, 11),
    ]);
  }

  test_library_extensions_localAndExported() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
extension E on String {}
''');
    await assertNoErrorsInCode(r'''
export 'lib1.dart';

extension E on String {}
''');
  }

  test_part_library() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
class N {}
''');

    newFile('$testPackageLibPath/lib2.dart', r'''
class N {}
''');

    var a = newFile('$testPackageLibPath/a.dart', r'''
export 'lib1.dart';
part 'b.dart';
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';
export 'lib2.dart';
''');

    await assertErrorsInFile2(a, []);

    await assertErrorsInFile2(b, [
      error(CompileTimeErrorCode.AMBIGUOUS_EXPORT, 25, 11),
    ]);
  }

  test_part_part() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
class N {}
''');

    newFile('$testPackageLibPath/lib2.dart', r'''
class N {}
''');

    var a = newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';
part 'c.dart';
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';
export 'lib1.dart';
''');

    var c = newFile('$testPackageLibPath/c.dart', r'''
part of 'a.dart';
export 'lib2.dart';
''');

    await assertErrorsInFile2(a, []);

    await assertErrorsInFile2(b, []);

    await assertErrorsInFile2(c, [
      error(CompileTimeErrorCode.AMBIGUOUS_EXPORT, 25, 11),
    ]);
  }
}
