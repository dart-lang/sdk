// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstAnnotationTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
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
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart' show mustBeConst;
//                                   ^^^^^^^^^^^
// [diag.experimentalMemberUse] 'mustBeConst' is experimental and could be removed or changed at any time.

final c = C('H' 'ello');

class C {
  C(@mustBeConst String s);
//   ^^^^^^^^^^^
// [diag.experimentalMemberUse] 'mustBeConst' is experimental and could be removed or changed at any time.
}
''');
  }

  test_binaryOperator_fails() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart' show mustBeConst;
//                                   ^^^^^^^^^^^
// [diag.experimentalMemberUse] 'mustBeConst' is experimental and could be removed or changed at any time.

void f(A a) {
  var b = A();
  a < b;
//    ^
// [diag.nonConstArgumentForConstParameter] Argument 'other' must be a constant.
}

class A {
  bool operator <(@mustBeConst A other) => false;
//                 ^^^^^^^^^^^
// [diag.experimentalMemberUse] 'mustBeConst' is experimental and could be removed or changed at any time.
}
''');
  }

  test_binaryOperator_fails_inAssignment() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart' show mustBeConst;
//                                   ^^^^^^^^^^^
// [diag.experimentalMemberUse] 'mustBeConst' is experimental and could be removed or changed at any time.

void f(A a) {
  var b = A();
  a += b;
//     ^
// [diag.nonConstArgumentForConstParameter] Argument 'other' must be a constant.
}

class A {
  A operator +(@mustBeConst A other) => this;
//              ^^^^^^^^^^^
// [diag.experimentalMemberUse] 'mustBeConst' is experimental and could be removed or changed at any time.
}
''');
  }

  test_binaryOperator_succeeds() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart' show mustBeConst;
//                                   ^^^^^^^^^^^
// [diag.experimentalMemberUse] 'mustBeConst' is experimental and could be removed or changed at any time.

void f(A a) {
  const b = A();
  a < b;
}

class A {
  const A();

  bool operator <(@mustBeConst A other) => false;
//                 ^^^^^^^^^^^
// [diag.experimentalMemberUse] 'mustBeConst' is experimental and could be removed or changed at any time.
}
''');
  }

  test_binaryOperator_succeeds_inAssignment() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart' show mustBeConst;
//                                   ^^^^^^^^^^^
// [diag.experimentalMemberUse] 'mustBeConst' is experimental and could be removed or changed at any time.

void f(A a) {
  const b = A();
  a += b;
}

class A {
  const A();

  A operator +(@mustBeConst A other) => this;
//              ^^^^^^^^^^^
// [diag.experimentalMemberUse] 'mustBeConst' is experimental and could be removed or changed at any time.
}
''');
  }

  test_constExpression_succeeds() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart' show mustBeConst;
//                                   ^^^^^^^^^^^
// [diag.experimentalMemberUse] 'mustBeConst' is experimental and could be removed or changed at any time.

void f() {
  g(const C());
}

void g(@mustBeConst C c) {}
//      ^^^^^^^^^^^
// [diag.experimentalMemberUse] 'mustBeConst' is experimental and could be removed or changed at any time.

class C {
  const C();
}
''');
  }

  test_constructor_constantLiteral_succeeds() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart' show mustBeConst;
//                                   ^^^^^^^^^^^
// [diag.experimentalMemberUse] 'mustBeConst' is experimental and could be removed or changed at any time.

final c = C(3);

class C {
  C(@mustBeConst int i);
//   ^^^^^^^^^^^
// [diag.experimentalMemberUse] 'mustBeConst' is experimental and could be removed or changed at any time.
}
''');
  }

  test_constructor_extensionType() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart' show mustBeConst;
//                                   ^^^^^^^^^^^
// [diag.experimentalMemberUse] 'mustBeConst' is experimental and could be removed or changed at any time.

final v = 3;

final c = C(v);
//          ^
// [diag.nonConstArgumentForConstParameter] Argument 'it' must be a constant.

extension type C(@mustBeConst int it) {}
//                ^^^^^^^^^^^
// [diag.experimentalMemberUse] 'mustBeConst' is experimental and could be removed or changed at any time.
''');
  }

  test_constructor_variable_fails() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart' show mustBeConst;
