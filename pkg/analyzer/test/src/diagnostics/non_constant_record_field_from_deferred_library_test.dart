// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NonConstantRecordFieldFromDeferredLibraryTest);
  });
}

@reflectiveTest
class NonConstantRecordFieldFromDeferredLibraryTest
    extends PubPackageResolutionTest {
  test_const_deferred() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
const int c = 1;
''');
    await assertErrorsInCode(r'''
import 'lib1.dart' deferred as a;
var v = const (a.c, );
''', [
      error(
          CompileTimeErrorCode.NON_CONSTANT_RECORD_FIELD_FROM_DEFERRED_LIBRARY,
          51,
          1),
    ]);
  }

  test_const_notDeferred() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
const int c = 1;
const int d = 2;
''');
    await assertNoErrorsInCode(r'''
import 'lib1.dart' as a;
var v = const (a.c, d: a.d);
''');
  }

  test_nonConst_deferred() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
const int c = 1;
''');
    await assertNoErrorsInCode(r'''
import 'lib1.dart' deferred as a;
var v = (a.c, );
''');
  }
}
