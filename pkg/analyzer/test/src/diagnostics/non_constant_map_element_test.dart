// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NonConstantMapElementTest);
    defineReflectiveTests(NonConstantMapKeyTest);
    defineReflectiveTests(NonConstantMapValueTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class NonConstantMapElementTest extends PubPackageResolutionTest {
  test_forElement_notConst_noError() async {
    await resolveTestCodeWithDiagnostics('''
void main() {
  var x;
  print({x: x, for (final x2 in [x]) x2: x2});
}
''');
  }

  test_ifElement_mayBeConst() async {
    await resolveTestCodeWithDiagnostics('''
void main() {
  const {1: null, if (true) null: null};
}
''');
  }

  test_ifElement_nested_mayBeConst() async {
    await resolveTestCodeWithDiagnostics('''
void main() {
  const {1: null, if (true) if (true) null: null};
}
''');
  }

  test_ifElement_notConstCondition() async {
    await resolveTestCodeWithDiagnostics('''
void main() {
  bool notConst = true;
  const {1: null, if (notConst) null: null};
//                    ^^^^^^^^
// [diag.nonConstantMapElement] The elements in a const map literal must be constant.
}
''');
  }

  test_ifElementWithElse_mayBeConst() async {
    await resolveTestCodeWithDiagnostics('''
void main() {
  const isTrue = true;
  const {1: null, if (isTrue) null: null else null: null};
//                                            ^^^^^^^^^^
// [diag.deadCode] Dead code.
}
''');
  }

  test_spreadElement_mayBeConst() async {
    await resolveTestCodeWithDiagnostics('''
void main() {
  const {1: null, ...{null: null}};
}
''');
  }

  test_spreadElement_notConst() async {
    await resolveTestCodeWithDiagnostics('''
void main() {
  var notConst = {};
  const {1: null, ...notConst};
//                   ^^^^^^^^
// [diag.nonConstantMapElement] The elements in a const map literal must be constant.
}
''');
  }
}

@reflectiveTest
class NonConstantMapKeyTest extends PubPackageResolutionTest {
  test_const_ifElement_thenElseFalse_finalElse() async {
    await resolveTestCodeWithDiagnostics('''
final dynamic a = 0;
var v = const <int, int>{if (1 < 0) 0: 0 else a: 0};
//                                            ^
// [diag.nonConstantMapKey] The keys in a const map literal must be constant.
''');
  }

  test_const_ifElement_thenElseFalse_finalThen() async {
    await resolveTestCodeWithDiagnostics('''
final dynamic a = 0;
var v = const <int, int>{if (1 < 0) a: 0 else 0: 0};
//                                  ^
// [diag.nonConstantMapKey] The keys in a const map literal must be constant.
''');
  }

  test_const_ifElement_thenElseTrue_finalElse() async {
    await resolveTestCodeWithDiagnostics('''
final dynamic a = 0;
var v = const <int, int>{if (1 > 0) 0: 0 else a: 0};
//                                            ^
// [diag.nonConstantMapKey] The keys in a const map literal must be constant.
''');
  }

  test_const_ifElement_thenElseTrue_finalThen() async {
    await resolveTestCodeWithDiagnostics('''
final dynamic a = 0;
var v = const <int, int>{if (1 > 0) a: 0 else 0: 0};
//                                  ^
// [diag.nonConstantMapKey] The keys in a const map literal must be constant.
''');
  }

  test_const_ifElement_thenFalse_constThen() async {
    await resolveTestCodeWithDiagnostics('''
const dynamic a = 0;
var v = const <int, int>{if (1 < 0) a: 0};
''');
  }

  test_const_ifElement_thenFalse_finalThen() async {
    await resolveTestCodeWithDiagnostics('''
final dynamic a = 0;
var v = const <int, int>{if (1 < 0) a: 0};
//                                  ^
// [diag.nonConstantMapKey] The keys in a const map literal must be constant.
''');
  }

  test_const_ifElement_thenTrue_constThen() async {
    await resolveTestCodeWithDiagnostics('''
const dynamic a = 0;
var v = const <int, int>{if (1 > 0) a: 0};
''');
  }

  test_const_ifElement_thenTrue_finalThen() async {
    await resolveTestCodeWithDiagnostics('''
final dynamic a = 0;
var v = const <int, int>{if (1 > 0) a: 0};
//                                  ^
// [diag.nonConstantMapKey] The keys in a const map literal must be constant.
''');
  }

  test_const_topVar() async {
    await resolveTestCodeWithDiagnostics('''
final dynamic a = 0;
var v = const <int, int>{a: 0};
//                       ^
// [diag.nonConstantMapKey] The keys in a const map literal must be constant.
''');
  }

  test_nonConst_topVar() async {
    await resolveTestCodeWithDiagnostics('''
final dynamic a = 0;
var v = <int, int>{a: 0};
''');
  }
}

@reflectiveTest
class NonConstantMapValueTest extends PubPackageResolutionTest {
  test_const_ifElement_thenElseFalse_finalElse() async {
    await resolveTestCodeWithDiagnostics('''
final dynamic a = 0;
var v = const <int, int>{if (1 < 0) 0: 0 else 0: a};
//                                               ^
// [diag.nonConstantMapValue] The values in a const map literal must be constant.
''');
  }

  test_const_ifElement_thenElseFalse_finalThen() async {
    await resolveTestCodeWithDiagnostics('''
final dynamic a = 0;
var v = const <int, int>{if (1 < 0) 0: a else 0: 0};
//                                     ^
// [diag.nonConstantMapValue] The values in a const map literal must be constant.
''');
  }

  test_const_ifElement_thenElseTrue_finalElse() async {
    await resolveTestCodeWithDiagnostics('''
final dynamic a = 0;
var v = const <int, int>{if (1 > 0) 0: 0 else 0: a};
//                                               ^
// [diag.nonConstantMapValue] The values in a const map literal must be constant.
''');
  }

  test_const_ifElement_thenElseTrue_finalThen() async {
    await resolveTestCodeWithDiagnostics('''
final dynamic a = 0;
var v = const <int, int>{if (1 > 0) 0: a else 0: 0};
//                                     ^
// [diag.nonConstantMapValue] The values in a const map literal must be constant.
''');
  }

  test_const_ifElement_thenFalse_constThen() async {
    await resolveTestCodeWithDiagnostics('''
const dynamic a = 0;
var v = const <int, int>{if (1 < 0) 0: a};
''');
  }

  test_const_ifElement_thenFalse_finalThen() async {
    await resolveTestCodeWithDiagnostics('''
final dynamic a = 0;
var v = const <int, int>{if (1 < 0) 0: a};
//                                     ^
// [diag.nonConstantMapValue] The values in a const map literal must be constant.
''');
  }

  test_const_ifElement_thenTrue_constThen() async {
    await resolveTestCodeWithDiagnostics('''
const dynamic a = 0;
var v = const <int, int>{if (1 > 0) 0: a};
''');
  }

  test_const_ifElement_thenTrue_finalThen() async {
    await resolveTestCodeWithDiagnostics('''
final dynamic a = 0;
var v = const <int, int>{if (1 > 0) 0: a};
//                                     ^
// [diag.nonConstantMapValue] The values in a const map literal must be constant.
''');
  }

  test_const_topVar() async {
    await resolveTestCodeWithDiagnostics('''
final dynamic a = 0;
var v = const <int, int>{0: a};
//                          ^
// [diag.nonConstantMapValue] The values in a const map literal must be constant.
''');
  }

  test_nonConst_topVar() async {
    await resolveTestCodeWithDiagnostics('''
final dynamic a = 0;
var v = <int, int>{0: a};
''');
  }
}
