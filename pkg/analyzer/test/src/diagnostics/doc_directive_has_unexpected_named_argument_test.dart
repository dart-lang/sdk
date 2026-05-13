// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
    await resolveTestCodeWithDiagnostics(r'''
/// {@animation 600 400 http://google.com foo=bar}
//                                        ^^^^^^^
// [diag.docDirectiveHasUnexpectedNamedArgument] The 'animation' directive has an unexpected named argument, 'foo'.
class C {}
''');
  }

  test_macro_hasExtraArgument() async {
    await resolveTestCodeWithDiagnostics(r'''
/// {@macro name foo=bar}
//               ^^^^^^^
// [diag.docDirectiveHasUnexpectedNamedArgument] The 'macro' directive has an unexpected named argument, 'foo'.
class C {}
''');
  }

  test_macro_noExtraArgument() async {
    await resolveTestCodeWithDiagnostics(r'''
/// {@macro name}
class C {}
''');
  }
}