//                                   ^^^^^^^^^^^
// [diag.experimentalMemberUse] 'mustBeConst' is experimental and could be removed or changed at any time.

final v = 3;

final c = C(v);
//          ^
// [diag.nonConstArgumentForConstParameter] Argument 'i' must be a constant.

class C {
  C(@mustBeConst int i);
//   ^^^^^^^^^^^
// [diag.experimentalMemberUse] 'mustBeConst' is experimental and could be removed or changed at any time.
}
''');
  }

  test_functionExpression_constantLiteral_succeeds() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart' show mustBeConst;
//                                   ^^^^^^^^^^^
// [diag.experimentalMemberUse] 'mustBeConst' is experimental and could be removed or changed at any time.

void f() {
  var g = (@mustBeConst int i) {};
//          ^^^^^^^^^^^
// [diag.experimentalMemberUse] 'mustBeConst' is experimental and could be removed or changed at any time.
  g(3);
}
''');
  }

  test_functionExpression_variable_fails() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart' show mustBeConst;
//                                   ^^^^^^^^^^^
// [diag.experimentalMemberUse] 'mustBeConst' is experimental and could be removed or changed at any time.

void f(int x) {
  var g = (@mustBeConst int i) {};
//          ^^^^^^^^^^^
// [diag.experimentalMemberUse] 'mustBeConst' is experimental and could be removed or changed at any time.
  g(x);
//  ^
// [diag.nonConstArgumentForConstParameter] Argument 'i' must be a constant.
}
''');
  }

  test_functionType_constantLiteral_succeeds() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart' show mustBeConst;
//                                   ^^^^^^^^^^^
// [diag.experimentalMemberUse] 'mustBeConst' is experimental and could be removed or changed at any time.

void f(void g(@mustBeConst int i)) {
//             ^^^^^^^^^^^
// [diag.experimentalMemberUse] 'mustBeConst' is experimental and could be removed or changed at any time.
  g(3);
}
''');
  }

  test_functionType_variable_fails() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart' show mustBeConst;
//                                   ^^^^^^^^^^^
// [diag.experimentalMemberUse] 'mustBeConst' is experimental and could be removed or changed at any time.

void f(void g(@mustBeConst int i), int x) {
//             ^^^^^^^^^^^
// [diag.experimentalMemberUse] 'mustBeConst' is experimental and could be removed or changed at any time.
  g(x);
//  ^
// [diag.nonConstArgumentForConstParameter] Argument 'i' must be a constant.
}
''');
  }

  test_indexExpression_constExpression_succeeds() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart' show mustBeConst;
//                                   ^^^^^^^^^^^
// [diag.experimentalMemberUse] 'mustBeConst' is experimental and could be removed or changed at any time.

void f(A a) {
  const b = A();
  a[1] = b;
}

class A {
  const A();

  void operator []=(@mustBeConst int i, @mustBeConst A v) {}
//                   ^^^^^^^^^^^
// [diag.experimentalMemberUse] 'mustBeConst' is experimental and could be removed or changed at any time.
//                                       ^^^^^^^^^^^
// [diag.experimentalMemberUse] 'mustBeConst' is experimental and could be removed or changed at any time.
}
''');
  }

  test_indexExpression_nonConstant_fails() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart' show mustBeConst;
//                                   ^^^^^^^^^^^
// [diag.experimentalMemberUse] 'mustBeConst' is experimental and could be removed or changed at any time.

void f(A a) {
  a[1] = A();
//       ^^^
// [diag.nonConstArgumentForConstParameter] Argument 'v' must be a constant.
}

class A {
  const A();

  void operator []=(@mustBeConst int i, @mustBeConst A v) {}
//                   ^^^^^^^^^^^
// [diag.experimentalMemberUse] 'mustBeConst' is experimental and could be removed or changed at any time.
//                                       ^^^^^^^^^^^
// [diag.experimentalMemberUse] 'mustBeConst' is experimental and could be removed or changed at any time.
}
''');
  }

  test_interpolationLiteral_fails() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart' show mustBeConst;
//                                   ^^^^^^^^^^^
// [diag.experimentalMemberUse] 'mustBeConst' is experimental and could be removed or changed at any time.

const a = 'ello';

final c = C('H$a');
//          ^^^^^
// [diag.nonConstArgumentForConstParameter] Argument 's' must be a constant.

class C {
  C(@mustBeConst String s);
//   ^^^^^^^^^^^
// [diag.experimentalMemberUse] 'mustBeConst' is experimental and could be removed or changed at any time.
}
''');
  }

  test_localFunction_constantLiteral_succeeds() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart' show mustBeConst;
