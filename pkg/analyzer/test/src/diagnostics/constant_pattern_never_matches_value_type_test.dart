// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstantPatternNeverMatchesValueTypeTest);
  });
}

@reflectiveTest
class ConstantPatternNeverMatchesValueTypeTest
    extends PubPackageResolutionTest {
  test_bool_bool() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(bool x) {
  if (x case (true)) {}
}
''');
  }

  test_bool_int() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(int x) {
  if (x case (true)) {}
//            ^^^^
// [diag.constantPatternNeverMatchesValueType] The matched value type 'int' can never be equal to this constant of type 'bool'.
}
''');
  }

  test_bool_ListOfBool() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(List<bool> x) {
  if (x case (true)) {}
//            ^^^^
// [diag.constantPatternNeverMatchesValueType] The matched value type 'List<bool>' can never be equal to this constant of type 'bool'.
}
''');
  }

  test_bool_typeParameter_bound_bool() async {
    await resolveTestCodeWithDiagnostics(r'''
void f<T extends bool>(T x) {
  if (x case (true)) {}
}
''');
  }

  test_bool_typeParameter_bound_bool_nested() async {
    await resolveTestCodeWithDiagnostics(r'''
void f<T extends bool>(List<T> x) {
  if (x case [true]) {}
}
''');
  }

  test_bool_typeParameter_bound_num() async {
    await resolveTestCodeWithDiagnostics(r'''
void f<T extends num>(T x) {
  if (x case (true)) {}
//            ^^^^
// [diag.constantPatternNeverMatchesValueType] The matched value type 'T' can never be equal to this constant of type 'bool'.
}
''');
  }

  test_bool_typeParameter_bound_num_nested() async {
    await resolveTestCodeWithDiagnostics(r'''
void f<T extends num>(List<T> x) {
  if (x case [true]) {}
//            ^^^^
// [diag.constantPatternNeverMatchesValueType] The matched value type 'T' can never be equal to this constant of type 'bool'.
}
''');
  }

  test_bool_typeParameter_promoted_bool() async {
    await resolveTestCodeWithDiagnostics(r'''
void f<T>(T x) {
  if (x is bool) {
    if (x case (true)) {}
  }
}
''');
  }

  test_bool_typeParameter_promoted_int() async {
    await resolveTestCodeWithDiagnostics(r'''
void f<T>(T x) {
  if (x is int) {
    if (x case (true)) {}
//              ^^^^
// [diag.constantPatternNeverMatchesValueType] The matched value type 'T & int' can never be equal to this constant of type 'bool'.
  }
}
''');
  }

  test_custom_notPrimitiveEquality_constantIsSubtypeOfValue() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(A x) {
  if (x case const B()) {}
}

class A {
  const A();
}

class B extends A {
  const B();
  bool operator ==(other) => true;
}
''');
  }

  test_custom_notPrimitiveEquality_constantIsSupertypeOfValue() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(B x) {
  if (x case const A()) {}
}

class A {
  const A();
  bool operator ==(other) => true;
}

class B extends A {
  const B();
}
''');
  }

  test_custom_primitiveEquality_constantIsSameTypeAsValue() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(A x) {
  if (x case const A()) {}
}

class A {
  const A();
}
''');
  }

  test_custom_primitiveEquality_constantIsSubtypeOfValue() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(A x) {
  if (x case const B()) {}
}

class A {
  const A();
}

class B extends A {
  const B();
}
''');
  }

  test_custom_primitiveEquality_constantIsSupertypeOfValue() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(B x) {
  if (x case const A()) {}
//           ^^^^^^^^^
// [diag.constantPatternNeverMatchesValueType] The matched value type 'B' can never be equal to this constant of type 'A'.
}

class A {
  const A();
}

class B extends A {
  const B();
}
''');
  }

  test_custom_primitiveEquality_generic_differentElement_constantIsSubtypeOfValue() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(A<int> x) {
  if (x case const B()) {}
}

class A<T> {
  const A();
}

class B extends A<int> {
  const B();
}
''');
  }

  test_custom_primitiveEquality_generic_differentElement_constantIsSupertypeOfValue() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(B x) {
  if (x case const A<int>()) {}
//           ^^^^^^^^^^^^^^
// [diag.constantPatternNeverMatchesValueType] The matched value type 'B' can never be equal to this constant of type 'A<int>'.
}

class A<T> {
  const A();
}

class B extends A<int> {
  const B();
}
''');
  }

  test_custom_primitiveEquality_generic_sameElement_constantIsSameTypeAsValue() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(A<int> x) {
  if (x case const A<int>()) {}
}

class A<T> {
  const A();
}
''');
  }

  test_custom_primitiveEquality_generic_sameElement_constantIsSubtypeOfValue() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(A<num> x) {
  if (x case const A<int>()) {}
}

class A<T> {
  const A();
}
''');
  }

  test_custom_primitiveEquality_generic_sameElement_constantIsSupertypeOfValue() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(A<int> x) {
  if (x case const A<num>()) {}
//           ^^^^^^^^^^^^^^
// [diag.constantPatternNeverMatchesValueType] The matched value type 'A<int>' can never be equal to this constant of type 'A<num>'.
}

