// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
    await resolveTestCodeWithDiagnostics(r'''
/// {@animation 600 400 http://google.com id=my-id}
class C {}
''');
  }

  test_animation_hasThreeArguments() async {
    await resolveTestCodeWithDiagnostics(r'''
/// {@animation 600 400 http://google.com}
class C {}
''');
  }

  test_animation_missingHeight() async {
    await resolveTestCodeWithDiagnostics(r'''
/// {@animation 600}
// [diag.docDirectiveMissingTwoArguments][column 5][length 17] The 'animation' directive is missing a 'height' and a 'url' argument.
class C {}
''');
  }

  test_youtube_hasThreeArguments() async {
    await resolveTestCodeWithDiagnostics(r'''
/// {@youtube 600 400 https://www.youtube.com/watch?v=123}
class C {}
''');
  }

  test_youtube_missingHeight() async {
    await resolveTestCodeWithDiagnostics(r'''
/// {@youtube 600}
// [diag.docDirectiveMissingTwoArguments][column 5][length 15] The 'youtube' directive is missing a 'height' and a 'url' argument.
class C {}
''');
  }

  test_youtube_missingHeight_andCurlyBrace() async {
    await resolveTestCodeWithDiagnostics(r'''
/// {@youtube 600
// [diag.docDirectiveMissingTwoArguments][column 5][length 14] The 'youtube' directive is missing a 'height' and a 'url' argument.
// [diag.docDirectiveMissingClosingBrace][column 18][length 1] Doc directive is missing a closing curly brace ('}').
class C {}
''');
  }
}
