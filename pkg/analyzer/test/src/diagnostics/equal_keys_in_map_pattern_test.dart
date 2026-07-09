// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(EqualKeysInMapPatternTest);
  });
}

@reflectiveTest
class EqualKeysInMapPatternTest extends PubPackageResolutionTest {
  test_identical_double() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(x) {
  if (x case {3.14: 1, 3.14: 2}) {}
//            ^^^^
// [context 1] The first key with this value.
//                     ^^^^
// [diag.equalKeysInMapPattern][context 1] Two keys in a map pattern can't be equal.
}
''');
  }

  test_identical_int() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(x) {
  if (x case {0: 1, 0: 2}) {}
//            ^
// [context 1] The first key with this value.
//                  ^
// [diag.equalKeysInMapPattern][context 1] Two keys in a map pattern can't be equal.
}
''');
  }

  test_identical_int_viaIdentifier() async {
    await resolveTestCodeWithDiagnostics(r'''
const a = 0;
const b = 0;

void f(x) {
  if (x case {a: 1, b: 2}) {}
//            ^
// [context 1] The first key with this value.
//                  ^
// [diag.equalKeysInMapPattern][context 1] Two keys in a map pattern can't be equal.
}
''');
  }

  test_identical_type() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(x) {
  if (x case {int: 0, int: 0}) {}
//            ^^^
// [context 1] The first key with this value.
//                    ^^^
// [diag.equalKeysInMapPattern][context 1] Two keys in a map pattern can't be equal.
}
''');
  }

  test_identical_type_extensionType() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(x) {
  if (x case {int: 0, E: 0}) {}
//            ^^^
// [context 1] The first key with this value.
//                    ^
// [diag.equalKeysInMapPattern][context 1] Two keys in a map pattern can't be equal.
}
extension type E(int it) {}
''');
  }

  test_notIdentical_double() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(x) {
  if (x case {3.14: 1, 2.71: 2}) {}
}
''');
  }

  test_notIdentical_int() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(x) {
  if (x case {0: 1, 2: 3}) {}
}
''');
  }

  test_notIdentical_userClass() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(x) {
  if (x case {const A(0): 1, const A(2): 3}) {}
}

class A {
  final int field;
  const A(this.field);
  bool operator ==(other) => false;
}
''');
  }

  test_recordType_notPrimitiveEqual_named() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(x) {
  if (x case {(a: const A()): 1, (a: const A()): 2}) {}
}

class A {
  const A();
  bool operator ==(other) => true;
}
''');
  }

  test_recordType_notPrimitiveEqual_positional() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(x) {
  if (x case {(0, const A()): 1, (0, const A()): 2}) {}
}

class A {
  const A();
  bool operator ==(other) => true;
}
''');
  }

  test_recordType_primitiveEqual_differentShape() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(x) {
  if (x case {(0, 1): 2, (0,): 3}) {}
}
''');
  }

  test_recordType_primitiveEqual_empty() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(x) {
  if (x case {(): 1, (): 2}) {}
//            ^^
// [context 1] The first key with this value.
//                   ^^
// [diag.equalKeysInMapPattern][context 1] Two keys in a map pattern can't be equal.
}
''');
  }

  test_recordType_primitiveEqual_named_equal() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(x) {
  if (x case {(a: 0): 1, (a: 0): 2}) {}
//            ^^^^^^
// [context 1] The first key with this value.
//                       ^^^^^^
// [diag.equalKeysInMapPattern][context 1] Two keys in a map pattern can't be equal.
}
''');
  }

  test_recordType_primitiveEqual_named_notEqual() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(x) {
  if (x case {(a: 0): 1, (a: 2): 3}) {}
}
''');
  }

  test_recordType_primitiveEqual_positional_equal() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(x) {
  if (x case {(0,): 1, (0,): 2}) {}
//            ^^^^
// [context 1] The first key with this value.
//                     ^^^^
// [diag.equalKeysInMapPattern][context 1] Two keys in a map pattern can't be equal.
}
''');
  }

  test_recordType_primitiveEqual_positional_notEqual() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(x) {
  if (x case {(0,): 1, (2,): 3}) {}
}
''');
  }
}
