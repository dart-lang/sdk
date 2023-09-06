// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.g.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DocYouTubeDirectiveMissingUrlTest);
  });
}

@reflectiveTest
class DocYouTubeDirectiveMissingUrlTest extends PubPackageResolutionTest {
  test_hasUrl() async {
    await assertNoErrorsInCode('''
/// {@youtube 600 400 http://google.com}
class C {}
''');
  }

  test_missingUrl() async {
    await assertErrorsInCode('''
/// {@youtube 600 400}
class C {}
''', [
      error(WarningCode.DOC_YOUTUBE_DIRECTIVE_MISSING_URL, 4, 19),
    ]);
  }

  test_missingUrl_andCurlyBrace() async {
    await assertErrorsInCode('''
/// {@youtube 600 400
class C {}
''', [
      error(WarningCode.DOC_YOUTUBE_DIRECTIVE_MISSING_URL, 4, 18),
      error(WarningCode.DOC_DIRECTIVE_MISSING_CLOSING_BRACE, 17, 1),
    ]);
  }
}
