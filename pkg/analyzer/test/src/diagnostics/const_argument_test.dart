// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstAnnotationTest);
  });
}

@reflectiveTest
class ConstAnnotationTest extends PubPackageResolutionTest {
  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfigWithMeta();
  }

  test_binary_fails() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart' show mustBeConst;

void main() {
  var b = B();
  var c = C();
  final r = b < c;
  print(r);
}

abstract class A {
  bool operator <(A other);
}

class B implements A {
  @override
  bool operator <(@mustBeConst A other) {
    return A is C;
  }
}

class C implements A {
  @override
  bool operator <(A other) {
    return false;
  }
}
''', [
      error(WarningCode.NON_CONST_ARGUMENT_FOR_CONST_PARAMETER, 111, 1),
    ]);
  }

  test_binary_succeeds() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart' show mustBeConst;

void main() {
  const b = B();
  const c = C();
  final r = b < c;
  print(r);
}

abstract class A {
  const A();

  bool operator <(A other);
}

class B implements A {
  const B();

  @override
  bool operator <(@mustBeConst A other) {
    return A is C;
  }
}

class C implements A {
  const C();

  @override
  bool operator <(A other) {
    return false;
  }
}
''');
  }

  test_const_named_optional_fails() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart' show mustBeConst;

final v = 3;

int f() => g(value: v);

int g({@mustBeConst int? value}) => (value ?? 0) + 1;
''', [
      error(WarningCode.NON_CONST_ARGUMENT_FOR_CONST_PARAMETER, 78, 8),
    ]);
  }

  test_const_named_optional_succeeds() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart' show mustBeConst;

const v = 3;

int f() => g(value: v);

int g({@mustBeConst int? value}) => (value ?? 0) + 1;
''');
  }

  test_const_named_required_succeeds() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart' show mustBeConst;

const v = 3;

int f() => g(value: v);

int g({@mustBeConst required int value}) => value + 1;
''');
  }

  test_const_positional_optional_succeeds() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart' show mustBeConst;

const v = 3;

int f() => g(v);

int g([@mustBeConst int? value]) => (value ?? 0) + 1;
''');
  }

  test_constant_positional_required_list_succeeds() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart' show mustBeConst;

const v = [3,4];

int f() => g(v);

int g(@mustBeConst List<int> value) => value.length;
''');
  }

  test_constant_positional_required_map_succeeds() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart' show mustBeConst;

const v = {'k1': 3, 'k2': 4};

int f() => g(v);

int g(@mustBeConst Map<String, int> value) => value.length;
''');
  }

  test_constant_positional_required_succeeds() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart' show mustBeConst;

const v = 3;

int f() => g(v);

int g(@mustBeConst int value) => value + 1;
''');
  }

  test_function_expression_fails() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart' show mustBeConst;

void f(int x) {
  var g = (@mustBeConst int i) {};
  g(x);
}
''', [
      error(WarningCode.NON_CONST_ARGUMENT_FOR_CONST_PARAMETER, 106, 1),
    ]);
  }

  test_function_expression_succeeds() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart' show mustBeConst;

void f() {
  var g = (@mustBeConst int i) {};
  g(3);
}
''');
  }

  test_function_type_succeeds() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart' show mustBeConst;

void f(void g(@mustBeConst int i), int x) {
  g(3);
}
''');
  }

  test_index_fails() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart' show mustBeConst;

void main() {
  final a = A();
  final b = A();
  a[1] = b;
}

class A {
  const A();

  void operator []=(@mustBeConst int i, @mustBeConst A v) {}
}
''', [
      error(WarningCode.NON_CONST_ARGUMENT_FOR_CONST_PARAMETER, 108, 1),
    ]);
  }

  test_index_succeeds() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart' show mustBeConst;

void main() {
  final a = A();
  const b = A();
  a[1] = b;
}

class A {
  const A();

  void operator []=(@mustBeConst int i, @mustBeConst A v) {}
}
''');
  }

  test_literal_constructor_succeeds() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart' show mustBeConst;

final c = C(3);

class C {
  final int i;
  C(@mustBeConst this.i);
}
''');
  }

  test_literal_method_succeeds() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart' show mustBeConst;

int f() => C().g(3);

class C {
  int g([@mustBeConst int? value]) => (value ?? 0) + 1;
}
''');
  }

  test_literal_named_required_succeeds() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart' show mustBeConst;

int f() => g(value: 3);

int g({@mustBeConst required int value}) => value + 1;
''');
  }

  test_local_function_fails() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart' show mustBeConst;

void f(int x) {
  void g(@mustBeConst int i) {}
  g(x);
}
''', [
      error(WarningCode.NON_CONST_ARGUMENT_FOR_CONST_PARAMETER, 103, 1),
    ]);
  }

  test_local_function_succeeds() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart' show mustBeConst;

