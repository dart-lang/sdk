// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UndefinedHiddenNameTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class UndefinedHiddenNameTest extends PubPackageResolutionTest {
  test_export() async {
    newFile('$testPackageLibPath/lib1.dart', '');
    await resolveTestCodeWithDiagnostics(r'''
export 'lib1.dart' hide a;
//                      ^
// [diag.undefinedHiddenName] The library 'package:test/lib1.dart' doesn't export a member with the hidden name 'a'.
''');
  }

  test_import() async {
    newFile('$testPackageLibPath/lib1.dart', '');
    await resolveTestCodeWithDiagnostics(r'''
import 'lib1.dart' hide a;
//     ^^^^^^^^^^^
// [diag.unusedImport] Unused import: 'lib1.dart'.
//                      ^
// [diag.undefinedHiddenName] The library 'package:test/lib1.dart' doesn't export a member with the hidden name 'a'.
''');
  }
}
