// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
    await resolveTestCodeWithDiagnostics(r'''
/// {@animation 600 400 http://google.com}
class C {}
''');
  }

  test_animation_missingWidth() async {
    await resolveTestCodeWithDiagnostics(r'''
/// {@animation}
// [diag.docDirectiveMissingThreeArguments][column 5][length 13] The 'animation' directive is missing a 'width', a 'height', and a 'url' argument.
class C {}
''');
  }

  test_youtube_hasWidth() async {
    await resolveTestCodeWithDiagnostics(r'''
/// {@youtube 600 400 https://www.youtube.com/watch?v=123}
class C {}
''');
  }

  test_youtube_missingWidth() async {
    await resolveTestCodeWithDiagnostics(r'''
/// {@youtube}
// [diag.docDirectiveMissingThreeArguments][column 5][length 11] The 'youtube' directive is missing a 'width', a 'height', and a 'url' argument.
class C {}
''');
  }

  test_youtube_missingWidth_andCurlyBrace() async {
    await resolveTestCodeWithDiagnostics(r'''
/// {@youtube
// [diag.docDirectiveMissingThreeArguments][column 5][length 10] The 'youtube' directive is missing a 'width', a 'height', and a 'url' argument.
class C {}
''');
  }
}
