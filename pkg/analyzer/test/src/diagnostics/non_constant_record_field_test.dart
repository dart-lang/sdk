// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NonConstantRecordFieldTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class NonConstantRecordFieldTest extends PubPackageResolutionTest {
  test_const_namedField() async {
    await resolveTestCodeWithDiagnostics('''
final a = 0;
var v = const (a: a);
//                ^
// [diag.nonConstantRecordField] The fields in a const record literal must be constants.
''');
  }

  test_const_positionalField() async {
    await resolveTestCodeWithDiagnostics('''
final a = 0;
var v = const (a, );
//             ^
// [diag.nonConstantRecordField] The fields in a const record literal must be constants.
''');
  }

  test_nonConst() async {
    await resolveTestCodeWithDiagnostics('''
final a = 0;
var v = (a, );
''');
  }
}