class A<T> {
  const A();
}
''');
  }

  test_custom_primitiveEquality_generic_sameElement_typeParameter() async {
    await resolveTestCodeWithDiagnostics(r'''
void f<T>(A<T> x) {
  if (x case const A<int>()) {}
}

class A<T> {
  const A();
}
''');
  }

  test_custom_primitiveEquality_generic_sameElement_typeParameter_contravariant() async {
    await resolveTestCodeWithDiagnostics(r'''
void f<T>(A<void Function(T)> x) {
  if (x case const A<void Function(int)>()) {}
}

class A<T> {
  const A();
}
''');
  }

  test_int_bool() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(bool x) {
  if (x case (0)) {}
//            ^
// [diag.constantPatternNeverMatchesValueType] The matched value type 'bool' can never be equal to this constant of type 'int'.
}
''');
  }

  test_int_double() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(double x) {
  if (x case (zero)) {}
}

const zero = 0;
''');
  }

  test_int_extensionTypeBool() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(bool it) {}

void f(E x) {
  if (x case (0)) {}
//            ^
// [diag.constantPatternNeverMatchesValueType] The matched value type 'bool' can never be equal to this constant of type 'int'.
}
''');
  }

  test_int_extensionTypeInt() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int it) {}

void f(E x) {
  if (x case (0)) {}
}
''');
  }

  test_int_functionType() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(void Function() x) {
  if (x case (0)) {}
//            ^
// [diag.constantPatternNeverMatchesValueType] The matched value type 'void Function()' can never be equal to this constant of type 'int'.
}

class A {}
''');
  }

  test_int_int() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(int x) {
  if (x case (0)) {}
}
''');
  }

  test_int_intQuestion() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(int? x) {
  if (x case (0)) {}
}
''');
  }

  test_int_num() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(num x) {
  if (x case (0)) {}
}
''');
  }

  test_int_otherClass() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(A x) {
  if (x case (0)) {}
//            ^
// [diag.constantPatternNeverMatchesValueType] The matched value type 'A' can never be equal to this constant of type 'int'.
}

class A {}
''');
  }

  test_int_recordType() async {
    await resolveTestCodeWithDiagnostics(r'''
void f((int, int) x) {
  if (x case 0) {}
//           ^
// [diag.constantPatternNeverMatchesValueType] The matched value type '(int, int)' can never be equal to this constant of type 'int'.
}

class A {}
''');
  }

  test_int_String() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(String x) {
  if (x case (0)) {}
//            ^
// [diag.constantPatternNeverMatchesValueType] The matched value type 'String' can never be equal to this constant of type 'int'.
}
''');
  }

  test_Null_functionType() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(void Function() x) {
  if (x case null) {}
//           ^^^^
// [diag.constantPatternNeverMatchesValueType] The matched value type 'void Function()' can never be equal to this constant of type 'Null'.
//                 ^^
// [diag.deadCode] Dead code.
}
''');
  }

  test_Null_functionTypeQuestion() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(void Function()? x) {
  if (x case null) {}
}
''');
  }

  test_Null_int() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(int x) {
  if (x case null) {}
//           ^^^^
// [diag.constantPatternNeverMatchesValueType] The matched value type 'int' can never be equal to this constant of type 'Null'.
//                 ^^
// [diag.deadCode] Dead code.
}
''');
  }

  test_Null_intQuestion() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(int? x) {
  if (x case null) {}
}
''');
  }

  test_Null_recordType() async {
    await resolveTestCodeWithDiagnostics(r'''
void f((int, int) x) {
  if (x case null) {}
//           ^^^^
// [diag.constantPatternNeverMatchesValueType] The matched value type '(int, int)' can never be equal to this constant of type 'Null'.
//                 ^^
// [diag.deadCode] Dead code.
}
''');
  }

  test_Null_recordTypeQuestion() async {
    await resolveTestCodeWithDiagnostics(r'''
void f((int, int)? x) {
  if (x case null) {}
}
''');
  }

  test_Null_typeParameterType_notNullableBound() async {
    await resolveTestCodeWithDiagnostics(r'''
void f<T extends Object>(T x) {
  if (x case null) {}
//           ^^^^
// [diag.constantPatternNeverMatchesValueType] The matched value type 'T' can never be equal to this constant of type 'Null'.
//                 ^^
// [diag.deadCode] Dead code.
}
''');
  }

  test_Null_typeParameterType_notNullableBound_question() async {
    await resolveTestCodeWithDiagnostics(r'''
void f<T extends Object>(T? x) {
  if (x case null) {}
}
''');
  }

  test_Null_typeParameterType_nullableBound() async {
    await resolveTestCodeWithDiagnostics(r'''
void f<T>(T x) {
  if (x case null) {}
}
''');
  }

  test_Null_typeParameterType_nullableBound_question() async {
    await resolveTestCodeWithDiagnostics(r'''
void f<T>(T? x) {
  if (x case null) {}
}
''');
  }
}
