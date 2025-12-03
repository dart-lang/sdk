// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
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
    await assertErrorsInCode(
      '''
library lib;
import 'lib1.dart' deferred as p;
''',
      [
        error(
          diag.importOfNonLibrary,
          20,
          11,
          messageContains: ["library 'lib1.dart' "],
        ),
      ],
    );
  }

  test_part() async {
    newFile('$testPackageLibPath/part.dart', r'''
part of lib;
''');
    await assertErrorsInCode(
      r'''
library lib;
import 'part.dart';
''',
      [
        error(
          diag.importOfNonLibrary,
          20,
          11,
          messageContains: ["library 'part.dart' "],
        ),
      ],
    );
  }
}