//                                   ^^^^^^^^^^^
// [diag.experimentalMemberUse] 'mustBeConst' is experimental and could be removed or changed at any time.

void f() {
  void g(@mustBeConst int i) {}
//        ^^^^^^^^^^^
// [diag.experimentalMemberUse] 'mustBeConst' is experimental and could be removed or changed at any time.
  g(3);
}
''');
  }

  test_localFunction_variable_fails() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart' show mustBeConst;
//                                   ^^^^^^^^^^^
// [diag.experimentalMemberUse] 'mustBeConst' is experimental and could be removed or changed at any time.

void f(int x) {
  void g(@mustBeConst int i) {}
//        ^^^^^^^^^^^
// [diag.experimentalMemberUse] 'mustBeConst' is experimental and could be removed or changed at any time.
  g(x);
//  ^
// [diag.nonConstArgumentForConstParameter] Argument 'i' must be a constant.
}
''');
  }

  test_method_constantLiteral_succeeds() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart' show mustBeConst;
//                                   ^^^^^^^^^^^
// [diag.experimentalMemberUse] 'mustBeConst' is experimental and could be removed or changed at any time.

void f(C c) => c.g(3);

class C {
  void g([@mustBeConst int? value]) {}
//         ^^^^^^^^^^^
// [diag.experimentalMemberUse] 'mustBeConst' is experimental and could be removed or changed at any time.
}
''');
  }

  test_method_variable_fails() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart' show mustBeConst;
//                                   ^^^^^^^^^^^
// [diag.experimentalMemberUse] 'mustBeConst' is experimental and could be removed or changed at any time.

final v = 3;

void f(C c) => c.g(v);
//                 ^
// [diag.nonConstArgumentForConstParameter] Argument 'value' must be a constant.

class C {
  void g([@mustBeConst int? value]) {}
//         ^^^^^^^^^^^
// [diag.experimentalMemberUse] 'mustBeConst' is experimental and could be removed or changed at any time.
}
''');
  }

  test_optionalNamed_constVariable_succeeds() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart' show mustBeConst;
//                                   ^^^^^^^^^^^
// [diag.experimentalMemberUse] 'mustBeConst' is experimental and could be removed or changed at any time.

const v = 3;

void f() => g(value: v);

void g({@mustBeConst int? value}) {}
//       ^^^^^^^^^^^
// [diag.experimentalMemberUse] 'mustBeConst' is experimental and could be removed or changed at any time.
''');
  }

  test_optionalNamed_noArgument_succeeds() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart' show mustBeConst;
//                                   ^^^^^^^^^^^
// [diag.experimentalMemberUse] 'mustBeConst' is experimental and could be removed or changed at any time.

void f() => g();

void g({@mustBeConst int? value}) {}
//       ^^^^^^^^^^^
// [diag.experimentalMemberUse] 'mustBeConst' is experimental and could be removed or changed at any time.
''');
  }

  test_optionalNamed_variable_fails() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart' show mustBeConst;
//                                   ^^^^^^^^^^^
// [diag.experimentalMemberUse] 'mustBeConst' is experimental and could be removed or changed at any time.

final v = 3;

void f() => g(value: v);
//            ^^^^^^^^
// [diag.nonConstArgumentForConstParameter] Argument 'value' must be a constant.

void g({@mustBeConst int? value}) {}
//       ^^^^^^^^^^^
// [diag.experimentalMemberUse] 'mustBeConst' is experimental and could be removed or changed at any time.
''');
  }

  test_optionalPositional_constVariable_succeeds() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart' show mustBeConst;
//                                   ^^^^^^^^^^^
// [diag.experimentalMemberUse] 'mustBeConst' is experimental and could be removed or changed at any time.

const v = 3;

void f() => g(v);

void g([@mustBeConst int? value]) {}
//       ^^^^^^^^^^^
// [diag.experimentalMemberUse] 'mustBeConst' is experimental and could be removed or changed at any time.
''');
  }

  test_optionalPositional_noArgument_succeeds() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart' show mustBeConst;
