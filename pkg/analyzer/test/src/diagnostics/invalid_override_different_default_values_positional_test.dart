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
    defineReflectiveTests(InvalidOverrideDifferentDefaultValuesPositionalTest);
    defineReflectiveTests(
      InvalidOverrideDifferentDefaultValuesPositionalWithNnbdTest,
    );
  });
}

@reflectiveTest
class InvalidOverrideDifferentDefaultValuesPositionalTest
    extends DriverResolutionTest {
  test_baseClassInOtherLibrary() async {
    newFile('/test/lib/a.dart', content: r'''
class A {
  foo([a = 0]) {}
}
''');
    await assertNoErrorsInCode(r'''
import 'a.dart';

class C extends A {
  foo([a = 0]) {}
}
''');
  }

  test_differentValues() async {
    await assertErrorsInCode(r'''
class A {
  m([x = 0]) {}
}
class B extends A {
  m([x = 1]) {}
}''', [
      error(
          StaticWarningCode
              .INVALID_OVERRIDE_DIFFERENT_DEFAULT_VALUES_POSITIONAL,
          53,
          5),
    ]);
  }

  test_equal_values_generic_different_files() async {
    newFile('/test/lib/other.dart', content: '''
class C {
  f([x = const ['x']]) {}
}
''');
    await assertNoErrorsInCode('''
import 'other.dart';
class D extends C {
  f([x = const ['x']]) {}
}
''');
  }

  test_equal_values_generic_undefined_value_base() async {
    // Note: we expect some errors due to the constant referring to undefined
    // values, but there should not be any INVALID_OVERRIDE... error.
    await assertErrorsInCode('''
class A {
  m([x = Undefined.value]) {}
}
class B extends A {
  m([x = 1]) {}
}
''', [
      error(CompileTimeErrorCode.NON_CONSTANT_DEFAULT_VALUE, 19, 9),
      error(StaticWarningCode.UNDEFINED_IDENTIFIER, 19, 9),
    ]);
  }

  test_equal_values_generic_undefined_value_both() async {
    // Note: we expect some errors due to the constant referring to undefined
    // values, but there should not be any INVALID_OVERRIDE... error.
    await assertErrorsInCode('''
class A {
  m([x = Undefined.value]) {}
}
class B extends A {
  m([x = Undefined2.value2]) {}
}
''', [
      error(CompileTimeErrorCode.NON_CONSTANT_DEFAULT_VALUE, 19, 9),
      error(StaticWarningCode.UNDEFINED_IDENTIFIER, 19, 9),
      error(CompileTimeErrorCode.NON_CONSTANT_DEFAULT_VALUE, 71, 10),
      error(StaticWarningCode.UNDEFINED_IDENTIFIER, 71, 10),
    ]);
  }

  test_equal_values_generic_undefined_value_derived() async {
    // Note: we expect some errors due to the constant referring to undefined
    // values, but there should not be any INVALID_OVERRIDE... error.
    await assertErrorsInCode('''
class A {
  m([x = 1]) {}
}
class B extends A {
  m([x = Undefined.value]) {}
}
''', [
      error(CompileTimeErrorCode.NON_CONSTANT_DEFAULT_VALUE, 57, 9),
      error(StaticWarningCode.UNDEFINED_IDENTIFIER, 57, 9),
    ]);
  }

  test_equalValues() async {
    await assertNoErrorsInCode(r'''
abstract class A {
  foo([x = 1]);
}

class C extends A {
  foo([x = 3 - 2]) {}
}
''');
  }

  test_equalValues_function() async {
    await assertNoErrorsInCode(r'''
nothing() => 'nothing';

class A {
  foo(String a, [orElse = nothing]) {}
}

class B extends A {
  foo(String a, [orElse = nothing]) {}
}
''');
  }

  test_explicitNull_overriddenWith_implicitNull() async {
    // If the base class provided an explicit null value for a default
    // parameter, then it is ok for the derived class to let the default value
    // be implicit, because the implicit default value of null matches the
    // explicit default value of null.
    await assertNoErrorsInCode(r'''
class A {
  foo([x = null]) {}
}
class B extends A {
  foo([x]) {}
}
''');
  }

  test_implicitNull_overriddenWith_value() async {
    // If the base class lets the default parameter be implicit, then it is ok
    // for the derived class to provide an explicit default value, even if it's
    // not null.
    await assertNoErrorsInCode(r'''
class A {
  foo([x]) {}
}
class B extends A {
  foo([x = 1]) {}
}
''');
  }

  test_value_overriddenWith_implicitNull() async {
    // If the base class provided an explicit value for a default parameter,
    // then it is a static warning for the derived class to provide a different
    // value, even if implicitly.
    await assertErrorsInCode(r'''
class A {
  foo([x = 1]) {}
}
class B extends A {
  foo([x]) {}
}
''', [
      error(
          StaticWarningCode
              .INVALID_OVERRIDE_DIFFERENT_DEFAULT_VALUES_POSITIONAL,
          57,
          1),
    ]);
  }
}

@reflectiveTest
class InvalidOverrideDifferentDefaultValuesPositionalWithNnbdTest
    extends InvalidOverrideDifferentDefaultValuesPositionalTest {
  @override
  AnalysisOptionsImpl get analysisOptions => AnalysisOptionsImpl()
    ..enabledExperiments = [EnableString.non_nullable]
    ..implicitCasts = false;

  @override
  bool get typeToStringWithNullability => true;

  test_equal_optIn_extends_optOut() async {
    newFile('/test/lib/a.dart', content: r'''
// @dart = 2.7
class A {
  void foo([int a = 0]) {}
}
''');

    await assertNoErrorsInCode(r'''
import 'a.dart';

class B extends A {
  void foo([int a = 0]) {}
}
''');
  }

  test_equal_optOut_extends_optIn() async {
    newFile('/test/lib/a.dart', content: r'''
class A {
  void foo([int a = 0]) {}
}
''');

    await assertNoErrorsInCode(r'''
// @dart = 2.7
import 'a.dart';

class B extends A {
  void foo([int a = 0]) {}
}
''');
  }
}
