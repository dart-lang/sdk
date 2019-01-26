// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidOverrideDifferentDefaultValuesTest);
  });
}

@reflectiveTest
class InvalidOverrideDifferentDefaultValuesTest extends DriverResolutionTest {
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

  test_differentValues_named() async {
    await _assertErrorNamed(r'''
class A {
  m({x = 0}) {}
}
class B extends A {
  m({x = 1}) {}
}''');
  }

  test_differentValues_positional() async {
    await _assertErrorPositional(r'''
class A {
  m([x = 0]) {}
}
class B extends A {
  m([x = 1]) {}
}''');
  }

  test_equalValues_named() async {
    await assertNoErrorsInCode(r'''
abstract class A {
  foo({x = 1});
}

class C extends A {
  foo({x = 3 - 2}) {}
}
''');
  }

  test_equalValues_named_function() async {
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

  test_equalValues_positional() async {
    await assertNoErrorsInCode(r'''
abstract class A {
  foo([x = 1]);
}

class C extends A {
  foo([x = 3 - 2]) {}
}
''');
  }

  test_equalValues_positional_function() async {
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

  test_explicitNull_overriddenWith_implicitNull_named() async {
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

  test_explicitNull_overriddenWith_implicitNull_positional() async {
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

  test_implicitNull_overriddenWith_value_named() async {
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

  test_implicitNull_overriddenWith_value_positional() async {
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

  test_value_overriddenWith_implicitNull_named() async {
    // If the base class provided an explicit value for a default parameter,
    // then it is a static warning for the derived class to provide a different
    // value, even if implicitly.
    await _assertErrorNamed(r'''
class A {
  foo({x: 1}) {}
}
class B extends A {
  foo({x}) {}
}
''');
  }

  test_value_overriddenWith_implicitNull_positional() async {
    // If the base class provided an explicit value for a default parameter,
    // then it is a static warning for the derived class to provide a different
    // value, even if implicitly.
    await _assertErrorPositional(r'''
class A {
  foo([x = 1]) {}
}
class B extends A {
  foo([x]) {}
}
''');
  }

  Future<void> _assertErrorNamed(String code) async {
    await assertErrorsInCode(code, [
      StaticWarningCode.INVALID_OVERRIDE_DIFFERENT_DEFAULT_VALUES_NAMED,
    ]);
  }

  Future<void> _assertErrorPositional(String code) async {
    await assertErrorsInCode(code, [
      StaticWarningCode.INVALID_OVERRIDE_DIFFERENT_DEFAULT_VALUES_POSITIONAL,
    ]);
  }
}
