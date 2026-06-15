// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NonConstantMapKeyFromDeferredLibraryTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class NonConstantMapKeyFromDeferredLibraryTest
    extends PubPackageResolutionTest {
  test_const_ifElement_thenTrue_deferredElse() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
const int c = 1;''');
    await resolveTestCodeWithDiagnostics(r'''
import 'lib1.dart' deferred as a;
const cond = true;
var v = const { if (cond) 0: 1 else a.c : 0};
//                                  ^^^
// [diag.nonConstantMapKey] The keys in a const map literal must be constant.
''');
  }

  test_const_ifElement_thenTrue_deferredThen() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
const int c = 1;''');
    await resolveTestCodeWithDiagnostics(r'''
import 'lib1.dart' deferred as a;
const cond = true;
var v = const { if (cond) a.c : 0};
//                          ^
// [diag.nonConstantMapKeyFromDeferredLibrary] Constant values from a deferred library can't be used as keys in a 'const' map literal.
''');
  }

  test_const_topLevel_deferred() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
const int c = 1;''');
    await resolveTestCodeWithDiagnostics(r'''
import 'lib1.dart' deferred as a;
var v = const {a.c : 0};
//               ^
// [diag.nonConstantMapKeyFromDeferredLibrary] Constant values from a deferred library can't be used as keys in a 'const' map literal.
''');
  }

  test_const_topLevel_deferred_nested() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
const int c = 1;''');
    await resolveTestCodeWithDiagnostics(r'''
import 'lib1.dart' deferred as a;
var v = const {a.c + 1 : 0};
//               ^
// [diag.nonConstantMapKeyFromDeferredLibrary] Constant values from a deferred library can't be used as keys in a 'const' map literal.
''');
  }
}
