// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.g.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DocDirectiveMissingOneArgumentTest);
  });
}

@reflectiveTest
class DocDirectiveMissingOneArgumentTest extends PubPackageResolutionTest {
  test_animation_hasOptionalIdArgument() async {
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

  test_canonicalFor_hasNoArguments() async {
    await assertErrorsInCode('''
/// {@canonicalFor}
class C {}
''', [
      error(WarningCode.DOC_DIRECTIVE_MISSING_ONE_ARGUMENT, 4, 16),
    ]);
  }

  test_canonicalFor_hasOneArguments() async {
    await assertNoErrorsInCode('''
/// {@canonicalFor String}
class C {}
''');
  }

  test_macro_hasNoArguments() async {
    await assertErrorsInCode('''
/// {@macro}
class C {}
''', [
      error(WarningCode.DOC_DIRECTIVE_MISSING_ONE_ARGUMENT, 4, 9),
    ]);
  }

  test_youtube_hasThreeArguments() async {
    await assertNoErrorsInCode('''
/// {@youtube 600 400 https://www.youtube.com/watch?v=123}
class C {}
''');
  }

  test_youtube_missingUrl() async {
    await assertErrorsInCode('''
/// {@youtube 600 400}
class C {}
''', [
      error(WarningCode.DOC_DIRECTIVE_MISSING_ONE_ARGUMENT, 4, 19),
    ]);
  }

  test_youtube_missingUrl_andCurlyBrace() async {
    await assertErrorsInCode('''
/// {@youtube 600 400
class C {}
''', [
      error(WarningCode.DOC_DIRECTIVE_MISSING_ONE_ARGUMENT, 4, 18),
      error(WarningCode.DOC_DIRECTIVE_MISSING_CLOSING_BRACE, 21, 1),
    ]);
  }
}