//                                   ^^^^^^^^^^^
// [diag.experimentalMemberUse] 'mustBeConst' is experimental and could be removed or changed at any time.

void f() => g();

void g([@mustBeConst int? value]) {}
//       ^^^^^^^^^^^
// [diag.experimentalMemberUse] 'mustBeConst' is experimental and could be removed or changed at any time.
''');
  }

  test_optionalPositional_variable_fails() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart' show mustBeConst;
//                                   ^^^^^^^^^^^
// [diag.experimentalMemberUse] 'mustBeConst' is experimental and could be removed or changed at any time.

final v = 3;

void f() => g(v);
//            ^
// [diag.nonConstArgumentForConstParameter] Argument 'value' must be a constant.

void g([@mustBeConst int? value]) {}
//       ^^^^^^^^^^^
// [diag.experimentalMemberUse] 'mustBeConst' is experimental and could be removed or changed at any time.
''');
  }

  test_primaryConstructor_constantLiteral_succeeds() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart' show mustBeConst;
//                                   ^^^^^^^^^^^
// [diag.experimentalMemberUse] 'mustBeConst' is experimental and could be removed or changed at any time.

final c = C(3);

class C(@mustBeConst int i);
//       ^^^^^^^^^^^
// [diag.experimentalMemberUse] 'mustBeConst' is experimental and could be removed or changed at any time.
''');
  }

  test_primaryConstructor_variable_fails() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart' show mustBeConst;
//                                   ^^^^^^^^^^^
// [diag.experimentalMemberUse] 'mustBeConst' is experimental and could be removed or changed at any time.

final f = 3;
final c = C(f);
//          ^
// [diag.nonConstArgumentForConstParameter] Argument 'i' must be a constant.

class C(@mustBeConst int i);
//       ^^^^^^^^^^^
// [diag.experimentalMemberUse] 'mustBeConst' is experimental and could be removed or changed at any time.
''');
  }

  test_redirectingConstructor_variable_fails() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart' show mustBeConst;
//                                   ^^^^^^^^^^^
// [diag.experimentalMemberUse] 'mustBeConst' is experimental and could be removed or changed at any time.

class A {
  A(@mustBeConst int i);
//   ^^^^^^^^^^^
// [diag.experimentalMemberUse] 'mustBeConst' is experimental and could be removed or changed at any time.
  A.named(int i) : this(i);
//                      ^
// [diag.nonConstArgumentForConstParameter] Argument 'i' must be a constant.
}
''');
  }

  test_redirectingFactoryConstructor_variable_succeeds() async {
    // The call to `A.named(v)` is not considered a direct call to `A()`; while
    // the parameters declared in `A.named` must "match" those in `A.new`, they
    // are separate. For example, they can have separate annotations.
    // TODO(srawlins): It still seems that to be consistent, we should report
    // `A.named(int i)`.
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart' show mustBeConst;
//                                   ^^^^^^^^^^^
// [diag.experimentalMemberUse] 'mustBeConst' is experimental and could be removed or changed at any time.

class A {
  A(@mustBeConst int i);
//   ^^^^^^^^^^^
// [diag.experimentalMemberUse] 'mustBeConst' is experimental and could be removed or changed at any time.
  factory A.named(int i) = A;
}

final v = 3;
var a = A.named(v);
''');
  }

  test_requiredNamed_constantLiteral_succeeds() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart' show mustBeConst;
//                                   ^^^^^^^^^^^
// [diag.experimentalMemberUse] 'mustBeConst' is experimental and could be removed or changed at any time.

void f() => g(value: 3);

