// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NonConstantMapValueTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class NonConstantMapValueTest extends PubPackageResolutionTest {
  test_const_ifTrue_elseFinal() async {
    await resolveTestCodeWithDiagnostics(r'''
final dynamic a = 0;
const cond = true;
var v = const {if (cond) 'a': 'b', 'c' : a};
//                                       ^
// [diag.nonConstantMapValue] The values in a const map literal must be constant.
''');
  }

  test_const_ifTrue_thenFinal() async {
    await resolveTestCodeWithDiagnostics(r'''
final dynamic a = 0;
const cond = true;
var v = const {if (cond) 'a' : a};
//                             ^
// [diag.nonConstantMapValue] The values in a const map literal must be constant.
''');
  }

  test_const_topLevel() async {
    await resolveTestCodeWithDiagnostics(r'''
final dynamic a = 0;
var v = const {'a' : a};
//                   ^
// [diag.nonConstantMapValue] The values in a const map literal must be constant.
''');
  }
}
