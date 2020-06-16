// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstConstructorWithMixinWithFieldTest);
  });
}

@reflectiveTest
class ConstConstructorWithMixinWithFieldTest extends DriverResolutionTest {
  test_class_instance_final() async {
    await assertErrorsInCode('''
class A {
  final a = 0;
}

class B extends Object with A {
  const B();
}
''', [
      error(
          CompileTimeErrorCode.CONST_CONSTRUCTOR_WITH_MIXIN_WITH_FIELD, 68, 1),
    ]);
  }

  test_class_instance_getter() async {
    await assertNoErrorsInCode('''
class A {
  int get a => 7;
}

class B extends Object with A {
  const B();
}
''');
  }

  test_class_instance_setter() async {
    await assertNoErrorsInCode('''
class A {
  set a(int x) {}
}

class B extends Object with A {
  const B();
}
''');
  }

  test_class_instanceField() async {
    await assertErrorsInCode('''
class A {
  var a;
}

class B extends Object with A {
  const B();
}
''', [
      error(CompileTimeErrorCode.CONST_CONSTRUCTOR_WITH_NON_FINAL_FIELD, 62, 1),
      error(
          CompileTimeErrorCode.CONST_CONSTRUCTOR_WITH_MIXIN_WITH_FIELD, 62, 1),
    ]);
  }

  test_class_multipleInstanceFields() async {
    await assertErrorsInCode('''
class A {
  var a;
  var b;
}

class B extends Object with A {
  const B();
}
''', [
      error(CompileTimeErrorCode.CONST_CONSTRUCTOR_WITH_NON_FINAL_FIELD, 71, 1),
      error(
          CompileTimeErrorCode.CONST_CONSTRUCTOR_WITH_MIXIN_WITH_FIELDS, 71, 1),
    ]);
  }

  test_class_noFields() async {
    await assertNoErrorsInCode('''
class M {}

class X extends Object with M {
  const X();
}
''');
  }

  test_class_static() async {
    await assertNoErrorsInCode('''
class M {
  static final a = 0;
}

class X extends Object with M {
  const X();
}
''');
  }

  test_mixin_instance() async {
    await assertErrorsInCode('''
mixin M {
  var a;
}

class X extends Object with M {
  const X();
}
''', [
      error(CompileTimeErrorCode.CONST_CONSTRUCTOR_WITH_NON_FINAL_FIELD, 62, 1),
      error(
          CompileTimeErrorCode.CONST_CONSTRUCTOR_WITH_MIXIN_WITH_FIELD, 62, 1),
    ]);
  }

  test_mixin_instance_final() async {
    await assertErrorsInCode('''
mixin M {
  final a = 0;
}

class X extends Object with M {
  const X();
}
''', [
      error(
          CompileTimeErrorCode.CONST_CONSTRUCTOR_WITH_MIXIN_WITH_FIELD, 68, 1),
    ]);
  }

  test_mixin_noFields() async {
    await assertNoErrorsInCode('''
mixin M {}

class X extends Object with M {
  const X();
}
''');
  }

  test_mixin_static() async {
    await assertNoErrorsInCode('''
mixin M {
  static final a = 0;
}

class X extends Object with M {
  const X();
}
''');
  }
}
