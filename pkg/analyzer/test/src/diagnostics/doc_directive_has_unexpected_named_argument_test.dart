// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.g.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DocDirectiveHasUnexpectedNamedArgumentTest);
  });
}

@reflectiveTest
class DocDirectiveHasUnexpectedNamedArgumentTest
    extends PubPackageResolutionTest {
  test_animation_hasUnexpectedArgument() async {
    await assertErrorsInCode('''
/// {@animation 600 400 http://google.com foo=bar}
class C {}
''', [
      error(WarningCode.DOC_DIRECTIVE_HAS_UNEXPECTED_NAMED_ARGUMENT, 42, 7),
    ]);
  }

  test_macro_hasExtraArgument() async {
    await assertErrorsInCode('''
/// {@macro name foo=bar}
class C {}
''', [
      error(WarningCode.DOC_DIRECTIVE_HAS_UNEXPECTED_NAMED_ARGUMENT, 17, 7),
    ]);
  }

  test_macro_noExtraArgument() async {
    await assertNoErrorsInCode('''
/// {@macro name}
class C {}
''');
  }
}
