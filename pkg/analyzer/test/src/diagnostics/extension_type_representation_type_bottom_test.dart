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
}
