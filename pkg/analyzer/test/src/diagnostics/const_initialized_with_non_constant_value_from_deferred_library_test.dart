// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(
      ConstInitializedWithNonConstantValueFromDeferredLibraryTest,
    );
  });
}

@reflectiveTest
class ConstInitializedWithNonConstantValueFromDeferredLibraryTest
    extends PubPackageResolutionTest {
  test_deferred() async {
    newFile('$testPackageLibPath/lib1.dart', '''
library lib1;
const V = 1;
''');
    await assertErrorsInCode(
      '''
library root;
import 'lib1.dart' deferred as a;
const B = a.V;
''',
      [
        error(
          CompileTimeErrorCode
              .constInitializedWithNonConstantValueFromDeferredLibrary,
          60,
          1,
        ),
      ],
    );
  }

  test_nested() async {
    newFile('$testPackageLibPath/lib1.dart', '''
library lib1;
const V = 1;
''');
    await assertErrorsInCode(
      '''
library root;
import 'lib1.dart' deferred as a;
const B = a.V + 1;
''',
      [
        error(
          CompileTimeErrorCode
              .constInitializedWithNonConstantValueFromDeferredLibrary,
          60,
          1,
        ),
      ],
    );
  }

  test_staticMethod_ofExtension() async {
    await assertErrorsInCode(
      '''
import '' deferred as self;
extension E on int {
  static int f(String s) => 7;
}
const g = self.E.f;
''',
      [
        error(CompileTimeErrorCode.deferredImportOfExtension, 7, 2),
        error(
          CompileTimeErrorCode
              .constInitializedWithNonConstantValueFromDeferredLibrary,
          97,
          1,
        ),
      ],
    );
  }
}
