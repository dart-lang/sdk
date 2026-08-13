// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NonConstantDefaultValueFromDeferredLibraryTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class NonConstantDefaultValueFromDeferredLibraryTest
    extends PubPackageResolutionTest {
  test_deferred() async {
    newFile('$testPackageLibPath/lib1.dart', '''
library lib1;
const V = 1;
''');
    await resolveTestCodeWithDiagnostics('''
library root;
import 'lib1.dart' deferred as a;
f({x = a.V}) {}
//       ^
// [diag.nonConstantDefaultValueFromDeferredLibrary] Constant values from a deferred library can't be used as a default parameter value.
''');
  }

  test_nested() async {
    newFile('$testPackageLibPath/lib1.dart', '''
library lib1;
const V = 1;
''');
    await resolveTestCodeWithDiagnostics('''
library root;
import 'lib1.dart' deferred as a;
f({x = a.V + 1}) {}
//       ^
// [diag.nonConstantDefaultValueFromDeferredLibrary] Constant values from a deferred library can't be used as a default parameter value.
''');
  }
}
