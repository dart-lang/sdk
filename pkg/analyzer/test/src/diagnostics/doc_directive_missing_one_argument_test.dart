// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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

  test_canonicalFor_hasNoArguments() async {
    await resolveTestCodeWithDiagnostics(r'''
/// {@canonicalFor}
// [diag.docDirectiveMissingOneArgument][column 5][length 16] The 'canonicalFor' directive is missing a 'element' argument.
class C {}
''');
  }

  test_canonicalFor_hasOneArguments() async {
    await resolveTestCodeWithDiagnostics(r'''
/// {@canonicalFor String}
class C {}
''');
  }

  test_macro_hasNoArguments() async {
    await resolveTestCodeWithDiagnostics(r'''
/// {@macro}
// [diag.docDirectiveMissingOneArgument][column 5][length 9] The 'macro' directive is missing a 'name' argument.
class C {}
''');
  }

  test_youtube_hasThreeArguments() async {
    await resolveTestCodeWithDiagnostics(r'''
/// {@youtube 600 400 https://www.youtube.com/watch?v=123}
class C {}
''');
  }

  test_youtube_missingUrl() async {
    await resolveTestCodeWithDiagnostics(r'''
/// {@youtube 600 400}
// [diag.docDirectiveMissingOneArgument][column 5][length 19] The 'youtube' directive is missing a 'url' argument.
class C {}
''');
  }

  test_youtube_missingUrl_andCurlyBrace() async {
    await resolveTestCodeWithDiagnostics(r'''
/// {@youtube 600 400
// [diag.docDirectiveMissingOneArgument][column 5][length 18] The 'youtube' directive is missing a 'url' argument.
// [diag.docDirectiveMissingClosingBrace][column 22][length 1] Doc directive is missing a closing curly brace ('}').
class C {}
''');
  }
}
