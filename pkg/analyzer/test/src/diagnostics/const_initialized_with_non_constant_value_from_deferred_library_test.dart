// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
    await resolveTestCodeWithDiagnostics(r'''
library root;
import 'lib1.dart' deferred as a;
const B = a.V;
//          ^
// [diag.constInitializedWithNonConstantValueFromDeferredLibrary] Constant values from a deferred library can't be used to initialize a 'const' variable.
''');
  }

  test_nested() async {
    newFile('$testPackageLibPath/lib1.dart', '''
library lib1;
const V = 1;
''');
    await resolveTestCodeWithDiagnostics(r'''
library root;
import 'lib1.dart' deferred as a;
const B = a.V + 1;
//          ^
// [diag.constInitializedWithNonConstantValueFromDeferredLibrary] Constant values from a deferred library can't be used to initialize a 'const' variable.
''');
  }

  test_staticMethod_ofExtension() async {
    await resolveTestCodeWithDiagnostics(r'''
import '' deferred as self;
//     ^^
// [diag.deferredImportOfExtension] Deferred library imports must hide all extension declarations.
extension E on int {
  static int f(String s) => 7;
}
const g = self.E.f;
//             ^
// [diag.constInitializedWithNonConstantValueFromDeferredLibrary] Constant values from a deferred library can't be used to initialize a 'const' variable.
''');
  }
}
