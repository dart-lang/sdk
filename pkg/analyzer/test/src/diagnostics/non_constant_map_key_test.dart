// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NonConstantMapKeyTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class NonConstantMapKeyTest extends PubPackageResolutionTest {
  test_const_ifElement_thenTrue_elseFinal() async {
    await resolveTestCodeWithDiagnostics(r'''
final dynamic a = 0;
const cond = true;
var v = const {if (cond) 0: 1 else a : 0};
//                                 ^
// [diag.nonConstantMapKey] The keys in a const map literal must be constant.
''');
  }

  test_const_ifElement_thenTrue_thenFinal() async {
    await resolveTestCodeWithDiagnostics(r'''
final dynamic a = 0;
const cond = true;
var v = const {if (cond) a : 0};
//                       ^
// [diag.nonConstantMapKey] The keys in a const map literal must be constant.
''');
  }

  test_const_topLevel() async {
    await resolveTestCodeWithDiagnostics(r'''
final dynamic a = 0;
var v = const {a : 0};
//             ^
// [diag.nonConstantMapKey] The keys in a const map literal must be constant.
''');
  }
}
