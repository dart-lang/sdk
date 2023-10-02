// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.g.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DocDirectiveArgumentWrongFormatTest);
  });
}

@reflectiveTest
class DocDirectiveArgumentWrongFormatTest extends PubPackageResolutionTest {
  test_animation_heightWrongFormat() async {
    await assertErrorsInCode('''
/// {@animation 600 nan http://google.com}
class C {}
''', [
      error(WarningCode.DOC_DIRECTIVE_ARGUMENT_WRONG_FORMAT, 20, 3),
    ]);
  }

  test_animation_urlWrongFormat() async {
    await assertNoErrorsInCode('''
/// {@animation 600 400 other}
class C {}
''');
  }

  test_animation_widthWrongFormat() async {
    await assertErrorsInCode('''
/// {@animation nan 400 http://google.com}
class C {}
''', [
      error(WarningCode.DOC_DIRECTIVE_ARGUMENT_WRONG_FORMAT, 16, 3),
    ]);
  }

  test_youtube_heightWrongFormat() async {
    await assertErrorsInCode('''
/// {@youtube 600 nan https://www.youtube.com/watch?v=123}
class C {}
''', [
      error(WarningCode.DOC_DIRECTIVE_ARGUMENT_WRONG_FORMAT, 18, 3),
    ]);
  }

  test_youtube_urlWrongFormat() async {
    await assertErrorsInCode('''
/// {@youtube 600 400 http://google.com}
class C {}
''', [
      error(WarningCode.DOC_DIRECTIVE_ARGUMENT_WRONG_FORMAT, 22, 17),
    ]);
  }

  test_youtube_widthWrongFormat() async {
    await assertErrorsInCode('''
/// {@youtube nan 400 https://www.youtube.com/watch?v=123}
class C {}
''', [
      error(WarningCode.DOC_DIRECTIVE_ARGUMENT_WRONG_FORMAT, 14, 3),
    ]);
  }
}