void g({@mustBeConst required int value}) {}
//       ^^^^^^^^^^^
// [diag.experimentalMemberUse] 'mustBeConst' is experimental and could be removed or changed at any time.
''');
  }

  test_requiredNamed_constVariable_succeeds() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart' show mustBeConst;
//                                   ^^^^^^^^^^^
// [diag.experimentalMemberUse] 'mustBeConst' is experimental and could be removed or changed at any time.

const v = 3;

void f() => g(value: v);

void g({@mustBeConst required int value}) {}
//       ^^^^^^^^^^^
// [diag.experimentalMemberUse] 'mustBeConst' is experimental and could be removed or changed at any time.
''');
  }

  test_requiredPositional_constVariable_succeeds() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart' show mustBeConst;
//                                   ^^^^^^^^^^^
// [diag.experimentalMemberUse] 'mustBeConst' is experimental and could be removed or changed at any time.

const v = 3;

void f() => g(v);

void g(@mustBeConst int value) {}
//      ^^^^^^^^^^^
// [diag.experimentalMemberUse] 'mustBeConst' is experimental and could be removed or changed at any time.
''');
  }

  test_requiredPositional_list_constVariable_succeeds() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart' show mustBeConst;
//                                   ^^^^^^^^^^^
// [diag.experimentalMemberUse] 'mustBeConst' is experimental and could be removed or changed at any time.

const v = [3,4];

void f() => g(v);

void g(@mustBeConst List<int> value) {}
//      ^^^^^^^^^^^
// [diag.experimentalMemberUse] 'mustBeConst' is experimental and could be removed or changed at any time.
''');
  }

  test_requiredPositional_localVariable_fails() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart' show mustBeConst;
//                                   ^^^^^^^^^^^
// [diag.experimentalMemberUse] 'mustBeConst' is experimental and could be removed or changed at any time.

void f(int value) => g(value);
//                     ^^^^^
// [diag.nonConstArgumentForConstParameter] Argument 'value' must be a constant.

void g(@mustBeConst int value) {}
//      ^^^^^^^^^^^
// [diag.experimentalMemberUse] 'mustBeConst' is experimental and could be removed or changed at any time.
''');
  }

  test_requiredPositional_map_constVariable_succeeds() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart' show mustBeConst;
//                                   ^^^^^^^^^^^
// [diag.experimentalMemberUse] 'mustBeConst' is experimental and could be removed or changed at any time.

const v = {'k1': 3, 'k2': 4};

void f() => g(v);

void g(@mustBeConst Map<String, int> value) {}
//      ^^^^^^^^^^^
// [diag.experimentalMemberUse] 'mustBeConst' is experimental and could be removed or changed at any time.
''');
  }

  test_requiredPositional_topLevelVariable_fails() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart' show mustBeConst;
//                                   ^^^^^^^^^^^
// [diag.experimentalMemberUse] 'mustBeConst' is experimental and could be removed or changed at any time.

final v = 3;

void f() => g(v);
//            ^
// [diag.nonConstArgumentForConstParameter] Argument 'value' must be a constant.

void g(@mustBeConst int value) {}
//      ^^^^^^^^^^^
// [diag.experimentalMemberUse] 'mustBeConst' is experimental and could be removed or changed at any time.
''');
  }

  test_setter_fails() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart' show mustBeConst;
//                                   ^^^^^^^^^^^
// [diag.experimentalMemberUse] 'mustBeConst' is experimental and could be removed or changed at any time.

void f() {
  final v = 3;
  i = v;
//    ^
// [diag.nonConstArgumentForConstParameter] Argument 'value' must be a constant.
}

set i(@mustBeConst int? value) {}
//     ^^^^^^^^^^^
// [diag.experimentalMemberUse] 'mustBeConst' is experimental and could be removed or changed at any time.
''');
  }

  test_setter_succeeds() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart' show mustBeConst;
//                                   ^^^^^^^^^^^
// [diag.experimentalMemberUse] 'mustBeConst' is experimental and could be removed or changed at any time.

void f() {
  i = 3;
}

set i(@mustBeConst int? value) {}
//     ^^^^^^^^^^^
// [diag.experimentalMemberUse] 'mustBeConst' is experimental and could be removed or changed at any time.
''');
  }

  test_subclassesDontInherit() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart' show mustBeConst;
//                                   ^^^^^^^^^^^
// [diag.experimentalMemberUse] 'mustBeConst' is experimental and could be removed or changed at any time.

final v = 3;

final r = B().f(v);

abstract class A {
  void f(@mustBeConst int i);
//        ^^^^^^^^^^^
// [diag.experimentalMemberUse] 'mustBeConst' is experimental and could be removed or changed at any time.
}

class B extends A {
  @override
  void f(int i) {}
}
''');
  }

  test_superclassCanBeOverriden_cast_succeeds() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart' show mustBeConst;
