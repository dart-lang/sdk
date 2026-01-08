// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
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

  test_adjacentLiteral_succeeds() async {
    await assertErrorsInCode(
      r'''
import 'package:meta/meta.dart' show mustBeConst;

final c = C('H' 'ello');

class C {
  C(@mustBeConst String s);
}
''',
      [
        error(diag.experimentalMemberUse, 37, 11),
        error(diag.experimentalMemberUse, 92, 11),
      ],
    );
  }

  test_binaryOperator_fails() async {
    await assertErrorsInCode(
      r'''
import 'package:meta/meta.dart' show mustBeConst;

void f(A a) {
  var b = A();
  a < b;
}

class A {
  bool operator <(@mustBeConst A other) => false;
}
''',
      [
        error(diag.experimentalMemberUse, 37, 11),
        error(diag.nonConstArgumentForConstParameter, 86, 1),
        error(diag.experimentalMemberUse, 121, 11),
      ],
    );
  }

  test_binaryOperator_succeeds() async {
    await assertErrorsInCode(
      r'''
import 'package:meta/meta.dart' show mustBeConst;

void f(A a) {
  const b = A();
  a < b;
}

class A {
  const A();

  bool operator <(@mustBeConst A other) => false;
}
''',
      [
        error(diag.experimentalMemberUse, 37, 11),
        error(diag.experimentalMemberUse, 137, 11),
      ],
    );
  }

  test_constExpression_succeeds() async {
    await assertErrorsInCode(
      r'''
import 'package:meta/meta.dart' show mustBeConst;

void f() {
  g(const C());
}

void g(@mustBeConst C c) {}

class C {
  const C();
}
''',
      [
        error(diag.experimentalMemberUse, 37, 11),
        error(diag.experimentalMemberUse, 89, 11),
      ],
    );
  }

  test_constructor_constantLiteral_succeeds() async {
    await assertErrorsInCode(
      r'''
import 'package:meta/meta.dart' show mustBeConst;

final c = C(3);

class C {
  C(@mustBeConst int i);
}
''',
      [
        error(diag.experimentalMemberUse, 37, 11),
        error(diag.experimentalMemberUse, 83, 11),
      ],
    );
  }

  test_constructor_extensionType() async {
    await assertErrorsInCode(
      r'''
import 'package:meta/meta.dart' show mustBeConst;

final v = 3;

final c = C(v);

extension type C(@mustBeConst int it) {}
''',
      [
        error(diag.experimentalMemberUse, 37, 11),
        error(diag.nonConstArgumentForConstParameter, 77, 1),
        error(diag.experimentalMemberUse, 100, 11),
      ],
    );
  }

  test_constructor_variable_fails() async {
    await assertErrorsInCode(
      r'''
import 'package:meta/meta.dart' show mustBeConst;

final v = 3;

final c = C(v);

class C {
  C(@mustBeConst int i);
}
''',
      [
        error(diag.experimentalMemberUse, 37, 11),
        error(diag.nonConstArgumentForConstParameter, 77, 1),
        error(diag.experimentalMemberUse, 97, 11),
      ],
    );
  }

  test_functionExpression_constantLiteral_succeeds() async {
    await assertErrorsInCode(
      r'''
import 'package:meta/meta.dart' show mustBeConst;

void f() {
  var g = (@mustBeConst int i) {};
  g(3);
}
''',
      [
        error(diag.experimentalMemberUse, 37, 11),
        error(diag.experimentalMemberUse, 74, 11),
      ],
    );
  }

  test_functionExpression_variable_fails() async {
    await assertErrorsInCode(
      r'''
import 'package:meta/meta.dart' show mustBeConst;

void f(int x) {
  var g = (@mustBeConst int i) {};
  g(x);
}
''',
      [
        error(diag.experimentalMemberUse, 37, 11),
        error(diag.experimentalMemberUse, 79, 11),
        error(diag.nonConstArgumentForConstParameter, 106, 1),
      ],
    );
  }

  test_functionType_constantLiteral_succeeds() async {
    await assertErrorsInCode(
      r'''
import 'package:meta/meta.dart' show mustBeConst;

void f(void g(@mustBeConst int i)) {
  g(3);
}
''',
      [
        error(diag.experimentalMemberUse, 37, 11),
        error(diag.experimentalMemberUse, 66, 11),
      ],
    );
  }

  test_functionType_variable_fails() async {
    await assertErrorsInCode(
      r'''
import 'package:meta/meta.dart' show mustBeConst;

void f(void g(@mustBeConst int i), int x) {
  g(x);
}
''',
      [
        error(diag.experimentalMemberUse, 37, 11),
        error(diag.experimentalMemberUse, 66, 11),
        error(diag.nonConstArgumentForConstParameter, 99, 1),
      ],
    );
  }

  test_indexExpression_constExpression_succeeds() async {
    await assertErrorsInCode(
      r'''
import 'package:meta/meta.dart' show mustBeConst;

void f(A a) {
  const b = A();
  a[1] = b;
}

class A {
  const A();

  void operator []=(@mustBeConst int i, @mustBeConst A v) {}
}
''',
      [
        error(diag.experimentalMemberUse, 37, 11),
        error(diag.experimentalMemberUse, 142, 11),
        error(diag.experimentalMemberUse, 162, 11),
      ],
    );
  }

  test_indexExpression_nonConstant_fails() async {
    await assertErrorsInCode(
      r'''
import 'package:meta/meta.dart' show mustBeConst;

void f(A a) {
  a[1] = A();
}

class A {
  const A();

  void operator []=(@mustBeConst int i, @mustBeConst A v) {}
}
''',
      [
        error(diag.experimentalMemberUse, 37, 11),
        error(diag.nonConstArgumentForConstParameter, 74, 3),
        error(diag.experimentalMemberUse, 127, 11),
        error(diag.experimentalMemberUse, 147, 11),
      ],
    );
  }

  test_interpolationLiteral_fails() async {
    await assertErrorsInCode(
      r'''
import 'package:meta/meta.dart' show mustBeConst;

const a = 'ello';

final c = C('H$a');

class C {
  C(@mustBeConst String s);
}
''',
      [
        error(diag.experimentalMemberUse, 37, 11),
        error(diag.nonConstArgumentForConstParameter, 82, 5),
        error(diag.experimentalMemberUse, 106, 11),
      ],
    );
  }

  test_localFunction_constantLiteral_succeeds() async {
    await assertErrorsInCode(
      r'''
import 'package:meta/meta.dart' show mustBeConst;

void f() {
  void g(@mustBeConst int i) {}
  g(3);
}
''',
      [
        error(diag.experimentalMemberUse, 37, 11),
        error(diag.experimentalMemberUse, 72, 11),
      ],
    );
  }

  test_localFunction_variable_fails() async {
    await assertErrorsInCode(
      r'''
import 'package:meta/meta.dart' show mustBeConst;

void f(int x) {
  void g(@mustBeConst int i) {}
  g(x);
}
''',
      [
        error(diag.experimentalMemberUse, 37, 11),
        error(diag.experimentalMemberUse, 77, 11),
        error(diag.nonConstArgumentForConstParameter, 103, 1),
      ],
    );
  }

  test_method_constantLiteral_succeeds() async {
    await assertErrorsInCode(
      r'''
import 'package:meta/meta.dart' show mustBeConst;

void f(C c) => c.g(3);

class C {
  void g([@mustBeConst int? value]) {}
}
''',
      [
        error(diag.experimentalMemberUse, 37, 11),
        error(diag.experimentalMemberUse, 96, 11),
      ],
    );
  }

  test_method_variable_fails() async {
    await assertErrorsInCode(
      r'''
import 'package:meta/meta.dart' show mustBeConst;

final v = 3;

void f(C c) => c.g(v);

class C {
  void g([@mustBeConst int? value]) {}
}
''',
      [
        error(diag.experimentalMemberUse, 37, 11),
        error(diag.nonConstArgumentForConstParameter, 84, 1),
        error(diag.experimentalMemberUse, 110, 11),
      ],
    );
  }

  test_optionalNamed_constVariable_succeeds() async {
    await assertErrorsInCode(
      r'''
import 'package:meta/meta.dart' show mustBeConst;

const v = 3;

void f() => g(value: v);

void g({@mustBeConst int? value}) {}
''',
      [
        error(diag.experimentalMemberUse, 37, 11),
        error(diag.experimentalMemberUse, 100, 11),
      ],
    );
  }

  test_optionalNamed_noArgument_succeeds() async {
    await assertErrorsInCode(
      r'''
import 'package:meta/meta.dart' show mustBeConst;

void f() => g();

void g({@mustBeConst int? value}) {}
''',
      [
        error(diag.experimentalMemberUse, 37, 11),
        error(diag.experimentalMemberUse, 78, 11),
      ],
    );
  }

  test_optionalNamed_variable_fails() async {
    await assertErrorsInCode(
      r'''
import 'package:meta/meta.dart' show mustBeConst;

final v = 3;

void f() => g(value: v);

void g({@mustBeConst int? value}) {}
''',
      [
        error(diag.experimentalMemberUse, 37, 11),
        error(diag.nonConstArgumentForConstParameter, 79, 8),
        error(diag.experimentalMemberUse, 100, 11),
      ],
    );
  }

  test_optionalPositional_constVariable_succeeds() async {
    await assertErrorsInCode(
      r'''
import 'package:meta/meta.dart' show mustBeConst;

const v = 3;

void f() => g(v);

void g([@mustBeConst int? value]) {}
''',
      [
        error(diag.experimentalMemberUse, 37, 11),
        error(diag.experimentalMemberUse, 93, 11),
      ],
    );
  }

  test_optionalPositional_noArgument_succeeds() async {
    await assertErrorsInCode(
      r'''
import 'package:meta/meta.dart' show mustBeConst;

void f() => g();

void g([@mustBeConst int? value]) {}
''',
      [
        error(diag.experimentalMemberUse, 37, 11),
        error(diag.experimentalMemberUse, 78, 11),
      ],
    );
  }

  test_optionalPositional_variable_fails() async {
    await assertErrorsInCode(
      r'''
import 'package:meta/meta.dart' show mustBeConst;

final v = 3;

void f() => g(v);

void g([@mustBeConst int? value]) {}
''',
      [
        error(diag.experimentalMemberUse, 37, 11),
        error(diag.nonConstArgumentForConstParameter, 79, 1),
        error(diag.experimentalMemberUse, 93, 11),
      ],
    );
  }

  test_redirectingConstructor_variable_fails() async {
    await assertErrorsInCode(
      r'''
import 'package:meta/meta.dart' show mustBeConst;

class A {
  A(@mustBeConst int i);
  A.named(int i) : this(i);
}
''',
      [
        error(diag.experimentalMemberUse, 37, 11),
        error(diag.experimentalMemberUse, 66, 11),
        error(diag.nonConstArgumentForConstParameter, 110, 1),
      ],
    );
  }

  test_redirectingFactoryConstructor_variable_succeeds() async {
    // The call to `A.named(v)` is not considered a direct call to `A()`; while
    // the parameters declared in `A.named` must "match" those in `A.new`, they
    // are separate. For example, they can have separate annotations.
    // TODO(srawlins): It still seems that to be consistent, we should report
    // `A.named(int i)`.
    await assertErrorsInCode(
      r'''
import 'package:meta/meta.dart' show mustBeConst;

class A {
  A(@mustBeConst int i);
  factory A.named(int i) = A;
}

final v = 3;
var a = A.named(v);
''',
      [
        error(diag.experimentalMemberUse, 37, 11),
        error(diag.experimentalMemberUse, 66, 11),
      ],
    );
  }

  test_requiredNamed_constantLiteral_succeeds() async {
    await assertErrorsInCode(
      r'''
import 'package:meta/meta.dart' show mustBeConst;

void f() => g(value: 3);

void g({@mustBeConst required int value}) {}
''',
      [
        error(diag.experimentalMemberUse, 37, 11),
        error(diag.experimentalMemberUse, 86, 11),
      ],
    );
  }

  test_requiredNamed_constVariable_succeeds() async {
    await assertErrorsInCode(
      r'''
import 'package:meta/meta.dart' show mustBeConst;

const v = 3;

void f() => g(value: v);

void g({@mustBeConst required int value}) {}
''',
      [
        error(diag.experimentalMemberUse, 37, 11),
        error(diag.experimentalMemberUse, 100, 11),
      ],
    );
  }

  test_requiredPositional_constVariable_succeeds() async {
    await assertErrorsInCode(
      r'''
import 'package:meta/meta.dart' show mustBeConst;

const v = 3;

void f() => g(v);

void g(@mustBeConst int value) {}
''',
      [
        error(diag.experimentalMemberUse, 37, 11),
        error(diag.experimentalMemberUse, 92, 11),
      ],
    );
  }

  test_requiredPositional_list_constVariable_succeeds() async {
    await assertErrorsInCode(
      r'''
import 'package:meta/meta.dart' show mustBeConst;

const v = [3,4];

void f() => g(v);

void g(@mustBeConst List<int> value) {}
''',
      [
        error(diag.experimentalMemberUse, 37, 11),
        error(diag.experimentalMemberUse, 96, 11),
      ],
    );
  }

  test_requiredPositional_localVariable_fails() async {
    await assertErrorsInCode(
      r'''
import 'package:meta/meta.dart' show mustBeConst;

void f(int value) => g(value);

void g(@mustBeConst int value) {}
''',
      [
        error(diag.experimentalMemberUse, 37, 11),
        error(diag.nonConstArgumentForConstParameter, 74, 5),
        error(diag.experimentalMemberUse, 91, 11),
      ],
    );
  }

  test_requiredPositional_map_constVariable_succeeds() async {
    await assertErrorsInCode(
      r'''
import 'package:meta/meta.dart' show mustBeConst;

const v = {'k1': 3, 'k2': 4};

void f() => g(v);

void g(@mustBeConst Map<String, int> value) {}
''',
      [
        error(diag.experimentalMemberUse, 37, 11),
        error(diag.experimentalMemberUse, 109, 11),
      ],
    );
  }

  test_requiredPositional_topLevelVariable_fails() async {
    await assertErrorsInCode(
      r'''
import 'package:meta/meta.dart' show mustBeConst;

final v = 3;

void f() => g(v);

void g(@mustBeConst int value) {}
''',
      [
        error(diag.experimentalMemberUse, 37, 11),
        error(diag.nonConstArgumentForConstParameter, 79, 1),
        error(diag.experimentalMemberUse, 92, 11),
      ],
    );
  }

  test_setter_fails() async {
    await assertErrorsInCode(
      r'''
import 'package:meta/meta.dart' show mustBeConst;

void f() {
  final v = 3;
  i = v;
}

set i(@mustBeConst int? value) {}
''',
      [
        error(diag.experimentalMemberUse, 37, 11),
        error(diag.nonConstArgumentForConstParameter, 83, 1),
        error(diag.experimentalMemberUse, 96, 11),
      ],
    );
  }

  test_setter_succeeds() async {
    await assertErrorsInCode(
      r'''
import 'package:meta/meta.dart' show mustBeConst;

void f() {
  i = 3;
}

set i(@mustBeConst int? value) {}
''',
      [
        error(diag.experimentalMemberUse, 37, 11),
        error(diag.experimentalMemberUse, 81, 11),
      ],
    );
  }

  test_subclassesDontInherit() async {
    await assertErrorsInCode(
      r'''
import 'package:meta/meta.dart' show mustBeConst;

final v = 3;

final r = B().f(v);

abstract class A {
  void f(@mustBeConst int i);
}

class B extends A {
  @override
  void f(int i) {}
}
''',
      [
        error(diag.experimentalMemberUse, 37, 11),
        error(diag.experimentalMemberUse, 115, 11),
      ],
    );
  }

  test_superclassCanBeOverriden_cast_succeeds() async {
    await assertErrorsInCode(
      r'''
import 'package:meta/meta.dart' show mustBeConst;

final v = 3;

final r = (B() as A).f(v);

abstract class A {
  void f(int i);
}

class B extends A {
  @override
  void f(@mustBeConst int i) {}
}
''',
      [
        error(diag.experimentalMemberUse, 37, 11),
        error(diag.experimentalMemberUse, 174, 11),
      ],
    );
  }

  test_superclassCanBeOverriden_noCast_fails() async {
    await assertErrorsInCode(
      r'''
import 'package:meta/meta.dart' show mustBeConst;

final v = 3;

final r = B().f(v);

abstract class A {
  void f(int i);
}

class B extends A {
  @override
  void f(@mustBeConst int i) {}
}
''',
      [
        error(diag.experimentalMemberUse, 37, 11),
        error(diag.nonConstArgumentForConstParameter, 81, 1),
        error(diag.experimentalMemberUse, 167, 11),
      ],
    );
  }

  test_superConstructor_variable_fails() async {
    await assertErrorsInCode(
      r'''
import 'package:meta/meta.dart' show mustBeConst;

class A {
  A(@mustBeConst int i);
}

class B extends A {
  B(int i) : super(i);
}
''',
      [
        error(diag.experimentalMemberUse, 37, 11),
        error(diag.experimentalMemberUse, 66, 11),
        error(diag.nonConstArgumentForConstParameter, 128, 1),
      ],
    );
  }

  test_superParameter_variable_succeeds() async {
    // TODO(srawlins): It seems that to be consistent, we should `super.i`.
    await assertErrorsInCode(
      r'''
import 'package:meta/meta.dart' show mustBeConst;

class A {
  A(@mustBeConst int i);
}

class B extends A {
  B(super.i);
}
''',
      [
        error(diag.experimentalMemberUse, 37, 11),
        error(diag.experimentalMemberUse, 66, 11),
      ],
    );
  }

  test_typedef_function_constantLiteral_succeeds() async {
    await assertErrorsInCode(
      r'''
import 'package:meta/meta.dart' show mustBeConst;

typedef Td = void Function(@mustBeConst int);

void f(Td td) {
  td(3);
}
''',
      [
        error(diag.experimentalMemberUse, 37, 11),
        error(diag.experimentalMemberUse, 79, 11),
      ],
    );
  }

  test_typedef_function_variable_succeeds() async {
    // An annotation on a parameter in a function type is not supported.
    await assertErrorsInCode(
      r'''
import 'package:meta/meta.dart' show mustBeConst;

typedef Td = void Function(@mustBeConst int);

void f(int x, Td td) {
  td(x);
}
''',
      [
        error(diag.experimentalMemberUse, 37, 11),
        error(diag.experimentalMemberUse, 79, 11),
      ],
    );
  }

  test_typedef_nonFunction_variable_fails() async {
    await assertErrorsInCode(
      r'''
import 'package:meta/meta.dart' show mustBeConst;

typedef T = C;

class C {
  C(@mustBeConst int i);
}

void g(int x) => T(x);
''',
      [
        error(diag.experimentalMemberUse, 37, 11),
        error(diag.experimentalMemberUse, 82, 11),
        error(diag.nonConstArgumentForConstParameter, 124, 1),
      ],
    );
  }
}
