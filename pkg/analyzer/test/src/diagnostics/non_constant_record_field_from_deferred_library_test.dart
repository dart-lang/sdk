// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NonConstantRecordFieldFromDeferredLibraryTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class NonConstantRecordFieldFromDeferredLibraryTest
    extends PubPackageResolutionTest {
  test_const_deferred() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
const int c = 1;
''');
    await resolveTestCodeWithDiagnostics(r'''
import 'lib1.dart' deferred as a;
var v = const (a.c, );
//               ^
// [diag.nonConstantRecordFieldFromDeferredLibrary] Constant values from a deferred library can't be used as fields in a 'const' record literal.
''');
  }

  test_const_notDeferred() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
const int c = 1;
const int d = 2;
''');
    await resolveTestCodeWithDiagnostics(r'''
import 'lib1.dart' as a;
var v = const (a.c, d: a.d);
''');
  }

  test_nonConst_deferred() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
const int c = 1;
''');
    await resolveTestCodeWithDiagnostics(r'''
import 'lib1.dart' deferred as a;
var v = (a.c, );
''');
  }
}
