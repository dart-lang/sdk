// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NonConstantSetElementTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class NonConstantSetElementTest extends PubPackageResolutionTest {
  test_const_ifElement_thenElseFalse_finalElse() async {
    await resolveTestCodeWithDiagnostics('''
final dynamic a = 0;
var v = const <int>{if (1 < 0) 0 else a};
//                                    ^
// [diag.nonConstantSetElement] The values in a const set literal must be constants.
''');
  }

  test_const_ifElement_thenElseFalse_finalThen() async {
    await resolveTestCodeWithDiagnostics('''
final dynamic a = 0;
var v = const <int>{if (1 < 0) a else 0};
//                             ^
// [diag.nonConstantSetElement] The values in a const set literal must be constants.
''');
  }

  test_const_ifElement_thenElseTrue_finalElse() async {
    await resolveTestCodeWithDiagnostics('''
final dynamic a = 0;
var v = const <int>{if (1 > 0) 0 else a};
//                                    ^
// [diag.nonConstantSetElement] The values in a const set literal must be constants.
''');
  }

  test_const_ifElement_thenElseTrue_finalThen() async {
    await resolveTestCodeWithDiagnostics('''
final dynamic a = 0;
var v = const <int>{if (1 > 0) a else 0};
//                             ^
// [diag.nonConstantSetElement] The values in a const set literal must be constants.
''');
  }

  test_const_ifElement_thenFalse_constThen() async {
    await resolveTestCodeWithDiagnostics('''
const dynamic a = 0;
var v = const <int>{if (1 < 0) a};
''');
  }

  test_const_ifElement_thenFalse_finalThen() async {
    await resolveTestCodeWithDiagnostics('''
final dynamic a = 0;
var v = const <int>{if (1 < 0) a};
//                             ^
// [diag.nonConstantSetElement] The values in a const set literal must be constants.
''');
  }

  test_const_ifElement_thenTrue_constThen() async {
    await resolveTestCodeWithDiagnostics('''
const dynamic a = 0;
var v = const <int>{if (1 > 0) a};
''');
  }

  test_const_ifElement_thenTrue_finalThen() async {
    await resolveTestCodeWithDiagnostics('''
final dynamic a = 0;
var v = const <int>{if (1 > 0) a};
//                             ^
// [diag.nonConstantSetElement] The values in a const set literal must be constants.
''');
  }

  test_const_parameter() async {
    await resolveTestCodeWithDiagnostics(r'''
f(a) {
  return const {a};
//              ^
// [diag.nonConstantSetElement] The values in a const set literal must be constants.
}''');
  }

  test_const_spread_final() async {
    await resolveTestCodeWithDiagnostics(r'''
final Set x = {};
var v = const {...x};
//                ^
// [diag.nonConstantSetElement] The values in a const set literal must be constants.
''');
  }

  test_const_topVar() async {
    await resolveTestCodeWithDiagnostics('''
final dynamic a = 0;
var v = const <int>{a};
//                  ^
// [diag.nonConstantSetElement] The values in a const set literal must be constants.
''');
  }

  test_nonConst_topVar() async {
    await resolveTestCodeWithDiagnostics('''
final dynamic a = 0;
var v = <int>{a};
''');
  }
}
