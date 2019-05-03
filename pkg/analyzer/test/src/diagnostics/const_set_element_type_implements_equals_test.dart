// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstSetElementTypeImplementsEqualsTest);
    defineReflectiveTests(
        ConstSetElementTypeImplementsEqualsWithUIAsCodeAndConstantsTest);
    defineReflectiveTests(
      ConstSetElementTypeImplementsEqualsWithUIAsCodeTest,
    );
  });
}

@reflectiveTest
class ConstSetElementTypeImplementsEqualsTest extends DriverResolutionTest {
  test_constField() async {
    await assertErrorCodesInCode(r'''
class A {
  static const a = const A();
  const A();
  operator ==(other) => false;
}
main() {
  const {A.a};
}
''', [CompileTimeErrorCode.CONST_SET_ELEMENT_TYPE_IMPLEMENTS_EQUALS]);
  }

  test_direct() async {
    await assertErrorCodesInCode(r'''
class A {
  const A();
  operator ==(other) => false;
}
main() {
  const {const A()};
}
''', [CompileTimeErrorCode.CONST_SET_ELEMENT_TYPE_IMPLEMENTS_EQUALS]);
  }

  test_dynamic() async {
    // Note: static type of B.a is "dynamic", but actual type of the const
    // object is A.  We need to make sure we examine the actual type when
    // deciding whether there is a problem with operator==.
    await assertErrorCodesInCode(r'''
class A {
  const A();
  operator ==(other) => false;
}
class B {
  static const a = const A();
}
main() {
  const {B.a};
}
''', [CompileTimeErrorCode.CONST_SET_ELEMENT_TYPE_IMPLEMENTS_EQUALS]);
  }

  test_factory() async {
    await assertErrorCodesInCode(r'''
class A { const factory A() = B; }

class B implements A {
  const B();

  operator ==(o) => true;
}

main() {
  var m = const {const A()};
}
''', [CompileTimeErrorCode.CONST_SET_ELEMENT_TYPE_IMPLEMENTS_EQUALS]);
  }

  test_super() async {
    await assertErrorCodesInCode(r'''
class A {
  const A();
  operator ==(other) => false;
}
class B extends A {
  const B();
}
main() {
  const {const B()};
}
''', [CompileTimeErrorCode.CONST_SET_ELEMENT_TYPE_IMPLEMENTS_EQUALS]);
  }
}

@reflectiveTest
class ConstSetElementTypeImplementsEqualsWithUIAsCodeAndConstantsTest
    extends ConstSetElementTypeImplementsEqualsWithUIAsCodeTest {
  @override
  AnalysisOptionsImpl get analysisOptions => AnalysisOptionsImpl()
    ..enabledExperiments = [
      EnableString.control_flow_collections,
      EnableString.spread_collections,
      EnableString.constant_update_2018
    ];
}

@reflectiveTest
class ConstSetElementTypeImplementsEqualsWithUIAsCodeTest
    extends ConstSetElementTypeImplementsEqualsTest {
  @override
  AnalysisOptionsImpl get analysisOptions => AnalysisOptionsImpl()
    ..enabledExperiments = [
      EnableString.control_flow_collections,
      EnableString.spread_collections
    ];

  test_spread_list() async {
    await assertErrorCodesInCode(
        r'''
class A {
  const A();
  operator ==(other) => false;
}

main() {
  const {...[A()]};
}
''',
        analysisOptions.experimentStatus.constant_update_2018
            ? [CompileTimeErrorCode.CONST_SET_ELEMENT_TYPE_IMPLEMENTS_EQUALS]
            : [CompileTimeErrorCode.NON_CONSTANT_SET_ELEMENT]);
  }

  test_spread_set() async {
    await assertErrorCodesInCode(
        r'''
class A {
  const A();
  operator ==(other) => false;
}

main() {
  const {...{A()}};
}
''',
        analysisOptions.experimentStatus.constant_update_2018
            ? [CompileTimeErrorCode.CONST_SET_ELEMENT_TYPE_IMPLEMENTS_EQUALS]
            : [
                CompileTimeErrorCode.CONST_SET_ELEMENT_TYPE_IMPLEMENTS_EQUALS,
                CompileTimeErrorCode.NON_CONSTANT_SET_ELEMENT
              ]);
  }
}
