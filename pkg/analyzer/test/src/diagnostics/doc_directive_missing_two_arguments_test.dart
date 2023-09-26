// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.g.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DocDirectiveMissingTwoArgumentsTest);
  });
}

@reflectiveTest
class DocDirectiveMissingTwoArgumentsTest extends PubPackageResolutionTest {
  test_animation_hasOptionalIdParameter() async {
    await assertNoErrorsInCode('''
/// {@animation 600 400 http://google.com id=my-id}
class C {}
''');
  }

  test_animation_hasThreeArguments() async {
    await assertNoErrorsInCode('''
/// {@animation 600 400 http://google.com}
class C {}
''');
  }

  test_animation_missingHeight() async {
    await assertErrorsInCode('''
/// {@animation 600}
class C {}
''', [
      error(WarningCode.DOC_DIRECTIVE_MISSING_TWO_ARGUMENTS, 4, 17),
    ]);
  }

  test_youtube_hasThreeArguments() async {
    await assertNoErrorsInCode('''
/// {@youtube 600 400 https://www.youtube.com/watch?v=123}
class C {}
''');
  }

  test_youtube_missingHeight() async {
    await assertErrorsInCode('''
/// {@youtube 600}
class C {}
''', [
      error(WarningCode.DOC_DIRECTIVE_MISSING_TWO_ARGUMENTS, 4, 15),
    ]);
  }

  test_youtube_missingHeight_andCurlyBrace() async {
    await assertErrorsInCode('''
/// {@youtube 600
class C {}
''', [
      error(WarningCode.DOC_DIRECTIVE_MISSING_TWO_ARGUMENTS, 4, 14),
      error(WarningCode.DOC_DIRECTIVE_MISSING_CLOSING_BRACE, 17, 1),
    ]);
  }
}
