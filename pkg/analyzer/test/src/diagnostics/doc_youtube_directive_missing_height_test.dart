// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.g.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DocYouTubeDirectiveMissingHeightTest);
  });
}

@reflectiveTest
class DocYouTubeDirectiveMissingHeightTest extends PubPackageResolutionTest {
  test_hasHeight() async {
    await assertNoErrorsInCode('''
/// {@youtube 600 400 http://google.com}
class C {}
''');
  }

  test_missingHeight() async {
    await assertErrorsInCode('''
/// {@youtube 600}
class C {}
''', [
      error(WarningCode.DOC_YOUTUBE_DIRECTIVE_MISSING_HEIGHT, 4, 15),
    ]);
  }

  test_missingHeight_andCurlyBrace() async {
    await assertErrorsInCode('''
/// {@youtube 600
class C {}
''', [
      error(WarningCode.DOC_YOUTUBE_DIRECTIVE_MISSING_HEIGHT, 4, 14),
      error(WarningCode.DOC_DIRECTIVE_MISSING_CLOSING_BRACE, 13, 1),
    ]);
  }
}
