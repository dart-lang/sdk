// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DuplicatePartTest);
  });
}

@reflectiveTest
class DuplicatePartTest extends PubPackageResolutionTest {
  test_library_sameSource() async {
    newFile('$testPackageLibPath/part.dart', r'''
part of 'test.dart';
''');

    await resolveTestCodeWithDiagnostics(r'''
part 'part.dart';
part 'foo/../part.dart';
//   ^^^^^^^^^^^^^^^^^^
// [diag.duplicatePart] The library already contains a part with the URI 'package:test/part.dart'.
''');
  }

  test_library_sameUri() async {
    newFile('$testPackageLibPath/part.dart', r'''
part of 'test.dart';
''');

    await resolveTestCodeWithDiagnostics(r'''
part 'part.dart';
part 'part.dart';
//   ^^^^^^^^^^^
// [diag.duplicatePart] The library already contains a part with the URI 'package:test/part.dart'.
''');
  }

  test_no_duplicates() async {
    newFile('$testPackageLibPath/part1.dart', '''
part of 'test.dart';
''');

    newFile('$testPackageLibPath/part2.dart', '''
part of 'test.dart';
''');

    await resolveTestCodeWithDiagnostics(r'''
part 'part1.dart';
part 'part2.dart';
''');
  }

  test_part_includesSelf() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';
part 'b.dart';
''');

    await assertErrorsInFile2(a, []);

    await assertErrorsInFile2(b, [error(diag.duplicatePart, 23, 8)]);
  }
}
