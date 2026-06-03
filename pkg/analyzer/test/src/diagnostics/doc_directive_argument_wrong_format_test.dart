// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
    await resolveTestCodeWithDiagnostics(r'''
/// {@animation 600 nan http://google.com}
//                  ^^^
// [diag.docDirectiveArgumentWrongFormat] The 'height' argument must be formatted as an integer.
class C {}
''');
  }

  test_animation_urlWrongFormat() async {
    await resolveTestCodeWithDiagnostics(r'''
/// {@animation 600 400 other}
class C {}
''');
  }

  test_animation_widthWrongFormat() async {
    await resolveTestCodeWithDiagnostics(r'''
/// {@animation nan 400 http://google.com}
//              ^^^
// [diag.docDirectiveArgumentWrongFormat] The 'width' argument must be formatted as an integer.
class C {}
''');
  }

  test_youtube_heightWrongFormat() async {
    await resolveTestCodeWithDiagnostics(r'''
/// {@youtube 600 nan https://www.youtube.com/watch?v=123}
//                ^^^
// [diag.docDirectiveArgumentWrongFormat] The 'height' argument must be formatted as an integer.
class C {}
''');
  }

  test_youtube_urlWrongFormat() async {
    await resolveTestCodeWithDiagnostics(r'''
/// {@youtube 600 400 http://google.com}
//                    ^^^^^^^^^^^^^^^^^
// [diag.docDirectiveArgumentWrongFormat] The 'url' argument must be formatted as a YouTube URL, starting with 'https://www.youtube.com/watch?v='.
class C {}
''');
  }

  test_youtube_widthWrongFormat() async {
    await resolveTestCodeWithDiagnostics(r'''
/// {@youtube nan 400 https://www.youtube.com/watch?v=123}
//            ^^^
// [diag.docDirectiveArgumentWrongFormat] The 'width' argument must be formatted as an integer.
class C {}
''');
  }
}
