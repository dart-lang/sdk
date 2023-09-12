// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.g.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DocDirectiveMissingThreeArgumentsTest);
  });
}

@reflectiveTest
class DocDirectiveMissingThreeArgumentsTest extends PubPackageResolutionTest {
  test_animation_hasWidth() async {
    await assertNoErrorsInCode('''
/// {@animation 600 400 http://google.com}
class C {}
''');
  }

  test_animation_missingWidth() async {
    await assertErrorsInCode('''
/// {@animation}
class C {}
''', [
      error(WarningCode.DOC_DIRECTIVE_MISSING_THREE_ARGUMENTS, 4, 13),
    ]);
  }

  test_youtube_hasWidth() async {
    await assertNoErrorsInCode('''
/// {@youtube 600 400 http://google.com}
class C {}
''');
  }

  test_youtube_missingWidth() async {
    await assertErrorsInCode('''
/// {@youtube}
class C {}
''', [
      error(WarningCode.DOC_DIRECTIVE_MISSING_THREE_ARGUMENTS, 4, 11),
    ]);
  }

  test_youtube_missingWidth_andCurlyBrace() async {
    await assertErrorsInCode('''
/// {@youtube
class C {}
''', [
      error(WarningCode.DOC_DIRECTIVE_MISSING_THREE_ARGUMENTS, 4, 10),
    ]);
  }
}
