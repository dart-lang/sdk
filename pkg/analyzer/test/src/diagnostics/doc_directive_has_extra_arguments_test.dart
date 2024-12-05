// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.g.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DocDirectiveHasExtraArgumentsTest);
  });
}

@reflectiveTest
class DocDirectiveHasExtraArgumentsTest extends PubPackageResolutionTest {
  test_animation_hasExtraArgument() async {
    await assertErrorsInCode('''
/// {@animation 600 400 http://google.com foo}
class C {}
''', [
      error(WarningCode.DOC_DIRECTIVE_HAS_EXTRA_ARGUMENTS, 42, 3),
    ]);
  }

  test_animation_noExtraArguments() async {
    await assertNoErrorsInCode('''
/// {@animation 600 400 http://google.com}
class C {}
''');
  }

  test_animation_optionalNamedArgument() async {
    await assertNoErrorsInCode('''
/// {@animation 600 400 http://google.com id=my-id}
class C {}
''');
  }

  test_macro_hasExtraArgument() async {
    await assertErrorsInCode('''
/// {@macro one two}
class C {}
''', [
      error(WarningCode.DOC_DIRECTIVE_HAS_EXTRA_ARGUMENTS, 16, 3),
    ]);
  }

  test_youtube_hasExtraArgument() async {
    await assertErrorsInCode('''
/// {@youtube 600 400 https://www.youtube.com/watch?v=123 foo}
class C {}
''', [
      error(WarningCode.DOC_DIRECTIVE_HAS_EXTRA_ARGUMENTS, 58, 3),
    ]);
  }

  test_youtube_hasExtraArgument_trailingWhitespace() async {
    await assertErrorsInCode('''
/// {@youtube 600 400 https://www.youtube.com/watch?v=123 foo }
class C {}
''', [
      error(WarningCode.DOC_DIRECTIVE_HAS_EXTRA_ARGUMENTS, 58, 3),
    ]);
  }

  test_youtube_noExtraArguments() async {
    await assertNoErrorsInCode('''
/// {@youtube 600 400 https://www.youtube.com/watch?v=123}
class C {}
''');
  }
}
