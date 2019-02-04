// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidOverrideDifferentDefaultValuesNamedTest);
  });
}

@reflectiveTest
class InvalidOverrideDifferentDefaultValuesNamedTest
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
    await _assertError(r'''
class A {
  m({x = 0}) {}
}
class B extends A {
  m({x = 1}) {}
}''');
  }

  test_equalValues() async {
    await assertNoErrorsInCode(r'''
abstract class A {
  foo({x = 1});
}

class C extends A {
  foo({x = 3 - 2}) {}
}
''');
  }

  test_equalValues_function() async {
    await assertNoErrorsInCode(r'''
nothing() => 'nothing';

class A {
  foo(String a, {orElse = nothing}) {}
}

class B extends A {
  foo(String a, {orElse = nothing}) {}
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
  foo({x: null}) {}
}
class B extends A {
  foo({x}) {}
}
''');
  }

  test_implicitNull_overriddenWith_value() async {
    // If the base class lets the default parameter be implicit, then it is ok
    // for the derived class to provide an explicit default value, even if it's
    // not null.
    await assertNoErrorsInCode(r'''
class A {
  foo({x}) {}
}
class B extends A {
  foo({x = 1}) {}
}
''');
  }

  test_value_overriddenWith_implicitNull() async {
    // If the base class provided an explicit value for a default parameter,
    // then it is a static warning for the derived class to provide a different
    // value, even if implicitly.
    await _assertError(r'''
class A {
  foo({x: 1}) {}
}
class B extends A {
  foo({x}) {}
}
''');
  }

  Future<void> _assertError(String code) async {
    await assertErrorsInCode(code, [
      StaticWarningCode.INVALID_OVERRIDE_DIFFERENT_DEFAULT_VALUES_NAMED,
    ]);
  }
}