void f() {
  void g(@mustBeConst int i) {}
  g(3);
}
''');
  }

  test_noarg_named_optional_succeeds() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart' show mustBeConst;

int f() => g();

int g({@mustBeConst int? value}) => (value ?? 0) + 1;
''');
  }

  test_noarg_positional_optional_succeeds() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart' show mustBeConst;

int f() => g();

int g([@mustBeConst int? value]) => (value ?? 0) + 1;
''');
  }

  test_non_specified_positional_required_fails() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart' show mustBeConst;

int f(int value) => g(value);

int g(@mustBeConst int value) => value + 1;
''', [
      error(WarningCode.NON_CONST_ARGUMENT_FOR_CONST_PARAMETER, 73, 5),
    ]);
  }

  test_nonconst_constructor_fails() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart' show mustBeConst;

final v = 3;

final c = C(v);

class C {
  final int i;
  C(@mustBeConst this.i);
}
''', [
      error(WarningCode.NON_CONST_ARGUMENT_FOR_CONST_PARAMETER, 77, 1),
    ]);
  }

  test_nonconst_method_fails() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart' show mustBeConst;

final v = 3;

int f() => C().g(v);

class C {
  int g([@mustBeConst int? value]) => (value ?? 0) + 1;
}
''', [
      error(WarningCode.NON_CONST_ARGUMENT_FOR_CONST_PARAMETER, 82, 1),
    ]);
  }

  test_nonconst_positional_optional_fails() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart' show mustBeConst;

final v = 3;

int f() => g(v);

int g([@mustBeConst int? value]) => (value ?? 0) + 1;
''', [
      error(WarningCode.NON_CONST_ARGUMENT_FOR_CONST_PARAMETER, 78, 1),
    ]);
  }

  test_nonconst_value_positional_required_fails() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart' show mustBeConst;

final v = 3;

int f() => g(v);

int g(@mustBeConst int value) => value + 1;
''', [
      error(WarningCode.NON_CONST_ARGUMENT_FOR_CONST_PARAMETER, 78, 1),
    ]);
  }

  test_setter_fails() async {
    await assertErrorsInCode(
      r'''
import 'package:meta/meta.dart' show mustBeConst;

void main() {
  final v = 3;
  A().i = v;
}

class A {
  int? _i;

  int? get i => _i;

  set i(@mustBeConst int? value) {
    _i = value;
  }
}
''',
      [error(WarningCode.NON_CONST_ARGUMENT_FOR_CONST_PARAMETER, 90, 1)],
    );
  }

  test_setter_succeeds() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart' show mustBeConst;

void main() {
  A().i = 3;
}

class A {
  int? _i;

  int? get i => _i;

  set i(@mustBeConst int? value) {
    _i = value;
  }
}
''');
  }

  test_subclasses_dont_inherit() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart' show mustBeConst;

final v = 3;

final r = B().f(v);

abstract class A {
  int f(@mustBeConst int i);
}

class B extends A {
  @override
  int f(int i) => i + 1;
}
''');
  }

  test_superclass_can_be_overriden_cast_succeeds() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart' show mustBeConst;

final v = 3;

final r = (B() as A).f(v);

abstract class A {
  int f(int i);
}

class B extends A {
  @override
  int f(@mustBeConst int i) => i + 1;
}
''');
  }

  test_superclass_can_be_overriden_no_cast_fails() async {
    await assertErrorsInCode(
      r'''
import 'package:meta/meta.dart' show mustBeConst;

final v = 3;

final r = B().f(v);

abstract class A {
  int f(int i);
}

class B extends A {
  @override
  int f(@mustBeConst int i) => i + 1;
}
''',
      [
        error(WarningCode.NON_CONST_ARGUMENT_FOR_CONST_PARAMETER, 81, 1),
      ],
    );
  }

// This seems to not be supported, as the `mustBeConst` is stripped from the
// metadata of the `staticParameterElement`.

//   test_function_type_fails() async {
//     await assertErrorsInCode(r'''
// import 'package:meta/meta.dart' show mustBeConst;

// void f(void g(@mustBeConst int i), int x) {
//   g(x);
// }
// ''', [
//       error(WarningCode.NON_CONST_ARGUMENT_FOR_CONST_PARAMETER, 103, 1),
//     ]);
//   }

  test_typedef_succeeds() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart' show mustBeConst;

typedef Td = void Function(@mustBeConst int);

void f(Td td) { td(3); }
''');
  }

// This seems to not be supported, as the `mustBeConst` is stripped from the
// metadata of the `staticParameterElement`.

//   test_typedef_fails() async {
//     await assertErrorsInCode(r'''
// import 'package:meta/meta.dart' show mustBeConst;

// typedef Td = void Function(@mustBeConst int);

// void f(int x, Td td) { td(x); }
// ''', [
//       error(WarningCode.NON_CONST_ARGUMENT_FOR_CONST_PARAMETER, 103, 1),
//     ]);
//   }
}
