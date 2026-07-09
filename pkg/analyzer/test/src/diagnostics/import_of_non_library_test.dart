// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ImportOfNonLibraryTest);
  });
}

@reflectiveTest
class ImportOfNonLibraryTest extends PubPackageResolutionTest {
  test_deferred() async {
    newFile('$testPackageLibPath/lib1.dart', '''
part of lib;
''');
    await resolveTestCodeWithDiagnostics(r'''
library lib;
import 'lib1.dart' deferred as p;
//     ^^^^^^^^^^^
// [diag.importOfNonLibrary] The imported library 'lib1.dart' can't have a part-of directive.
''');
  }

  test_part() async {
    newFile('$testPackageLibPath/part.dart', r'''
part of lib;
''');
    await resolveTestCodeWithDiagnostics(r'''
library lib;
import 'part.dart';
//     ^^^^^^^^^^^
// [diag.importOfNonLibrary] The imported library 'part.dart' can't have a part-of directive.
''');
  }
}
