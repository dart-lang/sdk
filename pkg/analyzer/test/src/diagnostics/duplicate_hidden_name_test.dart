// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DuplicateHiddenNameTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class DuplicateHiddenNameTest extends PubPackageResolutionTest {
  test_library_hidden() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
class A {}
class B {}
''');
    await resolveTestCodeWithDiagnostics(r'''
export 'lib1.dart' hide A, B, A;
//                            ^
// [diag.duplicateHiddenName] Duplicate hidden name.
''');
  }

  test_part_hidden() async {
    var a = getFile('$testPackageLibPath/a.dart');
    var b = getFile('$testPackageLibPath/b.dart');

    await resolveFilesWithDiagnostics({
      a: r'''
part 'b.dart';
''',
      b: r'''
part of 'a.dart';
export 'dart:math' hide pi, Random, pi;
//                                  ^^
// [diag.duplicateHiddenName] Duplicate hidden name.
''',
    });
  }
}
