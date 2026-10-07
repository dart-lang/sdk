// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DocImportInPartFileTest);
  });
}

@reflectiveTest
class DocImportInPartFileTest extends PubPackageResolutionTest {
  test_enhancedParts_disabled() async {
    var part = getFile('$testPackageLibPath/part.dart');
    await resolveFilesWithDiagnostics({
      testFile: r'''
// %before-language-feature: enhanced-parts
part 'part.dart';
''',
      part: r'''
// %before-language-feature: enhanced-parts
/// @docImport 'dart:math';
//             ^^^^^^^^^^^
// [diag.docImportInPartFile] Doc imports in part files require the 'enhanced-parts' language feature.
/// @docImport 'foo.dart';
//             ^^^^^^^^^^
// [diag.docImportInPartFile] Doc imports in part files require the 'enhanced-parts' language feature.
part of 'test.dart';
''',
    });
  }

  test_enhancedParts_enabled() async {
    var part = getFile('$testPackageLibPath/part.dart');
    await resolveFilesWithDiagnostics({
      testFile: r'''
part 'part.dart';
''',
      part: r'''
/// @docImport 'dart:math';
part of 'test.dart';
''',
    });
  }
}