//                                   ^^^^^^^^^^^
// [diag.experimentalMemberUse] 'mustBeConst' is experimental and could be removed or changed at any time.

final v = 3;

final r = (B() as A).f(v);

abstract class A {
  void f(int i);
}

class B extends A {
  @override
  void f(@mustBeConst int i) {}
//        ^^^^^^^^^^^
// [diag.experimentalMemberUse] 'mustBeConst' is experimental and could be removed or changed at any time.
}
''');
  }

  test_superclassCanBeOverriden_noCast_fails() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart' show mustBeConst;
//                                   ^^^^^^^^^^^
// [diag.experimentalMemberUse] 'mustBeConst' is experimental and could be removed or changed at any time.

final v = 3;

final r = B().f(v);
//              ^
// [diag.nonConstArgumentForConstParameter] Argument 'i' must be a constant.

abstract class A {
  void f(int i);
}

class B extends A {
  @override
  void f(@mustBeConst int i) {}
//        ^^^^^^^^^^^
// [diag.experimentalMemberUse] 'mustBeConst' is experimental and could be removed or changed at any time.
}
''');
  }

  test_superConstructor_variable_fails() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart' show mustBeConst;
//                                   ^^^^^^^^^^^
// [diag.experimentalMemberUse] 'mustBeConst' is experimental and could be removed or changed at any time.

class A {
  A(@mustBeConst int i);
//   ^^^^^^^^^^^
// [diag.experimentalMemberUse] 'mustBeConst' is experimental and could be removed or changed at any time.
}

class B extends A {
  B(int i) : super(i);
//                 ^
// [diag.nonConstArgumentForConstParameter] Argument 'i' must be a constant.
}
''');
  }

  test_superParameter_variable_succeeds() async {
    // TODO(srawlins): It seems that to be consistent, we should `super.i`.
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart' show mustBeConst;
//                                   ^^^^^^^^^^^
// [diag.experimentalMemberUse] 'mustBeConst' is experimental and could be removed or changed at any time.

class A {
  A(@mustBeConst int i);
//   ^^^^^^^^^^^
// [diag.experimentalMemberUse] 'mustBeConst' is experimental and could be removed or changed at any time.
}

class B extends A {
  B(super.i);
}
''');
  }

  test_typedef_function_constantLiteral_succeeds() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart' show mustBeConst;
//                                   ^^^^^^^^^^^
// [diag.experimentalMemberUse] 'mustBeConst' is experimental and could be removed or changed at any time.

typedef Td = void Function(@mustBeConst int);
//                          ^^^^^^^^^^^
// [diag.experimentalMemberUse] 'mustBeConst' is experimental and could be removed or changed at any time.

void f(Td td) {
  td(3);
}
''');
  }

  test_typedef_function_variable_succeeds() async {
    // An annotation on a parameter in a function type is not supported.
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart' show mustBeConst;
//                                   ^^^^^^^^^^^
// [diag.experimentalMemberUse] 'mustBeConst' is experimental and could be removed or changed at any time.

typedef Td = void Function(@mustBeConst int);
//                          ^^^^^^^^^^^
// [diag.experimentalMemberUse] 'mustBeConst' is experimental and could be removed or changed at any time.

void f(int x, Td td) {
  td(x);
}
''');
  }

  test_typedef_nonFunction_variable_fails() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart' show mustBeConst;
//                                   ^^^^^^^^^^^
// [diag.experimentalMemberUse] 'mustBeConst' is experimental and could be removed or changed at any time.

typedef T = C;

class C {
  C(@mustBeConst int i);
//   ^^^^^^^^^^^
// [diag.experimentalMemberUse] 'mustBeConst' is experimental and could be removed or changed at any time.
}

void g(int x) => T(x);
//                 ^
// [diag.nonConstArgumentForConstParameter] Argument 'i' must be a constant.
''');
  }
}
