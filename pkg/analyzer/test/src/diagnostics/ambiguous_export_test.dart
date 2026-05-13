// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AmbiguousExportTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
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
    await resolveTestCodeWithDiagnostics(r'''
export 'lib1.dart';
export 'lib2.dart';
//     ^^^^^^^^^^^
// [diag.ambiguousExport] The name 'N' is defined in the libraries 'package:test/lib1.dart' and 'package:test/lib2.dart'.
''');
  }

  test_library_extensions_bothExported() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
extension E on String {}
''');
    newFile('$testPackageLibPath/lib2.dart', r'''
extension E on String {}
''');
    await resolveTestCodeWithDiagnostics(r'''
export 'lib1.dart';
export 'lib2.dart';
//     ^^^^^^^^^^^
// [diag.ambiguousExport] The name 'E' is defined in the libraries 'package:test/lib1.dart' and 'package:test/lib2.dart'.
''');
  }

  test_library_extensions_localAndExported() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
extension E on String {}
''');
    await resolveTestCodeWithDiagnostics(r'''
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

    await assertErrorsInFile2(b, [error(diag.ambiguousExport, 25, 11)]);
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

    await assertErrorsInFile2(c, [error(diag.ambiguousExport, 25, 11)]);
  }
}
