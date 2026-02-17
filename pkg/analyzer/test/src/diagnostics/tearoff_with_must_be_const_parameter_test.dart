// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TearoffWithMustBeConstParameterTest);
  });
}

@reflectiveTest
class TearoffWithMustBeConstParameterTest extends PubPackageResolutionTest {
  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfigWithMeta();
  }

  test_constructor_invocation() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';
var g = C.new(1);
class C {
  // ignore: experimental_member_use
  C(@mustBeConst int x);
}
''');
  }

  test_constructor_tearoff() async {
    await assertErrorsInCode(
      r'''
import 'package:meta/meta.dart';
var g = C.new;
class C {
  // ignore: experimental_member_use
  C(@mustBeConst int x);
}
''',
      [error(diag.tearoffWithMustBeConstParameter, 41, 5)],
    );
  }

  test_function_invocation() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';
var g = f(1);
// ignore: experimental_member_use
void f(@mustBeConst int x) {}
''');
  }

  test_function_tearoff() async {
    await assertErrorsInCode(
      r'''
import 'package:meta/meta.dart';
var g = f;
// ignore: experimental_member_use
void f(@mustBeConst int x) {}
''',
      [error(diag.tearoffWithMustBeConstParameter, 41, 1)],
    );
  }

  test_genericFunction_instantiated_tearoff() async {
    await assertErrorsInCode(
      r'''
import 'package:meta/meta.dart';
var g = f<int>;
// ignore: experimental_member_use
void f<T>(@mustBeConst T x) {}
''',
      [error(diag.tearoffWithMustBeConstParameter, 41, 1)],
    );
  }

  test_method_implicitThis_tearoff() async {
    await assertErrorsInCode(
      r'''
import 'package:meta/meta.dart';
class C {
  Object get n => m;
  // ignore: experimental_member_use
  void m(@mustBeConst int x) {}
}
''',
      [error(diag.tearoffWithMustBeConstParameter, 61, 1)],
    );
  }

  test_method_invocation() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';
var g = C().m(1);
class C {
  // ignore: experimental_member_use
  void m(@mustBeConst int x) {}
}
''');
  }

  test_method_tearoff() async {
    await assertErrorsInCode(
      r'''
import 'package:meta/meta.dart';
var g = C().m;
class C {
  // ignore: experimental_member_use
  void m(@mustBeConst int x) {}
}
''',
      [error(diag.tearoffWithMustBeConstParameter, 45, 1)],
    );
  }
}
