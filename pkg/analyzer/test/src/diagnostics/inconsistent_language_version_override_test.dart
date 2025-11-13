// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InconsistentLanguageVersionOverrideTest);
  });
}

@reflectiveTest
class InconsistentLanguageVersionOverrideTest extends PubPackageResolutionTest {
  test_0_00_000_AAA() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
// @dart = 3.10
part 'b.dart';
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
// @dart = 3.10
part of 'a.dart';
part 'c.dart';
''');

    var c = newFile('$testPackageLibPath/c.dart', r'''
// @dart = 3.10
part of 'b.dart';
''');

    await assertErrorsInFile2(a, []);
    await assertErrorsInFile2(b, []);
    await assertErrorsInFile2(c, []);
  }

  test_0_00_000_AAB() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
// @dart = 3.10
part 'b.dart';
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
// @dart = 3.10
part of 'a.dart';
part 'c.dart';
''');

    var c = newFile('$testPackageLibPath/c.dart', r'''
// @dart = 3.11
part of 'b.dart';
''');

    await assertErrorsInFile2(a, []);
    await assertErrorsInFile2(b, [
      error(diag.inconsistentLanguageVersionOverride, 39, 8),
    ]);
    await assertErrorsInFile2(c, []);
  }

  test_0_00_000_AAN() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
// @dart = 3.10
part 'b.dart';
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
// @dart = 3.10
part of 'a.dart';
part 'c.dart';
''');

    var c = newFile('$testPackageLibPath/c.dart', r'''
part of 'b.dart';
''');

    await assertErrorsInFile2(a, []);
    await assertErrorsInFile2(b, [
      error(diag.inconsistentLanguageVersionOverride, 39, 8),
    ]);
    await assertErrorsInFile2(c, []);
  }

  test_0_00_000_ABB() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
// @dart = 3.10
part 'b.dart';
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
// @dart = 3.11
part of 'a.dart';
part 'c.dart';
''');

    var c = newFile('$testPackageLibPath/c.dart', r'''
// @dart = 3.11
part of 'b.dart';
''');

    await assertErrorsInFile2(a, [
      error(diag.inconsistentLanguageVersionOverride, 21, 8),
    ]);
    await assertErrorsInFile2(b, []);
    await assertErrorsInFile2(c, []);
  }

  test_0_00_000_NAA() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
// @dart = 3.10
part of 'a.dart';
part 'c.dart';
''');

    var c = newFile('$testPackageLibPath/c.dart', r'''
// @dart = 3.10
part of 'b.dart';
''');

    await assertErrorsInFile2(a, [
      error(diag.inconsistentLanguageVersionOverride, 5, 8),
    ]);
    await assertErrorsInFile2(b, []);
    await assertErrorsInFile2(c, []);
  }

  test_0_00_AA() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
// @dart = 3.2
part 'b.dart';
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
// @dart = 3.2
part of 'a.dart';
''');

    await assertErrorsInFile2(a, []);
    await assertErrorsInFile2(b, []);
  }

  test_0_00_AB() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
// @dart = 3.1
part 'b.dart';
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
// @dart = 3.2
part of 'a.dart';
''');

    await assertErrorsInFile2(a, [
      error(diag.inconsistentLanguageVersionOverride, 20, 8),
    ]);
    await assertErrorsInFile2(b, []);
  }

  test_0_00_NA() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
// @dart = 3.1
part of 'a.dart';
''');

    await assertErrorsInFile2(a, [
      error(diag.inconsistentLanguageVersionOverride, 5, 8),
    ]);
    await assertErrorsInFile2(b, []);
  }

  test_0_00_NN() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';
''');

    await assertErrorsInFile2(a, []);
    await assertErrorsInFile2(b, []);
  }
}
