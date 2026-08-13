// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
    await resolveTestCodeWithDiagnostics(r'''
/// {@animation 600 400 http://google.com foo}
//                                        ^^^
// [diag.docDirectiveHasExtraArguments] The 'animation' directive has '4' arguments, but only '3' are expected.
class C {}
''');
  }

  test_animation_noExtraArguments() async {
    await resolveTestCodeWithDiagnostics(r'''
/// {@animation 600 400 http://google.com}
class C {}
''');
  }

  test_animation_optionalNamedArgument() async {
    await resolveTestCodeWithDiagnostics(r'''
/// {@animation 600 400 http://google.com id=my-id}
class C {}
''');
  }

  test_macro_hasExtraArgument() async {
    await resolveTestCodeWithDiagnostics(r'''
/// {@macro one two}
//              ^^^
// [diag.docDirectiveHasExtraArguments] The 'macro' directive has '2' arguments, but only '1' are expected.
class C {}
''');
  }

  test_youtube_hasExtraArgument() async {
    await resolveTestCodeWithDiagnostics(r'''
/// {@youtube 600 400 https://www.youtube.com/watch?v=123 foo}
//                                                        ^^^
// [diag.docDirectiveHasExtraArguments] The 'youtube' directive has '4' arguments, but only '3' are expected.
class C {}
''');
  }

  test_youtube_hasExtraArgument_trailingWhitespace() async {
    await resolveTestCodeWithDiagnostics(r'''
/// {@youtube 600 400 https://www.youtube.com/watch?v=123 foo }
//                                                        ^^^
// [diag.docDirectiveHasExtraArguments] The 'youtube' directive has '4' arguments, but only '3' are expected.
class C {}
''');
  }

  test_youtube_noExtraArguments() async {
    await resolveTestCodeWithDiagnostics(r'''
/// {@youtube 600 400 https://www.youtube.com/watch?v=123}
class C {}
''');
  }
}
