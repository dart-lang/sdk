// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExtensionTypeRepresentationTypeBottomTest);
  });
}

@reflectiveTest
class ExtensionTypeRepresentationTypeBottomTest
    extends PubPackageResolutionTest {
  test_never() async {
    await assertErrorsInCode('''
extension type A(Never it) {}
''', [
      error(CompileTimeErrorCode.EXTENSION_TYPE_REPRESENTATION_TYPE_BOTTOM, 17,
          5),
    ]);
  }

  test_neverQuestion() async {
    await assertNoErrorsInCode('''
extension type A(Never? it) {}
''');
  }

  test_typeParameter_never_none() async {
    await assertErrorsInCode('''
extension type A<T extends Never>(T it) {}
''', [
      error(CompileTimeErrorCode.EXTENSION_TYPE_REPRESENTATION_TYPE_BOTTOM, 34,
          1),
    ]);
  }

  test_typeParameter_never_question() async {
    await assertNoErrorsInCode('''
extension type A<T extends Never>(T? it) {}
''');
  }

  test_typeParameter_never_question2() async {
    await assertNoErrorsInCode('''
extension type A<T extends Never, S extends T>(S? it) {}
''');
  }

  test_typeParameter_never_question3() async {
    await assertNoErrorsInCode('''
extension type A<T extends Never, S extends T?>(S it) {}
''');
  }
}
