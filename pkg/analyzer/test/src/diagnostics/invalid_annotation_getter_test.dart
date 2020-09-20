// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidAnnotationGetterTest);
  });
}

@reflectiveTest
class InvalidAnnotationGetterTest extends PubPackageResolutionTest {
  test_getter() async {
    await assertErrorsInCode(r'''
get V => 0;
@V
main() {
}
''', [
      error(CompileTimeErrorCode.INVALID_ANNOTATION_GETTER, 12, 2),
    ]);
  }

  test_importWithPrefix_getter() async {
    newFile('$testPackageLibPath/lib.dart', content: r'''
library lib;
get V => 0;
''');
    await assertErrorsInCode(r'''
import 'lib.dart' as p;
@p.V
main() {
}
''', [
      error(CompileTimeErrorCode.INVALID_ANNOTATION_GETTER, 24, 4),
    ]);
  }
}
